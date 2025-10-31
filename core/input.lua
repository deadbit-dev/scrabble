-- Модуль управления вводом
local input = {}

local math_helper = require("helpers.Math")

---Проверяет, превышено ли время для определения драга
---@param conf Config
---@param drag_start_time number
---@return boolean
local function is_drag_time_exceeded(conf, drag_start_time)
    return (love.timer.getTime() - drag_start_time) > conf.click.drag_threshold_time
end

---Проверяет, превышена ли дистанция для определения драга
---@param conf Config
---@param drag_start_pos {x: number, y: number}
---@param current_pos {x: number, y: number}
---@return boolean
local function is_drag_distance_exceeded(conf, drag_start_pos, current_pos)
    if not drag_start_pos then
        return false
    end

    local distance = math_helper.get_distance(drag_start_pos, current_pos)
    return distance > conf.click.drag_threshold_distance
end

---Определяет, нужно ли начинать драг
---@param conf Config
---@param drag_start_pos {x: number, y: number}
---@param drag_start_time number
---@param current_pos {x: number, y: number}
---@return boolean
local function should_start_drag(conf, drag_start_pos, drag_start_time, current_pos)
    return is_drag_time_exceeded(conf, drag_start_time) or is_drag_distance_exceeded(conf, drag_start_pos, current_pos)
end

---Обновляет состояние ввода
---@param state State
---@param conf Config
---@param dt number
function input.update(state, conf, dt)
    local mouse = state.input.mouse

    -- Обрабатываем нажатие мыши
    if input.is_mouse_pressed(state, 1) and mouse.click_pos == nil then
        local mouse_pos = input.get_mouse_pos(state)

        -- Если драг еще не активен, запоминаем позицию клика
        if not mouse.is_drag then
            mouse.click_pos = { x = mouse_pos.x, y = mouse_pos.y }
            mouse.last_click_pos = { x = mouse_pos.x, y = mouse_pos.y }
            mouse.last_click_time = love.timer.getTime()
        end
    end

    -- Если мышь нажата, проверяем нужно ли начинать драг
    if input.is_mouse_pressed(state, 1) and mouse.click_pos ~= nil then
        local mouse_pos = input.get_mouse_pos(state)

        -- Проверяем, нужно ли начинать драг
        if not mouse.is_drag and should_start_drag(conf, mouse.click_pos, mouse.last_click_time, mouse_pos) then
            mouse.is_drag = true
        end
    end

    -- Обрабатываем отпускание мыши
    if input.is_mouse_released(state, 1) then
        local mouse_pos = input.get_mouse_pos(state)
        local current_time = love.timer.getTime()

        if mouse.is_drag then
            mouse.is_drag = false
        else
            -- Проверяем тип клика
            if mouse.click_pos then
                -- Проверяем двойной клик
                if (current_time - mouse.last_click_time) < conf.click.double_click_threshold and
                    mouse.last_click_time > 0 then
                    mouse.is_double_click = true
                else
                    mouse.is_click = true
                end
            end
        end

        -- Сбрасываем состояние клика
        mouse.last_click_pos = nil
        mouse.last_click_time = 0

        mouse.click_pos = nil
    end
end

---Обрабатывает нажатие клавиши
---@param state State
---@param key string
function input.keypressed(state, key)
    if (state.input.keyboard.buttons[key] == nil) then
        state.input.keyboard.buttons[key] = {
            pressed = false,
            released = false
        }
    end

    state.input.keyboard.buttons[key].pressed = true
    state.input.keyboard.buttons[key].released = false
end

---Обрабатывает отпускание клавиши
---@param state State
---@param key string
function input.keyreleased(state, key)
    state.input.keyboard.buttons[key].released = true
    state.input.keyboard.buttons[key].pressed = false
end

---Обрабатывает нажатие мыши
---@param state State
---@param x number
---@param y number
---@param button number
function input.mousepressed(state, x, y, button)
    if (state.input.mouse.buttons[button] == nil) then
        state.input.mouse.buttons[button] = {
            pressed = false,
            released = false
        }
    end

    state.input.mouse.buttons[button].pressed = true
    state.input.mouse.buttons[button].released = false
end

---Обрабатывает движение мыши
---@param state State
---@param x number
---@param y number
---@param dx number
---@param dy number
function input.mousemoved(state, x, y, dx, dy)
    state.input.mouse.x = x
    state.input.mouse.y = y
    state.input.mouse.dx = dx
    state.input.mouse.dy = dy
end

---Обрабатывает отпускание кнопки мыши
---@param state State
---@param x number
---@param y number
---@param button number
function input.mousereleased(state, x, y, button)
    state.input.mouse.buttons[button].released = true
    state.input.mouse.buttons[button].pressed = false
end

---Очищает временные состояния ввода
---@param state State
function input.clear(state)
    state.input.mouse.is_click = false
    state.input.mouse.is_double_click = false

    for _, button in pairs(state.input.mouse.buttons) do
        if (button.released) then
            button.released = false
        end
    end

    for _, button in pairs(state.input.keyboard.buttons) do
        if (button.released) then
            button.released = false
        end
    end
end

---Проверяет, нажата ли клавиша
---@param state State
---@param key string
---@return boolean
function input.is_key_pressed(state, key)
    return state.input.keyboard.buttons[key] and state.input.keyboard.buttons[key].pressed
end

---Проверяет, отпущена ли клавиша
---@param state State
---@param key string
---@return boolean
function input.is_key_released(state, key)
    return state.input.keyboard.buttons[key] and state.input.keyboard.buttons[key].released
end

---Проверяет, нажата ли кнопка мыши
---@param state State
---@param button number
---@return boolean
function input.is_mouse_pressed(state, button)
    if (button == nil) then
        button = 1
    end

    return state.input.mouse.buttons[button] and state.input.mouse.buttons[button].pressed
end

---Проверяет, отпущена ли кнопка мыши
---@param state State
---@param button number
---@return boolean
function input.is_mouse_released(state, button)
    if (button == nil) then
        button = 1
    end

    return state.input.mouse.buttons[button] and state.input.mouse.buttons[button].released
end

---Получает позицию мыши
---@param state State
---@return {x: number, y: number}
function input.get_mouse_pos(state)
    return { x = state.input.mouse.x, y = state.input.mouse.y }
end

---Получает позицию клика
---@param state State
---@return {x: number, y: number}|nil
function input.get_click_pos(state)
    return state.input.mouse.click_pos
end

---Получает время последнего клика
---@param state State
---@return number
function input.get_last_click_time(state)
    return state.input.mouse.last_click_time
end

---Получает позицию последнего клика
---@param state State
---@return {x: number, y: number}|nil
function input.get_last_click_pos(state)
    return state.input.mouse.last_click_pos
end

---Проверяет, активен ли драг
---@param state State
---@return boolean
function input.is_drag(state)
    return state.input.mouse.is_drag
end

---Проверяет, произошел ли клик
---@param state State
---@return boolean
function input.is_click(state)
    return state.input.mouse.is_click
end

---Проверяет, произошел ли двойной клик
---@param state State
---@return boolean
function input.is_double_click(state)
    return state.input.mouse.is_double_click
end

return input
