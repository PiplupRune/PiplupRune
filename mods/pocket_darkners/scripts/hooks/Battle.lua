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

function Battle:areEnemiesFine()
    local not_fine = {}
    for _, i in ipairs(self:getActiveEnemies()) do 
        if i.paralyzed or i.frozen or i.affect_waves then 
            table.insert(not_fine, i) 
        end 
    end 
    return #not_fine == 0 
end 

function Battle:doStatusesMultiple()
    local active_enemies = self:getActiveEnemies()
    
    local flinched = {}
    local frozen = {}
    local para = {}
    local fine_waves = {}
    
    for _, enemy in ipairs(active_enemies) do
        if enemy.affect_waves then
            table.insert(flinched, enemy)
        elseif enemy.frozen then
            table.insert(frozen, enemy)
        elseif enemy.paralyzed and MathUtils.randomInt(1, 4) == 1 then
            table.insert(para, enemy)
        else
            if enemy.selected_wave then
                table.insert(fine_waves, enemy.selected_wave)
            end
        end
    end
    
    local wave_sequence = {}
    if #flinched > 0 then
        table.insert(wave_sequence, "statuses/multi_flinch")
        self.current_flinched_enemies = flinched
    end
    
    if #frozen > 0 then
        table.insert(wave_sequence, "statuses/multi_frozen")
        self.current_frozen_enemies = frozen
    end
    
    if #para > 0 then
        table.insert(wave_sequence, "statuses/multi_paralysis")
        self.current_para_enemies = para
    end

    for _, fine_wave in ipairs(fine_waves) do
        table.insert(wave_sequence, fine_wave)
    end

    if #wave_sequence == 0 then
        if self.state_reason then
            wave_sequence = type(self.state_reason) == "table" and Utils.copy(self.state_reason) or {self.state_reason}
        else
            wave_sequence = Utils.copy(self.encounter:getNextWaves())
        end
    end

    self:setWaves(wave_sequence)
end

function Battle:onStatusState()
    if #self:getActiveEnemies() > 1 then  
        self:doStatusesMultiple()
        return 
    end 
    
    local enemy = self:getActiveEnemies()[1]
    if enemy then
        if enemy.affect_waves then 
            self:setWaves({"statuses/hidden"})
            enemy.affect_waves = false 
        elseif enemy.frozen then 
            self:setWaves({"statuses/frozen"})
        elseif enemy.paralyzed and (love.math.random(1, 4) == 1) then
            self:setWaves({"statuses/paralysis"})
        else
            if self.state_reason then
                self:setWaves(self.state_reason)
            else
                self:setWaves(self.encounter:getNextWaves())
            end
        end
    end
end

function Battle:onDefendingBeginState()
    if self.state_reason == "CUTSCENE" then
        self:setState("DEFENDING")
        return
    end

    self:darken()
    self:hideTargets()
    self.current_selecting = 0
    self.battle_ui:clearEncounterText()
     
    local proceed = self:areEnemiesFine()

    if not proceed then 
        self:onStatusState() 
    else
        if self.state_reason then
            self:setWaves(self.state_reason)
            local enemy_found = false
            for i, enemy in ipairs(self.enemies) do
                if TableUtils.contains(enemy.waves, self.state_reason[1]) then
                    enemy.selected_wave = self.state_reason[1]
                    enemy_found = true
                end
            end
            if not enemy_found then
                TableUtils.pick(self.enemies).selected_wave = self.state_reason[1]
            end
        else
            self:setWaves(self.encounter:getNextWaves())
        end
    end

    if self.arena then
        self.arena:remove()
    end

    local soul_x, soul_y, soul_offset_x, soul_offset_y
    local arena_x, arena_y, arena_w, arena_h, arena_shape
    local arena_rotation = 0
    local has_arena = true
    local spawn_soul = true

    for _, wave in ipairs(self.waves) do
        soul_x = wave.soul_start_x or soul_x
        soul_y = wave.soul_start_y or soul_y
        soul_offset_x = wave.soul_offset_x or soul_offset_x
        soul_offset_y = wave.soul_offset_y or soul_offset_y
        arena_x = wave.arena_x or arena_x
        arena_y = wave.arena_y or arena_y
        arena_w = wave.arena_width and math.max(wave.arena_width, arena_w or 0) or arena_w
        arena_h = wave.arena_height and math.max(wave.arena_height, arena_h or 0) or arena_h
        arena_rotation = wave.arena_rotation or arena_rotation
        if wave.arena_shape then
            arena_shape = wave.arena_shape
        end
        if not wave.has_arena then
            has_arena = false
        end
        if not wave.spawn_soul then
            spawn_soul = false
        end
    end

    if #self.waves > 0 and (self.waves[1].id == "statuses/multi_flinch" or self.waves[1].id == "statuses/multi_frozen" or self.waves[1].id == "statuses/multi_paralysis" or self.waves[1].id == "statuses/hidden" or self.waves[1].id == "statuses/frozen" or self.waves[1].id == "statuses/paralysis") then
        has_arena = false
        spawn_soul = false
    end

    local center_x, center_y
    if has_arena then
        if not arena_shape then
            arena_w, arena_h = arena_w or 142, arena_h or 142
            arena_shape = { { 0, 0 }, { arena_w, 0 }, { arena_w, arena_h }, { 0, arena_h } }
        end

        local arena = Arena(arena_x or SCREEN_WIDTH / 2, arena_y or (SCREEN_HEIGHT - 155) / 2 + 10, arena_shape)
        arena.rotation = arena_rotation
        arena.layer = BATTLE_LAYERS["arena"]

        self.arena = arena
        self:addChild(arena)
        center_x, center_y = arena:getCenter()
    else
        center_x, center_y = SCREEN_WIDTH / 2, (SCREEN_HEIGHT - 155) / 2 + 10
    end

    if spawn_soul then
        soul_x = soul_x or (soul_offset_x and center_x + soul_offset_x)
        soul_y = soul_y or (soul_offset_y and center_y + soul_offset_y)
        self:spawnSoul(soul_x or center_x, soul_y or center_y)
    end


    for _, wave in ipairs(Game.battle.waves) do
        if wave:onArenaEnter() then
            wave.active = true
        end
    end

    self.defending_begin_timer = 0
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
            if enemy.poison then table.insert(poisoned, enemy)
            elseif enemy.toxic then table.insert(badly_poisoned, enemy) end
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
