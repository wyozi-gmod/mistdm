
local function SendWeaponDrop()
   RunConsoleCommand("lastinv")
end

function GM:OnSpawnMenuOpen()
   SendWeaponDrop()
end

