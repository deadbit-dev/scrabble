local log = import("log")
local board = import("board")
local hand = import("hand")
local element = import("element")

local space = {}

---Moves an element from one space to another
---@param game Game
---@param elem_uid number
---@param from_space SpaceInfo
---@param to_space SpaceInfo
function space.updateData(game, elem_uid, from_space, to_space)
    -- Remove element from source space
    if from_space.type == "board" then
        board.removeElement(game, from_space.data.x, from_space.data.y)
    elseif from_space.type == "hand" then
        hand.removeElem(game, from_space.data.hand_uid, from_space.data.index)
    end
    -- Note: screen space doesn't need removal as it's not tracked in state

    -- Add element to target space
    if to_space.type == "board" then
        board.addElement(game, to_space.data.x, to_space.data.y, elem_uid)
    elseif to_space.type == "hand" then
        hand.addElem(game, to_space.data.hand_uid, to_space.data.index, elem_uid)
    end
    -- Note: screen space doesn't need addition as it's not tracked in state
end

---Gets the world transform in screen space
---@param game Game
---@param x number
---@param y number
---@return Transform
function space.getWorldTransformInScreenSpace(game, x, y)
    local conf = game.conf
    return {
        x = x,
        y = y,
        width = conf.text.screen.base_size,
        height = conf.text.screen.base_size,
        z_index = 10
    }
end

---Calculates world transform from space info
---@param game Game
---@param spaceInfo SpaceInfo
---@return Transform
function space.getWorldTransformFromSpaceInfo(game, spaceInfo)
    -- NOTE: screen is default space info, nothing converts
    local worldTransform = space.getWorldTransformInScreenSpace(game, spaceInfo.data.x, spaceInfo.data.y)

    if (spaceInfo.type == "board") then
        worldTransform = board.getWorldTransformInBoardSpace(game, spaceInfo.data.x, spaceInfo.data.y)
    elseif (spaceInfo.type == "hand") then
        worldTransform = hand.getWorldTransformInHandSpace(game, spaceInfo.data.hand_uid, spaceInfo.data.index)
    end

    return worldTransform
end

---Gets the space type by position
---@param game Game
---@param x number
---@param y number
---@return SpaceType
function space.getSpaceTypeByPosition(game, x, y)
    -- NOTE: Check if point is in board area
    log.log("x: " .. x .. ", y: " .. y)
    print("isInBoardArea: ", space.isInBoardArea(game, x, y))
    if space.isInBoardArea(game, x, y) then
        return "board"
    end

    -- NOTE: Check if point is in hand area
    if space.isInHandArea(game, x, y) then
        return "hand"
    end

    -- NOTE: If not in any specific area, it's in screen space
    return "screen"
end

---Checks if point is in board area
---@param game Game
---@param x number
---@param y number
---@return boolean
function space.isInBoardArea(game, x, y)
    local board_transform = board.getWorldTransform(game)
    return x >= board_transform.x and x <= board_transform.x + board_transform.width and
        y >= board_transform.y and y <= board_transform.y + board_transform.height
end

---Checks if point is in hand area
---@param game Game
---@param x number
---@param y number
---@return boolean
function space.isInHandArea(game, x, y)
    local hand_transform = hand.getWorldTransform(game)
    return x >= hand_transform.x and x <= hand_transform.x + hand_transform.width and
        y >= hand_transform.y and y <= hand_transform.y + hand_transform.height
end

---Gets the board position by world position
---@param game Game
---@param x number
---@param y number
---@return {x: number, y: number}|nil
function space.getBoardPosByWorldPos(game, x, y)
    -- Check if point is within board boundaries
    if not space.isInBoardArea(game, x, y) then
        return nil
    end

    local conf = game.conf
    local layout = board.getLayout(conf)
    local transform = board.getWorldTransform(game)

    -- Calculate relative position within board area
    local relX = x - (transform.x + layout.fieldGaps.left)
    local relY = y - (transform.y + layout.fieldGaps.top)

    -- Calculate cell size including gap
    local cellSizeWithGap = layout.cellSize + layout.cellGap

    -- Calculate board coordinates (1-based) using round for better snapping
    local boardX = math.floor(relX / cellSizeWithGap) + 1
    local boardY = math.floor(relY / cellSizeWithGap) + 1

    -- Clamp coordinates to valid range (1 to field size)
    boardX = math.max(1, math.min(conf.field.size, boardX))
    boardY = math.max(1, math.min(conf.field.size, boardY))

    return { x = boardX, y = boardY }
end

---Sets an element's space and transform
---@param game Game
---@param elem_uid number
---@param space_info SpaceInfo
function space.set_space(game, elem_uid, space_info)
    local current_space = element.get_space(game, elem_uid)

    element.set_space(game, elem_uid, space_info)
    element.set_transform(game, elem_uid, space.getWorldTransformFromSpaceInfo(game, space_info))

    space.updateData(game, elem_uid, current_space, space_info)
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
