MDMItems = MDMItems or {}
MDMItems.Items = MDMItems.Items or {}

MDM_WEAPON = 1
MDM_PERK = 2

function MDMItems.GetItem(id)
	return MDMItems.Items[id]
end

function MDMItems.GetDataFor(clazz)
	local wep = clazz
	if not wep then return end
	if wep.MDMData then
		return wep.MDMData
	end
	if wep.Base then
		--return MDMItems.GetDataFor(wep.Base)
	end
end

-- Load perks

local perks = {}

local files = file.Find( GM.FolderName .. "/gamemode/shared/perks/*.lua", "LUA" )
if #files > 0 then
	for _, file in ipairs( files ) do
		Msg( "[MistDM] Loading perk: " .. file .. "\n" )

		PERK = {}

		include( GM.FolderName .. "/gamemode/shared/perks/" .. file )
		if SERVER then
			AddCSLuaFile( GM.FolderName .. "/gamemode/shared/perks/" .. file )
		end

		perks[string.StripExtension(file)] = PERK
	end
	PERK = nil
end


function MDMItems.Load()
	local ents = weapons.GetList()
	table.foreach(ents, function(k, v)
		local data = MDMItems.GetDataFor(v)
		if data then
			MDMItems.Items[v.ClassName] = {
				type = MDM_WEAPON,
				data = v.MDMData,
				id = v.ClassName
			}
		end
	end)

	table.foreach(perks, function(k, v)
		MDMItems.Items[k] = {
			type = MDM_PERK,
			data = v,
			id = k
		}
	end)

end

hook.Add("Initialize", "AddMDMItems", MDMItems.Load)