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

---Calculates distance between two points
---@param pos1 {x: number, y: number}
---@param pos2 {x: number, y: number}
---@return number
function utils.getDistance(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    return math.sqrt(dx * dx + dy * dy)
end

----------------------------------------

---Checks if enough time has passed for drag detection
---@param state State
---@param conf Config
---@return boolean
function utils.isDragTimeExceeded(state, conf)
    return (love.timer.getTime() - state.drag_start_time) > conf.click.drag_threshold_time
end

---Checks if mouse has moved enough distance for drag detection
---@param state State
---@param current_pos {x: number, y: number}
---@param conf Config
---@return boolean
function utils.isDragDistanceExceeded(state, current_pos, conf)
    if not state.drag_start_pos then
        return false
    end
    local distance = utils.getDistance(state.drag_start_pos, current_pos)
    return distance > conf.click.drag_threshold_distance
end

---Determines if interaction should be treated as drag
---@param state State
---@param current_pos {x: number, y: number}
---@param conf Config
---@return boolean
function utils.shouldStartDrag(state, current_pos, conf)
    return utils.isDragTimeExceeded(state, conf) or utils.isDragDistanceExceeded(state, current_pos, conf)
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
