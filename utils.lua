---Generates a unique identifier
---@return number
function generate_uid()
    _G.uid_counter = _G.uid_counter + 1
    return _G.uid_counter
end

---Creates a cell
---@param state State
---@param multiplier number
---@return number
function createCell(state, multiplier)
    local cell_uid = generate_uid()
    state.cells[cell_uid] = { uid = cell_uid, multiplier = multiplier }
    return cell_uid
end

---@param state State
---@param uid number
---@return Cell
function getCell(state, uid)
    return state.cells[uid]
end

---Removes a cell
---@param state State
---@param cell_uid number
function removeCell(state, cell_uid)
    state.cells[cell_uid] = nil
end

---Creates an element
---@param state State
---@param letter string
---@param points number
---@return number
function createElement(state, letter, points)
    local elem_uid = generate_uid()
    state.elements[elem_uid] = { uid = elem_uid, letter = letter, points = points }
    return elem_uid
end

---@param state State
---@param uid number
---@return Element
function getElem(state, uid)
    return state.elements[uid]
end

---Removes an element
---@param state State
---@param elem_uid number
function removeElement(state, elem_uid)
    state.elements[elem_uid] = nil
end

---Clears the state
---@param state State
function clearState(state)
    state.cells = {}
    state.elements = {}
    state.pool = {}
    state.board = {
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