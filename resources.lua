local resources = {
    fonts = {},
    textures = {},
}

local asset_folder_path = "assets/"

local function cleanupResource(resource)
    if resource then
        resource:release()
    end
end

function resources.loadFont(id, path, size)
    cleanupResource(resources.fonts[id])
    resources.fonts[id] = love.graphics.newFont(path, size)
end

local function loadFonts()
    local files = love.filesystem.getDirectoryItems(asset_folder_path)
    for _, file in ipairs(files) do
        if file:match("%.ttf$") or file:match("%.otf$") then
            local id = file:gsub("%.ttf$", ""):gsub("%.otf$", "")
            resources.loadFont(id, asset_folder_path .. file, 32)
        end
    end
end

function resources.loadTexture(id, path)
    cleanupResource(resources.textures[id])
    resources.textures[id] = love.graphics.newImage(path)
    resources.textures[id]:setFilter("linear", "linear")
end

local function loadTextures()
    local files = love.filesystem.getDirectoryItems(asset_folder_path)
    for _, file in ipairs(files) do
        if file:match("%.png$") or file:match("%.jpg$") or file:match("%.jpeg$") then
            local id = file:gsub("%.png$", ""):gsub("%.jpg$", ""):gsub("%.jpeg$", "")
            resources.loadTexture(id, asset_folder_path .. file)
        end
    end
end

function resources.load()
    loadFonts()
    loadTextures()
end

return resources
