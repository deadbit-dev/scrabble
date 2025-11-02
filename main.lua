local game = require("game")

function love.load()
    game.init()
end

function love.update(dt)
    game.update(dt)
end

function love.draw()
    game.draw()
end

---@param key string
function love.keypressed(key)
    game.keypressed(key)
end

---@param key string
function love.keyreleased(key)
    game.keyreleased(key)
end

---@param x number
---@param y number
---@param button number
function love.mousepressed(x, y, button)
    game.mousepressed(x, y, button)
end

---@param x number
---@param y number
---@param dx number
---@param dy number
function love.mousemoved(x, y, dx, dy)
    game.mousemoved(x, y, dx, dy)
end

---@param x number
---@param y number
---@param button number
function love.mousereleased(x, y, button)
    game.mousereleased(x, y, button)
end
