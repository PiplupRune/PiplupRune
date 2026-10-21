local MultiPara, super = Class(Wave)

function MultiPara:init()
    super.init(self)
    self.time = -1

    local enemies = Game.battle.current_para_enemies or {}
    local names = {}
    
    Assets.playSound("paralyze")
    
    for _, enemy in ipairs(enemies) do
        enemy:flash(nil, nil, nil, 100, ColorUtils.hexToRGB("FFF0B2"))
        enemy:expandRipple(ColorUtils.hexToRGB("FFF0B2"), 2, {70, 50}, 3)
        table.insert(names, enemy.name)
    end
    
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
end

function MultiPara:onStart()
    Game.battle:undarken()
end

return MultiPara
