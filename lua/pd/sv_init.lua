CreateConVar("pd_enabled", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable/Disable Prop Destruction")
CreateConVar("pd_recovering", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable/Disable props' recovering")
CreateConVar("pd_recovering_revive", 22, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Amount of time before recovering starting")
CreateConVar("pd_recovering_time", 25, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Amount of time spent for the prop's full recovering")
CreateConVar("pd_recovering_delay", 2, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Amount of time before the next prop's recovery")
CreateConVar("pd_stability_distance", 40, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The distance after prop becomes unstable")
CreateConVar("pd_poorstart", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable/Disable props' spawning with 1 HP")

PD.Enabled = GetConVar("pd_enabled"):GetBool()
PD.Recovering = GetConVar("pd_recovering"):GetBool()
PD.RecoveringTime = GetConVar("pd_recovering_time"):GetInt()
PD.RecoveringRevive = GetConVar("pd_recovering_revive"):GetInt()
PD.RecoveringDelay = GetConVar("pd_recovering_delay"):GetInt()
PD.StabilityDistance = GetConVar("pd_stability_distance"):GetInt()
PD.Poor = GetConVar("pd_poorstart"):GetBool()

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

    return startpos.z, tr.HitPos.z, tr.Entity
end

function PD.CreateRecovery(ent)
    local index = ent:EntIndex()

    if timer.Exists("PD Recovery #" .. index) then
        return
    end

    timer.Create("PD Recovery #" .. index, PD.RecoveringDelay, 0, function()
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

    timer.Create("PD Stability #" .. index, PD.RecoveringDelay, 0, function()
        if not IsValid(ent) then
            timer.Remove("PD Stability #" .. index)
            return
        end

        local destructible = {}
        local near = ents.FindInBox(ent:OBBMins() + Vector(20, 20, 20), ent:OBBMaxs() + Vector(20, 20, 20))

        for i = 1, #near do
            if near[i] == ent then
                continue
            end

            if near[i]:IsDestructible() then
                destructible[#destructible + 1] = near[i]
            end
        end

        if #destructible == 0 then
            local z, zh, hit = PD.Trace(ent)
            ent:SetStable(z - zh < PD.StabilityDistance)
        else
            ent:SetStable(#destructible > 0)
        end
    end)
end

--[[
    Hooks
]]

hook.Add("PlayerSpawnedProp", "Prop Destruction", function(pl, mdl, ent)
    if not PD.Enabled or not ent:IsDestructible() then
        return
    end

    ent:SetMaxHealth(ent:GetMaxStrength())
    
    if PD.Poor then
        ent:SetHealth(1)
        timer.Simple(PD.RecoveringDelay, function()
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
    if not PD.Enabled or not target:IsDestructible() or target:GetMaxHealth() <= 1 then
        return
    end

    target:SetHealth(target:Health() - dmginfo:GetDamage())

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

    if PD.Recovering then
        target:SetDamaged(true) -- Make sure last recovering proccess has ended
        timer.Simple(PD.RecoveringRevive, function()
            if IsValid(target) then
                target:SetDamaged(false)
                PD.CreateRecovery(target)
            end
        end)
    end
end)