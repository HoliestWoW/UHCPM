local addonName, UHCPM = ...

UHCPM.state = {
    playerHealth = 100, playerMaxHealth = 100, playerPowerType = -1, playerCurrentPower = 0, playerMaxPower = 0,
    playerPowerRatio = 0, targetCpRatio = 0, isToxified = false, isAsphyxiating = false, isCastingMagic = false,
    isIndoors = false, entranceX = nil, entranceY = nil, currentCastSchool = 0, lightPulse = 0
}

UHCPM.UI = {}
UHCPM.constants = { MAX_FLASH_DURATION = 4.0, MAX_HEARTS = 10, LIGHT_SCHOOLS = bit.bor(2, 4, 64) }

-- Cached Colors (Zero allocation)
UHCPM.colors = {
    transparent = CreateColor(0, 0, 0, 0),
    bloodDark = CreateColor(0.12, 0, 0, 1),
    powerGrads = {
        [0] = { CreateColor(0.1, 0.4, 1, 0.5), CreateColor(0.1, 0.4, 1, 0) }, -- Mana
        [1] = { CreateColor(1, 0.1, 0, 0.5), CreateColor(1, 0.1, 0, 0) },     -- Rage
        [3] = { CreateColor(1, 0.8, 0, 0.4), CreateColor(1, 0.8, 0, 0) }      -- Energy
    }
}

UHCPM.coreFrame = CreateFrame("Frame", "UHProMaxCore", UIParent)

function UHCPM.RandomFloat() return math.random(0, 1000) / 1000 end

-- Hidden Tooltip Scanner for reading Wand damage types
local wandScanner = CreateFrame("GameTooltip", "UHPMWandScanner", nil, "GameTooltipTemplate")

-- Cache variables so we don't scan tooltips 60 times a second
local cachedLightLevel = 1.0
local lightCacheDirty = true

-- Tracker to only update the scan when equipment actually changes
local equipmentTracker = CreateFrame("Frame")
equipmentTracker:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
equipmentTracker:RegisterEvent("PLAYER_ENTERING_WORLD")
equipmentTracker:SetScript("OnEvent", function()
    lightCacheDirty = true
end)

function UHCPM.GetEquippedLightLevel()
    -- Return the cached value immediately to save framerate
    if not lightCacheDirty then return cachedLightLevel end

    local slots = {16, 17, 18}
    local keywords = {"torch", "lantern", "lamp", "beacon", "candle", "flame", "fire", "brazier", "glowing", "radiant", "luminous"}
    local bestLight = 1.0 
    
    for _, slot in ipairs(slots) do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local lowerLink = string.lower(itemLink)
            local isPhysicalLight = false
            
            -- 1. Check for physical light sources
            for _, keyword in ipairs(keywords) do 
                if string.find(lowerLink, keyword) then 
                    isPhysicalLight = true
                    if bestLight > 0.40 then bestLight = 0.40 end
                    break
                end 
            end
            
            -- 2. Check for Wands (Only if the item isn't already a torch)
            if not isPhysicalLight then
                local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = GetItemInfo(itemLink)
                
                if classID and classID == 2 and subclassID == 19 then 
                    -- [FIXED] Tooltips MUST have their owner set right before reading
                    wandScanner:SetOwner(UIParent, "ANCHOR_NONE")
                    wandScanner:ClearLines()
                    wandScanner:SetInventoryItem("player", slot)
                    
                    local foundValidMagic = false
                    for i = 2, wandScanner:NumLines() do 
                        local lineFrame = _G["UHPMWandScannerTextLeft" .. i]
                        if lineFrame then
                            local text = lineFrame:GetText()
                            if text then
                                local lowerText = string.lower(text)
                                if string.find(lowerText, "fire damage") or 
                                   string.find(lowerText, "arcane damage") or 
                                   string.find(lowerText, "holy damage") then
                                   
                                    foundValidMagic = true
                                    break
                                end
                            end
                        end
                    end
                    
                    -- Hide the tooltip to prevent UI bugs
                    wandScanner:Hide()
                    
                    if foundValidMagic and bestLight > 0.80 then 
                        bestLight = 0.80 
                    end
                end
            end
        end
    end
    
    -- Cache the result so we don't have to scan again until gear changes
    cachedLightLevel = bestLight
    lightCacheDirty = false
    
    return cachedLightLevel
end

function UHCPM.IsDarkSubZone(zoneName)
    if not zoneName then return false end
    local z = string.lower(zoneName)
    
    -- 1. Explicitly Bright Zones (Lava, glowing cities, etc.)
    if string.find(z, "ragefire") or string.find(z, "molten") or string.find(z, "searing") or string.find(z, "blackrock") or string.find(z, "forge") or string.find(z, "fire") or string.find(z, "woodshop") or string.find(z, "gnomeregan") or string.find(z, "moon") then 
        return false 
    end
    
    -- 2. Whole Zones/Instances that are ALWAYS dark (No indoor check needed)
    local darkZones = {"duskwood", "scholomance", "stratholme", "maraudon", "dire maul", "scarlet monastery", "shadowfang", "uldaman", "razorfen", "naxxramas", "sunken temple", "atal'hakkar"}
    for _, zone in ipairs(darkZones) do
        if string.find(z, zone) then return true end
    end
    
    -- 3. Dynamic Sub-Zones (Caves, Mines, Crypts) - REQUIRES being physically indoors
    local darkSubZones = {"mine", "cave", "crypt", "den", "lair", "tomb", "barrow", "skull rock", "tunnel", "hold", "hive", "deeps", "catacomb", "vault", "burrow", "grotto", "excavation", "cellar"}
    for _, subZone in ipairs(darkSubZones) do
        if string.find(z, subZone) then 
            -- The game's native API verifies if you actually crossed the threshold into the cave
            if IsIndoors and IsIndoors() then
                return true
            end
        end
    end
    
    return false
end

-- ==========================================
-- IMMERSIVE PET MANAGEMENT
-- ==========================================
local petFrameCentered = false
local petFrameTimer = nil

-- The callback function MUST be declared above the slash command
local function BanishPetFrame()
    if not petFrameCentered then return end
    
    if InCombatLockdown() then
        PetFrame:SetAlpha(0)
    else
        PetFrame:ClearAllPoints()
        PetFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10000, 10000)
        PetFrame:Hide()
    end
    
    petFrameCentered = false
    UHCPM.ShowAlert("Pet Frame Auto-Hidden.", 1.0, 0.2, 0.2)
end

SLASH_UHCPMPETMENU1 = "/pet"
SlashCmdList["UHCPMPETMENU"] = function()
    -- Block if no pet exists and frame is hidden
    if not petFrameCentered and not UnitExists("pet") then
        print("You don't have an active pet.")
        return
    end

    if InCombatLockdown() then
        UHCPM.ShowAlert("Cannot move UI in combat!", 1.0, 0.2, 0.2)
        return
    end

    if not petFrameCentered then
        -- Ensure the SavedVariables database exists
        UHCPM_Config = UHCPM_Config or {}
        
        -- Cooldown Check using real-world epoch time to persist through logouts
        local currentPetGUID = UnitGUID("pet")
        local currentTime = time() 
        local commandCooldown = 300 -- 5 minutes in seconds
        
        if UHCPM_Config.petCooldownGUID == currentPetGUID then
            -- Calculates the real-world time delta since the command was last used
            local timeSinceLast = currentTime - (UHCPM_Config.petCooldownTime or 0)
            if timeSinceLast < commandCooldown then
                local remaining = math.ceil(commandCooldown - timeSinceLast)
                print("Pet management is on cooldown. Please wait " .. remaining .. " seconds.")
                return
            end
        end
        
        -- Passed Cooldown! Log this successful attempt directly into the saved config database
        UHCPM_Config.petCooldownGUID = currentPetGUID
        UHCPM_Config.petCooldownTime = currentTime

        PetFrame:SetParent(UIParent)
        PetFrame:Show()
        PetFrame:SetAlpha(1)
        
        PetFrame:ClearAllPoints()
        PetFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
        
        petFrameCentered = true
        UHCPM.ShowAlert("Pet Frame Centered.\nAuto-hiding in 10s.", 0.2, 1.0, 0.2)
        
        if petFrameTimer then petFrameTimer:Cancel() end
        petFrameTimer = C_Timer.NewTimer(10, BanishPetFrame)
    else
        -- Manual override to hide it early
        if petFrameTimer then petFrameTimer:Cancel() end
        BanishPetFrame()
    end
end

local _, playerClass = UnitClass("player")

if playerClass == "HUNTER" then
    local PetHappinessFrame = CreateFrame("Frame", "UHCMPetHappiness", UIParent)
    PetHappinessFrame:SetSize(24, 24)
    PetHappinessFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100) 
    
    PetHappinessFrame:SetFrameStrata("HIGH") 
    PetHappinessFrame:SetClampedToScreen(true)

    local happTex = PetHappinessFrame:CreateTexture(nil, "BACKGROUND")
    happTex:SetAllPoints()
    happTex:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness")
    PetHappinessFrame:Hide()

    local PetTooltip = CreateFrame("Frame", nil, PetHappinessFrame, "BackdropTemplate")
    PetTooltip:SetPoint("BOTTOMLEFT", PetHappinessFrame, "TOPRIGHT", 5, 5)
    PetTooltip:SetSize(240, 55)
    PetTooltip:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12, insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    PetTooltip:SetBackdropColor(0, 0, 0, 0.9)
    PetTooltip:Hide()

    local ttTitle = PetTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ttTitle:SetPoint("TOPLEFT", 8, -8)
    ttTitle:SetText("Pet Happiness")

    local ttDesc = PetTooltip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ttDesc:SetPoint("TOPLEFT", ttTitle, "BOTTOMLEFT", 0, -4)
    ttDesc:SetJustifyH("LEFT")
    ttDesc:SetText("Indicates your pet's current mood.\nHold Shift and drag to move this icon.")

    PetHappinessFrame:SetMovable(true)
    PetHappinessFrame:EnableMouse(true)
    PetHappinessFrame:RegisterForDrag("LeftButton")

    PetHappinessFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then self:StartMoving() end
    end)
    PetHappinessFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if UHCPM_Config then
            UHCPM_Config.petIconX = self:GetLeft()
            UHCPM_Config.petIconY = self:GetBottom()
        end
    end)

    PetHappinessFrame:SetScript("OnEnter", function() PetTooltip:Show() end)
    PetHappinessFrame:SetScript("OnLeave", function() PetTooltip:Hide() end)

    local function UpdatePetHappiness(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            if UHCPM_Config and UHCPM_Config.petIconX and UHCPM_Config.petIconY then
                PetHappinessFrame:ClearAllPoints()
                PetHappinessFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", UHCPM_Config.petIconX, UHCPM_Config.petIconY)
            end
        end

        if not UnitExists("pet") then 
            PetHappinessFrame:Hide()
            return
        end
        
        local happiness = GetPetHappiness()
        if not happiness then return end
        
        PetHappinessFrame:Show()
        
        if happiness == 1 then 
            happTex:SetTexCoord(0.375, 0.5625, 0, 0.359375)
            happTex:SetVertexColor(1, 0.2, 0.2, 0.9)
        elseif happiness == 2 then 
            happTex:SetTexCoord(0.1875, 0.375, 0, 0.359375)
            happTex:SetVertexColor(1, 1, 0.2, 0.8)
        elseif happiness == 3 then 
            happTex:SetTexCoord(0, 0.1875, 0, 0.359375)
            happTex:SetVertexColor(0.2, 1, 0.2, 0.4)
        end
    end

    PetHappinessFrame:RegisterEvent("UNIT_HAPPINESS")
    PetHappinessFrame:RegisterEvent("UNIT_PET")
    PetHappinessFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    PetHappinessFrame:SetScript("OnEvent", UpdatePetHappiness)
end

SLASH_UHCPMLEAVEPARTY1 = "/lp"
SLASH_UHCPMLEAVEPARTY2 = "/leaveparty"
SlashCmdList["UHCPMLEAVEPARTY"] = function()
    if IsInGroup() then
        LeaveParty()
    else
        UHCPM.ShowAlert("You aren't in a party.", 1.0, 0.2, 0.2)
    end
end

-- Create a custom immersive alert frame for important events
local AlertFrame = CreateFrame("Frame", nil, UIParent)
AlertFrame:SetSize(400, 50)
AlertFrame:SetPoint("TOP", UIParent, "TOP", 0, -150)
AlertFrame:SetFrameStrata("HIGH")

AlertFrame.text = AlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
AlertFrame.text:SetAllPoints()
AlertFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
AlertFrame:SetAlpha(0)

-- Animation group for fading in and out
AlertFrame.anim = AlertFrame:CreateAnimationGroup()
local fadeIn = AlertFrame.anim:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.5); fadeIn:SetOrder(1)
local hold = AlertFrame.anim:CreateAnimation("Alpha")
hold:SetFromAlpha(1); hold:SetToAlpha(1); hold:SetDuration(2.0); hold:SetOrder(2)
local fadeOut = AlertFrame.anim:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetDuration(1.5); fadeOut:SetOrder(3)

-- Global function so you can use this for other immersive pop-ups later
function UHCPM.ShowAlert(message, r, g, b)
    AlertFrame.text:SetText(message)
    AlertFrame.text:SetTextColor(r or 1, g or 0.8, b or 0)
    AlertFrame.anim:Stop()
    AlertFrame.anim:Play()
end

-- Track group changes to trigger the alert
local wasInParty = false
local GroupTracker = CreateFrame("Frame")
GroupTracker:RegisterEvent("GROUP_ROSTER_UPDATE")
GroupTracker:RegisterEvent("PLAYER_ENTERING_WORLD")

GroupTracker:SetScript("OnEvent", function(self, event)
    local inParty = (GetNumGroupMembers() > 1)
    
    if event == "PLAYER_ENTERING_WORLD" then
        wasInParty = inParty
    elseif event == "GROUP_ROSTER_UPDATE" then
        if inParty and not wasInParty then
            UHCPM.ShowAlert("Joined Party\nType /lp to leave", 0.2, 1.0, 0.2) 
        elseif not inParty and wasInParty then
            UHCPM.ShowAlert("Left Party", 1.0, 0.2, 0.2)
        end
        wasInParty = inParty
    end
end)

-- ==========================================
-- UHCPM ITEM TOOLTIP DEBUGGER
-- ==========================================
SLASH_UHCPMDEBUG1 = "/wandtest"
SlashCmdList["UHCPMDEBUG"] = function()
    -- Check if an item is currently held on the mouse cursor
    local infoType, itemID, itemLink = GetCursorInfo()
    
    if infoType ~= "item" or not itemLink then
        print("UHCPM: Please pick up an item on your mouse cursor first, then type /wandtest")
        return
    end

    print("--- UHCPM Tooltip Debugger ---")
    print("Item:", itemLink)
    
    -- Verify the item classification
    local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = GetItemInfo(itemLink)
    print("ClassID:", classID, "| SubclassID:", subclassID)
    
    -- Create a fresh scanner frame just for this test
    local scanner = CreateFrame("GameTooltip", "UHPMDebugScanner", nil, "GameTooltipTemplate")
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:ClearLines()
    scanner:SetHyperlink(itemLink)
    
    -- Dump every single line of text on the left side of the tooltip
    print("Tooltip Lines:")
    for i = 1, scanner:NumLines() do
        local lineFrame = _G["UHPMDebugScannerTextLeft" .. i]
        local text = lineFrame and lineFrame:GetText() or "N/A"
        print(i .. ": [" .. text .. "]")
    end
    
    scanner:Hide()
    print("------------------------------")
end