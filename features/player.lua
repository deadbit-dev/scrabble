local player = {}

---@class Player
---@field uid number
---@field hand_uid number
---@field points number


---@param hand_uid number
---@return Player
function player.create(hand_uid)
    local player_uid = GENERATE_UID()
    return { uid = player_uid, hand_uid = hand_uid, points = 0 }
end

return player
