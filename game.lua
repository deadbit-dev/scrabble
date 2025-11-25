local game = {}

local conf = import("conf")
local state = import("state")
local resources = import("resources")

local input = import("input")

local timer = import("timer")
local tween = import("tween")

local board = import("board")
local player = import("player")
local hand = import("hand")
local element = import("element")
local selection = import("selection")
local dragdrop = import("drag&drop")
local transition = import("transition")

local cheats = import("cheats")
local tests = import("tests")

function game.init()
    _G.uid_counter = 0
    state:init()

    resources.load()

    board.setup(state, conf)
    player.setup(state, conf)

    tests.add_element_to_board(state, conf)
end

function game.update(dt)
    if state.is_restart then game.init() end

    timer.update(state, dt)

    input.update(state, conf, dt)

    cheats.update(state, conf, dt)

    board.update(state, conf, dt)
    hand.update(state, conf, dt)
    selection.update(state, conf, dt)
    dragdrop.update(state, conf, dt)

    transition.update(state, conf, dt)
    tween.update(state, dt)

    input.clear(state)
end

function game.draw()
    love.graphics.clear(conf.colors.background)

    board.draw(state, conf, resources)
    hand.draw(state, conf, resources)
    element.draw(state, conf, resources)
end

function game.input(action_id, action)
    if action_id == Action.KEY_PRESSED then
        input.keypressed(state, action.key)
    end

    if action_id == Action.KEY_RELEASED then
        input.keyreleased(state, action.key)
    end

    if action_id == Action.MOUSE_PRESSED then
        input.mousepressed(state, action.x, action.y, action.button)
    end

    if action_id == Action.MOUSE_MOVED then
        input.mousemoved(state, action.x, action.y, action.dx, action.dy)
    end

    if action_id == Action.MOUSE_RELEASED then
        input.mousereleased(state, action.x, action.y, action.button)
    end
end

return game
