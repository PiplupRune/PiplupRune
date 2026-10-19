local EnemyBattler, super = HookSystem.hookScript(EnemyBattler)

function EnemyBattler:init(...)
    super.init(self, ...)
    self.affect_waves = false
    
    -- Status Trackers
    self.poison = false
    self.toxic = false
    self.paralyzed = false
    self.frozen = false 
    self.toxic_count = 0 -- Keeps track of how many turns Toxic has been active (itll never go away :3)
end 

function EnemyBattler:hurt(amount, ...)
    super.hurt(self, amount, ...)
end 

-- function EnemyBattler:getNextWaves()
--     if self.affect_waves then
--         self.affect_waves = false  
--         return {"statuses/hidden"}
--     elseif self.frozen then 
--         return {"statuses/frozen"} 
--     elseif self.paralyzed then 
--         if love.math.random(1, 4) == 1 then 
--             return {"statuses/paralysis"}
--         else
--             return super.getNextWaves(self)
--         end 
--     else 
--         return super.getNextWaves(self)
--     end 
-- end

function EnemyBattler:hasNonVolatileStatus()
    return self.poison or self.toxic or self.paralyzed or self.frozen 
end

--- Attempts to apply a specific status condition to the enemy battler.
---@param status string # The status ID to apply. Current options: `flinch`, `poison`, `paralysis` and `toxic`.
---@param msg string? # Optional custom text message string to pass to the statusMessage method.
function EnemyBattler:giveStatus(status, msg)

    if status == "flinch" then 
    if love.math.random(1, 10) <= 3 then 
            self:statusMessage("msg", msg or "flinched")
            self:debuffEffect(ColorUtils.hexToRGB("EFC55B"))
            self.affect_waves = true 
            return true
    end
        return false
    end

    -- KEEP THIS BLOCK OF CODE **AFTER** EVERY VOLATILE STATUS - REMINDER FOR FLUFFY (...when i say volatile i mean thingies that can be stacked)
    if self:hasNonVolatileStatus() then 
        return true, "* It had no effect."
    end

    if status == "poison" then  
        self:statusMessage("msg", msg or "poisoned")
        self.poison = true 
        local mask = ColorMaskFX(ColorUtils.hexToRGB("B868A0"))
        mask.amount = 0 
        self:addFX(mask)
        local snd = Assets.playSound("poison", 2)
        local tween = snd:getDuration() / 2
        Game.battle.timer:tween(tween, mask, {amount = 1}, "linear", function()
            Game.battle.timer:tween(tween, mask, {amount = 0})
        end)
        return true
    
    elseif status == "frostbite" then 
    self:statusMessage("msg", msg or "frostbitten")
    self.frozen = true 
    local mask = ColorMaskFX(ColorUtils.hexToRGB("739BD0"))
    mask.amount = 0 
    self:addFX(mask)
    Game.battle.timer:tween(0.25, mask, {amount = 0.7}, "linear", function()
        Game.battle.timer:tween(0.25, mask, {amount = 0})
    end)
    
    local spawned_positions = {}
    local mx = self.width / 4
    local my = self.height / 4
    
    local num_flakes = MathUtils.randomInt(3, 4)
    
    for i = 1, num_flakes do 
        local delay = (i - 1) * 0.15 
        
        Game.battle.timer:after(delay, function()
            local x, y
            local valid_position = false
            local safety_counter = 0
            
            while not valid_position and safety_counter < 50 do
                safety_counter = safety_counter + 1
                local base_x, base_y = self:getRelativePos(self.width/2, self.height/2)
                x = base_x + MathUtils.randomInt(-self.width/3, self.width/3)
                y = base_y + MathUtils.randomInt(-self.height/3, self.height/3)
                valid_position = true
                for _, pos in ipairs(spawned_positions) do
                    local distance_x = math.abs(x - pos.x)
                    local distance_y = math.abs(y - pos.y)
                    if distance_x < mx or distance_y < my then
                        valid_position = false
                        break
                    end
                end
            end
            table.insert(spawned_positions, {x = x, y = y})
            
            local ice = Sprite("effects/icespell/snowflake", x, y)
            ice:setOrigin(0.5, 0.5) 
            ice:setScale(0)
            ice.alpha = 0
            
            Game.battle:addChild(ice)
            local max_scale = MathUtils.random(0.6, 1.2) 
            ice.graphics.spin = MathUtils.random(-0.2, 0.2)
            
            Assets.playSound("snow_appear", 2)
            
            ice:fadeTo(1, 0.4)
            Game.battle.timer:tween(0.4, ice, {scale_x = max_scale, scale_y = max_scale}, "out-quad", function()
                Game.battle.timer:after(0.25, function()
                    ice.graphics.spin = ice.graphics.spin * -1 
                    ice:fadeOutAndRemove(0.4)
                    Game.battle.timer:tween(0.4, ice, {scale_x = 0, scale_y = 0}, "out-quad")
                end)
            end)
        end)
    end

        
    elseif status == "paralysis" then 
        self:statusMessage("msg", msg or "paralyzed")
        Assets.playSound("paralyze")
        self.paralyzed = true 
        self:flash(nil, nil, nil, 100, ColorUtils.hexToRGB("FFF0B2"))
        self:expandRipple(ColorUtils.hexToRGB("FFF0B2"), 2, {70, 50}, 3)
        return true
        
    elseif status == "toxic" then 
        self:statusMessage("msg", msg or "poisonedbadly")
        self.toxic = true  
        self.toxic_count = 1
        local mask = ColorMaskFX(ColorUtils.hexToRGB("B868A0"))
        mask.amount = 0 
        self:addFX(mask)
        local snd = Assets.playSound("poison", 2)
        local tween = snd:getDuration() / 2
        Game.battle.timer:tween(tween, mask, {amount = 1}, "linear", function()
            Game.battle.timer:tween(tween, mask, {amount = 0})
        end)
        return true
    end 
end

--- Removes a status condition from the enemy battler.
---@param status string # The ID of the status to cure (e.g., "poison").
function EnemyBattler:cure(status) 
    self:statusMessage("msg", "cured")
    if status == "poison" then 
        self.poison = false 
    elseif status == "frozen" then 
        self.frozen = false 
    elseif status == "paralysis" then 
        self.paralyzed = false 
    elseif status == "toxic" then
        self.toxic = false
        self.toxic_count = 0
    end 
end

-- this function is near useless but it helps sometimes ig. ..
function EnemyBattler:cureAll() 
    self.poison = false 
    self.toxic = false
    self.frozen = false 
    self.paralyzed = false 
    self.toxic_count = 0
    self.affect_waves = false 
end

--- A callback event caled whenever a status effect attempt is processed.
---@param status string # The name ID of the status that was processed.
---@param worked boolean # Whether the status was successfully applied to the enemy.
function EnemyBattler:onStatused(status, worked) return end  

---@param color table # The RGB table color for the rings (e.g. ColorUtils.hexToRGB("...") )
---@param amount number # How many ripple rings should expand out
---@param radius number|table # Max radius limit. Can be a flat number or a table mapping limits per ring index
function EnemyBattler:expandRipple(color, amount, radius, speed)
    amount = amount or 1
    local center_x, center_y = self:getRelativePos(self.sprite.width / 2, self.sprite.height / 2, Game.battle)
    for i = 1, amount do
        local delay = (i - 1) * 0.25     
        Game.battle.timer:after(delay, function()
            local max_r = type(radius) == "table" and (radius[i] or 80) or (radius or 80)
            local ripple = RippleEffect(center_x, center_y, color, 0, max_r, speed or 2.5)
            Game.battle:addChild(ripple)
        end)
    end
end

--- A function that is called when the enemy should take their poison damage. 
---@param toxic # Whether the damage should increase (bad poison), and will return the value, and the value for the next call. 
function EnemyBattler:takePoisonDamage(toxic)
    local mask = ColorMaskFX(ColorUtils.hexToRGB("B868A0"))
    mask.amount = 0 
    self:addFX(mask)
    local snd = Assets.playSound("poison", 2)
    local tween = snd:getDuration() / 2
    Game.battle.timer:tween(tween, mask, {amount = 1}, "linear", function()
        Game.battle.timer:tween(tween, mask, {amount = 0})
    end)
    
    if not toxic then 
        local dmg = MathUtils.roundFromZero(self.max_health / 8)
        self.hit_count = 0 
        self:hurt(dmg, nil, nil, ColorUtils.hexToRGB("B868A0"))
    else 
        local dmg = MathUtils.roundFromZero(self.max_health * (self.toxic_count / 16))
        self:hurt(dmg, nil, nil, ColorUtils.hexToRGB("B868A0"))
        self.hit_count = 0 
        self.toxic_count = self.toxic_count + 1
    end 
end

--- Spawns a colored overlay and scrolling white lines. 
---@param color table # The RGB table configuration defining the tint vector of the overlay shader lines.
---@param full_intensity number? # The maximum opacity intensity target peak the shader should approach. Defaults to 0.7.
function EnemyBattler:debuffEffect(color, full_intensity)
    local snd = Assets.playSound("stat_fell", 0.8)
    local my_fx = ShaderFX("debuff") 
    local peak = full_intensity or 0.7
    my_fx.shader:send("tint_color", color or COLORS.red)
    my_fx.shader:send("intensity", 0.0)
    my_fx.shader:send("scroll_y", 0.0)
    self:addFX(my_fx) 
    local current_scroll = 0
    local duration = snd:getDuration()
    local q_duration = duration / 4
    local h_duration = duration / 2
    Game.battle.timer:approach(q_duration, 0.0, peak, function(v)
        current_scroll = (current_scroll + (0.02 * DTMULT)) % 1.0
        my_fx.shader:send("scroll_y", current_scroll)
        my_fx.shader:send("intensity", v)
    end, "linear", function()
        Game.battle.timer:during(h_duration, function()
            current_scroll = (current_scroll + (0.02 * DTMULT)) % 1.0
            my_fx.shader:send("scroll_y", current_scroll)
            my_fx.shader:send("intensity", peak) 
        end, function()
            Game.battle.timer:approach(q_duration, peak, 0.0, function(v)
                current_scroll = (current_scroll + (0.02 * DTMULT)) % 1.0
                my_fx.shader:send("scroll_y", current_scroll)
                my_fx.shader:send("intensity", v)
            end, "linear", function()
                self:removeFX(my_fx)
            end)
        end)
    end)
end 

return EnemyBattler
