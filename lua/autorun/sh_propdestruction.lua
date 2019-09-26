AddCSLuaFile("prop_destruction/cl_init.lua")

if SERVER then 
	include("prop_destruction/sv_init.lua")
else
	include("prop_destruction/cl_init.lua")
end