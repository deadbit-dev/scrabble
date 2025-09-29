local ElementManager = {}

---Draws an element
---@param game Game
---@param uid number
local function draw_element(game, uid)
    local conf = game.conf
    local resources = game.resources
    local element_data = ElementManager.get_state(game, uid)

    if not element_data or not element_data.transform then return end

    -- NOTE: Use element dimensions from transform
    local texture_scaleX = 1
    local texture_scaleY = 1
    local elementWidth = element_data.transform.width
    local elementHeight = element_data.transform.height

    if resources.textures.element then
        texture_scaleX = elementWidth / resources.textures.element:getWidth()
        texture_scaleY = elementHeight / resources.textures.element:getHeight()
        elementWidth = resources.textures.element:getWidth() * texture_scaleX
        elementHeight = resources.textures.element:getHeight() * texture_scaleY
    end

    -- NOTE: Draw element texture
    love.graphics.setColor(conf.colors.white)
    if (resources.textures.element) then
        love.graphics.draw(resources.textures.element, element_data.transform.x, element_data.transform.y, 0,
            texture_scaleX,
            texture_scaleY)
    end

    -- NOTE: Setup font for text rendering
    love.graphics.setColor(conf.text.colors.element)
    if (resources.fonts.default) then
        love.graphics.setFont(resources.fonts.default)
    end

    local font = love.graphics.getFont()
    local textWidth = font:getWidth(element_data.letter)
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
    love.graphics.print(element_data.letter, element_data.transform.x / letter_scale + letter_scaledX,
        element_data.transform.y / letter_scale + letter_scaledY)
    love.graphics.pop()

    -- NOTE: Calculate points scale and position
    local point_scale = letter_scale * conf.text.point_scale_factor
    local pointsText = tostring(element_data.points)
    local pointsWidth = font:getWidth(pointsText)
    local pointsHeight = font:getHeight()
    local points_scaledX = (elementWidth - pointsWidth * point_scale - elementWidth * conf.text.element_padding) /
        point_scale
    local points_scaledY = (elementHeight - pointsHeight * point_scale - elementHeight * conf.text.element_padding) /
        point_scale

    -- NOTE: Draw points
    love.graphics.push()
    love.graphics.scale(point_scale)
    love.graphics.print(element_data.points, element_data.transform.x / point_scale + points_scaledX,
        element_data.transform.y / point_scale + points_scaledY)
    love.graphics.pop()
end

---Creates an element
---@param game Game
---@param letter string
---@param x number|nil
---@param y number|nil
---@param width number|nil
---@param height number|nil
function ElementManager.create(game, letter, x, y, width, height)
    local conf = game.conf
    local state = game.state
    local elem_uid = game.engine.generate_uid()
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
            type = SpaceType.SCREEN,
            data = {
                x = x or 0,
                y = y or 0
            }
        },
        letter = letter,
        points = conf.elements.latin[letter].points
    }

    return elem_uid
end

---@param game Game
---@param uid number
---@return Element
function ElementManager.get_state(game, uid)
    local state = game.state
    return state.elements[uid]
end

---Removes an element
---@param game Game
---@param elem_uid number
function ElementManager.remove(game, elem_uid)
    local state = game.state
    state.elements[elem_uid] = nil
end

---Sets an element's space and transform
---@param game Game
---@param elem_uid number
---@param space_info SpaceInfo
function ElementManager.set_space(game, elem_uid, space_info)
    local element_data = ElementManager.get_state(game, elem_uid)
    element_data.space = space_info
end

function ElementManager.get_space(game, elem_uid)
    local element_data = ElementManager.get_state(game, elem_uid)
    return element_data.space
end

function ElementManager.set_transform(game, elem_uid, transform)
    local element_data = ElementManager.get_state(game, elem_uid)
    element_data.transform = transform
end

function ElementManager.get_transform(game, elem_uid)
    local element_data = ElementManager.get_state(game, elem_uid)
    return element_data.transform
end

---Checks if point is within element's bounding box
---@param game Game
---@param elem_uid number
---@param point {x: number, y: number}
---@return boolean
function ElementManager.is_point_in_element_bounds(game, elem_uid, point)
    local element_data = ElementManager.get_state(game, elem_uid)
    local transform = element_data.transform
    return point.x >= transform.x
        and point.x <= transform.x + transform.width
        and point.y >= transform.y
        and point.y <= transform.y + transform.height
end

function ElementManager.draw(game)
    local state = game.state

    -- NOTE: Sort elements by transform.z_index before drawing
    local sorted_elements = {}
    for _, elem in pairs(state.elements) do
        table.insert(sorted_elements, elem)
    end
    table.sort(sorted_elements, function(a, b) return a.transform.z_index < b.transform.z_index end)

    for _, elem in pairs(sorted_elements) do
        draw_element(game, elem.uid)
    end
end

return ElementManager
