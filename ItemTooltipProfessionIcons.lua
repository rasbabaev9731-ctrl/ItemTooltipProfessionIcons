local _, ItemProfConstants = ...

local frame = CreateFrame( "Frame" )

local previousItemID = -1
local itemIcons = ""
local iconSize

--local ITEM_VENDOR_FLAG = ItemProfConstants.VENDOR_ITEM_FLAG
local ITEM_DMF_FLAG = ItemProfConstants.DMF_ITEM_FLAG
local ITEM_PROF_FLAGS = ItemProfConstants.ITEM_PROF_FLAGS
local QUEST_FLAG = ItemProfConstants.QUEST_FLAG
local NUM_PROFS_TRACKED = ItemProfConstants.NUM_PROF_FLAGS
local PROF_TEXTURES = ItemProfConstants.PROF_TEXTURES

local showProfs
local showQuests
local profFilter
local questFilter
--local includeVendor
local showDMF

ItemProfConstants.configTooltipIconsRealm = GetRealmName()
ItemProfConstants.configTooltipIconsChar = UnitName( "player" )

-- Default configuration values
local configDefaultShowProfs = true
local configDefaultShowQuests = true
local configDefaultProfFlags = 0x3FF
local configDefaultQuestFlags = 0x3FFFFF
local configDefaultIncludeVendor = false
local configDefaultIconSize = 16
local configDefaultShowDMF = true



local function CreateItemIcons( itemFlags )

--[[
	if not includeVendor then
		-- Return if the item has the vendor flag
		local isVendor = bit.band( itemFlags, ITEM_VENDOR_FLAG )
		if isVendor ~= 0 then
			return nil
		end
	end
--]]	
	
	local t = {}
	
	if showProfs then
	
		local enabledFlags = bit.band( itemFlags, profFilter )
		for i=0, NUM_PROFS_TRACKED-1 do
			local bitMask = bit.lshift( 1, i )
			local isSet = bit.band( enabledFlags, bitMask )
			if isSet ~= 0 then
				t[ #t+1 ] = "|T"
				t[ #t+1 ] = PROF_TEXTURES[ bitMask ]
				t[ #t+1 ] = ":"
				t[ #t+1 ] = iconSize
				t[ #t+1 ] = "|t "
			end
		end
	end
	
	if showDMF then
	
		local isTicketItem = bit.band( itemFlags, ITEM_DMF_FLAG )
		if isTicketItem ~= 0 then
			t[ #t+1 ] = "|T"
			t[ #t+1 ] = PROF_TEXTURES[ ITEM_DMF_FLAG ]
			t[ #t+1 ] = ":"
			t[ #t+1 ] = iconSize
			t[ #t+1 ] = "|t "
		end
	end
	
	if showQuests then
		-- Quest filter flags start at 0x400, shift to bit 0 will align with config filter
		local questFlags = bit.rshift( itemFlags, 10 )
		local isSet = bit.band( questFlags, questFilter )
		
		-- Check if the quest is faction exclusive
		local isFactionQuest = bit.band( questFlags, 0x06 )
		if isFactionQuest ~= 0 then
			-- Ignore the quest if the configuration isnt tracking this faction
			local isFactionEnabled = bit.band( isFactionQuest, questFilter )
			local showFaction = bit.band( isFactionQuest, isFactionEnabled )
			if showFaction == 0 then
				isSet = 0
			end
			
			-- Both flags must be set if the faction quest was for a specific class/profession
			if isSet < 0x08 and questFlags >= 0x08 then
				isSet = 0
			end
		end
		
		if isSet ~= 0 then
			t[ #t+1 ] = "|T"
			t[ #t+1 ] = PROF_TEXTURES[ QUEST_FLAG ]
			t[ #t+1 ] = ":"
			t[ #t+1 ] = iconSize
			t[ #t+1 ] = "|t "
		end
	end

	return table.concat( t )
end


local function ModifyItemTooltip( tt ) 
		
	local itemName, itemLink = tt:GetItem() 
	if not itemName then return end
	
	-- For 3.3.5a compatibility - extract item ID from link directly
	local itemID = tonumber( string.match( itemLink, "item:(%d+):" ) )
	if not itemID then
		-- Alternative pattern for some link formats
		itemID = tonumber( string.match( itemLink, "item:(%d+)" ) )
	end
	
	if not itemID then
		return
	end
	
	-- Reuse the texture state if the item hasn't changed
	if previousItemID == itemID then
		tt:AddLine( itemIcons )
		return
	end
	
	-- Check if the item is a profession reagent
	local itemFlags = ITEM_PROF_FLAGS[ itemID ]
	if itemFlags == nil then
		-- Don't modify the tooltip
		return
	end
	
	-- Convert the flags into texture icons
	previousItemID = itemID
	itemIcons = CreateItemIcons( itemFlags )
	
	if itemIcons and itemIcons ~= "" then
		tt:AddLine( itemIcons )
	end
end


function ItemProfConstants:ConfigChanged()
	-- Initialize config if it doesn't exist
	if not ItemTooltipIconsConfig then
		ItemTooltipIconsConfig = {}
	end
	
	if not ItemTooltipIconsConfig[ ItemProfConstants.configTooltipIconsRealm ] then
		ItemTooltipIconsConfig[ ItemProfConstants.configTooltipIconsRealm ] = {}
	end
	
	if not ItemTooltipIconsConfig[ ItemProfConstants.configTooltipIconsRealm ][ ItemProfConstants.configTooltipIconsChar ] then
		ItemTooltipIconsConfig[ ItemProfConstants.configTooltipIconsRealm ][ ItemProfConstants.configTooltipIconsChar ] = {}
	end
	
	local userVariables = ItemTooltipIconsConfig[ ItemProfConstants.configTooltipIconsRealm ][ ItemProfConstants.configTooltipIconsChar ]
	
	-- Set defaults if values don't exist
	if userVariables.showProfs == nil then
		userVariables.showProfs = configDefaultShowProfs
	end
	
	if userVariables.showQuests == nil then
		userVariables.showQuests = configDefaultShowQuests
	end
	
	if userVariables.profFlags == nil then
		userVariables.profFlags = configDefaultProfFlags
	end
	
	if userVariables.questFlags == nil then
		userVariables.questFlags = configDefaultQuestFlags
	end
	
	if userVariables.includeVendor == nil then
		userVariables.includeVendor = configDefaultIncludeVendor
	end
	
	if userVariables.iconSize == nil then
		userVariables.iconSize = configDefaultIconSize
	end
	
	if userVariables.showDMF == nil then
		userVariables.showDMF = configDefaultShowDMF
	end

	-- Now load the values
	showProfs = userVariables.showProfs
	showQuests = userVariables.showQuests
	profFilter = userVariables.profFlags
	questFilter = userVariables.questFlags
	--includeVendor = userVariables.includeVendor
	iconSize = userVariables.iconSize
	showDMF = userVariables.showDMF
	
	previousItemID = -1		-- Reset line
end


local function InitFrame()
	GameTooltip:HookScript( "OnTooltipSetItem", ModifyItemTooltip )
	--ItemRefTooltip:HookScript( "OnTooltipSetItem", ModifyItemTooltip )
	
	-- Initialize configuration after variables are loaded
	frame:RegisterEvent("VARIABLES_LOADED")
	frame:SetScript("OnEvent", function(self, event)
		if event == "VARIABLES_LOADED" then
			ItemProfConstants:ConfigChanged()
		end
	end)
end


InitFrame()