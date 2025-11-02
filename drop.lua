local drop = {}

local log = import("core.log")
local input = import("core.input")
local tween = import("core.tween")
local hand = import("hand")
local transition = import("transition")
local space = import("space")

---@param state State
---@param conf Config
---@param dt number
function drop.update(state, conf, dt)
    if (not input.is_drag(state) and state.drag.element_uid ~= nil) then
        local mouse_pos = input.get_mouse_pos(state)
        local space_type = space.get_space_type_by_position(state, conf, mouse_pos.x, mouse_pos.y)

        if (space_type == SpaceType.BOARD) then
            local board_pos = space.get_board_pos_by_world_pos(conf, mouse_pos.x, mouse_pos.y)
            if board_pos == nil then
                log.warn("[DROP ELEMENT TO BOARD]: wrong position for board " .. mouse_pos.x .. ", " .. mouse_pos.y)
                return
            end
            transition.to(state, conf, state.drag.element_uid, 0.7, tween.easing.inOutCubic,
                space.create_board_space(board_pos.x, board_pos.y)
            )
        elseif (space_type == SpaceType.HAND) then
            local hand_uid = state.players[state.current_player_uid].hand_uid
            local empty_slot = hand.get_empty_slot(state, hand_uid)

            -- NOTE: not has case when hand is full and we can drop element
            if empty_slot == nil then
                log.warn("[DROP ELEMENT TO HAND]: HAND IS FULL!")
                return
            end
            log.log("[DROP ELEMENT TO HAND]: hand_uid: " .. hand_uid .. ", empty_slot: " .. empty_slot)
            transition.to(state, conf, state.drag.element_uid, 0.7, tween.easing.inOutCubic,
                space.create_hand_space(hand_uid, empty_slot)
            )
        else
            -- NOTE: If dropped in screen space (outside board and hand), try to return to hand first, then to original position
            local hand_uid = state.players[state.current_player_uid].hand_uid
            local empty_slot = hand.get_empty_slot(state, hand_uid)

            -- NOTE: Try to place in hand first
            if empty_slot ~= nil then
                log.log("[DROP ELEMENT TO HAND (SCREEN SPACE)]: hand_uid: " .. hand_uid .. ", empty_slot: " .. empty_slot)
                transition.to(state, conf, state.drag.element_uid, 0.7, tween.easing.inOutCubic,
                    space.create_hand_space(hand_uid, empty_slot)
                )
            else
                -- NOTE: If hand is full, return element to its original position
                log.warn("[DROP ELEMENT TO HAND]: HAND IS FULL! Returning to original position.")
                if state.drag.original_space then
                    log.log("[DROP ELEMENT TO ORIGINAL POSITION]: type: " .. state.drag.original_space.type)
                    if state.drag.original_space.type == SpaceType.BOARD then
                        transition.to(state, conf, state.drag.element_uid, 0.7, tween.easing.inOutCubic,
                            space.create_board_space(state.drag.original_space.data.x, state.drag.original_space.data.y)
                        )
                    elseif state.drag.original_space.type == SpaceType.HAND then
                        transition.to(state, conf, state.drag.element_uid, 0.7, tween.easing.inOutCubic,
                            space.create_hand_space(state.drag.original_space.data.hand_uid,
                                state.drag.original_space.data.index)
                        )
                    end
                else
                    log.warn("[DROP ELEMENT]: No original position found!")
                end
            end
        end

        state.drag.active = false
        state.drag.element_uid = nil
        state.drag.original_space = nil
    end
end

return drop
