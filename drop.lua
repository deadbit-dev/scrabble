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
        else
            -- NOTE: If dropped in screen space (outside board and hand), try to return to hand first, then to original position
            local hand_uid = state.players[state.current_player_uid].hand_uid
            local empty_slot = hand.getEmptySlot(game, hand_uid)
            
            -- Try to place in hand first
            if empty_slot ~= nil then
                log.log("[DROP ELEMENT TO HAND (SCREEN SPACE)]: hand_uid: " .. hand_uid .. ", empty_slot: " .. empty_slot)
                transition.to(game, state.drag_element_uid, 0.7, tween.easing.inOutCubic,
                    space.createHandSpace(hand_uid, empty_slot)
                )
            else
                -- If hand is full, return element to its original position
                log.warn("[DROP ELEMENT TO HAND]: HAND IS FULL! Returning to original position.")
                if state.drag_original_space then
                    log.log("[DROP ELEMENT TO ORIGINAL POSITION]: type: " .. state.drag_original_space.type)
                    if state.drag_original_space.type == "board" then
                        transition.to(game, state.drag_element_uid, 0.7, tween.easing.inOutCubic,
                            space.createBoardSpace(state.drag_original_space.data.x, state.drag_original_space.data.y)
                        )
                    elseif state.drag_original_space.type == "hand" then
                        transition.to(game, state.drag_element_uid, 0.7, tween.easing.inOutCubic,
                            space.createHandSpace(state.drag_original_space.data.hand_uid, state.drag_original_space.data.index)
                        )
                    end
                else
                    log.warn("[DROP ELEMENT]: No original position found!")
                end
            end
        end
        state.drag_element_uid = nil
        state.drag_original_space = nil
    end
end

return drop
