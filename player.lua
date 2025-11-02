local player = {}

local system = import("core.system")
local hand = import("hand")
local element = import("element")

---Инициализирует игрока
---@param state State
---@param conf Config
function player.init(state, conf)
    local player_uid = system.generate_uid()
    local hand_uid = hand.init(state)
    state.players[player_uid] = { uid = player_uid, hand_uid = hand_uid, points = 0 }
    state.current_player_uid = player_uid

    -- NOTE: for test
    hand.add_element(state, hand_uid, 1, element.create(state, conf, "A"))
    hand.add_element(state, hand_uid, 2, element.create(state, conf, "B"))
    hand.add_element(state, hand_uid, 3, element.create(state, conf, "C"))
    hand.add_element(state, hand_uid, 4, element.create(state, conf, "D"))
    hand.add_element(state, hand_uid, 5, element.create(state, conf, "E"))
    hand.add_element(state, hand_uid, 6, element.create(state, conf, "F"))
    hand.add_element(state, hand_uid, 7, element.create(state, conf, "G"))
end

return player
