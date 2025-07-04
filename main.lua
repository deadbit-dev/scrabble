-- TODO: hotswap resources
-- TODO: move code to src directory
-- TODO: input state and handle function checks state where needed

-- NOTE: setup import and postswap
require("hotreload")

---@class Game
---@field conf Config
---@field state State
local game = {
    conf = import("conf"),
    state = import("state")
}

local logic = import("logic")
local rendering = import("rendering")
local resources = import("resources")

function love.load()
    resources.load()
    logic.init(game)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.keypressed(key)
    logic.keypressed(game, key)
end

local lurker = require("lurker")
function love.update(dt)
    lurker.update()
    logic.update(game, dt)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
    rendering.draw(game)
end
