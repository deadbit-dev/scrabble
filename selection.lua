local log = import("log")
local input = import("input")
local hand = import("hand")
local board = import("board")
local element = import("element")
local space = import("space")
local transition = import("transition")
local tween = import("tween")
local utils = import("utils")

local selection = {}

---Проверяет, является ли клик двойным
---@param game Game
---@param current_time number
---@return boolean
local function isDoubleClick(game, current_time)
    local conf = game.conf
    local state = game.state
    return (current_time - input.get_last_click_time(state)) < conf.click.double_click_threshold
end

---Находит элемент по позиции клика
---@param game Game
---@param mouse_pos {x: number, y: number}
---@return Element|nil
local function getElementAtPosition(game, mouse_pos)
    local state = game.state
    for _, elem in pairs(state.elements) do
        if utils.isPointInElementBounds(mouse_pos, elem) then
            return elem
        end
    end
    return nil
end

---Поднимает элемент при выборе
---@param game Game
---@param elem_uid number
local function liftElement(game, elem_uid)
    local conf = game.conf
    local elem = element.get(game, elem_uid)
    if not elem then return end

    -- Создаем твин для поднятия элемента
    local target_transform = {
        x = elem.transform.x,
        y = elem.transform.y - conf.click.selection_lift_offset,
        width = elem.transform.width,
        height = elem.transform.height,
        z_index = elem.transform.z_index + 1 -- поднимаем z_index для отображения поверх других
    }

    tween.create(
        game,
        conf.click.selection_animation_duration,
        elem.transform,
        target_transform,
        tween.easing.outQuad
    )
end

---Опускает элемент при снятии выбора
---@param game Game
---@param elem_uid number
local function lowerElement(game, elem_uid)
    local conf = game.conf
    local elem = element.get(game, elem_uid)
    if not elem then return end

    -- Возвращаем элемент в исходную позицию
    local target_transform = {
        x = elem.transform.x,
        y = elem.transform.y + conf.click.selection_lift_offset,
        width = elem.transform.width,
        height = elem.transform.height,
        z_index = elem.transform.z_index - 1 -- возвращаем z_index
    }

    tween.create(
        game,
        conf.click.selection_animation_duration,
        elem.transform,
        target_transform,
        tween.easing.outQuad
    )
end

---Обрабатывает клик по элементу в руке
---@param game Game
---@param elem Element
local function handleHandElementClick(game, elem)
    local state = game.state

    -- Если уже есть выбранный элемент, снимаем выбор
    if state.selected_element_uid and state.selected_element_uid ~= elem.uid then
        lowerElement(game, state.selected_element_uid)
    end

    -- Если кликнули по уже выбранному элементу, снимаем выбор
    if state.selected_element_uid == elem.uid then
        state.selected_element_uid = nil
        lowerElement(game, elem.uid)
        log.log("[CLICK]: Deselected element " .. elem.uid)
    else
        -- Выбираем новый элемент
        state.selected_element_uid = elem.uid
        liftElement(game, elem.uid)
        log.log("[CLICK]: Selected element " .. elem.uid)
    end
end

---Обрабатывает клик по элементу на поле
---@param game Game
---@param elem Element
local function handleBoardElementClick(game, elem)
    local state = game.state
    local current_time = love.timer.getTime()

    -- Проверяем двойной клик
    if isDoubleClick(game, current_time) then
        -- Двойной клик - перемещаем элемент в руку
        local hand_uid = state.players[state.current_player_uid].hand_uid

        local empty_slot = hand.getEmptySlot(game, hand_uid)

        if empty_slot then
            transition.to(game, elem.uid, 0.7, tween.easing.inOutCubic,
                space.createHandSpace(hand_uid, empty_slot)
            )

            log.log("[CLICK]: Double-clicked element " .. elem.uid .. " moved to hand slot " .. empty_slot)
        else
            log.warn("[CLICK]: No empty slots in hand for element " .. elem.uid)
        end
    end

    -- Время клика обновляется в input.updateInteraction
end

---Обрабатывает клик по пустой клетке поля
---@param game Game
---@param mouse_pos {x: number, y: number}
local function handleEmptyBoardClick(game, mouse_pos)
    local state = game.state

    -- Если есть выбранный элемент в руке, перемещаем его на поле
    if state.selected_element_uid then
        local selected_elem = element.get(game, state.selected_element_uid)
        if selected_elem and selected_elem.space.type == "hand" then
            -- Получаем позицию на поле
            local board_pos = space.getBoardPosByWorldPos(game, mouse_pos.x, mouse_pos.y)
            if board_pos then
                -- Проверяем, что клетка пустая
                local existing_elem = board.getBoardElemUID(game, board_pos.x, board_pos.y)
                if not existing_elem then
                    -- Убираем элемент из руки
                    hand.removeElem(game, selected_elem.space.data.hand_uid, selected_elem.space.data.index)

                    -- Перемещаем на поле
                    transition.to(game, state.selected_element_uid, 0.7, tween.easing.inOutCubic,
                        space.createBoardSpace(board_pos.x, board_pos.y)
                    )

                    -- Снимаем выбор
                    state.selected_element_uid = nil

                    log.log("[CLICK]: Moved selected element to board position " .. board_pos.x .. ", " .. board_pos.y)
                else
                    log.warn("[CLICK]: Board cell is not empty")
                end
            end
        end
    end
end

---Обновляет систему кликов
---@param game Game
---@param dt number
function selection.update(game, dt)
    local state = game.state

    -- Обрабатываем клики только если драг не активен
    if not input.is_drag_active(state) and input.get_action_type(state) then
        local clicked_elem = element.get(game, input.get_click_target_uid(state))

        if clicked_elem then
            -- Кликнули по элементу
            if clicked_elem.space.type == "hand" then
                if input.get_action_type(state) == "single" then
                    handleHandElementClick(game, clicked_elem)
                end
            elseif clicked_elem.space.type == "board" then
                if input.get_action_type(state) == "double" then
                    handleBoardElementClick(game, clicked_elem)
                end
            end
        else
            -- Кликнули по пустому месту (только одинарный клик)
            if input.get_action_type(state) == "single" then
                local mouse_pos = input.get_mouse_pos(state)
                if space.isInBoardArea(game, mouse_pos.x, mouse_pos.y) then
                    handleEmptyBoardClick(game, mouse_pos)
                end
            end
        end
    end
end

---Получает выбранный элемент
---@param game Game
---@return number|nil
function selection.getSelectedElement(game)
    return game.state.selected_element_uid
end

---Снимает выбор с элемента
---@param game Game
function selection.deselectElement(game)
    local state = game.state
    if state.selected_element_uid then
        lowerElement(game, state.selected_element_uid)
        state.selected_element_uid = nil
    end
end

return selection
