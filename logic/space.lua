local Space = {}

---Moves an element from one space to another
---@param game Game
---@param elem_uid number
---@param from_space SpaceInfo
---@param to_space SpaceInfo
function Space.updateData(game, elem_uid, from_space, to_space)
    local Board = game.logic.Board
    local HandManager = game.logic.HandManager

    -- Remove element from source space
    if from_space.type == "board" then
        Board.remove_element(game, from_space.data.x, from_space.data.y)
    elseif from_space.type == "hand" then
        HandManager.remove_element(game, from_space.data.hand_uid, from_space.data.index)
    end
    -- Note: screen space doesn't need removal as it's not tracked in state

    -- Add element to target space
    if to_space.type == "board" then
        Board.add_element(game, to_space.data.x, to_space.data.y, elem_uid)
    elseif to_space.type == "hand" then
        HandManager.add_element(game, to_space.data.hand_uid, to_space.data.index, elem_uid)
    end
    -- Note: screen space doesn't need addition as it's not tracked in state
end

---Gets the world transform in screen space
---@param game Game
---@param x number
---@param y number
---@return Transform
function Space.get_world_transform_in_screen_space(game, x, y)
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
function Space.get_world_transform_from_space_info(game, spaceInfo)
    local Board = game.logic.Board
    local HandManager = game.logic.HandManager

    -- NOTE: screen is default space info, nothing converts
    local worldTransform = Space.get_world_transform_in_screen_space(game, spaceInfo.data.x, spaceInfo.data.y)

    if (spaceInfo.type == "board") then
        worldTransform = Board.get_world_transform_in_board_space(game, spaceInfo.data.x, spaceInfo.data.y)
    elseif (spaceInfo.type == "hand") then
        worldTransform = HandManager.get_world_transform_in_hand_space(game, spaceInfo.data.hand_uid,
            spaceInfo.data.index)
    end

    return worldTransform
end

---Gets the space type by position
---@param game Game
---@param x number
---@param y number
---@return SpaceType
function Space.get_space_type_by_position(game, x, y)
    -- NOTE: Check if point is in board area
    if Space.is_in_board_area(game, x, y) then
        return "board"
    end

    -- NOTE: Check if point is in hand area
    if Space.is_in_hand_area(game, x, y) then
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
function Space.is_in_board_area(game, x, y)
    local Board = game.logic.Board

    local board_transform = Board.get_world_transform(game)
    return x >= board_transform.x and x <= board_transform.x + board_transform.width and
        y >= board_transform.y and y <= board_transform.y + board_transform.height
end

---Checks if point is in hand area
---@param game Game
---@param x number
---@param y number
---@return boolean
function Space.is_in_hand_area(game, x, y)
    local HandManager = game.logic.HandManager

    local hand_transform = HandManager.get_world_transform(game)
    return x >= hand_transform.x and x <= hand_transform.x + hand_transform.width and
        y >= hand_transform.y and y <= hand_transform.y + hand_transform.height
end

---Gets the board position by world position
---@param game Game
---@param x number
---@param y number
---@return {x: number, y: number}|nil
function Space.get_board_pos_by_world_pos(game, x, y)
    local conf = game.conf
    local Board = game.logic.Board

    -- Check if point is within board boundaries
    if not Space.is_in_board_area(game, x, y) then
        return nil
    end

    local layout = Board.get_layout(game)
    local transform = Board.get_world_transform(game)

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
function Space.set_space(game, elem_uid, space_info)
    local ElementsManager = game.logic.ElementsManager
    local current_space = ElementsManager.get_space(game, elem_uid)

    ElementsManager.set_space(game, elem_uid, space_info)
    ElementsManager.set_transform(game, elem_uid, Space.get_world_transform_from_space_info(game, space_info))

    Space.updateData(game, elem_uid, current_space, space_info)
end

---Creates a screen space info
---@param x number
---@param y number
---@return SpaceInfo
function Space.create_screen_space(x, y)
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
function Space.create_board_space(x, y)
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
function Space.create_hand_space(hand_uid, index)
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
function Space.equals(space1, space2)
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

return Space
