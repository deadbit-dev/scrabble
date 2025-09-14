local engine = import("engine")
local resources = import("resources")

local element = {}

---Creates an element
---@param game Game
---@param letter string
---@param x number|nil
---@param y number|nil
---@param width number|nil
---@param height number|nil
function element.create(game, letter, x, y, width, height)
    local conf = game.conf
    local state = game.state
    local elem_uid = engine.generate_uid()
    state.elements[elem_uid] = {
        uid = elem_uid,
        transform = {
            x = x or 0,
            y = y or 0,
            width = width or conf.text.screen.base_size,
            height = height or conf.text.screen.base_size,
            z_index = 1
        },
        space = {
            type = "screen",
            data = {
                x = x or 0,
                y = y or 0
            }
        },
        letter = letter,
        points = conf.elements.english[letter].points
    }
    return elem_uid
end

---@param game Game
---@param uid number
---@return Element
function element.get(game, uid)
    local state = game.state
    return state.elements[uid]
end

---Removes an element
---@param game Game
---@param elem_uid number
function element.remove(game, elem_uid)
    local state = game.state
    state.elements[elem_uid] = nil
end

---Sets an element's space and transform
---@param game Game
---@param elem_uid number
---@param space_info SpaceInfo
function element.set_space(game, elem_uid, space_info)
    local element_data = element.get(game, elem_uid)
    element_data.space = space_info
end

function element.get_space(game, elem_uid)
    local element_data = element.get(game, elem_uid)
    return element_data.space
end

function element.set_transform(game, elem_uid, transform)
    local element_data = element.get(game, elem_uid)
    element_data.transform = transform
end

function element.get_transform(game, elem_uid)
    local element_data = element.get(game, elem_uid)
    return element_data.transform
end

---Updates an element
---@param game Game
---@param dt number
function element.update(game, dt)
end

---@param game Game
---@param elem table Element data from state
function element.draw(game, elem)
    local conf = game.conf

    if not elem or not elem.transform then return end

    -- NOTE: Use element dimensions from transform
    local texture_scaleX = 1
    local texture_scaleY = 1
    local elementWidth = elem.transform.width
    local elementHeight = elem.transform.height

    if resources.textures.element then
        texture_scaleX = elementWidth / resources.textures.element:getWidth()
        texture_scaleY = elementHeight / resources.textures.element:getHeight()
        elementWidth = resources.textures.element:getWidth() * texture_scaleX
        elementHeight = resources.textures.element:getHeight() * texture_scaleY
    end

    -- NOTE: Draw element texture
    love.graphics.setColor(conf.colors.white)
    if (resources.textures.element) then
        love.graphics.draw(resources.textures.element, elem.transform.x, elem.transform.y, 0, texture_scaleX,
            texture_scaleY)
    end

    -- NOTE: Setup font for text rendering
    love.graphics.setColor(conf.text.colors.element)
    if (resources.fonts.default) then
        love.graphics.setFont(resources.fonts.default)
    end

    local font = love.graphics.getFont()
    local textWidth = font:getWidth(elem.letter)
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
    love.graphics.print(elem.letter, elem.transform.x / letter_scale + letter_scaledX,
        elem.transform.y / letter_scale + letter_scaledY)
    love.graphics.pop()

    -- NOTE: Calculate points scale and position
    local point_scale = letter_scale * conf.text.point_scale_factor
    local pointsText = tostring(elem.points)
    local pointsWidth = font:getWidth(pointsText)
    local pointsHeight = font:getHeight()
    local points_scaledX = (elementWidth - pointsWidth * point_scale - elementWidth * conf.text.element_padding) /
        point_scale
    local points_scaledY = (elementHeight - pointsHeight * point_scale - elementHeight * conf.text.element_padding) /
        point_scale

    -- NOTE: Draw points
    love.graphics.push()
    love.graphics.scale(point_scale)
    love.graphics.print(elem.points, elem.transform.x / point_scale + points_scaledX,
        elem.transform.y / point_scale + points_scaledY)
    love.graphics.pop()
end

return element
