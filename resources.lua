local resources = {}

local asset_path = "assets/"

resources.textures = {}
resources.fonts = {}

function resources.load()
    resources.textures.field = love.graphics.newImage(asset_path .. "field.png")
    resources.textures.cell = love.graphics.newImage(asset_path .. "cell.png")
    resources.textures.cell_shadow = love.graphics.newImage(asset_path .. "cell_shadow.png")
    resources.textures.cross = love.graphics.newImage(asset_path .. "cross.png")
    resources.textures.element = love.graphics.newImage(asset_path .. "element.png")
    resources.textures.hand = love.graphics.newImage(asset_path .. "hand.png")
    resources.textures.bottom_pad = love.graphics.newImage(asset_path .. "bottom_pad.png")
    resources.textures.top_pad = love.graphics.newImage(asset_path .. "top_pad.png")
    resources.textures.top_pad_shadow = love.graphics.newImage(asset_path .. "top_pad_shadow.png")
    resources.textures.cursor = love.graphics.newImage(asset_path .. "cursor.png")
    resources.textures.cursor_default = love.graphics.newImage(asset_path .. "cursor_default.png")
    resources.textures.cursor_grab = love.graphics.newImage(asset_path .. "cursor_grab.png")
    resources.textures.cursor_grab2 = love.graphics.newImage(asset_path .. "cursor_grab2.png")

    for _, texture in pairs(resources.textures) do
        texture:setFilter("linear", "linear")
    end

    resources.fonts.default = love.graphics.newFont(asset_path .. "default.ttf", 64)
end

return resources
