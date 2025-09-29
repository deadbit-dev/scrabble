local PlayerManager = {}

---@param game Game
function PlayerManager.init(game)
    local state = game.state
    local HandManager = game.logic.HandManager
    local ElementsManager = game.logic.ElementsManager

    local player_uid = game.engine.generate_uid()
    local hand_uid = HandManager.init(game)
    state.players[player_uid] = { uid = player_uid, hand_uid = hand_uid, points = 0 }
    state.current_player_uid = player_uid

    -- NOTE: for test
    HandManager.add_element(game, hand_uid, 1, ElementsManager.create(game, "A"))
    HandManager.add_element(game, hand_uid, 2, ElementsManager.create(game, "B"))
    HandManager.add_element(game, hand_uid, 3, ElementsManager.create(game, "C"))
    HandManager.add_element(game, hand_uid, 4, ElementsManager.create(game, "D"))
    HandManager.add_element(game, hand_uid, 5, ElementsManager.create(game, "E"))
    HandManager.add_element(game, hand_uid, 6, ElementsManager.create(game, "F"))
    HandManager.add_element(game, hand_uid, 7, ElementsManager.create(game, "G"))
end

return PlayerManager
