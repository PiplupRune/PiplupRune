local Battle, super = HookSystem.hookScript(Battle)

function Battle:init(...)
    super.init(self, ...)
    self.processing_statuses = false
end

function Battle:onEnemyDialogueState()
    if self.processing_statuses then
        super.onEnemyDialogueState(self)
        return
    end
    self:setState("STATUS")
end

function Battle:onStateChange(old, new, reason)
    if new == "STATUS" then
        self:onStatusGiveTime(old)
        self:checkEndWaves(old, new, reason)
        self.encounter:onStateChange(old, new, reason)
        return
    end
    super.onStateChange(self, old, new, reason)
end

function Battle:update()
    super.update(self)
    if self.state == "STATUS" then
        self:updateStatus()
    end
end

function Battle:onStatusGiveTime(old_state)
    self:darken()
    self:hideTargets()
    self.current_selecting = 0
    self.battle_ui:clearEncounterText()

    local text_lines = {}
    local poisoned = {}
    local badly_poisoned = {}
    
    for _, enemy in ipairs(self.enemies) do
        if enemy.active then
            if enemy.poison then
                table.insert(poisoned, enemy)
            elseif enemy.toxic then 
                table.insert(badly_poisoned, enemy)
            end
        end 
    end
    
    if #poisoned > 0 then
        for i = 1, #poisoned do
            poisoned[i]:takePoisonDamage(false)
            table.insert(text_lines, "* " .. poisoned[i].name .. " was hurt by the poison!")
        end
    end

    if #badly_poisoned > 0 then
        for i = 1, #badly_poisoned do
            badly_poisoned[i]:takePoisonDamage(true) 
            table.insert(text_lines, "* " .. badly_poisoned[i].name .. " was badly hurt by the poison!")
        end
    end
    
    if #text_lines == 0 then
        self:exitStatusState()
        return
    end

    local full_message = "[noskip]" .. table.concat(text_lines, "\n")
    self:battleText(full_message, function()
        local active_enemies = self:getActiveEnemies()
        if #active_enemies == 0 then
            self:onVictory()
            return true
        end
        self:exitStatusState()
        return true
    end)
end

function Battle:exitStatusState()
    self.processing_statuses = true
    self:setState("ENEMYDIALOGUE")
    self.processing_statuses = false
end

function Battle:updateStatus() return end 

return Battle
