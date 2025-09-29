local Tests = require("../tests")

local Board = class("Board")

function Board:constructor(cell_manager, element_manager)
    self.cell_manager = cell_manager
    self.element_manager = element_manager
end

---Initializes the game board by creating empty cells with multipliers
---@param game Game
function Board.init(game)
    for i = 1, game.conf.field.size do
        game.state.board.cell_uids[i] = {}
        game.state.board.elem_uids[i] = {}
        for j = 1, game.conf.field.size do
            Board.add_cell(game, i, j, self.cell_manager.create(game, game.conf.field.multipliers[i][j]))
        end
    end

    -- Tests.add_element_to_board(game)
end

---Updates transforms for all elements on the board
---@param game Game
local function update_elements_transform(game)
    local conf = game.conf

    for j = 1, conf.field.size do
        for i = 1, conf.field.size do
            local element_uid = Board.get_board_elem_uid(game, i, j)
            if element_uid then
                local element_data = self.element_manager.get_state(game, element_uid)
                if element_data then
                    element_data.transform = Board.get_world_transform_in_board_space(game, i, j)
                end
            end
        end
    end
end

---Updates the board
---@param game Game
---@param dt number
function Board.update(game, dt)
    game.state.board.transform = Board.get_world_transform(game)
    Board.update_elements_transform(game)
end

---Draws the board background
---@param conf Config
---@param transform Transform
local function draw_bg(conf, resources, transform)
    if (not resources.textures.field) then
        return
    end

    love.graphics.setColor(conf.colors.black)
    love.graphics.draw(resources.textures.field, transform.x, transform.y, 0,
        transform.width / resources.textures.field:getWidth(),
        transform.height / resources.textures.field:getHeight())
end

function Board.draw(game)
    local conf = game.conf
    local state = game.state
    local resources = game.resources

    draw_bg(conf, resources, state.board.transform)

    -- TODO: separate cells rendering too
    for i = 1, conf.field.size do
        for j = 1, conf.field.size do
            local cell_uid = Board.get_board_cell_uid(game, j, i)
            if cell_uid then
                local cell_data = cell_manager.get(game, cell_uid)
                local transform = Board.get_world_transform_in_board_space(game, j, i)
                local cell_size = math.min(transform.width, transform.height)
                cell_manager.cell_draw(game, transform.x, transform.y, cell_size, cell_data)
            end
        end
    end
end

---@param game Game
---@param x number
---@param y number
---@return number
function Board.get_board_cell_uid(game, x, y)
    return game.state.board.cell_uids[x][y]
end

---Sets a cell on the board
---@param game Game
---@param x number
---@param y number
---@param cell_uid number
function Board.add_cell(game, x, y, cell_uid)
    game.state.board.cell_uids[x][y] = cell_uid
end

---@param game Game
---@param x number
---@param y number
---@return number
function Board.get_board_elem_uid(game, x, y)
    return game.state.board.elem_uids[x][y]
end

---Sets an element on the board
---@param game Game
---@param x number
---@param y number
---@param elem_uid number
function Board.add_element(game, x, y, elem_uid)
    game.state.board.elem_uids[x][y] = elem_uid
    ElementManager.set_space(game, elem_uid, {
        type = SpaceType.BOARD,
        data = {
            x = x,
            y = y
        }
    })
end

---Removes an element from the board
---@param state State
---@param x number
---@param y number
function Board.remove_element(game, x, y)
    local elem_uid = game.state.board.elem_uids[x][y]
    if elem_uid then
        game.state.board.elem_uids[x][y] = nil
    end
end

---Calculates board cell layout
---@param game Game
---@return table containing cellSize, cellGap, and fieldGaps
function Board.get_layout(game)
    local conf = game.conf

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

    return {
        cellSize = cellSize,
        cellGap = cellGap,
        fieldGaps = fieldGaps
    }
end

---Calculates board world transform based on window size and configuration
---@param game Game
---@return Transform
function Board.get_world_transform(game)
    local conf = game.conf

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
        x = startX,
        y = startY,
        width = boardWidth,
        height = boardHeight,
        z_index = 0
    }
end

---@param game Game
---@param x number
---@param y number
---@return Transform
function Board.get_world_transform_in_board_space(game, x, y)
    local layout = Board.get_layout(game)
    local transform = Board.get_world_transform(game)
    return {
        x = transform.x + layout.fieldGaps.left +
            (x - 1) * (layout.cellSize + layout.cellGap),
        y = transform.y + layout.fieldGaps.top + (y - 1) * (layout.cellSize + layout.cellGap),
        width = layout.cellSize,
        height = layout.cellSize,
        z_index = -2
    }
end

return Board
