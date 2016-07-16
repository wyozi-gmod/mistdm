if SERVER then
   AddCSLuaFile()
end

SWEP.HoldType = "slam"

if CLIENT then

   SWEP.PrintName = "Spidertag"
   SWEP.Slot = 2

   SWEP.Icon = "VGUI/ttt/icon_mac"
end


SWEP.Base = "mdm_weaponbase"


SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel  = "models/weapons/c_bugbait.mdl"
SWEP.WorldModel = "models/weapons/w_bugbait.mdl"

SWEP.IronSightsPos = Vector(-8.921, -9.528, 2.9)
SWEP.IronSightsAng = Vector(0.699, -5.301, -7)

SWEP.MDMCrosshair = false

SWEP.DeploySpeed = 3

SWEP.MDMData = {
   stats = {},
   space = 50,
   model = "models/weapons/w_bugbait.mdl",
   name = "Spidertag",
   desc = "Allows you to stick to roofs. Attach to ceiling and crouchjump."
}

local Laser = Material( "cable/xbeam" )


function SWEP:Setup(ply)
   if not CLIENT then return end

   if ply.GetViewModel and ply:GetViewModel():IsValid() then
   local attachmentIndex = ply:GetViewModel():LookupAttachment("muzzle")
   if attachmentIndex == 0 then attachmentIndex = ply:GetViewModel():LookupAttachment("1") end
      if LocalPlayer():GetAttachment(attachmentIndex) then
         self.VM = ply:GetViewModel()
         self.Attach = attachmentIndex
      end
   end
   if ply:IsValid() then
      local attachmentIndex = ply:LookupAttachment("anim_attachment_RH")
      if ply:GetAttachment(attachmentIndex) then
         self.WM = ply
         self.WAttach = attachmentIndex
      end
   end
end
function SWEP:Initialize()
   self:Setup(self:GetOwner())
end
function SWEP:Deploy(ply)
   self:Setup(self:GetOwner())
end

function SWEP:GetTagPos()
   local tp = self:GetNWVector("TagPos")
   if tp == Vector(0, 0, 0) then return nil end
   return tp
end

function SWEP:PrimaryAttack()
   if self:GetTagPos() then
      self:SetNWVector("TagPos", Vector(0, 0, 0))
      return
   end
   self.Owner:LagCompensation( true )
   local tr = self.Owner:GetEyeTrace()
   self.Owner:LagCompensation(false)
   if (tr.Hit and not tr.Entity:IsPlayer() and tr.HitPos:Distance(self.Owner:GetPos()) < 500) then
      local pos = tr.HitPos
      self:SetNWVector("TagPos", pos)

      self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
      self.Owner:SetAnimation( PLAYER_ATTACK1 )
   else
      self:SetNWVector("TagPos", Vector(0, 0, 0))
   end
end

function SWEP:Think()
   if SERVER and self:GetTagPos() and self.Owner:KeyDown(IN_DUCK) then
      local diff = self:GetTagPos() - self.Owner:GetPos()
      local norm = diff:GetNormalized()

      local horizdist = Vector(diff.x, diff.y, 0):Length()
      if horizdist < 200 then
         norm.x = 0
         norm.y = 0
      end

      local vvel = norm * 5

         local zVel = self.Owner:GetVelocity().z
         local gravity = GetConVarNumber("sv_Gravity")
         vvel:Add(Vector(0,0,(gravity/100)*1.5)) -- Player speed. DO NOT MESS WITH THIS VALUE!
         if(zVel < 0) then
            vvel:Sub(Vector(0,0,zVel/100))
         end

      self.Owner:SetVelocity(vvel)
   end
end

function SWEP:SecondaryAttack()
   self:SetNWVector("TagPos", Vector(0, 0, 0))
end


function SWEP:GetWepPos()
   return self.VM and self.VM:GetAttachment(self.Attach).Pos or (self:GetPos())
end

function SWEP:ViewModelDrawn()
   if self:GetTagPos() then
      render.SetMaterial( Laser )

      render.DrawBeam( self:GetWepPos(), self:GetTagPos(), 8, 0, 12.5, Color(255, 0, 0, 255) ) 
   end
end

function SWEP:DrawWorldModel()
   self.Weapon:DrawModel()

   if self:GetTagPos() then
      render.SetMaterial( Laser )

      local posang = self.WM and self.WM:GetAttachment(self.WAttach) or nil
      local pos
      if posang then
         pos = posang.Pos + posang.Ang:Forward()*10 + posang.Ang:Up()*4.4 + posang.Ang:Right()
      else
         pos = self:GetWepPos()
      end
      render.DrawBeam( pos, self:GetTagPos(), 8, 0, 12.5, Color(255, 0, 0, 255) ) 
   end
end