-- FIXME: когда дропается элемент в руку, но под рукой поле, почему то дропается в поле а не в руку
-- FIXME: пока драгаешь поле, и тач задевает элемент в руке, то поле перестает драгаться, а начинает элемент
-- FIXME: нельзя дропать элемент в уже занятую ячеку в поле


local game = {}

local conf = import("conf")
local resources = import("resources")

local input = import("input")
local tween = import("tween")
local log = import("log")

local space = import("space")
local board = import("board")
local player = import("player")
local hand = import("hand")
local element = import("element")
local transition = import("transition")
local words = import('words')
local utils = import("utils")


---@class State
---@field is_restart boolean
---@field elements {[number]: Element}
---@field pool number[]
---@field board Board
---@field hands {[number]: Hand}
---@field players {[number]: Player}
---@field transitions Transition[]
---@field tweens {[number]: Tween}
---@field drag DragState
---@field selected_element_uid number|nil
---@field current_player_uid number|nil
---@field next_player_uid number|nil
---@filed step_timer number|nil
---@field input InputState
local state = {}

local function create_player(name)
    local hand_state = hand.create()
    state.hands[hand_state.uid] = hand_state
    local player_state = player.create(hand_state.uid, name)
    state.players[player_state.uid] = player_state
    return player_state.uid
end

---@param letter string
---@return number
local function create_element(letter)
    local element_state = element.create(conf, letter)
    state.elements[element_state.uid] = element_state
    return element_state.uid
end

local function get_current_player()
    return state.players[state.current_player_uid]
end

local function get_current_hand()
    return state.hands[get_current_player().hand_uid]
end

local function update_board_elemenets_world_transform()
    for y = 1, conf.field.size do
        for x = 1, conf.field.size do
            local elem_uid = board.get_elem_uid(state.board, x, y)
            if elem_uid then
                local elem_data = state.elements[elem_uid]
                local space_transform = board.get_space_transform(state.board, conf.field, x, y)
                elem_data.world_transform = {
                    x = space_transform.x + elem_data.transform.x,
                    y = space_transform.y + elem_data.transform.y,
                    width = space_transform.width + elem_data.transform.width,
                    height = space_transform.height + elem_data.transform.height,
                    z_index = space_transform.z_index + elem_data.transform.z_index
                }
            end
        end
    end
end

local function apply_pan_resistance(value, min_value, max_value, resistance)
    if value < min_value then
        local over = min_value - value
        return min_value - (over / (1 + over * resistance))
    end

    if value > max_value then
        local over = value - max_value
        return max_value + (over / (1 + over * resistance))
    end

    return value
end

local function board_zoom(pos, zoom)
    local new_zoom = zoom
    local old_zoom = state.board.zoom
    local min_zoom = conf.field.view.zoom.min
    local tracked_offset_x
    local tracked_offset_y

    if new_zoom < old_zoom and old_zoom > min_zoom then
        -- NOTE: For zoom-out, only do proportional recentering to avoid overshoot.
        local recenter_factor = utils.clamp((new_zoom - min_zoom) / (old_zoom - min_zoom), 0, 1)
        tracked_offset_x = state.board.offset.x * recenter_factor
        tracked_offset_y = state.board.offset.y * recenter_factor
    else
        local zoom_ratio = new_zoom / old_zoom
        local shift_dx = (state.board.base_transform.width * (new_zoom - old_zoom)) / 2
        local shift_dy = (state.board.base_transform.height * (new_zoom - old_zoom)) / 2
        tracked_offset_x = state.board.offset.x - pos.x * (zoom_ratio - 1) + shift_dx
        tracked_offset_y = state.board.offset.y - pos.y * (zoom_ratio - 1) + shift_dy
    end

    state.board.offset.x = tracked_offset_x
    state.board.offset.y = tracked_offset_y

    state.board.zoom = new_zoom
end

local function get_board_zoom_origin(base_transform, offset, zoom)
    local shift_x = (base_transform.width * (zoom - 1)) / 2
    local shift_y = (base_transform.height * (zoom - 1)) / 2
    return {
        x = base_transform.x + offset.x - shift_x,
        y = base_transform.y + offset.y - shift_y
    }
end

local function apply_board_transform()
    local zoom_origin = get_board_zoom_origin(state.board.base_transform, state.board.offset, state.board.zoom)
    state.board.transform = {
        x = zoom_origin.x,
        y = zoom_origin.y,
        width = state.board.base_transform.width * state.board.zoom,
        height = state.board.base_transform.height * state.board.zoom,
        z_index = 0
    }

    update_board_elemenets_world_transform()
end

--- NOTE: Recalculates all window-dependent layouts. Call on init and resize.
local function recalculate_layout()
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local base_width = window_width * (1 - (conf.window.padding.left + conf.window.padding.right))
    local base_height = window_height * (1 - (conf.window.padding.top + conf.window.padding.bottom))
    local center_x = window_width / 2
    local center_y = window_height / 2

    board.recalculate(state.board, conf.field, base_width, base_height, center_x, center_y)

    for _, h in pairs(state.hands) do
        hand.recalculate(h, conf)
    end
end

local function update_hand_elements_world_transform(hand_uid)
    for index, elem_uid in ipairs(state.hands[hand_uid].elem_uids) do
        if elem_uid then
            local elem = state.elements[elem_uid]
            if elem then
                local space_transform = hand.get_world_transform_in_hand_space(state.hands[hand_uid], conf, index)
                elem.world_transform = {
                    x = space_transform.x + elem.transform.x,
                    y = space_transform.y + elem.transform.y,
                    width = space_transform.width + elem.transform.width,
                    height = space_transform.height + elem.transform.height,
                    z_index = space_transform.z_index + elem.transform.z_index
                }
            end
        end
    end
end

local function update_current_hand_elements()
    update_hand_elements_world_transform(get_current_hand().uid)
end

local function update_transitions()
    for i = #state.transitions, 1, -1 do
        local trans = state.transitions[i]
        if trans.tween_uid ~= nil then
            local target_transform = space.get_space_transform(state, conf, trans.target_space)
            tween.update_target(state.tweens[trans.tween_uid], target_transform)
        end
    end
end

local function draw_elements(from_z_index, to_z_index)
    -- NOTE: Sort elements by transform.z_index before drawing
    local current_hand_uid = get_current_hand().uid
    local sorted_elements = table.filter(
        state.elements,
        function(value)
            if value.space and value.space.type == SpaceType.HAND and value.space.data.hand_uid ~= current_hand_uid then
                return false
            end
            return value.world_transform.z_index >= from_z_index and
                (to_z_index == nil or value.world_transform.z_index < to_z_index)
        end
    )

    for _, elem in pairs(sorted_elements) do
        element.draw(conf, elem, resources.textures.element, resources.fonts.default)
    end
end

local function draw_board()
    local board_textures = {
        field = resources.textures.field,
        cell = resources.textures.cell,
        shadow = resources.textures.cell_shadow,
        cross = resources.textures.cross
    }
    board.draw(state.board, conf.field, board_textures, conf.colors.black,
        resources.fonts.default)

    draw_elements(0, 1)
end

local function draw_stats()
    local window_width  = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local scale = math.min(window_width / conf.window.reference_width, window_height / conf.window.reference_height)

    local font = resources.fonts.default
    love.graphics.setFont(font)

    local positions = {
        { x = window_width * 0.05, align = "left" },
        { x = window_width * 0.95, align = "right" },
    }

    for i, uid in ipairs(state.player_order) do
        local p = state.players[uid]
        if not p then goto continue end

        local is_current = (uid == state.current_player_uid)
        local pos = positions[i]
        local y = window_height * 0.025

        if is_current then
            love.graphics.setColor(conf.colors.black)
        else
            love.graphics.setColor(0.6, 0.6, 0.6)
        end

        local points_str  = tostring(p.points)
        local name_width  = font:getWidth(p.name)   * scale
        local points_width = font:getWidth(points_str) * scale
        local line_height = font:getHeight() * scale

        local x_name   = pos.align == "right" and (pos.x - name_width)   or pos.x
        local x_points = pos.align == "right" and (pos.x - points_width) or pos.x

        love.graphics.print(p.name,    x_name,   y,                0, scale, scale)
        love.graphics.print(points_str, x_points, y + line_height, 0, scale, scale)

        ::continue::
    end
end

local function draw_step_timer()
    if state.step_timer == nil then return end

    local window_width  = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local scale = math.min(window_width / conf.window.reference_width, window_height / conf.window.reference_height)

    local font = resources.fonts.default
    love.graphics.setFont(font)

    local seconds_left = math.ceil(state.step_timer)
    local text = tostring(seconds_left)

    if seconds_left <= 3 then
        love.graphics.setColor(0.8, 0.2, 0.2)
    else
        love.graphics.setColor(conf.colors.black)
    end

    local text_width = font:getWidth(text) * scale
    local x = (window_width - text_width) / 2
    love.graphics.print(text, x, window_height * 0.025, 0, scale, scale)
end

local function draw_end_step_button()

end

local function draw_gui()
    draw_stats()
    draw_step_timer()
    draw_end_step_button()
end

-- TODO: move into input module
---@param current_time number
---@return boolean
local function is_double_click(current_time)
    return (current_time - state.input.mouse.last_click_time) < conf.click.double_click_threshold
end

---@param elem_uid number
local function lift_element(elem_uid)
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
        state.tweens,
        conf.click.selection_animation_duration,
        element_data.transform,
        target_transform,
        tween.easing.outQuad
    )
end

---@param elem_uid number
local function lower_element(elem_uid)
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
        state.tweens,
        conf.click.selection_animation_duration,
        element_data.transform,
        target_transform,
        tween.easing.outQuad
    )
end

---@param elem Element
local function handle_hand_element_click(elem)
    if state.selected_element_uid and state.selected_element_uid ~= elem.uid then
        lower_element(state.selected_element_uid)
    end

    if state.selected_element_uid == elem.uid then
        state.selected_element_uid = nil
        lower_element(elem.uid)
    else
        state.selected_element_uid = elem.uid
        lift_element(elem.uid)
    end
end

---@param elem Element
local function handle_board_element_click(elem)
    local current_time = love.timer.getTime()

    if state.selected_element_uid ~= nil then
        lower_element(state.selected_element_uid)
        state.selected_element_uid = nil
    end

    -- TODO: использовать проверку через input модуль
    if is_double_click(current_time) then
        local hand_uid = state.players[state.current_player_uid].hand_uid

        local empty_slot = hand.get_empty_slot(state.hands[hand_uid])

        if empty_slot then
            transition.to(state, conf, elem.uid, 0.7, tween.easing.inOutCubic, {
                type = SpaceType.HAND,
                data = {
                    hand_uid = hand_uid,
                    index = empty_slot
                }
            })
        else
            log.warn("[CLICK]: No empty slots in hand for element " .. elem.uid)
        end
    end
end

---@param mouse_pos Pos
local function handle_empty_board_click(mouse_pos)
    -- NOTE: if has selected element put it on board
    if state.selected_element_uid then
        local selected_elem = state.elements[state.selected_element_uid]
        if selected_elem and selected_elem.space.type == SpaceType.HAND then
            local board_pos = space.get_board_pos_by_world_pos(state.board, conf.field, mouse_pos.x, mouse_pos.y)
            if board_pos then
                local existing_elem = board.get_elem_uid(state.board, board_pos.x, board_pos.y)
                if not existing_elem then
                    hand.remove_element(state.hands[selected_elem.space.data.hand_uid], selected_elem.space.data.index)

                    state.elements[state.selected_element_uid].transform = { x = 0, y = 0, width = 0, height = 0, z_index = 0 }

                    transition.to(state, conf, state.selected_element_uid, 0.7, tween.easing.inOutCubic, {
                        type = SpaceType.BOARD,
                        data = board_pos
                    })

                    state.selected_element_uid = nil
                else
                    log.warn("[CLICK]: Board cell is not empty")
                end
            end
        end
    end
end

local function update_selection()
    if not state.input.mouse.is_drag and state.input.mouse.is_click or state.input.mouse.is_double_click then
        print("CLICK", state.input.mouse.is_click, state.input.mouse.is_double_click)
        local click_pos = state.input.mouse.click_pos
        if not click_pos then return end

        local clicked_elem = nil
        for uid, elem in pairs(state.elements) do
            if utils.is_point_in_transform_bounds(elem.world_transform, click_pos) then
                clicked_elem = elem
                break
            end
        end

        if clicked_elem then
            if clicked_elem.space.type == SpaceType.HAND then
                if state.input.mouse.is_click then
                    handle_hand_element_click(clicked_elem)
                end
            elseif clicked_elem.space.type == SpaceType.BOARD then
                if state.input.mouse.is_double_click then
                    handle_board_element_click(clicked_elem)
                end
            end
        else
            if state.input.mouse.is_click then
                if space.is_in_board_area(state.board, conf.field, click_pos.x, click_pos.y) then
                    handle_empty_board_click(click_pos)
                end
            end
        end
    end

    if state.drag.active and state.selected_element_uid then
        if state.drag.element_uid ~= state.selected_element_uid then
            lower_element(state.selected_element_uid)
        else
            state.elements[state.selected_element_uid].transform = { x = 0, y = 0, width = 0, height = 0, z_index = 0 }
        end
        state.selected_element_uid = nil
    end
end


local function start_drag()
    local elem_uid = state.drag.press_element_uid
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
        hand.remove_element(state.hands[data.hand_uid], data.index)
    elseif type == SpaceType.BOARD then
        board.remove_element(state.board, data.x, data.y)
    end

    local mouse_pos = input.get_mouse_pos(state.input)
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

-- TODO: simplify, more readability
local function drop()
    if (state.drag.element_uid ~= nil) then
        local mouse_pos = input.get_mouse_pos(state.input)
        local space_type = space.get_space_type_by_position(state, conf, mouse_pos.x, mouse_pos.y)

        if (space_type == SpaceType.BOARD) then
            local board_pos = space.get_board_pos_by_world_pos(state.board, conf.field, mouse_pos.x, mouse_pos.y)
            if board_pos == nil then
                log.warn("[DROP ELEMENT TO BOARD]: wrong position for board " .. mouse_pos.x .. ", " .. mouse_pos.y)
                return
            end
            transition.to(state, conf, state.drag.element_uid, 0.3, tween.easing.inOutCubic, {
                type = SpaceType.BOARD,
                data = board_pos
            }, function()
                print("SEARCH")
                local recognized_words = words.search(conf, state, resources, board_pos.x, board_pos.y)
                for idx, word_range in ipairs(recognized_words) do
                    local word = words.get_word_by_pos_range(state, word_range.start_pos, word_range.end_pos)
                    print("FOUND WORD: " .. word)
                end
            end)
        elseif (space_type == SpaceType.HAND) then
            local hand_uid = state.players[state.current_player_uid].hand_uid
            local empty_slot = hand.get_empty_slot(state.hands[hand_uid])

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
            local empty_slot = hand.get_empty_slot(state.hands[hand_uid])

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

---@class DragState
---@field active boolean
---@field element_uid number|nil
---@field original_space SpaceInfo|nil
---@field press_element_uid number|nil

---@return DragState
local function init_dnd()
    return {
        active = false,
        element_uid = nil,
        original_space = nil,
        press_element_uid = nil
    }
end

local function detect_press_target()
    if input.is_mouse_pressed(state.input, 1) and state.drag.press_element_uid == nil and not state.drag.active then
        local mouse_pos = input.get_mouse_pos(state.input)
        local current_hand_uid = get_current_hand().uid
        for _, elem in pairs(state.elements) do
            if elem.space and elem.space.type == SpaceType.HAND and elem.space.data.hand_uid ~= current_hand_uid then
                goto continue
            end
            if utils.is_point_in_transform_bounds(elem.world_transform, mouse_pos) then
                state.drag.press_element_uid = elem.uid
                break
            end
            ::continue::
        end
    end

    if not input.is_mouse_pressed(state.input, 1) then
        state.drag.press_element_uid = nil
    end
end

local function update_dnd()
    if state.input.mouse.is_drag and not state.drag.active then
        start_drag()
    end

    if (state.drag.active and state.drag.element_uid) then
        local element_data = state.elements[state.drag.element_uid]
        if element_data then
            local mouse_pos = input.get_mouse_pos(state.input)
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

    if not state.input.mouse.is_drag and state.drag.active then
        drop()
    end
end

local function next_step()
    local tmp = state.next_player_uid
    state.next_player_uid = state.current_player_uid
    state.current_player_uid = tmp
end

local function start_step_timer()
    state.step_timer = conf.step_time
end

local function update_step_timer(dt)
    if state.step_timer == nil then return end
    state.step_timer = math.max(0, state.step_timer - dt)
end

local function is_step_timeout()
    -- log.log("step_timer: " .. state.step_timer)
    return state.step_timer and state.step_timer == 0
end

local function reset_step_timer()
    state.step_timer = nil
end

local function start_hand_switch()
    local anim = state.hand_animation
    anim.phase = "shrink"
    anim.scale = 1
    tween.create(
        state.tweens,
        conf.hand_animation.shrink_duration,
        anim,
        { scale = 0 },
        tween.easing.inQuad,
        function()
            next_step()
            anim.phase = "grow"
            anim.scale = 0
            tween.create(
                state.tweens,
                conf.hand_animation.grow_duration,
                anim,
                { scale = 1 },
                tween.easing.outBack,
                function()
                    anim.phase = nil
                    start_step_timer()
                end
            )
        end
    )
end

function game.init()
    _G.uid_counter = 0

    resources.load()

    state = {
        is_restart = false,

        current_player_uid = nil,
        next_player_uid = nil,
        player_order = {},
        selected_element_uid = nil,
        step_timer = nil,
        hand_animation = { phase = nil, scale = 1 },

        elements = {},
        pool = {},
        board = board.create(conf.field),
        hands = {},
        players = {},
        transitions = {},
        tweens = {},

        input = input.init(),
        drag = init_dnd(),
    }

    local p1 = create_player("Player 1")
    local p2 = create_player("Player 2")

    state.player_order = { p1, p2 }
    state.current_player_uid = p1
    state.next_player_uid = p2

    -- NOTE: for test
    space.add_element_to_space(state, create_element("H"), space.board(6, 8))
    space.add_element_to_space(state, create_element("E"), space.board(7, 8))
    space.add_element_to_space(state, create_element("L"), space.board(8, 8))
    space.add_element_to_space(state, create_element("L"), space.board(9, 8))
    space.add_element_to_space(state, create_element("W"), space.board(10, 7))
    space.add_element_to_space(state, create_element("R"), space.board(10, 9))
    space.add_element_to_space(state, create_element("L"), space.board(10, 10))
    space.add_element_to_space(state, create_element("D"), space.board(10, 11))

    local current_hand = get_current_hand().uid
    space.add_element_to_space(state, create_element("O"), space.hand(current_hand, 1))
    space.add_element_to_space(state, create_element("B"), space.hand(current_hand, 2))
    space.add_element_to_space(state, create_element("C"), space.hand(current_hand, 3))
    space.add_element_to_space(state, create_element("D"), space.hand(current_hand, 4))
    space.add_element_to_space(state, create_element("E"), space.hand(current_hand, 5))
    space.add_element_to_space(state, create_element("F"), space.hand(current_hand, 6))
    space.add_element_to_space(state, create_element("G"), space.hand(current_hand, 7))



    recalculate_layout()
    start_step_timer()
end

function game.resize()
    recalculate_layout()
end

function game.input(action_id, action)
    if action_id == Action.KEY_PRESSED then
        input.keypressed(state.input, action.key)
    end

    if action_id == Action.KEY_RELEASED then
        input.keyreleased(state.input, action.key)
    end

    if action_id == Action.MOUSE_PRESSED then
        input.mousepressed(state.input, action.x, action.y, action.button)
    end

    if action_id == Action.MOUSE_MOVED then
        input.mousemoved(state.input, action.x, action.y, action.dx, action.dy)
    end

    if action_id == Action.MOUSE_RELEASED then
        input.mousereleased(state.input, action.x, action.y, action.button)
    end

    if action_id == Action.MOUSE_WHEEL_MOVED then
        input.mousewheelmoved(state.input, action.delta)
    end
end

function game.update(dt)
    if state.is_restart then game.init() end

    input.update(state.input, conf, dt)
    detect_press_target()

    if input.is_key_released(state.input, "f11") then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen, "desktop")
    end

    if input.is_key_released(state.input, "r") then
        state.is_restart = true
    end

    if input.is_key_released(state.input, "s") and state.hand_animation.phase == nil then
        reset_step_timer()
        start_hand_switch()
    end

    update_step_timer(dt)

    if is_step_timeout() then
        reset_step_timer()
        start_hand_switch()
    end

    local view_conf = conf.field.view
    if state.input.mouse.wheel ~= 0 then
        state.board.zoom_target = utils.clamp(
            state.board.zoom_target + state.input.mouse.wheel * view_conf.zoom.wheel_sensitivity,
            view_conf.zoom.min,
            view_conf.zoom.max
        )
        state.board.zoom_focus.x = state.input.mouse.x
        state.board.zoom_focus.y = state.input.mouse.y
    end

    local zoom_diff = state.board.zoom_target - state.board.zoom
    if math.abs(zoom_diff) > 0.0001 then
        local t_zoom = 1 - math.exp(-view_conf.zoom.smooth_speed * dt)
        local next_zoom = state.board.zoom + zoom_diff * t_zoom
        local zoom_origin = get_board_zoom_origin(state.board.base_transform, state.board.offset, state.board.zoom)
        board_zoom(
            {
                x = state.board.zoom_focus.x - zoom_origin.x,
                y = state.board.zoom_focus.y - zoom_origin.y
            },
            next_zoom
        )
    else
        state.board.zoom = state.board.zoom_target
    end

    local max_offset_x = (state.board.base_transform.width * (state.board.zoom - 1)) / 2
    local max_offset_y = (state.board.base_transform.height * (state.board.zoom - 1)) / 2
    local min_offset_x = -max_offset_x
    local min_offset_y = -max_offset_y
    local is_panning = (not state.drag.active and not state.drag.press_element_uid and state.input.mouse.is_drag)
    local should_return_to_bounds = (not state.input.mouse.is_drag)

    if is_panning then
        if not state.board.is_drag_view then
            state.board.is_drag_view = true
            state.board.pan_raw_offset.x = state.board.offset.x
            state.board.pan_raw_offset.y = state.board.offset.y
        end

        state.board.pan_raw_offset.x = state.board.pan_raw_offset.x + state.input.mouse.dx
        state.board.pan_raw_offset.y = state.board.pan_raw_offset.y + state.input.mouse.dy
        state.board.offset.x = apply_pan_resistance(
            state.board.pan_raw_offset.x,
            min_offset_x,
            max_offset_x,
            view_conf.pan.overscroll_resistance
        )
        state.board.offset.y = apply_pan_resistance(
            state.board.pan_raw_offset.y,
            min_offset_y,
            max_offset_y,
            view_conf.pan.overscroll_resistance
        )
    elseif should_return_to_bounds then
        state.board.is_drag_view = false
        local target_x = utils.clamp(state.board.offset.x, min_offset_x, max_offset_x)
        local target_y = utils.clamp(state.board.offset.y, min_offset_y, max_offset_y)
        local t = math.min(1, dt * view_conf.pan.return_speed)
        state.board.offset.x = state.board.offset.x + (target_x - state.board.offset.x) * t
        state.board.offset.y = state.board.offset.y + (target_y - state.board.offset.y) * t
        state.board.pan_raw_offset.x = state.board.offset.x
        state.board.pan_raw_offset.y = state.board.offset.y
    end

    apply_board_transform()
    update_current_hand_elements()

    update_selection()
    update_dnd()

    update_transitions()

    tween.update(state.tweens, dt)

    input.clear(state.input)
end

function game.draw()
    love.graphics.clear(conf.colors.background)

    draw_board()

    local current_hand = get_current_hand()
    local anim = state.hand_animation

    if anim.phase ~= nil then
        local ht = current_hand.transform
        local cx = ht.x + ht.width  / 2
        local cy = ht.y + ht.height / 2
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.scale(anim.scale, anim.scale)
        love.graphics.translate(-cx, -cy)
        hand.draw(current_hand, conf, resources.textures.hand)
        draw_elements(1)
        love.graphics.pop()
    else
        hand.draw(current_hand, conf, resources.textures.hand)
        draw_elements(1)
    end

    draw_gui()
end

return game
