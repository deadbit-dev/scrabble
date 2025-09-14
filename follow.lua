local utils = import("utils")
local element = import("element")

local follow = {}

function follow.to(game, elem_uid, target_transform, dt)
    local smoothness = 0.01
    local elem_transform = element.get_transform(game, elem_uid)
    element.set_transform(game, elem_uid, {
        x = utils.lerp(target_transform.x, elem_transform.x, smoothness ^ dt),
        y = utils.lerp(target_transform.y, elem_transform.y, smoothness ^ dt),
        width = utils.lerp(target_transform.width, elem_transform.width, smoothness ^ dt),
        height = utils.lerp(target_transform.height, elem_transform.height, smoothness ^ dt),
        z_index = utils.lerp(target_transform.z_index, elem_transform.z_index, smoothness ^ dt)
    })
end

return follow
