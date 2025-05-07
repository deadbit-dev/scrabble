local love = require("love")

local resources = {
    fonts = {},
    textures = {},
}

local function loadFont(id, path, size)
    resources.fonts[id] = love.graphics.newFont(path, size)
end

local function loadFonts()
    local files = love.filesystem.getDirectoryItems("assets")
    for _, file in ipairs(files) do
        if file:match("%.ttf$") or file:match("%.otf$") then
            local id = file:gsub("%.ttf$", ""):gsub("%.otf$", "")
            loadFont(id, "assets/" .. file, 32)
        end
    end
end

local function loadTexture(id, path)
    resources.textures[id] = love.graphics.newImage(path)
    resources.textures[id]:setFilter("linear", "linear")
end

local function loadTextures()
    local files = love.filesystem.getDirectoryItems("assets")
    for _, file in ipairs(files) do
        if file:match("%.png$") or file:match("%.jpg$") or file:match("%.jpeg$") then
            local id = file:gsub("%.png$", ""):gsub("%.jpg$", ""):gsub("%.jpeg$", "")
            loadTexture(id, "assets/" .. file)
        end
    end
end

function resources.load()
    loadFonts()
    loadTextures()
end

return resources
