local input = import("input")
local hand = import("hand")
local element = import("element")
local transition = import("transition")
local log = import("log")

local drag = {}

function drag.init(game)
end

function drag.update(game, dt)
    local state = game.state

    if(input.is_mouse_pressed(state)) then
        local mouse_pos = input.get_mouse_pos(state)
        for _, elem in pairs(state.elements) do
            if(drag.isPointInElementBounds(mouse_pos, elem) and (state.drag == nil or state.drag.uid ~= elem.uid)) then
                log.log("Drag element")
                
                -- TODO: how we will know which space and etc ??
                -- :(
                -- Get space from element and then serach by element uid in that space(hand, board, etc)
                -- Transition shit in that case too

                local hand_uid = game.state.players[game.state.current_player_uid].hand_uid
                local index = hand.getIndex(game, hand_uid, elem.uid)
                hand.removeElem(game, hand_uid, index)

                state.drag = {
                    uid = elem.uid,
                    x = mouse_pos.x or 0,
                    y = mouse_pos.y or 0,
                    offset_x = 0,
                    offset_y = 0
                }

                elem.transform.x = mouse_pos.x or 0
                elem.transform.y = mouse_pos.y or 0
                elem.transform.space = "screen"
            end
        end

        local elem = element.get(game, state.drag.uid)
        elem.transform.x = mouse_pos.x or 0
        elem.transform.y = mouse_pos.y or 0
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