-- Модуль управления выбором элементов
local selection = {}

local input = require("core.input")
local tween = require("core.tween")
local element = require("modules.element")
local hand = require("modules.hand")
local board = require("modules.board")
local transition = require("modules.transition")
local space = require("helpers.space")
local log = require("helpers.log")

---Проверяет, является ли клик двойным
---@param state State
---@param conf Config
---@param current_time number
---@return boolean
local function is_double_click(state, conf, current_time)
    return (current_time - input.get_last_click_time(state)) < conf.click.double_click_threshold
end

---Поднимает элемент при выборе
---@param state State
---@param conf Config
---@param elem_uid number
local function lift_element(state, conf, elem_uid)
    local element_data = element.get_state(state, elem_uid)
    if not element_data then return end

    -- Создаем твин для поднятия элемента
    local target_transform = {
        x = element_data.transform.x,
        y = element_data.transform.y - conf.click.selection_lift_offset,
        width = element_data.transform.width,
        height = element_data.transform.height,
        z_index = element_data.transform.z_index + 1 -- поднимаем z_index для отображения поверх других
    }

    tween.create(
        state,
        conf.click.selection_animation_duration,
        element_data.transform,
        target_transform,
        tween.easing.outQuad
    )
end

---Опускает элемент при снятии выбора
---@param state State
---@param conf Config
---@param elem_uid number
local function lower_element(state, conf, elem_uid)
    local element_data = element.get_state(state, elem_uid)
    if not element_data then return end

    -- Возвращаем элемент в исходную позицию
    local target_transform = {
        x = element_data.transform.x,
        y = element_data.transform.y + conf.click.selection_lift_offset,
        width = element_data.transform.width,
        height = element_data.transform.height,
        z_index = element_data.transform.z_index - 1 -- возвращаем z_index
    }

    tween.create(
        state,
        conf.click.selection_animation_duration,
        element_data.transform,
        target_transform,
        tween.easing.outQuad
    )
end

---Обрабатывает клик по элементу в руке
---@param state State
---@param conf Config
---@param elem Element
local function handle_hand_element_click(state, conf, elem)
    -- Если уже есть выбранный элемент, снимаем выбор
    if state.selected_element_uid and state.selected_element_uid ~= elem.uid then
        lower_element(state, conf, state.selected_element_uid)
    end

    -- Если кликнули по уже выбранному элементу, снимаем выбор
    if state.selected_element_uid == elem.uid then
        state.selected_element_uid = nil
        lower_element(state, conf, elem.uid)
        log.log("[CLICK]: Deselected element " .. elem.uid)
    else
        -- Выбираем новый элемент
        state.selected_element_uid = elem.uid
        lift_element(state, conf, elem.uid)
        log.log("[CLICK]: Selected element " .. elem.uid)
    end
end

---Обрабатывает клик по элементу на поле
---@param state State
---@param conf Config
---@param elem Element
local function handle_board_element_click(state, conf, elem)
    local current_time = love.timer.getTime()

    -- Проверяем двойной клик
    if is_double_click(state, conf, current_time) then
        -- Двойной клик - перемещаем элемент в руку
        local hand_uid = state.players[state.current_player_uid].hand_uid

        local empty_slot = hand.get_empty_slot(state, hand_uid)

        if empty_slot then
            transition.to(state, conf, elem.uid, 0.7, tween.easing.inOutCubic,
                space.create_hand_space(hand_uid, empty_slot)
            )

            log.log("[CLICK]: Double-clicked element " .. elem.uid .. " moved to hand slot " .. empty_slot)
        else
            log.warn("[CLICK]: No empty slots in hand for element " .. elem.uid)
        end
    end
end

---Обрабатывает клик по пустой клетке поля
---@param state State
---@param conf Config
---@param mouse_pos {x: number, y: number}
local function handle_empty_board_click(state, conf, mouse_pos)
    -- Если есть выбранный элемент в руке, перемещаем его на поле
    if state.selected_element_uid then
        local selected_elem = element.get_state(state, state.selected_element_uid)
        if selected_elem and selected_elem.space.type == SpaceType.HAND then
            -- Получаем позицию на поле
            local board_pos = space.get_board_pos_by_world_pos(conf, mouse_pos.x, mouse_pos.y)
            if board_pos then
                -- Проверяем, что клетка пустая
                local existing_elem = board.get_board_elem_uid(state, board_pos.x, board_pos.y)
                if not existing_elem then
                    -- Убираем элемент из руки
                    hand.remove_element(state, selected_elem.space.data.hand_uid, selected_elem.space.data.index)

                    -- Перемещаем на поле
                    transition.to(state, conf, state.selected_element_uid, 0.7, tween.easing.inOutCubic,
                        space.create_board_space(board_pos.x, board_pos.y)
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

---Обновляет систему выбора
---@param state State
---@param conf Config
---@param dt number
function selection.update(state, conf, dt)
    -- Обрабатываем клики только если драг не активен
    if not input.is_drag(state) and (input.is_click(state) or input.is_double_click(state)) then
        local click_pos = input.get_click_pos(state)
        if not click_pos then return end

        -- Находим элемент в позиции клика
        local clicked_elem = nil
        for uid, elem in pairs(state.elements) do
            if element.is_point_in_element_bounds(state, uid, click_pos) then
                clicked_elem = elem
                break
            end
        end

        if clicked_elem then
            -- Кликнули по элементу
            if clicked_elem.space.type == SpaceType.HAND then
                if input.is_click(state) then
                    handle_hand_element_click(state, conf, clicked_elem)
                end
            elseif clicked_elem.space.type == SpaceType.BOARD then
                if input.is_double_click(state) then
                    handle_board_element_click(state, conf, clicked_elem)
                end
            end
        else
            -- Кликнули по пустому месту (только одинарный клик)
            if input.is_click(state) then
                if space.is_in_board_area(conf, click_pos.x, click_pos.y) then
                    handle_empty_board_click(state, conf, click_pos)
                end
            end
        end
    end
end

---Получает выбранный элемент
---@param state State
---@return number|nil
function selection.get_selected_element(state)
    return state.selected_element_uid
end

---Снимает выбор с элемента
---@param state State
---@param conf Config
function selection.deselect_element(state, conf)
    if state.selected_element_uid then
        lower_element(state, conf, state.selected_element_uid)
        state.selected_element_uid = nil
    end
end

return selection
