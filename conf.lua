-- TODO: implement color themes / reorganization for colors of objects
-- TODO: refactoring - separate config by entity, for example, elements, cells, etc.

-- NOTE: system love2d config
function love.conf(t)
    t.window.resizable = true
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.width = 720
    t.window.height = 1280
    t.window.title = "Scrabble"
    t.window.msaa = 4
    t.window.highdpi = true
end

---@class Config
---@field window WindowConfig Window configuration settings
---@field colors Colors Color definitions
---@field field FieldConfig Field/board configuration settings
---@field text TextConfig Text configuration settings
---@field hand HandConfig Hand configuration settings
---@field elements ElementsConfig Elements configuration settings
---@field click ClickConfig Click configuration settings
---@field step_time number Step time in seconds

local conf = {}

-- "en" or "ru"
conf.language = "ru"

---@class Padding
---@field top number
---@field bottom number
---@field left number
---@field right number

---@class WindowConfig
---@field padding Padding
---@field reference_height number
---@field reference_width number
conf.window = {
    reference_height = 1280,
    reference_width  = 720,
    padding          = {
        top    = 0,
        bottom = 0,
        left   = 0.07,
        right  = 0.07,
    }
}

conf.layout = {
    margin_ratio        = 0.02, -- vertical margin from screen top/bottom (fraction of window height)
    gap_ratio           = 0.18, -- gap between sections (fraction of hand height)
    top_bar_ratio       = 0.55, -- top bar height (fraction of hand height)
    top_bar_timer_ratio = 0.62, -- timer font height as fraction of top bar height
    top_bar_stats_ratio = 0.46, -- player stats font height as fraction of top bar height
    rounds_indicator_ratio = 0.15, -- round indicator row height as fraction of hand height
}

---@class Colors
---@field white number[] RGB color values from 0-1
---@field background number[] RGB color values from 0-1
---@field black number[] RGB color values from 0-1
conf.colors = {
    white = { 1, 1, 1 },
    background = { 0.92, 0.87, 0.96 },
    black = { 0.27, 0.27, 0.27 }
}

conf.field = {
    size = 15,
    gap_ratio = {
        top = 0.4,
        bottom = 0.5,
        left = 0.4,
        right = 0.4
    },
    -- TODO: will be better to calculate max size based on window size
    max_size = {
        width = 3000,
        height = 3000
    },
    multipliers = {
        { 3, 1, 1, 2, 1, 1, 1, 3, 1, 1, 1, 2, 1, 1, 3 },
        { 1, 2, 1, 1, 1, 3, 1, 1, 1, 3, 1, 1, 1, 2, 1 },
        { 1, 1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1, 1 },
        { 2, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 2 },
        { 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1 },
        { 1, 3, 1, 1, 1, 3, 1, 1, 1, 3, 1, 1, 1, 3, 1 },
        { 1, 1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1, 1 },
        { 3, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 3 },
        { 1, 1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1, 1 },
        { 1, 3, 1, 1, 1, 3, 1, 1, 1, 3, 1, 1, 1, 3, 1 },
        { 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1 },
        { 2, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 2 },
        { 1, 1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1, 1 },
        { 1, 2, 1, 1, 1, 3, 1, 1, 1, 3, 1, 1, 1, 2, 1 },
        { 3, 1, 1, 2, 1, 1, 1, 3, 1, 1, 1, 2, 1, 1, 3 }
    },
    cell_gap_ratio = 0.15,
    cell_colors = {
        shadow = { 0.16, 0.16, 0.16 }, -- NOTE: #292929
        multiplier = {
            [1] = { 0.9, 0.82, 0.82 }, -- NOTE: #E6D1D1
            [2] = { 1, 0.78, 0.72 },   -- NOTE: #FFC8B8
            [3] = { 0.4, 0.37, 0.4 },  -- NOTE: #675F69
        }
    },
    cell_text_offset = 0.1,
    cell_text_scale_factor = 0.7,
    cell_text_colors = {
        multipliers = {
            [2] = { 0.25, 0.25, 0.25 }, -- NOTE: #404040
            [3] = { 1, 0.78, 0.72 },    -- NOTE: #D2D2D2
        }
    },
    view = {
        pan = {
            overscroll_resistance = 0.01,
            return_speed = 12
        },
        zoom = {
            min = 1,
            max = 2,
            wheel_sensitivity = 0.05,
            smooth_speed = 14
        }
    }
}

---@class TextConfig
---@field letter_scale_factor number Scale factor for letter text
---@field point_scale_factor number Scale factor for point numbers relative to letter scale
---@field offset number Text positioning offset as fraction of cell size
---@field colors { element: number[], multiplier: table<number, number[]> } Colors for text elements
---@field screen { base_size: number, letter_scale_factor: number, point_scale_factor: number, offset: number, min_size: number, max_size: number } Screen text configuration settingsNOTE: text settings
conf.text = {
    letter_scale_factor = 0.7,          -- NOTE: Letter scale relative to cell size
    point_scale_factor = 0.7,           -- NOTE: Points scale relative to letter scale
    offset = 0.1,                       -- NOTE: Text offset from cell edges
    colors = {
        element = { 0.25, 0.25, 0.25 }, -- NOTE: #404040
    },

    element_padding = 0.15,           -- NOTE: Text offset from element edges
    element_scale_factor = 0.7,       -- NOTE: Element scale relative to element size
    element_point_scale_factor = 0.6, -- NOTE: Element points scale relative to element scale

    -- NOTE: screen element settings (for elements not on the board)
    screen = {
        base_size = 80, -- NOTE: Base size in pixels for screen elements
    }
}

---@class HandConfig
---@field offset_from_center_percent number Offset from center of screen as percentage of screen height
---@field min_offset_from_bottom_screen_percent number Minimum margin from bottom screen edge in percentage of screen height
---@field width_ratio number Width as ratio of screen width
---@field height_ratio number Height as ratio of screen height
---@field element_spacing_ratio number Spacing as ratio of element size
conf.hand = {
    width_ratio = 0.8,
    height_ratio = 0.15,
    offset_from_center_percent = 0.75,
    min_offset_from_bottom_screen_percent = 0.01,
    min_height = 60,
    element_spacing_ratio = 0.12,
    element_offset_from_side_ratio = 0.05,
    available_width_ratio = 0.9,
    available_height_ratio = 0.8
}

---@class ClickConfig
---@field selection_lift_offset number Pixels to lift element when selected
---@field selection_animation_duration number Duration of selection animation in seconds
---@field double_click_threshold number Threshold for double click detection in seconds
---@field drag_threshold_distance number Minimum distance in pixels to start drag
---@field drag_threshold_time number Maximum time in seconds to distinguish click from drag
conf.click = {
    selection_lift_offset = 20,
    selection_animation_duration = 0.2,
    double_click_threshold = 0.3,
    drag_threshold_distance = 10,
    drag_threshold_time = 0.15
}

---@class ElementsConfig
---@field [string] table<string, { count: number, points: number }> Elements configuration by alphabet
conf.elements = {
    latin    = require("alphabets.latin"),
    cyrillic = require("alphabets.cyrillic"),
    arabic   = require("alphabets.arabic"),
    greek    = require("alphabets.greek")
}

conf.language_alphabet = {
    en = conf.elements.latin,
    ru = conf.elements.cyrillic,
}

conf.step_time = 20

conf.rounds = 5
conf.round_fill_duration = 0.45
conf.game_over_delay     = 1.5

conf.gui = {
    end_step_button = {
        height_ratio  = 0.45, -- button height relative to hand height
        padding_ratio = 0.25, -- text padding relative to button height
        corner_radius = 8,
    },
    stats_panel = {
        padding_x     = 12,
        padding_y     = 5,
        corner_radius = 8,
        color         = { 1, 1, 1, 0.88 },
    },
}

conf.min_word_length       = 3
conf.start_word_min_length = 4

conf.popup = {
    width_ratio    = 0.85,
    padding_ratio  = 0.06,
    cols           = 6,
    overlay_alpha  = 0.45,
    corner_radius  = 16,
    enter_duration = 0.2,
    exit_duration  = 0.12,
    bg_color       = { 0.97, 0.95, 0.99 },
}

conf.button_animation = {
    exit_grow_duration   = 0.12,
    exit_max_scale       = 1.12,
    exit_shrink_duration = 0.18,
    pre_switch_delay     = 0.2,
    enter_duration       = 0.32,
}

conf.hand_animation = {
    shrink_duration         = 0.22,
    grow_duration           = 0.38,
    compact_duration        = 0.15,
    return_invalid_duration = 0.7,
    refill_duration         = 0.55,
    refill_stagger          = 0.28,
    cancel_drag_duration    = 0.35,
    full_hand_delay         = 0.2,
}

conf.word_merge = {
    duration           = 0.55,
    pop_fraction       = 0.30,
    cap_fraction       = 0.25,  -- fraction of sprite width/height used as end caps in 3-slice
    separator_color    = { 0.2, 0.2, 0.2 },
    separator_alpha    = 0.40,
    separator_w_ratio  = 0.025, -- separator line width as fraction of cell height
    separator_h_ratio  = 0.70,  -- separator line height as fraction of tile-only height (excl. shadow)
}

conf.initial_word_animation = {
    fly_duration        = 0.55,
    stagger             = 0.07,
    board_rise_duration = 0.55,
}

conf.gui_intro_animation = {
    stats_duration = 0.45,
    hand_duration  = 0.45,
}

conf.menu = {
    title_height_ratio    = 0.068, -- title font height as fraction of window height
    subtitle_height_ratio = 0.030, -- subtitle font height as fraction of window height
    pulse_min_alpha       = 0.35,
    pulse_max_alpha       = 1.0,
    pulse_speed           = 0.6,   -- pulses per second
}

conf.definition_hold_time = 0.6   -- seconds to hold on a locked element to open definition

conf.definition_popup = {
    width_ratio        = 0.88,
    padding_ratio      = 0.05,
    overlay_alpha      = 0.45,
    bg_color           = { 0.98, 0.97, 0.94, 1 },
    corner_radius      = 14,
    title_height_ratio = 0.038,
    body_height_ratio  = 0.026,
    enter_duration     = 0.30,
    exit_duration      = 0.18,
    max_scroll_speed   = 30,
}

return conf
