include("sh_init.lua")

CreateConVar("props_destruction", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable or disable Prop Destruction.")
CreateConVar("props_recovering", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable or disable recovering for Prop Destruction.")
CreateConVar("props_lowspawn", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable or disable prop's spawning with 1 HP.")

--[[---------------------------------------------------------------------------
	Prop Initial Spawn
---------------------------------------------------------------------------]]

hook.Add("PlayerSpawnedProp", "PropDestruction_Spawn", function(ply, model, ent)
    if not GetConVar("props_destruction"):GetBool() then
        return
    end

    if ent:GetClass() != "prop_physics" then 
        return 
    end

    local phys = ent:GetPhysicsObject()
    ent:SetMaxHealth(ent:massToStrength(phys:GetMass())) 

    if GetConVar("props_recovering"):GetBool() then
        if GetConVar("props_lowspawn"):GetBool() then
            ent.firstRecovering = true

            ent:SetHealth(1)
            ent:SetNWBool("prop_recovering", true)

            timer.Create("PropRecovery" .. ent:EntIndex(), 1, 0, function()
                if not IsValid(ent) then
                    timer.Remove("PropRecovery" .. ent:EntIndex())
                    return 
                end

                if not ent:GetNWBool("prop_recovering") then
                    return 
                end

                if ent:Health() >= ent:GetMaxHealth() then
                    ent:SetNWBool("prop_recovering", false)
                    return
                end            

                if ent:Health() > ent:GetMaxHealth() / 2 then
                    ent:SetNWBool("prop_cracked", false)
                end

                if ent.firstRecovering then
                    ent:SetHealth(ent:Health() + 15)
                else
                    ent:SetHealth(ent:Health() + 1)
                end

                if ent:Health() > ent:GetMaxHealth() then
                    ent:SetHealth(ent:GetMaxHealth())
                    ent:SetNWBool("prop_recovering", false)
                    return
                end
            end)
        else
            ent:SetHealth(ent:GetMaxHealth())
        end
    else
        ent:SetHealth(ent:massToStrength(phys:GetMass()))
    end
end)

--[[---------------------------------------------------------------------------
	Prop Damage
---------------------------------------------------------------------------]]

hook.Add("EntityTakeDamage", "PropDestruction_Damage", function(target, dmginfo)
    if not GetConVar("props_destruction"):GetBool() then
        return
    end

    if target:GetClass() != "prop_physics" then 
        return 
    end

    if target:GetMaxHealth() <= 1 then
        return 
    end    

    target:SetHealth(target:Health() - dmginfo:GetDamage())

    if GetConVar("props_recovering"):GetBool() then
        if GetConVar("props_lowspawn"):GetBool() then
            if target.firstRecovering then
                target.firstRecovering = false
            end
        end

        if target:GetNWBool("prop_recovering") then
            target:SetNWBool("prop_recovering", false)
        end

        timer.Simple(25, function()
            target:SetNWBool("prop_recovering", true)     
        end) 
    end

    if IsValid(target) then
        if target:Health() <= 0 then   
            if target:GetMaxHealth() >= 45 then
                target:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav")
            end

            target:Remove()        
        end
    end

    if target:Health() < target:GetMaxHealth() / 2 then
        if target:GetNWBool("prop_cracked") then 
            return 
        end  

        if target:GetMaxHealth() >= 45 then
            target:EmitSound("physics/metal/metal_solid_strain" .. math.random(1, 4) .. ".wav")
        end

        target:SetNWBool("prop_cracked", true)
    end     
end)