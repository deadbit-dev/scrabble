local log = {}

---Base logging function
---@param message string The message to log
function log.log(message)
    print(message)
end

---Logs an informational message
---@param message string The message to log
function log.info(message)
    print("[INFO][" .. os.date("%H:%M:%S") .. "] " .. message)
end

---Logs a warning message
---@param message string The message to log
function log.warn(message)
    print("[WARN][" .. os.date("%H:%M:%S") .. "] " .. message)
end

---Logs an error message
---@param message string The message to log
function log.error(message)
    print("[ERROR][" .. os.date("%H:%M:%S") .. "] " .. message, debug.traceback())
end

return log
