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
function transition.create(game, elem_uid, duration, easing, from, to, onComplete)
    local conf = game.conf
    local state = game.state

    local element = element.get(game, elem_uid)
    table.insert(state.transitions, {
        uid = elem_uid,
        tween = tween.new(
            duration,
            transition.getWorldTransformFromSpaceInfo(game, from, element),
            transition.getWorldTransformFromSpaceInfo(game, to, element),
            easing
        ),
        onComplete = onComplete,
    })

    -- TODO: remove and add to pool ??

    -- if from.type == "hand" then
    --     hand.removeElem(game, from.data.hand_uid, from.data.index)
    -- end
    -- if from.type == "board" then
    --     board.removeElement(game, from.data.x, from.data.y, elem_uid)
    -- end

    -- if to.type == "hand" then
    --     hand.addElem(game, to.data.hand_uid, to.data.index, elem_uid)
    -- end
    -- if to.type == "board" then
    --     board.addElement(game, to.data.x, to.data.y, elem_uid)
    -- end

    return #state.transitions
end

---Removes a transition
---@param state State
---@param idx number
function transition.remove(state, idx)
    table.remove(state.transitions, idx)
end

---Updates the transitions
---@param game Game
---@param dt number
function transition.update(game, dt)
    local state = game.state
    for i = #state.transitions, 1, -1 do
        local trans = state.transitions[i]
        if trans.tween ~= nil then
            local isDone = trans.tween:update(dt)
            local elem = element.get(game, trans.uid)
            if elem then
                elem.transform = {
                    x = trans.tween.subject.position.x,
                    y = trans.tween.subject.position.y,
                    width = trans.tween.subject.width,
                    height = trans.tween.subject.height,
                }
                elem.z_index = 1
            end
            if isDone then
                if trans.onComplete then
                    trans.onComplete()
                end
                transition.remove(state, i)
            end
        end
    end
end

---Calculates world transform from space info
---@param game Game
---@param spaceInfo SpaceInfo
---@param element Element
---@return table undefined
function transition.getWorldTransformFromSpaceInfo(game, spaceInfo, element)
    local conf = game.conf
    local state = game.state

    -- NOTE: screen is default space info, nothing converts
    local worldTransform = {
        position = { x = spaceInfo.data.x, y = spaceInfo.data.y },
        width = conf.text.screen.base_size,
        height = conf.text.screen.base_size,
        space = "screen"
    }

    if (spaceInfo.type == "board") then
        local dimensions = board.getDimensions(conf)
        worldTransform = board.getWorldTransformInBoardSpace(conf, spaceInfo.data.x, spaceInfo.data.y)
    elseif (spaceInfo.type == "hand") then
        local dimensions = hand.getDimensions(conf)
        worldTransform = hand.getWorldTransformInHandSpace(game, spaceInfo.data.hand_uid, spaceInfo.data.index)
    end

    return worldTransform
end

function transition.poolToHand(game, elem_uid, hand_uid, toIndex, onComplete)
    transition.create(game, elem_uid, 0.7, tween.easing.inOutCubic,
        -- NOTE: from right of the screen - from pool
        {
            type = "screen",
            data = {
                x = love.graphics.getWidth(),
                y = love.graphics.getHeight() / 2
            }
        },
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

function transition.handToBoard(game, hand_uid, elem_uid, fromIndex, toX, toY, onComplete)
    -- local elem_uid = hand.getElemUID(game, hand_uid, fromIndex)
    transition.create(game, elem_uid, 0.7, tween.easing.inOutCubic,
        {
            type = "hand",
            data = {
                hand_uid = hand_uid,
                index = fromIndex
            }
        },
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

return transition