-- Модуль управления пространствами (board, hand, screen)
local space = {}

local board = require("modules.board")
local hand = require("modules.hand")
local element = require("modules.element")

---Перемещает элемент из одного пространства в другое (обновляет данные)
---@param state State
---@param elem_uid number
---@param from_space SpaceInfo
---@param to_space SpaceInfo
function space.update_data(state, elem_uid, from_space, to_space)
    -- Remove element from source space
    if from_space.type == SpaceType.BOARD then
        board.remove_element(state, from_space.data.x, from_space.data.y)
    elseif from_space.type == SpaceType.HAND then
        hand.remove_element(state, from_space.data.hand_uid, from_space.data.index)
    end
    -- Note: screen space doesn't need removal as it's not tracked in state

    -- Add element to target space
    if to_space.type == SpaceType.BOARD then
        board.add_element(state, to_space.data.x, to_space.data.y, elem_uid)
    elseif to_space.type == SpaceType.HAND then
        hand.add_element(state, to_space.data.hand_uid, to_space.data.index, elem_uid)
    end
    -- Note: screen space doesn't need addition as it's not tracked in state
end

---Получает мировой трансформ в screen space
---@param conf Config
---@param x number
---@param y number
---@return Transform
function space.get_world_transform_in_screen_space(conf, x, y)
    return {
        x = x,
        y = y,
        width = conf.text.screen.base_size,
        height = conf.text.screen.base_size,
        z_index = 10
    }
end

---Вычисляет мировой трансформ из space info
---@param state State
---@param conf Config
---@param space_info SpaceInfo
---@return Transform
function space.get_world_transform_from_space_info(state, conf, space_info)
    -- NOTE: screen is default space info, nothing converts
    local world_transform = space.get_world_transform_in_screen_space(conf, space_info.data.x, space_info.data.y)

    if (space_info.type == SpaceType.BOARD) then
        world_transform = board.get_world_transform_in_board_space(conf, space_info.data.x, space_info.data.y)
    elseif (space_info.type == SpaceType.HAND) then
        world_transform = hand.get_world_transform_in_hand_space(state, conf, space_info.data.hand_uid,
            space_info.data.index)
    end

    return world_transform
end

---Получает тип пространства по позиции
---@param state State
---@param conf Config
---@param x number
---@param y number
---@return SpaceType
function space.get_space_type_by_position(state, conf, x, y)
    -- NOTE: Check if point is in board area
    if space.is_in_board_area(conf, x, y) then
        return SpaceType.BOARD
    end

    -- NOTE: Check if point is in hand area
    if space.is_in_hand_area(state, conf, x, y) then
        return SpaceType.HAND
    end

    -- NOTE: If not in any specific area, it's in screen space
    return SpaceType.SCREEN
end

---Проверяет, находится ли точка в области поля
---@param conf Config
---@param x number
---@param y number
---@return boolean
function space.is_in_board_area(conf, x, y)
    local board_transform = board.get_world_transform(conf)
    return x >= board_transform.x and x <= board_transform.x + board_transform.width and
        y >= board_transform.y and y <= board_transform.y + board_transform.height
end

---Проверяет, находится ли точка в области руки
---@param state State
---@param conf Config
---@param x number
---@param y number
---@return boolean
function space.is_in_hand_area(state, conf, x, y)
    local hand_transform = hand.get_world_transform(state, conf)
    return x >= hand_transform.x and x <= hand_transform.x + hand_transform.width and
        y >= hand_transform.y and y <= hand_transform.y + hand_transform.height
end

---Получает позицию на поле по мировой позиции
---@param conf Config
---@param x number
---@param y number
---@return {x: number, y: number}|nil
function space.get_board_pos_by_world_pos(conf, x, y)
    -- Check if point is within board boundaries
    if not space.is_in_board_area(conf, x, y) then
        return nil
    end

    local layout = board.get_layout(conf)
    local transform = board.get_world_transform(conf)

    -- Calculate relative position within board area
    local relX = x - (transform.x + layout.fieldGaps.left)
    local relY = y - (transform.y + layout.fieldGaps.top)

    -- Calculate cell size including gap
    local cell_size_with_gap = layout.cellSize + layout.cellGap

    -- Calculate board coordinates (1-based) using round for better snapping
    local boardX = math.floor(relX / cell_size_with_gap) + 1
    local boardY = math.floor(relY / cell_size_with_gap) + 1

    -- Clamp coordinates to valid range (1 to field size)
    boardX = math.max(1, math.min(conf.field.size, boardX))
    boardY = math.max(1, math.min(conf.field.size, boardY))

    return { x = boardX, y = boardY }
end

---Устанавливает пространство элемента и его трансформ
---@param state State
---@param conf Config
---@param elem_uid number
---@param space_info SpaceInfo
function space.set_space(state, conf, elem_uid, space_info)
    local current_space = element.get_space(state, elem_uid)

    element.set_space(state, elem_uid, space_info)
    element.set_transform(state, elem_uid, space.get_world_transform_from_space_info(state, conf, space_info))

    space.update_data(state, elem_uid, current_space, space_info)
end

---Создает screen space info
---@param x number
---@param y number
---@return SpaceInfo
function space.create_screen_space(x, y)
    return {
        type = SpaceType.SCREEN,
        data = {
            x = x,
            y = y
        }
    }
end

---Создает board space info
---@param x number
---@param y number
---@return SpaceInfo
function space.create_board_space(x, y)
    return {
        type = SpaceType.BOARD,
        data = {
            x = x,
            y = y
        }
    }
end

---Создает hand space info
---@param hand_uid number
---@param index number
---@return SpaceInfo
function space.create_hand_space(hand_uid, index)
    return {
        type = SpaceType.HAND,
        data = {
            hand_uid = hand_uid,
            index = index
        }
    }
end

---Проверяет равенство двух space infos
---@param space1 SpaceInfo
---@param space2 SpaceInfo
---@return boolean
function space.equals(space1, space2)
    if space1.type ~= space2.type then
        return false
    end

    if space1.type == SpaceType.SCREEN or space1.type == SpaceType.BOARD then
        return space1.data.x == space2.data.x and space1.data.y == space2.data.y
    elseif space1.type == SpaceType.HAND then
        return space1.data.hand_uid == space2.data.hand_uid and space1.data.index == space2.data.index
    end

    return false
end

return space
