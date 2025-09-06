local board = import("board")
local hand = import("hand")
local element = import("element")
local transition = import("transition")
local player = import("player")
local timer = import("timer")
local input = import("input")
local drag = import("drag")
local drop = import("drop")
local log = import("log")
local tests = import("tests")

local logic = {}

---Initializes the initial game state
---@param game Game
function logic.init(game)
    _G.uid_counter = 0

    board.init(game)
    player.init(game)

    drag.init(game)
    drop.init(game)

    tests.addElementToBoard(game)
end

---Restarts the game
---@param game Game
function logic.restart(game)
    game.state:clear()
    logic.init(game)
end

---@param game Game
local function checkDevInput(game)
    local state = game.state
    if input.is_key_released(state, "f11") then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen, "desktop")
    end

    if input.is_key_released(state, "r") then
        logic.restart(game)
    end

    if input.is_key_released(state, "t") then
        tests.transition(game)
    end
end

---Updates the game state each frame
---@param game Game
---@param dt number Time elapsed since the last frame in seconds
function logic.update(game, dt)
    checkDevInput(game)
    drag.update(game, dt)
    drop.update(game, dt)
    timer.update(game, dt)
    board.update(game, dt)
    hand.update(game, dt)
    transition.update(game, dt)
    element.update(game, dt)
end

return logic
