-- Модуль управления перетаскиванием элементов
local drag = {}

local input = require("core.input")
local board = require("modules.board")
local hand = require("modules.hand")
local element = require("modules.element")
local space = require("helpers.space")

---Начинает драг
---@param state State
---@param conf Config
local function start_drag(state, conf)
    local click_pos = input.get_click_pos(state)
    if not click_pos then return end

    -- Находим элемент в позиции клика
    local element_uid = nil
    for _, elem in pairs(state.elements) do
        if element.is_point_in_element_bounds(state, elem.uid, click_pos) then
            element_uid = elem.uid
            break
        end
    end

    if not element_uid then return end

    local element_data = element.get_state(state, element_uid)
    if not element_data then return end

    local type = element_data.space.type
    local data = element_data.space.data

    -- Сохраняем состояние драга
    state.drag.active = true
    state.drag.element_uid = element_uid
    state.drag.original_space = {
        type = type,
        data = data
    }

    if type == SpaceType.HAND then
        hand.remove_element(state, data.hand_uid, data.index)
    elseif type == SpaceType.BOARD then
        board.remove_element(state, data.x, data.y)
    end

    local mouse_pos = input.get_mouse_pos(state)
    local target_x = mouse_pos.x
    local target_y = mouse_pos.y
    local target_transform = space.get_world_transform_in_screen_space(conf, target_x, target_y)
    target_transform.x = target_transform.x - element_data.transform.width / 2
    target_transform.y = target_transform.y - element_data.transform.height / 2
    space.set_space(state, conf, element_uid, space.create_screen_space(target_transform.x, target_transform.y))
end

---Обновляет позицию элемента во время драга
---@param state State
---@param conf Config
---@param dt number
local function update_drag(state, conf, dt)
    if (state.drag.active and state.drag.element_uid) then
        local element_data = element.get_state(state, state.drag.element_uid)
        if element_data then
            local mouse_pos = input.get_mouse_pos(state)
            local target_x = mouse_pos.x
            local target_y = mouse_pos.y
            local target_transform = space.get_world_transform_in_screen_space(conf, target_x, target_y)
            target_transform.x = target_transform.x - element_data.transform.width / 2
            target_transform.y = target_transform.y - element_data.transform.height / 2
            space.set_space(state, conf, element_data.uid,
                space.create_screen_space(target_transform.x, target_transform.y))
        end
    end
end

---Заканчивает драг
---@param state State
---@param conf Config
local function end_drag(state, conf)
    if state.drag.element_uid and state.drag.original_space then
        local element_data = element.get_state(state, state.drag.element_uid)
        if element_data then
            -- Возвращаем элемент в исходное место
            space.set_space(state, conf, element_data.uid, state.drag.original_space)
        end

        -- Сбрасываем состояние драга
        state.drag.active = false
        state.drag.element_uid = nil
        state.drag.original_space = nil
    end
end

---Обновляет состояние драга
---@param state State
---@param conf Config
---@param dt number
function drag.update(state, conf, dt)
    -- Начинаем драг когда input определяет это
    if input.is_drag(state) and not state.drag.active then
        start_drag(state, conf)
    end

    -- Обновляем позицию во время драга
    if state.drag.active then
        update_drag(state, conf, dt)
    end

    -- Завершаем драг когда input сообщает об окончании
    if not input.is_drag(state) and state.drag.active then
        end_drag(state, conf)
    end
end

return drag
