local Engine = {}

function Engine.init(game)
    _G.uid_counter = 0
    game.resources.load()

    game.engine.Input.init(game)

    for _, module in ipairs(game.logic) do
        if (module["init"]) then
            module.init(game)
        end
    end

    Engine.set_cursor(game.resources.imageData.cursor)
end

function Engine.update(game, dt)
    -- game.engine.lurker.update()

    game.engine.Input.update(game, dt)

    for _, module in ipairs(game.logic) do
        if (module["update"]) then
            module.update(game, dt)
        end
    end

    game.engine.Input.clear(game)
end

function Engine.draw(game)
    love.graphics.clear(game.conf.colors.background)

    for _, module in ipairs(game.logic) do
        if (module["draw"]) then
            module.draw(game)
        end
    end
end

---Restarts the game
---@param game Game
function Engine.restart(game)
    ---@diagnostic disable-next-line: undefined-field
    game.state:clear()
    Engine.init(game)
end

return Engine
