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
local input = import("input")
local rendering = import("rendering")
local resources = import("resources")

function love.load()
    resources.load()
    logic.init(game)
    input.init(game)
    rendering.init(game)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.keypressed(key)
    input.keypressed(game, key)
end

function love.keyreleased(key)
    input.keyreleased(game, key)
end

function love.mousepressed(x, y, button)
    input.mousepressed(game, x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    input.mousemoved(game, x, y, dx, dy)
end

function love.mousereleased(x, y, button)
    input.mousereleased(game, x, y, button)
end

local lurker = require("lurker")
function love.update(dt)
    lurker.update()
    logic.update(game, dt)
    input.clear(game)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
    rendering.draw(game)
end
