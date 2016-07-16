
include("resources.lua")

GM.Version = "0.1"
GM.Name = "MistDM"
GM.Author = "Cookie"

DeriveGamemode("base")

MDMModes = {}

local _, folders = file.Find( GM.FolderName .. "/gamemode/modes/*", "LUA" )
if #folders > 0 then
	for _, folder in ipairs( folders ) do
		Msg( "[MistDM] Loading mode: " .. folder .. "\n" )

		DMMODE = {}

		include(GM.FolderName .. "/gamemode/modes/" .. folder .. "/init.lua")

		MDMModes[folder] = DMMODE
		DMMODE = nil

		AddCSLuaFile(GM.FolderName .. "/gamemode/modes/" .. folder .. "/cl_init.lua")
	end
end

MDMMode = MDMModes["rounds"] -- todo?
MDMMode:Initialize()

local files = file.Find( GM.FolderName .. "/gamemode/shared/*.lua", "LUA" )
if #files > 0 then
	for _, file in ipairs( files ) do
		Msg( "[MistDM] Loading SHARED module: " .. file .. "\n" )
		include( GM.FolderName .. "/gamemode/shared/" .. file )
		AddCSLuaFile( GM.FolderName .. "/gamemode/shared/" .. file )
	end
end

local files = file.Find( GM.FolderName .. "/gamemode/server/*.lua", "LUA" )
if #files > 0 then
	for _, file in ipairs( files ) do
		Msg( "[MistDM] Loading SERVER module: " .. file .. "\n" )
		include( GM.FolderName .. "/gamemode/server/" .. file ) 
	end
end 

local files = file.Find( GM.FolderName .. "/gamemode/client/*.lua", "LUA" )
if #files > 0 then
	for _, file in ipairs( files ) do
		Msg( "[MistDM] Sending CLIENT module: " .. file .. "\n" )
		AddCSLuaFile( GM.FolderName .. "/gamemode/client/" .. file )
	end
end
