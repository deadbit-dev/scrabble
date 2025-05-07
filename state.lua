---@class Cell
---@field multiplier number

---@class Element
---@field letter string
---@field points number

---@class Board
---@field cells Cell[][]
---@field elements (Element|nil)[][]

---@class State
---@field board Board
local state = {
    board = {
        cells = {},
        elements = {}
    }
}

return state
