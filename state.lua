---@class Cell
---@field uid number
---@field multiplier number

---@class Transform
---@field x number
---@field y number
---@field width number
---@field height number
---@field z_index number

---@class Element
---@field uid number
---@field transform Transform
---@field space SpaceInfo
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
---@field element_uid number
---@field tween_uid number
---@field onComplete function|nil

---@class Tween
---@field uid number
---@field duration number
---@field subject table
---@field target table
---@field easing function
---@field clock number
---@field initial table|nil
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

---@class State
---@field cells {[number]: Cell}
---@field elements {[number]: Element}
---@field pool number[]
---@field board Board
---@field hands {[number]: Hand}
---@field players {[number]: Player}
---@field transitions Transition[]
---@field tweens {[number]: Tween}
---@field drag_element_uid number|nil
---@field drag_original_space SpaceInfo|nil
---@field selected_element_uid number|nil
---@field last_click_time number
---@field timers table[]
---@field current_player_uid number|nil
---@field input InputState

local state = {
    cells = {},
    elements = {},
    pool = {},
    board = {
        transform = { x = 0, y = 0, width = 0, height = 0 },
        cell_uids = {},
        elem_uids = {}
    },
    hands = {},
    players = {},
    transitions = {},
    tweens = {},
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
    drag_element_uid = nil,
    drag_original_space = nil,
    click_element_uid = nil,
    last_click_time = 0,
}

---Clears the state
function state:clear()
    self.cells = {}
    self.elements = {}
    self.pool = {}
    self.board = {
        transform = {
            x = 0,
            y = 0,
            width = 0,
            height = 0,
            z_index = 0
        },
        cell_uids = {},
        elem_uids = {}
    }
    self.hands = {}
    self.players = {}
    self.transitions = {}
    self.tweens = {}
    self.timers = {}
    self.current_player_uid = nil
    self.drag_element_uid = nil
    self.drag_original_space = nil
    self.click_element_uid = nil
    self.last_click_time = 0
end

return state
