-- NOTE: hotreload
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
    print('[imported]: ' .. module_name)
    return require(module_name)
end

---@diagnostic disable-next-line: duplicate-set-field
lurker.postswap = function(f)
    local module = f:gsub("%.lua$", "")

    if (module == "resources") then
        package.loaded[module].load()
    end

    if (_G.dependencies[module] == nil) then return end

    for i = 1, #_G.dependencies[module] do
        local dep = _G.dependencies[module][i]
        print('[updated dependence]: ' .. dep)
        -- TODO: need store dependencies with .lua instead of just name
        lurker.hotswapfile(dep .. ".lua")
        if (dep == "resources") then
            package.loaded[dep].load()
        end
    end
end
