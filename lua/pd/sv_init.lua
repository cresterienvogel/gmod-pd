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
	if not IsValid(ent) then
		return false
	end

	local mins = ent:OBBMins()
	local maxs = ent:OBBMaxs()
	local startpos = ent:GetPos()
	local len = 36

	local dirs = {
		ent:GetUp(),
		-ent:GetUp(),
		ent:GetForward(),
		-ent:GetForward(),
		ent:GetRight(),
		-ent:GetRight()
	}

	local bRadius = ent:BoundingRadius()
	local bMin, bMax = ent:GetCollisionBounds()

	len = len + bRadius / 5 + (bRadius > 150 and 50 or 0)

	local filter = ents.FindInSphere(ent:LocalToWorld(ent:OBBCenter()), bRadius)
	for _, e in ipairs(filter) do
		if e:GetClass():find("prop_") and ent ~= e then
			table.RemoveByValue(filter, e)
		end
	end

	for _, dir in pairs(dirs) do
		local tr = util.TraceHull({
			start = startpos,
			endpos = startpos + dir * len,
			maxs = maxs,
			mins = mins,
			filter = filter
		})

		if tr.HitWorld or (tr.Entity and IsValid(tr.Entity) and tr.Entity:IsDestructible() and tr.Entity:GetStable()) then
			return true
		end
	end

	return false
end

function PD.CreateRecovery(ent)
	local index = ent:EntIndex()
	if timer.Exists("PD Recovery #" .. index) then
		return
	end

	timer.Create("PD Recovery #" .. index, 3, 0, function()
		if not IsValid(ent) then
			timer.Remove("PD Recovery #" .. index)
			return
		end

		if ent:Health() >= ent:GetMaxHealth() or ent:GetDamaged() or not ent:GetStable() then
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
		ent:SetStable(PD.Trace(ent))
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
		ent:SetSimpleTimer(3, function()
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

	local blast = dmginfo:IsDamageType(DMG_BURN) or dmginfo:IsDamageType(DMG_BLAST)
	target:SetHealth(target:Health() - (blast and dmginfo:GetDamage() * 4 or dmginfo:GetDamage()))

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