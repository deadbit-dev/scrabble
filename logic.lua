local love = require("love")
local conf = require("conf")
local logic = {}

---Initializes the game board by creating empty cells with multipliers
---@param state State
local function initBoard(state)
    for i = 1, conf.field.size do
        state.board.cells[i] = {}
        state.board.elements[i] = {}
        for j = 1, conf.field.size do
            state.board.cells[i][j] = {
                multiplier = conf.field.multipliers[i][j]
            }
            state.board.elements[i][j] = nil
        end
    end
end

---Initializes the initial game state
---@param state State
function logic.init(state)
    initBoard(state)

    state.board.elements[1][1] = { letter = "H", points = 4 }
    state.board.elements[1][2] = { letter = "E", points = 1 }
    state.board.elements[1][3] = { letter = "L", points = 1 }
    state.board.elements[1][4] = { letter = "L", points = 1 }
    state.board.elements[1][5] = { letter = "O", points = 1 }
end

---Handles key presses
---@param state State
---@param key string
function logic.keypressed(state, key)
    if key == "f11" then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen, "desktop")
    end
end

---Updates the game state each frame
---@param state State
---@param dt number Time elapsed since the last frame in seconds
function logic.update(state, dt)
end

return logic
