local function ChangeMyTeam( ply, cmd, args )
	local n = tonumber(args[1])
	if n == TEAM_UNASSIGNED then return end
	if team.Valid(n) then
		ply.SpawnInTeam = n
		ply:ChatPrint("You will spawn in team " .. tostring(team.GetName(ply.SpawnInTeam)))
		if MDMMode.PlayerTeamSelected then
			MDMMode:PlayerTeamSelected(ply, n)
		end
	else
		ply:ChatPrint("Invalid team")
	end
end
concommand.Add( "mdm_setteam", ChangeMyTeam )


function GM:IsSpawnpointSuitable(ply, spwn)
   if not IsValid(ply) or ply:IsSpec() then return true end
   if (not IsValid(spwn) or not spwn:IsInWorld()) then return false end

   -- spwn is normally an ent, but we sometimes use a vector for jury rigged
   -- positions
   local pos = spwn:GetPos()

   if not util.IsInWorld(pos) then return false end

   local blocking = ents.FindInBox(pos + Vector( -16, -16, 0 ), pos + Vector( 16, 16, 64 ))

   for k, p in pairs(blocking) do
      if IsValid(p) and p:IsPlayer() and not p:IsSpec() and p:Alive() then
      	return false
      end
   end

   return true
end

local teamspawns = {
   [TEAM_GREEN] = {
      "info_player_terrorist",
      "info_player_combine",
      "info_player_axis"
   },
   [TEAM_PURPLE] = {
      "info_player_counterterrorist",
      "info_player_rebel",
      "info_player_allies"
   }
}

local dmspawns = {
   "info_player_deathmatch",
   "gmod_player_start",
   "info_player_teamspawn"
}

local function GetPossibleSpawns( ply )
   local ts = teamspawns[ ply:Team() ] or teamspawns[ TEAM_GREEN ] -- Uhh

   local possible = {}

   for _, aspawn in pairs(ts) do
      local es = ents.FindByClass(aspawn)
      table.foreach(es, function(k, v)
         table.insert(possible, v)
      end)
   end

   if table.Count(possible) > 0 then
      return possible
   end

   -- We need to add dm spawns because no team spawns were found

   for _, aspawn in pairs(dmspawns) do
      local es = ents.FindByClass(aspawn)
      table.foreach(es, function(k, v)
         table.insert(possible, v)
      end)
   end

   return possible

end

function GM:PlayerSelectSpawn( ply)
	local team = ply.SpawnInTeam or ply:Team()

	local spawns = GetPossibleSpawns( ply )

	table.Shuffle( spawns )

   MsgN("Possible spawns:")
   PrintTable(spawns)

   -- Optimistic attempt: assume there are sufficient spawns for all and one is
   -- free
   for k, spwn in pairs(spawns) do
      if self:IsSpawnpointSuitable(ply, spwn) then
         return spwn
      end
   end

	return spawns[1] -- table is shuffled so first entry should be random as well
end

--function GM:PlayerShouldTakeDamage( ply, attacker ) 
--	return ply:Team() ~= attacker:Team()
--end