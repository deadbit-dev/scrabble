local CellManager = {}

---Creates a cell
---@param game Game
---@param multiplier number
---@return number
function CellManager.create(game, multiplier)
    local cell_uid = game.engine.generate_uid()
    game.state.cells[cell_uid] = { uid = cell_uid, multiplier = multiplier }
    return cell_uid
end

---@param game Game
---@param uid number
---@return Cell
function CellManager.get(game, uid)
    return game.state.cells[uid]
end

---Removes a cell
---@param game Game
---@param cell_uid number
function CellManager.remove(game, cell_uid)
    game.state.cells[cell_uid] = nil
end

---@param game Game
---@param x number X position of the cell
---@param y number Y position of the cell
---@param cellSize number Size of the cell
---@param cell Cell
function CellManager.cell_draw(game, x, y, cellSize, cell)
    -- NOTE: draw cell
    if game.resources.textures.cell then
        love.graphics.setColor(game.conf.field.cell_colors.multiplier[cell.multiplier])
        love.graphics.draw(game.resources.textures.cell, x, y, 0, cellSize / game.resources.textures.cell:getWidth(),
            cellSize / game.resources.textures.cell:getHeight())
    end

    -- NOTE: draw cell shadow
    if game.resources.textures.cell_shadow then
        love.graphics.setColor(game.conf.field.cell_colors.shadow)
        love.graphics.draw(game.resources.textures.cell_shadow, x, y, 0,
            cellSize / game.resources.textures.cell_shadow:getWidth(),
            cellSize / game.resources.textures.cell_shadow:getHeight())
    end

    -- NOTE: draw multiplier if greater than 1
    if cell.multiplier > 1 then
        -- NOTE: draw cross
        if game.resources.textures.cross then
            local cross_scale = (cellSize * game.conf.text.letter_scale_factor * 0.4) /
                math.max(game.resources.textures.cross:getWidth(), game.resources.textures.cross:getHeight())

            local posX = (x + cellSize / 2) - cross_scale * game.resources.textures.cross:getWidth() / 2 - cellSize * 0.2
            local posY = (y + cellSize / 2) - cross_scale * game.resources.textures.cross:getHeight() / 2
            love.graphics.setColor(game.conf.text.colors.multiplier[cell.multiplier])
            love.graphics.draw(game.resources.textures.cross, posX, posY, 0, cross_scale, cross_scale)
        end

        -- NOTE: draw multiplier number
        love.graphics.setColor(game.conf.text.colors.multiplier[cell.multiplier])

        if (game.resources.fonts.default) then
            love.graphics.setFont(game.resources.fonts.default)
        end

        local font = love.graphics.getFont()
        local multiplierText = tostring(cell.multiplier)
        local multiplierWidth = font:getWidth(multiplierText)
        local multiplierHeight = font:getHeight()
        local multiplier_scale = (cellSize * game.conf.text.letter_scale_factor) / multiplierHeight

        love.graphics.push()
        love.graphics.scale(multiplier_scale)
        local scaledX = (x + (cellSize - multiplierWidth * multiplier_scale) / 2 + cellSize * 0.25 - cellSize * game.conf.text.offset) /
            multiplier_scale
        local scaledY = (y + (cellSize - multiplierHeight * multiplier_scale) / 2 - cellSize * game.conf.text.offset + cellSize * 0.1) /
            multiplier_scale
        love.graphics.print(multiplierText, scaledX, scaledY)
        love.graphics.pop()
    end
end

return CellManager
