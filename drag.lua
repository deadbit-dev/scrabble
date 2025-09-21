local log = import("log")
local input = import("input")
local hand = import("hand")
local board = import("board")
local element = import("element")
local space = import("space")
local follow = import("follow")
local transition = import("transition")
local selection = import("selection")
local utils = import("utils")

local drag = {}

local function startDrag(game)
    local state = game.state
    local elem = element.get(game, input.get_drag_element_uid(state))
    if not elem then return end

    local type = elem.space.type
    local data = elem.space.data

    state.drag_original_space = {
        type = type,
        data = data
    }

    if type == "hand" then
        hand.removeElem(game, data.hand_uid, data.index)
    elseif type == "board" then
        board.removeElement(game, data.x, data.y)
    end

    local mouse_pos = input.get_mouse_pos(state)
    local target_x = mouse_pos.x
    local target_y = mouse_pos.y
    local target_transform = space.getWorldTransformInScreenSpace(game, target_x, target_y)
    target_transform.x = target_transform.x - elem.transform.width / 2
    target_transform.y = target_transform.y - elem.transform.height / 2
    space.set_space(game, elem.uid, space.createScreenSpace(target_transform.x, target_transform.y))
end

local function updateDrag(game, dt)
    local state = game.state

    if (input.is_drag_active(state) and state.drag_original_space ~= nil) then
        local elem = element.get(game, input.get_drag_element_uid(state))
        if elem then
            local mouse_pos = input.get_mouse_pos(state)
            local target_x = mouse_pos.x
            local target_y = mouse_pos.y
            local target_transform = space.getWorldTransformInScreenSpace(game, target_x, target_y)
            target_transform.x = target_transform.x - elem.transform.width / 2
            target_transform.y = target_transform.y - elem.transform.height / 2
            space.set_space(game, elem.uid, space.createScreenSpace(target_transform.x, target_transform.y))
        end
    end
end

local function endDrag(game)
    local state = game.state

    if input.get_drag_element_uid(state) and state.drag_original_space then
        local elem = element.get(game, input.get_drag_element_uid(state))
        if elem then
            -- Возвращаем элемент в исходное место
            space.set_space(game, elem.uid, state.drag_original_space)
        end

        state.drag_original_space = nil
    end
end

function drag.update(game, dt)
    local state = game.state

    -- Начинаем драг когда input определяет это
    if input.get_action_type(state) == "drag" and state.drag_original_space == nil then
        startDrag(game)
    end

    -- Обновляем позицию во время драга
    if input.is_drag_active(state) then
        updateDrag(game, dt)
    end

    -- Завершаем драг когда input сообщает об окончании
    if not input.is_drag_active(state) and state.drag_original_space then
        endDrag(game)
    end
end

return drag
