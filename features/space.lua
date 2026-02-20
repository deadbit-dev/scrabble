local space = {}

local board = import("board")
local hand = import("hand")

---@enum SpaceType
SpaceType = {
    HAND = 1,
    BOARD = 2,
    SCREEN = 3
}

---@class SlotData
---@field hand_uid number
---@field index number

---@class SpaceInfo
---@field type SpaceType
---@field data Pos|SlotData

---@param state State
---@param from_space SpaceInfo
function space.remove_element_from_space(state, from_space)
    -- NOTE: remove element from source space
    if from_space.type == SpaceType.BOARD then
        board.remove_element(state.board, from_space.data.x, from_space.data.y)
    elseif from_space.type == SpaceType.HAND then
        hand.remove_element(state.hands[from_space.data.hand_uid], from_space.data.index)
    end
    -- NOTE: screen space doesn't need removal as it's not tracked in state
end

---@param state State
---@param elem_uid number
---@param to_space SpaceInfo
function space.add_element_to_space(state, elem_uid, to_space)
    -- NOTE: add element to target space
    -- NOTE: screen space doesn't need addition as it's not tracked in state
    if to_space.type == SpaceType.BOARD then
        board.add_element(state.board, to_space.data.x, to_space.data.y, elem_uid)
    elseif to_space.type == SpaceType.HAND then
        hand.add_element(state.hands[to_space.data.hand_uid], to_space.data.index, elem_uid)
    end

    state.elements[elem_uid].space = to_space
end

---@param conf Config
---@param x number
---@param y number
---@return Transform
function space.get_world_transform_in_screen_space(conf, x, y)
    return {
        x = x,
        y = y,
        width = conf.text.screen.base_size,
        height = conf.text.screen.base_size,
        z_index = 10
    }
end

---@param state State
---@param conf Config
---@param space_info SpaceInfo
---@return Transform
function space.get_space_transform(state, conf, space_info)
    if (space_info.type == SpaceType.BOARD) then
        return board.get_space_transform(state.board, conf.field, space_info.data.x, space_info.data.y)
    end

    if (space_info.type == SpaceType.HAND) then
        return hand.get_world_transform_in_hand_space(state.hands[space_info.data.hand_uid], conf, space_info.data.index)
    end

    -- NOTE: screen is default space info, nothing converts
    return space.get_world_transform_in_screen_space(conf, space_info.data.x, space_info.data.y)
end

---@param state State
---@param conf Config
---@param x number
---@param y number
---@return SpaceType
function space.get_space_type_by_position(state, conf, x, y)
    -- NOTE: check if point is in board area
    if space.is_in_board_area(state.board, conf.field, x, y) then
        return SpaceType.BOARD
    end

    -- NOTE: check if point is in hand area
    if space.is_in_hand_area(state, conf, x, y) then
        return SpaceType.HAND
    end

    -- NOTE: if not in any specific area, it's in screen space
    return SpaceType.SCREEN
end

---@param state Board
---@param conf FieldConfig
---@param x number
---@param y number
---@return boolean
function space.is_in_board_area(state, conf, x, y)
    return x >= state.transform.x and x <= state.transform.x + state.transform.width and
        y >= state.transform.y and y <= state.transform.y + state.transform.height
end

---@param state State
---@param conf Config
---@param x number
---@param y number
---@return boolean
function space.is_in_hand_area(state, conf, x, y)
    local hand_transform = hand.get_world_transform(conf)
    return x >= hand_transform.x and x <= hand_transform.x + hand_transform.width and
        y >= hand_transform.y and y <= hand_transform.y + hand_transform.height
end

---@param state Board
---@param conf FieldConfig
---@param x number
---@param y number
---@return Pos|nil
function space.get_board_pos_by_world_pos(state, conf, x, y)
    -- NOTE: check if point is within board boundaries
    if not space.is_in_board_area(state, conf, x, y) then
        return nil
    end

    local layout = board.get_layout(state, conf)

    -- NOTE: calculate relative position within board area
    local relX = x - (state.transform.x + layout.fieldGaps.left)
    local relY = y - (state.transform.y + layout.fieldGaps.top)

    -- NOTE: calculate cell size including gap
    local cell_size_with_gap = layout.cellSize + layout.cellGap

    -- NOTE: calculate board coordinates (1-based) using round for better snapping
    local boardX = math.floor(relX / cell_size_with_gap) + 1
    local boardY = math.floor(relY / cell_size_with_gap) + 1

    -- NOTE: clamp coordinates to valid range (1 to field size)
    boardX = math.max(1, math.min(conf.size, boardX))
    boardY = math.max(1, math.min(conf.size, boardY))

    return { x = boardX, y = boardY }
end

---@param x number
---@param y number
---@return SpaceInfo
function space.board(x, y)
    return {
        type = SpaceType.BOARD,
        data = { x = x, y = y }
    }
end

---@param hand_uid number
---@param index number
---@return SpaceInfo
function space.hand(hand_uid, index)
    return {
        type = SpaceType.HAND,
        data = { hand_uid = hand_uid, index = index }
    }
end

return space
