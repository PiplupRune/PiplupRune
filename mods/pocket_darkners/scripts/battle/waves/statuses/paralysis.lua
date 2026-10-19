local Basic, super = Class(Wave)

function Basic:init()
    super.init(self)
    self.time = 2
    self.spawn_soul = false
    self.has_arena = false   
    local snd = Assets.playSound("paralyze")
    local attackers = self:getAttackers() or {}
    local names = {}
    for _, enemy in ipairs(attackers) do
        enemy:shake()
        table.insert(names, enemy.name)
    end
    self.timer:after(snd:getDuration(), function()
        local full_message = ""
        
        if #names == 1 then
            full_message = "[noskip]* " .. names[1] .. " is paralyzed and can't move!"
        elseif #names == 2 then
            full_message = "[noskip]* " .. names[1] .. " and " .. names[2] .. " are paralyzed and can't move!"
        else
            local all_but_last = table.concat(names, ", ", 1, #names - 1)
            full_message = "[noskip]* " .. all_but_last .. ", and " .. names[#names] .. " are paralyzed and can't move!"
        end
        
        Game.battle:infoText(full_message)
    end)
end 

function Basic:onStart()
    Game.battle:undarken()
end

return Basic
