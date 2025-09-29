local Math = {}

---Calculates a percentage of the smaller side of the window
---@param width number Width of the window
---@param height number Height of the window
---@param percent number Percentage to calculate
---@return number Size of the smaller side
function Math.get_percent_size(width, height, percent)
    if (width > height) then
        return height * 0.8 * percent
    else
        return width * percent
    end
end

function Math.lerp(a, b, t)
    return a + (b - a) * t
end

---Calculates distance between two points
---@param pos1 {x: number, y: number}
---@param pos2 {x: number, y: number}
---@return number
function Math.get_distance(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    return math.sqrt(dx * dx + dy * dy)
end

return Math
