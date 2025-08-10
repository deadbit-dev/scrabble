local utils = import("utils")
local resources = import("resources")

local hand = {}

---@param state State
function hand.init(state)
    local hand_uid = generate_uid()
    state.hands[hand_uid] = { uid = hand_uid, elem_uids = {} }
    return hand_uid
end

---@param state State
---@param hand_uid number
---@param index number
---@param elem_uid number
function hand.addElem(state, hand_uid, index, elem_uid)
    table.insert(state.hands[hand_uid].elem_uids, index, elem_uid)
end

---@param state State
---@param hand_uid number
---@param index number
---@return Element
function hand.getElemUID(state, hand_uid, index)
    return state.hands[hand_uid].elem_uids[index]
end

---@param state State
---@param hand_uid number
---@param index number
function hand.removeElem(state, hand_uid, index)
    table.remove(state.hands[hand_uid].elem_uids, index)
end

---@param conf Config
---@param state State
---@param hand_uid number
---@param index number
---@return XYData
function hand.getWorldPosInHandSpace(conf, state, hand_uid, index)
    local hand_dimensions = hand.getDimensions(conf)
    local hand = state.hands[hand_uid]
    
    if #hand.elem_uids == 0 then
        return { x = hand_dimensions.x, y = hand_dimensions.y }
    end
    
    -- NOTE: Calculate element size based on hand dimensions (adaptive)
    local elementSize = math.min(hand_dimensions.width, hand_dimensions.height) * 0.5 -- 50% of smaller dimension
    local adaptiveSpacing = elementSize * conf.hand.element_spacing_ratio
    local totalWidth = #hand.elem_uids * elementSize + (#hand.elem_uids - 1) * adaptiveSpacing
    
    -- NOTE: Apply internal margin from hand background
    local availableWidth = hand_dimensions.width
    local availableHeight = hand_dimensions.height
    
    -- NOTE: Calculate starting position to center all elements within available hand area
    local startX = hand_dimensions.x + (availableWidth - totalWidth) / 2
    local centerY = hand_dimensions.y + availableHeight / 2
    
    -- NOTE: Calculate position for the specific element
    local x = startX + (index - 1) * (elementSize + adaptiveSpacing)
    local y = centerY - elementSize / 2
    
    return { x = x, y = y }
end

---Calculates hand background dimensions and position with adaptive scaling
---@param conf Config
---@return table containing hand dimensions and position
function hand.getDimensions(conf)
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()

    -- NOTE: Calculate hand dimensions as percentages of screen size
    local width = windowWidth * conf.hand.width_ratio
    local height = windowHeight * conf.hand.height_ratio

    -- NOTE: Ensure minimum usable space for hand
    local minHandHeight = conf.hand.min_height

    -- NOTE: Position at bottom center of screen
    local offset_from_center = getPercentSize(windowWidth / 2, windowHeight / 2, conf.hand.offset_from_center_percent)
    local x = (windowWidth - width) / 2
    local y = ((windowHeight - height) / 2) + offset_from_center

    -- NOTE: Ensure hand doesn't go below screen bottom
    local maxY = windowHeight - height
    local offset_from_bottom_screen = getPercentSize(windowWidth, windowHeight, conf.hand.min_offset_from_bottom_screen_percent)
    if y > maxY - offset_from_bottom_screen then
        y = maxY - offset_from_bottom_screen
    end

    local baseDimensions = {
        x = x,
        y = y,
        width = width,
        height = height
    }

    -- NOTE: Calculate actual dimensions with texture scaling
    local texture = resources.textures.bottom_pad
    local textureWidth = texture:getWidth()
    local textureHeight = texture:getHeight()

    -- NOTE: Calculate scale to fit the texture proportionally within the hand area
    local scaleX = baseDimensions.width / textureWidth
    local scaleY = baseDimensions.height / textureHeight
    local scale = math.min(scaleX, scaleY) -- Use smaller scale to maintain aspect ratio

    -- NOTE: Calculate actual dimensions based on scaled texture
    local scaledWidth = textureWidth * scale
    local scaledHeight = textureHeight * scale

    return {
        x = baseDimensions.x + (baseDimensions.width - scaledWidth) / 2,
        y = baseDimensions.y + (baseDimensions.height - scaledHeight) / 2,
        width = scaledWidth,
        height = scaledHeight
    }
end

return hand