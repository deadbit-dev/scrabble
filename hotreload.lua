-- TODO: implement hotreload resources
-- FIXME: if call for example reloadModules in logic.update, it will be infinite error and hotreload will not work


local love = require("love")

local log = require("log")
local resources = require("resources")

local CHECK_INTERVAL = 0.5;

local hotreload = {
    files = {},
    last_update = 0,
    last_reload_time = 0,
    last_error_time = 0,
    in_error_state = false,
    error_message = nil
}

---Registers a file for hot reloading
---@param file string Path to the file
---@param callback function|nil Optional callback to be called after reload
function hotreload.register(file, callback)
    assert(type(file) == "string", "File path must be a string")
    assert(type(callback) == "function" or callback == nil, "Callback must be a function or nil")

    table.insert(hotreload.files, {
        path = file,
        callback = callback
    })
    log.info("Registered file for hot reload: " .. file)
end

---Handles errors during hot reloading
---@param err string The error message
function hotreload.handleError(err)
    hotreload.last_error_time = os.time()
    hotreload.in_error_state = true
    hotreload.error_message = err
    log.error(err)
end

---Reloads all registered modules
---@return boolean true if reload was successful, false otherwise
function hotreload.reloadModules()
    if hotreload.in_error_state then
        return false
    end

    -- Clear modules
    for _, file in ipairs(hotreload.files) do
        local moduleName = file.path:gsub("%.lua$", "")
        package.loaded[moduleName] = nil
    end

    local success, err = pcall(function()
        for _, file in ipairs(hotreload.files) do
            local moduleName = file.path:gsub("%.lua$", "")
            package.loaded[moduleName] = require(moduleName)
        end
    end)

    if not success then
        hotreload.handleError("Error in hotreload: " .. err)
        return false
    end

    -- Call reload callbacks if success
    for _, file in ipairs(hotreload.files) do
        if file.callback then
            local success, err = pcall(file.callback)
            if not success then
                hotreload.handleError("Error in callback for " .. file.path .. ": " .. err)
            end
        end
    end

    return true
end

---Checks for file changes and triggers reload if necessary
function hotreload.checkFileChanges()
    local success, err = pcall(function()
        for _, file in ipairs(hotreload.files) do
            local last_modified = love.filesystem.getLastModified(file.path)
            if last_modified > hotreload.last_error_time and last_modified > (hotreload.last_reload_time or 0) then
                log.info("File changed: " .. file.path)
                hotreload.last_reload_time = os.time()
                hotreload.in_error_state = false
                hotreload.error_message = nil
                hotreload.reloadModules()
            end
        end
    end)

    if not success then
        hotreload.handleError("Error checking file changes: " .. err)
    end
end

---Updates the hot reload system
---@param dt number Delta time since last update
function hotreload.update(dt)
    hotreload.last_update = hotreload.last_update + dt
    if hotreload.last_update > CHECK_INTERVAL then
        hotreload.checkFileChanges()
        hotreload.last_update = 0
    end
end

---Draws an error message overlay
---@param message string The error message to display
function hotreload.drawErrorOverlay(message)
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()

    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

    -- Draw error message
    love.graphics.setColor(1, 0.3, 0.3, 1)
    love.graphics.setFont(resources.fonts.default)

    -- Word wrap the error message
    local font = love.graphics.getFont()
    local padding = 50
    local maxWidth = windowWidth - (padding * 2)
    local text = message
    local lines = {}
    local line = ""

    for word in text:gmatch("%S+") do
        local testLine = line .. " " .. word
        if font:getWidth(testLine) > maxWidth then
            table.insert(lines, line)
            line = word
        else
            line = testLine
        end
    end
    table.insert(lines, line)

    -- Draw each line
    local lineHeight = font:getHeight() * 1.2
    local totalHeight = #lines * lineHeight
    local startY = (windowHeight - totalHeight) / 2

    for i, line in ipairs(lines) do
        local x = (windowWidth - font:getWidth(line)) / 2
        local y = startY + (i - 1) * lineHeight
        love.graphics.print(line, x, y)
    end
end

return hotreload
