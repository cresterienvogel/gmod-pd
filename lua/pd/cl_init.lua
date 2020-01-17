CreateClientConVar("pd_cracks", 1, true, false, "Enable/Disable props' cracks")
CreateClientConVar("pd_hud", 1, true, false, "Enable/Disable HUD of Prop Destruction")

PD.Cracks = GetConVar("pd_cracks"):GetBool()
PD.HUD = GetConVar("pd_hud"):GetBool()

surface.CreateFont("pd_hud", {size = 26, weight = 300, antialias = true, extended = true, font = "Roboto Condensed"})
surface.CreateFont("pd_hud_shadow", {size = 27, weight = 300, antialias = true, extended = true, blursize = 1.5, font = "Roboto Condensed"})

--[[
    HUD
]]

local function PrettyText(text, font, x, y, color, xalign, yalign)
    draw.SimpleText(text, font .. "_shadow", x + 1, y + 1, ColorAlpha(color_black, 120), xalign, yalign and yalign or TEXT_ALIGN_TOP)
    draw.SimpleText(text, font, x + 1, y + 1, ColorAlpha(color_black, 150), xalign, yalign and yalign or TEXT_ALIGN_TOP)
    draw.SimpleText(text, font, x, y, color, xalign, yalign and yalign or TEXT_ALIGN_TOP)
end

hook.Add("HUDPaint", "Prop Destruction", function()
    if not PD.HUD then
        return
    end

    local tr = LocalPlayer():GetEyeTraceNoCursor()
    if IsValid(tr.Entity) and tr.HitPos:DistToSqr(LocalPlayer():EyePos()) < 22500 then
        local ent = tr.Entity

        if not ent:IsDestructible() or ent:GetMaxHealth() <= 1 then 
            return 
        end

        PrettyText("Health: " .. math.Round(ent:Health()) .. "/" .. math.Round(ent:GetMaxHealth()), "pd_hud", ScrW() / 2, ScrH() / 1.85 + 20, color_white, TEXT_ALIGN_CENTER)
        PrettyText(ent:GetStable() and "Stable" or "Unstable", "pd_hud", ScrW() / 2, ScrH() / 1.85 + 45, HSVToColor(ent:GetStable() and 140 or -20, 1, 1), TEXT_ALIGN_CENTER)
	end
end)

--[[
    Cracks
]]

local cracks = Material("crester/props/cracks")

local function RenderOverride(self)
	PD.DrawCrackedModel(self)
end

local prop_queue = {}
hook.Add("OnEntityCreated", "Prop Destruction", function(ent)
    if not PD.Cracks or not ent:IsDestructible() or ent:GetMaxHealth() <= 1 then
        return
    end
    
	table.insert(prop_queue, ent)
end)

hook.Add("Tick", "Prop Destruction", function()
	for i, v in ipairs(prop_queue) do
		if not IsValid(v) then
            table.remove(prop_queue, i)
        elseif v.RenderOverride == nil then
			v.RenderOverride = RenderOverride
			table.remove(prop_queue, i)
		end
	end
end)

function PD.DrawCrackedModel(ent)
	ent:DrawModel()

    if not PD.Cracks or ent:Health() > ent:GetMaxHealth() / 2 then 
        return 
    end

    cracks:SetTexture("$detail", Material(#ent:GetMaterial() > 0 and ent:GetMaterial() or (ent:GetMaterials()[1])):GetTexture("$basetexture"))
    
    render.MaterialOverride(cracks)
    render.SetBlend(0.9)

    ent:DrawModel()

    render.SetBlend(1)
    render.MaterialOverride()
end