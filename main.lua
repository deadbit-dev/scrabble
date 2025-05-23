-- TODO: hotswap dependencies
-- TODO: hotswap resources
-- TODO: move code to src directory
-- TODO: input state and handle function checks state where needed

local conf = require("conf")
local resources = require("resources")
local state = require("state")
local logic = require("logic")
local rendering = require("rendering")
local lurker = require("lurker")
local dependencies = require("dependencies")

-- Регистрируем зависимости
dependencies.register("logic", "conf")
dependencies.register("rendering", "conf")

-- local hotreload = require("hotreload")

function love.load()
    resources.load()
    logic.init(state)

    -- -- TODO: we can some how without registration, auto check loaded packages ?
    -- hotreload.register("conf.lua", function()
    --     print("conf reloaded")
    --     logic = require("logic")
    --     rendering = require("rendering")
    -- end)
    -- hotreload.register("utils.lua")
    -- hotreload.register("logic.lua", function()
    --     logic = require("logic")
    -- end)
    -- hotreload.register("rendering.lua", function()
    --     rendering = require("rendering")
    -- end)
end

function love.keypressed(key)
    -- NOTE: force reload on F5 key press
    -- if key == "f5" then
    -- hotreload.reloadModules()
    -- end

    -- local success, err = pcall(function()
    logic.keypressed(state, key)
    -- end)

    -- if not success then
    -- hotreload.handleError("Error in keypressed: " .. err)
    -- end
end

function love.update(dt)
    lurker.update()
    -- hotreload.update(dt)

    -- local success, err = pcall(function()
    logic.update(state, dt)
    -- end)
    -- if not success then
    --     hotreload.handleError("Error in updating logic: " .. err)
    -- end
end

function love.draw()
    -- if hotreload.in_error_state then
    --     hotreload.drawErrorOverlay()
    --     return
    -- end

    -- local success, err = pcall(function()
    rendering.draw(conf, state)
    -- end)

    -- if not success then
    --     print("ERROR: " .. err)
    --     local message = "Error in rendering: " .. err
    --     hotreload.handleError(message)
    --     hotreload.drawErrorOverlay()
    -- end
end

-- Добавляем обработчик после перезагрузки модулей
lurker.postswap = function(f)
    local module = f:gsub("%.lua$", "")
    dependencies.reload_module_and_dependents(module)
    conf = require("conf")
end
