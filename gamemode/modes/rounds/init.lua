MsgN("Loading round based MistDM")

AddCSLuaFile("shared.lua")
include("shared.lua")

CreateConVar("mluna_rounds_roundtime", "600", FCVAR_NOTIFY)
CreateConVar("mluna_rounds_preptime", "5", FCVAR_NOTIFY)
CreateConVar("mluna_rounds_posttime", "5", FCVAR_NOTIFY)
util.AddNetworkString("mluna_roundstate")

function DMMODE:Initialize()
	self.round_state = MLUNA_ROUND_WAIT
	self.first_round = true
	self:WaitForPlayers()
end

function DMMODE:SendRoundState(state, ply)
	net.Start("mluna_roundstate")
		net.WriteUInt(state, 8)
	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function DMMODE:SetRoundState(state)
	self.round_state = state
	table.foreach(player.GetAll(), function(k, v)
		v:ChatPrint("New round state: " .. tostring(state))
	end)
	MsgN("round state: " .. tostring(state))
	self:SendRoundState(state)
end

function DMMODE:GetRoundState()
	return self.round_state
end

function DMMODE:EnoughPlayers()
	local ready = 0
	-- only count truly available players, ie. no forced specs
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and (not ply:IsSpec() or ply.SpawnInTeam ~= TEAM_SPEC) then -- TODO check if should spawn
			ready = ready + 1
		end
	end
	return ready >= 2
end

function DMMODE:WaitingForPlayersChecker()
   if self:GetRoundState() == MLUNA_ROUND_WAIT and self:EnoughPlayers() then
		timer.Create("wait2prep", 1, 1, function()
			self:PrepareRound()
		end)
		timer.Stop("waitingforply")
   end
end

function DMMODE:WaitForPlayers()
	self:SetRoundState(MLUNA_ROUND_WAIT)

	if not timer.Start("waitingforply") then
		timer.Create("waitingforply", 2, 0, function()
			self:WaitingForPlayersChecker()
		end)
	end
end

function DMMODE:Cleanup()
	game.CleanUpMap(false, {})
end

function DMMODE:SpawnPly(ply)
	ply:StripWeapons()
	ply:Spawn()

	ply:Give("wdrp_spec_bazooka")

end

function DMMODE:PrepareRound()
	if not self:EnoughPlayers() then
		self:WaitForPlayers()
		return 
	end

	self:Cleanup()
	self:SetRoundState(MLUNA_ROUND_PREP)

	table.foreach(player.GetAll(), function(k, v)
		if v.SpawnInTeam and v.SpawnInTeam ~= v:Team() then
			v:SetTeam(v.SpawnInTeam)
		end
		local tm = v:Team()
		if tm == TEAM_SPEC then return end

		self:SpawnPly(v)

	end)

   	timer.Create("prep2begin", self.first_round and 20 or GetConVar("mluna_rounds_preptime"):GetInt(), 1, function()
		self:BeginRound()
	end)

	self.first_round = false

	NoteClHook(_, "PrepareRound")
end

function DMMODE:GetWinner()
	if not self:EnoughPlayers() then return 0 end
	
	local t1alive, t2alive = false, false
	table.foreach(player.GetAll(), function(k, v)
		if not v:IsSpec() and v:Alive() then
			if v:Team() == TEAM_GREEN then
				t1alive = true
			elseif v:Team() == TEAM_PURPLE then
				t2alive = true
			end
		end
	end)

	if t1alive and not t2alive then
		return 1
	end
	if t2alive and not t1alive then
		return 2
	end
	return 0
end

function DMMODE:CheckForWin() 
	local winner = self:GetWinner()
	if winner ~= 0 then
		self:EndRound(winner)
	end
end

function DMMODE:BeginRound()
	if not self:EnoughPlayers() then
		self:WaitForPlayers()
		return 
	end

	table.foreach(player.GetAll(), function(k, v)
		local tm = v:Team()
		if tm == TEAM_SPEC then return end

		if not v:Alive() then
			self:SpawnPly(v)
		end

	end)
	
	self:SetRoundState(MLUNA_ROUND_ACTIVE)
	if not timer.Start("winchecker") then
		timer.Create("winchecker", 1, 0, function()
			self:CheckForWin()
		end)
	end

	NoteClHook(_, "BeginRound")

end

function DMMODE:EndRound(winner)
	local winnerstr = winner == 0 and "timelimit" or team.GetName(winner)

	table.foreach(player.GetAll(), function(k, v)
		v:ChatPrint("WE GOT A WINNER: TEAM " .. winnerstr)
	end)

	self:SetRoundState(MLUNA_ROUND_POST)
	timer.Stop("winchecker")

	timer.Create("end2prep", GetConVar("mluna_rounds_posttime"):GetInt(), 1, function()
		self:PrepareRound()
	end)

	NoteClHook(_, "EndRound")
end

function DMMODE:PlayerInitialSpawn(ply)
	local bestteam = team.BestAutoJoinTeam()
	if bestteam == TEAM_UNASSIGNED or not bestteam then
		bestteam = math.random(2)
	end
	ply.SpawnInTeam = bestteam
	--ply:StripAll()
end

function DMMODE:PlayerSpawn(ply)

	-- latejoiner, send him some info
	if self:GetRoundState() == MLUNA_ROUND_ACTIVE then
		self:SendRoundState(self:GetRoundState(), ply)
	end

	if ply.SpawnInTeam and ply:Team() ~= ply.SpawnInTeam then
		ply:SetTeam(ply.SpawnInTeam)
	end

	if ply:IsSpec() then
		--ply:StripAll()
		ply:ChatPrint("Press tab and press on one of the headers to choose your team.")
		ply:Spectate(OBS_MODE_ROAMING)
		return
	end

	ply:UnSpectate()

	local um = ply:GetPData("mlunamodel", nil)
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

function DMMODE:PlayerDeathThink(ply)
	if ply:GetObserverMode() ~= OBS_MODE_ROAMING then
		ply:Spectate(OBS_MODE_ROAMING)
	end
	--[[if ( pl.NextSpawnTime && pl.NextSpawnTime > CurTime() ) then return end

	if ( pl:KeyPressed( IN_ATTACK ) || pl:KeyPressed( IN_ATTACK2 ) || pl:KeyPressed( IN_JUMP ) ) then
		pl:OpenWeaponSelector()
	end]]
end

function DMMODE:PlayerLoadoutSelected(ply, lo)
	if ( self:GetRoundState() == MLUNA_ROUND_WAIT or self:GetRoundState() == MLUNA_ROUND_PREP) and ply:Team() ~= TEAM_SPEC then
		self:SpawnPly(ply)
	end
end

function DMMODE:PlayerTeamSelected(ply, team)
	if team == TEAM_SPEC and self:GetRoundState() ~= MLUNA_ROUND_ACTIVE then
		ply:SetTeam(team)
		if ply:Alive() then
			ply:Kill()
		end
	end
	if ( ( self:GetRoundState() == MLUNA_ROUND_WAIT and not self:EnoughPlayers() ) or self:GetRoundState() == MLUNA_ROUND_PREP) and team ~= TEAM_SPEC then
		self:SpawnPly(ply)
	end
end
