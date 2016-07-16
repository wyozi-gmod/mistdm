
local draw, surface, math = draw, surface, math

local g_grds, g_wgrd, g_sz
function draw.GradientBox(x, y, w, h, al, ...)
   g_grds = {...}
   al = math.Clamp(math.floor(al), 0, 1)
   if(al == 1) then
      local t = w
      w, h = h, t
   end
   g_wgrd = w / (#g_grds - 1)
   local n
   for i = 1, w do
      for c = 1, #g_grds do
         n = c
         if(i <= g_wgrd * c) then break end
      end
      g_sz = i - (g_wgrd * (n - 1))
      surface.SetDrawColor(
         Lerp(g_sz/g_wgrd, g_grds[n].r, g_grds[n + 1].r),
         Lerp(g_sz/g_wgrd, g_grds[n].g, g_grds[n + 1].g),
         Lerp(g_sz/g_wgrd, g_grds[n].b, g_grds[n + 1].b),
         Lerp(g_sz/g_wgrd, g_grds[n].a, g_grds[n + 1].a))
      if(al == 1) then surface.DrawRect(x, y + i, h, 1)
      else surface.DrawRect(x + i, y, 1, h) end
   end
end

local tbtns
function GM:ScoreboardCreate()
   local t1btn = vgui.Create("DButton")
      t1btn:SetText("")
      t1btn.Paint = function()
         draw.GradientBox(0, 0, 400, 50, 0.5, team.GetColor(TEAM_GREEN), Color(0, 0, 0, 0))
         draw.SimpleText("Team " .. team.GetName(TEAM_GREEN), "Trebuchet24", 50, 10, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
      end
      t1btn:SetPos(0, 90)
      t1btn:SetSize(400, 50)
      t1btn.DoClick = function()
         RunConsoleCommand("mdm_setteam", "1")
      end

   local t2btn = vgui.Create("DButton")
      t2btn:SetText("")
      t2btn.Paint = function()
         draw.GradientBox(0, 0, 400, 50, 0.5, Color(0, 0, 0, 0), team.GetColor(TEAM_PURPLE))
         draw.SimpleText("Team " .. team.GetName(TEAM_PURPLE), "Trebuchet24", 350, 10, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
      end
      t2btn:SetPos(ScrW() - 400, 90)
      t2btn:SetSize(400, 50)
      t2btn.DoClick = function()
         RunConsoleCommand("mdm_setteam", "2")
      end

   tbtns = {}

   table.insert(tbtns, t1btn)
   table.insert(tbtns, t2btn)

   local t3btn = vgui.Create("DButton")
      t3btn:SetText("")
      t3btn.Paint = function()
         surface.SetDrawColor(Color(255, 255, 255, 255))
         surface.DrawRect(0, 0, 400, 50)
         draw.SimpleText("Spectator", "Trebuchet24", 200, 10, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
      end
      t3btn:SetPos(ScrW()/2 - 200, 0)
      t3btn:SetSize(400, 50)
      t3btn.DoClick = function()
         RunConsoleCommand("mdm_setteam", "3")
      end

   table.insert(tbtns, t3btn)

   local list = vgui.Create("DIconLayout")
   local midw = ScrW() / 2

   list:SetPos(midw - midw/2, ScrH() - 200)
   list:SetSize(midw, 100)
   list:SetSpaceX(5)

   local btnw = midw / 3 - 5

   if not LocalPlayer().loadouts then -- TODO Find a better place for this
      loadouts.Load()
   end

   for i=1, 3 do
      local btn = list:Add("DButton")
      btn:SetSize(btnw, 100)
         btn:SetText("Loadout #" .. tostring(i))
      --btn.DoClick = function()
      --   RunConsoleCommand("mdm_useloadout", tostring(i))
      --end
      btn.DoClick = function()

         local menu = DermaMenu()
         menu:AddOption( "Start using", function() RunConsoleCommand("mdm_useloadout", tostring(i)) end )
         menu:AddOption( "Modify", function() OpenItemMenu(i) end )
         menu:Open()
      end
      btn.Think = function()
         local txt = btn:GetText()
         local lo = LocalPlayer():GetLoadout(i)
         if lo and lo.name and lo.name ~= txt then
            btn:SetText(lo.name)
         end
      end
      
   end

   table.insert(tbtns, list)

   local modelBtn = vgui.Create("DButton")
      modelBtn:SetPos(midw - btnw/2 - 2, ScrH() - 90)
      modelBtn:SetSize(btnw, 50)

      modelBtn:SetText( "Select model" )

      modelBtn.DoClick = function()
         OpenModelSelector()
      end

   table.insert(tbtns, modelBtn)


end


function GM:ScoreboardShow()
   self.ShowScoreboard = true

   gui.EnableScreenClicker(true)
   
   if not tbtns then
      self:ScoreboardCreate()
   end
   table.foreach(tbtns, function(k, v) v:SetVisible(true) end)
end

function GM:ScoreboardHide()
   self.ShowScoreboard = false

   gui.EnableScreenClicker(false)

   table.foreach(tbtns, function(k, v) v:SetVisible(false) end)

end

local function DrawPlayers(x, xalign, y, nteam)
   local plys = team.GetPlayers(nteam)
   local clr = team.GetColor(nteam)

   local startx = x
   local xmul = 1
   if xalign == TEXT_ALIGN_LEFT then
      startx = x-60
      xmul = 1
   elseif xalign == TEXT_ALIGN_RIGHT then
      startx = ScrW() - 400
      xmul = -1
   end

   for _, ply in pairs(plys) do

      local cx = x

      draw.RoundedBox(6, startx, y, 410, 30, Color(clr.r, clr.g, clr.b, 50))
      draw.SimpleText(ply:Nick(), "Trebuchet24", cx, y+2, Color(255, 255, 255), xalign, TEXT_ALIGN_BOTTOM)

      cx = cx + (xmul * 275)

      surface.SetMaterial(Material("gui/silkicons/world"))
      surface.SetDrawColor(Color(255, 255, 255))
      surface.DrawTexturedRect(cx, y+7, 16, 16)

      cx = cx + (xmul * 25)

      draw.SimpleText(tostring(ply:Ping()), "Trebuchet24", cx, y+2, Color(255, 255, 255), xalign, TEXT_ALIGN_BOTTOM)

      y = y + 35
   end
end

local Stats = {}

net.Receive("mdm_statupd", function()
   local stat = net.ReadString()
   local diff = net.ReadInt(16)
   
   Stats[stat] = (Stats[stat] or 0) + diff
end)

function GM:HUDDrawScoreBoard()
   if not self.ShowScoreboard then return end

   -- Team 1

   --[[draw.TexturedQuad
   {
      texture = surface.GetTextureID "gui/gradient",
      color = team.GetColor(1),
      x = 0,
      y = 90,
      w = 400,
      h = 50
   }]]
   --draw.GradientBox(0, 90, 400, 50, 0.5, team.GetColor(TEAM_GREEN), Color(0, 0, 0, 0))
   --draw.SimpleText("Team " .. team.GetName(TEAM_GREEN), "Trebuchet24", 50, 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

   DrawPlayers(50, TEXT_ALIGN_LEFT, 150, TEAM_GREEN)

   -- Team 2

   DrawPlayers(ScrW() - 50, TEXT_ALIGN_RIGHT, 150, TEAM_PURPLE)

   DrawPlayers(ScrW()/2 - 200, TEXT_ALIGN_LEFT, 55, TEAM_SPEC)


   local midw = ScrW() / 2

   local sx = midw - midw/2
   local sy = ScrH() - 320

   surface.SetDrawColor(Color(255, 255, 255, 100))
   surface.DrawRect(sx, sy, midw - 5, 100)

   surface.SetDrawColor(Color(0, 0, 0))
   surface.DrawOutlinedRect(sx, sy, midw - 5, 100)

   surface.SetDrawColor(Color(255, 255, 255, 255))
   draw.SimpleText("Kills: " .. (Stats["kills"] or 0), "Trebuchet24", sx + 10, sy + 10, Color(0, 0, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
   draw.SimpleText("Deaths: " .. (Stats["deaths"] or 0), "Trebuchet24", sx + 10, sy + 35, Color(0, 0, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
   draw.SimpleText("Damage ratio: " .. (( Stats["dmggiven"] or 0 ) / ( Stats["dmgtaken"] or 1 )), "Trebuchet24", sx + 10, sy + 60, Color(0, 0, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

end
