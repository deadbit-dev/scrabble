local cron = import("cron")

local timer = {}

---Creates a timer
---@param state State
---@param duration number
---@param callback function
---@return table
function timer.delay(state, duration, callback)
    local timer = cron.after(duration, callback)
    table.insert(state.timers, timer)
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