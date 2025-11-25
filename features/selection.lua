local selection = {}

local log = import("log")
local input = import("input")
local tween = import("tween")
local hand = import("hand")
local board = import("board")
local transition = import("transition")
local space = import("space")
local utils = import("utils")


---@param state State
---@param conf Config
---@param current_time number
---@return boolean
local function is_double_click(state, conf, current_time)
    return (current_time - input.get_last_click_time(state)) < conf.click.double_click_threshold
end

---@param state State
---@param conf Config
---@param elem_uid number
local function lift_element(state, conf, elem_uid)
    local element_data = state.elements[elem_uid]
    if not element_data then return end

    local target_transform = {
        x = element_data.transform.x,
        y = element_data.transform.y - conf.click.selection_lift_offset,
        width = element_data.transform.width,
        height = element_data.transform.height,
        z_index = element_data.transform.z_index + 1
    }

    tween.create(
        state,
        conf.click.selection_animation_duration,
        element_data.transform,
        target_transform,
        tween.easing.outQuad
    )
end

---@param state State
---@param conf Config
---@param elem_uid number
local function lower_element(state, conf, elem_uid)
    local element_data = state.elements[elem_uid]
    if not element_data then return end

    local target_transform = {
        x = element_data.transform.x,
        y = element_data.transform.y + conf.click.selection_lift_offset,
        width = element_data.transform.width,
        height = element_data.transform.height,
        z_index = element_data.transform.z_index - 1
    }

    tween.create(
        state,
        conf.click.selection_animation_duration,
        element_data.transform,
        target_transform,
        tween.easing.outQuad
    )
end

---@param state State
---@param conf Config
---@param elem Element
local function handle_hand_element_click(state, conf, elem)
    log.log("HAND CLICK", elem.uid, state.selected_element_uid)

    if state.selected_element_uid and state.selected_element_uid ~= elem.uid then
        lower_element(state, conf, state.selected_element_uid)
    end

    if state.selected_element_uid == elem.uid then
        state.selected_element_uid = nil
        lower_element(state, conf, elem.uid)
        log.log("[CLICK]: Deselected element " .. elem.uid)
    else
        state.selected_element_uid = elem.uid
        lift_element(state, conf, elem.uid)
        log.log("[CLICK]: Selected element " .. elem.uid)
    end
end

---@param state State
---@param conf Config
---@param elem Element
local function handle_board_element_click(state, conf, elem)
    local current_time = love.timer.getTime()

    if state.selected_element_uid ~= nil then
        lower_element(state, conf, state.selected_element_uid)
        state.selected_element_uid = nil
    end

    if is_double_click(state, conf, current_time) then
        local hand_uid = state.players[state.current_player_uid].hand_uid

        local empty_slot = hand.get_empty_slot(state, hand_uid)

        if empty_slot then
            transition.to(state, conf, elem.uid, 0.7, tween.easing.inOutCubic, {
                type = SpaceType.HAND,
                data = {
                    hand_uid = hand_uid,
                    index = empty_slot
                }
            })

            log.log("[CLICK]: Double-clicked element " .. elem.uid .. " moved to hand slot " .. empty_slot)
        else
            log.warn("[CLICK]: No empty slots in hand for element " .. elem.uid)
        end
    end
end

---@param state State
---@param conf Config
---@param mouse_pos {x: number, y: number}
local function handle_empty_board_click(state, conf, mouse_pos)
    -- NOTE: if has selected element put it on board
    if state.selected_element_uid then
        local selected_elem = state.elements[state.selected_element_uid]
        if selected_elem and selected_elem.space.type == SpaceType.HAND then
            local board_pos = space.get_board_pos_by_world_pos(conf, mouse_pos.x, mouse_pos.y)
            if board_pos then
                local existing_elem = board.get_board_elem_uid(state, board_pos.x, board_pos.y)
                if not existing_elem then
                    hand.remove_element(state, selected_elem.space.data.hand_uid, selected_elem.space.data.index)

                    state.elements[state.selected_element_uid].transform = { x = 0, y = 0, width = 0, height = 0, z_index = 0 }

                    transition.to(state, conf, state.selected_element_uid, 0.7, tween.easing.inOutCubic, {
                        type = SpaceType.BOARD,
                        data = board_pos
                    })

                    state.selected_element_uid = nil

                    log.log("[CLICK]: Moved selected element to board position " .. board_pos.x .. ", " .. board_pos.y)
                else
                    log.warn("[CLICK]: Board cell is not empty")
                end
            end
        end
    end
end

---@param state State
---@param conf Config
---@param dt number
function selection.update(state, conf, dt)
    if not input.is_drag(state) and (input.is_click(state) or input.is_double_click(state)) then
        print("CLICK", input.is_click(state), input.is_double_click(state))
        local click_pos = input.get_click_pos(state)
        -- print("POS", click_pos)
        if not click_pos then return end

        -- print("XY", click_pos.x, click_pos.y)

        local clicked_elem = nil
        for uid, elem in pairs(state.elements) do
            if utils.is_point_in_transform_bounds(elem.world_transform, click_pos) then
                clicked_elem = elem
                -- print("FOUND", elem.uid)
                break
            end
        end

        if clicked_elem then
            print("CLICK BY", clicked_elem.uid, clicked_elem.space.type)
            if clicked_elem.space.type == SpaceType.HAND then
                if input.is_click(state) then
                    handle_hand_element_click(state, conf, clicked_elem)
                end
            elseif clicked_elem.space.type == SpaceType.BOARD then
                if input.is_double_click(state) then
                    handle_board_element_click(state, conf, clicked_elem)
                end
            end
        else
            if input.is_click(state) then
                if space.is_in_board_area(conf, click_pos.x, click_pos.y) then
                    handle_empty_board_click(state, conf, click_pos)
                end
            end
        end
    end

    if state.drag.active and state.selected_element_uid then
        if state.drag.element_uid ~= state.selected_element_uid then
            lower_element(state, conf, state.selected_element_uid)
        else
            state.elements[state.selected_element_uid].transform = { x = 0, y = 0, width = 0, height = 0, z_index = 0 }
        end
        state.selected_element_uid = nil
    end
end

---@param state State
---@return number|nil
function selection.get_selected_element(state)
    return state.selected_element_uid
end

---@param state State
---@param conf Config
function selection.deselect_element(state, conf)
    if state.selected_element_uid then
        lower_element(state, conf, state.selected_element_uid)
        state.selected_element_uid = nil
    end
end

return selection
