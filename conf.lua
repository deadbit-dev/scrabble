-- TODO: implement color themes / reorganization for colors of objects

local love = require("love")

local conf = {}

-- Window settings
conf.window = {
    padding = {
        top = 0.2,    -- ~150px of 1280px
        bottom = 0.2, -- ~150px of 1280px
        left = 0.07,  -- ~50px of 720px
        right = 0.07  -- ~50px of 720px
    }
}

conf.colors = {
    white = { 1, 1, 1 },
    background = { 0.92, 0.87, 0.96 },
}
-- Field settings
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
    }
}

-- Cell settings
conf.cell = {
    gap_ratio = 0.15,
    colors = {
        shadow = { 0.16, 0.16, 0.16 }, -- #292929
        multiplier = {
            [1] = { 1, 0.92, 0.92 },   -- #FFEBEB
            [2] = { 1, 0.78, 0.72 },   -- #FFC8B8
            [3] = { 0.4, 0.37, 0.4 },  -- #675F69
        }
    }
}

-- Text settings
conf.text = {
    letter_scale_factor = 0.7,          -- Letter scale relative to cell size
    point_scale_factor = 0.7,           -- Points scale relative to letter scale
    offset = 0.1,                       -- Text offset from cell edges
    colors = {
        element = { 0.25, 0.25, 0.25 }, -- #404040
        multiplier = {
            [2] = { 0.25, 0.25, 0.25 }, -- #404040
            [3] = { 1, 0.78, 0.72 },    -- #D2D2D2
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
