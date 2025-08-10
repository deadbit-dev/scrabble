local tween = import("tween")
local board = import("board")
local transition = import("transition")
local player = import("player")
local timer = import("timer")

local logic = {}

---Initializes the initial game state
---@param game Game
function logic.init(game)
    local conf = game.conf
    local state = game.state
    
    _G.uid_counter = 0

    board.init(conf, state)
    player.init(state)

    board.addElement(state, 2, 1, createElement(state, "H", conf.elements.english["H"].points))
    board.addElement(state, 2, 2, createElement(state, "E", conf.elements.english["E"].points))
    board.addElement(state, 2, 3, createElement(state, "L", conf.elements.english["L"].points))
    board.addElement(state, 2, 4, createElement(state, "L", conf.elements.english["L"].points))
    board.addElement(state, 2, 5, createElement(state, "O", conf.elements.english["O"].points))
    
    board.addElement(state, 1, 5, createElement(state, "W", conf.elements.english["W"].points))
    board.addElement(state, 3, 5, createElement(state, "R", conf.elements.english["R"].points))
    board.addElement(state, 4, 5, createElement(state, "L", conf.elements.english["L"].points))
    board.addElement(state, 5, 5, createElement(state, "D", conf.elements.english["D"].points))
end

function logic.restart(game)
    clearState(game.state)
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
    timer.update(game.state, dt)
    transition.update(game.state, dt)
end

function testTransition(game)
    local elem_uid = createElement(game.state, "A", 1)
    local hand_uid = game.state.players[game.state.current_player_uid].hand_uid
    transition.poolToHand(game, elem_uid, hand_uid, 1, function()
        timer.delay(game.state, 0.25, function()
            transition.handToBoard(game, hand_uid, 1, 1, 15, function()
                removeElement(game.state, elem_uid)
            end)
        end)
    end)
end

return logic
