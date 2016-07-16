surface.CreateFont("ItemMenuNot", {font = "Trebuchet24",
                                    size = 20,
                                    weight = 1000})

local matHover = Material( "vgui/check.png" )

local MaxWeight = 100

local DermaPanel

function OpenItemMenu(lo)

	if DermaPanel and DermaPanel:IsValid() then
		DermaPanel:Remove()
	end

	DermaPanel = vgui.Create( "DFrame" )  // Create the frame in a local variable
	DermaPanel:SetSize( 1040, 600 )              // Set the size to 300, 200 pixels
	DermaPanel:SetTitle( "Select loadout" ) // Set the title
	DermaPanel:SetVisible( true )               // Show it ( Optional - default true )
	DermaPanel:SetDraggable( true )             // Can you move/drag it? ( optional - default true )
	DermaPanel:ShowCloseButton( true )          // Show close button ( optional - default true ) ( recommended )
	DermaPanel:MakePopup()                      // Make it pop up
	DermaPanel:Center()

	local thislo = LocalPlayer():GetLoadout(lo)

	local NamePicker = vgui.Create("DTextEntry", DermaPanel)
	NamePicker:Dock( TOP )
	NamePicker:SetText((thislo and thislo.name) and thislo.name or "Loadout #" .. tostring(lo))

	local tabs = vgui.Create('DPropertySheet', DermaPanel)
	tabs:Dock( FILL )

	local Details = vgui.Create("HTML", DermaPanel)
	Details:Dock( LEFT )
	Details.Hotomolo = true
	Details:SetSize(250, 600)
	local function ShowDetailsAbout(item)
		if ShowingDetails == item then return end
		ShowingDetails = item

		local statz = ""

		for name, val in pairs(item.data.stats) do
			local clr = StatInfos[name].isGood(val) and "good" or "bad"
			statz = statz .. "<span class=\"" .. clr .. "\">"
			if type(val) == "boolean" then
				statz = statz .. name .. "=" .. tostring(val) .. "<br>"
			elseif type(val) == "number" then
				local perc = (val - 1) * 100
				statz = statz .. (perc > 0 and "+" or "") .. tostring(perc) .. "% " .. name .. "<br>"
			end
			statz = statz .. "</span>"
		end

		Details:SetHTML([[
<html>
<head>
<style>
body {
	color: white;
	text-align: center;
}
.good {
	background-color: green;
}
.bad {
	background-color: red;
}
</style>
</head>
<body>
<h1>]] .. item.data.name .. [[</h1>
<p>]] .. item.data.desc .. [[</p>
<p>]] .. statz .. [[</p>
</body>
</html>
		]])
	end

	local cats = {}

	table.foreach(MDMItems.Items, function(k, item)

		local cat = "Other"

		if item.type == MDM_PERK then
			cat = "Perks"
		elseif item.type == MDM_WEAPON then
			cat = "Weapons"
		end

		if item.data.cat then
			cat = item.data.cat
		end

		if not cats[cat] then
			cats[cat] = {}
		end
		table.insert(cats[cat], item)
	end)

	for name,items in pairs(cats) do
		local Scroll = vgui.Create( "DScrollPanel" ) //Create the Scroll panel
		Scroll:Dock( FILL )

		local IconList = vgui.Create( "DTileLayout", Scroll )
		IconList:SetBaseSize( 128 )
		IconList:MakeDroppable( "SandboxContentPanel", true )
		IconList:SetSelectionCanvas( true )
		--self.IconList:SetUseLiveDrag( true )
		IconList:Dock( FILL )

		Scroll.IconList = IconList

		table.foreach(items, function(k, item)
			
			local btn = vgui.Create("DButton", IconList)
			btn.Item = item

			btn:SetDoubleClickingEnabled( false )
			btn:SetText( "" )
			btn:SetSize( 128, 128 )	


			function btn:PaintOver( w, h)

				self:DrawSelections()

				if self.Hovered then
					ShowDetailsAbout(btn.Item)
				end

				if ( !self.Selected ) then return end

				surface.SetDrawColor( 255, 255, 255, 255 )
				surface.SetMaterial( matHover )
				surface.DrawTexturedRect(w-32, h-32, 32, 32)

			end

			local Icon

			if item.data.model then
				Icon = vgui.Create( "ModelImage", btn)

				Icon:SetMouseInputEnabled( false )
				Icon:SetKeyboardInputEnabled( false )

				Icon:SetModel(item.data.model, _, "000000000")
			else
				Icon = vgui.Create("DImage", btn)

				Icon:SetMaterial(item.data.icon)
			end

			Icon:SetSize( 128, 128 )	

			btn.Selected = thislo and table.HasValue(thislo.items, item.id) or false
			btn.DoClick = function()
				btn.Selected = not btn.Selected
			end

		end)

		tabs:AddSheet(name, Scroll, 'gui/silkicons/add', false, false, '')
	end

	local function GetItemPanels()
		local items = {}
		for _,child in pairs(tabs.Items) do
			for _,btn in pairs(child.Panel.IconList:GetChildren()) do
				table.insert(items, btn)
			end
		end
		return items
	end
	local function GetSelectedItems()
		local ips = {}
		for _,ip in pairs(GetItemPanels()) do
			if ip.Selected then
				table.insert(ips, ip.Item)
			end
		end
		return ips
	end

	local function ComputeWeight()
		local weight, yweight = 0, 0

		for _,child in pairs(GetItemPanels()) do

			if child.Selected then
				weight = weight + child.Item.data.space
			elseif child.Hovered then
				yweight = child.Item.data.space
			end
		end

		return weight, yweight
	end

	local ProgressBar = vgui.Create("DPanel", DermaPanel)
	ProgressBar:Dock( BOTTOM )
	ProgressBar.Paint = function()
		local w, h = ProgressBar:GetSize()
		w = w - 70

		surface.SetDrawColor(255, 0, 0, 255)
		surface.DrawRect(0, 2, w, h - 4)

		local weight, yweight = ComputeWeight()

		-- normalize
		weight = weight / MaxWeight
		yweight = yweight / MaxWeight

		surface.SetDrawColor(0, 255, 0, 255)
		local fsize = w * weight
		surface.DrawRect(0, 2, fsize, h - 4)

		surface.SetDrawColor(255, 255, 0, 255)
		surface.DrawRect(fsize, 2, w * yweight, h - 4)

		if weight > 1 then
            draw.SimpleText("YOUR LOADOUT IS TOO HEAVY TO CONTINUE", "ItemMenuNot", 50, 0, Color(0, 0, 0, 255))
        elseif (weight+yweight) > 1 then
            draw.SimpleText("YOUR LOADOUT WOULD BE TOO HEAVY TO CONTINUE", "ItemMenuNot", 50, 0, Color(255, 127, 0, 255))
		end

        draw.SimpleText(tostring(weight*MaxWeight) .. " / " .. tostring(MaxWeight), "ItemMenuNot", fsize + (fsize < 50 and 5 or -5), 1, Color(0, 0, 0, 255), fsize < 50 and TEXT_ALIGN_LEFT or TEXT_ALIGN_RIGHT)

	end

	local cbtn = vgui.Create("DButton", ProgressBar)
	cbtn:SetText("Done!")
	cbtn:Dock( RIGHT )
	cbtn.DoClick = function()

		if ComputeWeight() > MaxWeight then
			return
		end

		local tbl = {
			name = NamePicker:GetText(),
			items = {}
		}

		for _,child in pairs(GetSelectedItems()) do
			table.insert(tbl.items, child.id)
		end

		local me = LocalPlayer()
		if not me.loadouts then
			me.loadouts = {}
		end
		me.loadouts[lo] = tbl

		net.Start("mdm_loadout")
			net.WriteUInt(lo, 8)
			net.WriteTable(tbl)
		net.SendToServer()

		loadouts.Save()

		DermaPanel:Close()
	end

end