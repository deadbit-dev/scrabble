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
---@field hand_uid number
---@field points number

---@alias SpaceType
---| "hand"
---| "board"
---| "screen"

---@class XYData
---@field x number
---@field y number

---@class SlotData
---@field hand_uid number
---@field index number

---@class SpaceInfo
---@field type SpaceType
---@field data XYData|SlotData

---@class Transition
---@field uid number
---@field tween table
---@field onComplete function|nil

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
---@field timers table[]
---@field current_player_uid number|nil

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
    drag = nil,
    timers = {},
    current_player_uid = nil
}

return state
