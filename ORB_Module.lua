if select(2, UnitClass("player")) ~= "DEATHKNIGHT" then
   return
end
------------------------------------------------------------------
-- Local config

local NoTextureText = "(none)";

------------------------------------------------------------------

ORB_Module		= {};

--
-- Change strata level for this module. Used when entering/leaving combat
--
function ORB_Module:ChangeStrata(strata)
	if( self.frame) then
		self.frame:SetFrameStrata(strata);
	end
end

--
-- Create a module.
-- Use:
-- local myModule = ORB_Module:create("SomeName");
-- function myModule:OnEnable() (do stuff) end
-- OneRuneBar:RegisterModule(myModule);
--
function ORB_Module:create(name)
	local n = {};
	setmetatable(n, { __index = ORB_Module } );
	n.name = name;
	return n;
end

--
-- Init the module, Modules should use Enable
--
function ORB_Module:init()
	if( self.isRunning ) then return; end

	if( not self.cfg ) then
		self.cfg = ORB_Config[self.name];
	end

	-- Now we are ready to enable this module
	if( self.OnEnable ) then self:OnEnable(); end
	
	self.isRunning = true;
	self:Print((self.name or "Unknown").." module enabled.");
end

function ORB_Module:CreateTexture(f)
	local tex = f:CreateTexture(nil, "BACKGROUND");
	return tex;
end

function ORB_Module:CreateBar(name, parent)
	local Bar = CreateFrame("StatusBar", name, parent);
	Bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	Bar:GetStatusBarTexture():SetHorizTile(true);
	Bar:SetMinMaxValues(0, 100);
	Bar:SetValue(100);
	
	Bar.bg = Bar:CreateTexture(nil, "BACKGROUND");
	Bar.bg:SetAllPoints(Bar);
	Bar.bg:SetColorTexture(0.25, 0.25, 0.25, 0.5);
	
	-- Create text on bar
	local text = Bar:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	--text:SetFont(ElvUI[1]["media"].normFont, 12, "" );
	text:SetFont("Fonts\\FRIZQT__.TTF", self:Config_GetFontSize(), "");
	text:SetPoint("CENTER", Bar, "CENTER", 0, 0);
	Bar.text = text;

	return Bar;
end

function ORB_Module:CreateMoveFrame()
	local f = CreateFrame("frame", nil, self.frame);
	f.parent = self.frame;
	f:SetAllPoints(f.parent);
	f.parent:SetMovable(true);
	f:EnableMouse(true);
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", function(frame) frame.parent:StartMoving() end );
	f:SetScript("OnDragStop", function(frame) frame.parent:StopMovingOrSizing(); frame.parent.owner:SavePosition() end );
	
	f.bg = f:CreateTexture(nil, "ARTWORK");
	f.bg:SetAllPoints(f);
	f.bg:SetColorTexture(0.8,0.8,0.8, 0.4);
	f:SetFrameStrata("HIGH");
	f:Hide();
	
	self.moveFrame = f;
end

function ORB_Module:CreateBorderTexture(f, from, to)
	local t = self:CreateTexture(f);
	t:SetPoint(from, f, to, 0, 0);
	t:SetPoint(to, f, from, 0, 0);
	t:SetColorTexture( 0.0, 0.0, 0.0 );
	return t;
end

function ORB_Module:CreateBorder(f)
	f.t = self:CreateBorderTexture( f, "TOPLEFT", "TOPRIGHT" );
	f.b = self:CreateBorderTexture( f, "BOTTOMLEFT", "BOTTOMRIGHT" );
	f.l = self:CreateBorderTexture( f, "TOPLEFT", "BOTTOMLEFT" );
	f.r = self:CreateBorderTexture( f, "TOPRIGHT", "BOTTOMRIGHT" );
end

function ORB_Module:UpdateBorderSizes( f )
	local borderSize = self:Config_GetBorderSize();

	f.t:SetHeight( borderSize );
	f.b:SetHeight( borderSize );
	f.l:SetWidth( borderSize );
	f.r:SetWidth( borderSize );
end

function ORB_Module:Disable()
	if( not self.isRunning ) then return; end -- Not running
	
	-- Hide frame and unregister all events
	if( self.frame ) then
		self.frame:Hide();
		self.frame:UnregisterAllEvents();
	end

	if( self.OnDisable ) then self:OnDisable(); end

	self.isRunning = nil;
	self:Print(self.name.." module disabled.");
end

function ORB_Module:ChangeVisibility(show)
	if( not self.isRunning ) then return; end

	if( self.frame ) then
		if( show ) then
			self.frame:Show();
		else
			self.frame:Hide();
		end
	end
end

function ORB_Module:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("ORB: "..msg);
end

function ORB_Module:SavePosition()
	if( not self.frame ) then return; end
	
--	ORB_Config[self.name].Position = { self.frame:GetPoint() };
	
	-- Save position
	self.cfg.Position = { self.frame:GetPoint() };
end

function ORB_Module:LoadPosition()
	if( not self.frame ) then return; end -- if no frame exists no position exists.

	if( self.cfg and self.cfg.Position ) then
		self.frame:SetPoint( unpack(self.cfg.Position) );
	else
		self:Error("Failed to load position for module "..self.name);
	end
	
	if( self.OnLoadPosition ) then
		self:OnLoadPosition();
	end
end

function ORB_Module:Error(msg)
	DEFAULT_CHAT_FRAME:AddMessage("ORB Error: "..msg);
end

function ORB_Module:ResetConfig()
	
	-- Create new empty table
	ORB_Config[self.name] = nil; self.cfg = nil;
	ORB_Config[self.name] = {};
	
	-- Copy default values needed for this module
	for k,v in pairs(ORB_Config_Defaults[self.name]) do
		ORB_Config[self.name][k] = v;
	end
	
	-- Set it as our config
	self.cfg = ORB_Config[self.name];	
end

function ORB_Module:InitOptions(parent)

	-- Make sure we have our configuration settings available
	if( not ORB_Config[self.name] ) then
		self:ResetConfig();
	end

	local panel = CreateFrame("frame", self.name.."_OptionsPanel", parent);
	panel.name = self.name;
	panel.parent = parent.name;
	panel.owner = self;
	panel.okay = function(self) self.owner._OnOkay(self.owner); end
	panel.default = function(self) self.owner._OnDefault(self.owner); end
	--
	-- Module panel
	--
	local xoff, yoff = 20, -20;
	
	local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	header:SetPoint("TOPLEFT", panel, "TOPLEFT", xoff, yoff);
	header:SetText(parent.name.." - "..panel.name );
	panel.header = header;
	
	-- Module disable checkbox
	local cb = CreateFrame("CheckButton", "ORB_DisableModule_"..self.name, panel, "InterfaceOptionsCheckButtonTemplate");
	cb:SetPoint("TOPLEFT", header, "TOPLEFT", 0, yoff);
	cb.text = _G[cb:GetName().."Text"];
	cb.text:SetText("Enable "..self.name.." module");
	local v = true;
	if( ORB_Config.disabled_modules and ORB_Config.disabled_modules[self.name] and ORB_Config.disabled_modules[self.name] == true ) then
		v = false;
	end
	cb:SetChecked( v );
	self.CB_Disabled = cb;

	-- Texture options
	local textureText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	textureText:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 0, yoff);
	textureText:SetText("Texture");

	local textureDD = CreateFrame("frame", "ORB_ModuleTextureDD_"..self.name, panel, "UIDropDownMenuTemplate");
	textureDD:ClearAllPoints();
	textureDD:SetPoint("TOPLEFT", textureText, "BOTTOMLEFT", -20, 0);
	textureDD:SetScript("OnShow", function(self)
									UIDropDownMenu_SetSelectedValue(self, ORB_Config[self.owner.name].Texture or NoTextureText);
									UIDropDownMenu_SetText(self, ORB_Config[self.owner.name].Texture or NoTextureText);
								end
						);
	textureDD:Show();
	textureDD.owner = self;
	self.TextureDD = textureDD;

	UIDropDownMenu_Initialize(
		textureDD,
		function(self, level)
			local OnClick = 
				function(self)
					UIDropDownMenu_SetSelectedID(self.owner, self:GetID());
					if( self.owner.owner.SetBarTexture ) then self.owner.owner:SetBarTexture(self.value); end
				end;

			local info = UIDropDownMenu_CreateInfo();
			info.text = NoTextureText;
			info.value = nil;
			info.owner = self;
			info.func = OnClick;
			UIDropDownMenu_AddButton(info, level);

			local BarTextures = {};
			if( SM ) then
				BarTextures = SM:List("statusbar");
			end

			for k,v in pairs(BarTextures) do
				info = UIDropDownMenu_CreateInfo();
				info.text = v;
				info.value = v;
				info.owner = self;
				info.func = OnClick;
				UIDropDownMenu_AddButton(info, level);
			end
		end
	);
	UIDropDownMenu_SetWidth(textureDD, 100);
	UIDropDownMenu_SetButtonWidth(textureDD, 124);
	UIDropDownMenu_JustifyText(textureDD, "LEFT");

	local borderSizeLabel = self:CreateLabel( panel, "Border Size:");
	borderSizeLabel:SetPoint("TOPLEFT", textureDD, "BOTTOMLEFT", 20, yoff);
	
	local borderSizeBox = self:CreateEditBox( panel, "ORB_ModuleBorderSizeEditBox_"..self.name,
		function(self) return self:Config_GetBorderSize(); end,
		function(self, value) self:Config_SetBorderSize(value); end );
	borderSizeBox:SetPoint("TOPLEFT", borderSizeLabel, "TOPRIGHT", 4, 0);
	borderSizeBox:SetPoint("BOTTOMLEFT", borderSizeLabel, "BOTTOMRIGHT", 0, 0);

	local barWidthLabel = self:CreateLabel( panel, "Bar Width:");
	barWidthLabel:SetPoint("TOPLEFT", borderSizeLabel, "BOTTOMLEFT", 0, yoff);
	
	local barWidthBox = self:CreateEditBox( panel, "ORB_ModuleBarWidthEditBox_"..self.name,
		function(self) return self:Config_GetBarSize()[1]; end,
		function(self, value) self:Config_SetBarSize(value, self:Config_GetBarSize()[2]); end );
	barWidthBox:SetPoint("TOPLEFT", barWidthLabel, "TOPRIGHT", 4, 0);
	barWidthBox:SetPoint("BOTTOMLEFT", barWidthLabel, "BOTTOMRIGHT", 0, 0);

	local barHeightLabel = self:CreateLabel( panel, "Height:");
	barHeightLabel:SetPoint("TOPLEFT", barWidthBox, "TOPRIGHT", 4, 0);
	
	local barHeightBox = self:CreateEditBox( panel, "ORB_ModuleBarHeightEditBox_"..self.name,
		function(self) return self:Config_GetBarSize()[2]; end,
		function(self, value) self:Config_SetBarSize(self:Config_GetBarSize()[1], value); end );
	barHeightBox:SetPoint("TOPLEFT", barHeightLabel, "TOPRIGHT", 4, 0);
	barHeightBox:SetPoint("BOTTOMLEFT", barHeightLabel, "BOTTOMRIGHT", 0, 0);

	local fontSizeLabel = self:CreateLabel( panel, "Font Size:");
	fontSizeLabel:SetPoint("TOPLEFT", barWidthLabel, "BOTTOMLEFT", 0, yoff);
	
	local fontSizeBox = self:CreateEditBox( panel, "ORB_ModuleBarFontSizeEditBox_"..self.name,
		function(self) return self:Config_GetFontSize(); end,
		function(self, value) self:Config_SetFontSize(value); end );
	fontSizeBox:SetPoint("TOPLEFT", fontSizeLabel, "TOPRIGHT", 4, 0);
	fontSizeBox:SetPoint("BOTTOMLEFT", fontSizeLabel, "BOTTOMRIGHT", 0, 0);

	if( self.OnInitOptions ) then self:OnInitOptions(panel, fontSizeLabel ); end
	
	--
	-- Add panel to blizzards addon config
	--
	self.panel = panel;
	InterfaceOptions_AddCategory(self.panel);
end

function ORB_Module:CreateColorButtonOption(panel, name)
	local btn = CreateFrame("button", self.name..name.."button", panel, "UIPanelButtonTemplate");
	btn.owner = self;
	btn.orbcolorname = name;
	btn:SetWidth(80);
	btn:SetHeight(22);
	btn:SetText(name);
	btn:SetScript("OnClick", function(self) 
								ColorPickerFrame.previousValues = { self.owner:GetConfigColor(self.owner, self.orbcolorname) };
								ColorPickerFrame.func = function() self.owner:SetBarColor(self.owner, self.orbcolorname, ColorPickerFrame:GetColorRGB()) end;
								ColorPickerFrame.opacityFunc = function() self.owner:SetBarColor(self.owner, self.orbcolorname, ColorPickerFrame:GetColorRGB()); end;
								ColorPickerFrame.cancelFunc = function() self.owner:SetBarColor(self.owner, self.orbcolorname, unpack(ColorPickerFrame.previousValues)); end;
								ColorPickerFrame:SetColorRGB( self.owner:GetConfigColor(self.owner, self.orbcolorname) );
								ColorPickerFrame:SetFrameStrata("DIALOG");
								ColorPickerFrame:Show();
							 end);

	local tex = panel:CreateTexture(nil, "BACKGROUND");
	tex:SetWidth(20);
	tex:SetHeight(20);
	tex:SetPoint("LEFT", btn, "RIGHT", 10, 0);
	tex:SetColorTexture( self:GetConfigColor(self, name) );

	if( not panel.barcolor ) then
		panel.barcolor = {};
	end

	panel.barcolor[name] = tex;

	return btn, tex;
end

function ORB_Module:CreateLabel( panel, labelText )
	local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	label:SetText(labelText);
	return label
end

function ORB_Module:CreateEditBox( panel, name, getConfigFunc, setConfigFunc )
	local box = CreateFrame( "editbox", name, panel, "InputBoxTemplate");
	box.owner = self;
	box:SetHeight(30);
	box:SetWidth(30);
	box:SetAutoFocus(false);
	box:SetMaxLetters(3);
	box:SetNumeric(true);

	box:SetScript("OnShow", function(self) self:SetText(getConfigFunc(self.owner)); self:SetCursorPosition(0); end);
	box:SetScript("OnEscapePressed", function(self) self:SetText(getConfigFunc(self.owner)); self:ClearFocus(); end);
	box:SetScript("OnEnterPressed", function(self) local val = self:GetNumber(); setConfigFunc(self.owner, val); self:ClearFocus(); end);

	return box;
end

function ORB_Module:_OnOkay()
	-- Disable/Enable
	local status = self.CB_Disabled:GetChecked();
	if( status and not self.isRunning ) then
		--self:Print(self.name.." module activated.");
		ORB_Config.disabled_modules[self.name] = nil;
		
	elseif( not status and self.isRunning ) then
		--self:Print(self.name.." module deactivated.");
		if( not ORB_Config.disabled_modules ) then ORB_Config.disabled_modules = {}; end
		ORB_Config.disabled_modules[self.name] = true;
	end
end

function ORB_Module:_OnDefault()
	self:ResetConfig();

	-- Load default value
	local v = true;
	if( ORB_Config_Defaults.disabled_modules and ORB_Config_Defaults.disabled_modules[self.name] and ORB_Config_Defaults.disabled_modules[self.name] == true ) then
		v = false;
	end
	self.CB_Disabled:SetChecked( v );
	
	if( self.OnDefault ) then
		self:OnDefault(); 
	end
	
	if( v == true ) then
		self:init();
	else
		self:Disable();
	end
end

function ORB_Module:Config_GetBorderSize()
	return ORB_Config[self.name].BorderSize or ORB_Config_Defaults[self.name].BorderSize;
end

function ORB_Module:Config_SetBorderSize(val)
	ORB_Config[self.name].BorderSize = val;

	if( self.PositionFrame ) then
		self:PositionFrame();
	end
end

function ORB_Module:Config_GetBarSize()
	return ORB_Config[self.name].BarSize or ORB_Config_Defaults[self.name].BarSize;
end

function ORB_Module:Config_SetBarSize(width, height)
	ORB_Config[self.name].BarSize = { width, height };

	if( self.PositionFrame ) then
		self:PositionFrame();
	end
end

function ORB_Module:Config_GetFontSize()
	return ORB_Config[self.name].FontSize or ORB_Config_Defaults[self.name].FontSize;
end

function ORB_Module:Config_SetFontSize(val)
	ORB_Config[self.name].FontSize = val;
	self.Bar.text:SetFont("Fonts\\FRIZQT__.TTF", val, "");
end
