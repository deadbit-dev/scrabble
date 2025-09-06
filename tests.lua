local board = import("board")
local hand = import("hand")
local element = import("element")
local transition = import("transition")
local timer = import("timer")
local log = import("log")

local tests = {}

---Adds test elements to the board
---@param game Game
function tests.addElementToBoard(game)
    board.addElement(game, 6, 8, element.create(game, "H"))
    board.addElement(game, 7, 8, element.create(game, "E"))
    board.addElement(game, 8, 8, element.create(game, "L"))
    board.addElement(game, 9, 8, element.create(game, "L"))
    board.addElement(game, 10, 8, element.create(game, "O"))
    board.addElement(game, 10, 7, element.create(game, "W"))
    board.addElement(game, 10, 9, element.create(game, "R"))
    board.addElement(game, 10, 10, element.create(game, "L"))
    board.addElement(game, 10, 11, element.create(game, "D"))
end

function tests.transition(game)
    local elem_uid = element.create(game, "A")
    local hand_uid = game.state.players[game.state.current_player_uid].hand_uid
    transition.poolToHand(game, elem_uid, hand_uid, 1, function()
        -- timer.delay(game.state, 0.25, function()
        transition.handToBoard(game, hand_uid, elem_uid, 1, 1, 15)
        -- end)
    end)
end

return tests
