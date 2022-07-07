PD = PD or {}

AddCSLuaFile("pd/cl_init.lua")
AddCSLuaFile("pd/sh_init.lua")
if SERVER then
	include("pd/sv_init.lua")
	include("pd/sh_init.lua")
else
	include("pd/cl_init.lua")
	include("pd/sh_init.lua")
end