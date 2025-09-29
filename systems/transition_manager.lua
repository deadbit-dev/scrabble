local Space = require("../modules.space")
local Tween = require("../modules.tween")
local ElementsManager = require("elements_manager")

local TransitionManager = {}

---Creates a transition
---@param game Game
---@param elem_uid number
---@param duration number
---@param easing function
---@param to SpaceInfo
---@param onComplete function|nil
---@return number
function TransitionManager.to(game, elem_uid, duration, easing, to, onComplete)
    local state = game.state

    local element_data = ElementsManager.get_state(game, elem_uid)
    local current_space = ElementsManager.get_space(game, elem_uid)

    Space.updateData(game, elem_uid, current_space, to)

    -- Создаем обертку для коллбэка, которая удалит переход
    local transition_index = #state.transitions + 1
    local wrapped_callback = function()
        -- Удаляем переход
        TransitionManager.remove(state, transition_index)
        -- Вызываем оригинальный коллбэк
        if onComplete then
            onComplete()
        end
    end

    -- Создаем твин и получаем его UID
    local tween_uid = Tween.create(
        game,
        duration,
        element_data.transform,
        Space.get_world_transform_from_space_info(game, to),
        easing,
        wrapped_callback
    )

    table.insert(state.transitions, {
        element_uid = elem_uid,
        tween_uid = tween_uid,
        onComplete = onComplete,
    })

    return transition_index
end

---Removes a transition
---@param game Game
---@param idx number
function TransitionManager.remove(game, idx)
    table.remove(game.state.transitions, idx)
end

---Updates the transitions
---@param game Game
---@param dt number
function TransitionManager.late_update(game, dt)
    local state = game.state

    for i = #state.transitions, 1, -1 do
        local trans = state.transitions[i]
        if trans.tween_uid ~= nil then
            local target_space = ElementsManager.get_space(game, trans.element_uid)
            local target_transform = Space.get_world_transform_from_space_info(game, target_space)
            Tween.updateTarget(game, trans.tween_uid, target_transform)
        end
    end
end

return TransitionManager
