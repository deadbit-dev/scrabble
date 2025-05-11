local utils = {}

---@param state State
---@param uid number
---@return Cell
function utils.getCell(state, uid)
    return state.cells[uid]
end

---@param state State
---@param uid number
---@return Element
function utils.getElem(state, uid)
    return state.elements[uid]
end

---@param state State
---@param x number
---@param y number
---@return Cell
function utils.getBoardCell(state, x, y)
    return utils.getCell(state, state.board.cell_uids[x][y])
end

---@param state State
---@param x number
---@param y number
---@return Element
function utils.getBoardElem(state, x, y)
    return utils.getElem(state, state.board.elem_uids[x][y])
end

return utils
