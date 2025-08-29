local input = import("input")
local hand = import("hand")
local board = import("board")
local element = import("element")
local transition = import("transition")
local log = import("log")

local drag = {}

function drag.init(game)
end

function drag.update(game, dt)
    local state = game.state

    if (input.is_mouse_pressed(state)) then
        local mouse_pos = input.get_mouse_pos(state)
        for _, elem in pairs(state.elements) do
            if (drag.isPointInElementBounds(mouse_pos, elem) and state.drag == nil) then
                local type = elem.space.type
                local data = elem.space.data
                if type == "hand" then
                    hand.removeElem(game, data.hand_uid, data.index)
                elseif type == "board" then
                    board.removeElement(game, data.x, data.y)
                end

                state.drag = {
                    uid = elem.uid,
                    offset_x = mouse_pos.x - elem.transform.x,
                    offset_y = mouse_pos.y - elem.transform.y
                }

                elem.transform.x = mouse_pos.x - state.drag.offset_x
                elem.transform.y = mouse_pos.y - state.drag.offset_y
                elem.space = {
                    type = "screen",
                    data = {
                        x = elem.transform.x,
                        y = elem.transform.y
                    }
                }
            end
        end

        local elem = element.get(game, state.drag.uid)
        elem.transform.x = mouse_pos.x - state.drag.offset_x
        elem.transform.y = mouse_pos.y - state.drag.offset_y
        elem.space.data = {
            x = elem.transform.x,
            y = elem.transform.y
        }
    end

    if (input.is_mouse_released(state)) then
        state.drag = nil
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
