local tween = import("tween")
local utils = import("utils")
local board = import("board")

local logic = {}

local uid_counter = 0
---Generates a unique identifier
---@return number
local function generate_uid()
    uid_counter = uid_counter + 1
    return uid_counter
end

---Creates a cell
---@param state State
---@param multiplier number
---@return number
local function createCell(state, multiplier)
    local cell_uid = generate_uid()
    state.cells[cell_uid] = { uid = cell_uid, multiplier = multiplier }
    return cell_uid
end

---Sets a cell on the board
---@param state State
---@param x number
---@param y number
---@param cell_uid number
local function addCellToBoard(state, x, y, cell_uid)
    state.board.cell_uids[x][y] = cell_uid
end

---Creates an element
---@param state State
---@param letter string
---@param points number
---@return number
local function createElement(state, letter, points)
    local elem_uid = generate_uid()
    state.elements[elem_uid] = { uid = elem_uid, letter = letter, points = points }
    return elem_uid
end

---Removes an element
---@param state State
---@param elem_uid number
local function removeElement(state, elem_uid)
    state.elements[elem_uid] = nil
end

---Sets an element on the board
---@param state State
---@param x number
---@param y number
---@param elem_uid number
local function addElementToBoard(state, x, y, elem_uid)
    state.board.elem_uids[x][y] = elem_uid
end

---Initializes the game board by creating empty cells with multipliers
---@param conf Config
---@param state State
local function initBoard(conf, state)
    for i = 1, conf.field.size do
        state.board.cell_uids[i] = {}
        state.board.elem_uids[i] = {}
        for j = 1, conf.field.size do
            addCellToBoard(state, i, j, createCell(state, conf.field.multipliers[i][j]))
        end
    end
end

---@param state State
local function initHand(state)
    local hand_uid = generate_uid()
    state.hands[hand_uid] = { uid = hand_uid, elem_uids = {} }
    return hand_uid
end

local function initPlayer(state)
    local player_uid = generate_uid()
    local hand_uid = initHand(state)
    state.players[player_uid] = { uid = player_uid, hand_uid = hand_uid }
    state.current_player_uid = player_uid

    -- NOTE: for test
    table.insert(state.hands[hand_uid].elem_uids, createElement(state, "A", 1))
    table.insert(state.hands[hand_uid].elem_uids, createElement(state, "B", 2))
    table.insert(state.hands[hand_uid].elem_uids, createElement(state, "C", 3))
    table.insert(state.hands[hand_uid].elem_uids, createElement(state, "D", 4))
    table.insert(state.hands[hand_uid].elem_uids, createElement(state, "E", 5))
end

---Creates a transition
---@param state State
---@param elem_uid number
---@param duration number
---@param easing function
---@param from SpaceInfo
---@param to SpaceInfo
---@param onComplete function|nil
---@return number
local function createTransition(conf, state, elem_uid, duration, easing, from, to, onComplete)
    local element = board.getElem(state, elem_uid)
    table.insert(state.transitions, {
        uid = elem_uid,
        tween = tween.new(
            duration,
            utils.getWorldParamsFromSpaceInfo(conf, from, element),
            utils.getWorldParamsFromSpaceInfo(conf, to, element),
            easing
        ),
        onComplete = onComplete,
    })

    return #state.transitions
end

---Removes a transition
---@param state State
---@param idx number
local function removeTransition(state, idx)
    table.remove(state.transitions, idx)
end

local function updateTransitions(state, dt)
    for i = #state.transitions, 1, -1 do
        local transition = state.transitions[i]
        if transition.tween ~= nil then
            if transition.tween:update(dt) then
                if transition.onComplete then
                    transition.onComplete()
                end
                removeTransition(state, i)
            end
        end
    end
end

local function poolToHandTransition(game, elem_uid, onComplete)
    createTransition(game.conf, game.state, elem_uid, 0.7, tween.easing.inOutCubic,
        -- NOTE: from right of the screen - from pool
        {
            type = "screen",
            data = {
                x = love.graphics.getWidth(),
                y = love.graphics.getHeight() / 2
            }
        },

        -- NOTE: to bottom of the screen - to hand
        {
            type = "screen",
            data = {
                x = 50,
                y = 800
            }
        },
        onComplete

    )
end

local function handToBoardTransition(game, elem_uid, onComplete)
    createTransition(game.conf, game.state, elem_uid, 0.7, tween.easing.inOutCubic,
        -- NOTE: from bottom of the screen - from hand
        -- TODO: hand space
        {
            type = "screen",
            data = {
                x = 50,
                y = 800
            }
        },

        -- NOTE: to left bottom corner of the board - to board
        {
            type = "board",
            data = {
                x = 1,
                y = 15
            }
        },
        onComplete
    )
end

local function testTransition(game)
    local elem_uid = createElement(game.state, "A", 1)
    poolToHandTransition(game, elem_uid, function()
        utils.timer(game.state, 0.25, function()
            handToBoardTransition(game, elem_uid)
        end)
    end)
end

local function updateTimers(state, dt)
    for i = #state.timers, 1, -1 do
        local timer = state.timers[i]
        if timer:update(dt) then
            table.remove(state.timers, i)
        end
    end
end

---Initializes the initial game state
---@param game Game
function logic.init(game)
    local conf = game.conf
    local state = game.state

    initBoard(conf, state)
    initPlayer(state)

    addElementToBoard(state, 1, 1, createElement(state, "H", 4))
    addElementToBoard(state, 1, 2, createElement(state, "E", 1))
    addElementToBoard(state, 1, 3, createElement(state, "L", 1))
    addElementToBoard(state, 1, 4, createElement(state, "L", 1))
    addElementToBoard(state, 1, 5, createElement(state, "O", 1))
end

function logic.restart(game)
    uid_counter = 0
    utils.clearState(game.state)
    logic.init(game)
end

---Handles key presses
---@param game Game
---@param key string
function logic.keypressed(game, key)
    if key == "f11" then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen, "desktop")
    end

    if key == "r" then
        logic.restart(game)
    end

    if key == "t" then
        testTransition(game)
    end
end

---Updates the game state each frame
---@param game Game
---@param dt number Time elapsed since the last frame in seconds
function logic.update(game, dt)
    updateTimers(game.state, dt)
    updateTransitions(game.state, dt)
end

return logic
