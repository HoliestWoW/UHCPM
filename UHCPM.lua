-- Addon: Ultra Hardcore Pro Max
-- Author: HoliestWoW
-- Module: OTS Survival Core

local UHProMax = CreateFrame("Frame", "UHProMaxCore", UIParent)

-------------------------------------------------
-- 0. CONFIGURATION & OPTIONS MENU
-------------------------------------------------
local defaults = {
    hideChat = false,
    combatHearts = false,
    hideErrors = false,
    lowHealthAudio = false,
}

local OptionsPanel = CreateFrame("Frame", "UHCPMOptionsPanel")
OptionsPanel.name = "Ultra Hardcore Pro Max"

local title = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("UHCPM - Immersion Settings")

-- Factory function (No longer sets the checked state immediately)
local function CreateCheckbox(name, labelText, yOffset, dbKey, callback)
    local cb = CreateFrame("CheckButton", name, OptionsPanel, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, yOffset)
    _G[name .. "Text"]:SetText(labelText)
    
    cb:SetScript("OnClick", function(self)
        UHCPM_Config[dbKey] = self:GetChecked()
        if callback then callback(self:GetChecked()) end
    end)
    return cb
end

-- Chat Box Toggle Callback
local function UpdateChatVisibility(isHidden)
    local targetAlpha = isHidden and 0 or 1
    for i = 1, NUM_CHAT_WINDOWS do
        if _G["ChatFrame"..i] then
            _G["ChatFrame"..i]:SetAlpha(targetAlpha)
        end
    end
    if isHidden then SetCVar("chatBubbles", "1") end
end

-- Error Message Toggle Callback
local function UpdateErrorMessages(isHidden)
    if isHidden then
        UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
        SetCVar("Sound_EnableErrorSpeech", "0")
    else
        UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
        SetCVar("Sound_EnableErrorSpeech", "1")
    end
end

-- Build the Checkboxes UI
local chatToggle = CreateCheckbox("UHCPMChatToggle", "Hide Chat Box (Rely on Chat Bubbles)", -50, "hideChat", UpdateChatVisibility)
local heartToggle = CreateCheckbox("UHCPMHeartToggle", "Fade Hearts Out of Combat (If Full Health)", -80, "combatHearts", nil)
local errorToggle = CreateCheckbox("UHCPMErrorToggle", "Disable UI Error Text & Speech (e.g., 'Out of Mana')", -110, "hideErrors", UpdateErrorMessages)
local audioToggle = CreateCheckbox("UHCPMAudioToggle", "Muffle World Audio on Low Health (Focus on Heartbeat)", -140, "lowHealthAudio", nil)

-- Register the Menu
if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(OptionsPanel, OptionsPanel.name)
    Settings.RegisterAddOnCategory(category)
else
    InterfaceOptions_AddCategory(OptionsPanel)
end

-- Volume Ducking Logic for the Low Health Filter
local originalVolumes = {}
local audioIsMuffled = false

function UHCPM_MuffleAudio(enable)
    if enable and not audioIsMuffled then
        originalVolumes.sfx = GetCVar("Sound_SFXVolume")
        originalVolumes.music = GetCVar("Sound_MusicVolume")
        originalVolumes.ambience = GetCVar("Sound_AmbienceVolume")
        
        SetCVar("Sound_SFXVolume", tostring(tonumber(originalVolumes.sfx or 1) * 0.15))
        SetCVar("Sound_MusicVolume", tostring(tonumber(originalVolumes.music or 1) * 0.15))
        SetCVar("Sound_AmbienceVolume", tostring(tonumber(originalVolumes.ambience or 1) * 0.15))
        audioIsMuffled = true
    elseif not enable and audioIsMuffled then
        if originalVolumes.sfx then
            SetCVar("Sound_SFXVolume", originalVolumes.sfx)
            SetCVar("Sound_MusicVolume", originalVolumes.music)
            SetCVar("Sound_AmbienceVolume", originalVolumes.ambience)
        end
        audioIsMuffled = false
    end
end

-- THE FIX: Wait for PLAYER_LOGIN before touching the SavedVariables
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
EventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- 1. Initialize the global table if it doesn't exist
        UHCPM_Config = UHCPM_Config or {}
        
        -- 2. Merge defaults to prevent nil errors
        for k, v in pairs(defaults) do
            if UHCPM_Config[k] == nil then 
                UHCPM_Config[k] = v 
            end
        end
        
        -- 3. Now that variables are loaded from disk, visually update the checkboxes
        chatToggle:SetChecked(UHCPM_Config.hideChat)
        heartToggle:SetChecked(UHCPM_Config.combatHearts)
        errorToggle:SetChecked(UHCPM_Config.hideErrors)
        audioToggle:SetChecked(UHCPM_Config.lowHealthAudio)
        
        -- 4. Apply the loaded settings to the game environment
        UpdateChatVisibility(UHCPM_Config.hideChat)
        UpdateErrorMessages(UHCPM_Config.hideErrors)
        
    elseif event == "PLAYER_LEAVING_WORLD" then
        -- Failsafe: Restore audio before logout so the user's CVars aren't permanently altered
        UHCPM_MuffleAudio(false) 
    end
end)

-------------------------------------------------
-- 1. THE UI PURGE & ACTION CAM (OTS & FOCUS)
-------------------------------------------------
local function CleanupBuffFrame()
    -- Apply a "Purity" aesthetic to the buff bar
    BuffFrame:ClearAllPoints()
    BuffFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20)
    
    -- Strip the messy borders from the existing buffs
    hooksecurefunc("BuffFrame_Update", function()
        for i = 1, BUFF_MAX_DISPLAY do
            local buff = _G["BuffButton" .. i]
            if buff then
                -- Hide the icon border/frame
                local border = _G["BuffButton" .. i .. "Border"]
                if border then border:Hide() end
            end
        end
    end)
end

-- Update your EnforceCameraAndPurgeUI function:
local function EnforceCameraAndPurgeUI()
    -- Kill the Experimental Camera Warning Popup
    UIParent:UnregisterEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED")

    -- A. The Over-The-Shoulder & Target Focus Cam (ActionCamPlus Method)
    SetCVar("test_cameraActionCamMode", "basic") 
    SetCVar("CameraKeepCharacterCentered", "0") 
    SetCVar("CameraReduceUnexpectedMovement", "0") 
    SetCVar("test_cameraOverShoulder", "1.2")
	SetCVar("cameraSmoothStyle", "2")
	SetCVar("cameraYawMoveSpeed", "0")
    
    -- Explicit Focus Tracking Strengths
    SetCVar("test_cameraTargetFocusEnemyEnable", "1") 
    SetCVar("test_cameraTargetFocusInteractEnable", "1") 
    SetCVar("test_cameraTargetFocusEnemyStrengthYaw", "1.0") 
    SetCVar("test_cameraTargetFocusEnemyStrengthPitch", "0.75") 

    -- B. The Ironclad Zoom Lock
    SetCVar("cameraZoomSpeed", "0") 
    SetCVar("cameraDistanceMaxZoomFactor", "1") 

    -- C. The True UI Purge
    local framesToKill = {
        MinimapCluster, Minimap, 
        BuffFrame, TargetFrame, PlayerFrame, 
        CompactRaidFrameManager, PartyMemberFrame1,
        ComboFrame 
    }
    for _, frame in ipairs(framesToKill) do
        if frame and type(frame) == "table" and frame.Hide then
            frame:Hide()
            frame:SetAlpha(0)
            frame:EnableMouse(false)
            frame:HookScript("OnShow", function(self) self:Hide() end) 
        end
    end
	
	CleanupBuffFrame()

    -- D. The Action Bar Art Purge (No Frills)
    local actionBarArt = {
        MainMenuBarLeftEndCap, MainMenuBarRightEndCap,
        MainMenuBarTexture0, MainMenuBarTexture1, MainMenuBarTexture2, MainMenuBarTexture3,
        MainMenuMaxLevelBar0, MainMenuMaxLevelBar1, MainMenuMaxLevelBar2, MainMenuMaxLevelBar3,
        ActionBarUpButton, ActionBarDownButton,
        SlidingActionBarTexture0, SlidingActionBarTexture1,
        StanceBarLeft, StanceBarMiddle, StanceBarRight
    }
    
    for _, art in ipairs(actionBarArt) do
        if art then
            art:Hide()
            art:SetAlpha(0)
        end
    end
	
	-- Hiding the Latency/Ping Bar
    if MainMenuBarPerformanceBarFrame then
        MainMenuBarPerformanceBarFrame:Hide()
        MainMenuBarPerformanceBarFrame:SetScript("OnShow", function(self) self:Hide() end)
    end

    -- Hiding Action Button Hotkeys (Numbers) and Macro Text
    local actionBars = {"ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarLeftButton", "MultiBarRightButton"}
    for _, barName in ipairs(actionBars) do
        for i = 1, 12 do
            local hotkey = _G[barName..i.."HotKey"]
            local macro = _G[barName..i.."Name"]
            if hotkey then hotkey:SetAlpha(0) end
            if macro then macro:SetAlpha(0) end
        end
    end

    -- Safely strip any lingering page numbers
    if MainMenuBarArtFrame and MainMenuBarArtFrame.PageNumber then
        MainMenuBarArtFrame.PageNumber:Hide()
        MainMenuBarArtFrame.PageNumber:SetAlpha(0)
    end

    -- Scorched earth: Strip all background textures from the master frame
    if MainMenuBarArtFrame then
        for i = 1, MainMenuBarArtFrame:GetNumRegions() do
            local region = select(i, MainMenuBarArtFrame:GetRegions())
            if region and region:GetObjectType() == "Texture" then
                region:SetTexture(nil)
            end
        end
    end

    -- E. Strict Tooltip Filtering
    GameTooltip:HookScript("OnShow", function(self)
        local _, item = self:GetItem()
        local _, spell = self:GetSpell()
        if not item and not spell then
            self:Hide()
        end
    end)

    -- F. Combat Text Suppression
    SetCVar("nameplateMaxDistance", "5")
    SetCVar("enableFloatingCombatText", "0") 
    SetCVar("CombatDamage", "0") 
    SetCVar("CombatHealing", "0")
	
	-- G. Chat Box Relocation
    ChatFrame1:ClearAllPoints()
    ChatFrame1:SetUserPlaced(true) -- Strict override to prevent the game from resetting it
    ChatFrame1:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -40) -- Anchors safely out of the way
end

-------------------------------------------------
-- 3. HEALTH, DARKNESS & OXYGEN VIGNETTES
-------------------------------------------------
local healthVignette = CreateFrame("Frame", nil, UIParent)
healthVignette:SetAllPoints()
healthVignette:SetFrameStrata("FULLSCREEN")

local bloodDark = CreateColor(0.12, 0, 0, 1)
local transparent = CreateColor(0, 0, 0, 0)

local topTex = healthVignette:CreateTexture(nil, "BACKGROUND")
topTex:SetPoint("TOPLEFT"); topTex:SetPoint("TOPRIGHT")
topTex:SetColorTexture(1, 1, 1, 1) 
topTex:SetGradient("VERTICAL", transparent, bloodDark)

local botTex = healthVignette:CreateTexture(nil, "BACKGROUND")
botTex:SetPoint("BOTTOMLEFT"); botTex:SetPoint("BOTTOMRIGHT")
botTex:SetColorTexture(1, 1, 1, 1)
botTex:SetGradient("VERTICAL", bloodDark, transparent)

local leftTex = healthVignette:CreateTexture(nil, "BACKGROUND")
leftTex:SetPoint("TOPLEFT"); leftTex:SetPoint("BOTTOMLEFT")
leftTex:SetColorTexture(1, 1, 1, 1)
leftTex:SetGradient("HORIZONTAL", bloodDark, transparent)

local rightTex = healthVignette:CreateTexture(nil, "BACKGROUND")
rightTex:SetPoint("TOPRIGHT"); rightTex:SetPoint("BOTTOMRIGHT")
rightTex:SetColorTexture(1, 1, 1, 1)
rightTex:SetGradient("HORIZONTAL", transparent, bloodDark)

healthVignette:SetAlpha(0)

local darknessOverlay = CreateFrame("Frame", nil, UIParent)
darknessOverlay:SetAllPoints()
darknessOverlay:SetFrameStrata("FULLSCREEN") 
local darknessTex = darknessOverlay:CreateTexture(nil, "BACKGROUND")
darknessTex:SetAllPoints()
darknessTex:SetColorTexture(0, 0, 0) 
darknessTex:SetAlpha(0)

-- Oxygen Deprivation (Drowning)
local drownVignette = CreateFrame("Frame", nil, UIParent)
drownVignette:SetAllPoints()
drownVignette:SetFrameStrata("FULLSCREEN") 
local drownTex = drownVignette:CreateTexture(nil, "BACKGROUND")
drownTex:SetAllPoints()
drownTex:SetColorTexture(0.02, 0.08, 0.15) 
drownVignette:SetAlpha(0)

local entranceX, entranceY = nil, nil
local isIndoors = false
local currentDarknessAlpha = 0

local function HasTorchEquipped()
    -- 1. Check BOTH Ranged (18) and Main/Off-hand (16, 17)
    local slots = {16, 17, 18}
    
    -- Expanded list to include "wand" and generic lighting terms
    local keywords = {"torch", "lantern", "lamp", "beacon", "candle", "flame", "fire", "brazier", "wand"}
    
    for _, slot in ipairs(slots) do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            -- Check by Name/Link keywords
            local lowerLink = string.lower(itemLink)
            for _, keyword in ipairs(keywords) do
                if string.find(lowerLink, keyword) then
                    return true
                end
            end
            
            -- Check by Item Type (Class 2 = Weapon)
            local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = GetItemInfo(itemLink)
            if classID == 2 and subclassID == 19 then -- 19 is the specific ID for Wands
                return true
            end
        end
    end
    
    return false
end

local function IsDarkSubZone(zoneName)
    if not zoneName then return false end
    local z = string.lower(zoneName)
    if string.find(z, "mine") or string.find(z, "cave") or string.find(z, "crypt") or 
       string.find(z, "den") or string.find(z, "lair") or string.find(z, "tomb") or 
       string.find(z, "barrow") or string.find(z, "duskwood") then
        return true
    end
    return false
end

-------------------------------------------------
-- 4. COMBAT LOG TRACKER (TOXINS & CASTS)
-------------------------------------------------
local activeToxins = {} 
local currentCastSchool = 0 

local function HasToxin()
    for i = 1, 40 do
        local name = UnitDebuff("player", i)
        if not name then break end
        if activeToxins[name] then 
            return true 
        end
    end
    return false
end

local CombatTracker = CreateFrame("Frame")
CombatTracker:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
CombatTracker:RegisterEvent("UNIT_AURA")

CombatTracker:SetScript("OnEvent", function(self, event)
    if event == "UNIT_AURA" then
        -- Clean up expired toxins
        for spellName in pairs(activeToxins) do
            local found = false
            for i = 1, 40 do
                if UnitDebuff("player", i) == spellName then
                    found = true
                    break
                end
            end
            if not found then
                activeToxins[spellName] = nil
            end
        end
        
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, arg12, arg13, arg14 = CombatLogGetCurrentEventInfo()
        
        -- TRACK YOUR OWN CASTING (For Spatial Illumination)
        if sourceGUID == UnitGUID("player") then
            if subEvent == "SPELL_CAST_START" or subEvent == "SPELL_CAST_SUCCESS" then
                currentCastSchool = arg14 
            end
        end
        
        -- TRACK TOXINS AGAINST YOU
        if destGUID == UnitGUID("player") then
            if subEvent == "SPELL_PERIODIC_DAMAGE" then
                local spellName = arg13
                if not activeToxins[spellName] then
                    activeToxins[spellName] = true
                end
            elseif subEvent == "SPELL_AURA_REMOVED" then
                local spellName = arg13
                if activeToxins[spellName] then
                    activeToxins[spellName] = nil
                end
            end
        end
    end
end)

-------------------------------------------------
-- 5. THE DIEGETIC HEALTH ENGINE (HEARTS)
-------------------------------------------------
local heartFrame = CreateFrame("Frame", "UHPMHearts", UIParent)
heartFrame:SetSize(520, 50) 
heartFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 350, 90)
heartFrame:SetFrameStrata("LOW")

local hearts = {}
local MAX_HEARTS = 10

-- Factory for physical hearts
local function CreateHeart(index)
    local frame = CreateFrame("Frame", nil, heartFrame)
    frame:SetSize(48, 48) 
    
    if index == 1 then
        frame:SetPoint("LEFT", heartFrame, "LEFT", 0, 0)
    else
        frame:SetPoint("LEFT", hearts[index-1].frame, "RIGHT", 4, 0)
    end

    local bgTex = frame:CreateTexture(nil, "BACKGROUND")
    bgTex:SetAllPoints()
    bgTex:SetTexture("Interface\\AddOns\\UHCPM\\heart.tga")
    bgTex:SetVertexColor(0.15, 0.15, 0.15) 

    local fgTex = frame:CreateTexture(nil, "ARTWORK")
    fgTex:SetPoint("LEFT", frame, "LEFT", 0, 0)
    fgTex:SetSize(48, 48) 
    fgTex:SetTexture("Interface\\AddOns\\UHCPM\\heart.tga")
    
    return { frame = frame, bgTex = bgTex, fgTex = fgTex }
end

for i = 1, MAX_HEARTS do
    table.insert(hearts, CreateHeart(i))
end

-------------------------------------------------
-- 6. DIEGETIC PARTICLE ENGINE (RESOURCES)
-------------------------------------------------
local resVignette = CreateFrame("Frame", nil, UIParent)
resVignette:SetAllPoints()
resVignette:SetFrameStrata("LOW") 
resVignette:SetFrameLevel(1)

local resTex = resVignette:CreateTexture(nil, "BACKGROUND")
resTex:SetPoint("BOTTOMLEFT")
resTex:SetPoint("BOTTOMRIGHT")
resTex:SetHeight(UIParent:GetHeight() * 0.35) 
resTex:SetColorTexture(1, 1, 1, 1)
resTex:SetGradient("VERTICAL", CreateColor(0,0,0,0), CreateColor(0,0,0,0))
resVignette:SetAlpha(0)

local comboVignette = CreateFrame("Frame", nil, UIParent)
comboVignette:SetAllPoints()
comboVignette:SetFrameStrata("LOW") 
comboVignette:SetFrameLevel(2)

local comboTex = comboVignette:CreateTexture(nil, "BACKGROUND")
comboTex:SetPoint("TOPLEFT")
comboTex:SetPoint("TOPRIGHT")
comboTex:SetColorTexture(1, 1, 1, 1)
comboTex:SetGradient("VERTICAL", CreateColor(0.7, 0, 0, 0), CreateColor(0.7, 0, 0, 0.8))
comboVignette:SetAlpha(0)

local currentComboRatio = 0
local lastPowerType = -1 

local UHPMParticles = CreateFrame("Frame", "UHPMParticleEngine", UIParent)
UHPMParticles:SetAllPoints()
UHPMParticles:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
UHPMParticles:SetFrameStrata("LOW") 

local particlePool = {}
local activeParticles = {}
local MAX_PARTICLES = 200

for i = 1, MAX_PARTICLES do
    local tex = UHPMParticles:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark") 
    tex:SetBlendMode("ADD") 
    tex:SetSize(16, 32) 
    tex:SetAlpha(0)
    tex:Hide()
    
    tex.isActive = false
    tex.pType = -1 
    tex.posX = 0; tex.posY = 0
    tex.velX = 0; tex.velY = 0
    tex.life = 0
    
    table.insert(particlePool, tex)
end

local function SpawnParticle(powerType, powerRatio)
    local p = nil
    for _, tex in ipairs(particlePool) do
        if not tex.isActive then p = tex; break end
    end
    if not p then return end 

    p.pType = powerType
    p.baseAlpha = 0.9 

    if powerType == 1 then
        p:SetVertexColor(0.9, 0.1, 0.0) 
        p.velY = math.random(30, 60)
        p:SetSize(12, 12) 
    elseif powerType == 0 then
        p:SetVertexColor(0.2, 0.6, 1.0) 
        p.velY = math.random(60, 100) 
        p:SetSize(math.random(12, 24), math.random(40, 60)) 
    elseif powerType == 3 then
        p:SetVertexColor(1.0, 0.9, 0.2) 
        p.velY = math.random(70, 110)
        p:SetSize(12, 12)
    else
        return
    end

    local screenWidth = UIParent:GetWidth()
    p.posX = math.random(-(screenWidth / 2.5), (screenWidth / 2.5)) 
    p.posY = 0 
    p.velX = (math.random() - 0.5) * 20 
    
    p.life = 1.0 
    p.isActive = true
    p:SetAlpha(p.baseAlpha) 
    p:Show()
    
    table.insert(activeParticles, p)
end

-------------------------------------------------
-- 7. THE MASTER ON-UPDATE LOOP
-------------------------------------------------
local timeSinceLastSpawn = 0
local timeSinceLastHeartbeat = 0 
local activeHeartbeatHandle = nil 

UHProMax:SetScript("OnUpdate", function(self, elapsed)
    
    -- A. The Immortal Camera & Nameplate Lock
    SetCVar("nameplateShowEnemies", "0")
    SetCVar("nameplateShowFriends", "0")
    SetCVar("nameplateShowAll", "0")
    
    SetCVar("test_cameraActionCamMode", "basic")
    SetCVar("test_cameraOverShoulder", "1.2")
    SetCVar("test_cameraTargetFocusEnemyEnable", "1")

    -- NEW: The Anti-Pan Hard Lock
    if IsMouseButtonDown("LeftButton") and not IsMouseButtonDown("RightButton") then
        SetView(5)
        SetView(5) -- Calling this twice instantly overrides the camera transition smoothing
    end

    local currentZoom = GetCameraZoom()
    local targetZoom = 3.0
    if currentZoom > 3.1 then
        CameraZoomIn(currentZoom - targetZoom)
    elseif currentZoom < 2.9 then
        CameraZoomOut(targetZoom - currentZoom)
    end

    -- B. Health Vignette Math (Dynamic Panic Audio)
    local hpCurrent = UnitHealth("player")
    local hpMax = UnitHealthMax("player")
    
    if UnitIsDeadOrGhost("player") then
        healthVignette:SetAlpha(0)
        timeSinceLastHeartbeat = 0
        if activeHeartbeatHandle then
            StopSound(activeHeartbeatHandle)
            activeHeartbeatHandle = nil
        end
        UHCPM_MuffleAudio(false)
    elseif hpMax > 0 then
        local hpRatio = hpCurrent / hpMax
        
        if hpRatio < 0.50 then 
            local baseSeverity = (0.50 - hpRatio) / 0.50 
            
            -- VISUAL MATH
            local heartRate = 4 + (baseSeverity * 10) 
            local throb = (math.sin(GetTime() * heartRate) * 0.08) * baseSeverity
            local animatedSeverity = math.max(baseSeverity + throb, 0)
            
            -- AUDIO MATH & MUFFLE
            if UHCPM_Config.lowHealthAudio then
                UHCPM_MuffleAudio(true)
            end

            local beatInterval = 1.2 - (baseSeverity * 0.8) 
            timeSinceLastHeartbeat = timeSinceLastHeartbeat + elapsed
            
            if timeSinceLastHeartbeat >= beatInterval then
                if activeHeartbeatHandle then
                    StopSound(activeHeartbeatHandle)
                end
                
                -- Play sound on the "Master" channel so it pierces through the muffled SFX
                local willPlay, soundHandle = PlaySoundFile("Interface\\AddOns\\UHCPM\\Heartbeat sound.ogg", "Master")
                if willPlay then
                    activeHeartbeatHandle = soundHandle
                end
                
                timeSinceLastHeartbeat = 0
            end
            
            local screenW = UIParent:GetWidth()
            local screenH = UIParent:GetHeight()
            
            topTex:SetHeight((screenH * 1.8) * animatedSeverity)
            botTex:SetHeight((screenH * 1.8) * animatedSeverity)
            leftTex:SetWidth((screenW * 1.8) * animatedSeverity)
            rightTex:SetWidth((screenW * 1.8) * animatedSeverity)

            healthVignette:SetAlpha(1)
        else
            healthVignette:SetAlpha(0)
            timeSinceLastHeartbeat = 0 
            UHCPM_MuffleAudio(false)
            
            if activeHeartbeatHandle then
                StopSound(activeHeartbeatHandle)
                activeHeartbeatHandle = nil
            end
        end
    end

    -- C. Spatial Darkness Math (Illumination & Torch Flicker)
    local targetDarknessAlpha = 0
    if isIndoors and entranceX and entranceY then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then
                local currentX, currentY = pos:GetXY()
                local dx = currentX - entranceX
                local dy = currentY - entranceY
                local distance = math.sqrt((dx * dx) + (dy * dy))
                targetDarknessAlpha = math.min(distance * 200, 0.98) 
            end
        end
    end

    local isCastingMagic = false
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        if currentCastSchool == 2 or currentCastSchool == 4 or currentCastSchool == 64 then
            isCastingMagic = true
        end
    end

    if isCastingMagic and targetDarknessAlpha > 0.10 then
        targetDarknessAlpha = 0.10 
    elseif HasTorchEquipped() and targetDarknessAlpha > 0.40 then
        targetDarknessAlpha = 0.40 
    end

    if currentDarknessAlpha < targetDarknessAlpha then
        currentDarknessAlpha = math.min(currentDarknessAlpha + (elapsed * 0.3), targetDarknessAlpha)
    elseif currentDarknessAlpha > targetDarknessAlpha then
        currentDarknessAlpha = math.max(currentDarknessAlpha - (elapsed * 2.5), targetDarknessAlpha)
    end

    local finalDarknessAlpha = currentDarknessAlpha
    if currentDarknessAlpha > 0.05 then
        local time = GetTime()
        if isCastingMagic then
            local magicPulse = math.sin(time * 20) * 0.015 
            finalDarknessAlpha = math.max(math.min(currentDarknessAlpha + magicPulse, 1), 0)
        else
            local slowWave = math.sin(time * 3) * 0.015
            local fastWave = math.cos(time * 7) * 0.01
            local jitter = (math.random() - 0.5) * 0.01 
            local erraticFlutter = slowWave + fastWave + jitter
            finalDarknessAlpha = math.max(math.min(currentDarknessAlpha + erraticFlutter, 1), 0)
        end
    end
    darknessTex:SetAlpha(finalDarknessAlpha)

    -- D. Organ Heart Math
    if hpMax > 0 and not UnitIsDeadOrGhost("player") then
        local activeHalfHearts = math.ceil((hpCurrent / hpMax) * (MAX_HEARTS * 2))
        local isToxified = HasToxin()
		
        -- The Fix: Using UnitAffectingCombat and ensuring config loaded safely
        local showHearts = true
        if UHCPM_Config and UHCPM_Config.combatHearts and not UnitAffectingCombat("player") and (hpCurrent >= hpMax) then
            showHearts = false
        end
        
        if showHearts then
            heartFrame:SetAlpha(1)
            -- Render Physical Health
            for i = 1, MAX_HEARTS do
                local h = hearts[i]
                local leftHalf = (i * 2) - 1
                local rightHalf = i * 2
                
                if activeHalfHearts >= rightHalf then
                    h.fgTex:SetWidth(48)
                    h.fgTex:SetTexCoord(0, 1, 0, 1)
                    h.fgTex:SetAlpha(1)
                    h.fgTex:SetVertexColor(isToxified and 0.4 or 0.85, isToxified and 0.8 or 0.1, isToxified and 0.2 or 0.1)
                elseif activeHalfHearts == leftHalf then
                    h.fgTex:SetWidth(24) 
                    h.fgTex:SetTexCoord(0, 0.5, 0, 1) 
                    h.fgTex:SetAlpha(1)
                    h.fgTex:SetVertexColor(isToxified and 0.4 or 0.85, isToxified and 0.8 or 0.1, isToxified and 0.2 or 0.1)
                else
                    h.fgTex:SetAlpha(0) 
                end
            end
            heartFrame:Show()
        else
            heartFrame:SetAlpha(0)
            heartFrame:Hide()
        end
    else
        heartFrame:Hide()
    end

    -- E. Particle Engine Physics
    for i = #activeParticles, 1, -1 do
        local p = activeParticles[i]
        
        p.posX = p.posX + (p.velX * elapsed)
        p.posY = p.posY + (p.velY * elapsed)
        p.life = p.life - (elapsed * 0.5) 
        
        if p.life <= 0 then
            p.isActive = false; p:Hide()
            table.remove(activeParticles, i)
        else
            local currentAlpha = p.life * p.baseAlpha
            
            if p.pType == 0 then
                p.posX = p.posX + math.random(-4, 4) 
                if math.random() > 0.6 then
                    p:SetAlpha(currentAlpha * 0.3) 
                else
                    p:SetAlpha(currentAlpha) 
                end
            else
                p.posX = p.posX + (math.sin(GetTime() * 3 + p.velY) * 0.5) 
                p:SetAlpha(currentAlpha)
            end
            p:SetPoint("CENTER", UHPMParticles, "BOTTOM", p.posX, p.posY)
        end
    end
    
    -- F. Lethality Haze (Combo Points)
    local cp = GetComboPoints("player", "target") or 0
    local targetCpRatio = cp / 5.0 
    
    if currentComboRatio < targetCpRatio then
        currentComboRatio = math.min(currentComboRatio + (elapsed * 5), targetCpRatio) 
    elseif currentComboRatio > targetCpRatio then
        currentComboRatio = math.max(currentComboRatio - (elapsed * 2), targetCpRatio)
    end
    
    if currentComboRatio > 0 then
        local screenH = UIParent:GetHeight()
        comboTex:SetHeight((screenH * 0.40) * currentComboRatio) 
        comboVignette:SetAlpha(currentComboRatio)
    else
        comboVignette:SetAlpha(0)
    end

    -- G. Resource Vignette & Particle Spawning Logic
    timeSinceLastSpawn = timeSinceLastSpawn + elapsed
    
    local currentPower = UnitPower("player")
    local maxPower = UnitPowerMax("player")
    local powerRatio = maxPower > 0 and (currentPower / maxPower) or 0
    local powerType = UnitPowerType("player")

    if powerType ~= lastPowerType then
        if powerType == 1 then
            resTex:SetGradient("VERTICAL", CreateColor(1, 0.1, 0, 0.5), CreateColor(1, 0.1, 0, 0))
        elseif powerType == 0 then
            resTex:SetGradient("VERTICAL", CreateColor(0.1, 0.4, 1, 0.5), CreateColor(0.1, 0.4, 1, 0))
        elseif powerType == 3 then
            resTex:SetGradient("VERTICAL", CreateColor(1, 0.8, 0, 0.4), CreateColor(1, 0.8, 0, 0))
        else
            resTex:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, 0))
        end
        lastPowerType = powerType
    end

    resVignette:SetAlpha(powerRatio)

    local shouldSpawn = false
    local intensity = 0

    if powerType == 1 then
        if currentPower >= 15 then
            shouldSpawn = true
            intensity = (currentPower - 15) / (maxPower - 15)
        end
    elseif powerType == 0 or powerType == 3 then
        if powerRatio >= 0.50 then
            shouldSpawn = true
            intensity = (powerRatio - 0.50) * 2 
        end
    end

    if shouldSpawn then
        local spawnRate = 0.10 - (intensity * 0.09) 
        if timeSinceLastSpawn >= spawnRate then
            SpawnParticle(powerType, powerRatio)
            timeSinceLastSpawn = 0
        end
    end
    
    -- H. Asphyxiation Engine (Drowning & Fatigue)
    local isAsphyxiating = false
    local asphyxRatio = 1
    local asphyxType = ""
    
    for i = 1, 3 do
        local timer, value, maxvalue = GetMirrorTimerInfo(i)
        if (timer == "BREATH" or timer == "EXHAUSTION") and maxvalue > 0 then
            isAsphyxiating = true
            asphyxRatio = value / maxvalue 
            asphyxType = timer
        end
    end

    if isAsphyxiating then
        local severity = 1 - asphyxRatio
        if asphyxType == "BREATH" then
            drownTex:SetColorTexture(0.02, 0.08, 0.15) 
        elseif asphyxType == "EXHAUSTION" then
            drownTex:SetColorTexture(0.1, 0.1, 0.1) 
        end
        drownVignette:SetAlpha(severity * 0.90) 
    else
        drownVignette:SetAlpha(0)
    end
    
    -- I. Dynamic Action Bar Manager (Preparation Mode)
    local isPreparing = false
    if (SpellBookFrame and SpellBookFrame:IsShown()) or (CharacterFrame and CharacterFrame:IsShown()) then
        isPreparing = true
    end
    
    if CursorHasSpell() or CursorHasItem() or CursorHasMacro() then
        isPreparing = true
    end

    local inCombat = InCombatLockdown()
    local actionBars = {
        "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight", 
        "MultiBarRight", "MultiBarLeft"
    }

    for _, barName in ipairs(actionBars) do
        local bar = _G[barName]
        if bar then
            if isPreparing and not inCombat then
                bar:SetAlpha(1)
                bar:EnableMouse(true)
            else
                bar:SetAlpha(0)
                bar:EnableMouse(false)
            end
        end
    end
end)

-------------------------------------------------
-- 8. EVENT TRIGGERS
-------------------------------------------------
UHProMax:RegisterEvent("ZONE_CHANGED_INDOORS")
UHProMax:RegisterEvent("ZONE_CHANGED")
UHProMax:RegisterEvent("ZONE_CHANGED_NEW_AREA")
UHProMax:RegisterEvent("PLAYER_ENTERING_WORLD") 

UHProMax:SetScript("OnEvent", function(self, event, ...)
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    local subZone = GetMinimapZoneText()

    if event == "PLAYER_ENTERING_WORLD" then
        EnforceCameraAndPurgeUI()
        
        -- Wait half a second for the UI and 3D world to fully render
        C_Timer.After(0.5, function()
            local currentZoom = GetCameraZoom()
            if currentZoom ~= 3.0 then
                CameraZoomIn(50) 
                C_Timer.After(0.1, function()
                    CameraZoomOut(3.0) 
                    -- THE FIX: Wait for the camera to finish moving backward before saving
                    C_Timer.After(0.5, function()
                        SaveView(5) 
                    end)
                end)
            else
                SaveView(5)
            end
        end)

        if pos then
            if IsDarkSubZone(subZone) then
                isIndoors = true
                entranceX, entranceY = -10, -10
            else
                isIndoors = false
                entranceX, entranceY = nil, nil
            end
        end
    end

    if (event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA") and pos then
        if IsDarkSubZone(subZone) and not isIndoors then
            entranceX, entranceY = pos:GetXY()
            isIndoors = true
        elseif not IsDarkSubZone(subZone) and isIndoors then
            isIndoors = false
            entranceX, entranceY = nil, nil
        end
    end
end)

-------------------------------------------------
-- 9. CRITICAL TRIAGE PROTOCOL (GROUP HUD)
-------------------------------------------------
local TriageFrame = CreateFrame("Frame", "UHPMTriage", UIParent)
TriageFrame:SetSize(200, 150)
TriageFrame:SetPoint("LEFT", UIParent, "LEFT", 40, 0) -- Anchored to the middle-left of the screen

local triageLines = {}

-- Create a dynamic text line for the 4 possible party members
for i = 1, 4 do
    local text = TriageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if i == 1 then
        text:SetPoint("TOPLEFT", TriageFrame, "TOPLEFT", 0, 0)
    else
        text:SetPoint("TOPLEFT", triageLines[i-1], "BOTTOMLEFT", 0, -12) -- Stacks them downward
    end
    
    text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE") 
    text:SetJustifyH("LEFT")
    text:SetAlpha(0) -- Hidden by default
    triageLines[i] = text
end

-- We only listen to efficient, group-specific events
TriageFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
TriageFrame:RegisterEvent("UNIT_HEALTH")
TriageFrame:RegisterEvent("UNIT_MAXHEALTH")
TriageFrame:RegisterEvent("UNIT_CONNECTION")

TriageFrame:SetScript("OnEvent", function(self, event, unit)
    -- Ignore health updates unless they specifically belong to a party member
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_CONNECTION" then
        if not (unit and string.match(unit, "^party%d$")) then return end
    end

    for i = 1, 4 do
        local partyUnit = "party"..i
        local line = triageLines[i]
        
        if UnitExists(partyUnit) then
            local name = UnitName(partyUnit)
            
            if not UnitIsConnected(partyUnit) then
                line:SetText(name .. " - OFFLINE")
                line:SetTextColor(0.5, 0.5, 0.5) -- Ash Gray
                line:SetAlpha(1)
            elseif UnitIsDeadOrGhost(partyUnit) then
                line:SetText(name .. " - DEAD")
                line:SetTextColor(0.4, 0.4, 0.4) -- Dark Gray
                line:SetAlpha(1)
            else
                local hp = UnitHealth(partyUnit)
                local maxHp = UnitHealthMax(partyUnit)
                
                if maxHp > 0 then
                    local ratio = hp / maxHp
                    
                    if ratio <= 0.50 then
                        local percent = math.floor(ratio * 100)
                        line:SetText(name .. " - " .. percent .. "%")
                        
                        -- Color shift for critical status
                        if ratio <= 0.20 then
                            line:SetTextColor(1, 0, 0) -- Bright Red
                        else
                            line:SetTextColor(0.85, 0.1, 0.1) -- Dark Blood Red
                        end
                        
                        line:SetAlpha(1)
                    else
                        line:SetAlpha(0) -- Dissolve into the shadows when healed above 50%
                    end
                end
            end
        else
            line:SetAlpha(0) -- Hide if the party slot is empty
        end
    end
end)

local function GetRelativeAngle(sourceGUID)
    local x1, y1 = UnitPosition("player")
    
    local sourceUnit = nil
    for i=1, 4 do 
        if UnitGUID("party"..i) == sourceGUID then sourceUnit = "party"..i end 
    end
    if UnitGUID("target") == sourceGUID then sourceUnit = "target" end
    
    if not sourceUnit then return nil end
    
    local x2, y2 = UnitPosition(sourceUnit)
    
    if not x2 or not y2 then return nil end
    
    local playerFacing = GetPlayerFacing()
    return math.atan2(y2 - y1, x2 - x1) - playerFacing
end

-------------------------------------------------
-- 10. HEART SHAKE (CRIT/CRUSH ONLY)
-------------------------------------------------
local ThreatEngine = CreateFrame("Frame")
ThreatEngine:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

ThreatEngine:SetScript("OnEvent", function(self, event)
    local timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID = CombatLogGetCurrentEventInfo()
    
    -- Only trigger if we are the ones getting hit
    if destGUID ~= UnitGUID("player") then return end

    local critical, crushing = false, false

    if subEvent == "SWING_DAMAGE" then
        -- Melee swings: critical is 18th, crushing is 20th
        critical = select(18, CombatLogGetCurrentEventInfo())
        crushing = select(20, CombatLogGetCurrentEventInfo())
    elseif subEvent == "SPELL_DAMAGE" or subEvent == "RANGE_DAMAGE" then
        -- Spells/Ranged: critical is 21st, crushing is 23rd
        critical = select(21, CombatLogGetCurrentEventInfo())
        crushing = select(23, CombatLogGetCurrentEventInfo())
    end
    
    if critical or crushing then
        if not heartFrame.shakeAnim then
            heartFrame.shakeAnim = heartFrame:CreateAnimationGroup()
            
            -- Jerk right
            local anim1 = heartFrame.shakeAnim:CreateAnimation("Translation")
            anim1:SetOffset(15, 0)
            anim1:SetDuration(0.05)
            anim1:SetOrder(1)
            
            -- Snap back to center
            local anim2 = heartFrame.shakeAnim:CreateAnimation("Translation")
            anim2:SetOffset(-15, 0)
            anim2:SetDuration(0.05)
            anim2:SetOrder(2)
        end
        heartFrame.shakeAnim:Play()
    end
end)

-------------------------------------------------
-- 11. BUFF FRAME PERSISTENCE
-------------------------------------------------
BuffFrame:Show()
BuffFrame:SetScript("OnShow", function(self) self:Show() end)

-------------------------------------------------
-- 12. RESTING INDICATOR (ZZZ)
-------------------------------------------------
local restingFrame = CreateFrame("Frame", "UHPMResting", UIParent)
restingFrame:SetSize(24, 24)
restingFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -80) 
restingFrame:Hide()

local restTex = restingFrame:CreateTexture(nil, "OVERLAY")
restTex:SetAllPoints()

restTex:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
restTex:SetTexCoord(0, 0.5, 0, 0.421875) 

restTex:SetAlpha(0.8) 

restingFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
restingFrame:SetScript("OnEvent", function()
    if IsResting() then
        restingFrame:Show()
    else
        restingFrame:Hide()
    end
end)

if IsResting() then restingFrame:Show() end