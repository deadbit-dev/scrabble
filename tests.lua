local Tests = {}

---Adds test elements to the board
---@param game Game
function Tests.add_element_to_board(game)
    game.logic.board.add_element(game, 6, 8, game.logic.element_manager.create(game, "H"))
    game.logic.board.add_element(game, 7, 8, game.logic.element_manager.create(game, "E"))
    game.logic.board.add_element(game, 8, 8, game.logic.element_manager.create(game, "L"))
    game.logic.board.add_element(game, 9, 8, game.logic.element_manager.create(game, "L"))
    game.logic.board.add_element(game, 10, 8, game.logic.element_manager.create(game, "O"))
    game.logic.board.add_element(game, 10, 7, game.logic.element_manager.create(game, "W"))
    game.logic.board.add_element(game, 10, 9, game.logic.element_manager.create(game, "R"))
    game.logic.board.add_element(game, 10, 10, game.logic.element_manager.create(game, "L"))
    game.logic.board.add_element(game, 10, 11, game.logic.element_manager.create(game, "D"))
end

function Tests.transition(game)
    local elem_uid = game.logic.element_manager.create(game, "A")
    local hand_uid = game.state.players[game.state.current_player_uid].hand_uid
    game.logic.transition_manager.poolToHand(game, elem_uid, hand_uid, 1, function()
        game.logic.transition_manager.handToBoard(game, hand_uid, elem_uid, 1, 1, 15)
    end)
end

return Tests
