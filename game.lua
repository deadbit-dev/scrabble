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

local function create_player()
    local hand_state = hand.create()
    state.hands[hand_state.uid] = hand_state
    local player_state = player.create(hand_state.uid)
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
                local space_transform = board.get_world_transform_in_board_space(state.board, conf.field, x, y)
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

local function board_offset(offset)
    state.board.offset.x = offset.x
    state.board.offset.y = offset.y
end

local function board_zoom(pos, zoom)
    local new_zoom = math.min(2.5, math.max(1, zoom))
    local old_zoom = state.board.zoom

    board_offset({
        x = state.board.offset.x - pos.x * (new_zoom / old_zoom - 1),
        y = state.board.offset.y - pos.y * (new_zoom / old_zoom - 1)
    })

    state.board.zoom = new_zoom

    -- local new_zoom = math.min(2.5, math.max(1.0, zoom))
    -- local old_zoom = state.board.zoom

    -- -- Вычисляем изменение зума
    -- local zoom_delta = new_zoom - old_zoom

    -- if zoom_delta > 0 then
    --     -- УВЕЛИЧЕНИЕ: чистое слежение за курсором
    --     state.board.offset.x = state.board.offset.x - pos.x * (new_zoom / old_zoom - 1)
    --     state.board.offset.y = state.board.offset.y - pos.y * (new_zoom / old_zoom - 1)
    -- elseif zoom_delta < 0 then
    --     -- УМЕНЬШЕНИЕ: комбинация слежения и возврата к центру

    --     -- 1. Сначала вычисляем pure tracked offset
    --     local tracked_offset_x = state.board.offset.x - pos.x * (new_zoom / old_zoom - 1)
    --     local tracked_offset_y = state.board.offset.y - pos.y * (new_zoom / old_zoom - 1)

    --     -- 2. Определяем силу возврата к центру
    --     -- Чем ближе new_zoom к 1.0, тем сильнее возвращаемся
    --     local distance_from_one = new_zoom - 1.0 -- от 0.0 до 1.5
    --     -- local return_strength = 1.0 - (distance_from_one / 1.5) -- от 1.0 до 0.0

    --     -- Можно использовать нелинейную функцию для более плавного/резкого перехода
    --     local return_strength = math.pow(1.0 - (distance_from_one / 1.5), 0.7)

    --     -- 3. Интерполируем
    --     state.board.offset.x = tracked_offset_x * (1 - return_strength)
    --     state.board.offset.y = tracked_offset_y * (1 - return_strength)
    -- end

    -- state.board.zoom = new_zoom
end

-- TODO: передать в board.update_transfrom посчитаный внешний transform
local function update_board_transform()
    -- NOTE: Calculate the total available space for the board using percentage-based padding
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    state.board.transform.x = window_width / 2
    state.board.transform.y = window_height / 2
    state.board.transform.width = window_width * (1 - (conf.window.padding.left + conf.window.padding.right))
    state.board.transform.height = window_height * (1 - (conf.window.padding.top + conf.window.padding.bottom))
    state.board.transform = board.get_world_transform(state.board, conf.field)
end

local function apply_board_transform()
    state.board.transform.x = state.board.transform.x + state.board.offset.x
    state.board.transform.y = state.board.transform.y + state.board.offset.y

    state.board.transform.width = state.board.transform.width * state.board.zoom
    state.board.transform.height = state.board.transform.height * state.board.zoom

    update_board_elemenets_world_transform()
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

local function update_current_hand_transform()
    local current_hand = get_current_hand()
    current_hand.transform = hand.get_world_transform(conf)
    update_hand_elements_world_transform(current_hand.uid)
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
    local sorted_elements = table.filter(
        state.elements,
        function(value)
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
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()

    love.graphics.print("NIK1", window_width * 0.05, window_height * 0.025)
    love.graphics.print("100", window_width * 0.05, window_height * 0.025 + 50)

    love.graphics.print("NIK2", window_width * 0.75, window_height * 0.025)
    love.graphics.print("300", window_width * 0.75, window_height * 0.025 + 50)
end

local function draw_step_timer()

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
    local click_pos = input.get_mouse_pos(state.input)
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

---@return DragState
local function init_dnd()
    return {
        active = false,
        element_uid = nil,
        original_space = nil
    }
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

-- ###########################################################################################################################

function game.init()
    _G.uid_counter = 0

    resources.load()

    state = {
        is_restart = false,
        is_drag_view = false,

        current_player_uid = nil,
        next_player_uid = nil,
        selected_element_uid = nil,
        step_timer = nil,

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

    local p1 = create_player()
    local p2 = create_player()

    print("PLAYER1:", p1)
    print("PLAYER2:", p2)

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



    start_step_timer()
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

    if input.is_key_released(state.input, "f11") then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen, "desktop")
    end

    if input.is_key_released(state.input, "r") then
        state.is_restart = true
    end

    update_step_timer(dt)

    if is_step_timeout() then
        reset_step_timer()
        next_step()
        print("NEXT TURN", state.current_player_uid, state.next_player_uid)
        -- TODO: нужно включать только по готовности
        start_step_timer()
    end

    update_board_transform()
    update_current_hand_transform()

    if (not state.drag.active and state.input.mouse.is_drag) then
        board_offset({ x = state.board.offset.x + state.input.mouse.dx, y = state.board.offset.y + state.input.mouse.dy })
    end

    if state.input.mouse.wheel ~= 0 then
        board_zoom(
            {
                x = state.input.mouse.x - (state.board.transform.x + state.board.offset.x),
                y = state.input.mouse.y - (state.board.transform.y + state.board.offset.y)
            },
            state.board.zoom + state.input.mouse.wheel * 0.1
        )
    end

    apply_board_transform()

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
    hand.draw(current_hand, conf, resources.textures.hand)

    draw_elements(1)

    -- draw_gui()
end

return game
