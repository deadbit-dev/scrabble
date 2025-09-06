local utils = {}

---Calculates a percentage of the smaller side of the window
---@param width number Width of the window
---@param height number Height of the window
---@param percent number Percentage to calculate
---@return number Size of the smaller side
function utils.getPercentSize(width, height, percent)
    if (width > height) then
        return height * 0.8 * percent
    else
        return width * percent
    end
end

return utils
