local Drop = {}

function Drop.update(game, dt)
    local state = game.state
    local Engine = game.engine
    local Log = Engine.Log
    local Input = Engine.Input
    local Tween = Engine.tween
    local HandManager = game.logic.HandManager
    local TransitionsManager = game.logic.TransitionsManager
    local Space = game.logic.Space

    -- Обрабатываем дроп когда драг завершился
    if (not Input.is_drag(state) and state.drag.element_uid ~= nil) then
        local mouse_pos = Input.get_mouse_pos(state)
        local space_type = Space.get_space_type_by_position(game, mouse_pos.x, mouse_pos.y)
        if (space_type == SpaceType.BOARD) then
            local board_pos = Space.get_board_pos_by_world_pos(game, mouse_pos.x, mouse_pos.y)
            TransitionsManager.to(game, state.drag.element_uid, 0.7, Tween.easing.inOutCubic,
                Space.create_board_space(board_pos.x, board_pos.y)
            )
        elseif (space_type == SpaceType.HAND) then
            local hand_uid = state.players[state.current_player_uid].hand_uid
            local empty_slot = HandManager.get_empty_slot(game, hand_uid)

            -- NOTE: not has case when hand is full and we can drop element
            if empty_slot == nil then
                Log.warn("[DROP ELEMENT TO HAND]: HAND IS FULL!")
                return
            end
            Log.log("[DROP ELEMENT TO HAND]: hand_uid: " .. hand_uid .. ", empty_slot: " .. empty_slot)
            TransitionsManager.to(game, state.drag.element_uid, 0.7, Tween.easing.inOutCubic,
                Space.create_hand_space(hand_uid, empty_slot)
            )
        else
            -- NOTE: If dropped in screen space (outside board and hand), try to return to hand first, then to original position
            local hand_uid = state.players[state.current_player_uid].hand_uid
            local empty_slot = HandManager.get_empty_slot(game, hand_uid)

            -- Try to place in hand first
            if empty_slot ~= nil then
                Log.log("[DROP ELEMENT TO HAND (SCREEN SPACE)]: hand_uid: " .. hand_uid .. ", empty_slot: " .. empty_slot)
                TransitionsManager.to(game, state.drag.element_uid, 0.7, Tween.easing.inOutCubic,
                    Space.create_hand_space(hand_uid, empty_slot)
                )
            else
                -- If hand is full, return element to its original position
                Log.warn("[DROP ELEMENT TO HAND]: HAND IS FULL! Returning to original position.")
                if state.drag.original_space then
                    Log.log("[DROP ELEMENT TO ORIGINAL POSITION]: type: " .. state.drag.original_Space.type)
                    if state.drag.original_Space.type == SpaceType.BOARD then
                        TransitionsManager.to(game, state.drag.element_uid, 0.7, Tween.easing.inOutCubic,
                            Space.create_board_space(state.drag.original_Space.data.x, state.drag.original_Space.data.y)
                        )
                    elseif state.drag.original_Space.type == SpaceType.HAND then
                        TransitionsManager.to(game, state.drag.element_uid, 0.7, Tween.easing.inOutCubic,
                            Space.create_hand_space(state.drag.original_Space.data.hand_uid,
                                state.drag.original_Space.data.index)
                        )
                    end
                else
                    Log.warn("[DROP ELEMENT]: No original position found!")
                end
            end
        end
        state.drag.active = false
        state.drag.element_uid = nil
        state.drag.original_space = nil
    end
end

return Drop
