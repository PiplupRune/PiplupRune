local Wave, super = HookSystem.hookScript(Wave)

function Wave:init(...)
    super.init(self, ...)
    for _, p in ipairs(self:getAttackers()) do 
        if p.paralyzed then 
            self:paralysisText(p)
        end 
        if p.frozen then 
            self:frozenText(p)
        end 
        if p.affect_waves then  
            self:flinch(p)
        end 
    end 
end 

function Wave:flinch() end 

function Wave:paralysisText() end 

function Wave:frozenText() end 



return Wave
