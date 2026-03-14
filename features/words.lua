local words = {}

local dict  = import("dict")
local log   = import("log")
local utils = import("utils")

---@enum Direction
Direction = {
    HORIZONTAL = 1,
    VERTICAL = 2
}


---@param conf Config
---@param state State
---@param x number
---@param y number
---@param dir Pos
---@return table
local function find_empty_pos(conf, state, x, y, dir)
    local prev_x, prev_y = x, y
    while x >= 1 and x < conf.field.size and y >= 1 and y < conf.field.size do
        if state.board.elem_uids[y][x] == nil then
            return { x = prev_x, y = prev_y }
        end

        prev_x, prev_y = x, y
        x, y = x + dir.x, y + dir.y
    end

    return { x = prev_x, y = prev_y }
end

---@param conf Config
---@param state State
---@param x number
---@param y number
---@param dir Direction
---@return { start_pos: Pos, end_pos: Pos }
local function find_word(conf, state, x, y, dir)
    if dir == Direction.HORIZONTAL then
        local lp = find_empty_pos(conf, state, x, y, { x = -1, y = 0 })
        local rp = find_empty_pos(conf, state, x, y, { x = 1, y = 0 })
        return { start_pos = lp, end_pos = rp }
    end

    if dir == Direction.VERTICAL then
        local tp = find_empty_pos(conf, state, x, y, { x = 0, y = -1 })
        local bp = find_empty_pos(conf, state, x, y, { x = 0, y = 1 })
        return { start_pos = tp, end_pos = bp }
    end

    log.warn("Wrond direction " .. dir)

    return { start_pos = { x = -1, y = -1 }, end_pos = { x = -1, y = -1 } }
end

---@param conf Config
---@param state State
---@param resources table
---@param x number
---@param y number
---@return {start_pos: Pos, end_pos: Pos }[]
function words.search(conf, state, resources, x, y)
    local lang = conf.language or "en"
    local trie = resources.dict[lang]
    local found_words = {}
    local h_word = find_word(conf, state, x, y, Direction.HORIZONTAL)
    local h_word_len = h_word.end_pos.x - h_word.start_pos.x + 1
    if h_word_len >= conf.min_word_length then
        local word = words.get_word_by_pos_range(state, h_word.start_pos, h_word.end_pos)
        if words.is_valid(trie, word) then
            table.insert(found_words, h_word)
        end
    end

    local v_word = find_word(conf, state, x, y, Direction.VERTICAL)
    local v_word_len = v_word.end_pos.y - v_word.start_pos.y + 1
    if v_word_len >= conf.min_word_length then
        local word = words.get_word_by_pos_range(state, v_word.start_pos, v_word.end_pos)
        if words.is_valid(trie, word) then
            table.insert(found_words, v_word)
        end
    end

    return found_words
end

---@param trie table
---@param word string
---@return boolean
function words.is_valid(trie, word)
    return dict.word_exists(trie, word)
end

---@param state State
---@param start_pos Pos
---@param end_pos Pos
---@return string
function words.get_word_by_pos_range(state, start_pos, end_pos)
    local word = ""
    local x, y = start_pos.x, start_pos.y

    local dx = end_pos.x - start_pos.x
    local dy = end_pos.y - start_pos.y

    local step_x = dx == 0 and 0 or (dx > 0 and 1 or -1)
    local step_y = dy == 0 and 0 or (dy > 0 and 1 or -1)

    local elem_uid = state.board.elem_uids[y][x]
    local elem_data = state.elements[elem_uid]
    word = word .. elem_data.letter

    while x ~= end_pos.x or y ~= end_pos.y do
        x = x + step_x
        y = y + step_y

        elem_uid = state.board.elem_uids[y][x]
        elem_data = state.elements[elem_uid]
        word = word .. elem_data.letter
    end

    return utils.utf8_lower(word)
end

---@param conf Config
---@param state State
---@param word_range {start_pos: Pos, end_pos: Pos}
---@return number
function words.calculate_score(conf, state, word_range)
    local start_pos = word_range.start_pos
    local end_pos   = word_range.end_pos
    local dx = end_pos.x == start_pos.x and 0 or 1
    local dy = end_pos.y == start_pos.y and 0 or 1

    local total = 0
    local x, y = start_pos.x, start_pos.y
    repeat
        local elem_uid = state.board.elem_uids[y][x]
        if elem_uid then
            local multiplier = conf.field.multipliers[y][x] or 1
            total = total + state.elements[elem_uid].points * multiplier
        end
        x = x + dx
        y = y + dy
    until x == end_pos.x + dx and y == end_pos.y + dy

    return total
end

return words
