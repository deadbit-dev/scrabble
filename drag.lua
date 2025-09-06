local log = import("log")
local input = import("input")
local hand = import("hand")
local board = import("board")
local element = import("element")
local tween = import("tween")
local transition = import("transition")

local drag = {}

function drag.init(game)
end

local function checkDragStart(game, mouse_pos)
    local state = game.state
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
end

local function updateDrag(game, mouse_pos)
    local state = game.state

    if (state.drag ~= nil) then
        local elem = element.get(game, state.drag.uid)

        -- TODO: with transition/tween

        elem.transform.x = mouse_pos.x - state.drag.offset_x
        elem.transform.y = mouse_pos.y - state.drag.offset_y
        elem.space.data = {
            x = elem.transform.x,
            y = elem.transform.y
        }
    end
end

function drag.update(game, dt)
    local state = game.state

    if (input.is_mouse_pressed(state)) then
        local mouse_pos = input.get_mouse_pos(state)
        checkDragStart(game, mouse_pos)
        updateDrag(game, mouse_pos)
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
