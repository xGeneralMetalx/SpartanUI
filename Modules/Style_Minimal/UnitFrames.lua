local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Minimal");
local PlayerFrames = spartan:GetModule("PlayerFrames");
local PartyFrames = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------
local square = [[Interface\AddOns\SpartanUI\media\map-overlay.tga]]

local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget",[6]="player"}
local Smoothv2 = [[Interface\AddOns\SpartanUI_PlayerFrames\media\Smoothv2.tga]]
local texture = [[Interface\AddOns\SpartanUI_PlayerFrames\media\texture.tga]]
local metal = [[Interface\AddOns\SpartanUI_PlayerFrames\media\metal.tga]]

--Interface/WorldStateFrame/ICONS-CLASSES
local lfdrole = [[Interface\AddOns\SpartanUI\media\icon_role.tga]]

local colors = setmetatable({},{__index = SpartanoUF.colors});
for k,v in pairs(SpartanoUF.colors) do if not colors[k] then colors[k] = v end end
do -- setup custom colors that we want to use
	colors.health 		= {0,1,50/255};			-- the color of health bars
	colors.reaction[1]	= {1, 50/255, 0};		-- Hated
	colors.reaction[2]	= colors.reaction[1];	-- Hostile
	colors.reaction[3]	= {1, 150/255, 0};		-- Unfriendly
	colors.reaction[4]	= {1, 220/255, 0};		-- Neutral
	colors.reaction[5]	= colors.health;		-- Friendly
	colors.reaction[6]	= colors.health;		-- Honored
	colors.reaction[7]	= colors.health;		-- Revered
	colors.reaction[8]	= colors.health;		-- Exalted
end

local menu = function(self)
	local unit = string.gsub(self.unit,"(.)",string.upper,1);
	if (_G[unit..'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[unit..'FrameDropDown'], 'cursor')
	end
end

local threat = function(self,event,unit)
	if (not self.Portrait) then -- no Portrait color artwork if possible
		if (not self.artwork) then return end
		-- if (not self.artwork.bg:IsObjectType("Texture")) then return; end
		-- unit = string.gsub(self.unit,"(.)",string.upper,1) or string.gsub(unit,"(.)",string.upper,1)
		-- local status
		-- if UnitExists(unit) then status = UnitThreatSituation(unit) else status = 0; end
		-- if (status and status > 0) then
			-- local r,g,b = GetThreatStatusColor(status);
			-- self.artwork.bg:SetVertexColor(r,g,b);
		-- else
			-- self.artwork.bg:SetVertexColor(1,1,1);
		-- end
	else -- Portrait exsits color picture for threat
		if (not self.Portrait:IsObjectType("Texture")) then return; end
		unit = string.gsub(self.unit,"(.)",string.upper,1) or string.gsub(unit,"(.)",string.upper,1)
		local status
		if UnitExists(unit) then status = UnitThreatSituation(unit) else status = 0; end
		if (status and status > 0) then
			local r,g,b = GetThreatStatusColor(status);
			self.Portrait:SetVertexColor(r,g,b);
		else
			self.Portrait:SetVertexColor(1,1,1);
		end
	end
end

local name = function(self)
	if (UnitIsEnemy(self.unit,"player")) then self.Name:SetTextColor(1, 50/255, 0);
	elseif (UnitIsUnit(self.unit,"player")) then self.Name:SetTextColor(1, 1, 1); 
	else
		local r,g,b = unpack(colors.reaction[UnitReaction(self.unit,"player")] or {1,1,1});
		self.Name:SetTextColor(r,g,b);
	end
end

local pvpIcon = function (self, event, unit)
	if(unit ~= self.unit) then return end
	
	local pvp = self.PvP
	if(pvp.PreUpdate) then
		pvp:PreUpdate()
	end
	
	if pvp.shadow == nil then
		pvp.shadow = self:CreateTexture(nil,"BACKGROUND");
		pvp.shadow:SetSize(25,25);
		pvp.shadow:SetPoint("CENTER",pvp,"CENTER",2,-2);
		pvp.shadow:SetVertexColor(0,0,0,.9)
	end
	
	local status
	local factionGroup = UnitFactionGroup(unit)
	if(UnitIsPVPFreeForAll(unit)) then
		pvp:SetTexture[[Interface\FriendsFrame\UI-Toast-FriendOnlineIcon]]
		status = 'ffa'
	-- XXX - WoW5: UnitFactionGroup() can return Neutral as well.
	elseif(factionGroup and factionGroup ~= 'Neutral' and UnitIsPVP(unit)) then
		pvp:SetTexture([[Interface\FriendsFrame\PlusManz-]]..factionGroup)
		pvp.shadow:SetTexture([[Interface\FriendsFrame\PlusManz-]]..factionGroup)
		status = factionGroup
	end

	if(status) then
		pvp:Show()
		pvp.shadow:Show()
	else
		pvp:Hide()
		pvp.shadow:Hide()
	end

	if(pvp.PostUpdate) then
		return pvp:PostUpdate(status)
	end
end

function CreatePortrait(self)
	if DBMod.PlayerFrames.Portrait3D then			
		local Portrait = CreateFrame('PlayerModel', nil, self)
		Portrait:SetScript("OnShow", function(self) self:SetCamera(0) end)
		Portrait.type = "3D"
		return Portrait;
	else
		local tmp = self:CreateTexture(nil,"BORDER");
		tmp:SetTexCoord(0.15,0.86,0.15,0.86)
		return tmp;
	end
end

--	Updating functions
local PostUpdateText = function(self,unit)
	self:Untag(self.Health.value)
	if self.Power then self:Untag(self.Power.value) end
	self:Tag(self.Health.value, PlayerFrames:TextFormat("health"))
	if self.Power then self:Tag(self.Power.value, PlayerFrames:TextFormat("mana")) end
end

local PostUpdateAura = function(self,unit)
	if DBMod.PlayerFrames[unit] then
		if DBMod.PlayerFrames[unit].AuraDisplay then
			self:Show();
			self.size = DBMod.PlayerFrames[unit].Auras.size;
			self.spacing = DBMod.PlayerFrames[unit].Auras.spacing;
			self.showType = DBMod.PlayerFrames[unit].Auras.showType;
			self.numBuffs = DBMod.PlayerFrames[unit].Auras.NumBuffs;
			self.numDebuffs = DBMod.PlayerFrames[unit].Auras.NumDebuffs;
			self.onlyShowPlayer = DBMod.PlayerFrames[unit].Auras.onlyShowPlayer;
		else
			self:Hide();
		end
	end
end

local PostUpdateColor = function(self,unit)
	self.Health.frequentUpdates = true;
	self.Health.colorDisconnected = true;
	if DBMod.PlayerFrames.bars[unit].color == "reaction" then
		self.Health.colorReaction = true;
		self.Health.colorClass = false;
	elseif DBMod.PlayerFrames.bars[unit].color == "happiness" then
		self.Health.colorHappiness = true;
		self.Health.colorReaction = false;
		self.Health.colorClass = false;
	elseif DBMod.PlayerFrames.bars[unit].color == "class" then
		self.Health.colorClass = true;
		self.Health.colorReaction = false;
	else
		self.Health.colorClass = false;
		self.Health.colorReaction = false;
		self.Health.colorSmooth = true;
	end
	self.colors.smooth = {1,0,0, 1,1,0, 0,1,0}
	self.Health.colorHealth = true;
end

local ChangeFrameStatus = function(self,unit)
	if DBMod.PlayerFrames[unit].display then
		self:Show();
	else
		self:Hide();
	end
end

local PostCastStop = function(self)
	if self.Time then self.Time:SetTextColor(1,1,1); end
end

local PostCastStart = function(self,unit,name,rank,text,castid)
	self:SetStatusBarColor(1,0.7,0);
end

local PostChannelStart = function(self,unit,name,rank,text,castid)
	self:SetStatusBarColor(1,0.2,0.7);
end

local OnCastbarUpdate = function(self,elapsed)
	if self.casting then
		self.duration = self.duration + elapsed
		if (self.duration >= self.max) then
			self.casting = nil;
			self:Hide();
			if PostCastStop then PostCastStop(self:GetParent()); end
			if PostCastStop then PostCastStop(self); end
			return;
		end
		if self.Time then
			if self.delay ~= 0 then self.Time:SetTextColor(1,0,0); else self.Time:SetTextColor(1,1,1); end
			if DBMod.PlayerFrames.Castbar.text[self:GetParent().unit] == 1 then
				self.Time:SetFormattedText("%.1f",self.max - self.duration);
			else
				self.Time:SetFormattedText("%.1f",self.duration);
			end
		end
		if DBMod.PlayerFrames.Castbar[self:GetParent().unit] == 1 then
			self:SetValue(self.max-self.duration)
		else
			self:SetValue(self.duration)
		end
	elseif self.channeling then
		self.duration = self.duration - elapsed;
		if (self.duration <= 0) then
			self.channeling = nil;
			self:Hide();
			if PostChannelStop then PostChannelStop(self:GetParent()); end
			return;
		end
		if self.Time then
			if self.delay ~= 0 then self.Time:SetTextColor(1,0,0); else self.Time:SetTextColor(1,1,1); end
				self.Time:SetFormattedText("%.1f",self.max-self.duration);
		end
		if DBMod.PlayerFrames.Castbar[self:GetParent().unit] == 1 then
			self:SetValue(self.duration)
		else
			self:SetValue(self.max-self.duration)
		end
	else
		self.unitName = nil;
		self.channeling = nil;
		self:SetValue(1);
		self:Hide();
	end
end

local MakeSmallFrame = function(self,unit)
	self.menu = menu;
	self:RegisterForClicks("AnyDown");
	self:EnableMouse(enable)
	self:SetClampedToScreen(true)
	self:SetScript("OnEnter", UnitFrame_OnEnter);
	self:SetScript("OnLeave", UnitFrame_OnLeave);
	
	self:SetSize(100, 40);
	do --setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(2); self.artwork:SetAllPoints(self);
		
		-- if DBMod.PartyFrames.Portrait then
			-- self.Portrait = CreatePortrait(self);
			-- self.Portrait:SetSize(60, 60);
			-- self.Portrait:SetPoint("TOPLEFT",self,"TOPLEFT",35,-15);
		-- end
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(3);
			health:SetSize(self:GetWidth(), 30);
			health:SetPoint("TOP",self,"TOP",0,0);
			health:SetStatusBarTexture(Smoothv2)
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			-- health.value:SetAllPoints(health);
			health.value:SetPoint("TOPLEFT",health,"TOPLEFT",0,-5);
			health.value:SetPoint("TOPRIGHT",health,"TOPRIGHT",0,-5);
			health.value:SetPoint("BOTTOMLEFT",health,"BOTTOMLEFT",0,0);
			health.value:SetPoint("BOTTOMRIGHT",health,"BOTTOMRIGHT",0,0);

			health.value:SetJustifyH("CENTER");
			health.value:SetJustifyV("MIDDLE");
			self:Tag(health.value, PlayerFrames:TextFormat("health"))
			-- self:Tag(health.value, "[perhp]% ([missinghpdynamic])")	
			
			local Background = health:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(health)
			Background:SetTexture(1, 1, 1, .2)
			
			self.Health = health;
			self.Health.bg = Background;
			self.Health.colorTapping = true;
			self.Health.frequentUpdates = true;
			self.Health.colorDisconnected = true;
			if DBMod.PlayerFrames.bars[unit] then
				if DBMod.PlayerFrames.bars[unit].color == "reaction" then
					self.Health.colorReaction = true;
				elseif DBMod.PlayerFrames.bars[unit].color == "happiness" then
					self.Health.colorHappiness = true;
				elseif DBMod.PlayerFrames.bars[unit].color == "class" then
					self.Health.colorClass = true;
				end
			else
				self.Health.colorSmooth = true;
			end
			
			self.colors.smooth = {1,0,0, 1,1,0, 0,1,0}
			self.Health.colorHealth = true;
			
			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(200, 16)
			otherBars:SetSize(150, 16)
			
			self.HealPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4,
			}
		end
		do -- power bar
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(3);
			power:SetSize(self:GetWidth(), 4);
			power:SetPoint("TOP",self.Health,"BOTTOM",0,0);
			power:SetStatusBarTexture(Smoothv2)
			
			-- power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			-- power.value:SetAllPoints(power);
			-- power.value:SetJustifyH("CENTER");
			-- power.value:SetJustifyV("MIDDLE");
			-- self:Tag(power.value, TextFormat("mana"))
			
			local Background = power:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(power)
			Background:SetTexture(1, 1, 1, .2)
			
			self.Power = power;
			self.Power.bg = Background;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
			
		end
	end
	do -- setup items, icons, and text
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = 1/2,
		}
		
		local items = CreateFrame("Frame",nil,self);
		items:SetFrameStrata("BACKGROUND");
		items:SetAllPoints(self);
		items:SetFrameLevel(4);
		items.low = CreateFrame("Frame",nil,self);
		items.low:SetFrameStrata("BACKGROUND");
		items.low:SetAllPoints(self);
		items.low:SetFrameLevel(1);
		
		self.Name = items:CreateFontString();
		spartan:FormatFont(self.Name, 10, "Player")
		self.Name:SetHeight(10);
		self.Name:SetJustifyH("CENTER");
		self.Name:SetJustifyV("BOTTOM");
		self.Name:SetPoint("TOPLEFT",self,"TOPLEFT",0,0);
		self.Name:SetPoint("TOPRIGHT",self,"TOPRIGHT",0,0);
		self:Tag(self.Name, "[SUI_ColorClass][name]");
		
		self.LFDRole = items:CreateTexture(nil,"BORDER");
		self.LFDRole:SetSize(15, 15);
		self.LFDRole:SetPoint("CENTER",items,"TOPLEFT",0,0);
		self.LFDRole:SetTexture(lfdrole);
		self.LFDRole:SetAlpha(.75);
		
		self.PvP = items:CreateTexture(nil,"BORDER");
		self.PvP:SetSize(25, 25);
		self.PvP:SetPoint("CENTER",self.Portrait,"BOTTOMLEFT",0,0);
		self.PvP.Override = pvpIcon
		
		self.LevelSkull = items:CreateTexture(nil,"ARTWORK");
		self.LevelSkull:SetSize(16, 16);
		self.LevelSkull:SetPoint("LEFT",self.Name,"LEFT");
		
		self.RaidIcon = items:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetSize(20, 20);
		self.RaidIcon:SetPoint("CENTER",self,"RIGHT",2,-2);
		
		self.ResurrectIcon = items:CreateTexture(nil, 'OVERLAY')
		self.ResurrectIcon:SetSize(30, 30)
		self.ResurrectIcon:SetPoint("CENTER",self,"CENTER",0,0)

		self.ReadyCheck = items:CreateTexture(nil, 'OVERLAY')
		self.ReadyCheck:SetSize(30, 30)
		self.ReadyCheck:SetPoint("CENTER",self,"CENTER",0,0)
		
		self.StatusText = items:CreateFontString(nil, "OVERLAY", "SUI_FontOutline12");
		self.StatusText:SetPoint("TOP",self.Name,"BOTTOM");
		self.StatusText:SetJustifyH("CENTER");
		self:Tag(self.StatusText, "[afkdnd]");
	end
	-- self.AuraWatch = spartan:oUF_Buffs(self)
	
	self.TextUpdate = PostUpdateText;
	self.ColorUpdate = PostUpdateColor;
	return self;
end

local MakeLargeFrame = function(self,unit,width)
	self.menu = menu;
	self:RegisterForClicks("anyup");
	self:SetAttribute("*type2", "menu");
	self:EnableMouse(enable)
	self:SetScript("OnEnter", UnitFrame_OnEnter);
	self:SetScript("OnLeave", UnitFrame_OnLeave);
	
	if width then
		self:SetSize(width, 40);
	else
		self:SetSize(200, 40);
	end
	
	do --setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(2); self.artwork:SetAllPoints(self);
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame("StatusBar",nil,self);
			cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(3);
			cast:SetSize(self:GetWidth(), 5);
			cast:SetPoint("TOP",self,"TOP",0,-1);
			cast:SetStatusBarTexture(Smoothv2)
			
			cast.Time = cast:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			cast.Time:SetSize(20,8);
			cast.Time:SetJustifyH("LEFT"); cast.Time:SetJustifyV("MIDDLE");
			cast.Time:SetPoint("LEFT",cast,"RIGHT",2,0);
			
			local Background = cast:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(cast)
			Background:SetTexture(1, 1, 1, .2)
			
			self.Castbar = cast;
			self.Castbar.bg = Background;
			self.Castbar.OnUpdate = OnCastbarUpdate;
			self.Castbar.PostCastStart = PostCastStart;
			self.Castbar.PostChannelStart = PostChannelStart;
			self.Castbar.PostCastStop = PostCastStop;
		end
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(3);
			health:SetSize(self:GetWidth(), 30);
			health:SetPoint("TOP",self.Castbar,"BOTTOM",0,0);
			health:SetStatusBarTexture(Smoothv2)
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetAllPoints(health);
			health.value:SetJustifyH("CENTER");
			health.value:SetJustifyV("MIDDLE");
			self:Tag(health.value, PlayerFrames:TextFormat("health"))
			-- self:Tag(health.value, "[perhp]% ([missinghpdynamic])")	
			
			local Background = health:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(health)
			Background:SetTexture(1, 1, 1, .2)
			
			self.Health = health;
			self.Health.bg = Background;
			self.Health.colorTapping = true;
			self.Health.frequentUpdates = true;
			self.Health.colorDisconnected = true;
			if DBMod.PlayerFrames.bars[unit] then
				if DBMod.PlayerFrames.bars[unit].color == "reaction" then
					self.Health.colorReaction = true;
				elseif DBMod.PlayerFrames.bars[unit].color == "happiness" then
					self.Health.colorHappiness = true;
				elseif DBMod.PlayerFrames.bars[unit].color == "class" then
					self.Health.colorClass = true;
				end
			else
				self.Health.colorSmooth = true;
			end
			
			self.colors.smooth = {1,0,0, 1,1,0, 0,1,0}
			self.Health.colorHealth = true;
			
			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(200, 16)
			otherBars:SetSize(150, 16)
			
			self.HealPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4,
			}
		end
		do -- power bar
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(3);
			power:SetSize(self:GetWidth(), 8);
			power:SetPoint("TOP",self.Health,"BOTTOM",0,0);
			power:SetStatusBarTexture(Smoothv2)
			
			power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.value:SetAllPoints(power);
			power.value:SetJustifyH("CENTER");
			power.value:SetJustifyV("MIDDLE");
			self:Tag(power.value, "[perpp]%")	
			
			local Background = power:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(power)
			Background:SetTexture(1, 1, 1, .2)
			
			self.Power = power;
			self.Power.bg = Background;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
			
		end
		do -- HoTs Display
			local class, classFileName = UnitClass("player");
			local spellIDs ={}
			if classFileName == "DRUID" then
				spellIDs = {
					774, -- Rejuvenation
					33763, -- Lifebloom
					8936, -- Regrowth
					102351, -- Cenarion Ward
					48438, -- Wild Growth
					155777, -- Germination
					102342, -- Ironbark
				}
			elseif classFileName == "PRIEST" then
				spellIDs = {
					139, -- Renew
					17, -- sheild
					33076, -- Prayer of Mending
				}
			end
			self.Buffs = CreateFrame("Frame",nil,self);
			self.Buffs:SetSize(self:GetWidth(), DBMod.PartyFrames.Auras.size+2);
				if unit == "player" or unit == "target" then
					self.Buffs:SetPoint("BOTTOM",self,"TOP", 0, 14)
				else
					self.Buffs:SetPoint("TOPLEFT",self,"TOPRIGHT", 2, 0)
				end
			self.Buffs.onlyShowPlayer = true
			self.Buffs.filter = spellIDs
			self.Buffs.size = DBMod.PartyFrames.Auras.size;
			self.Buffs.spacing = DBMod.PartyFrames.Auras.spacing;
			self.Buffs.showType = DBMod.PartyFrames.Auras.showType;
			self.Buffs.size = DBMod.PartyFrames.Auras.size;
			local FilterType = function(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
				for i, sid in pairs(spellIDs) do
					if sid == spellID then return true end
				end
				return false
			end
			self.Buffs.CustomFilter = FilterType
		end
		do -- setup buffs and debuffs
			local tmp = 0
			if unit == "player" and (playerClass =="DEATHKNIGHT" or playerClass =="DRUID") then tmp = -5 end
			
			self.Debuffs = CreateFrame("Frame",nil,self);
			self.Debuffs:SetSize(self:GetWidth(), 17);
			if unit == "player" or unit == "target" then
				self.Debuffs:SetPoint("TOPRIGHT",self,"BOTTOMRIGHT",0,-5 + tmp);
				self.Debuffs:SetPoint("TOPLEFT",self,"BOTTOMLEFT",0,-5 + tmp);
				self.Debuffs.num = 12;
			else
				self.Debuffs:SetPoint("BOTTOMLEFT",self,"BOTTOMRIGHT",0,0 + tmp);
				self.Debuffs.num = 4;
			end
			self.Debuffs:SetFrameStrata("BACKGROUND");
			self.Debuffs:SetFrameLevel(4);
			-- settings
			self.Debuffs.size = DBMod.PartyFrames.Auras.size;
			self.Debuffs.spacing = DBMod.PartyFrames.Auras.spacing;
			self.Debuffs.showType = DBMod.PartyFrames.Auras.showType;
			self.Debuffs.initialAnchor = "TOPLEFT";
			self.Debuffs.gap = true; -- adds an empty spacer between buffs and debuffs
			self.Debuffs.numBuffs = DBMod.PartyFrames.Auras.NumBuffs;
			self.Debuffs.numDebuffs = DBMod.PartyFrames.Auras.NumDebuffs;
			
			self.Debuffs.PostUpdate = PartyFrames:PostUpdateAura(self,unit);
		end
		do --Special Icons/Bars
			local playerClass = select(2, UnitClass("player"))
			if unit == "player" and playerClass == "DRUID" then
				local DruidMana = CreateFrame("StatusBar", nil, self)
				DruidMana:SetSize(self:GetWidth(), 4);
				DruidMana:SetPoint("TOP",self.Power,"BOTTOM",0,0);
				DruidMana.colorPower = true
				DruidMana:SetStatusBarTexture(Smoothv2)

				-- Add a background
				local Background = DruidMana:CreateTexture(nil, 'BACKGROUND')
				Background:SetAllPoints(DruidMana)
				Background:SetTexture(1, 1, 1, .2)

				-- Register it with oUF
				self.DruidMana = DruidMana
				self.DruidMana.bg = Background
				
				-- local EclipseBar = CreateFrame('Frame', nil, self)
				-- EclipseBar:SetPoint('BOTTOM', self, 'TOP')
				-- EclipseBar:SetSize(self:GetWidth(), 20)

				-- Position and size
				-- local LunarBar = CreateFrame('StatusBar', nil, EclipseBar)
				-- LunarBar:SetPoint('LEFT')
				-- LunarBar:SetSize(self:GetWidth(), 20)

				-- local SolarBar = CreateFrame('StatusBar', nil, EclipseBar)
				-- SolarBar:SetPoint('LEFT', LunarBar:GetStatusBarTexture(), 'RIGHT')
				-- SolarBar:SetSize(self:GetWidth(), 20)

				-- Register with oUF
				-- EclipseBar.LunarBar = LunarBar
				-- EclipseBar.SolarBar = SolarBar
				-- self.EclipseBar = EclipseBar
			elseif unit == "player" and playerClass =="DEATHKNIGHT" then
				self.Runes = CreateFrame("Frame", nil, self)
				
				for i = 1, 6 do
					self.Runes[i] = CreateFrame("StatusBar", self:GetName().."_Runes"..i, self)
					self.Runes[i]:SetHeight(6)
					self.Runes[i]:SetWidth((self:GetWidth() - 6) / 6)
					if (i == 1) then
						self.Runes[i]:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -3)
					else
						self.Runes[i]:SetPoint("TOPLEFT", self.Runes[i-1], "TOPRIGHT", 1, 0)
					end
					self.Runes[i]:SetStatusBarTexture(Smoothv2)

					self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, "BORDER")
					self.Runes[i].bg:SetPoint("TOPLEFT", self.Runes[i], "TOPLEFT", -0, 0)
					self.Runes[i].bg:SetPoint("BOTTOMRIGHT", self.Runes[i], "BOTTOMRIGHT", 0, -0)				
					self.Runes[i].bg:SetTexture(Smoothv2)
					self.Runes[i].bg.multiplier = 0.34
				end
			elseif unit == "player" and (playerClass =="MONK" or playerClass =="PALADIN" or playerClass =="PRIEST" or playerClass =="WARLOCK") then
				local ClassIcons = {}
				for index = 1, 6 do
					local Icon = self:CreateTexture(nil, 'BORDER')

					-- Position and size.
					Icon:SetSize(16, 16)
					Icon:SetTexture([[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_combo]]);
					Icon:SetPoint('TOPLEFT', self.Power, 'BOTTOMLEFT', index * Icon:GetWidth(), -3)
					
					
					Icon.bg = self:CreateTexture(nil, "BACKGROUND")
					Icon.bg:SetSize(16, 16)
					Icon.bg:SetTexture([[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_combo]]);
					Icon.bg:SetVertexColor(.4, .4, .4, .7)
					Icon.bg:SetAllPoints(Icon)

					ClassIcons[index] = Icon
				end
			end
		end
	end
	do -- setup items, icons, and text
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = 1/2,
		}
		
		local items = CreateFrame("Frame",nil,self);
		items:SetFrameStrata("BACKGROUND");
		items:SetAllPoints(self);
		items:SetFrameLevel(4);
		items.low = CreateFrame("Frame",nil,self);
		items.low:SetFrameStrata("BACKGROUND");
		items.low:SetAllPoints(self.Portrait);
		items.low:SetFrameLevel(1);
		
		self.Name = items:CreateFontString();
		spartan:FormatFont(self.Name, 12, "Player")
		self.Name:SetSize(self:GetWidth(), 12);
		self.Name:SetJustifyH("CENTER");
		self.Name:SetJustifyV("BOTTOM");
		self.Name:SetPoint("BOTTOMLEFT",self,"TOPLEFT",0,0);
		self.Name:SetPoint("BOTTOMRIGHT",self,"TOPRIGHT",0,0);
		self:Tag(self.Name, "[difficulty][level] [SUI_ColorClass][name]");
		
		self.RareElite = items.low:CreateTexture(nil,"ARTWORK", nil, -5);
		self.RareElite:SetSize(150, 70);
		self.RareElite:SetPoint("BOTTOM",self.Health,"TOP",0,0);
		self.RareElite.small = true
		
		self.LFDRole = items:CreateTexture(nil,"BORDER");
		self.LFDRole:SetSize(18, 18);
		self.LFDRole:SetPoint("CENTER",items,"TOPLEFT",0,0);
		self.LFDRole:SetTexture(lfdrole);
		self.LFDRole:SetAlpha(.75);
		
		self.PvP = items:CreateTexture(nil,"BORDER");
		self.PvP:SetSize(25, 25);
		self.PvP:SetPoint("CENTER",self.Portrait,"BOTTOMLEFT",0,0);
		self.PvP.Override = pvpIcon
		
		self.LevelSkull = items:CreateTexture(nil,"ARTWORK");
		self.LevelSkull:SetSize(16, 16);
		self.LevelSkull:SetPoint("LEFT",self.Name,"LEFT");
		
		self.RaidIcon = items:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetSize(24, 24);
		self.RaidIcon:SetPoint("CENTER",items,"RIGHT",2,-4);
		
		self.StatusText = items:CreateFontString(nil, "OVERLAY", "SUI_FontOutline22");
		self.StatusText:SetPoint("CENTER",items,"CENTER");
		self.StatusText:SetJustifyH("CENTER");
		self:Tag(self.StatusText, "[afkdnd]");
		
		self.CPoints = items:CreateFontString(nil, "BORDER","SUI_FontOutline13");
		self.CPoints:SetPoint("TOPLEFT",items,"BOTTOMRIGHT",8,-4);
		for i = 1, 5 do
			self.CPoints[i] = items:CreateTexture(nil,"OVERLAY");
			self.CPoints[i]:SetTexture([[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_combo]]);
			if (i == 1) then self.CPoints[1]:SetPoint("LEFT",self.CPoints,"RIGHT",1,-1); else 
				self.CPoints[i]:SetPoint("LEFT",self.CPoints[i-1],"RIGHT",-2,0);
			end
		end
		items:SetScript("OnUpdate",function()
			if self.CPoints then
				local cp = GetComboPoints("player","target");
				self.CPoints:SetText( (cp > 0 and cp) or "");
			end
		end);
	end

	self.TextUpdate = PostUpdateText;
	self.ColorUpdate = PostUpdateColor;
	return self;
end

local CreateUnitFrame = function(self,unit)
	self.colors = module.colors;
	
	return ((unit == "player" and MakeLargeFrame(self,unit))
	or (unit == "target" and MakeLargeFrame(self,unit))
	or MakeSmallFrame(self,unit));
end

local CreateUnitFrameParty = function(self,unit)
	self:HookScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			PartyFrames.party.mover:Show();
			DBMod.PartyFrames.moved = true;
			PartyFrames.party:SetMovable(true);
			PartyFrames.party:StartMoving();
		end
	end);
	self:HookScript("OnMouseUp",function(self,button)
		PartyFrames.party.mover:Hide();
		PartyFrames.party:StopMovingOrSizing();
		local Anchors = {}
		Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = PartyFrames.party:GetPoint()
		for k,v in pairs(Anchors) do
			DBMod.PartyFrames.Anchors[k] = v
		end
	end);
	
	if DB.Styles.Minimal.PartyFramesSize ~= nil and DB.Styles.Minimal.PartyFramesSize == "small" then
		return MakeSmallFrame(self,unit)
	else
		return MakeLargeFrame(self,unit,150)
	end
end

local CreateUnitFrameRaid = function(self,unit)
	self:HookScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			spartan.RaidFrames.mover:Show();
			DBMod.RaidFrames.moved = true;
			spartan.RaidFrames:SetMovable(true);
			spartan.RaidFrames:StartMoving();
		end
	end);
	self:HookScript("OnMouseUp",function(self,button)
		spartan.RaidFrames.mover:Hide();
		spartan.RaidFrames:StopMovingOrSizing();
		local Anchors = {}
		Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = spartan.RaidFrames:GetPoint()
		for k,v in pairs(Anchors) do
			DBMod.RaidFrames.Anchors[k] = v
		end
	end);
	
	return MakeSmallFrame(self,unit)
end

SpartanoUF:RegisterStyle("Spartan_MinimalFrames", CreateUnitFrame);
SpartanoUF:RegisterStyle("Spartan_MinimalFrames_Party", CreateUnitFrameParty);
SpartanoUF:RegisterStyle("Spartan_MinimalFrames_Raid", CreateUnitFrameRaid);

function module:UpdateAltBarPositions()
	local classname, classFileName = UnitClass("player");	
	-- Druid EclipseBar
	EclipseBarFrame:ClearAllPoints();
	if DBMod.PlayerFrames.ClassBar.movement.moved then
		EclipseBarFrame:SetPoint(DBMod.PlayerFrames.ClassBar.movement.point,
		DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		DBMod.PlayerFrames.ClassBar.movement.xOffset,
		DBMod.PlayerFrames.ClassBar.movement.yOffset);
	else
		EclipseBarFrame:SetPoint("TOPRIGHT",PlayerFrames.player,"TOPRIGHT",157,12);
	end
	
	-- Monk Chi Bar (Hard to move but it is doable.)
	MonkHarmonyBar.Show = MonkHarmonyBar.Hide
	MonkHarmonyBar:Hide()
	
	--Paladin Holy Power
	PaladinPowerBar.Show = MonkHarmonyBar.Hide
	PaladinPowerBar:Hide()
	
	--Priest Power Frame
	PriestBarFrame.Show = MonkHarmonyBar.Hide
	PriestBarFrame:Hide()
	
	--Warlock Power Frame
	WarlockPowerFrame.Show = MonkHarmonyBar.Hide
	WarlockPowerFrame:Hide()
	
	-- relocate the AlternatePowerBar
	if classFileName == "DRUID" then
		PlayerFrameAlternateManaBar:Hide()
		PlayerFrameAlternateManaBar.Show = PlayerFrameAlternateManaBar.Hide
	elseif classFileName ~= "MONK" then
		PlayerFrameAlternateManaBar:ClearAllPoints();
		if DBMod.PlayerFrames.AltManaBar.movement.moved then
			PlayerFrameAlternateManaBar:SetPoint(DBMod.PlayerFrames.AltManaBar.movement.point,
			DBMod.PlayerFrames.AltManaBar.movement.relativeTo,
			DBMod.PlayerFrames.AltManaBar.movement.relativePoint,
			DBMod.PlayerFrames.AltManaBar.movement.xOffset,
			DBMod.PlayerFrames.AltManaBar.movement.yOffset);
		else
			PlayerFrameAlternateManaBar:SetPoint("TOPLEFT",PlayerFrames.player,"BOTTOMLEFT",40,0);
		end
	end
end

function module:PlayerFrames()
	SpartanoUF:SetActiveStyle("Spartan_MinimalFrames");
	
	for a,b in pairs(FramesList) do
		PlayerFrames[b] = SpartanoUF:Spawn(b,"SUI_"..b.."Frame");
		if b == "player" then
			PlayerFrames:SetupExtras()
		end
	end
	
	module:PositionFrame()

	module:UpdateAltBarPositions();
	
	if DBMod.PlayerFrames.BossFrame.display == true then
		for i = 1, MAX_BOSS_FRAMES do
			PlayerFrames.boss[i] = SpartanoUF:Spawn('boss'..i, 'SUI_Boss'..i)
			if i == 1 then
				PlayerFrames.boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
				PlayerFrames.boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
			else
				PlayerFrames.boss[i]:SetPoint('TOP', PlayerFrames.boss[i-1], 'BOTTOM', 0, -10)             
			end
		end
	end
end

function module:PositionFrame(b)
		if b == "player" or b == nil then PlayerFrames.player:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOM",-60,170); end
		if b == "pet" or b == nil then PlayerFrames.pet:SetPoint("RIGHT",PlayerFrames.player,"BOTTOMLEFT",-4,0); end
		
		if b == "target" or b == nil then PlayerFrames.target:SetPoint("LEFT",PlayerFrames.player,"RIGHT",120,0); end
		if b == "targettarget" or b == nil then PlayerFrames.targettarget:SetPoint("LEFT",PlayerFrames.target,"BOTTOMRIGHT",4,0); end
		
		if b == "focus" or b == nil then PlayerFrames.focus:SetPoint("BOTTOMLEFT",PlayerFrames.target,"TOP",0,30); end
		if b == "focustarget" or b == nil then PlayerFrames.focustarget:SetPoint("BOTTOMLEFT", PlayerFrames.focus, "BOTTOMRIGHT", 5, 0); end
		
		
		-- PlayerFrames.player:SetScale(DB.scale);
		for a,b in pairs(FramesList) do
			PlayerFrames[b]:SetScale(DB.scale);
			-- _G["SUI_"..b.."Frame"]:SetScale(DB.scale);
		end
end

function module:RaidFrames()
	SpartanoUF:SetActiveStyle("Spartan_MinimalFrames_Raid");
	
	local xoffset = 3
	local yOffset = -5
	local point = 'TOP'
	local columnAnchorPoint = 'LEFT'
	local groupingOrder = 'TANK,HEALER,DAMAGER,NONE'
	
	if DBMod.RaidFrames.mode == "GROUP" then
		groupingOrder = '1,2,3,4,5,6,7,8'
	end
	-- print(DBMod.RaidFrames.mode)
	-- print(groupingOrder)
	local raid = SpartanoUF:SpawnHeader(nil, nil, 'raid',
		"showRaid", DBMod.RaidFrames.showRaid,
		"showParty", DBMod.RaidFrames.showParty,
		"showPlayer", DBMod.RaidFrames.showPlayer,
		"showSolo", DBMod.RaidFrames.showSolo,
		'xoffset', xoffset,
		'yOffset', yOffset,
		'point', point,
		'groupBy', DBMod.RaidFrames.mode,
		'groupingOrder', groupingOrder,
		'sortMethod', 'index',
		'maxColumns', DBMod.RaidFrames.maxColumns,
		'unitsPerColumn', DBMod.RaidFrames.unitsPerColumn,
		'columnSpacing', DBMod.RaidFrames.columnSpacing,
		'columnAnchorPoint', columnAnchorPoint
	)
	
	return (raid)
end

function module:PartyFrames()
	module:Options_PartyFrames()
	SpartanoUF:SetActiveStyle("Spartan_MinimalFrames_Party");
	local party = SpartanoUF:SpawnHeader("SUI_PartyFrameHeader", nil, nil,
		"showRaid", DBMod.PartyFrames.showRaid,
		"showParty", DBMod.PartyFrames.showParty,
		"showPlayer", DBMod.PartyFrames.showPlayer,
		"showSolo", DBMod.PartyFrames.showSolo,
		"yOffset", -15,
		"xOffset", 0,
		"columnAnchorPoint", "TOPLEFT",
		"initial-anchor", "TOPLEFT");
		
	-- party:SetParent("SpartanUI");
	-- party:SetClampedToScreen(true);
	-- PartyMemberBackground.Show = function() return; end
	-- PartyMemberBackground:Hide();
	
	-- party:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -60)
	
	return (party)
end