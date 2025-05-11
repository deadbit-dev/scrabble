local love = require("love")

local resources = require("resources")
local state = require("state")
local logic = require("logic")
local rendering = require("rendering")
local hotreload = require("hotreload")

function love.load()
    resources.load()
    logic.init(state)

    hotreload.register("conf.lua")
    hotreload.register("utils.lua")
    hotreload.register("logic.lua", function()
        logic = require("logic")
    end)
    hotreload.register("rendering.lua", function()
        rendering = require("rendering")
    end)
end

function love.keypressed(key)
    -- Force reload on F5 key press
    if key == "f5" then
        hotreload.reloadModules()
    end

    local success, err = pcall(function()
        logic.keypressed(state, key)
    end)

    if not success then
        hotreload.handleError("Error in keypressed logic: " .. err)
    end
end

function love.update(dt)
    hotreload.update(dt)

    local success, err = pcall(function()
        logic.update(state, dt)
    end)
    if not success then
        hotreload.handleError("Error in updating logic: " .. err)
    end
end

function love.draw()
    if hotreload.in_error_state then
        hotreload.drawErrorOverlay(hotreload.error_message)
        return
    end

    local success, err = pcall(function()
        rendering.draw(state)
    end)

    if not success then
        local message = "Error in drawing rendering: " .. err
        hotreload.handleError(message)
        hotreload.drawErrorOverlay(message)
    end
end
