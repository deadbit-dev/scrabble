local game = {}

require("core.hotreload")

local conf = import("conf")
local state = import("state")
local resources = import("resources")

local input = import("core.input")
local tween = import("core.tween")

local board = import("board")
local player = import("player")
local hand = import("hand")
local element = import("element")
local selection = import("selection")
local drag = import("drag")
local drop = import("drop")
local transition = import("transition")

local cheats = import("cheats")
local tests = import("tests")

function game.init()
    _G.uid_counter = 0

    resources.load()

    board.init(state, conf)
    player.init(state, conf)

    tests.add_element_to_board(state, conf)
end

local function check_restart()
    if not state.is_restart then
        return
    end

    game.clear()
    game.init()
end

local lurker = require("core.lurker")
---@param dt number
function game.update(dt)
    lurker.update()

    check_restart()

    input.update(state, conf, dt)

    cheats.update(state, conf, dt)

    board.update(state, conf, dt)
    hand.update(state, conf, dt)
    selection.update(state, conf, dt)
    drag.update(state, conf, dt)
    drop.update(state, conf, dt)

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

function game.clear()
    state = {
        is_restart = false,
        cells = {},
        elements = {},
        pool = {},
        board = {
            transform = { x = 0, y = 0, width = 0, height = 0, z_index = 0 },
            cell_uids = {},
            elem_uids = {}
        },
        hands = {},
        players = {},
        transitions = {},
        tweens = {},
        timers = {},
        current_player_uid = nil,
        selected_element_uid = nil,
        drag = {
            active = false,
            element_uid = nil,
            original_space = nil
        },
        input = {
            mouse = {
                x = 0,
                y = 0,
                dx = 0,
                dy = 0,
                buttons = {},
                last_click_pos = nil,
                last_click_time = 0,
                click_pos = nil,
                is_drag = false,
                is_click = false,
                is_double_click = false
            },
            keyboard = {
                buttons = {}
            }
        }
    }
end

---@param key string
function game.keypressed(key)
    input.keypressed(state, key)
end

---@param key string
function game.keyreleased(key)
    input.keyreleased(state, key)
end

---@param x number
---@param y number
---@param button number
function game.mousepressed(x, y, button)
    input.mousepressed(state, x, y, button)
end

---@param x number
---@param y number
---@param dx number
---@param dy number
function game.mousemoved(x, y, dx, dy)
    input.mousemoved(state, x, y, dx, dy)
end

---@param x number
---@param y number
---@param button number
function game.mousereleased(x, y, button)
    input.mousereleased(state, x, y, button)
end

return game
