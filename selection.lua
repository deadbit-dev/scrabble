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
    return (current_time - state.last_click_time) < conf.click.double_click_threshold
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
        
        -- Находим свободный слот в руке
        local empty_slot = nil
        for i = 1, #state.hands[hand_uid].elem_uids do
            if not state.hands[hand_uid].elem_uids[i] then
                empty_slot = i
                break
            end
        end
        
        if empty_slot then
            -- Убираем элемент с поля
            board.removeElement(game, elem.space.data.x, elem.space.data.y)
            
            -- Перемещаем в руку через переход
            transition.to(game, elem.uid, 0.7, tween.easing.inOutCubic,
                space.createHandSpace(hand_uid, empty_slot)
            )
            
            log.log("[CLICK]: Double-clicked element " .. elem.uid .. " moved to hand slot " .. empty_slot)
        else
            log.warn("[CLICK]: No empty slots in hand for element " .. elem.uid)
        end
    end
    
    state.last_click_time = current_time
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
    
    -- Обрабатываем клик мыши
    if input.is_mouse_pressed(state) then
        local mouse_pos = input.get_mouse_pos(state)
        local clicked_elem = getElementAtPosition(game, mouse_pos)
        
        if clicked_elem then
            -- Кликнули по элементу
            if clicked_elem.space.type == "hand" then
                handleHandElementClick(game, clicked_elem)
            elseif clicked_elem.space.type == "board" then
                handleBoardElementClick(game, clicked_elem)
            end
        else
            -- Кликнули по пустому месту
            if space.isInBoardArea(game, mouse_pos.x, mouse_pos.y) then
                handleEmptyBoardClick(game, mouse_pos)
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
