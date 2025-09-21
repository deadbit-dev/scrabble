local utils = import("utils")

local input = {}

---Находит элемент по позиции мыши
---@param game Game
---@param mouse_pos {x: number, y: number}
---@return number|nil element_uid
local function getElementAtPosition(game, mouse_pos)
    local state = game.state
    for _, elem in pairs(state.elements) do
        if utils.isPointInElementBounds(mouse_pos, elem) then
            return elem.uid
        end
    end
    return nil
end

function input.init(game)
    -- love.keyboard.setKeyRepeat(true)
end

----Определяет тип взаимодействия и обновляет состояние
---@param game Game
---@param dt number
function input.update(game, dt)
    local state = game.state
    local conf = game.conf
    local mouse = state.input.mouse

    -- Сбрасываем тип действия в начале кадра
    mouse.action_type = nil
    mouse.click_target_uid = nil

    if input.is_mouse_pressed(state, 1) then
        local mouse_pos = input.get_mouse_pos(state)

        -- Если драг еще не активен, проверяем начало взаимодействия
        if not mouse.drag_active then
            local element_uid = getElementAtPosition(game, mouse_pos)
            mouse.click_target_uid = element_uid
            mouse.last_click_pos = { x = mouse_pos.x, y = mouse_pos.y }
            mouse.last_click_time = love.timer.getTime()

            -- Если есть элемент под курсором, начинаем отслеживание драга
            if element_uid then
                mouse.drag_element_uid = element_uid
            end
        end
    end

    -- Если мышь нажата и есть элемент для драга
    if input.is_mouse_pressed(state, 1) and mouse.drag_element_uid then
        local mouse_pos = input.get_mouse_pos(state)

        -- Проверяем, нужно ли начинать драг
        local temp_state = {
            drag_start_pos = mouse.last_click_pos,
            drag_start_time = mouse.last_click_time
        }
        if not mouse.drag_active and utils.shouldStartDrag(temp_state, mouse_pos, conf) then
            mouse.drag_active = true
            mouse.action_type = "drag"
        end
    end

    -- Обрабатываем отпускание мыши
    if input.is_mouse_released(state, 1) then
        local mouse_pos = input.get_mouse_pos(state)
        local current_time = love.timer.getTime()

        if mouse.drag_active then
            -- Завершаем драг
            mouse.drag_active = false
            mouse.drag_element_uid = nil
        else
            -- Проверяем тип клика
            local element_uid = getElementAtPosition(game, mouse_pos)

            if element_uid then
                -- Проверяем двойной клик
                if (current_time - mouse.last_click_time) < conf.click.double_click_threshold and
                    mouse.last_click_time > 0 then
                    mouse.action_type = "double"
                else
                    mouse.action_type = "single"
                end
                mouse.click_target_uid = element_uid
            end
        end

        -- Сбрасываем состояние клика
        mouse.last_click_pos = nil
        mouse.last_click_time = 0
    end
end --@param game Game

---@param key string
function input.keypressed(game, key)
    if (game.state.input.keyboard.buttons[key] == nil) then
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
    if (game.state.input.mouse.buttons[button] == nil) then
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
    if (button == nil) then
        button = 1
    end

    return state.input.mouse.buttons[button] and state.input.mouse.buttons[button].pressed
end

---@param state State
---@param button number
function input.is_mouse_released(state, button)
    if (button == nil) then
        button = 1
    end

    return state.input.mouse.buttons[button] and state.input.mouse.buttons[button].released
end

---@param state State
function input.get_mouse_pos(state)
    return { x = state.input.mouse.x, y = state.input.mouse.y }
end

-- Action methods
---@param state State
---@return string|nil
function input.get_action_type(state)
    return state.input.mouse.action_type
end

---@param state State
---@return number|nil
function input.get_click_target_uid(state)
    return state.input.mouse.click_target_uid
end

---@param state State
---@return number
function input.get_last_click_time(state)
    return state.input.mouse.last_click_time
end

---@param state State
---@return {x: number, y: number}|nil
function input.get_last_click_pos(state)
    return state.input.mouse.last_click_pos
end

-- Drag methods
---@param state State
---@return boolean
function input.is_drag_active(state)
    return state.input.mouse.drag_active
end

---@param state State
---@return number|nil
function input.get_drag_element_uid(state)
    return state.input.mouse.drag_element_uid
end

return input
