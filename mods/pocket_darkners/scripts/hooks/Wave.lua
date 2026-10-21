local Wave, super = HookSystem.hookScript(Wave)

function Wave:init()
    super.init(self)
    
    self.skip = false 
    self.targets_that_flinched = {} 
    local flinched = {}
    local para = {}
    local frozen = {}
    
    for _, p in ipairs(self:getAttackers()) do 
        if p.paralyzed then 
            if MathUtils.randomInt(1, 4) == 1 then
                table.insert(para, p)
            end
        elseif p.frozen then 
            table.insert(frozen, p)
        elseif p.affect_waves then  
            table.insert(flinched, p)
        end 
    end 
    
    if #flinched >= 1 then 
       self:flinch(flinched)
       self.targets_that_flinched = flinched -- Exact same spelling
    end 
    if #para >= 1 then 
       self:paralysisText(para)
    end 
    if #frozen >= 1 then 
       self:frozenText(frozen)
    end 
end 

function Wave:onEnd(...)
    super.onEnd(self, ...)
    for _, f in ipairs(self.targets_that_flinched) do -- Exact same spelling
        if f then 
            f.affect_waves = false 
        end 
    end 
end 

function Wave:update()
    super.update(self)
    if self.skip then 
        for _, s in ipairs(self.bullets) do 
            for _, attacker in ipairs(self:getAttackers()) do
                if (attacker.paralyzed or attacker.frozen or attacker.affect_waves) and s.attacker == attacker then
                    s:remove()
                end
            end
        end 
    end
end 

function Wave:flinch(enemies)
    local names = {}
    for _, enemy in ipairs(enemies) do 
        enemy:expandRipple(ColorUtils.hexToRGB("EFC55B"), 2, {70, 50}, 3)
        table.insert(names, enemy.name)
    end 
    
    local full_message = ""
    if #names == 1 then
        full_message = "[noskip]* " .. names[1] .. " flinched and couldn't move!"
    elseif #names == 2 then
        full_message = "[noskip]* " .. names[1] .. " and " .. names[2] .. " flinched and couldn't move!"
    else
        local all_but_last = table.concat(names, ", ", 1, #names - 1)
        full_message = "[noskip]* " .. all_but_last .. ", and " .. names[#names] .. " flinched and couldn't move!"
    end
    
    self:doText(full_message)
    self.skip = true 
end 

function Wave:paralysisText(enemies) 
    local names = {} 
    local snd = Assets.playSound("paralyze")
    for _, enemy in ipairs(enemies) do 
        enemy:flash(nil, nil, nil, 100, ColorUtils.hexToRGB("FFF0B2"))
        enemy:expandRipple(ColorUtils.hexToRGB("FFF0B2"), 2, {70, 50}, 3)
        table.insert(names, enemy.name)
    end 
    self.timer:after(snd:getDuration() - 0.2, function()
        local full_message = ""   
        if #names == 1 then
            full_message = "[noskip]* " .. names[1] .. " is paralyzed and can't move!"
        elseif #names == 2 then
            full_message = "[noskip]* " .. names[1] .. " and " .. names[2] .. " are paralyzed and can't move!"
        else
            local all_but_last = table.concat(names, ", ", 1, #names - 1)
            full_message = "[noskip]* " .. all_but_last .. ", and " .. names[#names] .. " are paralyzed and can't move!"
        end
        self:doText(full_message)
    end)
    self.skip = true 
end 

function Wave:frozenText(enemies) 
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
    
    self:doText(full_message)
    self.skip = true 
end 

function Wave:doText(str)
    Game.battle:infoText(str)
    self.timer:afterCond(function() 
        return Input.pressed("confirm")
    end, function()
        if #self:getAttackers() == 1 then self:setFinished(true) end 
        Game.battle:infoText("")
    end)
end 

return Wave
