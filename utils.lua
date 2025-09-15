local utils = {}

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

function utils.lerp(a, b, t)
    return a + (b - a) * t
end

---Checks if point is within element's bounding box
---@param point {x: number, y: number}
---@param element Element
---@return boolean
function utils.isPointInElementBounds(point, element)
    local transform = element.transform
    return point.x >= transform.x
        and point.x <= transform.x + transform.width
        and point.y >= transform.y
        and point.y <= transform.y + transform.height
end

return utils
