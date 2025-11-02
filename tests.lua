local tests = {}

local board = import("board")
local element = import("element")
local transition = import("transition")

function tests.add_element_to_board(state, conf)
    board.add_element(state, 6, 8, element.create(state, conf, "H"))
    board.add_element(state, 7, 8, element.create(state, conf, "E"))
    board.add_element(state, 8, 8, element.create(state, conf, "L"))
    board.add_element(state, 9, 8, element.create(state, conf, "L"))
    board.add_element(state, 10, 8, element.create(state, conf, "O"))
    board.add_element(state, 10, 7, element.create(state, conf, "W"))
    board.add_element(state, 10, 9, element.create(state, conf, "R"))
    board.add_element(state, 10, 10, element.create(state, conf, "L"))
    board.add_element(state, 10, 11, element.create(state, conf, "D"))
    board.add_element(state, 10, 12, element.create(state, conf, "S"))
end

function tests.transition(state, conf)
    local elem_uid = element.create(state, conf, "A")
    local hand_uid = state.players[state.current_player_uid].hand_uid
    transition.poolToHand(state, conf, elem_uid, hand_uid, 1, function()
        transition.handToBoard(state, conf, hand_uid, elem_uid, 1, 1, 15)
    end)
end

return tests
