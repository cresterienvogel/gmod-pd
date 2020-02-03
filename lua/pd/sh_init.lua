local meta = FindMetaTable("Entity")

function meta:IsDestructible()
    return self:GetClass() == "prop_physics"
end

function meta:GetStable()
    return self:GetNWBool("Stable")
end

function meta:GetDamaged()
    return self:GetNWBool("Damaged")
end

function meta:GetRecoveryPerOnce()
    return self:GetMaxStrength() / 25
end

function meta:GetMaxStrength()
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        return phys:GetMass() * 2.25
    end

    return 1
end
