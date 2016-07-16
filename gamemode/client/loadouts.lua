loadouts = {}

function loadouts.Save()
	local myloadouts = LocalPlayer().loadouts or {}
	file.Write("mistdmloadouts.txt", util.TableToJSON(myloadouts))
end

function loadouts.LoadTable()
	return util.JSONToTable(file.Read("mistdmloadouts.txt", "DATA") or "[]")
end

function loadouts.Load()
	LocalPlayer().loadouts = loadouts.LoadTable()

	for i,lo in pairs(LocalPlayer().loadouts) do
		net.Start("mdm_loadout")
			net.WriteUInt(i, 8)
			net.WriteTable(lo)
		net.SendToServer()
	end
end
