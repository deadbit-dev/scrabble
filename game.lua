local game = {}

local conf = import("conf")
local state = import("state")
local resources = import("resources")

local input = import("input")

local tween = import("tween")

local board = import("board")
local player = import("player")
local hand = import("hand")
local element = import("element")
local selection = import("selection")
local dragdrop = import("drag&drop")
local transition = import("transition")


function GENERATE_UID()
    if (_G.uid_counter == nil) then _G.uid_counter = 0 end
    _G.uid_counter = _G.uid_counter + 1
    return _G.uid_counter
end

function game.init()
    _G.uid_counter = 0

    state:init()

    resources.load()

    board.setup(state, conf)
    player.setup(state, conf)

    -- NOTE: for test
    board.add_element(state, conf, 6, 8, element.create(state, conf, "H"))
    board.add_element(state, conf, 7, 8, element.create(state, conf, "E"))
    board.add_element(state, conf, 8, 8, element.create(state, conf, "L"))
    board.add_element(state, conf, 9, 8, element.create(state, conf, "L"))
    board.add_element(state, conf, 10, 7, element.create(state, conf, "W"))
    board.add_element(state, conf, 10, 9, element.create(state, conf, "R"))
    board.add_element(state, conf, 10, 10, element.create(state, conf, "L"))
    board.add_element(state, conf, 10, 11, element.create(state, conf, "D"))
end

function game.update(dt)
    if state.is_restart then game.init() end

    input.update(state, conf, dt)

    if input.is_key_released(state, "f11") then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen, "desktop")
    end

    if input.is_key_released(state, "r") then
        state.is_restart = true
    end

    board.update(state, conf, dt)
    hand.update(state, conf, dt)
    selection.update(state, conf, dt)
    dragdrop.update(state, conf, resources, dt)

    transition.update(state, conf, dt)
    tween.update(state, dt)

    input.clear(state)
end

function game.draw()
    love.graphics.clear(conf.colors.background)

    board.draw(state, conf, resources)
    hand.draw(state, conf, resources)

    -- NOTE: Sort elements by transform.z_index before drawing
    local sorted_elements = {}
    for _, elem in pairs(state.elements) do
        table.insert(sorted_elements, elem)
    end
    table.sort(sorted_elements, function(a, b) return a.world_transform.z_index < b.world_transform.z_index end)

    for _, elem in pairs(sorted_elements) do
        element.draw(conf, resources, elem)
    end
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
