local logic = {}

local uid_counter = 0
---Generates a unique identifier
---@return number
local function generate_uid()
    uid_counter = uid_counter + 1
    return uid_counter
end

---Sets a cell on the board
---@param state State
---@param x number
---@param y number
---@param multiplier number
local function addCell(state, x, y, multiplier)
    local cell_uid = generate_uid()
    state.cells[cell_uid] = { uid = cell_uid, multiplier = multiplier }
    state.board.cell_uids[x][y] = cell_uid
end

---Sets an element on the board
---@param state State
---@param x number
---@param y number
---@param letter string
---@param points number
local function addElement(state, x, y, letter, points)
    local elem_uid = generate_uid()
    state.elements[elem_uid] = { uid = elem_uid, letter = letter, points = points }
    state.board.elem_uids[x][y] = elem_uid
end

---Initializes the game board by creating empty cells with multipliers
---@param state State
local function initBoard(state)
    local conf = require("conf")
    for i = 1, conf.field.size do
        state.board.cell_uids[i] = {}
        state.board.elem_uids[i] = {}
        for j = 1, conf.field.size do
            addCell(state, i, j, conf.field.multipliers[i][j])
        end
    end
end

---Initializes the initial game state
---@param game Game
function logic.init(game)
    local state = game.state

    initBoard(state)

    addElement(state, 1, 1, "H", 4)
    addElement(state, 1, 2, "E", 1)
    addElement(state, 1, 3, "L", 1)
    addElement(state, 1, 4, "L", 1)
    addElement(state, 1, 5, "O", 1)
end

---Handles key presses
---@param game Game
---@param key string
function logic.keypressed(game, key)
    if key == "f11" then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen, "desktop")
    end
end

---Updates the game state each frame
---@param game Game
---@param dt number Time elapsed since the last frame in seconds
function logic.update(game, dt)
end

return logic
