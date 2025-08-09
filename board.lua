local resources = import("resources")

local board = {}

---@param state State
---@param uid number
---@return Cell
function board.getCell(state, uid)
    return state.cells[uid]
end

---@param state State
---@param uid number
---@return Element
function board.getElem(state, uid)
    return state.elements[uid]
end

---@param state State
---@param x number
---@param y number
---@return Cell
function board.getBoardCellUID(state, x, y)
    return board.getCell(state, state.board.cell_uids[x][y])
end

---@param state State
---@param x number
---@param y number
---@return Element
function board.getBoardElemUID(state, x, y)
    return board.getElem(state, state.board.elem_uids[x][y])
end

---@param x number
---@param y number
---@param dimensions table
---@return XYData
function board.getWorldPosInBoardSpace(x, y, dimensions)
    return {
        x = dimensions.startX + dimensions.fieldGaps.left +
            (x - 1) * (dimensions.cellSize + dimensions.cellGap),
        y = dimensions.startY + dimensions.fieldGaps.top + (y - 1) * (dimensions.cellSize + dimensions.cellGap)
    }
end

---Calculates board dimensions and positions based on window size and configuration
---@param conf Config
---@return table containing all calculated dimensions and positions
function board.getBoardDimensions(conf)
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()

    -- NOTE: Calculate the total available space for the board using percentage-based padding
    local availableWidth = windowWidth * (1 - (conf.window.padding.left + conf.window.padding.right))
    local availableHeight = windowHeight * (1 - (conf.window.padding.top + conf.window.padding.bottom))

    -- NOTE: Limit the board size to the maximum allowed size
    if (conf.field.max_size.width < availableWidth) then
        availableWidth = conf.field.max_size.width
    end

    if (conf.field.max_size.height < availableHeight) then
        availableHeight = conf.field.max_size.height
    end

    -- NOTE: Calculate the space needed for all gaps
    local totalCellGaps = conf.field.size - 1
    local cellSize = math.min(
        availableWidth /
        (conf.field.size + (conf.field.size - 1) * conf.field.cell_gap_ratio + conf.field.gap_ratio.left + conf.field.gap_ratio.right),
        availableHeight /
        (conf.field.size + (conf.field.size - 1) * conf.field.cell_gap_ratio + conf.field.gap_ratio.top + conf.field.gap_ratio.bottom)
    )
    local cellGap = cellSize * conf.field.cell_gap_ratio
    local fieldGaps = {
        top = cellSize * conf.field.gap_ratio.top,
        bottom = cellSize * conf.field.gap_ratio.bottom,
        left = cellSize * conf.field.gap_ratio.left,
        right = cellSize * conf.field.gap_ratio.right
    }

    local totalHorizontalGaps = (cellGap * totalCellGaps) + fieldGaps.left + fieldGaps.right
    local totalVerticalGaps = (cellGap * totalCellGaps) + fieldGaps.top + fieldGaps.bottom

    -- NOTE: Calculate total board size including gaps
    local boardWidth = (cellSize * conf.field.size) + totalHorizontalGaps
    local boardHeight = (cellSize * conf.field.size) + totalVerticalGaps

    -- NOTE: Calculate starting position to center the board
    local startX = (windowWidth / 2) - (boardWidth / 2)
    local startY = (windowHeight / 2) - (boardHeight / 2)

    return {
        cellSize = cellSize,
        cellGap = cellGap,
        fieldGaps = fieldGaps,
        boardWidth = boardWidth,
        boardHeight = boardHeight,
        startX = startX,
        startY = startY
    }
end

return board
