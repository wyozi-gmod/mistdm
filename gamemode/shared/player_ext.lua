local meta = FindMetaTable("Player")

function meta:Items()
	if self.Itemst then
		return self.Itemst
	end
	self.Itemst = {}
	return self.Itemst
end

function meta:HasItem(id)
	for _,item in pairs(self:Items()) do
		if item.id == id then
			return true
		end
	end
	return false
end

function meta:GetItem(id)
	for _,item in pairs(self:Items()) do
		if item.id == id then
			return item
		end
	end
end

function meta:GetAssocEntity(id)
	for _,wep in pairs(self:GetWeapons()) do
		if wep.ClassName == id then
			return wep
		end
	end
end

function meta:GetLoadout(id)
	if not id then
		id = self.UseLoadout
	end
	if not self.loadouts or not id then return end
	return self.loadouts[id]
end

function meta:GetStatMul(stat)
	local base = 1

	table.foreach(self:Items(), function(k,v)
		local item = v
		if not item.data.stats then return end
		local stats = item.data.stats
		if not stats[stat] or type(stats[stat]) ~= "number" then return end
		base = base * stats[stat]
	end)

	return base
end

function meta:HasStat(stat)
	for _,item in pairs(self:Items()) do
		if not item.data.stats then continue end
		local stats = item.data.stats
		if stats[stat] then return true end
	end
	return false
end

function meta:GetHeartbeat()
	return self:GetNWInt("hbeat", 0)
end

if SERVER then

	util.AddNetworkString("mdm_gitem")

	function meta:UpdateItems(ids)
		if not ids then
			local lo = self:GetLoadout()
			if lo then
				ids = lo.items
			else
				ids = {}
			end
		end
		self.Itemst = {}

		for _, id in pairs(ids) do
			local item = MDMItems.GetItem(id)
			if not item then
				ErrorNoHalt("giving nonexistent item " .. id)
				return false
			end

			table.insert(self.Itemst, item)
			if item.type == MDM_WEAPON then
				self:Give(id)
			end
		end

		net.Start("mdm_gitem")
			net.WriteEntity(self)
			net.WriteTable(ids)
		net.Broadcast()
	end

	function meta:SetHeartbeat(hb)
		self:SetNWInt("hbeat", hb)
	end

elseif CLIENT then
	function meta:UpdateItems(ids)
		if not ids then
			ids = self:GetLoadout().items
		end
		self.Itemst = {}

		for _, id in pairs(ids) do
			local item = MDMItems.GetItem(id)
			if not item then
				ErrorNoHalt("giving nonexistent item " .. id)
				return false
			end

			table.insert(self.Itemst, item)
		end
		return item
	end
	net.Receive("mdm_gitem", function()
		local ent = net.ReadEntity()
		if IsValid(ent) then
			ent:UpdateItems(net.ReadTable())	
		end
	end)
end

function meta:IsSprinting()
	return self:KeyDown(IN_SPEED)
end

function meta:IsSpec()
	return self:Team() == TEAM_SPEC
end