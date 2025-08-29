---Generates a unique identifier
---@return number
function generate_uid()
    _G.uid_counter = _G.uid_counter + 1
    return _G.uid_counter
end

---Clears the state
---@param state State
function clearState(state)
    state.cells = {}
    state.elements = {}
    state.pool = {}
    state.board = {
        transform = {
            x = 0,
            y = 0,
            width = 0,
            height = 0
        },
        cell_uids = {},
        elem_uids = {}
    }
    state.hands = {}
    state.players = {}
    state.transitions = {}
    state.timers = {}
    state.current_player_uid = nil
    state.drag = nil
end

---Calculates a percentage of the smaller side of the window
---@param width number Width of the window
---@param height number Height of the window
---@param percent number Percentage to calculate
---@return number Size of the smaller side
function getPercentSize(width, height, percent)
    if (width > height) then
        return height * 0.8 * percent
    else
        return width * percent
    end
end
