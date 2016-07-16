function GetPlayerFeetTrace(me)
	local pos = me:EyePos()
	local ang = me:EyeAngles()
	local down = -ang:Up()

	return util.TraceLine({start = pos, endpos =pos + down * 30, filter = me })
end

ValidMDMModels = {
	"models/player/alyx.mdl",
	"models/player/Eli.mdl",
	"models/player/monk.mdl",
	"models/player/mossman.mdl",
	"models/player/kleiner.mdl",
	"models/player/odessa.mdl",
	"models/player/gman_high.mdl",
	"models/player/breen.mdl",
	"models/player/Barney.mdl"
}

StatInfos = {
	["MuteFootsteps"] = {
		isGood = function(val) return val end
	},
	["HealRate"] = {
		isGood = function(val) return val > 1 end
	},
	["TimeTillHeal"] = {
		isGood = function(val) return val < 1 end
	},
	["HudDebris"] = {
		isGood = function(val) return val < 1 end
	},
	["BunnyhopHelper"] = {
		isGood = function(val) return val end
	},
	["Longjumper"] = {
		isGood = function(val) return val end
	},
	["HudShowVitalStats"] = {
		isGood = function(val) return val end
	},
	["HudShowTeam"] = {
		isGood = function(val) return val end
	},
	["HudsShowEnemies"] = {
		isGood = function(val) return val end
	},
	["HudShowMinimap"] = {
		isGood = function(val) return val end
	},
	["Flashlight"] = {
		isGood = function(val) return val end
	},
	["NoFalldmg"] = {
		isGood = function(val) return val end
	},
	["RedDotSight"] = {
		isGood = function(val) return val end
	},
	["HudShowCrosshair"] = {
		isGood = function(val) return val end
	},
	["SpreadModifier"] = {
		isGood = function(val) return val < 1 end
	},
	["SprintSpreadModifier"] = {
		isGood = function(val) return val < 1 end
	},
	["RecoilModifier"] = {
		isGood = function(val) return val < 1 end
	},
	["DamageModifier"] = {
		isGood = function(val) return val < 1 end
	}
}