---@diagnostic disable: duplicate-set-field

local lurker = require("lurker")
local lume = require("lume")

_G.import = function(module_name)
    local caller_info = debug.getinfo(2, "S")
    if caller_info and caller_info.source then
        local caller_module = caller_info.source:match("@?([^/\\]+)%.lua$")
        if caller_module then
            _G.dependencies = _G.dependencies or {}
            _G.dependencies[module_name] = _G.dependencies[module_name] or {}
            if lume.find(_G.dependencies[module_name], caller_module) == nil then
                table.insert(_G.dependencies[module_name], caller_module)
            end
        end
    end
    return require(module_name)
end

lurker.postswap = function(f)
    local module = f:gsub("%.lua$", "")

    if (module == "resources") then
        package.loaded[module].load()
    end

    if (_G.dependencies[module] == nil) then return end

    for i = 1, #_G.dependencies[module] do
        local dep = _G.dependencies[module][i]
        -- Skip entry-point files (like main.lua) that are not loaded as modules
        -- and are not accessible via love.filesystem.getInfo (lurker.resetfile crashes).
        -- These don't need hotswapping: live references use package.loaded["game"] directly.
        if package.loaded[dep] ~= nil then
            lurker.hotswapfile(dep .. ".lua")
        end
        if (dep == "resources") then
            package.loaded[dep].load()
        end
    end

    -- After hotswapping game (and its dependents like main.lua), re-initialize
    -- game state. When game.lua is reloaded, `local state = {}` resets to an
    -- empty table, so any input/update call before init() would crash on nil.
    if module == "game" then
        package.loaded["game"].init()
    end
end
