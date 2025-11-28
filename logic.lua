local logic = {}

---@enum Direction
Direction = {
    HORIZONTAL = 1,
    VERTICAL = 2
}


---@param conf Config
---@param state State
---@param x number
---@param y number
---@param dir table
---@return table
local function find_empty_pos(conf, state, x, y, dir)
    local prev_x, prev_y = x, y
    while x >= 1 and x < conf.field.size and y >= 1 and y < conf.field.size do
        if state.board.elem_uids[x][y] == nil then
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
---@return table
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

    return {}
end

---@param conf Config
---@param state State
---@param x number
---@param y number
---@return table[]
function logic.recognize_words(conf, state, x, y)
    local words = {}
    local h_word = find_word(conf, state, x, y, Direction.HORIZONTAL)
    local h_word_len = h_word.end_pos.x - h_word.start_pos.x + 1
    print("HORIZONTAL", h_word_len)
    if h_word_len > 0 then table.insert(words, h_word) end
    local v_word = find_word(conf, state, x, y, Direction.VERTICAL)
    local v_word_len = v_word.end_pos.y - v_word.start_pos.y + 1
    print("VERTICAL", v_word_len)
    if v_word_len > 0 then table.insert(words, v_word) end
    return words
end

---@param word string
---@return boolean
function logic.is_valid_word(word)
    return true
end

return logic
