local element = {}

---@param state State
---@param conf Config
---@param letter string
---@param x number|nil
---@param y number|nil
---@param width number|nil
---@param height number|nil
---@return number
function element.create(state, conf, letter, x, y, width, height)
    local elem_uid = GENERATE_UID()
    state.elements[elem_uid] = {
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
        points = conf.elements.latin[letter].points
    }

    return elem_uid
end

---@param conf Config
---@param resources table
---@param element_data Element
function element.draw(conf, resources, element_data)
    if not element_data or not element_data.transform then return end

    local world_transform = element_data.world_transform;

    -- NOTE: Use element dimensions from transform
    local texture_scaleX = 1
    local texture_scaleY = 1
    local element_width = world_transform.width
    local element_height = world_transform.height

    if resources.textures.element then
        texture_scaleX = element_width / resources.textures.element:getWidth()
        texture_scaleY = element_height / resources.textures.element:getHeight()
        element_width = resources.textures.element:getWidth() * texture_scaleX
        element_height = resources.textures.element:getHeight() * texture_scaleY
    end

    -- NOTE: Draw element texture
    love.graphics.setColor(conf.colors.white)
    if (resources.textures.element) then
        love.graphics.draw(resources.textures.element, world_transform.x, world_transform.y, 0,
            texture_scaleX,
            texture_scaleY)
    end

    -- NOTE: Setup font for text rendering
    love.graphics.setColor(conf.text.colors.element)
    if (resources.fonts.default) then
        love.graphics.setFont(resources.fonts.default)
    end

    local font = love.graphics.getFont()
    local text_width = font:getWidth(element_data.letter)
    local text_height = font:getHeight()

    -- NOTE: Calculate letter scale and position
    local letter_scale = (element_width * conf.text.letter_scale_factor) / text_height
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
    local point_scale = letter_scale * conf.text.point_scale_factor
    local points_text = tostring(element_data.points)
    local points_width = font:getWidth(points_text)
    local points_height = font:getHeight()
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

return element
