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
---@field space SpaceInfo
---@field transform Transform
---@field world_transform Transform
---@field letter string
---@field points number

---@class Board
---@field transform Transform
---@field cell_uids (number)[][]
---@field elem_uids (number|nil)[][]

---@class Hand
---@field uid number
---@field transform Transform
---@field elem_uids (number)[]
---@field size number

---@class Player
---@field uid number
---@field hand_uid number
---@field points number

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
---@field target_space SpaceInfo
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

---@class Pos
---@field x number
---@field y number

---@class MouseState
---@field x number
---@field y number
---@field dx number
---@field dy number
---@field buttons {[number]: ButtonState}
---@field press_time number
---@field last_click_time number
---@field last_click_pos Pos|nil
---@field press_pos Pos|nil
---@field click_pos Pos|nil
---@field is_drag boolean
---@field is_click boolean
---@field is_double_click boolean

---@class KeyboardState
---@field buttons {[string]: ButtonState}

---@class InputState
---@field mouse MouseState
---@field keyboard KeyboardState

---@class DragState
---@field active boolean
---@field element_uid number|nil
---@field original_space SpaceInfo|nil

---@class State
---@field is_restart boolean
---@field cells {[number]: Cell}
---@field elements {[number]: Element}
---@field pool number[]
---@field board Board
---@field hands {[number]: Hand}
---@field players {[number]: Player}
---@field transitions Transition[]
---@field tweens {[number]: Tween}
---@field drag DragState
---@field selected_element_uid number|nil
---@field current_player_uid number|nil
---@field input InputState

---@enum SpaceType
SpaceType = {
    HAND = 1,
    BOARD = 2,
    SCREEN = 3
}

---@enum Action
Action = {
    KEY_PRESSED = 1,
    KEY_RELEASED = 2,
    MOUSE_PRESSED = 3,
    MOUSE_MOVED = 4,
    MOUSE_RELEASED = 5
}

local state = {}

function state:init()
    self.is_restart = false
    self.cells = {}
    self.elements = {}
    self.pool = {}
    self.board = {
        transform = { x = 0, y = 0, width = 0, height = 0, z_index = 0 },
        cell_uids = {},
        elem_uids = {}
    }
    self.hands = {}
    self.players = {}
    self.transitions = {}
    self.tweens = {}
    self.current_player_uid = nil
    self.selected_element_uid = nil
    self.drag = {
        active = false,
        element_uid = nil,
        original_space = nil
    }
    self.input = {
        mouse = {
            x = 0,
            y = 0,
            dx = 0,
            dy = 0,
            buttons = {},
            press_time = 0,
            last_click_time = 0,
            last_click_pos = nil,
            click_pos = nil,
            is_drag = false,
            is_click = false,
            is_double_click = false
        },
        keyboard = {
            buttons = {}
        }
    }
end

return state
