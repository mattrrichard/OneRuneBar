if select(2, UnitClass("player")) ~= "DEATHKNIGHT" then
	-- Don't do anything it player isn't a Death Knight
	return
end

TRB_Config_Defaults = {

	["Runes"] = {
		["Position"] = { "CENTER", nil, "CENTER", 0, -135, },
		["Color"] = { [1] = 0.8, [2] = 0.7,   [3] = 0.9, [4] = 1 },
	},
	
	["Diseases"] = {
		["Colors"] = { 
			["ff"] = { 0, 0.5, 1,  1, },		-- Frost Fever
			["bp"] = { 0, 0.7, 0,  1, },		-- Blood Plague
			["vp"] = { 0.34, 0.22, 0,  1, }, -- Virulent Plague
		},
		["Position"] = { "CENTER", nil, "CENTER", 160, -13, },
	},
	
	["RunicPower"] = {
		["Colors"] = { [1] = 0.2, [2] = 0.7, [3] = 1,   [4] = 1 },
		["Position"] = { "CENTER", nil, "CENTER", 0, -150, },
	},
	
	["Horn of Winter"] = {
		["Colors"] = { [1] = 0, [2] = 0, [3] = 1,   [4] = 1 },
		["Position"] = { "CENTER", nil, "CENTER", 0, 0, },
	},
	
	-- Out of Combat settings
	["OOC_Alpha"] = 0.7,
};
