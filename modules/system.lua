local System = {}

---Generates a unique identifier
---@return number
function System.generate_uid()
    _G.uid_counter = _G.uid_counter + 1
    return _G.uid_counter
end

function System.set_cursor(imageData)
    local cur = love.mouse.newCursor(imageData, imageData:getWidth() * 0.5, imageData:getHeight() * 0.5)
    love.mouse.setCursor(cur)
end

return System
