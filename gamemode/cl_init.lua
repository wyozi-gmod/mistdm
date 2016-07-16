
DeriveGamemode("base")

MDMModes = {}

local _, folders = file.Find( GM.FolderName .. "/gamemode/modes/*", "LUA" )
if #folders > 0 then
	for _, folder in ipairs( folders ) do
		Msg( "[MistDM] Loading mode: " .. folder .. "\n" )
		DMMODE = {}

		include(GM.FolderName .. "/gamemode/modes/" .. folder .. "/cl_init.lua")

		MDMModes[folder] = DMMODE
		DMMODE = nil

	end
end

MDMMode = MDMModes["rounds"]

local files = file.Find( GM.FolderName .. "/gamemode/shared/*.lua", "LUA" )
if #files > 0 then
	for _, file in ipairs( files ) do
		Msg( "[MistDM] Loading SHARED module: " .. file .. "\n" )
		include( GM.FolderName .. "/gamemode/shared/" .. file )
	end
end

local files = file.Find( GM.FolderName .. "/gamemode/client/*.lua", "LUA" )
if #files > 0 then
	for _, file in ipairs( files ) do
		Msg( "[MistDM] Loading CLIENT module: " .. file .. "\n" )
		include( GM.FolderName .. "/gamemode/client/" .. file ) 
	end
end 
