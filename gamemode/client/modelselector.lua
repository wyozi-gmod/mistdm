

function OpenModelSelector()

	local DermaPanel = vgui.Create( "DFrame" )  // Create the frame in a local variable
	DermaPanel:SetSize( 1040, 600 )              // Set the size to 300, 200 pixels
	DermaPanel:SetTitle( "Select model" ) // Set the title
	DermaPanel:SetVisible( true )               // Show it ( Optional - default true )
	DermaPanel:SetDraggable( true )             // Can you move/drag it? ( optional - default true )
	DermaPanel:ShowCloseButton( true )          // Show close button ( optional - default true ) ( recommended )
	DermaPanel:MakePopup()                      // Make it pop up
	DermaPanel:Center()

	local Scroll = vgui.Create( "DScrollPanel", DermaPanel ) //Create the Scroll panel
	Scroll:Dock( FILL )

	local IconList = vgui.Create( "DTileLayout", Scroll )
	IconList:SetBaseSize( 64 )
	IconList:MakeDroppable( "SandboxContentPanel", true )
	IconList:SetSelectionCanvas( true )
	--self.IconList:SetUseLiveDrag( true )
	IconList:Dock( FILL )

	table.foreach(ValidMDMModels, function(k, item)
		
		local btn = vgui.Create("DButton", IconList)

		btn:SetDoubleClickingEnabled( false )
		btn:SetText( "" )
		btn:SetSize( 64, 64 )	


		function btn:PaintOver( w, h)

			self:DrawSelections()

			if ( !self.Hovered ) then return end

			--surface.SetDrawColor( 255, 255, 255, 255 )
			--surface.SetMaterial( matHover )
			--surface.DrawTexturedRect(w-32, h-32, 32, 32)

		end

		local Icon

			Icon = vgui.Create( "ModelImage", btn)

			Icon:SetMouseInputEnabled( false )
			Icon:SetKeyboardInputEnabled( false )

			Icon:SetModel(item, _, "000000000")


		Icon:SetSize( 64, 64 )	

		btn.DoClick = function()

			RunConsoleCommand("mdm_setmodel", item)

			DermaPanel:Close()
		end

	end)

end