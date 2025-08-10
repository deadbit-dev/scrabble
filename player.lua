local hand = import("hand")

local player = {}

function player.init(state)
    local player_uid = generate_uid()
    local hand_uid = hand.init(state)
    state.players[player_uid] = { uid = player_uid, hand_uid = hand_uid }
    state.current_player_uid = player_uid

    -- NOTE: for test
    table.insert(state.hands[hand_uid].elem_uids, createElement(state, "A", 1))
    table.insert(state.hands[hand_uid].elem_uids, createElement(state, "B", 2))
    table.insert(state.hands[hand_uid].elem_uids, createElement(state, "C", 3))
    table.insert(state.hands[hand_uid].elem_uids, createElement(state, "D", 4))
    table.insert(state.hands[hand_uid].elem_uids, createElement(state, "E", 5))
end

return player