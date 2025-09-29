local Drag = {}

local function start_drag(game)
    local state = game.state
    local Input = game.engine.Input
    local Board = game.logic.Board
    local HandManager = game.logic.HandManager
    local ElementsManager = game.logic.ElementsManager
    local Space = game.logic.Space

    local click_pos = Input.get_click_pos(state)
    if not click_pos then return end

    -- Находим элемент в позиции клика
    local element_uid = nil
    for _, elem in pairs(state.elements) do
        if ElementsManager.is_point_in_element_bounds(click_pos, elem) then
            element_uid = elem.uid
            break
        end
    end

    if not element_uid then return end

    local elemenet_data = ElementsManager.get_state(game, element_uid)
    if not elemenet_data then return end

    local type = elemenet_data.space.type
    local data = elemenet_data.space.data

    -- Сохраняем состояние драга
    state.drag.active = true
    state.drag.element_uid = element_uid
    state.drag.original_space = {
        type = type,
        data = data
    }

    if type == SpaceType.HAND then
        HandManager.remove_element(game, data.hand_uid, data.index)
    elseif type == SpaceType.BOARD then
        Board.remove_element(game, data.x, data.y)
    end

    local mouse_pos = Input.get_mouse_pos(state)
    local target_x = mouse_pos.x
    local target_y = mouse_pos.y
    local target_transform = Space.get_world_transform_in_screen_space(game, target_x, target_y)
    target_transform.x = target_transform.x - elemenet_data.transform.width / 2
    target_transform.y = target_transform.y - elemenet_data.transform.height / 2
    Space.set_space(game, element_uid, Space.create_screen_space(target_transform.x, target_transform.y))
end

local function update_drag(game, dt)
    local state = game.state
    local Input = game.engine.Input
    local ElementsManager = game.logic.ElementsManager
    local Space = game.logic.Space

    if (state.drag.active and state.drag.element_uid) then
        local element_data = ElementsManager.get_state(game, state.drag.element_uid)
        if element_data then
            local mouse_pos = Input.get_mouse_pos(state)
            local target_x = mouse_pos.x
            local target_y = mouse_pos.y
            local target_transform = Space.get_world_transform_in_screen_space(game, target_x, target_y)
            target_transform.x = target_transform.x - element_data.transform.width / 2
            target_transform.y = target_transform.y - element_data.transform.height / 2
            Space.set_space(game, element_data.uid, Space.create_screen_space(target_transform.x, target_transform.y))
        end
    end
end

local function end_drag(game)
    local state = game.state
    local ElementsManager = game.logic.ElementsManager
    local Space = game.logic.Space

    if state.drag.element_uid and state.drag.original_space then
        local element_data = ElementsManager.get_state(game, state.drag.element_uid)
        if element_data then
            -- Возвращаем элемент в исходное место
            Space.set_space(game, element_data.uid, state.drag.original_space)
        end

        -- Сбрасываем состояние драга
        state.drag.active = false
        state.drag.element_uid = nil
        state.drag.original_space = nil
    end
end

function Drag.update(game, dt)
    local state = game.state
    local Input = game.engine.Input

    -- Начинаем драг когда input определяет это
    if Input.is_drag(state) and not state.drag.active then
        start_drag(game)
    end

    -- Обновляем позицию во время драга
    if state.drag.active then
        update_drag(game, dt)
    end

    -- Завершаем драг когда input сообщает об окончании
    if not Input.is_drag(state) and state.drag.active then
        end_drag(game)
    end
end

return Drag
