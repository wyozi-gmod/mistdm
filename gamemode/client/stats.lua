
-- Muted footsteps

hook.Add("PlayerFootstep", "MuteFeet", function(ply)
	if ply:HasStat("MuteFootsteps") then
		return true
	end
end)

hook.Add("CreateMove", "MistBunny", function(ucmd)
	if not LocalPlayer():HasStat("BunnyhopHelper") then return end
	
	local ply = LocalPlayer()
	if IsValid(ply) and bit.band(ucmd:GetButtons(), IN_DUCK) > 0 and ply:OnGround() then
		ucmd:SetButtons( bit.bor(ucmd:GetButtons(), IN_JUMP) )
	end
end)

net.Receive("mdm_hooknote", function()
	local hk = net.ReadString()
	local hktbl = net.ReadTable()
	hook.Call("MDM" .. hk, GAMEMODE, hktbl)
end)

--[[
local LastHB

hook.Add("Think", "PlayerEmitHeartbeat", function()
	local BeatsPerSecond = LocalPlayer():GetHeartbeat() / 60
	if BeatsPerSecond <= 0 then return end

	if not LastHB or LastHB < (CurTime() - BeatsPerSecond) then
		LocalPlayer():EmitSound("player/heartbeat1.wav")
		LastHB = CurTime()
	end
end)

]]

-- Heartbeat player/heartbeat1.wav

