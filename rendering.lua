local log = import("log")
local resources = import("resources")
local board = import("board")
local utils = import("utils")

local rendering = {}

---Draws the game board and all its elements
---@param game Game
function rendering.draw(game)
    local conf = game.conf
    local state = game.state

    --- IDEA: calculate dimensions and other render-dependendent params once in draw and keep them in game state, other will be it read from there

    love.graphics.clear(conf.colors.background)

    rendering.drawBoard(conf, state)
    rendering.drawHand(conf, state)
    rendering.drawTransitions(conf, state)
end

function rendering.drawBoard(conf, state)
    local dimensions = board.getBoardDimensions(conf)
    rendering.drawBoardBg(conf, dimensions)

    -- NOTE: draw cells and their contents
    for i = 1, conf.field.size do
        for j = 1, conf.field.size do
            -- NOTE: calculate position with gaps
            local pos = board.getWorldPosInBoardSpace(j, i, dimensions)
            local x, y = pos.x, pos.y

            -- TODO: if has element in this cell, then do not draw that cell

            rendering.drawCell(conf, x, y, dimensions.cellSize, board.getBoardCellUID(state, i, j))

            local element = board.getBoardElemUID(state, i, j)
            if element then
                rendering.drawElem(conf, x, y, element, dimensions.cellSize)
            end
        end
    end
end

---Draws the board background
---@param conf Config
---@param dimensions table containing board dimensions and positions
function rendering.drawBoardBg(conf, dimensions)
    if (not resources.textures.field) then
        return
    end

    love.graphics.setColor(conf.colors.black)
    love.graphics.draw(resources.textures.field, dimensions.startX, dimensions.startY, 0,
        dimensions.boardWidth / resources.textures.field:getWidth(),
        dimensions.boardHeight / resources.textures.field:getHeight())
end

---Draws a single cell with its shadow and multiplier
---@param conf Config
---@param x number X position of the cell
---@param y number Y position of the cell
---@param cellSize number Size of the cell
---@param cell Cell
function rendering.drawCell(conf, x, y, cellSize, cell)
    -- NOTE: draw cell
    if resources.textures.cell then
        love.graphics.setColor(conf.field.cell_colors.multiplier[cell.multiplier])
        love.graphics.draw(resources.textures.cell, x, y, 0, cellSize / resources.textures.cell:getWidth(),
            cellSize / resources.textures.cell:getHeight())
    end

    -- NOTE: draw cell shadow
    if resources.textures.cell_shadow then
        love.graphics.setColor(conf.field.cell_colors.shadow)
        love.graphics.draw(resources.textures.cell_shadow, x, y, 0,
            cellSize / resources.textures.cell_shadow:getWidth(),
            cellSize / resources.textures.cell_shadow:getHeight())
    end

    -- NOTE: draw multiplier if greater than 1
    if cell.multiplier > 1 then
        -- NOTE: draw cross
        if resources.textures.cross then
            local cross_scale = (cellSize * conf.text.letter_scale_factor * 0.4) /
                math.max(resources.textures.cross:getWidth(), resources.textures.cross:getHeight())

            local posX = (x + cellSize / 2) - cross_scale * resources.textures.cross:getWidth() / 2 - cellSize * 0.2
            local posY = (y + cellSize / 2) - cross_scale * resources.textures.cross:getHeight() / 2
            love.graphics.setColor(conf.text.colors.multiplier[cell.multiplier])
            love.graphics.draw(resources.textures.cross, posX, posY, 0, cross_scale, cross_scale)
        end

        -- NOTE: draw multiplier number
        love.graphics.setColor(conf.text.colors.multiplier[cell.multiplier])

        if (resources.fonts.default) then
            love.graphics.setFont(resources.fonts.default)
        end

        local font = love.graphics.getFont()
        local multiplierText = tostring(cell.multiplier)
        local multiplierWidth = font:getWidth(multiplierText)
        local multiplierHeight = font:getHeight()
        local multiplier_scale = (cellSize * conf.text.letter_scale_factor) / multiplierHeight

        love.graphics.push()
        love.graphics.scale(multiplier_scale)
        local scaledX = (x + (cellSize - multiplierWidth * multiplier_scale) / 2 + cellSize * 0.25 - cellSize * conf.text.offset) /
            multiplier_scale
        local scaledY = (y + (cellSize - multiplierHeight * multiplier_scale) / 2 - cellSize * conf.text.offset + cellSize * 0.1) /
            multiplier_scale
        love.graphics.print(multiplierText, scaledX, scaledY)
        love.graphics.pop()
    end
end

---Draws a game element
---@param conf Config
---@param x number X position of the element
---@param y number Y position of the element
---@param element table Element data containing letter and points
---@param scale number Scale factor for the element
function rendering.drawElem(conf, x, y, element, scale)
    if not element then return end

    -- NOTE: Calculate element dimensions based on scale
    local elementSize = scale
    local texture_scaleX = 1
    local texture_scaleY = 1
    local elementWidth = elementSize
    local elementHeight = elementSize

    if resources.textures.element then
        texture_scaleX = elementSize / resources.textures.element:getWidth()
        texture_scaleY = elementSize / resources.textures.element:getHeight()
        elementWidth = resources.textures.element:getWidth() * texture_scaleX
        elementHeight = resources.textures.element:getHeight() * texture_scaleY
    end

    -- NOTE: Draw element texture
    love.graphics.setColor(conf.colors.white)
    if (resources.textures.element) then
        love.graphics.draw(resources.textures.element, x, y, 0, texture_scaleX, texture_scaleY)
    end

    -- NOTE: Setup font for text rendering
    love.graphics.setColor(conf.text.colors.element)
    if (resources.fonts.default) then
        love.graphics.setFont(resources.fonts.default)
    end

    local font = love.graphics.getFont()
    local textWidth = font:getWidth(element.letter)
    local textHeight = font:getHeight()

    -- NOTE: Calculate letter scale and position
    local letter_scale = (elementWidth * conf.text.screen.letter_scale_factor) / textHeight
    local letter_scaledX = ((elementWidth - textWidth * letter_scale) / 2 - elementWidth * conf.text.screen.offset) /
        letter_scale
    local letter_scaledY = ((elementHeight - textHeight * letter_scale) / 2 - elementHeight * conf.text.screen.offset) /
        letter_scale

    -- NOTE: Draw letter
    love.graphics.push()
    love.graphics.scale(letter_scale)
    love.graphics.print(element.letter, x / letter_scale + letter_scaledX, y / letter_scale + letter_scaledY)
    love.graphics.pop()

    -- NOTE: Calculate points scale and position
    local point_scale = letter_scale * conf.text.screen.point_scale_factor
    local pointsText = tostring(element.points)
    local pointsWidth = font:getWidth(pointsText)
    local pointsHeight = font:getHeight()
    local points_scaledX = (elementWidth - pointsWidth * point_scale - elementWidth * conf.text.screen.offset) /
        point_scale
    local points_scaledY = (elementHeight - pointsHeight * point_scale - elementHeight * conf.text.screen.offset) /
        point_scale

    -- NOTE: Draw points
    love.graphics.push()
    love.graphics.scale(point_scale)
    love.graphics.print(element.points, x / point_scale + points_scaledX, y / point_scale + points_scaledY)
    love.graphics.pop()
end

---@param conf Config
---@param state State
function rendering.drawHand(conf, state)
    local dimensions = utils.getHandDimensions(conf)
    rendering.drawHandBg(conf, dimensions)
    local hand = state.hands[state.players[state.current_player_uid].hand_uid]

    if #hand.elem_uids == 0 then return end

    -- NOTE: Calculate element size based on hand dimensions (adaptive)
    local elementSize = math.min(dimensions.width, dimensions.height) * 0.5 -- 50% of smaller dimension
    local adaptiveSpacing = elementSize * conf.hand.element_spacing_ratio
    local totalWidth = #hand.elem_uids * elementSize + (#hand.elem_uids - 1) * adaptiveSpacing

    -- NOTE: Apply internal margin from hand background
    local availableWidth = dimensions.width
    local availableHeight = dimensions.height

    -- NOTE: Calculate starting position to center all elements within available hand area
    local startX = dimensions.x + (availableWidth - totalWidth) / 2
    local centerY = dimensions.y + availableHeight / 2

    for i, elem_uid in ipairs(hand.elem_uids) do
        local element = board.getElem(state, elem_uid)

        -- NOTE: Calculate position for each element
        local x = startX + (i - 1) * (elementSize + adaptiveSpacing)
        local y = centerY - elementSize / 2

        rendering.drawElem(conf, x, y, element, elementSize)
    end
end

function rendering.drawHandBg(conf, dimensions)
    if (not resources.textures.hand) then
        return
    end

    love.graphics.setColor(conf.colors.black)
    love.graphics.draw(resources.textures.hand, dimensions.x, dimensions.y, 0,
        dimensions.width / resources.textures.hand:getWidth(),
        dimensions.height / resources.textures.hand:getHeight())
end

---Draws all transitions
---@param conf Config
---@param state State
function rendering.drawTransitions(conf, state)
    for _, transition in ipairs(state.transitions) do
        rendering.drawTransition(conf, state, transition)
    end
end

---Draws a transition
---@param conf Config
---@param state State
---@param transition Transition
function rendering.drawTransition(conf, state, transition)
    local element = board.getElem(state, transition.uid)
    local transform = transition.tween.subject
    local position = transform.position
    local scale = transform.scale

    rendering.drawElem(conf, position.x, position.y, element, scale)
end

return rendering
