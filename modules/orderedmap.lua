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
