-- FIXME: когда дропается элемент в руку, но под рукой поле, почему то дропается в поле а не в руку
-- FIXME: пока драгаешь поле, и тач задевает элемент в руке, то поле перестает драгаться, а начинает элемент
-- FIXME: нельзя дропать элемент в уже занятую ячеку в поле


local game = {}

local resources_loaded = false

-- forward declarations (used in callbacks defined before the function bodies)
local recalculate_pending_points
local open_wildcard_popup

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
    local ww              = love.graphics.getWidth()
    local wh              = love.graphics.getHeight()
    local lc              = conf.layout
    local avail_w         = ww * (1 - conf.window.padding.left - conf.window.padding.right)

    -- derive section heights from natural hand size
    local natural_ht      = hand.get_world_transform(conf)
    local hand_h          = natural_ht.height
    local hand_w          = natural_ht.width
    local gap             = hand_h * lc.gap_ratio
    local top_bar_h       = hand_h * lc.top_bar_ratio
    local button_h        = hand_h * conf.gui.end_step_button.height_ratio
    local indicator_h     = hand_h * lc.rounds_indicator_ratio
    local margin          = wh * lc.margin_ratio

    -- board gets remaining vertical space
    local avail_for_board = wh - 2 * margin - top_bar_h - gap - gap - hand_h - gap - indicator_h - button_h

    -- first pass: get actual board dimensions (center at origin)
    board.recalculate(state.board, conf.field, avail_w, avail_for_board, 0, 0)
    local board_h = state.board.base_transform.height

    -- center entire block vertically
    local block_h = top_bar_h + gap + board_h + gap + hand_h + gap + indicator_h + button_h
    local block_y = (wh - block_h) / 2

    -- second pass: board at correct position
    local board_center_x = ww / 2
    local board_center_y = block_y + top_bar_h + gap + board_h / 2
    board.recalculate(state.board, conf.field, avail_w, avail_for_board, board_center_x, board_center_y)

    -- hand: below board, centered horizontally
    local hand_y = block_y + top_bar_h + gap + board_h + gap
    local hand_x = ww / 2 - hand_w / 2
    for _, h in pairs(state.hands) do
        hand.recalculate(h, conf, {
            x = hand_x,
            y = hand_y,
            width = hand_w,
            height = hand_h,
            z_index = natural_ht.z_index,
        })
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
            local tw = state.tweens[trans.tween_uid]
            local target_transform = space.get_space_transform(state, conf, trans.target_space)
            local saved_z = tw and tw.target and tw.target.z_index
            tween.update_target(tw, target_transform)
            -- preserve fly_z: z_index is fixed for the duration of the transition
            if saved_z and tw and tw.target then
                tw.target.z_index = saved_z
            end
        end
    end
end

local function draw_elements(from_z_index, to_z_index)
    local current_hand_uid = get_current_hand().uid
    local elems = table.filter(
        state.elements,
        function(value)
            if value.space and value.space.type == SpaceType.HAND and value.space.data.hand_uid ~= current_hand_uid then
                return false
            end
            return value.world_transform.z_index >= from_z_index and
                (to_z_index == nil or value.world_transform.z_index < to_z_index)
        end
    )

    table.sort(elems, function(a, b)
        return a.world_transform.z_index < b.world_transform.z_index
    end)

    for _, elem in ipairs(elems) do
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

local function get_top_bar_bounds()
    local bt     = state.board.base_transform
    local hand_h = get_current_hand().transform.height
    local gap    = hand_h * conf.layout.gap_ratio
    local h      = hand_h * conf.layout.top_bar_ratio
    return { x = bt.x, y = bt.y - gap - h, width = bt.width, height = h }
end

local function draw_stats()
    local bar  = get_top_bar_bounds()
    local font = resources.fonts.default
    love.graphics.setFont(font)
    local scale = bar.height * conf.layout.top_bar_stats_ratio / font:getHeight()
    local text_y = bar.y + (bar.height - font:getHeight() * scale) / 2

    local sides = {
        { uid = state.player_order[1], align = "left",  x = bar.x },
        { uid = state.player_order[2], align = "right", x = bar.x + bar.width },
    }

    for _, side in ipairs(sides) do
        local p = state.players[side.uid]
        if not p then goto continue end

        local is_current = (side.uid == state.current_player_uid)
        love.graphics.setColor(is_current and conf.colors.black or { 0.6, 0.6, 0.6 })

        local points_str = tostring(p.points)
        if p.pending_points > 0 then
            points_str = points_str .. " (+" .. p.pending_points .. ")"
        end
        local text = side.align == "right"
            and (points_str .. "  " .. p.name)
            or (p.name .. "  " .. points_str)
        local tw   = font:getWidth(text) * scale
        local x    = side.align == "right" and (side.x - tw) or side.x
        love.graphics.print(text, x, text_y, 0, scale, scale)

        ::continue::
    end
end

local function draw_step_timer()
    if state.step_timer == nil then return end

    local bar  = get_top_bar_bounds()
    local font = resources.fonts.default
    love.graphics.setFont(font)
    local scale = bar.height * conf.layout.top_bar_timer_ratio / font:getHeight()

    local seconds_left = math.ceil(state.step_timer)
    local text = tostring(seconds_left)

    if seconds_left <= 3 then
        love.graphics.setColor(0.8, 0.2, 0.2)
    else
        love.graphics.setColor(conf.colors.black)
    end

    local tw = font:getWidth(text) * scale
    local th = font:getHeight() * scale
    local x  = bar.x + (bar.width - tw) / 2
    local y  = bar.y + (bar.height - th) / 2
    love.graphics.print(text, x, y, 0, scale, scale)
end

local function get_round_indicator_bounds()
    local ht          = get_current_hand().transform
    local hand_h      = ht.height
    local gap         = hand_h * conf.layout.gap_ratio
    local indicator_h = hand_h * conf.layout.rounds_indicator_ratio
    return {
        x      = ht.x,
        y      = ht.y + hand_h + gap * 0.5,
        width  = ht.width,
        height = indicator_h,
    }
end

local function get_end_step_button_bounds()
    local bc          = conf.gui.end_step_button
    local ht          = get_current_hand().transform
    local hand_h      = ht.height
    local gap         = hand_h * conf.layout.gap_ratio
    local indicator_h = hand_h * conf.layout.rounds_indicator_ratio
    return {
        x      = ht.x,
        y      = ht.y + hand_h + gap * 0.5 + indicator_h + gap * 0.5,
        width  = ht.width,
        height = hand_h * bc.height_ratio,
    }
end

local function draw_end_step_button()
    local btn = state.button_animation
    if btn.scale <= 0 then return end
    local in_exit = (btn.phase == "exit")
    if not in_exit and not state.button_visible then return end

    local active = not in_exit
    local b      = get_end_step_button_bounds()
    local bc     = conf.gui.end_step_button
    local r      = bc.corner_radius

    local cx     = b.x + b.width / 2
    local cy     = b.y + b.height / 2
    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.scale(btn.scale, btn.scale)
    love.graphics.translate(-cx, -cy)

    -- background
    if active then
        love.graphics.setColor(0.15, 0.15, 0.15)
    else
        love.graphics.setColor(0.6, 0.6, 0.6)
    end
    love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, r, r)

    -- progress bar fill (left to right, white)
    if state.step_timer ~= nil then
        local progress = state.step_timer / conf.step_time
        local fill_w   = b.width * progress
        if fill_w > 0 then
            love.graphics.setScissor(b.x, b.y, fill_w, b.height)
            love.graphics.setColor(1, 1, 1, 0.25)
            love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, r, r)
            love.graphics.setScissor()
        end
    end

    -- label
    local font = resources.fonts.default
    love.graphics.setFont(font)
    local text = "END"
    local pad = b.height * bc.padding_ratio
    local scale = math.min(
        (b.width - pad * 2) / font:getWidth(text),
        (b.height - pad * 2) / font:getHeight()
    )
    local tw = font:getWidth(text) * scale
    local th = font:getHeight() * scale
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, b.x + (b.width - tw) / 2, b.y + (b.height - th) / 2, 0, scale, scale)

    love.graphics.pop()
end

local function draw_round_indicators()
    local n          = conf.rounds
    local turns      = state.turns_taken
    local r          = get_round_indicator_bounds()
    local sr         = 0.25 -- spacing as fraction of indicator width
    local w          = r.width / (n + (n - 1) * sr)
    local spacing    = w * sr
    local half_gap   = 2
    local half_w     = (w - half_gap) / 2
    local corner_r   = 2

    local cr, cg, cb = conf.colors.black[1], conf.colors.black[2], conf.colors.black[3]

    local function draw_half(hx, fill_t)
        -- outline
        love.graphics.setColor(cr, cg, cb, 0.4)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", hx, r.y, half_w, r.height, corner_r, corner_r)
        -- fill
        if fill_t >= 1 then
            love.graphics.setColor(cr, cg, cb)
            love.graphics.rectangle("fill", hx, r.y, half_w, r.height, corner_r, corner_r)
        elseif fill_t > 0 then
            love.graphics.setScissor(hx, r.y, half_w * fill_t, r.height + 1)
            love.graphics.setColor(cr, cg, cb)
            love.graphics.rectangle("fill", hx, r.y, half_w, r.height, corner_r, corner_r)
            love.graphics.setScissor()
        end
    end

    for i = 1, n do
        local bx           = r.x + (i - 1) * (w + spacing)

        local left_fill_t  = (turns >= (i - 1) * 2 + 1) and 1 or 0
        local right_fill_t = (turns >= i * 2) and 1 or 0

        if state.round_fill then
            if state.round_fill.index == i then
                if state.round_fill.half == 1 then
                    left_fill_t = state.round_fill.progress
                else
                    right_fill_t = state.round_fill.progress
                end
            end
        end

        draw_half(bx, left_fill_t)
        draw_half(bx + half_w + half_gap, right_fill_t)
    end
end

local function get_popup_layout()
    local ww, wh   = love.graphics.getDimensions()
    local alphabet = conf.language_alphabet[conf.language] or conf.elements.latin
    local letters  = {}
    for k in pairs(alphabet) do
        if k ~= "*" then table.insert(letters, k) end
    end
    table.sort(letters)

    local pc   = conf.popup
    local pw   = ww * pc.width_ratio
    local pad  = pw * pc.padding_ratio
    local cols = pc.cols
    local cgap = pw * 0.025
    local cw   = (pw - 2 * pad - (cols - 1) * cgap) / cols
    local rows = math.ceil(#letters / cols)
    local ph   = 2 * pad + rows * cw + (rows - 1) * cgap

    return {
        x        = (ww - pw) / 2,
        y        = (wh - ph) / 2,
        width    = pw,
        height   = ph,
        pad      = pad,
        cols     = cols,
        cell_w   = cw,
        cell_gap = cgap,
        letters  = letters,
    }
end

open_wildcard_popup = function(elem_uid)
    local p    = state.popup
    p.visible  = true
    p.type     = "wildcard"
    p.elem_uid = elem_uid
    p.scale    = 0
    p.phase    = "enter"
    tween.create(state.tweens, conf.popup.enter_duration, p, { scale = 1 },
        tween.easing.outBack, function() p.phase = nil end)
end

local function close_popup(on_complete)
    local p = state.popup
    p.phase = "exit"
    tween.create(state.tweens, conf.popup.exit_duration, p, { scale = 0 },
        tween.easing.inQuad, function()
            p.visible  = false
            p.type     = nil
            p.elem_uid = nil
            p.phase    = nil
            if on_complete then on_complete() end
        end)
end

local function draw_popup()
    if not state.popup.visible then return end

    local p      = state.popup
    local ww, wh = love.graphics.getDimensions()
    local pc     = conf.popup
    local lay    = get_popup_layout()

    -- overlay
    love.graphics.setColor(0, 0, 0, pc.overlay_alpha * p.scale)
    love.graphics.rectangle("fill", 0, 0, ww, wh)

    -- panel (scaled from center)
    local cx = lay.x + lay.width / 2
    local cy = lay.y + lay.height / 2
    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.scale(p.scale, p.scale)
    love.graphics.translate(-cx, -cy)

    love.graphics.setColor(pc.bg_color)
    love.graphics.rectangle("fill", lay.x, lay.y, lay.width, lay.height, pc.corner_radius, pc.corner_radius)

    for idx, letter in ipairs(lay.letters) do
        local col = (idx - 1) % lay.cols
        local row = math.floor((idx - 1) / lay.cols)
        local cell_x = lay.x + lay.pad + col * (lay.cell_w + lay.cell_gap)
        local cell_y = lay.y + lay.pad + row * (lay.cell_w + lay.cell_gap)

        local temp_elem = {
            uid             = 0,
            letter          = letter,
            points          = (conf.language_alphabet[conf.language] or conf.elements.latin)[letter].points,
            is_wildcard     = false,
            locked          = false,
            space           = { type = SpaceType.SCREEN, data = {} },
            transform       = { x = 0, y = 0, width = 0, height = 0, z_index = 0 },
            world_transform = {
                x = cell_x,
                y = cell_y,
                width = lay.cell_w,
                height = lay.cell_w,
                z_index = 10
            }
        }
        element.draw(conf, temp_elem, resources.textures.element, resources.fonts.default)
    end

    love.graphics.pop()
end

local function return_wildcard_to_hand_and_close_popup(on_complete)
    local elem_uid = state.popup.elem_uid
    local elem     = state.elements[elem_uid]
    if elem and elem.space.type == SpaceType.BOARD then
        board.remove_element(state.board, elem.space.data.x, elem.space.data.y)

        local hand_uid   = state.players[state.current_player_uid].hand_uid
        local hand_state = state.hands[hand_uid]
        local empty_slot
        for i = 1, hand_state.size do
            local v = hand_state.elem_uids[i]
            if v == nil or v == -1 then
                empty_slot = i
                break
            end
        end
        if empty_slot then
            transition.to(state, conf, elem_uid, conf.hand_animation.cancel_drag_duration,
                tween.easing.inOutCubic, space.hand(hand_uid, empty_slot))
        end
    end
    close_popup(on_complete)
end

local function update_popup()
    if not state.popup.visible or state.popup.phase ~= nil then return end
    if not state.input.mouse.is_click then return end

    local mp  = input.get_mouse_pos(state.input)
    local lay = get_popup_layout()

    -- check letter cells
    for idx, letter in ipairs(lay.letters) do
        local col    = (idx - 1) % lay.cols
        local row    = math.floor((idx - 1) / lay.cols)
        local cell_x = lay.x + lay.pad + col * (lay.cell_w + lay.cell_gap)
        local cell_y = lay.y + lay.pad + row * (lay.cell_w + lay.cell_gap)
        local bounds = { x = cell_x, y = cell_y, width = lay.cell_w, height = lay.cell_w }

        if utils.is_point_in_transform_bounds(bounds, mp) then
            local elem = state.elements[state.popup.elem_uid]
            if elem then
                local alphabet = conf.language_alphabet[conf.language] or conf.elements.latin
                elem.letter = letter
                elem.points = alphabet[letter].points
            end
            close_popup(function()
                recalculate_pending_points()
            end)
            return
        end
    end

    -- click outside panel — return element to hand and close
    if mp.x < lay.x or mp.x > lay.x + lay.width
        or mp.y < lay.y or mp.y > lay.y + lay.height then
        return_wildcard_to_hand_and_close_popup(nil)
    end
end

local function draw_gui()
    draw_stats()
    draw_round_indicators()
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

local function get_hand_slots_in_transition(hand_uid)
    local in_transition = {}
    for _, trans in ipairs(state.transitions) do
        if trans.target_space.type == SpaceType.HAND
            and trans.target_space.data.hand_uid == hand_uid then
            in_transition[trans.target_space.data.index] = true
        end
    end
    return in_transition
end

recalculate_pending_points = function()
    local seen = {}
    local total = 0

    for _, elem in pairs(state.elements) do
        if elem.space.type == SpaceType.BOARD and not elem.locked then
            local x, y = elem.space.data.x, elem.space.data.y
            local found = words.search(conf, state, resources, x, y)
            for _, word_range in ipairs(found) do
                local key = word_range.start_pos.x .. "," .. word_range.start_pos.y
                    .. "-" .. word_range.end_pos.x .. "," .. word_range.end_pos.y
                if not seen[key] then
                    seen[key] = true
                    total = total + words.calculate_score(conf, state, word_range)
                end
            end
        end
    end

    state.players[state.current_player_uid].pending_points = total
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
        local hand_uid      = state.players[state.current_player_uid].hand_uid
        local hand_state    = state.hands[hand_uid]
        local in_transition = get_hand_slots_in_transition(hand_uid)
        local empty_slot
        for i = 1, hand_state.size do
            local val = hand_state.elem_uids[i]
            if (val == nil or val == -1) and not in_transition[i] then
                empty_slot = i
                break
            end
        end

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

                    local placed_uid = state.selected_element_uid
                    transition.to(state, conf, placed_uid, 0.7, tween.easing.inOutCubic, {
                        type = SpaceType.BOARD,
                        data = board_pos
                    }, function()
                        if state.elements[placed_uid] and state.elements[placed_uid].is_wildcard then
                            open_wildcard_popup(placed_uid)
                        else
                            recalculate_pending_points()
                        end
                    end)

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
        local click_pos = state.input.mouse.click_pos
        if not click_pos then return end

        local current_hand_uid = get_current_hand().uid
        local clicked_elem = nil
        for _, elem in pairs(state.elements) do
            if elem.space.type == SpaceType.HAND and elem.space.data.hand_uid ~= current_hand_uid then
                goto continue
            end
            if elem.space.type == SpaceType.BOARD and elem.locked then
                goto continue
            end
            if utils.is_point_in_transform_bounds(elem.world_transform, click_pos) then
                if clicked_elem == nil or elem.world_transform.z_index > clicked_elem.world_transform.z_index then
                    clicked_elem = elem
                end
            end
            ::continue::
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


---@return string
local function pick_random_dict_word(min_len)
    local trie = resources.dict[conf.language or "en"]
    if not trie then return "word" end

    local alphabet = conf.language_alphabet[conf.language] or conf.elements.latin
    local function word_fits_alphabet(w)
        for _, ch in ipairs(utils.utf8_chars(w)) do
            if not alphabet[utils.utf8_upper(ch)] then return false end
        end
        return true
    end

    for _ = 1, 200 do
        -- pick a random root letter
        local root_keys = {}
        for k in pairs(trie) do table.insert(root_keys, k) end
        local ch = root_keys[math.random(#root_keys)]
        local word = ch
        local node = trie[ch]

        -- random walk, max 12 steps
        for _ = 1, 12 do
            local child_keys = {}
            for k in pairs(node.children) do table.insert(child_keys, k) end

            local can_stop = node.complete and #word >= min_len
            local has_children = #child_keys > 0

            if can_stop and (not has_children or math.random() < 0.4) then
                if word_fits_alphabet(word) then return word end
                break
            elseif has_children then
                ch = child_keys[math.random(#child_keys)]
                word = word .. ch
                node = node.children[ch]
            else
                break
            end
        end

        if node and node.complete and #word >= min_len and word_fits_alphabet(word) then
            return word
        end
    end

    return "word"
end

local function pick_random_letter()
    local alphabet = conf.language_alphabet[conf.language] or conf.elements.latin
    local pool = {}
    for letter, data in pairs(alphabet) do
        for _ = 1, data.count do
            table.insert(pool, letter)
        end
    end
    return pool[math.random(#pool)]
end

local function fill_current_hand(on_complete)
    local hand_uid      = state.players[state.current_player_uid].hand_uid
    local hand_state    = state.hands[hand_uid]
    local ht            = hand_state.transform
    local ww            = love.graphics.getWidth()
    local in_transition = get_hand_slots_in_transition(hand_uid)

    -- collect empty slots to fill
    local slots_to_fill = {}
    for i = 1, hand_state.size do
        local slot = hand_state.elem_uids[i]
        if (slot == nil or slot == -1) and not in_transition[i] then
            table.insert(slots_to_fill, i)
        end
    end

    state.is_filling_hand = true
    local function done()
        state.is_filling_hand = false
        if on_complete then on_complete() end
    end

    if #slots_to_fill == 0 then
        local dummy = { t = 0 }
        tween.create(state.tweens, conf.hand_animation.full_hand_delay, dummy, { t = 1 },
            tween.easing.linear, done)
        return
    end

    for stagger_index, i in ipairs(slots_to_fill) do
        local elem_uid       = create_element(pick_random_letter())
        local elem           = state.elements[elem_uid]

        -- start off-screen to the right, vertically centred on the hand
        local sz             = ht.height * 0.5
        elem.world_transform = {
            x       = ww + sz,
            y       = ht.y + (ht.height - sz) / 2,
            width   = sz,
            height  = sz,
            z_index = 2,
        }

        local delay          = (stagger_index - 1) * conf.hand_animation.refill_stagger
        local callback       = (stagger_index == #slots_to_fill) and done or nil

        transition.to(state, conf, elem_uid,
            conf.hand_animation.refill_duration,
            tween.easing.inOutCubic,
            space.hand(hand_uid, i),
            callback,
            delay)
    end
end

local function compact_hand(hand_uid)
    local hand_state = state.hands[hand_uid]

    -- collect present elements in slot order
    local present = {}
    for old_index = 1, hand_state.size do
        local uid = hand_state.elem_uids[old_index]
        if uid and uid ~= -1 then
            table.insert(present, { uid = uid, old_index = old_index })
        end
    end

    -- animate elements that need to shift to a new slot
    for new_index, item in ipairs(present) do
        if item.old_index ~= new_index then
            transition.to(state, conf, item.uid, conf.hand_animation.compact_duration,
                tween.easing.outQuad, space.hand(hand_uid, new_index))
        end
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
        compact_hand(data.hand_uid)
    elseif type == SpaceType.BOARD then
        board.remove_element(state.board, data.x, data.y)
        if element_data.is_wildcard then
            element_data.letter = "*"
            element_data.points = 0
        end
        recalculate_pending_points()
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
            local existing = board.get_elem_uid(state.board, board_pos.x, board_pos.y)
            if existing then
                -- cell occupied — return element to current available position
                local orig = state.drag.original_space
                if orig and orig.type == SpaceType.BOARD then
                    transition.to(state, conf, state.drag.element_uid, 0.3, tween.easing.inOutCubic,
                        space.board(orig.data.x, orig.data.y))
                else
                    -- came from hand: compact may have shifted slots, find a fresh empty one
                    local hand_uid      = state.players[state.current_player_uid].hand_uid
                    local hand_state    = state.hands[hand_uid]
                    local in_transition = get_hand_slots_in_transition(hand_uid)
                    local empty_slot
                    for i = 1, hand_state.size do
                        local val = hand_state.elem_uids[i]
                        if (val == nil or val == -1) and not in_transition[i] then
                            empty_slot = i
                            break
                        end
                    end
                    if empty_slot then
                        transition.to(state, conf, state.drag.element_uid, 0.3, tween.easing.inOutCubic,
                            space.hand(hand_uid, empty_slot))
                    end
                end
            else
                local placed_uid = state.drag.element_uid
                transition.to(state, conf, placed_uid, 0.3, tween.easing.inOutCubic, {
                    type = SpaceType.BOARD,
                    data = board_pos
                }, function()
                    if state.elements[placed_uid] and state.elements[placed_uid].is_wildcard then
                        open_wildcard_popup(placed_uid)
                    else
                        recalculate_pending_points()
                    end
                end)
            end
        elseif (space_type == SpaceType.HAND) then
            local hand_uid      = state.players[state.current_player_uid].hand_uid
            local hand_state    = state.hands[hand_uid]
            local in_transition = get_hand_slots_in_transition(hand_uid)
            local empty_slot
            for i = 1, hand_state.size do
                local val = hand_state.elem_uids[i]
                if (val == nil or val == -1) and not in_transition[i] then
                    empty_slot = i
                    break
                end
            end

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
            local hand_uid      = state.players[state.current_player_uid].hand_uid
            local hand_state    = state.hands[hand_uid]
            local in_transition = get_hand_slots_in_transition(hand_uid)
            local empty_slot
            for i = 1, hand_state.size do
                local val = hand_state.elem_uids[i]
                if (val == nil or val == -1) and not in_transition[i] then
                    empty_slot = i
                    break
                end
            end

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
        local in_hand_area = space.is_in_hand_area(state, conf, mouse_pos.x, mouse_pos.y)
        local best = nil
        for _, elem in pairs(state.elements) do
            if elem.space.type == SpaceType.HAND and elem.space.data.hand_uid ~= current_hand_uid then
                goto continue
            end
            if elem.space.type == SpaceType.BOARD and elem.locked then
                goto continue
            end
            -- board elements are not pickable when pressing in the hand area, and vice versa
            if in_hand_area and elem.space.type == SpaceType.BOARD then
                goto continue
            end
            if not in_hand_area and elem.space.type == SpaceType.HAND then
                goto continue
            end
            if utils.is_point_in_transform_bounds(elem.world_transform, mouse_pos) then
                if best == nil or elem.world_transform.z_index > best.world_transform.z_index then
                    best = elem
                end
            end
            ::continue::
        end
        if best then
            state.drag.press_element_uid = best.uid
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

local function lock_board_elements()
    for _, elem in pairs(state.elements) do
        if elem.space.type == SpaceType.BOARD then
            elem.locked = true
        end
    end
end

local function return_invalid_board_elements(on_complete)
    local hand_uid = state.players[state.current_player_uid].hand_uid
    local hand_state = state.hands[hand_uid]

    -- collect unlocked board elements not part of any valid word
    local to_return = {}
    for _, elem in pairs(state.elements) do
        if elem.space.type == SpaceType.BOARD and not elem.locked then
            local x, y = elem.space.data.x, elem.space.data.y
            local found = words.search(conf, state, resources, x, y)
            if #found == 0 then
                if elem.is_wildcard then
                    elem.letter = "*"
                    elem.points = 0
                end
                table.insert(to_return, elem.uid)
            end
        end
    end

    if #to_return == 0 then
        recalculate_pending_points()
        on_complete()
        return
    end

    -- assign slots locally without modifying hand_state (pre-assigning to hand_state would cause
    -- update_hand_elements_world_transform to snap world_transform each frame, killing the tween)
    local assignments = {}
    local used_slots = {}
    local in_transition = get_hand_slots_in_transition(hand_uid)
    for _, elem_uid in ipairs(to_return) do
        for i = 1, hand_state.size do
            local val = hand_state.elem_uids[i]
            if (val == nil or val == -1) and not used_slots[i] and not in_transition[i] then
                assignments[elem_uid] = i
                used_slots[i] = true
                break
            end
        end
    end

    local pending = #to_return
    local function on_each_complete()
        pending = pending - 1
        if pending == 0 then
            recalculate_pending_points()
            on_complete()
        end
    end

    for _, elem_uid in ipairs(to_return) do
        local slot = assignments[elem_uid]
        if slot then
            transition.to(state, conf, elem_uid, conf.hand_animation.return_invalid_duration,
                tween.easing.inOutCubic, space.hand(hand_uid, slot), on_each_complete)
        else
            on_each_complete()
        end
    end
end

local function next_step()
    lock_board_elements()
    local current = state.players[state.current_player_uid]
    current.points = current.points + current.pending_points
    current.pending_points = 0
    state.turns_taken = state.turns_taken + 1

    local round_index = math.ceil(state.turns_taken / 2)
    local half = (state.turns_taken % 2 == 1) and 1 or 2
    state.round_fill = { index = round_index, half = half, progress = 0 }
    tween.create(state.tweens, conf.round_fill_duration, state.round_fill,
        { progress = 1 }, tween.easing.outCubic)

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

local function cancel_selection(on_complete)
    if not state.selected_element_uid then
        on_complete()
        return
    end

    local elem_uid = state.selected_element_uid
    state.selected_element_uid = nil

    local element_data = state.elements[elem_uid]
    if not element_data then
        on_complete()
        return
    end

    tween.create(
        state.tweens,
        conf.click.selection_animation_duration,
        element_data.transform,
        { x = 0, y = 0, width = 0, height = 0, z_index = 0 },
        tween.easing.outQuad,
        on_complete
    )
end

local function cancel_drag(on_complete)
    state.selected_element_uid = nil

    if not state.drag.active then
        state.drag = init_dnd()
        on_complete()
        return
    end

    local elem_uid = state.drag.element_uid
    local orig     = state.drag.original_space
    state.drag     = init_dnd() -- reset immediately so update_dnd stops tracking

    if elem_uid and state.elements[elem_uid] then
        local elem = state.elements[elem_uid]
        elem.transform = { x = 0, y = 0, width = 0, height = 0, z_index = 0 }

        local target_space
        if orig and orig.type == SpaceType.BOARD then
            target_space = space.board(orig.data.x, orig.data.y)
        else
            local hand_uid      = state.players[state.current_player_uid].hand_uid
            local hand_state    = state.hands[hand_uid]
            local in_transition = get_hand_slots_in_transition(hand_uid)
            for i = 1, hand_state.size do
                local val = hand_state.elem_uids[i]
                if (val == nil or val == -1) and not in_transition[i] then
                    target_space = space.hand(hand_uid, i)
                    break
                end
            end
        end

        if target_space then
            transition.to(state, conf, elem_uid, conf.hand_animation.cancel_drag_duration,
                tween.easing.inOutCubic, target_space, on_complete)
        else
            on_complete()
        end
    else
        on_complete()
    end
end

local function start_button_exit(on_complete)
    local btn = state.button_animation
    btn.phase = "exit"
    btn.scale = 1
    tween.create(state.tweens, conf.button_animation.exit_grow_duration, btn,
        { scale = conf.button_animation.exit_max_scale }, tween.easing.outQuad,
        function()
            tween.create(state.tweens, conf.button_animation.exit_shrink_duration, btn,
                { scale = 0 }, tween.easing.inQuad,
                function()
                    btn.phase = nil
                    if on_complete then on_complete() end
                end)
        end)
end

local function start_button_enter(on_complete)
    state.button_visible = true
    local btn = state.button_animation
    btn.phase = "enter"
    btn.scale = 0
    tween.create(state.tweens, conf.button_animation.enter_duration, btn,
        { scale = 1 }, tween.easing.outBack,
        function()
            btn.phase = nil
            if on_complete then on_complete() end
        end)
end

local function trigger_end_step()
    state.button_visible = false
    reset_step_timer()
    start_button_exit(function()
        local dummy = { t = 0 }
        tween.create(state.tweens, conf.button_animation.pre_switch_delay, dummy, { t = 1 },
            tween.easing.linear, function()
                state.pending_hand_switch = true
            end)
    end)
end

local function start_hand_switch()
    local anim = state.hand_animation
    anim.phase = "return"
    anim.scale = 1

    cancel_selection(function()
        cancel_drag(function()
            return_invalid_board_elements(function()
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

                        if math.floor(state.turns_taken / 2) >= conf.rounds then
                            anim.phase = "gameover"
                            local captured_tweens = state.tweens
                            local dummy = { t = 0 }
                            tween.create(state.tweens, conf.game_over_delay, dummy, { t = 1 },
                                tween.easing.linear, function()
                                    if state.tweens == captured_tweens then
                                        state.is_restart = true
                                    end
                                end)
                            return
                        end

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
                                fill_current_hand(function()
                                    start_button_enter(start_step_timer)
                                end)
                            end
                        )
                    end
                )
            end)
        end)
    end)
end

function game.init()
    _G.uid_counter = 0

    if not resources_loaded then
        resources.load()
        resources_loaded = true
    end

    state = {
        is_restart           = false,

        current_player_uid   = nil,
        next_player_uid      = nil,
        player_order         = {},
        selected_element_uid = nil,
        step_timer           = nil,
        turns_taken          = 0,
        round_fill           = nil,
        is_filling_hand      = false,
        pending_hand_switch  = false,
        button_visible       = false,
        hand_animation       = { phase = nil, scale = 1 },
        button_animation     = { phase = nil, scale = 0 },
        popup                = { visible = false, type = nil, elem_uid = nil, scale = 0, phase = nil },

        elements             = {},
        pool                 = {},
        board                = board.create(conf.field),
        hands                = {},
        players              = {},
        transitions          = {},
        tweens               = {},

        input                = input.init(),
        drag                 = init_dnd(),
    }

    local p1 = create_player("Pavlik")
    local p2 = create_player("Vladik")

    state.player_order = { p1, p2 }
    state.current_player_uid = p1
    state.next_player_uid = p2

    local word = pick_random_dict_word(conf.start_word_min_length)
    local chars = utils.utf8_chars(word)
    local center = math.ceil(conf.field.size / 2)
    local start_x = center - math.floor(#chars / 2)
    for i, ch in ipairs(chars) do
        local letter = utils.utf8_upper(ch)
        space.add_element_to_space(state, create_element(letter), space.board(start_x + i - 1, center))
    end

    lock_board_elements()

    recalculate_layout()
    fill_current_hand(function()
        start_button_enter(start_step_timer)
    end)
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

    if action_id == Action.TOUCH_PRESSED then
        input.touchpressed(state.input, action.id, action.x, action.y)
    end

    if action_id == Action.TOUCH_MOVED then
        input.touchmoved(state.input, action.id, action.x, action.y)
    end

    if action_id == Action.TOUCH_RELEASED then
        input.touchreleased(state.input, action.id)
    end
end

function game.update(dt)
    if state.is_restart then game.init() end

    input.update(state.input, conf, dt)
    if state.hand_animation.phase == nil and not state.is_filling_hand then
        detect_press_target()
    end

    if input.is_key_released(state.input, "f11") then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen, "desktop")
    end

    if input.is_key_released(state.input, "r") then
        state.is_restart = true
    end

    local can_end_step = state.step_timer ~= nil
        and state.hand_animation.phase == nil
        and state.button_animation.phase == nil
        and not state.pending_hand_switch
        and not state.popup.visible
        and not state.is_filling_hand

    if input.is_key_released(state.input, "s") and can_end_step then
        trigger_end_step()
    end

    if state.input.mouse.is_click and can_end_step then
        local mp = input.get_mouse_pos(state.input)
        local b = get_end_step_button_bounds()
        if utils.is_point_in_transform_bounds(b, mp) then
            trigger_end_step()
        end
    end

    update_step_timer(dt)

    if is_step_timeout() and can_end_step then
        trigger_end_step()
    end

    if is_step_timeout() and state.popup.visible and state.popup.phase == nil then
        return_wildcard_to_hand_and_close_popup(trigger_end_step)
    end

    if state.pending_hand_switch and #state.transitions == 0 and state.hand_animation.phase == nil then
        state.pending_hand_switch = false
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

    if state.input.pinch_delta ~= 0 then
        state.board.zoom_target = utils.clamp(
            state.board.zoom_target * (1 + state.input.pinch_delta),
            view_conf.zoom.min,
            view_conf.zoom.max
        )
        if state.input.pinch_midpoint then
            state.board.zoom_focus.x = state.input.pinch_midpoint.x
            state.board.zoom_focus.y = state.input.pinch_midpoint.y
        end
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
    local is_panning = (not state.drag.active and not state.drag.press_element_uid
        and state.input.mouse.is_drag and not state.input.is_two_finger)
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

    if state.hand_animation.phase == nil and not state.is_filling_hand and not state.popup.visible then
        update_selection()
        update_dnd()
    end

    update_popup()

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
        local cx = ht.x + ht.width / 2
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
    draw_popup()
end

return game
