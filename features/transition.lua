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
---@return number
function transition.to(state, conf, elem_uid, duration, easing, to, on_complete)
    local element_data = state.elements[elem_uid]
    local current_space = element_data.space

    space.remove_element_from_space(state, current_space)

    local transition_index = #state.transitions + 1
    local wrapped_callback = function()
        transition.remove(state, transition_index)
        space.add_element_to_space(state, elem_uid, to)
        if on_complete then
            on_complete()
        end
    end

    local tween_uid = tween.create(
        state.tweens,
        duration,
        element_data.world_transform,
        space.get_space_transform(state, conf, to),
        easing,
        wrapped_callback
    )

    table.insert(state.transitions, {
        element_uid = elem_uid,
        tween_uid = tween_uid,
        target_space = to,
        onComplete = on_complete,
    })

    return transition_index
end

---@param state State
---@param idx number
function transition.remove(state, idx)
    table.remove(state.transitions, idx)
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
