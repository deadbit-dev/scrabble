-- NOTE: setup import and postswap [DEPRICATED]
-- require("hotreload")

local Board = require("systems.board"),
local CellManager = require("systems.cell_manager"),
local PlayerManager = require("systems.player_manager"),
local HandManager = require("systems.hand_manager"),
local ElementManager = require("systems.element_manager"),
local Selection = require("systems.selection"),
local Drag = require("systems.drag"),
local Drop = require("systems.drop"),
local TransitionManager = require("systems.transition_manager"),
-- local Cheats = require("systems.cheats"),

local Game = require("game")

function love.load()
    game = Game.new(
        require("conf"),
        require("resources"),
        require("state"),
        OrderedMap({
            addSystem(Board, CellManager, ElementManager),
            -- CellManager(),
            -- PlayerManager(),
            -- HandManager(),
            -- ElementManager(),
            -- Selection(),
            -- Drag(),
            -- Drop(),
            -- TransitionManager(),
        })
    )
end

function love.update(dt)
    game:update(dt)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
    game:render()
end

---@diagnostic disable-next-line: duplicate-set-field
function love.keypressed(key)
    Input.keypressed(data.state, key)
end

function love.keyreleased(key)
    Input.keyreleased(data.state, key)
end

function love.mousepressed(x, y, button)
    Input.mousepressed(data.state, x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    Input.mousemoved(data.state, x, y, dx, dy)
end

function love.mousereleased(x, y, button)
    Input.mousereleased(data.state, x, y, button)
end