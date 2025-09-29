local Input = require("modules.input")
local Tween = require("modules.tween")

local Game = class("Game")

function Game:constructor(data, systems)
    self.data = data
    self.systems = systems

    _G.uid_counter = 0
end

function Game:generate_uid()
    _G.uid_counter = _G.uid_counter + 1
    return _G.uid_counter
end

function Game:update(dt)
    Input.update(dt)
    
    for _, system in ipairs(self.systems) do
        if (system["update"]) then
            system.update(self, dt)
        end
    end

    Tween.update(dt)

    for _, system in ipairs(self.systems) do
        if (system["late_update"]) then
            system.late_update(dt)
        end
    end

    Input.clear()
end

function Game:render()
    love.graphics.clear(self.conf.colors.background)

    for _, system in ipairs(self.systems) do
        if (system["draw"]) then
            system.draw()
        end
    end
end

return Game