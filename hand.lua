local log = import("log")
local utils = import("utils")
local engine = import("engine")
local resources = import("resources")
local element = import("element")

local hand = {}

---@param game Game
function hand.init(game)
    local state = game.state
    local hand_uid = engine.generate_uid()
    state.hands[hand_uid] = {
        uid = hand_uid,
        elem_uids = {},
        transform = { x = 0, y = 0, width = 0, height = 0, z_index = 0 }
    }
    return hand_uid
end

---@param game Game
---@param hand_uid number
---@param index number
---@param elem_uid number
function hand.addElem(game, hand_uid, index, elem_uid)
    local state = game.state
    state.hands[hand_uid].elem_uids[index] = elem_uid
    local elem = element.get(game, elem_uid)
    elem.space = {
        type = "hand",
        data = {
            hand_uid = hand_uid,
            index = index
        }
    }
end

---@param game Game
---@param hand_uid number
---@param index number
---@return number
function hand.getElemUID(game, hand_uid, index)
    local state = game.state
    return state.hands[hand_uid].elem_uids[index]
end

---@param game Game
---@param hand_uid number
---@param index number
function hand.removeElem(game, hand_uid, index)
    local state = game.state
    state.hands[hand_uid].elem_uids[index] = nil
end

---@param game Game
---@param hand_uid number
---@param elem_uid number
function hand.getIndex(game, hand_uid, elem_uid)
    local state = game.state
    for index, elem_uid in ipairs(state.hands[hand_uid].elem_uids) do
        if elem_uid == elem_uid then
            return index
        end
    end
end

---@param game Game
---@param hand_uid number
---@param index number
---@return XYData
function hand.getWorldTransformInHandSpace(game, hand_uid, index)
    local conf = game.conf
    local state = game.state
    local hand_dimensions = hand.getDimensions(conf)
    local hand_data = state.hands[hand_uid]
    local availableWidth = hand_dimensions.width
    local availableHeight = hand_dimensions.height

    -- NOTE: Calculate element size based on available width and height
    local elementSize = math.min(availableWidth, availableHeight) * 0.5 -- 50% of smaller dimension
    local adaptiveSpacing = elementSize * conf.hand.element_spacing_ratio
    local offsetFromSide = availableWidth * conf.hand.element_offset_from_side_ratio
    local totalWidth = (#hand_data.elem_uids * elementSize + (#hand_data.elem_uids - 1) * adaptiveSpacing) +
        (offsetFromSide * 2)

    if totalWidth > availableWidth then
        local scaleFactor = availableWidth / totalWidth
        elementSize = elementSize * scaleFactor
        adaptiveSpacing = adaptiveSpacing * scaleFactor
    end

    -- NOTE: Calculate starting position from left edge of hand
    local startX = hand_dimensions.x + offsetFromSide
    local centerY = hand_dimensions.y + availableHeight / 2

    -- NOTE: Calculate position for the specific element (sequential from left to right)
    local x = startX + (index - 1) * (elementSize + adaptiveSpacing)
    local y = centerY - elementSize / 2

    return {
        x = x,
        y = y,
        width = elementSize,
        height = elementSize,
        z_index = 2
    }
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
    local offset_from_center = utils.getPercentSize(windowWidth / 2, windowHeight / 2,
        conf.hand.offset_from_center_percent)
    local x = (windowWidth - width) / 2
    local y = ((windowHeight - height) / 2) + offset_from_center

    -- NOTE: Ensure hand doesn't go below screen bottom
    local maxY = windowHeight - height
    local offset_from_bottom_screen = utils.getPercentSize(windowWidth, windowHeight,
        conf.hand.min_offset_from_bottom_screen_percent)
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

---Updates the hand
---@param game Game
---@param dt number
function hand.update(game, dt)
    local conf = game.conf
    local state = game.state

    for hand_uid, hand_data in pairs(state.hands) do
        hand.updateTransform(game, hand_uid)
        hand.updateElementsTransform(game, hand_uid)
    end
end

---Updates hand transform based on current window size
---@param game Game
---@param hand_uid number
function hand.updateTransform(game, hand_uid)
    local conf = game.conf
    local state = game.state
    local hand_data = state.hands[hand_uid]
    local dimensions = hand.getDimensions(conf)

    hand_data.transform = {
        x = dimensions.x,
        y = dimensions.y,
        width = dimensions.width,
        height = dimensions.height,
        z_index = 0
    }
end

---Updates transforms for all elements in the hand
---@param game Game
---@param hand_uid number
function hand.updateElementsTransform(game, hand_uid)
    local conf = game.conf
    local state = game.state
    local hand_data = state.hands[hand_uid]

    for index, elem_uid in ipairs(hand_data.elem_uids) do
        if elem_uid then
            local elem = state.elements[elem_uid]
            if elem then
                elem.transform = hand.getWorldTransformInHandSpace(game, hand_uid, index)
                elem.z_index = -1
            end
        end
    end
end

local function drawBg(conf, transform)
    if (not resources.textures.hand) then
        return
    end

    love.graphics.setColor(conf.colors.black)
    love.graphics.draw(resources.textures.hand, transform.x, transform.y, 0,
        transform.width / resources.textures.hand:getWidth(),
        transform.height / resources.textures.hand:getHeight())
end

---@param game Game
function hand.draw(game)
    local conf = game.conf
    local state = game.state

    for hand_uid, hand_data in pairs(state.hands) do
        drawBg(conf, hand_data.transform)
    end
end

return hand
