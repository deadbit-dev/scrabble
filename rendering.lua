local resources = require("resources")
local utils = require("utils")

local rendering = {}

---Calculates board dimensions and positions based on window size and configuration
---@param conf Config
---@return table containing all calculated dimensions and positions
function rendering.calculateBoardDimensions(conf)
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

---Draws the board background
---@param conf Config
---@param dimensions table containing board dimensions and positions
function rendering.drawBoardBg(conf, dimensions)
    love.graphics.setColor(conf.colors.white)
    love.graphics.draw(resources.textures.field_black, dimensions.startX, dimensions.startY, 0,
        dimensions.boardWidth / resources.textures.field_black:getWidth(),
        dimensions.boardHeight / resources.textures.field_black:getHeight())
end

---Draws a single cell with its shadow and multiplier
---@param conf Config
---@param x number X position of the cell
---@param y number Y position of the cell
---@param cellSize number Size of the cell
---@param cell Cell
function rendering.drawCell(conf, x, y, cellSize, cell)
    -- NOTE: draw cell
    if resources.textures.cell then
        love.graphics.setColor(conf.field.cell_colors.multiplier[cell.multiplier])
        love.graphics.draw(resources.textures.cell, x, y, 0, cellSize / resources.textures.cell:getWidth(),
            cellSize / resources.textures.cell:getHeight())
    end

    -- NOTE: draw cell shadow
    if resources.textures.cell_shadow then
        love.graphics.setColor(conf.field.cell_colors.shadow)
        love.graphics.draw(resources.textures.cell_shadow, x, y, 0,
            cellSize / resources.textures.cell_shadow:getWidth(),
            cellSize / resources.textures.cell_shadow:getHeight())
    end

    -- NOTE: draw multiplier if greater than 1
    if cell.multiplier > 1 then
        -- NOTE: draw cross
        if resources.textures.cross then
            local cross_scale = (cellSize * conf.text.letter_scale_factor * 0.4) /
                math.max(resources.textures.cross:getWidth(), resources.textures.cross:getHeight())

            local posX = (x + cellSize / 2) - cross_scale * resources.textures.cross:getWidth() / 2 - cellSize * 0.2
            local posY = (y + cellSize / 2) - cross_scale * resources.textures.cross:getHeight() / 2
            love.graphics.setColor(conf.text.colors.multiplier[cell.multiplier])
            love.graphics.draw(resources.textures.cross, posX, posY, 0, cross_scale, cross_scale)
        end

        -- NOTE: draw multiplier number
        love.graphics.setColor(conf.text.colors.multiplier[cell.multiplier])
        love.graphics.setFont(resources.fonts.default)

        local font = love.graphics.getFont()
        local multiplierText = tostring(cell.multiplier)
        local multiplierWidth = font:getWidth(multiplierText)
        local multiplierHeight = font:getHeight()
        local multiplier_scale = (cellSize * conf.text.letter_scale_factor) / multiplierHeight

        love.graphics.push()
        love.graphics.scale(multiplier_scale)
        local scaledX = (x + (cellSize - multiplierWidth * multiplier_scale) / 2 + cellSize * 0.25 - cellSize * conf.text.offset) /
            multiplier_scale
        local scaledY = (y + (cellSize - multiplierHeight * multiplier_scale) / 2 - cellSize * conf.text.offset + cellSize * 0.1) /
            multiplier_scale
        love.graphics.print(multiplierText, scaledX, scaledY)
        love.graphics.pop()
    end
end

---Draws a game element (letter and points)
---@param conf Config
---@param x number X position of the cell
---@param y number Y position of the cell
---@param cellSize number Size of the cell
---@param element table Element data containing letter and points
function rendering.drawElem(conf, x, y, cellSize, element)
    if not element then return end

    love.graphics.setColor(conf.colors.white)
    love.graphics.draw(resources.textures.element, x, y, 0, cellSize / resources.textures.element:getWidth(),
        cellSize / resources.textures.element:getHeight())

    love.graphics.setColor(conf.text.colors.element)
    love.graphics.setFont(resources.fonts.default)

    local font = love.graphics.getFont()
    local textWidth = font:getWidth(element.letter)
    local textHeight = font:getHeight()

    -- NOTE: calculate scale based on cell size
    local letter_scale = (cellSize * conf.text.letter_scale_factor) / textHeight
    local point_scale = letter_scale * conf.text.point_scale_factor

    -- NOTE: draw letter
    love.graphics.push()
    love.graphics.scale(letter_scale)
    local scaledX = (x + (cellSize - textWidth * letter_scale) / 2 - cellSize * conf.text.offset) / letter_scale
    local scaledY = (y + (cellSize - textHeight * letter_scale) / 2 - cellSize * conf.text.offset) / letter_scale
    love.graphics.print(element.letter, scaledX, scaledY)
    love.graphics.pop()

    -- NOTE: draw points
    local pointsText = tostring(element.points)
    local pointsWidth = font:getWidth(pointsText)
    local pointsHeight = font:getHeight()

    love.graphics.push()
    love.graphics.scale(point_scale)
    local scaledPointsX = (x + cellSize - pointsWidth * point_scale - cellSize * conf.text.offset) / point_scale
    local scaledPointsY = (y + cellSize - pointsHeight * point_scale - cellSize * conf.text.offset) / point_scale
    love.graphics.print(pointsText, scaledPointsX, scaledPointsY)
    love.graphics.pop()
end

---Draws the game board and all its elements
---@param conf Config
---@param state State
function rendering.draw(conf, state)
    love.graphics.clear(conf.colors.background)

    local dimensions = rendering.calculateBoardDimensions(conf)
    rendering.drawBoardBg(conf, dimensions)

    -- NOTE: draw cells and their contents
    for i = 1, conf.field.size do
        for j = 1, conf.field.size do
            -- NOTE: calculate position with gaps
            local x = dimensions.startX + dimensions.fieldGaps.left +
                (j - 1) * (dimensions.cellSize + dimensions.cellGap)
            local y = dimensions.startY + dimensions.fieldGaps.top + (i - 1) * (dimensions.cellSize + dimensions.cellGap)

            rendering.drawCell(conf, x, y, dimensions.cellSize, utils.getBoardCell(state, i, j))
            rendering.drawElem(conf, x, y, dimensions.cellSize, utils.getBoardElem(state, i, j))
        end
    end
end

return rendering
