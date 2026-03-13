local player = {}

---@class Player
---@field uid number
---@field hand_uid number
---@field points number
---@field pending_points number
---@field name string


---@param hand_uid number
---@param name string
---@return Player
function player.create(hand_uid, name)
    local player_uid = GENERATE_UID()
    return { uid = player_uid, hand_uid = hand_uid, points = 0, pending_points = 0, name = name }
end

return player
