local Basic, super = Class(Wave)

function Basic:init()
    super.init(self)
    self.time = 0.6
    self.spawn_soul = false
    self.has_arena = false 
    local names = {}
    for _, enemy in ipairs(Game.battle:getActiveEnemies()) do
        if enemy.frozen then
            table.insert(names, enemy.name)
        end
    end

    -- Format the text string based on how many enemies are frozen solid
    local full_message = ""
    if #names == 1 then
        full_message = "[noskip]* " .. names[1] .. " was frozen solid and couldn't move!"
    elseif #names == 2 then
        full_message = "[noskip]* " .. names[1] .. " and " .. names[2] .. " are frozen solid and can't move!"
    else
        local all_but_last = table.concat(names, ", ", 1, #names - 1)
        full_message = "[noskip]* " .. all_but_last .. ", and " .. names[#names] .. " are frozen solid and can't move!"
    end

    Game.battle:infoText(full_message)
end 

function Basic:onStart()
    Game.battle:undarken()
end

return Basic
