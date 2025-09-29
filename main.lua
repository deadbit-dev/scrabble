-- NOTE: setup import and postswap [DEPRICATED]
-- require("hotreload")


local OrderedMap = require("modules.orderedmap")

---@class Game
---@field conf Config
---@field state State
---@field modules table
local game = {
    conf = require("conf"),
    resources = require("resources"),
    state = require("state"),
    engine = require("engine"),
    logic = OrderedMap({
        require("logic.board"),
        require("logic.cell_manager"),
        require("logic.player_manager"),
        require("logic.hand_manager"),
        require("logic.element_manager"),
        require("logic.selection"),
        require("logic.drag"),
        require("logic.drop"),
        require("logic.transition_manager"),
        require("logic.space"),
        require("logic.cheats"),
        require("logic.tests"),
    })
}

function love.load()
    game.engine.init(game)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.keypressed(key)
    game.engine.Input.keypressed(game.state, key)
end

function love.keyreleased(key)
    game.engine.Input.keyreleased(game.state, key)
end

function love.mousepressed(x, y, button)
    game.engine.Input.mousepressed(game.state, x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    game.engine.Input.mousemoved(game.state, x, y, dx, dy)
end

function love.mousereleased(x, y, button)
    game.engine.Input.mousereleased(game.state, x, y, button)
end

function love.update(dt)
    if (not game.engine.is_ready) then
        return
    end
    game.engine.update(game, dt)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
    if (not game.engine.is_ready) then
        return
    end
    game.engine.draw(game)
end
