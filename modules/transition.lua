-- Модуль управления переходами элементов между пространствами
local transition = {}

local space = require("helpers.space")
local tween = require("core.tween")
local element = require("modules.element")

---Создает переход элемента
---@param state State
---@param conf Config
---@param elem_uid number
---@param duration number
---@param easing function
---@param to SpaceInfo
---@param on_complete function|nil
---@return number
function transition.to(state, conf, elem_uid, duration, easing, to, on_complete)
    local element_data = element.get_state(state, elem_uid)
    local current_space = element.get_space(state, elem_uid)

    space.update_data(state, elem_uid, current_space, to)

    -- Создаем обертку для коллбэка, которая удалит переход
    local transition_index = #state.transitions + 1
    local wrapped_callback = function()
        -- Удаляем переход
        transition.remove(state, transition_index)
        -- Вызываем оригинальный коллбэк
        if on_complete then
            on_complete()
        end
    end

    -- Создаем твин и получаем его UID
    local tween_uid = tween.create(
        state,
        duration,
        element_data.transform,
        space.get_world_transform_from_space_info(state, conf, to),
        easing,
        wrapped_callback
    )

    table.insert(state.transitions, {
        element_uid = elem_uid,
        tween_uid = tween_uid,
        onComplete = on_complete,
    })

    return transition_index
end

---Удаляет переход
---@param state State
---@param idx number
function transition.remove(state, idx)
    table.remove(state.transitions, idx)
end

---Обновляет переходы
---@param state State
---@param conf Config
---@param dt number
function transition.update(state, conf, dt)
    for i = #state.transitions, 1, -1 do
        local trans = state.transitions[i]
        if trans.tween_uid ~= nil then
            local target_space = element.get_space(state, trans.element_uid)
            local target_transform = space.get_world_transform_from_space_info(state, conf, target_space)
            tween.update_target(state, trans.tween_uid, target_transform)
        end
    end
end

return transition
