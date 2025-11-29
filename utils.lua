local utils = {}

---Calculates a percentage of the smaller side of the window
---@param width number Width of the window
---@param height number Height of the window
---@param percent number Percentage to calculate
---@return number Size of the smaller side
function utils.get_percent_size(width, height, percent)
    if (width > height) then
        return height * 0.8 * percent
    else
        return width * percent
    end
end

function utils.lerp(a, b, t)
    return a + (b - a) * t
end

---Calculates distance between two points
---@param pos1 Pos
---@param pos2 Pos
---@return number
function utils.get_distance(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    return math.sqrt(dx * dx + dy * dy)
end

---@param transform Transform
---@param point Pos
---@return boolean
function utils.is_point_in_transform_bounds(transform, point)
    return point.x >= transform.x
        and point.x <= transform.x + transform.width
        and point.y >= transform.y
        and point.y <= transform.y + transform.height
end

---@param image_data table
function utils.set_cursor(image_data)
    local cur = love.mouse.newCursor(image_data, image_data:getWidth() * 0.5, image_data:getHeight() * 0.5)
    love.mouse.setCursor(cur)
end

return utils
