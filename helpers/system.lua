-- Системные функции общего назначения
local system = {}

---Инициализирует системные переменные
function system.init()
    _G.uid_counter = 0
end

---Generates a unique identifier
---@return number
function system.generate_uid()
    _G.uid_counter = _G.uid_counter + 1
    return _G.uid_counter
end

---Устанавливает курсор
---@param image_data table
function system.set_cursor(image_data)
    local cur = love.mouse.newCursor(image_data, image_data:getWidth() * 0.5, image_data:getHeight() * 0.5)
    love.mouse.setCursor(cur)
end

return system
