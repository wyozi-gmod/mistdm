
-- kill hl2 beep
function GM:PlayerDeathSound() return true end


function GM:DoPlayerDeath(ply, attacker, dmginfo)

	if ply:IsSpec() then return end

	-- if spec dont do anything

   -- Drop all weapons and accessories?

   -- Create ragdoll

   self.BaseClass.DoPlayerDeath(self, ply, attacker, dmginfo)

   -- Clear out any weapon or equipment we still have
   --ply:StripAll()
end

function GM:PlayerDeath( victim, infl, attacker)
   -- tell no one

   self.BaseClass.PlayerDeath(self, victim, infl, attacker)
   
end

-- First spawn on the server
function GM:PlayerInitialSpawn( ply )
	if MDMMode.PlayerInitialSpawn then
		MDMMode:PlayerInitialSpawn(ply)
	end
end

-- Only active players can use kill cmd
function GM:CanPlayerSuicide(ply)
   return not ply:IsSpec()
end

function GM:PlayerUse(ply, ent)
   return not ply:IsSpec()
end

function GM:PlayerSpawn(ply)

	player_manager.SetPlayerClass( ply, "player_mistdm" )

	if MDMMode.PlayerSpawn then
		MDMMode:PlayerSpawn(ply)
	end

end

function GM:PlayerShouldTakeDamage( victim, pl )
   if (pl:IsPlayer() and victim:IsPlayer()) then
      return victim:Team() ~= pl:Team()
   end
end

function GM:PlayerDeathThink( pl )
   if MDMMode.PlayerDeathThink then
      MDMMode:PlayerDeathThink(pl)
   end
end


util.AddNetworkString("mdm_loadout")
net.Receive("mdm_loadout", function(le, cl)

   local loadout = net.ReadUInt(8)
   local tbl = net.ReadTable()

   -- TODO check for weight etc

   if not cl.loadouts then
      cl.loadouts = {}
   end

   cl.loadouts[loadout] = tbl
   cl.UseLoadout = loadout

   cl:ChatPrint("Loadout succesfully modified.")
end)

concommand.Add( "mdm_useloadout", function( ply, cmd, args )
   local n = tonumber(args[1])
   
   ply.UseLoadout = n -- TODO sanenify
   ply:ChatPrint("You have selected loadout " .. tostring(n) .. " to use. It will be active next life.") 

   if MDMMode.PlayerLoadoutSelected then
      MDMMode:PlayerLoadoutSelected(ply, n)
   end
end )

concommand.Add( "mdm_setmodel", function( ply, cmd, args )
   local n = args[1]
   
   if n and table.HasValue(ValidMDMModels, n) then
      ply:SetPData("mdmmodel", n)
      ply:ChatPrint("Your model has been changed will be changed next life.")
   else
      ply:ChatPrint("Invalid model " .. n)
   end
   
end )


--[[
	TODO go spec:

	victim:Freeze(false)
   victim:SetRagdollSpec(true)
   victim:Spectate(OBS_MODE_IN_EYE)

   local rag_ent = victim.server_ragdoll or victim:GetRagdollEntity()
   victim:SpectateEntity(rag_ent)

   victim:Flashlight(false)

   victim:Extinguish()

]]