local input = import("input")
local logic = import("logic")
local tests = import("tests")

local dev = {}

local function hotKeys(game)
    local state = game.state
    if input.is_key_released(state, "f11") then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen, "desktop")
    end

    if input.is_key_released(state, "r") then
        logic.restart(game)
    end

    if input.is_key_released(state, "t") then
        tests.transition(game)
    end
end

---@param game Game
function dev.update(game)
    hotKeys(game)
end

return dev
