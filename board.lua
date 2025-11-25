local board = {}

local log = import("log")
local cell = import("cell")

---@param state State
---@param conf Config
function board.setup(state, conf)
    for i = 1, conf.field.size do
        state.board.cell_uids[i] = {}
        state.board.elem_uids[i] = {}
        for j = 1, conf.field.size do
            board.add_cell(state, conf, i, j, cell.create(state, conf.field.multipliers[i][j]))
        end
    end
end

local function update_elemenets_world_transform(state, conf)
    for y = 1, conf.field.size do
        for x = 1, conf.field.size do
            local elem_uid = board.get_board_elem_uid(state, x, y)
            if elem_uid then
                local elem_data = state.elements[elem_uid]
                local space_transform = board.get_world_transform_in_board_space(conf, x, y)
                elem_data.world_transform = {
                    x = space_transform.x + elem_data.transform.x,
                    y = space_transform.y + elem_data.transform.y,
                    width = space_transform.width + elem_data.transform.width,
                    height = space_transform.height + elem_data.transform.height,
                    z_index = space_transform.z_index + elem_data.transform.z_index
                }
            end
        end
    end
end

---@param state State
---@param conf Config
---@param dt number
function board.update(state, conf, dt)
    state.board.transform = board.get_world_transform(conf)
    update_elemenets_world_transform(state, conf)
end

---@param conf Config
---@param resources table
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

---@param state State
---@param conf Config
---@param resources table
function board.draw(state, conf, resources)
    draw_bg(conf, resources, state.board.transform)

    -- TODO: separate cells rendering too
    for i = 1, conf.field.size do
        for j = 1, conf.field.size do
            local cell_uid = board.get_board_cell_uid(state, j, i)
            if cell_uid then
                local cell_data = cell.get(state, cell_uid)
                local transform = board.get_world_transform_in_board_space(conf, j, i)
                local cell_size = math.min(transform.width, transform.height)
                cell.draw(conf, resources, transform.x, transform.y, cell_size, cell_data)
            end
        end
    end
end

---@param state State
---@param x number
---@param y number
---@return number
function board.get_board_cell_uid(state, x, y)
    return state.board.cell_uids[x][y]
end

---@param state State
---@param conf Config
---@param x number
---@param y number
---@param cell_uid number
function board.add_cell(state, conf, x, y, cell_uid)
    state.board.cell_uids[x][y] = cell_uid
end

---@param state State
---@param x number
---@param y number
---@return number
function board.get_board_elem_uid(state, x, y)
    return state.board.elem_uids[x][y]
end

---@param state State
---@param x number
---@param y number
---@param elem_uid number
function board.add_element(state, conf, x, y, elem_uid)
    state.board.elem_uids[x][y] = elem_uid
    local element_data = state.elements[elem_uid]
    element_data.space = {
        type = SpaceType.BOARD,
        data = {
            x = x,
            y = y
        }
    }
end

-- TODO: by remove element from board, we need reset space for him to Screen, but how if board used in space ?

---@param state State
---@param x number
---@param y number
function board.remove_element(state, x, y)
    local elem_uid = state.board.elem_uids[x][y]
    if elem_uid then
        state.board.elem_uids[x][y] = nil
    end
end

---@param conf Config
---@return table containing cellSize, cellGap, and fieldGaps
function board.get_layout(conf)
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()

    -- NOTE: Calculate the total available space for the board using percentage-based padding
    local available_width = window_width * (1 - (conf.window.padding.left + conf.window.padding.right))
    local available_height = window_height * (1 - (conf.window.padding.top + conf.window.padding.bottom))

    -- NOTE: Limit the board size to the maximum allowed size
    if (conf.field.max_size.width < available_width) then
        available_width = conf.field.max_size.width
    end

    if (conf.field.max_size.height < available_height) then
        available_height = conf.field.max_size.height
    end

    -- NOTE: Calculate the space needed for all gaps
    local cell_size = math.min(
        available_width /
        (conf.field.size + (conf.field.size - 1) * conf.field.cell_gap_ratio + conf.field.gap_ratio.left + conf.field.gap_ratio.right),
        available_height /
        (conf.field.size + (conf.field.size - 1) * conf.field.cell_gap_ratio + conf.field.gap_ratio.top + conf.field.gap_ratio.bottom)
    )
    local cell_gap = cell_size * conf.field.cell_gap_ratio
    local field_gaps = {
        top = cell_size * conf.field.gap_ratio.top,
        bottom = cell_size * conf.field.gap_ratio.bottom,
        left = cell_size * conf.field.gap_ratio.left,
        right = cell_size * conf.field.gap_ratio.right
    }

    return {
        cellSize = cell_size,
        cellGap = cell_gap,
        fieldGaps = field_gaps
    }
end

---@param conf Config
---@return Transform
function board.get_world_transform(conf)
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()

    -- NOTE: Calculate the total available space for the board using percentage-based padding
    local available_width = window_width * (1 - (conf.window.padding.left + conf.window.padding.right))
    local available_height = window_height * (1 - (conf.window.padding.top + conf.window.padding.bottom))

    -- NOTE: Limit the board size to the maximum allowed size
    if (conf.field.max_size.width < available_width) then
        available_width = conf.field.max_size.width
    end

    if (conf.field.max_size.height < available_height) then
        available_height = conf.field.max_size.height
    end

    -- NOTE: Calculate the space needed for all gaps
    local total_cell_gaps = conf.field.size - 1
    local cell_size = math.min(
        available_width /
        (conf.field.size + (conf.field.size - 1) * conf.field.cell_gap_ratio + conf.field.gap_ratio.left + conf.field.gap_ratio.right),
        available_height /
        (conf.field.size + (conf.field.size - 1) * conf.field.cell_gap_ratio + conf.field.gap_ratio.top + conf.field.gap_ratio.bottom)
    )
    local cell_gap = cell_size * conf.field.cell_gap_ratio
    local field_gaps = {
        top = cell_size * conf.field.gap_ratio.top,
        bottom = cell_size * conf.field.gap_ratio.bottom,
        left = cell_size * conf.field.gap_ratio.left,
        right = cell_size * conf.field.gap_ratio.right
    }

    local total_horizontal_gaps = (cell_gap * total_cell_gaps) + field_gaps.left + field_gaps.right
    local total_vertical_gaps = (cell_gap * total_cell_gaps) + field_gaps.top + field_gaps.bottom

    -- NOTE: Calculate total board size including gaps
    local board_width = (cell_size * conf.field.size) + total_horizontal_gaps
    local board_height = (cell_size * conf.field.size) + total_vertical_gaps

    -- NOTE: Calculate starting position to center the board
    local startX = (window_width / 2) - (board_width / 2)
    local startY = (window_height / 2) - (board_height / 2)

    return {
        x = startX,
        y = startY,
        width = board_width,
        height = board_height,
        z_index = 0
    }
end

---@param conf Config
---@param x number
---@param y number
---@return Transform
function board.get_world_transform_in_board_space(conf, x, y)
    local layout = board.get_layout(conf)
    local transform = board.get_world_transform(conf)
    return {
        x = transform.x + layout.fieldGaps.left +
            (x - 1) * (layout.cellSize + layout.cellGap),
        y = transform.y + layout.fieldGaps.top + (y - 1) * (layout.cellSize + layout.cellGap),
        width = layout.cellSize,
        height = layout.cellSize,
        z_index = -2
    }
end

return board
