local input = {}

function input.init(game)
    -- love.keyboard.setKeyRepeat(true)
end

---@param game Game
---@param key string
function input.keypressed(game, key)
    if( game.state.input.keyboard.buttons[key] == nil ) then
        game.state.input.keyboard.buttons[key] = {
            pressed = false,
            released = false
        }
    end

    game.state.input.keyboard.buttons[key].pressed = true
    game.state.input.keyboard.buttons[key].released = false
end

---@param game Game
---@param key string
function input.keyreleased(game, key)
    game.state.input.keyboard.buttons[key].released = true
    game.state.input.keyboard.buttons[key].pressed = false
end

---@param game Game
---@param x number
---@param y number
---@param button number
function input.mousepressed(game, x, y, button)
    if( game.state.input.mouse.buttons[button] == nil ) then
        game.state.input.mouse.buttons[button] = {
            pressed = false,
            released = false
        }
    end

    game.state.input.mouse.buttons[button].pressed = true
    game.state.input.mouse.buttons[button].released = false
end

---@param game Game
---@param x number
---@param y number
---@param dx number
---@param dy number
function input.mousemoved(game, x, y, dx, dy)
    game.state.input.mouse.x = x
    game.state.input.mouse.y = y
    game.state.input.mouse.dx = dx
    game.state.input.mouse.dy = dy
end

---@param game Game
---@param x number
---@param y number
---@param button number
function input.mousereleased(game, x, y, button)
    game.state.input.mouse.buttons[button].released = true
    game.state.input.mouse.buttons[button].pressed = false
end

---@param game Game
function input.clear(game)
    local state = game.state

    for _, button in pairs(state.input.mouse.buttons) do
        if( button.released ) then
            button.released = false
        end
    end

    for _, button in pairs(state.input.keyboard.buttons) do
        if( button.released ) then
            button.released = false
        end
    end
end

---@param state State
---@param key string
function input.is_key_pressed(state, key)
    return state.input.keyboard.buttons[key] and state.input.keyboard.buttons[key].pressed
end

---@param state State
---@param key string
function input.is_key_released(state, key)
    return state.input.keyboard.buttons[key] and state.input.keyboard.buttons[key].released
end

---@param state State
---@param button number
function input.is_mouse_pressed(state, button)
    if(button == nil) then
        button = 1
    end

    return state.input.mouse.buttons[button] and state.input.mouse.buttons[button].pressed
end

---@param state State
---@param button number
function input.is_mouse_released(state, button)
    if(button == nil) then
        button = 1
    end

    return state.input.mouse.buttons[button] and state.input.mouse.buttons[button].released
end

---@param state State
function input.get_mouse_pos(state)
    return {x = state.input.mouse.x, y = state.input.mouse.y}
end

return input