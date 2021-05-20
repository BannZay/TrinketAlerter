local TrinketAlerter = BannZay.TrinketAlerter;
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");

if TrinketAlerter == nil or AceConfig == nil or AceConfigDialog == nil then print("TrinketAlerter blizzard options will not be created as there dependencies to be satisfied"); return; end

local BlizzOptions = {};
local WotlkClassIds = {
	"WARRIOR",
	"PALADIN",
	"HUNTER",
	"ROGUE",
	"PRIEST",
	"DEATHKNIGHT",
	"SHAMAN",
	"MAGE",
};


local function AddHooks()
	hooksecurefunc(TrinketAlerter, "OnInitialize", BlizzOptions.OnInitialize);
end

function BlizzOptions:OnInitialize()
	AceConfig:RegisterOptionsTable("TrinketAlerter", BlizzOptions:BuildBlizzardOptions())
	AceConfigDialog:AddToBlizOptions("TrinketAlerter", "TrinketAlerter")
end

local function SetOption(info, value)
	local key = info.arg or info[#info]
	
	if key == nil then
		return;
	end

	TrinketAlerter.db[key] = value;
	TrinketAlerter:ApplyDbSettings();
end

local function GetOption(info)
	local key = info.arg or info[#info]
	return TrinketAlerter.db[key];
end

function BlizzOptions:BuildBlizzardOptions()
	local s = TrinketAlerter.Settings;

	local options = 
	{
		type = "group",
		name = "TrinketAlerter (/ta or /trinketAlerter)",
		plugins = {},
		get = GetOption,
		set = SetOption,
		args = {}
	}
	
	options.args["lock"] = 
	{
		type = "execute",
		name = "Lock",
		desc = "lock frames (/trinketAlerter lock)",
		order = 1,
		func = function(info, value) TrinketAlerter:Lock(); end,
	}
	
	options.args[s.AnimationTime] = 
	{
		type = "range",
		name = "Animation time",
		desc = "The time frame flashes after trinket was used",
		min =.4,
		max = 6,
		step =.2,
		order = 2,
	}
	
	options.args[s.Scale] = 
	{
		type = "range",
		name = "Scale",
		desc = "",
		min =.3,
		max = 6,
		step =.1,
		order = 3,
	}
	
	options.args[s.AnimationSpeed] = 
	{
		type = "range",
		name = "AnimationSpeed",
		desc = "",
		min =.05,
		max = 1,
		step =.05,
		order = 4,
	}
	
	options.args["test"] = 
	{
		type = "execute",
		name = "Test",
		desc = "",
		order = 99,
		func = function(info, value)  TrinketAlerter:Lock(false); TrinketAlerter:FlashFreeFrame(WotlkClassIds[math.random(1, 8)]); end,
	}
	
	return options;
end

AddHooks();