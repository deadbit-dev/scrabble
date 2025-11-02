local cheats = {}

local input = import("core.input")
local tests = import("tests")

function cheats.update(state, conf, dt)
    if input.is_key_released(state, "f11") then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen, "desktop")
    end

    if input.is_key_released(state, "r") then
        state.is_restart = true
    end

    if input.is_key_released(state, "t") then
        tests.transition(state, conf)
    end
end

return cheats
