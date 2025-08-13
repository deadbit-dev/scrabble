local log = import("log")
local resources = import("resources")
local board = import("board")
local hand = import("hand")
local transition = import("transition")

local rendering = {}

---Draws all transitions
---@param conf Config
---@param state State
local function drawTransitions(conf, state)
    for _, trans in ipairs(state.transitions) do
        transition.draw(conf, state, trans)
    end
end

---Draws the game board and all its elements
---@param game Game
function rendering.draw(game)
    local conf = game.conf
    local state = game.state

    --- IDEA: calculate dimensions and other render-dependendent params once in draw and keep them in game state, other will be it read from there

    love.graphics.clear(conf.colors.background)

    board.draw(conf, state)
    hand.draw(conf, state)
    drawTransitions(conf, state)
end

return rendering
