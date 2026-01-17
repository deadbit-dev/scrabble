-- FIXME/TODO: change input state once instead of into love input callback
-- FIXME: почему то при долгом удерживании драг не определяется
-- TODO: проверку дабл клика

local input = {}

local utils = import("utils")

---@class Pos
---@field x number
---@field y number

---@class ButtonState
---@field pressed boolean
---@field released boolean

---@class MouseState
---@field x number
---@field y number
---@field dx number
---@field dy number
---@field wheel number
---@field buttons {[number]: ButtonState}
---@field press_time number
---@field last_click_time number
---@field last_click_pos Pos|nil
---@field press_pos Pos|nil
---@field click_pos Pos|nil
---@field is_drag boolean
---@field is_click boolean
---@field is_double_click boolean

---@class KeyboardState
---@field buttons {[string]: ButtonState}

---@class InputState
---@field mouse MouseState
---@field keyboard KeyboardState

---@param conf Config
---@param drag_start_time number
---@return boolean
local function is_drag_time_exceeded(conf, drag_start_time)
    return (love.timer.getTime() - drag_start_time) > conf.click.drag_threshold_time
end

---@param conf Config
---@param drag_start_pos Pos
---@param current_pos Pos
---@return boolean
local function is_drag_distance_exceeded(conf, drag_start_pos, current_pos)
    if not drag_start_pos then
        return false
    end

    local distance = utils.get_distance(drag_start_pos, current_pos)
    return distance > conf.click.drag_threshold_distance
end

---@param conf Config
---@param drag_start_pos Pos
---@param drag_start_time number
---@param current_pos Pos
---@return boolean
local function should_start_drag(conf, drag_start_pos, drag_start_time, current_pos)
    return is_drag_time_exceeded(conf, drag_start_time) or is_drag_distance_exceeded(conf, drag_start_pos, current_pos)
end

---@return InputState
function input.init()
    return {
        mouse = {
            x = 0,
            y = 0,
            dx = 0,
            dy = 0,
            wheel = 0,
            buttons = {},
            press_time = 0,
            last_click_time = 0,
            last_click_pos = nil,
            click_pos = nil,
            is_drag = false,
            is_click = false,
            is_double_click = false
        },
        keyboard = {
            buttons = {}
        }
    }
end

---@param state InputState
---@param conf Config
---@param dt number
function input.update(state, conf, dt)
    local mouse = state.mouse

    if input.is_mouse_pressed(state, 1) then
        if mouse.press_pos == nil then
            local mouse_pos = input.get_mouse_pos(state)

            -- NOTE: keep mouse pos
            if not mouse.is_drag then
                mouse.press_pos = { x = mouse_pos.x, y = mouse_pos.y }
                mouse.press_time = love.timer.getTime()
            end
        else
            local mouse_pos = input.get_mouse_pos(state)

            -- NOTE: drag check
            if not mouse.is_drag and should_start_drag(conf, mouse.press_pos, mouse.press_time, mouse_pos) then
                mouse.is_drag = true
            end
        end
    end

    if input.is_mouse_released(state, 1) then
        local current_time = love.timer.getTime()

        if mouse.is_drag then
            mouse.is_drag = false
        else
            -- NOTE: double click check
            if (current_time - mouse.last_click_time) < conf.click.double_click_threshold and
                mouse.last_click_time > 0 then
                mouse.is_double_click = true
            else
                mouse.is_click = true
            end
            mouse.last_click_time = current_time
            mouse.click_pos = input.get_mouse_pos(state)
        end

        mouse.press_pos = nil
    end
end

---@param state InputState
function input.clear(state)
    state.mouse.is_click = false
    state.mouse.is_double_click = false

    state.mouse.dx = 0
    state.mouse.dy = 0

    state.mouse.wheel = 0

    for _, button in pairs(state.mouse.buttons) do
        if (button.released) then
            button.released = false
        end
    end

    for _, button in pairs(state.keyboard.buttons) do
        if (button.released) then
            button.released = false
        end
    end
end

---@param state InputState
---@param key string
function input.keypressed(state, key)
    if (state.keyboard.buttons[key] == nil) then
        state.keyboard.buttons[key] = {
            pressed = false,
            released = false
        }
    end

    state.keyboard.buttons[key].pressed = true
    state.keyboard.buttons[key].released = false
end

---@param state InputState
---@param key string
function input.keyreleased(state, key)
    state.keyboard.buttons[key].released = true
    state.keyboard.buttons[key].pressed = false
end

---@param state InputState
---@param x number
---@param y number
---@param button number
function input.mousepressed(state, x, y, button)
    if (state.mouse.buttons[button] == nil) then
        state.mouse.buttons[button] = {
            pressed = false,
            released = false
        }
    end

    state.mouse.buttons[button].pressed = true
    state.mouse.buttons[button].released = false
    state.mouse.x = x
    state.mouse.y = y
end

---@param state InputState
---@param x number
---@param y number
---@param dx number
---@param dy number
function input.mousemoved(state, x, y, dx, dy)
    state.mouse.x = x
    state.mouse.y = y
    state.mouse.dx = dx
    state.mouse.dy = dy
end

---@param state InputState
---@param x number
---@param y number
---@param button number
function input.mousereleased(state, x, y, button)
    state.mouse.buttons[button].released = true
    state.mouse.buttons[button].pressed = false
    state.mouse.x = x
    state.mouse.y = y
end

---@param state InputState
---@param delta number
function input.mousewheelmoved(state, delta)
    state.mouse.wheel = delta
end

---@param state InputState
---@param key string
---@return boolean
function input.is_key_pressed(state, key)
    return state.keyboard.buttons[key] and state.keyboard.buttons[key].pressed
end

---@param state InputState
---@param key string
---@return boolean
function input.is_key_released(state, key)
    return state.keyboard.buttons[key] and state.keyboard.buttons[key].released
end

---@param state InputState
---@param button number
---@return boolean
function input.is_mouse_pressed(state, button)
    if (button == nil) then
        button = 1
    end

    return state.mouse.buttons[button] and state.mouse.buttons[button].pressed
end

---@param state InputState
---@param button number
---@return boolean
function input.is_mouse_released(state, button)
    if (button == nil) then
        button = 1
    end

    return state.mouse.buttons[button] and state.mouse.buttons[button].released
end

---@param state InputState
---@return Pos
function input.get_mouse_pos(state)
    return { x = state.mouse.x, y = state.mouse.y }
end

return input
