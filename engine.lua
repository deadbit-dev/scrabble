local resources = import("resources")
local input = import("input")
local dev = import("dev")
local logic = import("logic")
local rendering = import("rendering")


local engine = {}

function engine.init(game)
    _G.uid_counter = 0

    resources.load()
    logic.init(game)
    input.init(game)
    rendering.init(game)
end

local lurker = require("lurker")
function engine.update(game, dt)
    lurker.update()
    input.update(game, dt)
    dev.update(game, dt)
    logic.update(game, dt)
    input.clear(game)
end

function engine.draw(game)
    rendering.draw(game)
end

---Restarts the game
---@param game Game
function engine.restart(game)
    ---@diagnostic disable-next-line: undefined-field
    game.state:clear()
    engine.init(game)
end

---Generates a unique identifier
---@return number
function engine.generate_uid()
    _G.uid_counter = _G.uid_counter + 1
    return _G.uid_counter
end

return engine
