local log = import("log")
local input = import("input")
local hand = import("hand")
local board = import("board")
local element = import("element")
local space = import("space")
local follow = import("follow")
local transition = import("transition")

local drag = {}

local function checkDragStart(game, mouse_pos)
    local state = game.state
    for _, elem in pairs(state.elements) do
        if (drag.isPointInElementBounds(mouse_pos, elem) and state.drag_element_uid == nil) then
            local type = elem.space.type
            local data = elem.space.data
            if type == "hand" then
                hand.removeElem(game, data.hand_uid, data.index)
            elseif type == "board" then
                board.removeElement(game, data.x, data.y)
            end

            state.drag_element_uid = elem.uid

            local target_x = mouse_pos.x
            local target_y = mouse_pos.y
            local target_transform = space.getWorldTransformInScreenSpace(game, target_x, target_y)
            target_transform.x = target_transform.x - elem.transform.width / 2
            target_transform.y = target_transform.y - elem.transform.height / 2
            space.set_space(game, elem.uid, space.createScreenSpace(target_transform.x, target_transform.y))
        end
    end
end

local function updateDrag(game, mouse_pos, dt)
    local state = game.state

    if (state.drag_element_uid ~= nil) then
        local elem = element.get(game, state.drag_element_uid)

        local target_x = mouse_pos.x
        local target_y = mouse_pos.y
        local target_transform = space.getWorldTransformInScreenSpace(game, target_x, target_y)
        target_transform.x = target_transform.x - elem.transform.width / 2
        target_transform.y = target_transform.y - elem.transform.height / 2
        space.set_space(game, elem.uid, space.createScreenSpace(target_transform.x, target_transform.y))
        -- TODO: smooothely pick up element
        -- transition will be done and we need just reset transform each update
        -- but how we know what transition is done ? callback set flag ? ugh...
    end
end

function drag.update(game, dt)
    local state = game.state

    if (input.is_mouse_pressed(state)) then
        local mouse_pos = input.get_mouse_pos(state)
        checkDragStart(game, mouse_pos)
        updateDrag(game, mouse_pos, dt)
    end
end

---Checks if point is within element's bounding box
---@param point {x: number, y: number}
---@param element Element
---@return boolean
function drag.isPointInElementBounds(point, element)
    local transform = element.transform
    return point.x >= transform.x
        and point.x <= transform.x + transform.width
        and point.y >= transform.y
        and point.y <= transform.y + transform.height
end

return drag
