local Selection = {}

local Math = require("Math")

---Проверяет, является ли клик двойным
---@param game Game
---@param current_time number
---@return boolean
local function is_double_click(game, current_time)
    local conf = game.conf
    local state = game.state
    local Input = game.engine.Input

    return (current_time - Input.get_last_click_time(state)) < conf.click.double_click_threshold
end

-- ---Находит элемент по позиции клика
-- ---@param game Game
-- ---@param mouse_pos {x: number, y: number}
-- ---@return Element|nil
-- local function get_element_at_position(game, mouse_pos)
--     local state = game.state
--     local ElementsManager = game.logic.ElementsManager

--     for elem_uid, element_data in pairs(state.elements) do
--         if ElementsManager.is_point_in_element_bounds(game, mouse_pos, elem_uid) then
--             return element_data
--         end
--     end
--     return nil
-- end

---Поднимает элемент при выборе
---@param game Game
---@param elem_uid number
local function lift_element(game, elem_uid)
    local conf = game.conf
    local Tween = game.engine.tween
    local ElementsManager = game.logic.ElementsManager

    local element_data = ElementsManager.get_state(game, elem_uid)
    if not element_data then return end

    -- Создаем твин для поднятия элемента
    local target_transform = {
        x = element_data.transform.x,
        y = element_data.transform.y - conf.click.selection_lift_offset,
        width = element_data.transform.width,
        height = element_data.transform.height,
        z_index = element_data.transform.z_index + 1 -- поднимаем z_index для отображения поверх других
    }

    Tween.create(
        game,
        conf.click.selection_animation_duration,
        element_data.transform,
        target_transform,
        Tween.easing.outQuad
    )
end

---Опускает элемент при снятии выбора
---@param game Game
---@param elem_uid number
local function lower_element(game, elem_uid)
    local conf = game.conf
    local Tween = game.engine.tween
    local ElementsManager = game.logic.ElementsManager

    local element_data = ElementsManager.get_state(game, elem_uid)
    if not element_data then return end

    -- Возвращаем элемент в исходную позицию
    local target_transform = {
        x = element_data.transform.x,
        y = element_data.transform.y + conf.click.selection_lift_offset,
        width = element_data.transform.width,
        height = element_data.transform.height,
        z_index = element_data.transform.z_index - 1 -- возвращаем z_index
    }

    Tween.create(
        game,
        conf.click.selection_animation_duration,
        element_data.transform,
        target_transform,
        Tween.easing.outQuad
    )
end

---Обрабатывает клик по элементу в руке
---@param game Game
---@param elem Element
local function handle_hand_element_click(game, elem)
    local state = game.state
    local Log = game.engine.Log

    -- Если уже есть выбранный элемент, снимаем выбор
    if state.selected_element_uid and state.selected_element_uid ~= elem.uid then
        lower_element(game, state.selected_element_uid)
    end

    -- Если кликнули по уже выбранному элементу, снимаем выбор
    if state.selected_element_uid == elem.uid then
        state.selected_element_uid = nil
        lower_element(game, elem.uid)
        Log.log("[CLICK]: Deselected element " .. elem.uid)
    else
        -- Выбираем новый элемент
        state.selected_element_uid = elem.uid
        lift_element(game, elem.uid)
        Log.log("[CLICK]: Selected element " .. elem.uid)
    end
end

---Обрабатывает клик по элементу на поле
---@param game Game
---@param elem Element
local function handle_board_element_click(game, elem)
    local state = game.state
    local Log = game.engine.Log
    local Tween = game.engine.Tween
    local HandManager = game.logic.HandManager
    local Transition = game.logic.Transition
    local Space = game.logic.Space

    local current_time = love.timer.getTime()

    -- Проверяем двойной клик
    if is_double_click(game, current_time) then
        -- Двойной клик - перемещаем элемент в руку
        local hand_uid = state.players[state.current_player_uid].hand_uid

        local empty_slot = HandManager.get_empty_slot(game, hand_uid)

        if empty_slot then
            Transition.to(game, elem.uid, 0.7, Tween.easing.inOutCubic,
                Space.create_hand_space(hand_uid, empty_slot)
            )

            Log.log("[CLICK]: Double-clicked element " .. elem.uid .. " moved to hand slot " .. empty_slot)
        else
            Log.warn("[CLICK]: No empty slots in hand for element " .. elem.uid)
        end
    end

    -- Время клика обновляется в input.updateInteraction
end

---Обрабатывает клик по пустой клетке поля
---@param game Game
---@param mouse_pos {x: number, y: number}
local function handleEmptyBoardClick(game, mouse_pos)
    local state = game.state
    local Log = game.engine.Log
    local Tween = game.engine.Tween
    local ElementsManager = game.logic.ElementsManager
    local HandManager = game.logic.HandManager
    local Board = game.logic.Board
    local Transition = game.logic.Transition
    local Space = game.logic.Space

    -- Если есть выбранный элемент в руке, перемещаем его на поле
    if state.selected_element_uid then
        local selected_elem = ElementsManager.get_state(game, state.selected_element_uid)
        if selected_elem and selected_elem.space.type == "hand" then
            -- Получаем позицию на поле
            local board_pos = Space.get_board_pos_by_world_pos(game, mouse_pos.x, mouse_pos.y)
            if board_pos then
                -- Проверяем, что клетка пустая
                local existing_elem = Board.get_board_elem_uid(game, board_pos.x, board_pos.y)
                if not existing_elem then
                    -- Убираем элемент из руки
                    HandManager.remove_element(game, selected_elem.space.data.hand_uid, selected_elem.space.data.index)

                    -- Перемещаем на поле
                    Transition.to(game, state.selected_element_uid, 0.7, Tween.easing.inOutCubic,
                        Space.create_board_space(board_pos.x, board_pos.y)
                    )

                    -- Снимаем выбор
                    state.selected_element_uid = nil

                    Log.log("[CLICK]: Moved selected element to board position " .. board_pos.x .. ", " .. board_pos.y)
                else
                    Log.warn("[CLICK]: Board cell is not empty")
                end
            end
        end
    end
end

---Обновляет систему кликов
---@param game Game
---@param dt number
function Selection.update(game, dt)
    local state = game.state
    local Input = game.engine.Input
    local ElementsManager = game.logic.ElementsManager
    local Space = game.logic.Space

    -- Обрабатываем клики только если драг не активен
    if not Input.is_drag(state) and (Input.is_click(state) or Input.is_double_click(state)) then
        local click_pos = Input.get_click_pos(state)
        if not click_pos then return end

        -- Находим элемент в позиции клика
        local clicked_elem = nil
        for uid, elem in pairs(state.elements) do
            if ElementsManager.is_point_in_element_bounds(game, uid, click_pos) then
                clicked_elem = elem
                break
            end
        end

        if clicked_elem then
            -- Кликнули по элементу
            if clicked_elem.space.type == "hand" then
                if Input.is_click(state) then
                    handle_hand_element_click(game, clicked_elem)
                end
            elseif clicked_elem.space.type == "board" then
                if Input.is_double_click(state) then
                    handle_board_element_click(game, clicked_elem)
                end
            end
        else
            -- Кликнули по пустому месту (только одинарный клик)
            if Input.is_click(state) then
                if Space.isInBoardArea(game, click_pos.x, click_pos.y) then
                    handleEmptyBoardClick(game, click_pos)
                end
            end
        end
    end
end

---Получает выбранный элемент
---@param game Game
---@return number|nil
function Selection.get_selected_element(game)
    return game.state.selected_element_uid
end

---Снимает выбор с элемента
---@param game Game
function Selection.deselect_element(game)
    local state = game.state
    if state.selected_element_uid then
        lower_element(game, state.selected_element_uid)
        state.selected_element_uid = nil
    end
end

return Selection
