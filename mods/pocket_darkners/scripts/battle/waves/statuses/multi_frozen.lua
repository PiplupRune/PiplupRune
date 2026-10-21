local MultiFrozen, super = Class(Wave)

function MultiFrozen:init()
    super.init(self)
    self.time = -1
    
    local enemies = Game.battle.current_frozen_enemies or {}
    local names = {}
    
    for _, enemy in ipairs(enemies) do
        table.insert(names, enemy.name)
    end
    
    local full_message = ""
    if #names == 1 then
        full_message = "[noskip]* " .. names[1] .. " was frozen solid and can't move!"
    elseif #names == 2 then
        full_message = "[noskip]* " .. names[1] .. " and " .. names[2] .. " are frozen solid and can't move!"
    else
        local all_but_last = table.concat(names, ", ", 1, #names - 1)
        full_message = "[noskip]* " .. all_but_last .. ", and " .. names[#names] .. " are frozen solid and can't move!"
    end
    
    Game.battle:infoText(full_message)
end

function MultiFrozen:onStart()
    Game.battle:undarken()
end

return MultiFrozen
