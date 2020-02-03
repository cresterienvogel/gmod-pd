CreateConVar("pd_enabled", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable/Disable Prop Destruction")
CreateConVar("pd_recovering", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable/Disable props' recovering")
CreateConVar("pd_poor", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable/Disable props' poor start")

--[[
    Meta
]]

local meta = FindMetaTable("Entity")

function meta:SetStable(bool)
    self:SetNWBool("Stable", bool)
end

function meta:SetDamaged(bool)
    self:SetNWBool("Damaged", bool)
end

--[[
    Functions
]]

function PD.Trace(ent)
    local mins = ent:OBBMins()
    local maxs = ent:OBBMaxs()
    local startpos = ent:GetPos()

    local tr = util.TraceHull({
        start = startpos,
        endpos = Vector(startpos.x, startpos.y, -1000000),
        maxs = maxs,
        mins = mins,
        filter = ent
    })

    return startpos.z, tr.HitPos.z, tr.Entity, tr.HitWorld
end

function PD.CreateRecovery(ent)
    local index = ent:EntIndex()

    if timer.Exists("PD Recovery #" .. index) then
        return
    end

    timer.Create("PD Recovery #" .. index, 3, 0, function()
        if not IsValid(ent) or ent:Health() >= ent:GetMaxHealth() or ent:GetDamaged() or not ent:GetStable() then
            timer.Remove("PD Recovery #" .. index)
            return
        end

        ent:SetHealth(ent:Health() + ent:GetRecoveryPerOnce())
        if ent:Health() > ent:GetMaxHealth() then -- Oops
            ent:SetHealth(ent:GetMaxHealth())
        end
    end)
end

function PD.CreateStability(ent)
    local index = ent:EntIndex()

    timer.Create("PD Stability #" .. index, 1, 0, function()
        if not IsValid(ent) then
            timer.Remove("PD Stability #" .. index)
            return
        end

        local z, zh, hit, world = PD.Trace(ent)
        if not world and not hit:IsDestructible() and not hit:IsPlayer() then
            ent:SetStable(false)
            return
        end

        ent:SetStable(z - zh < 40)
    end)
end

--[[
    Hooks
]]

hook.Add("PlayerSpawnedProp", "Prop Destruction", function(pl, mdl, ent)
    if not GetConVar("pd_enabled"):GetBool() or not ent:IsDestructible() then
        return
    end

    ent:SetMaxHealth(ent:GetMaxStrength())
    
    if GetConVar("pd_poor"):GetBool() then
        ent:SetHealth(1)
        timer.Simple(3, function()
            if not IsValid(ent) then
                return
            end

            PD.CreateRecovery(ent)
        end)
    else
        ent:SetHealth(ent:GetMaxHealth())
    end

    PD.CreateStability(ent)
end)

hook.Add("EntityTakeDamage", "Prop Destruction", function(target, dmginfo)
    if not GetConVar("pd_enabled"):GetBool() or not target:IsDestructible() or target:GetMaxHealth() <= 1 then
        return
    end

    target:SetHealth(target:Health() - dmginfo:GetDamage())

    if timer.Exists("PD Recovery #" .. target:EntIndex()) then
        timer.Remove("PD Recovery #" .. target:EntIndex())
    end

    if target:Health() <= 0 then
        if target:GetMaxHealth() >= 45 then
            target:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav")
        end

        target:Remove()
        return
    end 

    if PD.Cracks and not target:GetCracked() then -- Let's make it cracked
        if target:Health() < (target:GetMaxHealth() / 2) then
            if target:GetMaxHealth() >= 45 then
                target:EmitSound("physics/metal/metal_solid_strain" .. math.random(1, 4) .. ".wav")
            end
        end
    end

    if GetConVar("pd_recovering"):GetBool() then
        if timer.Exists("PD Recovery Try #" .. target:EntIndex()) then
            timer.Remove("PD Recovery Try #" .. target:EntIndex())
        end

        target:SetDamaged(true) -- Make sure last recovering proccess has ended
        timer.Create("PD Recovery Try #" .. target:EntIndex(), 22, 1, function()
            if IsValid(target) and target:GetDamaged() then
                target:SetDamaged(false)
                PD.CreateRecovery(target)
            end
        end)
    end
end)
