local board = import("board")
local hand = import("hand")
local element = import("element")

local space = {}

---Calculates world transform from space info
---@param game Game
---@param spaceInfo SpaceInfo
---@return table
function space.getWorldTransformFromSpaceInfo(game, spaceInfo)
    local conf = game.conf

    -- NOTE: screen is default space info, nothing converts
    local worldTransform = {
        position = { x = spaceInfo.data.x, y = spaceInfo.data.y },
        width = conf.text.screen.base_size,
        height = conf.text.screen.base_size,
        z_index = 0
    }

    if (spaceInfo.type == "board") then
        worldTransform = board.getWorldTransformInBoardSpace(conf, spaceInfo.data.x, spaceInfo.data.y)
    elseif (spaceInfo.type == "hand") then
        worldTransform = hand.getWorldTransformInHandSpace(game, spaceInfo.data.hand_uid, spaceInfo.data.index)
    end

    return worldTransform
end

function space.set_space(game, elem_uid, space_info)
    element.set_space(game, elem_uid, space_info)
    element.set_transform(game, elem_uid, space.getWorldTransformFromSpaceInfo(game, space_info))
end

---Creates a screen space info
---@param x number
---@param y number
---@return SpaceInfo
function space.createScreenSpace(x, y)
    return {
        type = "screen",
        data = {
            x = x,
            y = y
        }
    }
end

---Creates a board space info
---@param x number
---@param y number
---@return SpaceInfo
function space.createBoardSpace(x, y)
    return {
        type = "board",
        data = {
            x = x,
            y = y
        }
    }
end

---Creates a hand space info
---@param hand_uid number
---@param index number
---@return SpaceInfo
function space.createHandSpace(hand_uid, index)
    return {
        type = "hand",
        data = {
            hand_uid = hand_uid,
            index = index
        }
    }
end

---Checks if two space infos are equal
---@param space1 SpaceInfo
---@param space2 SpaceInfo
---@return boolean
function space.equals(space1, space2)
    if space1.type ~= space2.type then
        return false
    end

    if space1.type == "screen" or space1.type == "board" then
        return space1.data.x == space2.data.x and space1.data.y == space2.data.y
    elseif space1.type == "hand" then
        return space1.data.hand_uid == space2.data.hand_uid and space1.data.index == space2.data.index
    end

    return false
end

return space
