surface.CreateFont("prop_destruction", {size = 26, weight = 350, antialias = true, extended = true, font = "Roboto Condensed"})

--[[---------------------------------------------------------------------------
	Drawing stuff
---------------------------------------------------------------------------]]

function surface.strengthToColor(m1, m2)
    if m1 < m2 / 2 and m1 > m2 / 3 then
        return Color(200, 200, 200)
    elseif m1 < m2 / 3 then
        return Color(255, 0, 0)
    end 

    return color_white  
end

function surface.DrawDestructionText(text, x, y, color, xalign, yalign)
    draw.SimpleText(text, "prop_destruction", x - 1, y + 1, Color(0, 0, 0, 200), xalign, yalign)
    draw.SimpleText(text, "prop_destruction", x, y, color, xalign, yalign)
end

--[[---------------------------------------------------------------------------
	Cracks
---------------------------------------------------------------------------]]

local cracks = Material("crester/props/cracks")
local function RenderOverride(self)
	DrawCrackedModel(self)
end

local prop_queue = {}
hook.Add("OnEntityCreated", "PropDestruction", function(ent)
    if ent:GetClass() != "prop_physics" then 
        return 
    end

    if ent:GetMaxHealth() <= 1 then
        return 
    end
    
	table.insert(prop_queue, ent)
end)

hook.Add("Tick", "PropDestruction", function()
	for i, v in ipairs(prop_queue) do
		if not IsValid(v) then
			table.remove(prop_queue, i)
		elseif v.RenderOverride == nil then
			v.RenderOverride = RenderOverride
			table.remove(prop_queue, i)
		end
	end
end)

function DrawCrackedModel(ent)
	ent:DrawModel()

    if ent:Health() > ent:GetMaxHealth() / 2 then 
        return 
    end

    cracks:SetTexture("$detail", Material(#ent:GetMaterial() > 0 and ent:GetMaterial() or (ent:GetMaterials()[1])):GetTexture("$basetexture"))
    
    render.MaterialOverride(cracks)
        render.SetBlend(0.9)
        ent:DrawModel()
        render.SetBlend(1)
    render.MaterialOverride()
end

--[[---------------------------------------------------------------------------
	HUD
---------------------------------------------------------------------------]]

hook.Add("HUDPaint", "PropDestruction_Status", function()
	local tr = LocalPlayer():GetEyeTraceNoCursor()

    if tr.Entity:IsValid() and tr.HitPos:DistToSqr(LocalPlayer():EyePos()) < 22500 then
        if tr.Entity:GetClass() != "prop_physics" then 
            return 
        end

        if tr.Entity:GetMaxHealth() <= 1 then
            return 
        end       

        surface.DrawDestructionText(math.Round(tr.Entity:Health()), ScrW() / 2 - 8, ScrH() / 1.85 + 20, surface.strengthToColor(tr.Entity:Health(), tr.Entity:GetMaxHealth()), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        surface.DrawDestructionText(" / " .. math.Round(tr.Entity:GetMaxHealth()), ScrW() / 2 - 8, ScrH() / 1.85 + 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
end)