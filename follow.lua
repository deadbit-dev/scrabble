local follow = {}

local utils = import("utils")

function follow.to(state, elem_uid, target_transform, dt)
    local smoothness = 0.01
    local element_data = state.elements[elem_uid]
    element_data.transform = {
        x = utils.lerp(target_transform.x, element_data.transform.x, smoothness ^ dt),
        y = utils.lerp(target_transform.y, element_data.transform.y, smoothness ^ dt),
        width = utils.lerp(target_transform.width, element_data.transform.width, smoothness ^ dt),
        height = utils.lerp(target_transform.height, element_data.transform.height, smoothness ^ dt),
        z_index = utils.lerp(target_transform.z_index, element_data.transform.z_index, smoothness ^ dt)
    }
end

return follow
