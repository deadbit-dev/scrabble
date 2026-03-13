local transition = {}

local space = import("space")
local tween = import("tween")

---@class Transition
---@field element_uid number
---@field target_space SpaceInfo
---@field tween_uid number
---@field onComplete function|nil

---@param state State
---@param conf Config
---@param elem_uid number
---@param duration number
---@param easing function
---@param to SpaceInfo
---@param on_complete function|nil
---@param delay number|nil
---@return number
function transition.to(state, conf, elem_uid, duration, easing, to, on_complete, delay)
    local element_data = state.elements[elem_uid]
    local current_space = element_data.space

    space.remove_element_from_space(state, current_space)

    local entry = {
        element_uid = elem_uid,
        tween_uid   = nil,
        target_space = to,
        onComplete  = on_complete,
    }

    local wrapped_callback = function()
        transition.remove_by_element(state, elem_uid)
        space.add_element_to_space(state, elem_uid, to)
        if on_complete then
            on_complete()
        end
    end

    local target = space.get_space_transform(state, conf, to)
    local fly_z = math.max(element_data.world_transform.z_index, target.z_index) + 1
    element_data.world_transform.z_index = fly_z
    target.z_index = fly_z

    local tween_uid = tween.create(
        state.tweens,
        duration,
        element_data.world_transform,
        target,
        easing,
        wrapped_callback,
        delay
    )

    entry.tween_uid = tween_uid
    table.insert(state.transitions, entry)
end

---@param state State
---@param elem_uid number
function transition.remove_by_element(state, elem_uid)
    for i = #state.transitions, 1, -1 do
        if state.transitions[i].element_uid == elem_uid then
            table.remove(state.transitions, i)
            return
        end
    end
end

-- function transition.pool_to_hand(state, conf, elem_uid, hand_uid, toIndex, onComplete)
--     screen_to_hand(state, conf, elem_uid, love.graphics.getWidth(), love.graphics.getHeight() / 2, hand_uid,
--         toIndex,
--         onComplete)
-- end

-- function transition.screen_to_hand(state, conf, elem_uid, fromX, fromY, hand_uid, toIndex, onComplete)
--     -- NOTE: from right of the screen - from pool
--     space.set_space(state, conf, elem_uid, space.create_screen_space(fromX, fromY))

--     to(game, elem_uid, 0.7, tween.easing.inOutCubic,
--         space.create_hand_space(hand_uid, toIndex),
--         onComplete
--     )
-- end

-- function transition.hand_to_board(state, conf, hand_uid, elem_uid, fromIndex, toX, toY, onComplete)
--     space.set_space(state, conf, elem_uid, space.create_hand_space(hand_uid, fromIndex))
--     to(game, elem_uid, 0.7, tween.easing.inOutCubic,
--         space.create_board_space(toX, toY),
--         onComplete
--     )
-- end

return transition
