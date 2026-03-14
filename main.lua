---@diagnostic disable: duplicate-set-field

---@enum Action
Action = {
    KEY_PRESSED = 1,
    KEY_RELEASED = 2,
    MOUSE_PRESSED = 3,
    MOUSE_MOVED = 4,
    MOUSE_RELEASED = 5,
    MOUSE_WHEEL_MOVED = 6,
    TOUCH_PRESSED = 7,
    TOUCH_MOVED = 8,
    TOUCH_RELEASED = 9,
}

---@class Transform
---@field x number
---@field y number
---@field width number
---@field height number
---@field z_index number

package.path = package.path .. ";modules/?.lua;features/?.lua"

table.filter = function(array, filterIterator)
    -- filter result to be returned
    local result = {}

    -- iterate over main array
    for key, value in pairs(array) do
        -- call filterIterator
        if filterIterator(value, key, array) then
            -- append the value in filtered result
            table.insert(result, value)
        end
    end

    -- return the filtered result
    return result
end

require("hotreload")

local lurker = require("lurker")
import("game") -- register dependency so game.lua changes propagate

-- Proxy table: always delegates to the current hotswapped game module,
-- so main.lua never needs to be re-required when game.lua changes.
local game = setmetatable({}, {
    __index = function(_, k) return package.loaded["game"][k] end
})

function GENERATE_UID()
    if (_G.uid_counter == nil) then _G.uid_counter = 0 end
    _G.uid_counter = _G.uid_counter + 1
    return _G.uid_counter
end

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
    game.input(Action.MOUSE_PRESSED, { x = x, y = y, button = button })
end

function love.mousemoved(x, y, dx, dy)
    game.input(Action.MOUSE_MOVED, { x = x, y = y, dx = dx, dy = dy })
end

function love.mousereleased(x, y, button)
    game.input(Action.MOUSE_RELEASED, { x = x, y = y, button = button })
end

function love.wheelmoved(x, y)
    game.input(Action.MOUSE_WHEEL_MOVED, { delta = y })
end

function love.touchpressed(id, x, y)
    game.input(Action.TOUCH_PRESSED, { id = id, x = x, y = y })
end

function love.touchmoved(id, x, y, dx, dy)
    game.input(Action.TOUCH_MOVED, { id = id, x = x, y = y, dx = dx, dy = dy })
end

function love.touchreleased(id, x, y)
    game.input(Action.TOUCH_RELEASED, { id = id, x = x, y = y })
end

function love.resize(w, h)
    game.resize()
end
