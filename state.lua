---@class Cell
---@field uid number
---@field multiplier number

---@class Element
---@field uid number
---@field letter string
---@field points number

---@class Board
---@field cell_uids (number|nil)[][]
---@field elem_uids (number|nil)[][]

---@class Hand
---@field uid number
---@field elem_uids (number|nil)[]

---@class Player
---@field uid number
---@field hand Hand
---@field points number

---@alias SpaceType
---| "hand"
---| "board"
---| "screen"

---@class IndexData
---@field index number

---@class XYData
---@field x number
---@field y number

---@class FromInfo
---@field type SpaceType
---@field data IndexData|XYData

---@class ToInfo
---@field type SpaceType
---@field data IndexData|XYData

---@class Transition
---@field elem_uid number
---@field from FromInfo
---@field to ToInfo
---@field progress number
---@field duration number
---@field easing string

---@class DragState
---@field uid number
---@field x number
---@field y number
---@field offset_x number
---@field offset_y number

---@class State
---@field cells {[number]: Cell}
---@field elements {[number]: Element}
---@field pool number[]
---@field board Board
---@field hands {[number]: Hand}
---@field players {[number]: Player}
---@field transitions Transition[]
---@field drag DragState|nil
local state = {
    cells = {},
    elements = {},
    pool = {},
    board = {
        cell_uids = {},
        elem_uids = {}
    },
    hands = {},
    players = {},
    transitions = {},
    drag = nil
}

return state
