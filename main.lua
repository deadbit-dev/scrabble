local conf = require("conf")
local state = require("state")
local resources = require("resources")

local system = require("helpers.system")
local input = require("core.input")
local tween = require("core.tween")

local board = require("modules.board")
local player = require("modules.player")
local hand = require("modules.hand")
local element = require("modules.element")
local selection = require("modules.selection")
local drag = require("modules.drag")
local drop = require("modules.drop")
local transition = require("modules.transition")

function love.load()
    system.init()

    resources.load()

    board.init(state, conf)
    player.init(state, conf)
end

---@param dt number
function love.update(dt)
    input.update(state, conf, dt)

    board.update(state, conf, dt)
    hand.update(state, conf, dt)
    selection.update(state, conf, dt)
    drag.update(state, conf, dt)
    drop.update(state, conf, dt)
    transition.update(state, conf, dt)

    tween.update(state, dt)

    input.clear(state)
end

function love.draw()
    love.graphics.clear(conf.colors.background)

    board.draw(state, conf, resources)
    hand.draw(state, conf, resources)
    element.draw(state, conf, resources)
end

---@param key string
function love.keypressed(key)
    input.keypressed(state, key)
end

---@param key string
function love.keyreleased(key)
    input.keyreleased(state, key)
end

---@param x number
---@param y number
---@param button number
function love.mousepressed(x, y, button)
    input.mousepressed(state, x, y, button)
end

---@param x number
---@param y number
---@param dx number
---@param dy number
function love.mousemoved(x, y, dx, dy)
    input.mousemoved(state, x, y, dx, dy)
end

---@param x number
---@param y number
---@param button number
function love.mousereleased(x, y, button)
    input.mousereleased(state, x, y, button)
end
