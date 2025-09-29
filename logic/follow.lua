local Follow = {}

function Follow.to(game, elem_uid, target_transform, dt)
    local Math = game.engine.Math
    local ElementsManager = game.logic.ElementsManager

    local smoothness = 0.01
    local elem_transform = ElementsManager.get_transform(game, elem_uid)
    ElementsManager.set_transform(game, elem_uid, {
        x = Math.lerp(target_transform.x, elem_transform.x, smoothness ^ dt),
        y = Math.lerp(target_transform.y, elem_transform.y, smoothness ^ dt),
        width = Math.lerp(target_transform.width, elem_transform.width, smoothness ^ dt),
        height = Math.lerp(target_transform.height, elem_transform.height, smoothness ^ dt),
        z_index = Math.lerp(target_transform.z_index, elem_transform.z_index, smoothness ^ dt)
    })
end

return Follow
