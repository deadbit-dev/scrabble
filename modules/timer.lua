local timer = {}

---Creates a timer
---@param game Game
---@param duration number
---@param callback function
---@return table
function timer.delay(game, duration, callback)
    local timer = game.engine.cron.after(duration, callback)
    table.insert(game.state.timers, timer)
    return timer
end

---Updates the timers
---@param game Game
---@param dt number
function timer.update(game, dt)
    local state = game.state
    for i = #state.timers, 1, -1 do
        local timer = state.timers[i]
        if timer:update(dt) then
            table.remove(state.timers, i)
        end
    end
end

return timer
