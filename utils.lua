function class(className, super)
    local cls = {
        __cname = className,
        __super = super
    }
    
    if super then
        setmetatable(cls, {__index = super})
    end
    
    cls.__index = cls
    
    function cls.new(...)
        local instance = setmetatable({}, cls)
        if instance.constructor then
            instance:constructor(...)
        end
        return instance
    end
    
    return cls
end

function OrderedMap(modules)
    local result = {}

    for i, path in ipairs(modules) do
        local module = require(path)

        -- Используем последнюю часть пути как имя
        -- "ui.widgets" -> "widgets", "board" -> "board"
        local name = path:match("([^%.]+)$")

        result[i] = module
        result[name] = module
    end

    return result
end