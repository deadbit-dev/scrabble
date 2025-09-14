local resources = import("resources")
local board = import("board")
local hand = import("hand")
local element = import("element")
local log = import("log")
local rendering = {}

function rendering.init(game)
    local imageData = resources.imageData.cursor
    local cur = love.mouse.newCursor(imageData, imageData:getWidth() * 0.5, imageData:getHeight() * 0.5)
    love.mouse.setCursor(cur)
end

---Draws the game board and all its elements
---@param game Game
function rendering.draw(game)
    local conf = game.conf
    local state = game.state

    love.graphics.clear(conf.colors.background)

    board.draw(game)
    hand.draw(game)

    -- NOTE: Sort elements by transform.z_index before drawing
    local sorted_elements = {}
    for _, elem in pairs(state.elements) do
        table.insert(sorted_elements, elem)
    end
    table.sort(sorted_elements, function(a, b) return a.transform.z_index < b.transform.z_index end)

    for _, elem in pairs(sorted_elements) do
        element.draw(game, elem)
    end
end

return rendering
