---@class Cell
---@field uid number
---@field multiplier number

---@class Transform
---@field x number
---@field y number
---@field width number
---@field height number

---@class Element
---@field uid number
---@field transform Transform
---@field space SpaceInfo
---@field z_index number
---@field letter string
---@field points number

---@class Board
---@field transform Transform
---@field cell_uids (number)[][]
---@field elem_uids (number|nil)[][]

---@class Hand
---@field uid number
---@field transform Transform
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

---@class ButtonState
---@field pressed boolean
---@field released boolean

---@class MouseState
---@field x number
---@field y number
---@field dx number
---@field dy number
---@field buttons {[number]: ButtonState}

---@class KeyboardState
---@field buttons {[string]: ButtonState}

---@class InputState
---@field mouse MouseState
---@field keyboard KeyboardState

---@class DragState
---@field uid number
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
---@field input InputState

local state = {
    cells = {},
    elements = {},
    pool = {},
    board = {
        transform = { x = 0, y = 0, width = 0, height = 0, scale = 1 },
        cell_uids = {},
        elem_uids = {}
    },
    hands = {},
    players = {},
    transitions = {},
    timers = {},
    current_player_uid = nil,
    input = {
        mouse = {
            x = 0,
            y = 0,
            dx = 0,
            dy = 0,
            buttons = {}
        },
        keyboard = {
            buttons = {}
        }
    },
    drag = nil
}

return state
