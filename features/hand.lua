local hand = {}

local utils = import("utils")

---@class Hand
---@field uid number
---@field transform Transform
---@field elem_uids (number)[]
---@field size number


---@param conf Config
---@param transform Transform
---@param texture any
local function draw_bg(conf, transform, texture)
    if (not texture) then
        return
    end

    love.graphics.setColor(conf.colors.black)
    love.graphics.draw(texture, transform.x, transform.y, 0,
        transform.width / texture:getWidth(),
        transform.height / texture:getHeight())
end

---@return Hand
function hand.create()
    local hand_uid = GENERATE_UID()
    return {
        uid = hand_uid,
        elem_uids = {},
        transform = { x = 0, y = 0, width = 0, height = 0, z_index = 0 },
        size = 7
    }
end

---@param state Hand
---@param index number
---@param elem_uid number
function hand.add_element(state, index, elem_uid)
    state.elem_uids[index] = elem_uid
end

---@param state Hand
---@param index number
---@return number
function hand.get_elem_uid(state, index)
    return state.elem_uids[index]
end

---@param state Hand
---@return number|nil
function hand.get_empty_slot(state)
    for index = 1, state.size do
        if state.elem_uids[index] == -1 then
            return index
        end
    end
    return nil
end

---@param state Hand
---@param index number
function hand.remove_element(state, index)
    state.elem_uids[index] = -1
end

---@param state Hand
---@param elem_uid number
---@return number|nil
function hand.get_index(state, elem_uid)
    for index, uid in ipairs(state.elem_uids) do
        if elem_uid == uid then
            return index
        end
    end
end

---@param state Hand
---@return boolean
function hand.is_empty(state)
    for index = 1, state.size do
        if state.elem_uids[index] ~= -1 then
            return false
        end
    end
    return true
end

---@param state Hand
---@param conf Config
---@param index number
---@return Transform
function hand.get_world_transform_in_hand_space(state, conf, index)
    local hand_transform = hand.get_world_transform(conf)
    local available_width = hand_transform.width
    local available_height = hand_transform.height

    -- NOTE: Calculate element size based on available width and height
    local element_size = math.min(available_width, available_height) * 0.5 -- 50% of smaller dimension
    local adaptive_spacing = element_size * conf.hand.element_spacing_ratio
    local offset_from_side = available_width * conf.hand.element_offset_from_side_ratio
    local total_width = (state.size * element_size + (state.size - 1) * adaptive_spacing) +
        (offset_from_side * 2)

    if total_width > available_width then
        local scale_factor = available_width / total_width
        element_size = element_size * scale_factor
        adaptive_spacing = adaptive_spacing * scale_factor
    end

    -- NOTE: Calculate starting position from left edge of hand
    local startX = hand_transform.x + offset_from_side
    local centerY = hand_transform.y + available_height / 2

    -- NOTE: Calculate position for the specific element (sequential from left to right)
    local x = startX + (index - 1) * (element_size + adaptive_spacing)
    local y = centerY - element_size / 2

    return {
        x = x,
        y = y,
        width = element_size,
        height = element_size,
        z_index = 2
    }
end

---@param conf Config
---@return Transform
function hand.get_world_transform(conf)
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()

    -- NOTE: Calculate hand dimensions as percentages of screen size
    local width = window_width * conf.hand.width_ratio
    local height = window_height * conf.hand.height_ratio

    -- NOTE: Ensure minimum usable space for hand
    local min_hand_height = conf.hand.min_height

    -- NOTE: Position at bottom center of screen
    local offset_from_center = utils.get_percent_size(window_width / 2, window_height / 2,
        conf.hand.offset_from_center_percent)
    local x = (window_width - width) / 2
    local y = ((window_height - height) / 2) + offset_from_center

    -- NOTE: Ensure hand doesn't go below screen bottom
    local maxY = window_height - height
    local offset_from_bottom_screen = utils.get_percent_size(window_width, window_height,
        conf.hand.min_offset_from_bottom_screen_percent)
    if y > maxY - offset_from_bottom_screen then
        y = maxY - offset_from_bottom_screen
    end

    local base_dimensions = {
        x = x,
        y = y,
        width = width,
        height = height
    }

    -- NOTE: Calculate actual dimensions with texture scaling
    local resources = import("resources")
    local texture = resources.textures.bottom_pad
    if not texture then
        return {
            x = base_dimensions.x,
            y = base_dimensions.y,
            width = base_dimensions.width,
            height = base_dimensions.height,
            z_index = 1
        }
    end

    local texture_width = texture:getWidth()
    local texture_height = texture:getHeight()

    -- NOTE: Calculate scale to fit the texture proportionally within the hand area
    local scaleX = base_dimensions.width / texture_width
    local scaleY = base_dimensions.height / texture_height
    local scale = math.min(scaleX, scaleY) -- Use smaller scale to maintain aspect ratio

    -- NOTE: Calculate actual dimensions based on scaled texture
    local scaled_width = texture_width * scale
    local scaled_height = texture_height * scale

    return {
        x = base_dimensions.x + (base_dimensions.width - scaled_width) / 2,
        y = base_dimensions.y + (base_dimensions.height - scaled_height) / 2,
        width = scaled_width,
        height = scaled_height,
        z_index = 1
    }
end

---@param state Hand
---@param conf Config
---@param hand_texture any
function hand.draw(state, conf, hand_texture)
    draw_bg(conf, state.transform, hand_texture)
end

return hand
