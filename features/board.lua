local board = {}

---@class FieldConfig
---@field size number Size of the game board (width/height in cells)
---@field gap_ratio { top: number, bottom: number, left: number, right: number } Ratios for field gaps
---@field max_size { width: number, height: number } Maximum board dimensions in pixels
---@field multipliers number[][] 2D array of cell multiplier values
---@field cell_gap_ratio number Ratio for gaps between cells
---@field cell_colors { shadow: number[], multiplier: table<number, number[]> } Colors for cell elements
---@field cell_text_offset number Offset for cell text
---@field cell_text_scale_factor number Scale factor for cell text
---@field cell_text_colors { multipliers: table<number, number[]> } Colors for cell text

---@class Cell
---@field uid number
---@field multiplier number

---@class Board
---@field transform Transform
---@field offset { x: number, y: number }
---@field zoom number
---@field cells {[number]: Cell}
---@field cell_uids (number)[][]
---@field elem_uids (number|nil)[][]


---@param multiplier number
---@return Cell
local function create_cell(multiplier)
    return { uid = GENERATE_UID(), multiplier = multiplier }
end

---@param transform Transform
---@param field_texture any
local function draw_bg(transform, field_texture, color)
    if (not field_texture) then
        return
    end

    love.graphics.setColor(color)
    love.graphics.draw(field_texture, transform.x, transform.y, 0,
        transform.width / field_texture:getWidth(),
        transform.height / field_texture:getHeight())
end

---@param conf FieldConfig
---@param transform Transform
---@param cell_data Cell
---@param cell_size number Size of the cell
---@parms textures { cell: any, shadow: any, cross: any }
local function draw_cell(conf, transform, cell_data, cell_size, textures, font)
    -- NOTE: draw cell
    if textures.cell then
        love.graphics.setColor(conf.cell_colors.multiplier[cell_data.multiplier])
        love.graphics.draw(textures.cell, transform.x, transform.y, 0, cell_size / textures.cell:getWidth(),
            cell_size / textures.cell:getHeight())
    end

    -- NOTE: draw cell shadow
    if textures.shadow then
        love.graphics.setColor(conf.cell_colors.shadow)
        love.graphics.draw(textures.shadow, transform.x, transform.y, 0,
            cell_size / textures.shadow:getWidth(),
            cell_size / textures.shadow:getHeight())
    end

    -- NOTE: draw multiplier if greater than 1
    if cell_data.multiplier > 1 then
        -- NOTE: draw cross
        if textures.cross then
            local cross_scale = (cell_size * conf.cell_text_scale_factor * 0.4) /
                math.max(textures.cross:getWidth(), textures.cross:getHeight())

            local posX = (transform.x + cell_size / 2) - cross_scale * textures.cross:getWidth() / 2 - cell_size * 0.2
            local posY = (transform.y + cell_size / 2) - cross_scale * textures.cross:getHeight() / 2
            love.graphics.setColor(conf.cell_text_colors.multipliers[cell_data.multiplier])
            love.graphics.draw(textures.cross, posX, posY, 0, cross_scale, cross_scale)
        end

        -- NOTE: draw multiplier number
        love.graphics.setColor(conf.cell_text_colors.multipliers[cell_data.multiplier])

        if (font == nil) then
            font = love.graphics.getFont()
        end

        love.graphics.setFont(font)

        local multiplier_text = tostring(cell_data.multiplier)
        local multiplier_width = font:getWidth(multiplier_text)
        local multiplier_height = font:getHeight()
        local multiplier_scale = (cell_size * conf.cell_text_scale_factor) / multiplier_height

        love.graphics.push()
        love.graphics.scale(multiplier_scale)
        local scaledX = (transform.x + (cell_size - multiplier_width * multiplier_scale) / 2 + cell_size * 0.25 - cell_size * conf.cell_text_offset) /
            multiplier_scale
        local scaledY = (transform.y + (cell_size - multiplier_height * multiplier_scale) / 2 - cell_size * conf.cell_text_offset + cell_size * 0.1) /
            multiplier_scale
        love.graphics.print(multiplier_text, scaledX, scaledY)
        love.graphics.pop()
    end
end

---@param conf FieldConfig
---@return Board
function board.create(conf)
    local state = {
        transform = { x = 0, y = 0, width = 0, height = 0, z_index = 0 },
        offset = { x = 0, y = 0 },
        zoom = 1,
        pan_raw_offset = { x = 0, y = 0 },
        zoom_target = 1,
        zoom_focus = { x = 0, y = 0 },
        is_drag_view = false,
        cells = {},
        cell_uids = {},
        elem_uids = {}
    }

    for i = 1, conf.size do
        state.cell_uids[i] = {}
        state.elem_uids[i] = {}
        for j = 1, conf.size do
            local cell = create_cell(conf.multipliers[i][j])
            state.cell_uids[i][j] = cell.uid
            state.cells[cell.uid] = cell
        end
    end

    return state
end

---@param state Board
---@param x number
---@param y number
---@return Cell | nil
function board.get_cell(state, x, y)
    local uid = state.cell_uids[y][x]
    if uid == nil then
        return nil
    end

    return state.cells[state.cell_uids[y][x]]
end

---@param state Board
---@param conf FieldConfig
---@param textures any
---@param color any
---@param font any
function board.draw(state, conf, textures, color, font)
    draw_bg(state.transform, textures.field, color)

    for i = 1, conf.size do
        for j = 1, conf.size do
            local cell_data = board.get_cell(state, j, i)
            if cell_data ~= nil then
                local transform = board.get_space_transform(state, conf, j, i)
                local cell_size = math.min(transform.width, transform.height)

                draw_cell(
                    conf,
                    transform,
                    cell_data,
                    cell_size,
                    { cell = textures.cell, shadow = textures.shadow, cross = textures.cross },
                    font
                )
            end
        end
    end
end

-- TODO: ???

---@param state Board
---@param x number
---@param y number
---@param elem_uid number
function board.add_element(state, x, y, elem_uid)
    state.elem_uids[y][x] = elem_uid
end

---@param state Board
---@param x number
---@param y number
---@return number
function board.get_elem_uid(state, x, y)
    return state.elem_uids[y][x]
end

---@param state Board
---@param x number
---@param y number
function board.remove_element(state, x, y)
    local elem_uid = state.elem_uids[y][x]
    if elem_uid then
        state.elem_uids[y][x] = nil
    end
end

-- TODO: по хорошему не должны тут отсчитывать от окна, мы должны принимать transform окна

---@param state Board
---@param conf FieldConfig
---@return Transform
function board.get_world_transform(state, conf)
    local width = state.transform.width
    local height = state.transform.height

    -- NOTE: Limit the board size to the maximum allowed size
    if (conf.max_size.width < width) then
        width = conf.max_size.width
    end

    if (conf.max_size.height < height) then
        height = conf.max_size.height
    end

    -- NOTE: Calculate the space needed for all gaps
    local total_cell_gaps = conf.size - 1
    local cell_size = math.min(
        width / (conf.size + (conf.size - 1) * conf.cell_gap_ratio + conf.gap_ratio.left + conf.gap_ratio.right),
        height / (conf.size + (conf.size - 1) * conf.cell_gap_ratio + conf.gap_ratio.top + conf.gap_ratio.bottom)
    )
    local cell_gap = cell_size * conf.cell_gap_ratio
    local field_gaps = {
        top = cell_size * conf.gap_ratio.top,
        bottom = cell_size * conf.gap_ratio.bottom,
        left = cell_size * conf.gap_ratio.left,
        right = cell_size * conf.gap_ratio.right
    }

    local total_horizontal_gaps = (cell_gap * total_cell_gaps) + field_gaps.left + field_gaps.right
    local total_vertical_gaps = (cell_gap * total_cell_gaps) + field_gaps.top + field_gaps.bottom

    -- NOTE: Calculate total board size including gaps
    local board_width = (cell_size * conf.size) + total_horizontal_gaps
    local board_height = (cell_size * conf.size) + total_vertical_gaps

    -- NOTE: Calculate starting position to center the board
    -- FIXME: x, y is right ?
    local startX = state.transform.x - (board_width / 2)
    local startY = state.transform.y - (board_height / 2)

    return {
        x = startX,
        y = startY,
        width = board_width,
        height = board_height,
        z_index = 0
    }
end

---@param state Board
---@param conf FieldConfig
---@param x number
---@param y number
---@return Transform
function board.get_space_transform(state, conf, x, y)
    local layout = board.get_layout(state, conf)
    return {
        x = state.transform.x + layout.fieldGaps.left +
            (x - 1) * (layout.cellSize + layout.cellGap),
        y = state.transform.y + layout.fieldGaps.top + (y - 1) * (layout.cellSize + layout.cellGap),
        width = layout.cellSize,
        height = layout.cellSize,
        z_index = 0
    }
end

---@param state Board
---@param conf FieldConfig
---@return table containing cellSize, cellGap, and fieldGaps
function board.get_layout(state, conf)
    local width = state.transform.width
    local height = state.transform.height

    -- NOTE: Limit the board size to the maximum allowed size
    if (conf.max_size.width < width) then
        width = conf.max_size.width
    end

    if (conf.max_size.height < height) then
        height = conf.max_size.height
    end

    -- NOTE: Calculate the space needed for all gaps
    local cell_size = math.min(
        width / (conf.size + (conf.size - 1) * conf.cell_gap_ratio + conf.gap_ratio.left + conf.gap_ratio.right),
        height / (conf.size + (conf.size - 1) * conf.cell_gap_ratio + conf.gap_ratio.top + conf.gap_ratio.bottom)
    )
    local cell_gap = cell_size * conf.cell_gap_ratio
    local field_gaps = {
        top = cell_size * conf.gap_ratio.top,
        bottom = cell_size * conf.gap_ratio.bottom,
        left = cell_size * conf.gap_ratio.left,
        right = cell_size * conf.gap_ratio.right
    }

    return {
        cellSize = cell_size,
        cellGap = cell_gap,
        fieldGaps = field_gaps
    }
end

return board
