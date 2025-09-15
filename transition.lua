local log = import("log")
local tween = import("tween")
local space = import("space")
local element = import("element")

local transition = {}

---Creates a transition
---@param game Game
---@param elem_uid number
---@param duration number
---@param easing function
---@param to SpaceInfo
---@param onComplete function|nil
---@return number
function transition.to(game, elem_uid, duration, easing, to, onComplete)
    local state = game.state
    local element_data = element.get(game, elem_uid)

    -- Создаем обертку для коллбэка, которая удалит переход
    local transition_index = #state.transitions + 1
    local wrappedCallback = function()
        -- Удаляем переход
        transition.remove(state, transition_index)
        -- Вызываем оригинальный коллбэк
        if onComplete then
            onComplete()
        end
    end

    -- Создаем твин и получаем его UID
    local tween_uid = tween.create(
        game,
        duration,
        element_data.transform,
        space.getWorldTransformFromSpaceInfo(game, to),
        easing,
        wrappedCallback
    )

    table.insert(state.transitions, {
        element_uid = elem_uid,
        tween_uid = tween_uid,
        onComplete = onComplete,
    })

    return transition_index
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
        if trans.tween_uid ~= nil then
            local target_space = element.get_space(game, trans.element_uid)
            local target_transform = space.getWorldTransformFromSpaceInfo(game, target_space)
            tween.updateTarget(game, trans.tween_uid, target_transform)
        end
    end
end

function transition.poolToHand(game, elem_uid, hand_uid, toIndex, onComplete)
    transition.screenToHand(game, elem_uid, love.graphics.getWidth(), love.graphics.getHeight() / 2, hand_uid, toIndex,
        onComplete)
end

function transition.screenToHand(game, elem_uid, fromX, fromY, hand_uid, toIndex, onComplete)
    -- NOTE: from right of the screen - from pool
    space.set_space(game, elem_uid, space.createScreenSpace(fromX, fromY))

    transition.to(game, elem_uid, 0.7, tween.easing.inOutCubic,
        space.createHandSpace(hand_uid, toIndex),
        onComplete
    )
end

function transition.handToBoard(game, hand_uid, elem_uid, fromIndex, toX, toY, onComplete)
    space.set_space(game, elem_uid, space.createHandSpace(hand_uid, fromIndex))
    transition.to(game, elem_uid, 0.7, tween.easing.inOutCubic,
        space.createBoardSpace(toX, toY),
        onComplete
    )
end

return transition
