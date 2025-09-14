local log = import("log")
local input = import("input")
local space = import("space")
local hand = import("hand")
local tween = import("tween")
local transition = import("transition")

local drop = {}

function drop.update(game, dt)
    local state = game.state
    if (input.is_mouse_released(state) and state.drag_element_uid ~= nil) then
        local mouse_pos = input.get_mouse_pos(state)
        local space_type = space.getSpaceTypeByPosition(game, mouse_pos.x, mouse_pos.y)
        log.log("[DROP ELEMENT]: space_type: " .. space_type)
        if (space_type == "board") then
            local board_pos = space.getBoardPosByWorldPos(game, mouse_pos.x, mouse_pos.y)
            log.log("[DROP ELEMENT TO BOARD]: board_pos: " .. board_pos.x .. ", " .. board_pos.y)
            transition.to(game, state.drag_element_uid, 0.7, tween.easing.inOutCubic,
                space.createBoardSpace(board_pos.x, board_pos.y)
            )
        elseif (space_type == "hand") then
            local hand_uid = state.players[state.current_player_uid].hand_uid
            local empty_slot = 1 -- hand.getEmptySlot(game, hand_uid)

            -- NOTE: not has case when hand is full and we can drop element
            if empty_slot == nil then
                log.warn("[DROP ELEMENT TO HAND]: HAND IS FULL!")
                return
            end
            log.log("[DROP ELEMENT TO HAND]: hand_uid: " .. hand_uid .. ", empty_slot: " .. empty_slot)
            transition.to(game, state.drag_element_uid, 0.7, tween.easing.inOutCubic,
                space.createHandSpace(hand_uid, empty_slot)
            )
        end
        state.drag_element_uid = nil
    end
end

return drop
