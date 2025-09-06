local engine = {}

---Generates a unique identifier
---@return number
function engine.generate_uid()
    _G.uid_counter = _G.uid_counter + 1
    return _G.uid_counter
end

return engine
