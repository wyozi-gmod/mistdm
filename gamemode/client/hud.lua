
surface.CreateFont("InfoPaints", {font = "Trebuchet24",
                                    size = 28,
                                    weight = 1000})

-- Paints player status HUD element in the bottom left
function GM:HUDPaint()
   local client = LocalPlayer()

   if client:Alive() and not client:IsSpec() then
    DrawColorMod(client)
    DrawMotionBlurMod(client)
    DrawInfoPaint(client)
    DrawScreenBlood(client)
   end

end

-- Hide the standard HUD stuff
local hud = {"CHudHealth", "CHudBattery", "CHudAmmo", "CHudSecondaryAmmo"}
function GM:HUDShouldDraw(name)

   for k, v in pairs(hud) do
      if name == v then return false end
   end

   return true
end


function DrawScreenBlood(client)
    if (client.ScreenBloodEnts == nil) then return end

    local health = client:Health()

    for index,data in ipairs(client.ScreenBloodEnts) do

        if (health >= data.ehp) then
            table.remove(client.ScreenBloodEnts, index)
            if (#client.ScreenBloodEnts <= 0) then
                client.ScreenBloodEnts = nil
                return
            end
        else
            local fPercentage = (health - data.shp) / (data.ehp - data.shp)
        
            local strPath = data.version == 2 and "sprites/screensplatter/blood_screen02" or "sprites/screensplatter/blood_screen01"
        
            local blood = surface.GetTextureID(strPath)
            surface.SetTexture(blood)
            surface.SetDrawColor(255, 255, 255, 200.0 * (1.0-(fPercentage * fPercentage * fPercentage)) * data.alpha)
            
            //local fFall =  (1.0 + fPercentage*0.2)
            local x = ScrW() * data.posx
            local y = ScrH() * data.posy

            local size = data.size * 0.6
            local screenscale = (ScrW() + ScrH()) / 2.0
            surface.DrawTexturedRectRotated(x, y, screenscale*size, screenscale*size, data.angle)
        end
    end
end


function DrawColorMod(client)
    local panic = 1 - client:Health() / 100 -- assume max health
    panic = panic + 0.2
    panic = panic * client:GetStatMul("HudDebris")
    
    local fScale = 3

    local tab = {}
    
    local fColor = 1.0
    fColor = fColor * (1.0 - math.min(panic*fScale, 1.0))
    
    local wep = client:GetActiveWeapon()
    if IsValid(wep) and wep:GetIronsights() then
        local fZoom = 0.6
        if (wep.ZoomInit and wep.ZoomTime) then
            local fDifference = CurTime() - wep.ZoomInit
            local fPercentage = fDifference / wep.ZoomTime
            fPercentage = math.max(fPercentage, 0.0)
            fPercentage = math.min(fPercentage, 1.0)
            fZoom = 1.0 - (fPercentage * 0.35)
            panic = panic + fPercentage * 0.15
        end
        fColor = fColor * fZoom
    end
    
    panic = math.max(panic, 0.0)
    panic = math.min(panic, 1.0)
    
    tab[ "$pp_colour_addr" ] = 0;
    tab[ "$pp_colour_addg" ] = 0;
    tab[ "$pp_colour_addb" ] = 0;
    tab[ "$pp_colour_brightness" ] = -0.075 * panic * fScale;
    tab[ "$pp_colour_contrast" ] = 1 + ( 0.385 * panic * fScale );
    tab[ "$pp_colour_colour" ] = fColor;
    tab[ "$pp_colour_mulr" ] = 1;
    tab[ "$pp_colour_mulg" ] = 1; 
    tab[ "$pp_colour_mulb" ] = 1;
    
    DrawColorModify( tab );
end

function DrawMotionBlurMod(client)
    local fBlur = 1 - client:Health() / 100 -- assume max health
    fBlur = fBlur / 5 -- reduce effect
    if client:IsSprinting() then
      fBlur = fBlur + 0.3
    end
    fBlur = fBlur * client:GetStatMul("HudDebris")
    if (fBlur <= 0.3) then return end
    
    local fBlurNeg = (1.0 - fBlur*0.7)
    local fFade = 1.0
    fFade = fFade * fBlurNeg
    fFade = fFade * fBlurNeg
    fFade = fFade * fBlurNeg
    fFade = fFade * fBlurNeg
    fFade = fFade * fBlurNeg
    fFade = fFade * fBlurNeg
    fFade = math.max(fFade, 0.02)
    DrawMotionBlur(fFade, 1.0, 0.0)
end

net.Receive("mdm_blood", function()

  local hPlayer = LocalPlayer()
  local debrismul = hPlayer:GetStatMul("HudDebris")
  local fDamage = net.ReadFloat()
  local max = net.ReadUInt(16)
  fDamage = math.min(fDamage, 40)

  local fScale = 1
  fScale = math.max(fScale, 0.0)
  fScale = math.min(fScale, 10.0)

  fDamage = fDamage * fScale
  if (fDamage <= 0) then return end

  local iBlood = math.ceil(fDamage / 15.0)

  local i = 1
  for i=1,iBlood do
    if (hPlayer.ScreenBloodEnts == nil) then
        hPlayer.ScreenBloodEnts = {}
    end

    local blood = {}
    blood.time = CurTime()

    blood.shp = hPlayer:Health() - fDamage
    blood.ehp = math.min(max, blood.shp + math.random(3, 30)*debrismul)

    blood.size = math.random(400, 1000)/1000.0

    local fAngle = math.random(0, math.pi*2 * 100)/100.0
    local fDistance = math.random(30.0, 80.0) / 100.0
    blood.posx = 0.5 + math.cos(fAngle)*fDistance
    blood.posy = 0.5 + math.sin(fAngle)*fDistance
    blood.version = math.random(1, 2)
    blood.angle = math.random(0, 360)
    blood.alpha = math.random(90, 100)/100.0 * debrismul

    table.insert(hPlayer.ScreenBloodEnts, blood)
  end
end)


-- Returns player's ammo information
local function GetAmmo(ply)
   local weap = ply:GetActiveWeapon()
   if not weap or not ply:Alive() then return -1 end

   local ammo_inv = weap:Ammo1()
   local ammo_clip = weap:Clip1()
   local ammo_max = weap.Primary.ClipSize

   return ammo_clip, ammo_max, ammo_inv
end

function DrawInfoPaint(client)
    if client:GetActiveWeapon().Primary then
        local ammo_clip, ammo_max, ammo_inv = GetAmmo(client)
        if ammo_clip != -1 then
            draw.SimpleText(string.format("%i + %02i", ammo_clip, ammo_inv), "InfoPaints", ScrW() - 10, ScrH() - 10, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end
    end

    DrawExtraHuds(client)

end

local sin, cos, atan2, rad = math.sin, math.cos, math.atan2, math.rad
local function RotateVector(vec, angle)
  local x, y, x_origin, y_origin = vec.x, vec.y, 0, 0
  return Vector(((x - x_origin) * cos(angle)) - ((y_origin - y) * sin(angle)), ((y_origin - y) * cos(angle)) - ((x - x_origin) * sin(angle)), 0)
end

local function GeneratePolyCircle(x,y,radius,quality)
    local circle = {};
    local tmp = 0;
    for i=1,quality do
        tmp = rad(i*360)/quality
        circle[i] = {x = x + cos(tmp)*radius,y = y + sin(tmp)*radius};
    end
    return circle;
end

local function LerpNumber(num, num1, num2)
  return num1 + (num2-num1)*num
end

local function LerpColor(num, clr1, clr2)
  return Color(LerpNumber(num, clr1.r, clr2.r), LerpNumber(num, clr1.g, clr2.g), LerpNumber(num, clr1.b, clr2.b), LerpNumber(num, clr1.a, clr2.a))
end

local RadarCircles = {}
for i=0, 100, 20 do
  RadarCircles[i] = GeneratePolyCircle(150, 150, i, 20)
end


function DrawExtraHuds(client)
  if client:HasStat("HudShowVitalStats") then
    --draw.SimpleText("HP: " .. tostring(client:Health()), "InfoPaints", ScrW() /2, ScrH() / 2, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    --draw.SimpleText("Heart rate: " .. tostring(client:GetHeartbeat()), "InfoPaints", ScrW() /2, ScrH() / 2 - 100, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
  end
  --if client:HasStat("HudShowMinimap") then
    
    for i=0, 100, 20 do
      surface.SetDrawColor(Color(0, 255 * (1 - i/100), 0, 170 * (i/100)))
      surface.DrawPoly(RadarCircles[i])
      --surface.DrawCircle(150, 150, i, Color(0, 255 * (1 - i/100), 0))
    end

    local miangle = client:EyeAngles():Forward()
    miangle.z = 0
    miangle:Normalize()

    local angle1 = atan2(miangle.y, miangle.x)

    local rotated = RotateVector(miangle, angle1)

    surface.DrawLine(150, 150, 150, 150 - 20)

    local function TestAng(pos, clr)
      local diff = pos - LocalPlayer():GetPos()
      diff = diff / 10

      local length = diff:Length()
      if length > 100 then
        return
      end
      local angle2 = atan2(diff.y, diff.x)
      local tangle = angle1 - angle2 - math.pi/2

      local levector = Vector(cos(tangle) * length, sin(tangle) * length, 0)

      surface.DrawCircle(150 + levector.x, 150 + levector.y, 5, clr)
    end

    for _,ply in pairs(player.GetAll()) do
      local clr
      if ply == LocalPlayer() or not ply.LSPos or not ply:Alive() or ply:IsSpec() then
        continue
      elseif ply.CriticalShow and ply.CriticalShow > CurTime() then
        clr = LerpColor(math.Clamp(ply.CriticalShow - CurTime(), 0, 1), Color(255, 0, 0, 0), Color(255, 0, 0, 255))
      elseif ply:Team() == LocalPlayer():Team() then
        clr = Color(0, 255, 0)
      else
        clr = LerpColor(math.Clamp(ply.LSUpd - CurTime() + 2, 0, 1), Color(100, 100, 100), Color(255, 127, 0))
      end
      TestAng(ply.LSPos, clr)
    end
    TestAng(LocalPlayer():GetPos(), Color(0, 0, 255))

  --end
end

hook.Add("MDMCritRadar", "NOWWORK", function(tbl)
  for _,ply in pairs(tbl) do
    if IsValid(ply) then
      ply.CriticalShow = CurTime() + 2
    end
  end
end)

hook.Add("MDMPrepareRound", "NOWWORK", function(tbl)
  for _,ply in pairs(player.GetAll()) do
    ply.CriticalShow = 0
    ply.LSPos = nil
    ply.LSUpd = 0
  end
end)

timer.Create("RadarUpdater", 1, 0, function()
  if not LocalPlayer():HasStat("HudShowMinimap") then return end

  local lpos = LocalPlayer():EyePos()
  local lteam = LocalPlayer():Team()

  -- TODO dont update if ironsights or something to allow silent knifing

  for _,ply in pairs(player.GetAll()) do
    if ply:Team() == TEAM_SPEC then continue end
    if ply:Team() == lteam then
      ply.LSPos = ply:GetPos()
      ply.LSUpd = CurTime()
    else
      local trace = { start = lpos, endpos = ply:EyePos(), filter = ply }
      local tr = util.TraceLine( trace )

      if not tr.Hit then
        ply.LSPos = ply:GetPos()
        ply.LSUpd = CurTime()
      end 
    end
  end
end)

-- TODO only show enemies in radar if their in LOS or they've shot recently

local HudFxMat = CreateMaterial( "HudFxMat", "VertexLitGeneric", { ["$basetexture"] = "models/debug/debugwhite", ["$model"] = 1, ["$ignorez"] = 1 } ); --Last minute change

local function AddToColor(color, add)
  return color + add <= 255 and color + add or color + add - 255
end

hook.Add("RenderScreenspaceEffects", "HudFx", function()

    local steam, senemies = LocalPlayer():HasStat("HudShowTeam"), LocalPlayer():HasStat("HudShowEnemies")

    if not steam and not senemies then return end

    for _, ply in pairs( player.GetAll() ) do
      local equalteam = ply:Team() == LocalPlayer():Team()

      if (ply != LocalPlayer() && ply:Alive() && ply:Health() > 0 && ((senemies and not equalteam) or (steam and equalteam)) ) then
        local color = team.GetColor( ply:Team() );
        
        cam.Start3D( LocalPlayer():EyePos(), LocalPlayer():EyeAngles() );
          render.SuppressEngineLighting( true );
          render.SetColorModulation( color.r/255, color.g/255, color.b/255, 1 );
          render.MaterialOverride( HudFxMat );
          ply:DrawModel();
          render.SetColorModulation( AddToColor( color.r, 150 )/255, AddToColor( color.g, 150 )/255, AddToColor( color.b, 150 )/255, 1 );
          
          if (IsValid( ply:GetActiveWeapon() )) then
            ply:GetActiveWeapon():DrawModel() 
          end
          
          render.SetColorModulation( 1, 1, 1, 1 );
          
          render.MaterialOverride();
          render.SetModelLighting( 4, color.r/255, color.g/255, color.b/255 );
          ply:DrawModel();
          render.SuppressEngineLighting( false );
        cam.End3D();
      end
    end
end)
--[[
hook.Add("MDMHealStarted", "HudSounds", function()
  surface.PlaySound("HL1/fvox/automedic_on.wav")
end)
hook.Add("MDMHealStopped", "HudSounds", function()
  surface.PlaySound("HL1/fvox/medical_repaired.wav")
end)
]]