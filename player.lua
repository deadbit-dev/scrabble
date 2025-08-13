local hand = import("hand")
local element = import("element")

local player = {}

function player.init(state)
    local player_uid = generate_uid()
    local hand_uid = hand.init(state)
    state.players[player_uid] = { uid = player_uid, hand_uid = hand_uid }
    state.current_player_uid = player_uid

    -- NOTE: for test
    hand.addElem(state, hand_uid, 1, element.create(state, "A", 1))
    hand.addElem(state, hand_uid, 2, element.create(state, "B", 2))
    hand.addElem(state, hand_uid, 3, element.create(state, "C", 3))
    hand.addElem(state, hand_uid, 4, element.create(state, "D", 4))
    hand.addElem(state, hand_uid, 5, element.create(state, "E", 5))
end

return player