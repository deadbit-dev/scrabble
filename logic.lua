local tween = import("tween")
local board = import("board")
local element = import("element")
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

    board.addElement(state, 2, 1, element.create(state, "H", conf.elements.english["H"].points))
    board.addElement(state, 2, 2, element.create(state, "E", conf.elements.english["E"].points))
    board.addElement(state, 2, 3, element.create(state, "L", conf.elements.english["L"].points))
    board.addElement(state, 2, 4, element.create(state, "L", conf.elements.english["L"].points))
    board.addElement(state, 2, 5, element.create(state, "O", conf.elements.english["O"].points))
    
    board.addElement(state, 1, 5, element.create(state, "W", conf.elements.english["W"].points))
    board.addElement(state, 3, 5, element.create(state, "R", conf.elements.english["R"].points))
    board.addElement(state, 4, 5, element.create(state, "L", conf.elements.english["L"].points))
    board.addElement(state, 5, 5, element.create(state, "D", conf.elements.english["D"].points))
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



return logic
