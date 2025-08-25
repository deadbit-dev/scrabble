local resources = import("resources")
local cell = import("cell")
local element = import("element")

local board = {}

---@param state State
---@param x number
---@param y number
---@return Cell
function board.getBoardCellUID(game, x, y)
    local state = game.state
    return state.board.cell_uids[x][y]
end

---Sets a cell on the board
---@param state State
---@param x number
---@param y number
---@param cell_uid number
function board.addCell(game, x, y, cell_uid)
    local state = game.state
    state.board.cell_uids[x][y] = cell_uid
end

---@param state State
---@param x number
---@param y number
---@return Element
function board.getBoardElemUID(game, x, y)
    local state = game.state
    return state.board.elem_uids[x][y]
end


---Sets an element on the board
---@param state State
---@param x number
---@param y number
---@param elem_uid number
function board.addElement(game, x, y, elem_uid)
    local state = game.state
    state.board.elem_uids[x][y] = elem_uid
end

---Removes an element from the board
---@param state State
---@param x number
---@param y number
function board.removeElement(game, x, y)
    local state = game.state
    local elem_uid = state.board.elem_uids[x][y]
    if elem_uid then
        state.board.elem_uids[x][y] = nil
    end
end

---Initializes the game board by creating empty cells with multipliers
---@param conf Config
---@param state State
function board.init(game)
    local conf = game.conf
    local state = game.state
    for i = 1, conf.field.size do
        state.board.cell_uids[i] = {}
        state.board.elem_uids[i] = {}
        for j = 1, conf.field.size do
            board.addCell(game, i, j, cell.create(game, conf.field.multipliers[i][j]))
        end
    end
end

---Calculates board dimensions and positions based on window size and configuration
---@param conf Config
---@return table containing all calculated dimensions and positions
function board.getDimensions(conf)
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

---Updates the board
---@param game Game
---@param dt number
function board.update(game, dt)
    local conf = game.conf
    local dimensions = board.getDimensions(conf)
    
    board.updateTransform(game, dimensions)
    board.updateElementsTransform(game, dimensions)
end

---Updates board transform based on current window size
---@param game Game
---@param dimensions table
function board.updateTransform(game, dimensions)
    local state = game.state
    
    state.board.transform = {
        x = dimensions.startX,
        y = dimensions.startY,
        width = dimensions.boardWidth,
        height = dimensions.boardHeight
    }
end

---Updates transforms for all elements on the board
---@param game Game
---@param dimensions table
function board.updateElementsTransform(game, dimensions)
    local conf = game.conf
    local state = game.state
    
    for j = 1, conf.field.size do
        for i = 1, conf.field.size do
            local element_uid = board.getBoardElemUID(game, i, j)
            if element_uid then
                local elem = element.get(game, element_uid)
                if elem then
                    elem.transform = board.getWorldTransformInBoardSpace(conf, i, j)
                    elem.z_index = -2
                end
            end
        end
    end
end

---Draws the board background
---@param conf Config
---@param transform Transform
local function drawBg(conf, transform)
    if (not resources.textures.field) then
        return
    end

    love.graphics.setColor(conf.colors.black)
    love.graphics.draw(resources.textures.field, transform.x, transform.y, 0,
        transform.width / resources.textures.field:getWidth(),
        transform.height / resources.textures.field:getHeight())
end

function board.draw(game)
    local conf = game.conf
    local state = game.state
    
    drawBg(conf, state.board.transform)
    
    for i = 1, conf.field.size do
        for j = 1, conf.field.size do
            local cell_uid = board.getBoardCellUID(game, j, i)
            if cell_uid then
                local cell_data = cell.get(game, cell_uid)
                local transform = board.getWorldTransformInBoardSpace(conf, j, i)
                local cell_size = math.min(transform.width, transform.height)
                cell.draw(game, transform.x, transform.y, cell_size, cell_data)
            end
        end
    end
end

---@param conf Config
---@param x number
---@param y number
---@return XYData
function board.getWorldTransformInBoardSpace(conf, x, y)
    local dimensions = board.getDimensions(conf)
    return {
        x = dimensions.startX + dimensions.fieldGaps.left +
            (x - 1) * (dimensions.cellSize + dimensions.cellGap),
        y = dimensions.startY + dimensions.fieldGaps.top + (y - 1) * (dimensions.cellSize + dimensions.cellGap),
        width = dimensions.cellSize,
        height = dimensions.cellSize,
        space = "board"
    }
end

return board
