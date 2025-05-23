-- TODO: implement color themes / reorganization for colors of objects

---@class WindowConfig
---@field padding { top: number, bottom: number, left: number, right: number }

---@class Colors
---@field white number[] RGB color values from 0-1
---@field background number[] RGB color values from 0-1

---@class FieldConfig
---@field size number Size of the game board (width/height in cells)
---@field gap_ratio { top: number, bottom: number, left: number, right: number } Ratios for field gaps
---@field max_size { width: number, height: number } Maximum board dimensions in pixels
---@field multipliers number[][] 2D array of cell multiplier values
---@field cell_gap_ratio number Ratio for gaps between cells
---@field cell_colors { shadow: number[], multiplier: table<number, number[]> } Colors for cell elements

---@class TextConfig
---@field letter_scale_factor number Scale factor for letter text
---@field point_scale_factor number Scale factor for point numbers relative to letter scale
---@field offset number Text positioning offset as fraction of cell size
---@field colors { element: number[], multiplier: table<number, number[]> } Colors for text elements

---@class Config
---@field window WindowConfig Window configuration settings
---@field colors Colors Color definitions
---@field field FieldConfig Field/board configuration settings
---@field text TextConfig Text configuration settings

local conf = {}

-- NOTE: window settings
conf.window = {
    padding = {
        top = 0.2,    -- NOTE: ~150px of 1280px
        bottom = 0.2, -- NOTE: ~150px of 1280px
        left = 0.07,  -- NOTE: ~50px of 720px
        right = 0.07  -- NOTE: ~50px of 720px
    }
}

conf.colors = {
    white = { 1, 1, 1 },
    background = { 0.92, 0.87, 0.96 },
}
-- NOTE: field settings
conf.field = {
    size = 15,
    gap_ratio = {
        top = 0.4,
        bottom = 0.5,
        left = 0.4,
        right = 0.4
    },
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
            [1] = { 1, 0.92, 0.92 },   -- NOTE: #FFEBEB
            [2] = { 1, 0.78, 0.72 },   -- NOTE: #FFC8B8
            [3] = { 0.4, 0.37, 0.4 },  -- NOTE: #675F69
        }
    }
}

-- NOTE: elements settings
-- IDEA: maybe later will be bater geneate points for each language depends of world list
conf.elements = {
    english = {
        { letter = "A", count = 9,  points = 1 },
        { letter = "B", count = 2,  points = 3 },
        { letter = "C", count = 2,  points = 3 },
        { letter = "D", count = 4,  points = 2 },
        { letter = "E", count = 12, points = 1 },
        { letter = "F", count = 2,  points = 4 },
        { letter = "G", count = 3,  points = 2 },
        { letter = "H", count = 2,  points = 4 },
        { letter = "I", count = 9,  points = 1 },
        { letter = "J", count = 1,  points = 8 },
        { letter = "K", count = 1,  points = 5 },
        { letter = "L", count = 4,  points = 1 },
        { letter = "M", count = 2,  points = 3 },
        { letter = "N", count = 6,  points = 1 },
        { letter = "O", count = 8,  points = 1 },
        { letter = "P", count = 2,  points = 3 },
        { letter = "Q", count = 1,  points = 10 },
        { letter = "R", count = 6,  points = 1 },
        { letter = "S", count = 4,  points = 1 },
        { letter = "T", count = 6,  points = 1 },
        { letter = "U", count = 4,  points = 1 },
        { letter = "V", count = 2,  points = 4 },
        { letter = "W", count = 2,  points = 4 },
        { letter = "X", count = 1,  points = 8 },
        { letter = "Y", count = 2,  points = 4 },
        { letter = "Z", count = 1,  points = 10 },
        { letter = "*", count = 2,  points = 0 }
    },
    russian = {
        { letter = "А", count = 8, points = 1 },
        { letter = "Б", count = 3, points = 3 },
        { letter = "В", count = 8, points = 1 },
        { letter = "Г", count = 3, points = 3 },
        { letter = "Д", count = 4, points = 2 },
        { letter = "Е", count = 8, points = 1 },
        { letter = "Ж", count = 1, points = 5 },
        { letter = "З", count = 1, points = 5 },
        { letter = "И", count = 8, points = 1 },
        { letter = "Й", count = 2, points = 4 },
        { letter = "К", count = 4, points = 2 },
        { letter = "Л", count = 4, points = 2 },
        { letter = "М", count = 4, points = 2 },
        { letter = "Н", count = 8, points = 1 },
        { letter = "О", count = 8, points = 1 },
        { letter = "П", count = 4, points = 2 },
        { letter = "Р", count = 8, points = 1 },
        { letter = "С", count = 8, points = 1 },
        { letter = "Т", count = 8, points = 1 },
        { letter = "У", count = 4, points = 3 },
        { letter = "Ф", count = 1, points = 8 },
        { letter = "Х", count = 1, points = 5 },
        { letter = "Ц", count = 1, points = 5 },
        { letter = "Ч", count = 1, points = 5 },
        { letter = "Ш", count = 1, points = 8 },
        { letter = "Щ", count = 1, points = 10 },
        { letter = "Ъ", count = 1, points = 10 },
        { letter = "Ы", count = 2, points = 4 },
        { letter = "Ь", count = 3, points = 3 },
        { letter = "Э", count = 1, points = 8 },
        { letter = "Ю", count = 1, points = 8 },
        { letter = "Я", count = 3, points = 3 },
        { letter = "*", count = 2, points = 0 }
    }
}

-- NOTE: text settings
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
    }
}

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

return conf
