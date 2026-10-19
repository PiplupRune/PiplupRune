local Basic, super = Class(Wave)

function Basic:init()
    super.init(self)
    self.time = 0.4
    self.spawn_soul = false
    self.has_arena = false 
    local attacker = self:getAttackers()[1]
    local name = attacker:getName()
    Game.battle:infoText(full_message)
end 

function Basic:onStart()
    Game.battle:undarken()
end

return Basic
