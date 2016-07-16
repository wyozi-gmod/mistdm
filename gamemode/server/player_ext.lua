local meta = FindMetaTable("Player")

function meta:IsDamaged()
	return self:Health() < self:GetMaxHealth()
end

function meta:TimeSinceDamageTaken()
	return (not self.LastDamageTaken) and 99999 or (CurTime() - self.LastDamageTaken)
end

function meta:IsInItemMenu()
	return self.InItemMenu
end

util.AddNetworkString("mdm_statupd")
function meta:UpdateStat(stat, diff)
	net.Start("mdm_statupd")
		net.WriteString(stat)
		net.WriteInt(diff, 16)
	net.Send(self)
end