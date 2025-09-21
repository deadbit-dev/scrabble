local json = require("json")
local log = require("log")

---@class ElementsConfLoader
---@field elements table<string, table<string, { count: number, points: number }>> Loaded elements configuration by alphabet
local elements_conf_loader = {}

---Load elements configuration from separate JSON files
---@param game Game The game instance
function elements_conf_loader.load(game)
    -- Initialize conf.elements with empty table
    game.conf.elements = {}

    -- List of available alphabets (file names without .json extension)
    local alphabets = { "latin", "cyrillic", "greek", "arabic" }

    -- Load each alphabet from its own JSON file
    for _, alphabet in ipairs(alphabets) do
        local filename = alphabet .. ".json"
        local success, data = pcall(function()
            local file = love.filesystem.read(filename)
            return json.decode(file)
        end)

        if success and data then
            game.conf.elements[alphabet] = data
        else
            log.warn("Failed to load " .. filename .. ": " .. tostring(data))
        end
    end

    elements_conf_loader.elements = game.conf.elements
end

return elements_conf_loader
