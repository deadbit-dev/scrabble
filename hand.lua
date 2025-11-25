local hand = {}

local utils = import("utils")
local system = import("system")

---@param state State
---@return number
function hand.setup(state)
    local hand_uid = system.generate_uid()
    state.hands[hand_uid] = {
        uid = hand_uid,
        elem_uids = {},
        transform = { x = 0, y = 0, width = 0, height = 0, z_index = 0 },
        size = 7
    }
    return hand_uid
end

---@param state State
---@param hand_uid number
---@param index number
---@param elem_uid number
function hand.add_element(state, hand_uid, index, elem_uid)
    state.hands[hand_uid].elem_uids[index] = elem_uid
    state.elements[elem_uid].space = {
        type = SpaceType.HAND,
        data = {
            hand_uid = hand_uid,
            index = index
        }
    }
end

---@param state State
---@param hand_uid number
---@param index number
---@return number
function hand.get_elem_uid(state, hand_uid, index)
    return state.hands[hand_uid].elem_uids[index]
end

---@param state State
---@param hand_uid number
---@return number|nil
function hand.get_empty_slot(state, hand_uid)
    local hand_data = state.hands[hand_uid]
    for index = 1, hand_data.size do
        if hand_data.elem_uids[index] == -1 then
            return index
        end
    end
    return nil
end

---@param state State
---@param hand_uid number
---@param index number
function hand.remove_element(state, hand_uid, index)
    state.hands[hand_uid].elem_uids[index] = -1
end

---@param state State
---@param hand_uid number
---@param elem_uid number
---@return number|nil
function hand.get_index(state, hand_uid, elem_uid)
    for index, uid in ipairs(state.hands[hand_uid].elem_uids) do
        if elem_uid == uid then
            return index
        end
    end
end

---@param state State
---@param hand_uid number
---@return boolean
function hand.is_empty(state, hand_uid)
    local hand_data = state.hands[hand_uid]
    if not hand_data then
        return true
    end

    for index = 1, hand_data.size do
        if hand_data.elem_uids[index] ~= -1 then
            return false
        end
    end
    return true
end

---@param state State
---@param conf Config
---@param hand_uid number
---@param index number
---@return Transform
function hand.get_world_transform_in_hand_space(state, conf, hand_uid, index)
    local hand_transform = hand.get_world_transform(state, conf)
    local hand_data = state.hands[hand_uid]
    local available_width = hand_transform.width
    local available_height = hand_transform.height

    -- NOTE: Calculate element size based on available width and height
    local element_size = math.min(available_width, available_height) * 0.5 -- 50% of smaller dimension
    local adaptive_spacing = element_size * conf.hand.element_spacing_ratio
    local offset_from_side = available_width * conf.hand.element_offset_from_side_ratio
    local total_width = (hand_data.size * element_size + (hand_data.size - 1) * adaptive_spacing) +
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

---@param state State
---@param conf Config
---@return Transform
function hand.get_world_transform(state, conf)
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

---@param state State
---@param conf Config
---@param hand_uid number
local function update_elements_world_transform(state, conf, hand_uid)
    local hand_data = state.hands[hand_uid]

    for index, elem_uid in ipairs(hand_data.elem_uids) do
        if elem_uid then
            local elem = state.elements[elem_uid]
            if elem then
                local space_transform = hand.get_world_transform_in_hand_space(state, conf, hand_uid, index)
                elem.world_transform = {
                    x = space_transform.x + elem.transform.x,
                    y = space_transform.y + elem.transform.y,
                    width = space_transform.width + elem.transform.width,
                    height = space_transform.height + elem.transform.height,
                    z_index = space_transform.z_index + elem.transform.z_index
                }
            end
        end
    end
end

---@param state State
---@param conf Config
---@param dt number
function hand.update(state, conf, dt)
    for hand_uid, _ in pairs(state.hands) do
        state.hands[hand_uid].transform = hand.get_world_transform(state, conf)
        update_elements_world_transform(state, conf, hand_uid)
    end
end

---@param conf Config
---@param resources table
---@param transform Transform
local function draw_bg(conf, resources, transform)
    if (not resources.textures.hand) then
        return
    end

    love.graphics.setColor(conf.colors.black)
    love.graphics.draw(resources.textures.hand, transform.x, transform.y, 0,
        transform.width / resources.textures.hand:getWidth(),
        transform.height / resources.textures.hand:getHeight())
end

---@param state State
---@param conf Config
---@param resources table
function hand.draw(state, conf, resources)
    for _, hand_data in pairs(state.hands) do
        draw_bg(conf, resources, hand_data.transform)
    end
end

return hand
