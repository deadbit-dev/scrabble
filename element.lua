local element = {}

local system = import("core.system")

---@param conf Config
---@param resources table
---@param element_data Element
local function draw_element(conf, resources, element_data)
    if not element_data or not element_data.transform then return end

    -- NOTE: Use element dimensions from transform
    local texture_scaleX = 1
    local texture_scaleY = 1
    local element_width = element_data.transform.width
    local element_height = element_data.transform.height

    if resources.textures.element then
        texture_scaleX = element_width / resources.textures.element:getWidth()
        texture_scaleY = element_height / resources.textures.element:getHeight()
        element_width = resources.textures.element:getWidth() * texture_scaleX
        element_height = resources.textures.element:getHeight() * texture_scaleY
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
    love.graphics.print(element_data.letter, element_data.transform.x / letter_scale + letter_scaledX,
        element_data.transform.y / letter_scale + letter_scaledY)
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
    love.graphics.print(element_data.points, element_data.transform.x / point_scale + points_scaledX,
        element_data.transform.y / point_scale + points_scaledY)
    love.graphics.pop()
end

---@param state State
---@param conf Config
---@param letter string
---@param x number|nil
---@param y number|nil
---@param width number|nil
---@param height number|nil
---@return number
function element.create(state, conf, letter, x, y, width, height)
    local elem_uid = system.generate_uid()
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

---@param state State
---@param uid number
---@return Element
function element.get_state(state, uid)
    return state.elements[uid]
end

---@param state State
---@param elem_uid number
function element.remove(state, elem_uid)
    state.elements[elem_uid] = nil
end

---@param state State
---@param elem_uid number
---@param space_info SpaceInfo
function element.set_space(state, elem_uid, space_info)
    local element_data = element.get_state(state, elem_uid)
    element_data.space = space_info
end

---@param state State
---@param elem_uid number
---@return SpaceInfo
function element.get_space(state, elem_uid)
    local element_data = element.get_state(state, elem_uid)
    return element_data.space
end

---@param state State
---@param elem_uid number
---@param transform Transform
function element.set_transform(state, elem_uid, transform)
    local element_data = element.get_state(state, elem_uid)
    element_data.transform = transform
end

---@param state State
---@param elem_uid number
---@return Transform
function element.get_transform(state, elem_uid)
    local element_data = element.get_state(state, elem_uid)
    return element_data.transform
end

---@param state State
---@param elem_uid number
---@param point {x: number, y: number}
---@return boolean
function element.is_point_in_element_bounds(state, elem_uid, point)
    local element_data = element.get_state(state, elem_uid)
    local transform = element_data.transform
    return point.x >= transform.x
        and point.x <= transform.x + transform.width
        and point.y >= transform.y
        and point.y <= transform.y + transform.height
end

---@param state State
---@param conf Config
---@param resources table
function element.draw(state, conf, resources)
    -- NOTE: Sort elements by transform.z_index before drawing
    local sorted_elements = {}
    for _, elem in pairs(state.elements) do
        table.insert(sorted_elements, elem)
    end
    table.sort(sorted_elements, function(a, b) return a.transform.z_index < b.transform.z_index end)

    for _, elem in pairs(sorted_elements) do
        draw_element(conf, resources, elem)
    end
end

return element
