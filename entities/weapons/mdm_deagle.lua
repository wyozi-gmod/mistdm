if SERVER then
   AddCSLuaFile()
end

SWEP.HoldType        = "pistol"

if CLIENT then
   SWEP.PrintName       = "Deagle"        
   SWEP.Author          = "TTT"

   SWEP.Slot            = 1
   SWEP.SlotPos         = 1

   SWEP.Icon = "VGUI/ttt/icon_deagle"
end

SWEP.Base = "mdm_weaponbase"

SWEP.Primary.Ammo       = "AlyxGun" -- hijack an ammo type we don't use otherwise
SWEP.Primary.Recoil        = 6
SWEP.Primary.Damage = 37
SWEP.Primary.Delay = 0.6
SWEP.Primary.Cone = 0.02
SWEP.Primary.ClipSize = 8
SWEP.Primary.ClipMax = 36
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = true

SWEP.HeadshotMultiplier = 4

SWEP.AutoSpawnable      = true
SWEP.AmmoEnt = "item_ammo_revolver_ttt"
SWEP.Primary.Sound         = Sound( "Weapon_Deagle.Single" )

SWEP.UseHands        = true
SWEP.ViewModelFlip      = false
SWEP.ViewModelFOV    = 54
SWEP.ViewModel       = "models/weapons/cstrike/c_pist_deagle.mdl"
SWEP.WorldModel         = "models/weapons/w_pist_deagle.mdl"

SWEP.IronSightsPos = Vector(-6.361, -3.701, 2.15)
SWEP.IronSightsAng = Vector(0, 0, 0)

SWEP.MDMData = {
   stats = {},
   space = 30,
   model = "models/weapons/w_pist_deagle.mdl",
   name = "Desert Eagle",
   desc = "A powerful pistol."
}
