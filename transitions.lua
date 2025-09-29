local Space = require("space")
local Tween = require("tween")
local TransitionManager = require("systems.transition_manager")

local Transitions = {}

function Transitions.pool_to_hand(game, elem_uid, hand_uid, toIndex, onComplete)
    TransitionManager.screen_to_hand(game, elem_uid, love.graphics.getWidth(), love.graphics.getHeight() / 2, hand_uid,
        toIndex,
        onComplete)
end

function Transitions.screen_to_hand(game, elem_uid, fromX, fromY, hand_uid, toIndex, onComplete)
    -- NOTE: from right of the screen - from pool
    Space.set_space(game, elem_uid, Space.create_screen_space(fromX, fromY))

    TransitionManager.to(game, elem_uid, 0.7, Tween.easing.inOutCubic,
        Space.create_hand_space(hand_uid, toIndex),
        onComplete
    )
end

function Transitions.hand_to_board(game, hand_uid, elem_uid, fromIndex, toX, toY, onComplete)
    Space.set_space(game, elem_uid, Space.create_hand_space(hand_uid, fromIndex))
    TransitionManager.to(game, elem_uid, 0.7, Tween.easing.inOutCubic,
        Space.create_board_space(toX, toY),
        onComplete
    )
end

return Transitions