local dependencies = {
    -- Таблица зависимостей: { модуль = { зависимые_модули } }
    deps = {},
    -- Таблица обратных зависимостей: { зависимый_модуль = { модули_которые_его_используют } }
    reverse_deps = {}
}

-- Регистрирует зависимость между модулями
-- @param module string Имя модуля, который зависит от других
-- @param deps table|string Таблица имен модулей или одно имя модуля, от которых зависит module
function dependencies.register(module, deps)
    if type(deps) == "string" then
        deps = { deps }
    end

    -- Сохраняем прямые зависимости
    dependencies.deps[module] = deps

    -- Обновляем обратные зависимости
    for _, dep in ipairs(deps) do
        dependencies.reverse_deps[dep] = dependencies.reverse_deps[dep] or {}
        table.insert(dependencies.reverse_deps[dep], module)
    end
end

-- Получает все модули, которые зависят от указанного модуля
-- @param module string Имя модуля
-- @return table Таблица имен модулей, которые зависят от указанного
function dependencies.get_dependents(module)
    return dependencies.reverse_deps[module] or {}
end

-- Перезагружает модуль и все модули, которые от него зависят
-- @param module string Имя модуля для перезагрузки
function dependencies.reload_module_and_dependents(module)
    -- Сначала перезагружаем сам модуль
    package.loaded[module] = nil
    require(module)

    -- Затем перезагружаем все зависимые модули
    local dependents = dependencies.get_dependents(module)
    for _, dep in ipairs(dependents) do
        package.loaded[dep] = nil
        require(dep)
    end
end

-- Важно: возвращаем саму таблицу dependencies, а не true
return dependencies
