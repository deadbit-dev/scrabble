local utils = {}

---Calculates a percentage of the smaller side of the window
---@param width number Width of the window
---@param height number Height of the window
---@param percent number Percentage to calculate
---@return number Size of the smaller side
function utils.get_percent_size(width, height, percent)
    if (width > height) then
        return height * 0.8 * percent
    else
        return width * percent
    end
end

local _cyrillic_lower = {
    ["А"]="а",["Б"]="б",["В"]="в",["Г"]="г",["Д"]="д",["Е"]="е",["Ё"]="ё",
    ["Ж"]="ж",["З"]="з",["И"]="и",["Й"]="й",["К"]="к",["Л"]="л",["М"]="м",
    ["Н"]="н",["О"]="о",["П"]="п",["Р"]="р",["С"]="с",["Т"]="т",["У"]="у",
    ["Ф"]="ф",["Х"]="х",["Ц"]="ц",["Ч"]="ч",["Ш"]="ш",["Щ"]="щ",["Ъ"]="ъ",
    ["Ы"]="ы",["Ь"]="ь",["Э"]="э",["Ю"]="ю",["Я"]="я",
}

local _cyrillic_upper = {}
for up, lo in pairs(_cyrillic_lower) do _cyrillic_upper[lo] = up end

-- Split UTF-8 string into array of characters
function utils.utf8_chars(s)
    local chars = {}
    local i = 1
    while i <= #s do
        local byte = s:byte(i)
        local char_len = byte < 0x80 and 1 or byte < 0xE0 and 2 or byte < 0xF0 and 3 or 4
        table.insert(chars, s:sub(i, i + char_len - 1))
        i = i + char_len
    end
    return chars
end

-- UTF-8 aware lowercase (handles ASCII + Cyrillic)
function utils.utf8_lower(s)
    return (s:gsub("[\xD0\xD1][\x80-\xBF]", function(c)
        return _cyrillic_lower[c] or c
    end):gsub("%a", string.lower))
end

-- UTF-8 aware uppercase (handles ASCII + Cyrillic)
function utils.utf8_upper(s)
    return (s:gsub("[\xD0\xD1][\x80-\xBF]", function(c)
        return _cyrillic_upper[c] or c
    end):gsub("%a", string.upper))
end

function utils.lerp(a, b, t)
    return a + (b - a) * t
end

---@param value number
---@param min_value number
---@param max_value number
---@return number
function utils.clamp(value, min_value, max_value)
    return math.max(math.min(value, max_value), min_value)
end

---Calculates distance between two points
---@param pos1 Pos
---@param pos2 Pos
---@return number
function utils.get_distance(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    return math.sqrt(dx * dx + dy * dy)
end

---@param transform Transform
---@param point Pos
---@return boolean
function utils.is_point_in_transform_bounds(transform, point)
    return point.x >= transform.x
        and point.x <= transform.x + transform.width
        and point.y >= transform.y
        and point.y <= transform.y + transform.height
end

function utils.aabb(x1, y1, w1, h1, x2, y2, w2, h2)
    w2, h2 = w2 or 0, h2 or 0
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

--if something is within bounds of an ellipse
function utils.pie(x, y, a, b, x0, y0)
    return utils.aabb(x - a, y - b, 2 * a, 2 * b, x0, y0) and
        (((x - x0) * (x - x0) / (a * a)) + ((y - y0) * (y - y0) / (b * b)) <= 1)
end

return utils
