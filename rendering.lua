local resources = import("resources")
local transition = import("transition")
local board = import("board")
local hand = import("hand")
local element = import("element")

local rendering = {}

---Draws the game board and all its elements
---@param game Game
function rendering.draw(game)
    local conf = game.conf
    local state = game.state

    --- IDEA: calculate dimensions and other render-dependendent params once in draw and keep them in game state, other will be it read from there

    love.graphics.clear(conf.colors.background)

    board.draw(game)
    hand.draw(game)

    -- NOTE: Sort elements by z_index before drawing
    local sorted_elements = {}
    for _, elem in pairs(state.elements) do
        table.insert(sorted_elements, elem)
    end
    table.sort(sorted_elements, function(a, b) return a.z_index < b.z_index end)

    for _, elem in pairs(sorted_elements) do
        element.draw(game, elem)
    end
end

return rendering
