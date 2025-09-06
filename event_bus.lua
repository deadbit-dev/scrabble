local event_bus = {}

-- Internal storage for event listeners
local listeners = {}

---Subscribes to an event type
---@param event_id string The type of event to listen for
---@param callback function Function to call when event is emitted
---@param priority number|nil Optional priority (higher numbers called first, default 0)
---@return function Unsubscribe function
function event_bus.subscribe(event_id, callback, priority)
    if not listeners[event_id] then
        listeners[event_id] = {}
    end

    local listener = {
        callback = callback,
        priority = priority or 0
    }

    table.insert(listeners[event_id], listener)

    -- Sort by priority (higher priority first)
    table.sort(listeners[event_id], function(a, b)
        return a.priority > b.priority
    end)

    -- Return unsubscribe function
    return function()
        event_bus.unsubscribe(event_id, callback)
    end
end

---Unsubscribes from an event type
---@param event_id string The type of event
---@param callback function The callback function to remove
function event_bus.unsubscribe(event_id, callback)
    if not listeners[event_id] then
        return
    end

    for i = #listeners[event_id], 1, -1 do
        if listeners[event_id][i].callback == callback then
            table.remove(listeners[event_id], i)
        end
    end

    -- Clean up empty event ids
    if #listeners[event_id] == 0 then
        listeners[event_id] = nil
    end
end

---Emits an event to all subscribers
---@param event_id string The type of event to emit
---@param data any Optional data to pass to listeners
---@param source string|nil Optional source identifier for debugging
function event_bus.emit(event_id, data, source)
    if not listeners[event_id] then
        return
    end

    -- Call all listeners
    for _, listener in ipairs(listeners[event_id]) do
        local success, error_msg = pcall(listener.callback, data, event_id, source)
        if not success then
            print("Error in event listener for " .. event_id .. ": " .. tostring(error_msg))
        end
    end
end

---Clears all listeners
function event_bus.clear()
    listeners = {}
end

return event_bus
