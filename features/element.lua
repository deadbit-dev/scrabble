local element = {}

---@class Element
---@field uid number
---@field space SpaceInfo
---@field transform Transform
---@field world_transform Transform
---@field letter string
---@field points number
---@field locked boolean
---@field is_wildcard boolean

---@param conf Config
---@param letter string
---@param x number|nil
---@param y number|nil
---@param width number|nil
---@param height number|nil
---@return Element
function element.create(conf, letter, x, y, width, height)
    local elem_uid = GENERATE_UID()
    return {
        uid = elem_uid,
        space = {
            type = SpaceType.SCREEN,
            data = {
                x = x or 0,
                y = y or 0
            }
        },
        transform = {
            x = 0,
            y = 0,
            width = 0,
            height = 0,
            z_index = 0
        },
        world_transform = {
            x = x or 0,
            y = y or 0,
            width = width or conf.text.screen.base_size,
            height = height or conf.text.screen.base_size,
            z_index = 1
        },
        letter = letter,
        points = (conf.language_alphabet[conf.language] or conf.elements.latin)[letter].points,
        locked = false,
        is_wildcard = (letter == "*")
    }
end

---@param conf Config
---@param element_data Element
---@param texture any
function element.draw_texture(conf, element_data, texture)
    if not element_data or not element_data.world_transform then return end
    if not texture then return end

    local world_transform = element_data.world_transform
    local texture_scaleX = world_transform.width  / texture:getWidth()
    local texture_scaleY = world_transform.height / texture:getHeight()

    love.graphics.setColor(conf.colors.white)
    love.graphics.draw(texture, world_transform.x, world_transform.y, 0,
        texture_scaleX, texture_scaleY)
end

---@param conf Config
---@param element_data Element
---@param font any
function element.draw_text(conf, element_data, font)
    if not element_data or not element_data.world_transform then return end

    local world_transform = element_data.world_transform
    local element_width   = world_transform.width
    local element_height  = world_transform.height

    love.graphics.setColor(conf.text.colors.element)

    if font == nil then font = love.graphics.getFont() end
    love.graphics.setFont(font)

    local text_width  = font:getWidth(element_data.letter)
    local text_height = font:getHeight()

    -- NOTE: Calculate letter scale and position
    local letter_scale   = (element_width * conf.text.letter_scale_factor) / text_height
    local letter_scaledX = ((element_width - text_width * letter_scale) / 2 - element_width * conf.text.element_padding) /
        letter_scale
    local letter_scaledY = ((element_height - text_height * letter_scale) / 2 - element_height * conf.text.element_padding) /
        letter_scale

    -- NOTE: Draw letter
    love.graphics.push()
    love.graphics.scale(letter_scale)
    love.graphics.print(element_data.letter, world_transform.x / letter_scale + letter_scaledX,
        world_transform.y / letter_scale + letter_scaledY)
    love.graphics.pop()

    -- NOTE: Calculate points scale and position
    local digit_factor   = element_data.points >= 10 and 0.75 or 1.0
    local point_scale    = letter_scale * conf.text.element_point_scale_factor * digit_factor
    local points_text    = tostring(element_data.points)
    local points_width   = font:getWidth(points_text)
    local points_height  = font:getHeight()
    local points_scaledX = (element_width - points_width * point_scale - element_width * conf.text.element_padding) /
        point_scale
    local points_scaledY = (element_height - points_height * point_scale - element_height * conf.text.element_padding) /
        point_scale

    -- NOTE: Draw points
    love.graphics.push()
    love.graphics.scale(point_scale)
    love.graphics.print(element_data.points, world_transform.x / point_scale + points_scaledX,
        world_transform.y / point_scale + points_scaledY)
    love.graphics.pop()
end

---@param conf Config
---@param element_data Element
---@param texture any
---@param font any
function element.draw(conf, element_data, texture, font)
    element.draw_texture(conf, element_data, texture)
    element.draw_text(conf, element_data, font)
end

return element
