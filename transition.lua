local resources = import("resources")
local tween = import("tween")
local board = import("board")
local hand = import("hand")
local element = import("element")
local timer = import("timer")

local transition = {}

---Creates a transition
---@param state State
---@param elem_uid number
---@param duration number
---@param easing function
---@param from SpaceInfo
---@param to SpaceInfo
---@param onComplete function|nil
---@return number
function transition.create(conf, state, elem_uid, duration, easing, from, to, onComplete)
    local element = element.get(state, elem_uid)
    table.insert(state.transitions, {
        uid = elem_uid,
        tween = tween.new(
            duration,
            transition.getWorldParamsFromSpaceInfo(conf, state, from, element),
            transition.getWorldParamsFromSpaceInfo(conf, state, to, element),
            easing
        ),
        onComplete = onComplete,
    })

    return #state.transitions
end

---Removes a transition
---@param state State
---@param idx number
function transition.remove(state, idx)
    table.remove(state.transitions, idx)
end

function transition.update(state, dt)
    for i = #state.transitions, 1, -1 do
        local trans = state.transitions[i]
        if trans.tween ~= nil then
            if trans.tween:update(dt) then
                if trans.onComplete then
                    trans.onComplete()
                end
                transition.remove(state, i)
            end
        end
    end
end

---@param conf Config
---@param state State
---@param transition Transition
function transition.draw(conf, state, transition)
    local elem = element.get(state, transition.uid)
    local transform = transition.tween.subject
    local position = transform.position
    local scale = transform.scale

    element.draw(conf, position.x, position.y, elem, scale)
end

---Calculates world transform from space info
---@param conf Config
---@param spaceInfo SpaceInfo
---@param element Element
---@return table undefined
function transition.getWorldParamsFromSpaceInfo(conf, state, spaceInfo, element)
    -- NOTE: screen is default space info, nothing converts
    local worldParams = {
        position = { x = spaceInfo.data.x, y = spaceInfo.data.y },
        scale = conf.text.screen.base_size
    }

    if (spaceInfo.type == "board") then
        local dimensions = board.getDimensions(conf)
        worldParams.position = board.getWorldPosInBoardSpace(conf, spaceInfo.data.x, spaceInfo.data.y)
        worldParams.scale = dimensions.cellSize
    elseif (spaceInfo.type == "hand") then
        local dimensions = hand.getDimensions(conf)
        worldParams.position = hand.getWorldPosInHandSpace(conf, state, spaceInfo.data.hand_uid, spaceInfo.data.index)
        worldParams.scale = math.min(dimensions.width, dimensions.height) * 0.5
    end

    return worldParams
end

function transition.poolToHand(game, elem_uid, hand_uid, toIndex, onComplete)
    transition.create(game.conf, game.state, elem_uid, 0.7, tween.easing.inOutCubic,
        -- NOTE: from right of the screen - from pool
        {
            type = "screen",
            data = {
                x = love.graphics.getWidth(),
                y = love.graphics.getHeight() / 2
            }
        },

        -- NOTE: to bottom of the screen - to hand
        {
            type = "hand",
            data = {
                hand_uid = hand_uid,
                index = toIndex
            }
        },
        onComplete

    )
end

function transition.handToBoard(game, hand_uid, fromIndex, toX, toY, onComplete)
    local conf = game.conf
    local state = game.state

    local elem_uid = hand.getElemUID(state, hand_uid, fromIndex)
    transition.create(conf, state, elem_uid, 0.7, tween.easing.inOutCubic,
        -- NOTE: from bottom of the screen - from hand
        -- TODO: hand space
        {
            type = "hand",
            data = {
                hand_uid = hand_uid,
                index = fromIndex
            }
        },

        -- NOTE: to left bottom corner of the board - to board
        {
            type = "board",
            data = {
                x = toX,
                y = toY
            }
        },
        onComplete
    )
end

function testTransition(game)
    local elem_uid = element.create(game.state, "A", 1)
    local hand_uid = game.state.players[game.state.current_player_uid].hand_uid
    transition.poolToHand(game, elem_uid, hand_uid, 1, function()
        timer.delay(game.state, 0.25, function()
            transition.handToBoard(game, hand_uid, 1, 1, 15, function()
                element.remove(game.state, elem_uid)
            end)
        end)
    end)
end

return transition