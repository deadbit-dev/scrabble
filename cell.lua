local resources = import("resources")

local cell = {}

---Creates a cell
---@param state State
---@param multiplier number
---@return number
function cell.create(state, multiplier)
    local cell_uid = generate_uid()
    state.cells[cell_uid] = { uid = cell_uid, multiplier = multiplier }
    return cell_uid
end

---@param state State
---@param uid number
---@return Cell
function cell.get(state, uid)
    return state.cells[uid]
end

---Removes a cell
---@param state State
---@param cell_uid number
function cell.remove(state, cell_uid)
    state.cells[cell_uid] = nil
end

---@param conf Config
---@param x number X position of the cell
---@param y number Y position of the cell
---@param cellSize number Size of the cell
---@param cell Cell
function cell.draw(conf, x, y, cellSize, cell)
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

        if (resources.fonts.default) then
            love.graphics.setFont(resources.fonts.default)
        end

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

return cell