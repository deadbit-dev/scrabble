local hand = import("hand")
local element = import("element")

local player = {}

---@param game Game
function player.init(game)
    local state = game.state
    local player_uid = generate_uid()
    local hand_uid = hand.init(game)
    state.players[player_uid] = { uid = player_uid, hand_uid = hand_uid, points = 0 }
    state.current_player_uid = player_uid

    hand.addElem(game, hand_uid, 1, element.create(game, "A"))
    hand.addElem(game, hand_uid, 2, element.create(game, "B"))
    hand.addElem(game, hand_uid, 3, element.create(game, "C"))
    hand.addElem(game, hand_uid, 4, element.create(game, "D"))
    hand.addElem(game, hand_uid, 5, element.create(game, "E"))
    hand.addElem(game, hand_uid, 6, element.create(game, "F"))
    hand.addElem(game, hand_uid, 7, element.create(game, "G"))
end

return player
