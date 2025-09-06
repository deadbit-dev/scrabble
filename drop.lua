local input = import("input")
local element = import("element")
local transition = import("transition")
local log = import("log")

local drop = {}

function drop.init(game)
end

function drop.update(game, dt)
    local state = game.state

    if (input.is_mouse_released(state)) then
        state.drag = nil
    end
end

return drop
