--[[---------------------------------------------------------------------------
	Meta functions
---------------------------------------------------------------------------]]

local meta = FindMetaTable("Entity")

function meta:massToStrength(mass)
    return mass * 2.25
end