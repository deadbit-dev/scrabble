local resources = import("resources")

local element = {}

---Creates an element
---@param state State
---@param letter string
---@param points number
---@return number
function element.create(state, letter, points)
    local elem_uid = generate_uid()
    state.elements[elem_uid] = { uid = elem_uid, letter = letter, points = points }
    return elem_uid
end

---@param state State
---@param uid number
---@return Element
function element.get(state, uid)
    return state.elements[uid]
end

---Removes an element
---@param state State
---@param elem_uid number
function element.remove(state, elem_uid)
    state.elements[elem_uid] = nil
end

---@param conf Config
---@param x number X position of the element
---@param y number Y position of the element
---@param element table Element data containing letter and points
---@param scale number Scale factor for the element
function element.draw(conf, x, y, element, scale)
    if not element then return end

    -- NOTE: Calculate element dimensions based on scale
    local elementSize = scale
    local texture_scadrawElemleX = 1
    local texture_scaleY = 1
    local elementWidth = elementSize
    local elementHeight = elementSize

    if resources.textures.element then
        texture_scaleX = elementSize / resources.textures.element:getWidth()
        texture_scaleY = elementSize / resources.textures.element:getHeight()
        elementWidth = resources.textures.element:getWidth() * texture_scaleX
        elementHeight = resources.textures.element:getHeight() * texture_scaleY
    end

    -- NOTE: Draw element texture
    love.graphics.setColor(conf.colors.white)
    if (resources.textures.element) then
        love.graphics.draw(resources.textures.element, x, y, 0, texture_scaleX, texture_scaleY)
    end

    -- NOTE: Setup font for text rendering
    love.graphics.setColor(conf.text.colors.element)
    if (resources.fonts.default) then
        love.graphics.setFont(resources.fonts.default)
    end

    local font = love.graphics.getFont()
    local textWidth = font:getWidth(element.letter)
    local textHeight = font:getHeight()

    -- NOTE: Calculate letter scale and position
    local letter_scale = (elementWidth * conf.text.letter_scale_factor) / textHeight
    local letter_scaledX = ((elementWidth - textWidth * letter_scale) / 2 - elementWidth * conf.text.element_padding) /
        letter_scale
    local letter_scaledY = ((elementHeight - textHeight * letter_scale) / 2 - elementHeight * conf.text.element_padding) /
        letter_scale

    -- NOTE: Draw letter
    love.graphics.push()
    love.graphics.scale(letter_scale)
    love.graphics.print(element.letter, x / letter_scale + letter_scaledX, y / letter_scale + letter_scaledY)
    love.graphics.pop()

    -- NOTE: Calculate points scale and position
    local point_scale = letter_scale * conf.text.point_scale_factor
    local pointsText = tostring(element.points)
    local pointsWidth = font:getWidth(pointsText)
    local pointsHeight = font:getHeight()
    local points_scaledX = (elementWidth - pointsWidth * point_scale - elementWidth * conf.text.element_padding) /
        point_scale
    local points_scaledY = (elementHeight - pointsHeight * point_scale - elementHeight * conf.text.element_padding) /
        point_scale

    -- NOTE: Draw points
    love.graphics.push()
    love.graphics.scale(point_scale)
    love.graphics.print(element.points, x / point_scale + points_scaledX, y / point_scale + points_scaledY)
    love.graphics.pop()
end


return element