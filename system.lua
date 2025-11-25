local system = {}

---@return number
function system.generate_uid()
    _G.uid_counter = _G.uid_counter + 1
    return _G.uid_counter
end

return system
