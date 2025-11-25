---@diagnostic disable: duplicate-set-field

package.path = package.path .. ";modules/?.lua;features/?.lua"

require("hotreload")

local lurker = require("lurker")
local game = import("game")

function love.load()
    game.init()
end

function love.update(dt)
    lurker.update()
    game.update(dt)
end

function love.draw()
    game.draw()
end

function love.keypressed(key)
    game.input(Action.KEY_PRESSED, { key = key })
end

function love.keyreleased(key)
    game.input(Action.KEY_RELEASED, { key = key })
end

function love.mousepressed(x, y, button)
    game.input(Action.MOUSE_PRESSED, { x = x, y = x, button = button })
end

function love.mousemoved(x, y, dx, dy)
    game.input(Action.MOUSE_MOVED, { x = x, y = y, dx = dx, dy = dy })
end

function love.mousereleased(x, y, button)
    game.input(Action.MOUSE_RELEASED, { x = x, y = y, button = button })
end
