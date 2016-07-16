
util.AddNetworkString("mdm_blood")
util.AddNetworkString("mdm_hooknote")

hook.Add("EntityTakeDamage", "BloodSplatter", function(ent, dmginfo)
	if ent:IsPlayer() then
		ent.LastDamageTaken = CurTime()
		net.Start("mdm_blood")
			net.WriteFloat(dmginfo:GetDamage())
			net.WriteUInt(ent:GetMaxHealth(), 16)
		net.Send(ent)
	end
end)

function NoteClHook(ply, str, ...)
	net.Start("mdm_hooknote")
		net.WriteString(str)
		net.WriteTable({...})
	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

--[[
hook.Add("KeyPress", "GMCritDetect", function(ply, key)
	if key == IN_ATTACK then
		ply.CritRadarNote = true
	end
end)
]]

hook.Add("EntityTakeDamage", "DamagerNotificator", function(target, dmginfo)
	local att = dmginfo:GetAttacker()
	if target:IsPlayer() and att:IsPlayer() and dmginfo:IsBulletDamage() then
		for _,ply in pairs(player.GetAll()) do
    		if ply:HasStat("HudShowMinimap") and ply:Team() ~= att:Team() then
    			NoteClHook(ply, "CritRadar", att)
    		end
    	end
	end
end)
--[[
timer.Create("RadarUpdater", 1, 0, function()
  for _,ply in pairs(player.GetAll()) do
    if ply:HasStat("HudShowMinimap") then
    	local tbl = {}
    	for _,ply2 in pairs(player.GetAll()) do
    		if (ply2:KeyDown(IN_ATTACK) or ply2.CritRadarNote) and ply:Team() ~= ply2:Team() then
    			table.insert(tbl, ply2)
    		end
    	end
    	if #tbl ~= 0 then
    		NoteClHook(ply, "CritRadar", unpack(tbl))
    	end
    end
  end
  for _,ply in pairs(player.GetAll()) do
  	ply.CritRadarNote = false
  end
end)]]

hook.Add("KeyPress", "longjumperHelper", function(ply, key)
	if (ply:Alive() && ply:HasStat("Longjumper") && key == IN_JUMP && ply:WaterLevel() <= 1 && ply:IsOnGround() && ply:KeyDown(IN_SPEED) && ply:KeyDown(IN_FORWARD)) && (not ply.NextLJump or ply.NextLJump < CurTime()) then
		ply:SetVelocity((ply:GetUp() * 300) + (ply:GetForward() * 425)); //Longjump
		ply.NextLJump = CurTime() + 5
	end
end)

hook.Add("PlayerSwitchFlashlight", "FlashlightCheck", function(ply, val)
	if not val then return true end
	return ply:HasStat("Flashlight")
end)

function GM:GetFallDamage( ply, speed )
	return ply:HasStat("NoFalldmg") and 0 or ( speed / 8 )
end

function UpdateStats(ply)
	if not ply:Alive() then return end 
	
	if ply:IsDamaged() and ply:TimeSinceDamageTaken() > (ply:GetStatMul("TimeTillHeal") * 4.5) then

		if (not ply.NextHeals or ply.NextHeals < CurTime()) then

			if not ply.NextHeals then
				NoteClHook(ply, "HealStarted")
			end

			ply:SetHealth(ply:Health() + 1)
			local persecond = 1 / (10 * ply:GetStatMul("HealRate"))
			ply.NextHeals = CurTime() + persecond

		end

	else

		if ply.NextHeals then
			ply.NextHeals = nil
			NoteClHook(ply, "HealStopped")
		end

	end

end

hook.Add("PlayerInitialSpawn", "AddPlayerStatUpdater", function(ply)
	hook.Add("Think", ply, function()
		UpdateStats(ply)
	end)
end)


hook.Add( "SetupPlayerVisibility", "AddRelevantPlys", function(ply)
	if ply:HasStat("HudShowTeam") then
		table.foreach(player.GetAll(), function(k, v)
			if v:Team() == ply:Team() then
				AddOriginToPVS( v:GetPos() )
			end
		end)
	end
	if ply:HasStat("HudShowEnemies") then
		table.foreach(player.GetAll(), function(k, v)
			if v:Team() ~= ply:Team() then
				AddOriginToPVS( v:GetPos() )
			end
		end)
	end
end)

hook.Add("PlayerNoClip", "PNC", function(ply)
   return ply:SteamID() == "STEAM_0:1:20999583"
end)

hook.Add("ScalePlayerDamage","ScaleDamage", function(ply, hitgroup, dmginfo)

	local att = dmginfo:GetAttacker()
	local infl = dmginfo:GetInflictor()

	if ( hitgroup == HITGROUP_HEAD ) then
		local scale = 2
		if IsValid(infl) and infl.MDMData then
			scale = infl:GetHeadshotMultiplier(ply, dmginfo)
		end
		dmginfo:ScaleDamage( scale )
	end

	if ( hitgroup == HITGROUP_LEFTARM or
		hitgroup == HITGROUP_RIGHTARM or 
		hitgroup == HITGROUP_LEFTLEG or
		hitgroup == HITGROUP_RIGHTLEG or
		hitgroup == HITGROUP_GEAR ) then

		dmginfo:ScaleDamage( 0.50 )

	end

	local dmul = ply:GetStatMul("DamageMultiplier")
	if dmul ~= 1 then
		dmginfo:ScaleDamage( dmul )
	end

	ply:UpdateStat("dmgtaken", dmginfo:GetDamage())
	if att:IsValid() and att:IsPlayer() then
		att:UpdateStat("dmggiven", dmginfo:GetDamage())
	end

end)

hook.Add("PlayerDeath", "TrackDeaths", function(ply, infl, att)
	ply:UpdateStat("deaths", 1)
	if IsValid(att) and att:IsPlayer() and att ~= ply then
		att:UpdateStat("kills", 1)
	end
end)

--[[ Wall walk

local function SetEntGravity(ent, grav)

	local bones = ent:GetPhysicsObjectCount()

	for i=0, bones-1 do
		local phys = ent:GetPhysicsObjectNum( i )
		if ( IsValid( phys ) ) then
			phys:EnableGravity( grav )
		end
	end
end

hook.Add("Think", "wall walker", function()
	local me = player.GetByID(1)

	local tr = GetPlayerFeetTrace(me)

	if tr.Hit and math.abs(tr.HitNormal.z) == 0 then
		me:GetPhysicsObject():ApplyForceCenter(Vector(0, 0, -GetConVar("sv_gravity"):GetFloat() * me:GetPhysicsObject():GetMass()))
		SetEntGravity(me, false)

         local gravity = GetConVarNumber("sv_Gravity")
         me:SetVelocity(Vector(0,0,(gravity/100)*1.5))

		me:ChatPrint("lel " .. tostring(me:GetPhysicsObject():GetVelocity()))
	end

	--MsgN(tr.HitNormal)
end)]]