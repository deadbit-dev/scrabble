local resources = {}

local json = import("json")
local dict = import("dict")
local log = import("log")

resources.textures = {}
resources.fonts = {}
resources.dict = {}

function resources.load()
    resources.textures.field = love.graphics.newImage("assets/field.png")
    resources.textures.cell = love.graphics.newImage("assets/cell.png")
    resources.textures.cell_shadow = love.graphics.newImage("assets/cell_shadow.png")
    resources.textures.cross = love.graphics.newImage("assets/cross.png")
    resources.textures.element = love.graphics.newImage("assets/element.png")
    resources.textures.hand = love.graphics.newImage("assets/hand.png")
    resources.textures.bottom_pad = love.graphics.newImage("assets/bottom_pad.png")
    resources.textures.top_pad = love.graphics.newImage("assets/top_pad.png")
    resources.textures.top_pad_shadow = love.graphics.newImage("assets/top_pad_shadow.png")
    resources.textures.cursor = love.graphics.newImage("assets/cursor.png")
    resources.textures.cursor_default = love.graphics.newImage("assets/cursor_default.png")
    resources.textures.cursor_grab = love.graphics.newImage("assets/cursor_grab.png")
    resources.textures.cursor_grab2 = love.graphics.newImage("assets/cursor_grab2.png")

    for _, texture in pairs(resources.textures) do
        texture:setFilter("linear", "linear")
    end

    log.log("Images loaded")

    resources.fonts.default = love.graphics.newFont("assets/default.ttf", 64)

    log.log("Fonts loaded")

    local success, content = pcall(love.filesystem.read, "dicts/en_trie.json")
    log.log(success, content)

    if success and content then
        local trie = json.decode(content)
        log.log("Loaded dict with " .. dict.count_words(trie) .. " words")
        resources.dict.en = trie
    end
end

return resources
