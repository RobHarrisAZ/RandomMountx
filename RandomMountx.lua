local LAM = LibStub("LibAddonMenu-2.0")
local ZO_CallLaterId = 1
function zo_callLater(func, ms)
    local id = ZO_CallLaterId
    local name = "CallLaterFunction"..id
    ZO_CallLaterId = ZO_CallLaterId + 1
 
    EVENT_MANAGER:RegisterForUpdate(name, ms,
        function()
            EVENT_MANAGER:UnregisterForUpdate(name)
            func(id)
        end)
    return id
end
local function CreateSettingsMenu()
	--local defaults = RandomMount:DefaultSettings()
	local optionsData = {}
	table.insert(optionsData, {type = "header", name = zo_strformat("|c3f7fff<<1>>|r", GetString(RM_HEADING1))})
	local mounts = {}
	for id,obj in pairs(RandomMount.settings.mounts) do
		mounts[#mounts+1] = {
			type = "checkbox",
			name = obj.collectibleName,
			getFunc = function() return RandomMount.settings.mounts[id].use end,
			setFunc = function(value) RandomMount.settings.mounts[id].use = value end,
			default = true
		}
	end
	table.sort(mounts, function(a,b) return a.name<b.name end)
	for id,obj in ipairs(mounts) do
		table.insert(optionsData, obj)
	end

	table.insert(optionsData, {type = "header", name = zo_strformat("|c3f7fff<<1>>|r", GetString(RM_HEADING2))})
	local pets = {}
	for id,obj in pairs(RandomMount.settings.pets) do
		pets[#pets+1] = {
			type = "checkbox",
			name = obj.collectibleName,
			getFunc = function() return RandomMount.settings.pets[id].use end,
			setFunc = function(value) RandomMount.settings.pets[id].use = value end,
			default = true
		}
	end
	table.sort(pets, function(a,b) return a.name<b.name end)
	for id,obj in ipairs(pets) do
		table.insert(optionsData, obj)
	end

	local OptionsName = "RandomMountOptions"
	local panelData = {
		type = "panel",
		name = RandomMount.ADDON_NAME,
		displayName = zo_strformat("|cff8800<<1>>|r", RandomMount.ADDON_NAME),
		author = "Weolo, Infidelux",
		version = RandomMount.ADDON_VERSION,
		registerForRefresh = true,
		registerForDefaults = true,
		website = "http://www.esoui.com/downloads/info1984-RandomMount.html"
	}
	LAM:RegisterAddonPanel(OptionsName, panelData)
	LAM:RegisterOptionControls(OptionsName, optionsData)
end
local function OnPlayerActivated()
	RandomMount:OnPlayerActivated()
end
local function SummonMount()
	RandomMount:SummonMount()
end
local function OnMountedStateChanged(eventCode, mounted)
	if not mounted then
		-- Select a random mount for the next time the player mounts
		-- Need a delay here before switching the mount
		zo_callLater(SummonMount, 1200)
	end	
end
local function OnLoaded(eventType, addonName)
	local name = RandomMount.ADDON_NAME
	if addonName ~= name then return end
	EVENT_MANAGER:UnregisterForEvent(name, EVENT_ADD_ON_LOADED)
	local aa = ZO_SavedVars:NewCharacterIdSettings("RandomMountSettings", 1, nil, RandomMount:DefaultSettings())
	if aa.toCharacterId ~= true then --Changed to character settings v1.7
		local old = ZO_SavedVars:NewAccountWide("RandomMountSettings", 1, nil, RandomMount:DefaultSettings())
		if NonContiguousCount(old.mounts) > 0 then
			aa.currentMountId = old.currentMountId
			ZO_ShallowTableCopy(old.mounts, aa.mounts)
		end
		if NonContiguousCount(old.pets) > 0 then
			aa.currentPetId = old.currentPetId
			ZO_ShallowTableCopy(old.pets, aa.pets)
		end
		aa.toCharacterId = true
	end
	RandomMount.settings = aa
	EVENT_MANAGER:RegisterForEvent(name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
	EVENT_MANAGER:RegisterForEvent(name, EVENT_MOUNTED_STATE_CHANGED, OnMountedStateChanged)
end
local function OnZone(...)
	--RandomMount:SummonMount()
	RandomMount:SummonPet()
end

local RM_Object = ZO_Object:Subclass()
function RM_Object:New(...)
	local object = ZO_Object.New(self)
	object:Initialize(...)
	return object
end
function RM_Object:Initialize()
	self.ADDON_NAME = "RandomMountx"
	self.ADDON_VERSION = "1.7a"
	self.settings = {}
	self.player_activated = false
	self.mountChanged = GetTimeStamp()
	self.petChanged = GetTimeStamp()
end
function RM_Object:OnPlayerActivated()
	if self.player_activated then return end --Only the first time
	self.player_activated = true
	EVENT_MANAGER:UnregisterForEvent(self.ADDON_NAME, EVENT_PLAYER_ACTIVATED)
	self:GetMounts()
	CreateSettingsMenu()
	EVENT_MANAGER:RegisterForEvent(RandomMount.ADDON_NAME, EVENT_ZONE_CHANGED, OnZone)
end
function RM_Object:GetMounts()
	for categoryIndex=1, GetNumCollectibleCategories() do
		local _, _, numCollectibles, _, _, _ = GetCollectibleCategoryInfo(categoryIndex)
		for collectibleIndex=1, numCollectibles do
			local collectibleId = GetCollectibleId(categoryIndex, nil, collectibleIndex)
			local collectibleName, _, _, _, unlocked, _, _, categoryType = GetCollectibleInfo(collectibleId)
			if categoryType == COLLECTIBLE_CATEGORY_TYPE_MOUNT then
				if unlocked and not IsCollectibleBlocked(collectibleId) then
					if self.settings.mounts[collectibleId] then
						self.settings.mounts[collectibleId].collectibleName = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleName)
					else
						self.settings.mounts[collectibleId] = {
							collectibleName = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleName),
							use = true
						}
					end
				end
			end
			if categoryType == COLLECTIBLE_CATEGORY_TYPE_VANITY_PET then
				if unlocked and not IsCollectibleBlocked(collectibleId) then
					if self.settings.pets[collectibleId] then
						self.settings.pets[collectibleId].collectibleName = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleName)
					else
						self.settings.pets[collectibleId] = {
							collectibleName = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleName),
							use = true
						}
					end
				end
			end
		end
	end
end
function RM_Object:DefaultSettings()
	return {
		currentMountId = 0,
		currentPetId = 0,
		mounts = {},
		pets = {},
		toCharacterId = false
	}
end
function RM_Object:IsAssistantOut()
	return (GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_ASSISTANT) ~= 0)
end
function RM_Object:SummonMount()
	if not self:InPvP() then
		local t = {}
		for id,obj in pairs(self.settings.mounts) do
			if obj.use then
				--CHAT_SYSTEM:AddMessage("Adding Mount: " .. id)
				t[#t+1] = id
			end
		end
		if #t > 0 then
			local newMount = t[math.random(1, #t)]
			if (not IsMounted()) and (not IsCollectibleActive(newMount)) and IsCollectibleUsable(newMount) and (not IsUnitInCombat("player")) then-- and GetDiffBetweenTimeStamps(GetTimeStamp(), self.mountChanged)>5
				-- CHAT_SYSTEM:AddMessage("New MountId: " .. newMount)
				self.settings.currentMountId = newMount
				UseCollectible(newMount)
				self.mountChanged = GetTimeStamp()
			else
				-- Debug output- to see why the mount didn't change.
				-- This most commonly gets hit via the normal dismount keybind. Blocking to dismount doesn't 
				-- seem to have this issue as much
				-- CHAT_SYSTEM:AddMessage("Mount not available: " .. newMount)
				-- CHAT_SYSTEM:AddMessage("IsMounted:" .. (IsMounted() and 'true' or 'false'))
				-- CHAT_SYSTEM:AddMessage("IsActive:" .. (IsCollectibleActive(newMount) and 'true' or 'false'))
				-- CHAT_SYSTEM:AddMessage("IsCollectibleUsable:" .. (IsCollectibleUsable(newMount) and 'true' or 'false'))
				-- CHAT_SYSTEM:AddMessage("IsInCombat:" .. (IsUnitInCombat("player") and 'true' or 'false'))
			end
		
		end
	end
end
function RM_Object:SummonPet()
	if not self:InPvP() then
		local t = {}
		for id,obj in pairs(self.settings.pets) do
			if obj.use then
				t[#t+1] = id
			end
		end
		if #t > 0 then
			local newPet = t[math.random(1, #t)]
			if (not self:IsAssistantOut()) and (not IsCollectibleActive(newPet)) and IsCollectibleUsable(newPet) and GetDiffBetweenTimeStamps(GetTimeStamp(), self.petChanged)>5 and (not IsUnitInCombat("player")) then
				self.settings.currentPetId = newPet
				UseCollectible(newPet)
				self.petChanged = GetTimeStamp()
			end
		end
	end
end
function RM_Object:InPvP()
	return IsInAvAZone() or IsUnitPvPFlagged("player") or IsActiveWorldBattleground()
end
RandomMount = RM_Object:New()
EVENT_MANAGER:RegisterForEvent(RandomMount.ADDON_NAME, EVENT_ADD_ON_LOADED, OnLoaded)