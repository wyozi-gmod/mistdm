MsgN("Loading tdm based MistDM")



function DMMODE:Initialize()
end

function DMMODE:SpawnPly(ply)
	ply:StripWeapons()
	ply:Spawn()
	
	ply:Give("wdrp_spec_bazooka")

end

function DMMODE:PlayerInitialSpawn(ply)
	local bestteam = team.BestAutoJoinTeam()
	if bestteam == TEAM_UNASSIGNED then
		bestteam = math.random(2)
	end
	ply.SpawnInTeam = bestteam
	--ply:StripAll()
end

function DMMODE:PlayerSpawn(ply)

	if ply.SpawnInTeam and ply:Team() ~= ply.SpawnInTeam then
		ply:SetTeam(ply.SpawnInTeam)
	end

	local um = ply:GetPData("mdmmodel", nil)
	if um then
		ply:SetModel(um)
	else
		if ply:Team() == TEAM_GREEN then -- HACK HACK HACK
			ply:SetModel("models/player/kleiner.mdl")
		else
			ply:SetModel("models/player/mossman.mdl")
		end
	end

	local clr = team.GetColor(ply:Team())
	ply:SetPlayerColor(Vector(clr.r, clr.g, clr.b))
	
	local oldhands = ply:GetHands()
	if IsValid(oldhands) then oldhands:Remove() end

	local hands = ents.Create( "gmod_hands" )
	if IsValid(hands) then
		ply:SetHands(hands)
		hands:SetOwner(ply)

		-- Which hands should we use?
		local simplemodel = ply:GetModel()
		local info = player_manager.TranslatePlayerHands(simplemodel)
		if info then
			hands:SetModel(info.model)
			hands:SetSkin(info.skin)
			hands:SetBodyGroups(info.body)
		end

		-- Attach them to the viewmodel
		local vm = ply:GetViewModel(0)
		hands:AttachToViewmodel(vm)

		vm:DeleteOnRemove(hands)
		ply:DeleteOnRemove(hands)

		hands:Spawn()
	end

end

function DMMODE:PlayerDeathThink(pl)
	if ( pl.NextSpawnTime && pl.NextSpawnTime > CurTime() ) then return end

	if ( pl:KeyPressed( IN_ATTACK ) || pl:KeyPressed( IN_ATTACK2 ) || pl:KeyPressed( IN_JUMP ) ) and not pl:IsSpec() then
		self:SpawnPly(pl)
	end
end

function DMMODE:PlayerTeamSelected(ply, team)
	if team == TEAM_SPEC then
		ply:SetTeam(team)
		if ply:Alive() then
			ply:Kill()
		end
	end
end
