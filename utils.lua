local board = import("board")
local resources = import("resources")
local cron = import("cron")

local utils = {}

---Calculates world transform from space info
---@param conf Config
---@param spaceInfo SpaceInfo
---@param element Element
---@return table undefined
function utils.getWorldParamsFromSpaceInfo(conf, spaceInfo, element)
    -- NOTE: screen is default space info, nothing converts
    local worldParams = {
        position = { x = spaceInfo.data.x, y = spaceInfo.data.y },
        scale = conf.text.screen.base_size
    }

    if (spaceInfo.type == "board") then
        local dimensions = board.getBoardDimensions(conf)
        worldParams.position = board.getWorldPosInBoardSpace(spaceInfo.data.x, spaceInfo.data.y, dimensions)
        worldParams.scale = dimensions.cellSize
    elseif (spaceInfo.type == "hand") then
        -- TODO: convert slot index to world position
        worldParams.position.x = 0
        worldParams.position.y = 0
        worldParams.scale = conf.text.screen.base_size
    end

    return worldParams
end

---Calculates a percentage of the smaller side of the window
---@param width number Width of the window
---@param height number Height of the window
---@param percent number Percentage to calculate
---@return number Size of the smaller side
function utils.getPercentSize(width, height, percent)
    if (width > height) then
        return height * 0.8 * percent
    else
        return width * percent
    end
end

---Calculates hand background dimensions and position with adaptive scaling
---@param conf Config
---@return table containing hand dimensions and position
function utils.getHandDimensions(conf)
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()

    -- NOTE: Calculate hand dimensions as percentages of screen size
    local width = windowWidth * conf.hand.width_ratio
    local height = windowHeight * conf.hand.height_ratio

    -- NOTE: Ensure minimum usable space for hand
    local minHandHeight = conf.hand.min_height
    local minMargin = conf.hand.min_offset_from_bottom_screen

    -- NOTE: Adjust height if screen is too small
    if height < minHandHeight then
        height = minHandHeight
    end

    -- NOTE: Ensure hand doesn't exceed available space
    local maxHeight = windowHeight - (minMargin * 2)
    if height > maxHeight then
        height = maxHeight
    end

    -- NOTE: Position at bottom center of screen
    local x = (windowWidth - width) / 2
    local y = ((windowHeight - height) / 2) +
        utils.getPercentSize(windowWidth, windowHeight, conf.hand.offset_from_center_percent)

    -- NOTE: Ensure hand doesn't go below screen bottom
    local maxY = windowHeight - height
    if y > maxY - minMargin then
        y = maxY - minMargin
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

    -- NOTE: Re-check position after scaling to ensure it still fits
    local finalY = baseDimensions.y + (baseDimensions.height - scaledHeight) / 2
    local finalMaxY = windowHeight - scaledHeight - minMargin
    if finalY > finalMaxY then
        finalY = finalMaxY
    end

    return {
        x = baseDimensions.x + (baseDimensions.width - scaledWidth) / 2,
        y = finalY,
        width = scaledWidth,
        height = scaledHeight
    }
end

---Creates a timer
---@param state State
---@param duration number
---@param callback function
---@return table
function utils.timer(state, duration, callback)
    local timer = cron.after(duration, callback)
    table.insert(state.timers, timer)
    return timer
end

---Clears the state
---@param state State
function utils.clearState(state)
    state.cells = {}
    state.elements = {}
    state.pool = {}
    state.board = {
        cell_uids = {},
        elem_uids = {}
    }
    state.hands = {}
    state.players = {}
    state.transitions = {}
    state.timers = {}
    state.current_player_uid = nil
    state.drag = nil
end

return utils
