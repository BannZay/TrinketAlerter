local BannZayLib = LibStub:GetLibrary("BannZayLib-1.0")

local Array = BannZayLib.Array;
local KVP = BannZayLib.KVP;
local Logger = BannZayLib.Logger;
local Utils = BannZayLib.Utils;
local Namespace = BannZayLib.Namespace;

local db;
local logger = Logger:New("TrinketAlerter", 3);
local TrinketAlerter = LibStub("AceAddon-3.0"):NewAddon("TrinketAlerter");
TrinketAlerter.Event = {}

Namespace:Register("BannZay.TrinketAlerter", TrinketAlerter);

TrinketAlerter.Settings = 
{
	AnimationTime = "animationTime",
	Scale = "scale",
	AnimationSpeed = "animationSpeed"
}

function TrinketAlerter:GetDefaultDbSettings()
	return	{ 
		profile = {
			x = 0,
			y = 0,
			[TrinketAlerter.Settings.AnimationTime] = 1.8,
			[TrinketAlerter.Settings.AnimationSpeed] = .1,
			[TrinketAlerter.Settings.Scale] = 3,
			classesTexture = "Interface\\TargetingFrame\\UI-Classes-Circles",
			lockedTexture = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01",
			}
		};
end

function TrinketAlerter:ApplyDbSettings()

	self.framesPool:ForEach(function(f) f:SetScale(db.scale); end );

	self.leadFrame:ClearAllPoints()
	if (db.x==0 and db.y==0) then
		self.leadFrame:SetPoint("Right", UIParent, "Center", 0, -self.leadFrame:GetHeight()/2)
	else
		local scale = self.leadFrame:GetEffectiveScale()
		self.leadFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.x/scale, db.y/scale)
	end
end

function TrinketAlerter:OnProfileChanged(event, database, newProfileKey)
	db = self.db.profile
	self.db = db;
end

function TrinketAlerter:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("TrinketAlerterDB", self:GetDefaultDbSettings());
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged");
	self:OnProfileChanged();

	local framesPool = Array:New();
	local frame1 = self:CreateNotificationFrame(nil);
	local frame2 = self:CreateNotificationFrame(frame1);
	local frame3 = self:CreateNotificationFrame(frame2);
	local frame4 = self:CreateNotificationFrame(frame3);
	local frame5 = self:CreateNotificationFrame(frame4);
	framesPool:Add(frame1, frame2, frame3, frame4, frame5);
	
	self.leadFrame = frame1;
	self.framesPool = framesPool;
	
	local taCommanManager = BannZayLib.SlashCommandManager:New("TrinketAlerter", "ta");
	taCommanManager:AddCommand("lock", function() self:Lock(); end);
	
	Utils:SetMouseMove(self.leadFrame, false, nil, function() local scale = self.leadFrame:GetEffectiveScale(); db.x = self.leadFrame:GetLeft() * scale; db.y = self.leadFrame:GetTop() * scale end);
	self.locked = false;
	self.eventNotificatioDelay = 3;
	self:ApplyDbSettings();
end


function TrinketAlerter:Lock(value)
	if value == nil then
		value = not self.locked;
	end

	if self.locked == value then
		return;
	end

	self.locked = value;
	
	self.framesPool:ForEach(function(f) UIFrameFlashStop(f); self:SetFrameLocked(f, self.locked); end);
	self.leadFrame.texture:SetAlpha(1);
	Utils:SetMouseMove(self.leadFrame, self.locked);
	
	if self.locked then
		self.framesPool:ForEach(function(f) f.borrowedTill = 0; end); -- release all frames
	end
	
end

function TrinketAlerter:SetFrameLocked(frame, value)
	if value then
		frame.texture:SetTexture(db.lockedTexture);
		frame.texture:SetTexCoord(0,1,0,1);
		frame:Show();
		frame.texture:SetAlpha(0.1);
	else
		frame.texture:SetTexture(db.classesTexture); 
		frame:Hide();
		frame.texture:SetAlpha(1);
	end
end

function TrinketAlerter:OnEnable()
	self.EventHandler = CreateFrame("Frame");
	self.EventHandler:SetScript("OnEvent", function(evHandler, event, ...) self.Event[event](evHandler, ...); end);

	for k,v in pairs(self.Event) do
		self.EventHandler:RegisterEvent(k)
	end
end

function TrinketAlerter:CreateNotificationFrame(neighbor, name)
	local frame = CreateFrame("Frame", name);
	frame:Hide();
	frame.borrowedTill = 0;
	frame:SetHeight(50);
	frame:SetWidth(50);
	
	if neighbor ~= nil	then
		frame:SetPoint("Left", neighbor, "Right");
	else
		frame:SetPoint("Center", "UIParent", "Center");
	end
	
	local texture = frame:CreateTexture(nil,BORDER);
	frame.texture = texture;
	texture:SetTexture(db.classesTexture);
	texture:SetAllPoints();
	
	return frame;
end

function TrinketAlerter:BorrowFrame(borrowTime)
	local freeFrame = self.framesPool:Find(function(x) return GetTime() > x.borrowedTill end);
	
	if freeFrame ~= nil then
		freeFrame.borrowedTill = GetTime() + borrowTime;
	end
	
	return freeFrame;
end

function TrinketAlerter:Notify(unit)
    local unitName = UnitName(unit)

    if (self.lastNotification ~= nil and self.lastNotification:Item1() == unitName and GetTime() - self.lastNotification:Item2() < self.eventNotificatioDelay) then
        return nil -- do not notify about the same events
    end

    local unitClass, classId = UnitClass(unit)

    self:FlashFreeFrame(classId, unitName) -- Pass the unitName to the FlashFreeFrame function

    self.lastNotification = KVP:New(unitName, GetTime())
end

function TrinketAlerter:FlashFreeFrame(classId, unitName)
    local frame = self:BorrowFrame(db.animationTime)

    if frame == nil then
        logger:Log(0, "No free notification frames found")
        return
    end

    frame.texture:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classId]))

    -- Add the player's name to the notification frame
    local playerNameText = frame:CreateFontString(nil, "OVERLAY")
    playerNameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    playerNameText:SetText(unitName)
    playerNameText:SetPoint("TOP", frame, "BOTTOM", 0, -2)

    UIFrameFlash(frame, db.animationSpeed, db.animationSpeed, db.animationTime, false)
end



function TrinketAlerter.Event:UNIT_SPELLCAST_SUCCEEDED(unit, spell, rank)
	local self = TrinketAlerter;

	if self.locked then	return; end
	
	if UnitIsFriend("player", unit) then return end
	
	-- pvp trinket
	if (spell == GetSpellInfo(59752) or spell == GetSpellInfo(42292)) then
		self:Notify(unit);
	end

	-- wotf
	if ( spell == GetSpellInfo(7744)) then	
		self:Notify(unit);
	end
end


