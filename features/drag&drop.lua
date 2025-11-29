local drag = {}

local log = import("log")
local input = import("input")
local board = import("board")
local hand = import("hand")
local space = import("space")
local tween = import("tween")
local transition = import("transition")
local utils = import("utils")
local words = import("words")

---@param state State
---@param conf Config
local function start_drag(state, conf)
    local click_pos = input.get_mouse_pos(state)
    if not click_pos then return end

    -- NOTE: find element in click pos
    local elem_uid = nil
    for _, elem in pairs(state.elements) do
        -- local space_transform = space.get_space_transform(state, conf, elem.space)
        -- local world_transform = {
        --     x = space_transform.x + elem.transform.x,
        --     y = space_transform.y + elem.transform.y,
        --     width = space_transform.width,
        --     height = space_transform.height,
        --     z_index = space_transform.z_index
        -- }
        if utils.is_point_in_transform_bounds(elem.world_transform, click_pos) then
            elem_uid = elem.uid
            break
        end
    end

    if not elem_uid then return end

    local element_data = state.elements[elem_uid]
    if not element_data then return end

    local type = element_data.space.type
    local data = element_data.space.data

    state.drag.active = true
    state.drag.element_uid = elem_uid
    state.drag.original_space = {
        type = type,
        data = data
    }

    if type == SpaceType.HAND then
        hand.remove_element(state, data.hand_uid, data.index)
    elseif type == SpaceType.BOARD then
        board.remove_element(state, data.x, data.y)
    end

    local mouse_pos = input.get_mouse_pos(state)
    local target_x = mouse_pos.x
    local target_y = mouse_pos.y
    local target_transform = space.get_world_transform_in_screen_space(conf, target_x, target_y)
    target_transform.x = target_transform.x - element_data.world_transform.width / 2
    target_transform.y = target_transform.y - element_data.world_transform.height / 2

    state.elements[elem_uid].space = {
        type = SpaceType.SCREEN,
        data = {
            x = target_transform.x,
            y = target_transform.y
        }
    }

    local space_transform = space.get_world_transform_in_screen_space(conf, target_transform
        .x, target_transform.y)
    state.elements[element_data.uid].world_transform = {
        x = space_transform.x + element_data.transform.x,
        y = space_transform.y + element_data.transform.y,
        width = space_transform.width + element_data.transform.width,
        height = space_transform.height + element_data.transform.height,
        z_index = space_transform.z_index + 1
    }
end

---@param state State
---@param conf Config
---@param dt number
local function update_drag(state, conf, dt)
    if (state.drag.active and state.drag.element_uid) then
        local element_data = state.elements[state.drag.element_uid]
        if element_data then
            local mouse_pos = input.get_mouse_pos(state)
            local target_x = mouse_pos.x
            local target_y = mouse_pos.y
            local target_transform = space.get_world_transform_in_screen_space(conf, target_x, target_y)
            target_transform.x = target_transform.x - element_data.world_transform.width / 2
            target_transform.y = target_transform.y - element_data.world_transform.height / 2
            state.elements[element_data.uid].space = {
                type = SpaceType.SCREEN,
                data = {
                    x = target_transform.x,
                    y = target_transform.y
                }
            }
            local space_transform = space.get_world_transform_in_screen_space(conf, target_transform
                .x, target_transform.y)
            state.elements[element_data.uid].world_transform = {
                x = space_transform.x + element_data.transform.x,
                y = space_transform.y + element_data.transform.y,
                width = space_transform.width + element_data.transform.width,
                height = space_transform.height + element_data.transform.height,
                z_index = space_transform.z_index + 1
            }
        end
    end
end


-- TODO: simplify, more readability
---@param state State
---@param conf Config
---@param dt number
local function drop(state, conf, dt)
    if (state.drag.element_uid ~= nil) then
        local mouse_pos = input.get_mouse_pos(state)
        local space_type = space.get_space_type_by_position(state, conf, mouse_pos.x, mouse_pos.y)

        if (space_type == SpaceType.BOARD) then
            local board_pos = space.get_board_pos_by_world_pos(conf, mouse_pos.x, mouse_pos.y)
            if board_pos == nil then
                log.warn("[DROP ELEMENT TO BOARD]: wrong position for board " .. mouse_pos.x .. ", " .. mouse_pos.y)
                return
            end
            transition.to(state, conf, state.drag.element_uid, 0.3, tween.easing.inOutCubic, {
                type = SpaceType.BOARD,
                data = board_pos
            }, function()
                local recognized_words = words.recognize(conf, state, board_pos.x, board_pos.y)
                for idx, word in ipairs(recognized_words) do
                    print("FOUND WORD: ", word.start_pos.x, word.start_pos.y, word.end_pos.x, word.end_pos.y)
                    local char = state.board.elem_uids[word.start_pos.x][word.start_pos.y]
                    if words.is_valid(word) then
                        print("VALID WORD :)")
                    end
                end
            end)
        elseif (space_type == SpaceType.HAND) then
            local hand_uid = state.players[state.current_player_uid].hand_uid
            local empty_slot = hand.get_empty_slot(state, hand_uid)

            -- NOTE: not has case when hand is full and we can drop element
            if empty_slot == nil then
                log.warn("[DROP ELEMENT TO HAND]: HAND IS FULL!")
                return
            end
            log.log("[DROP ELEMENT TO HAND]: hand_uid: " .. hand_uid .. ", empty_slot: " .. empty_slot)
            transition.to(state, conf, state.drag.element_uid, 0.3, tween.easing.inOutCubic, {
                type = SpaceType.HAND,
                data = {
                    hand_uid = hand_uid,
                    index = empty_slot
                }
            })
        else
            -- NOTE: If dropped in screen space (outside board and hand), try to return to hand first, then to original position
            local hand_uid = state.players[state.current_player_uid].hand_uid
            local empty_slot = hand.get_empty_slot(state, hand_uid)

            -- NOTE: Try to place in hand first
            if empty_slot ~= nil then
                log.log("[DROP ELEMENT TO HAND (SCREEN SPACE)]: hand_uid: " .. hand_uid .. ", empty_slot: " .. empty_slot)
                transition.to(state, conf, state.drag.element_uid, 0.3, tween.easing.inOutCubic, {
                    type = SpaceType.HAND,
                    data = {
                        hand_uid = hand_uid,
                        index = empty_slot
                    }
                })
            else
                -- NOTE: If hand is full, return element to its original position
                log.warn("[DROP ELEMENT TO HAND]: HAND IS FULL! Returning to original position.")
                if state.drag.original_space then
                    log.log("[DROP ELEMENT TO ORIGINAL POSITION]: type: " .. state.drag.original_space.type)
                    if state.drag.original_space.type == SpaceType.BOARD then
                        transition.to(state, conf, state.drag.element_uid, 0.3, tween.easing.inOutCubic, {
                            type = SpaceType.BOARD,
                            data = state.drag.original_space.data
                        })
                    elseif state.drag.original_space.type == SpaceType.HAND then
                        transition.to(state, conf, state.drag.element_uid, 0.3, tween.easing.inOutCubic, {
                            type = SpaceType.HAND,
                            data = {
                                hand_uid = state.drag.original_space.data.hand_uid,
                                index = state.drag.original_space.data.index
                            }
                        })
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

---@param state State
---@param conf Config
---@param dt number
function drag.update(state, conf, dt)
    if input.is_drag(state) and not state.drag.active then
        start_drag(state, conf)
    end

    if state.drag.active then
        update_drag(state, conf, dt)
    end

    if not input.is_drag(state) and state.drag.active then
        drop(state, conf, dt)
    end
end

return drag
