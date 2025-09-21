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

local conf = {}

---@class WindowConfig
---@field padding { top: number, bottom: number, left: number, right: number }
conf.window = {
    padding = {
        top = 0.2,    -- NOTE: ~150px of 1280px
        bottom = 0.2, -- NOTE: ~150px of 1280px
        left = 0.07,  -- NOTE: ~50px of 720px
        right = 0.07  -- NOTE: ~50px of 720px
    }
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

---@class FieldConfig
---@field size number Size of the game board (width/height in cells)
---@field gap_ratio { top: number, bottom: number, left: number, right: number } Ratios for field gaps
---@field max_size { width: number, height: number } Maximum board dimensions in pixels
---@field multipliers number[][] 2D array of cell multiplier values
---@field cell_gap_ratio number Ratio for gaps between cells
---@field cell_colors { shadow: number[], multiplier: table<number, number[]> } Colors for cell elements
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
        width = 600,
        height = 600
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
        multiplier = {
            [2] = { 0.25, 0.25, 0.25 }, -- NOTE: #404040
            [3] = { 1, 0.78, 0.72 },    -- NOTE: #D2D2D2
        },
    },

    element_padding = 0.15,           -- NOTE: Text offset from element edges
    element_scale_factor = 0.7,       -- NOTE: Element scale relative to element size
    element_point_scale_factor = 0.7, -- NOTE: Element points scale relative to element scale

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
    offset_from_center_percent = 1.2,
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
conf.elements = {}

return conf
