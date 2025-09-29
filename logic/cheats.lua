local cheats = {}

local function hotKeys(game)
    local state = game.state
    local Engine = game.engine
    local Input = game.engine.Input
    local Tests = game.logic.Tests

    if Input.is_key_released(state, "f11") then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen, "desktop")
    end

    if Input.is_key_released(state, "r") then
        Engine.restart(game)
    end

    if Input.is_key_released(state, "t") then
        Tests.transition(game)
    end
end

---@param game Game
function cheats.update(game)
    hotKeys(game)
end

return cheats
