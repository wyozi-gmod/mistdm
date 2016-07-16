if SERVER then
   AddCSLuaFile()
end

SWEP.HoldType        = "ar2"

if CLIENT then
   SWEP.PrintName       = "AK47"        
   SWEP.Author          = "TTT"

   SWEP.Slot            = 1
   SWEP.SlotPos         = 1

   SWEP.Icon = "VGUI/ttt/icon_deagle"
end

SWEP.Base = "mdm_weaponbase"

SWEP.Primary.Delay       = 0.09
SWEP.Primary.Recoil      = 3
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 17
SWEP.Primary.Cone        = 0.025
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.ClipSize    = 25
SWEP.Primary.ClipMax     = 90
SWEP.Primary.DefaultClip = 45
SWEP.Primary.Sound       = Sound( "Weapon_AK47.Single" )

SWEP.IronSightsPos = Vector( -6.65, -5, 2.4 )
SWEP.IronSightsAng = Vector( 2.2, -0, 0 )

SWEP.UseHands        = true
SWEP.ViewModelFlip      = false
SWEP.ViewModelFOV    = 54
SWEP.ViewModel  = "models/weapons/cstrike/c_rif_ak47.mdl"
SWEP.WorldModel = "models/weapons/w_rif_ak47.mdl"

SWEP.MDMData = {
   stats = {},
   space = 50,
   model = "models/weapons/w_rif_ak47.mdl",
   name = "AK47",
   desc = "A powerful but loud and expensive rifle."
}
