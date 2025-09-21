local board = import("board")
local hand = import("hand")
local element = import("element")
local transition = import("transition")
local tween = import("tween")
local timer = import("timer")
local drag = import("drag")
local drop = import("drop")
local selection = import("selection")
local player = import("player")
local dev = import("dev")

local logic = {}

---Initializes the initial game state
---@param game Game
function logic.init(game)
    board.init(game)
    player.init(game)

    dev.testAddElementToBoard(game)
end

---Updates the game state each frame
---@param game Game
---@param dt number Time elapsed since the last frame in seconds
function logic.update(game, dt)
    selection.update(game, dt)
    drag.update(game, dt)
    drop.update(game, dt)
    timer.update(game, dt)
    board.update(game, dt)
    hand.update(game, dt)
    transition.update(game, dt)
    tween.update(game, dt)
    element.update(game, dt)
end

return logic
