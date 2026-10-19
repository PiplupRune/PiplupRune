local Basic, super = Class(Wave)

function Basic:init()
    super.init(self)
    self.time = 0.4
    self.spawn_soul = false
    self.has_arena = false 
    local attackers = self:getAttackers() or {}
    local names = {}
    for _, enemy in ipairs(attackers) do
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
    Game.battle:infoText(full_message)
end 

function Basic:onStart()
    Game.battle:undarken()
end

return Basic
