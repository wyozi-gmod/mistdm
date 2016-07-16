-- Custom weapon base, used to derive from CS one, still very similar

if SERVER then
   AddCSLuaFile( )
end

if CLIENT then
   SWEP.DrawCrosshair   = false
   SWEP.ViewModelFOV    = 82
   SWEP.ViewModelFlip   = true
   SWEP.CSMuzzleFlashes = true
end

SWEP.Base = "mdm_base"

SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

SWEP.IsGrenade = false

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.MDMCrosshair = true

SWEP.Primary.Sound          = Sound( "Weapon_Pistol.Empty" )
SWEP.Primary.Recoil         = 1.5
SWEP.Primary.Damage         = 1
SWEP.Primary.NumShots       = 1
SWEP.Primary.Cone           = 0.02
SWEP.Primary.Delay          = 0.15

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "none"
SWEP.Primary.ClipMax        = -1

SWEP.Secondary.ClipSize     = 1
SWEP.Secondary.DefaultClip  = 1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.ClipMax      = -1

SWEP.HeadshotMultiplier = 2.7

SWEP.StoredAmmo = 0
SWEP.IsDropped = false

SWEP.DeploySpeed = 1.4

SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK
SWEP.ReloadAnim = ACT_VM_RELOAD


local function AccessorFuncDT(tbl, varname, name) -- TODO lel
   tbl["Get" .. name] = function(s) return s.dt and s.dt[varname] end
   tbl["Set" .. name] = function(s, v) if s.dt then s.dt[varname] = v end end
end

AccessorFuncDT(SWEP, "ironsights", "Ironsights")

-- crosshair
if CLIENT then

   function SWEP:DrawHUD()

      if not self.MDMCrosshair or not self.Owner:HasStat("HudShowCrosshair") then return end

      local client = LocalPlayer()

      local sights = self:GetIronsights()

      local x = ScrW() / 2.0
      local y = ScrH() / 2.0
      local scale = math.max(0.2,  10 * self:GetPrimaryCone())

      local LastShootTime = self.Weapon:LastShootTime()
      scale = scale * (2 - math.Clamp( (CurTime() - LastShootTime) * 5, 0.0, 1.0 ))

      --[[local LastSprintTime = self.LastSprintTime
      if LastSprintTime then
         scale = scale * (2 - math.Clamp( (CurTime() - LastSprintTime) * 5, 0.0, 1.0 ))
      end]]

      local alpha = sights and 0.8 or 1

      surface.SetDrawColor(255,
                           255,
                           255,
                           255 * alpha)

      local gap = 50 * scale
      local length = gap + 25 * 0.3
      surface.DrawLine( x - length, y, x - gap, y )
      surface.DrawLine( x + length, y, x + gap, y )
      surface.DrawLine( x, y - length, x, y - gap )
      surface.DrawLine( x, y + length, x, y + gap )

      if self.HUDHelp then
         self:DrawHelp()
      end
   end
end

-- Shooting functions largely copied from weapon_cs_base
function SWEP:PrimaryAttack(worldsnd)

   self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
   self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

   if not self:CanPrimaryAttack() or self:IsOwnerSprinting() then return end

   if not worldsnd then
      self.Weapon:EmitSound( self.Primary.Sound, self.Primary.SoundLevel )
   elseif SERVER then
      sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
   end

   self:ShootBullet( self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone() )

   self:TakePrimaryAmmo( 1 )

   local owner = self.Owner
   if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end

   owner:ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0 ) )
end

function SWEP:DryFire(setnext)
   if CLIENT and LocalPlayer() == self.Owner then
      self:EmitSound( "Weapon_Pistol.Empty" )
   end

   setnext(self, CurTime() + 0.2)

   self:Reload()
end

function SWEP:CanPrimaryAttack()
   if not IsValid(self.Owner) then return end

   if self.Weapon:Clip1() <= 0 then
      self:DryFire(self.SetNextPrimaryFire)
      return false
   end
   return true
end

function SWEP:CanSecondaryAttack()
   if not IsValid(self.Owner) then return end

   if self.Weapon:Clip2() <= 0 then
      self:DryFire(self.SetNextSecondaryFire)
      return false
   end
   return true
end

local function Sparklies(attacker, tr, dmginfo)
   if tr.HitWorld and tr.MatType == MAT_METAL then
      local eff = EffectData()
      eff:SetOrigin(tr.HitPos)
      eff:SetNormal(tr.HitNormal)
      util.Effect("cball_bounce", eff)
   end
end

function SWEP:IsOwnerSprinting()
   return self.Owner:IsSprinting() and self.Owner:GetVelocity():Length() > 200
end

function SWEP:ShootBullet( dmg, recoil, numbul, cone )

   self.Weapon:SendWeaponAnim(self.PrimaryAnim)

   self.Owner:MuzzleFlash()
   self.Owner:SetAnimation( PLAYER_ATTACK1 )

   if not IsFirstTimePredicted() then return end

   local sights = self:GetIronsights()

   numbul = numbul or 1
   cone   = cone   or 0.01

   local bullet = {}
   bullet.Num    = numbul
   bullet.Src    = self.Owner:GetShootPos()
   bullet.Dir    = self.Owner:GetAimVector()
   bullet.Spread = Vector( cone, cone, 0 )
   bullet.Tracer = 4
   bullet.TracerName = self.Tracer or "Tracer"
   bullet.Force  = 10
   bullet.Damage = dmg
   if CLIENT then
      bullet.Callback = Sparklies
   end

   self.Owner:FireBullets( bullet )

   -- Owner can die after firebullets
   if (not IsValid(self.Owner)) or (not self.Owner:Alive()) or self.Owner:IsNPC() then return end

   if ((game.SinglePlayer() and SERVER) or
       ((not game.SinglePlayer()) and CLIENT and IsFirstTimePredicted())) then

      -- reduce recoil if ironsighting
      recoil = sights and (recoil * 0.6) or recoil
      recoil = recoil * self.Owner:GetStatMul("RecoilModifier")

      local eyeang = self.Owner:EyeAngles()
      eyeang.pitch = eyeang.pitch - recoil
      self.Owner:SetEyeAngles( eyeang )
   end

end

function SWEP:GetPrimaryCone()
   local cone = self.Primary.Cone or 0.2
   -- accuracy bonus when sighting
   if self:GetIronsights() then
      cone = cone * 0.65
   end
   -- accuracy bonus when crouching
   if self.Owner:KeyDown( IN_DUCK ) then
      cone = cone * 0.8
   end
   if self:IsOwnerSprinting() then
      cone = cone * 9 * self.Owner:GetStatMul("SprintSpreadModifier")
   end
   return cone * self.Owner:GetStatMul("SpreadModifier")
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)
   return self.HeadshotMultiplier or 2
end

function SWEP:IsEquipment()
   return WEPS.IsEquipment(self)
end

function SWEP:DrawWeaponSelection() end

function SWEP:SecondaryAttack()
   if self.NoSights or (not self.IronSightsPos) then return end
   if self:IsOwnerSprinting() then return end
   --if self:GetNextSecondaryFire() > CurTime() then return end


   self:SetNextSecondaryFire(CurTime() + 0.3)
end

function SWEP:Deploy()
   self:SetIronsights(false)
   return true
end

function SWEP:Reload()
   self.Weapon:DefaultReload(self.ReloadAnim)
   self:SetIronsights( false )
end


function SWEP:OnRestore()
   self.NextSecondaryAttack = 0
   self:SetIronsights( false )
end

function SWEP:Ammo1()
   return IsValid(self.Owner) and self.Owner:GetAmmoCount(self.Primary.Ammo) or false
end

-- The OnDrop() hook is useless for this as it happens AFTER the drop. OwnerChange
-- does not occur when a drop happens for some reason. Hence this thing.
function SWEP:PreDrop()
   if SERVER and IsValid(self.Owner) and self.Primary.Ammo != "none" then
      local ammo = self:Ammo1()

      -- Do not drop ammo if we have another gun that uses this type
      for _, w in pairs(self.Owner:GetWeapons()) do
         if IsValid(w) and w != self and w:GetPrimaryAmmoType() == self:GetPrimaryAmmoType() then
            ammo = 0
         end
      end

      self.StoredAmmo = ammo

      if ammo > 0 then
         self.Owner:RemoveAmmo(ammo, self.Primary.Ammo)
      end
   end
end

function SWEP:DampenDrop()
   -- For some reason gmod drops guns on death at a speed of 400 units, which
   -- catapults them away from the body. Here we want people to actually be able
   -- to find a given corpse's weapon, so we override the velocity here and call
   -- this when dropping guns on death.
   local phys = self:GetPhysicsObject()
   if IsValid(phys) then
      phys:SetVelocityInstantaneous(Vector(0,0,-75) + phys:GetVelocity() * 0.001)
      phys:AddAngleVelocity(phys:GetAngleVelocity() * -0.99)
   end
end

local SF_WEAPON_START_CONSTRAINED = 1

-- Picked up by player. Transfer of stored ammo and such.
function SWEP:Equip(newowner)
   if SERVER then
      if self:IsOnFire() then
         self:Extinguish()
      end

      self.fingerprints = self.fingerprints or {}

      if not table.HasValue(self.fingerprints, newowner) then
         table.insert(self.fingerprints, newowner)
      end

      if self:HasSpawnFlags(SF_WEAPON_START_CONSTRAINED) then
         -- If this weapon started constrained, unset that spawnflag, or the
         -- weapon will be re-constrained and float
         local flags = self:GetSpawnFlags()
         local newflags = bit.band(flags, bit.bnot(SF_WEAPON_START_CONSTRAINED))
         self:SetKeyValue("spawnflags", newflags)
      end
   end

   if SERVER and IsValid(newowner) and self.StoredAmmo > 0 and self.Primary.Ammo != "none" then
      local ammo = newowner:GetAmmoCount(self.Primary.Ammo)
      local given = math.min(self.StoredAmmo, self.Primary.ClipMax - ammo)

      newowner:GiveAmmo( given, self.Primary.Ammo)
      self.StoredAmmo = 0
   end
end

-- We were bought as special equipment, some weapons will want to do something
-- extra for their buyer
function SWEP:WasBought(buyer)
end

-- Set up ironsights dt bool. Weapons using their own DT vars will have to make
-- sure they call this.
function SWEP:SetupDataTables()
   -- Put it in the last slot, least likely to interfere with derived weapon's
   -- own stuff.
   self:DTVar("Bool", 3, "ironsights")
end

function SWEP:Initialize()
   if CLIENT and self.Weapon:Clip1() == -1 then
      self.Weapon:SetClip1(self.Primary.DefaultClip)
   elseif SERVER then
      self:SetIronsights(false)
   end

   self:SetDeploySpeed(self.DeploySpeed)

   -- compat for gmod update
   if self.SetWeaponHoldType then
      self:SetWeaponHoldType(self.HoldType or "pistol")
   end

end

function SWEP:Think()
   if SERVER then
      local amnt = 999 - self:Ammo1()
      if amnt > 0 then
         self.Owner:GiveAmmo( amnt, self.Primary.Ammo)
      end
   end

   self:SetIronsights( self.Owner:KeyDown( IN_ATTACK2 ) and not self:IsOwnerSprinting() )

   if self:IsOwnerSprinting() then
      self.LastSprintTime = CurTime()
      if SERVER and not self.LF then
         self.Owner:SetFOV(88, 0.3)
         self.LF = true
      end
   else
      if SERVER and self.LF then
         self.Owner:SetFOV(0, 0.3)
         self.LF = false
      end
   end

   if CLIENT then

      local velMulti = 0.001
      local ply = self.Owner

      local tVelocity = ply:GetVelocity()
      local tAngles = ply:EyeAngles()

      local tvelle = math.max(tVelocity:Length(), self:GetIronsights() and 50 or 0)
      local fMulti = tvelle * velMulti
      local timeMulti = self:GetIronsights() and 0.1 or 1

      local bTilt, bBop = self:IsOwnerSprinting(), true

      if (bTilt) then
         local fPitch = 0.0
         if (ply:OnGround()) then
             if (ply:KeyDown(IN_MOVERIGHT) and not ply:KeyDown(IN_MOVELEFT)) then
                 fPitch = 75.0
             elseif (ply:KeyDown(IN_MOVELEFT)) then
                 fPitch = -75.0
             end
         end
         
         if (fPitch != 0.0) then
             ply.headbop_val = (ply.headbop_val or 0.0) + fMulti * fPitch * 0.07
             ply.headbop_val = math.min(ply.headbop_val, 100.0)
             ply.headbop_val = math.max(ply.headbop_val, -100.0)
         else
             ply.headbop_val = (ply.headbop_val or 0.0) * 0.9
         end
         local fRoll = math.sin(ply.headbop_val / 100.0 * math.pi / 2.0) * 3.0
         
         tAngles.r = fRoll

      else
         tAngles.r = 0
      end

      if (ply:OnGround() and bBop) then
         tAngles.p = tAngles.p + math.sin(CurTime()*14.0*timeMulti)*0.1 * fMulti
      end

      ply:SetEyeAngles(tAngles)
   end
end

if CLIENT then
   local LaserDot = Material( "Sprites/light_glow02_add" )

   hook.Add( "RenderScreenspaceEffects", "LASERPOINTER.RenderScreenspaceEffects", function()
     for k,v in ipairs( player.GetAll() ) do
         local weap = v:GetActiveWeapon()
         
         if IsValid( weap ) and weap.MDMCrosshair and v:HasStat("RedDotSight") then
             cam.Start3D( EyePos(), EyeAngles() )
                 local color = Color(255,0,0,255)
                 local shootpos = v:GetShootPos()
                 local ang = v:GetAimVector()
                 
                 local tr = {}
                 tr.start = shootpos
                 tr.endpos = shootpos + ( ang * 999999 )
                 tr.filter = v
                 tr.mask = MASK_SHOT
                 
                 local trace = util.TraceLine( tr )
                 local Size = 4 + ( math.random() * 10 )
                 local beamendpos = trace.HitPos
                 
                 render.SetMaterial( LaserDot )
                 render.DrawQuadEasy( beamendpos + trace.HitNormal * 0.5, trace.HitNormal, Size, Size, color, 0 )
                 render.DrawQuadEasy( beamendpos + trace.HitNormal * 0.5, trace.HitNormal * -1, Size, Size, color, 0 )
                 
             cam.End3D()
         end
     end
   end )

   local IRONSIGHT_TIME = 0.15
   function SWEP:GetViewModelPosition( pos, ang )

      if self:IsOwnerSprinting() then
         --pos = pos + (-2) * ang:Up()
         ang = ang * 1
         self.TargetPitch = -10

         local ply = self.Owner
         if (ply:KeyDown(IN_MOVERIGHT) and not ply:KeyDown(IN_MOVELEFT)) then
            self.TargetYaw = 5
         elseif (ply:KeyDown(IN_MOVELEFT)) then
            self.TargetYaw = -5
         end
      else
         self.TargetPitch = 0
         self.TargetYaw = 0
      end

      self.TrailPitch = math.Approach(self.TrailPitch or 0, self.TargetPitch, 0.2)
      self.TrailYaw = math.Approach(self.TrailYaw or 0, self.TargetYaw, 0.1)

      ang:RotateAroundAxis(ang:Right(), self.TrailPitch or 0)
      ang:RotateAroundAxis(ang:Up(), self.TrailYaw or 0)

      if not self.IronSightsPos then return pos, ang end

      local bIron = self:GetIronsights()

      if bIron != self.bLastIron then
         self.bLastIron = bIron
         self.fIronTime = CurTime()

         if bIron then
            self.SwayScale = 0.3
            self.BobScale = 0.1
         else
            self.SwayScale = 1.0
            self.BobScale = 1.0
         end

      end

      local fIronTime = self.fIronTime or 0
      if (not bIron) and fIronTime < CurTime() - IRONSIGHT_TIME then
         return pos, ang
      end

      local mul = 1.0

      if fIronTime > CurTime() - IRONSIGHT_TIME then

         mul = math.Clamp( (CurTime() - fIronTime) / IRONSIGHT_TIME, 0, 1 )

         if not bIron then mul = 1 - mul end
      end

      local offset = self.IronSightsPos +  vector_origin

      if self.IronSightsAng then
         ang = ang * 1
         ang:RotateAroundAxis( ang:Right(),    self.IronSightsAng.x * mul )
         ang:RotateAroundAxis( ang:Up(),       self.IronSightsAng.y * mul )
         ang:RotateAroundAxis( ang:Forward(),  self.IronSightsAng.z * mul )
      end

      pos = pos + offset.x * ang:Right() * mul
      pos = pos + offset.y * ang:Forward() * mul
      pos = pos + offset.z * ang:Up() * mul

      return pos, ang
   end
end