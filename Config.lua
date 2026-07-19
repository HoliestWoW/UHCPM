local addonName, UHCPM = ...
UHCPM.OriginalState = { cvars = {}, chatPoints = {} }
local defaults = { 
    hideChat = false, 
    combatHearts = true, 
    hideErrors = true, 
    lowHealthAudio = true, 
    darknessAlpha = 0.95, 
    hasCalibrated = false, 
    reduceCameraMotion = false, 
	disableTargetTracking = false,
    hideActionBarArt = true, 
    showNPCNames = true 
}
local OptionsPanel = CreateFrame("Frame", "UHCPMOptionsPanel"); OptionsPanel.name = "Ultra Hardcore Pro Max"
local title = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 16, -16); title:SetText("UHCPM - Immersion Settings")
local function CreateCheckbox(name, labelText, yOffset, dbKey, callback)
    local cb = CreateFrame("CheckButton", name, OptionsPanel, "UICheckButtonTemplate"); cb:SetPoint("TOPLEFT", 16, yOffset); _G[name .. "Text"]:SetText(labelText)
    cb:SetScript("OnClick", function(self) UHCPM_Config[dbKey] = self:GetChecked(); if callback then callback(self:GetChecked()) end end); return cb
end

local function UpdateChatVisibility(isHidden)
    local targetAlpha = isHidden and 0 or 1
    
    SetCVar("socialChat", isHidden and "0" or "1")
    
    for i = 1, NUM_CHAT_WINDOWS do 
        local chat = _G["ChatFrame"..i]
        local tab = _G["ChatFrame"..i.."Tab"]
        
        if chat then 
            chat:EnableMouse(not isHidden)
            chat:SetAlpha(targetAlpha)
            
            if not chat.UHCPMHooked then
                hooksecurefunc(chat, "SetAlpha", function(self, alpha)
                    if UHCPM_Config and UHCPM_Config.hideChat and alpha > 0 then
                        self:SetAlpha(0)
                    end
                end)
                chat.UHCPMHooked = true
            end
        end 
        
        if tab then 
            tab:EnableMouse(not isHidden)
            tab:SetAlpha(targetAlpha)
            
            if not tab.UHCPMHooked then
                hooksecurefunc(tab, "SetAlpha", function(self, alpha)
                    if UHCPM_Config and UHCPM_Config.hideChat and alpha > 0 then
                        self:SetAlpha(0)
                    end
                end)
                tab.UHCPMHooked = true
            end
        end 
    end
    
    if QuickJoinToastButton then QuickJoinToastButton:SetAlpha(targetAlpha); QuickJoinToastButton:EnableMouse(not isHidden) end
    if ChatFrameMenuButton then ChatFrameMenuButton:SetAlpha(targetAlpha); ChatFrameMenuButton:EnableMouse(not isHidden) end
    if ChatFrameChannelButton then ChatFrameChannelButton:SetAlpha(targetAlpha); ChatFrameChannelButton:EnableMouse(not isHidden) end
end

local function UpdateErrorMessages(isHidden)
    if isHidden then UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE"); SetCVar("Sound_EnableErrorSpeech", "0") else UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE"); SetCVar("Sound_EnableErrorSpeech", "1") end
end

-- Capture the returned checkbox frames so we can update them later
local chatCb = CreateCheckbox("UHCPMChatToggle", "Hide Chat Box", -50, "hideChat", UpdateChatVisibility)
local heartCb = CreateCheckbox("UHCPMHeartToggle", "Fade Hearts Out of Combat", -80, "combatHearts", function() UHCPM.UpdateHeartVisuals() end)
local errorCb = CreateCheckbox("UHCPMErrorToggle", "Disable UI Error Text", -110, "hideErrors", UpdateErrorMessages)
local audioCb = CreateCheckbox("UHCPMAudioToggle", "Muffle Audio on Low Health", -140, "lowHealthAudio", nil)
local actionCamCb = CreateCheckbox("UHCPMActionCamToggle", "Reduce Camera Motion (Basic)", -170, "reduceCameraMotion", function(isChecked)
    SetCVar("test_cameraDynamicPitch", isChecked and "0" or "1")
    SetCVar("test_cameraHeadMovementStrength", isChecked and "0" or "1")
end)
local trackingCb = CreateCheckbox("UHCPMTrackingToggle", "Disable Camera Target Tracking", -200, "disableTargetTracking", function(isChecked)
    SetCVar("test_cameraTargetFocusEnemyEnable", isChecked and "0" or "1")
    SetCVar("test_cameraTargetFocusInteractEnable", isChecked and "0" or "1")
end)
local barArtCb = CreateCheckbox("UHCPMBarArtToggle", "Hide Action Bar Art", -230, "hideActionBarArt", function(isChecked)
    if UHCPM.UpdateActionBarArt then UHCPM.UpdateActionBarArt(isChecked) end
end)
local npcNamesCb = CreateCheckbox("UHCPMNPCNamesToggle", "Show NPC Names", -260, "showNPCNames", function(isChecked)
    SetCVar("UnitNameNPC", isChecked and "1" or "0")
end)
local calButton = CreateFrame("Button", "UHCPMCalOptionButton", OptionsPanel, "UIPanelButtonTemplate")
calButton:SetPoint("TOPLEFT", 16, -300)
calButton:SetSize(160, 26)
calButton:SetText("Calibrate Darkness")
calButton:SetScript("OnClick", function()
    if UHCPM_Calibration then 
        UHCPM_Calibration:Show() 
        if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then HideUIPanel(InterfaceOptionsFrame) end
    end
end)

-- ==========================================
-- RESTORE DEFAULTS LOGIC
-- ==========================================
local function RestoreDefaults()
    if not UHCPM_Config then return end
    
    for k, v in pairs(defaults) do 
        UHCPM_Config[k] = v 
    end
    
    chatCb:SetChecked(UHCPM_Config.hideChat)
    heartCb:SetChecked(UHCPM_Config.combatHearts)
    errorCb:SetChecked(UHCPM_Config.hideErrors)
    audioCb:SetChecked(UHCPM_Config.lowHealthAudio)
    actionCamCb:SetChecked(UHCPM_Config.reduceCameraMotion)
    barArtCb:SetChecked(UHCPM_Config.hideActionBarArt)
    npcNamesCb:SetChecked(UHCPM_Config.showNPCNames)
	trackingCb:SetChecked(UHCPM_Config.disableTargetTracking)
    UHCPM.UpdateHeartVisuals()
    UpdateChatVisibility(UHCPM_Config.hideChat)
    UpdateErrorMessages(UHCPM_Config.hideErrors)
    
    SetCVar("test_cameraDynamicPitch", UHCPM_Config.reduceCameraMotion and "0" or "1")
    SetCVar("test_cameraHeadMovementStrength", UHCPM_Config.reduceCameraMotion and "0" or "1")
    SetCVar("UnitNameNPC", UHCPM_Config.showNPCNames and "1" or "0")
    
    if UHCPM.UpdateActionBarArt then 
        UHCPM.UpdateActionBarArt(UHCPM_Config.hideActionBarArt) 
    end
    
    print("UHCPM: Settings restored to default.")
end

-- ==========================================
-- CUSTOM DEFAULTS BUTTON & POPUP
-- ==========================================
StaticPopupDialogs["UHCPM_CONFIRM_DEFAULTS"] = {
    text = "Reset all Ultra Hardcore Pro Max settings to their defaults?",
    button1 = YES,
    button2 = NO,
    OnAccept = function() RestoreDefaults() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local defaultsButton = CreateFrame("Button", "UHCPMMainDefaultsButton", OptionsPanel, "UIPanelButtonTemplate")
defaultsButton:SetPoint("TOPRIGHT", OptionsPanel, "TOPRIGHT", -16, -16)
defaultsButton:SetSize(96, 22) -- Matches standard Blizzard UI dimensions
defaultsButton:SetText("Defaults")
defaultsButton:SetScript("OnClick", function()
    StaticPopup_Show("UHCPM_CONFIRM_DEFAULTS")
end)

-- Legacy support fallback
OptionsPanel.default = RestoreDefaults

-- ==========================================
-- REGISTRATION
-- ==========================================
if Settings and Settings.RegisterCanvasLayoutCategory then 
    local category = Settings.RegisterCanvasLayoutCategory(OptionsPanel, OptionsPanel.name)
    Settings.RegisterAddOnCategory(category) 
else 
    InterfaceOptions_AddCategory(OptionsPanel) 
end

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
EventFrame:RegisterEvent("PLAYER_LOGOUT") -- Required for restoration

EventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        local cvarsToCache = {
            "chatBubbles", "Sound_EnableErrorSpeech", "test_cameraDynamicPitch", "test_cameraHeadMovementStrength",
            "gamma", "UnitNameNPC", "nameplateShowEnemies", "nameplateShowFriends", "nameplateShowAll",
            "test_cameraOverShoulder", "test_cameraTargetFocusEnemyEnable", "CameraKeepCharacterCentered",
            "CameraReduceUnexpectedMovement", "cameraSmoothStyle", "cameraYawMoveSpeed", "test_cameraTargetFocusInteractEnable",
            "test_cameraTargetFocusEnemyStrengthYaw", "test_cameraTargetFocusEnemyStrengthPitch", "cameraZoomSpeed",
            "cameraDistanceMaxZoomFactor", "nameplateMaxDistance", "enableFloatingCombatText", "CombatDamage", "CombatHealing",
            "cameraSavedDistance", "cameraSavedPitch", "cameraView"
        }
        for _, cvar in ipairs(cvarsToCache) do
            UHCPM.OriginalState.cvars[cvar] = GetCVar(cvar)
        end

        UHCPM_Config = UHCPM_Config or {}
        for k, v in pairs(defaults) do if UHCPM_Config[k] == nil then UHCPM_Config[k] = v end end
        
        chatCb:SetChecked(UHCPM_Config.hideChat)
        heartCb:SetChecked(UHCPM_Config.combatHearts)
        errorCb:SetChecked(UHCPM_Config.hideErrors)
        audioCb:SetChecked(UHCPM_Config.lowHealthAudio)
        actionCamCb:SetChecked(UHCPM_Config.reduceCameraMotion)
        barArtCb:SetChecked(UHCPM_Config.hideActionBarArt)
        npcNamesCb:SetChecked(UHCPM_Config.showNPCNames)
		trackingCb:SetChecked(UHCPM_Config.disableTargetTracking)
        UHCPM.UpdateHeartVisuals()
        UpdateChatVisibility(UHCPM_Config.hideChat)
        UpdateErrorMessages(UHCPM_Config.hideErrors)
        
        SetCVar("test_cameraDynamicPitch", UHCPM_Config.reduceCameraMotion and "0" or "1")
        SetCVar("test_cameraHeadMovementStrength", UHCPM_Config.reduceCameraMotion and "0" or "1")
        SetCVar("UnitNameNPC", UHCPM_Config.showNPCNames and "1" or "0")
        
        if UHCPM.UpdateActionBarArt then UHCPM.UpdateActionBarArt(UHCPM_Config.hideActionBarArt) end
        
        if not UHCPM_Config.hasCalibrated then
            C_Timer.After(1.0, function()
                if UHCPM_Calibration then UHCPM_Calibration:Show() end
            end)
            UHCPM_Config.hasCalibrated = true
        end

    elseif event == "PLAYER_LEAVING_WORLD" then 
        UHCPM.MuffleAudio(false) 
        
    elseif event == "PLAYER_LOGOUT" then
        UHCPM.isLoggingOut = true
        for cvar, val in pairs(UHCPM.OriginalState.cvars) do
            if val ~= nil then SetCVar(cvar, val) end
        end
    end
end)

-- ==========================================
-- CALIBRATION MENU (Full Screen Preview)
-- ==========================================
local calFrame = CreateFrame("Frame", "UHCPM_Calibration", UIParent)
calFrame:SetAllPoints() -- Stretches the frame to cover the entire screen
calFrame:SetFrameStrata("FULLSCREEN_DIALOG") -- Ensures it sits above all other UI
calFrame:Hide()
tinsert(UISpecialFrames, calFrame:GetName())

-- The full-screen cave screenshot
local cavePreview = calFrame:CreateTexture(nil, "BACKGROUND")
cavePreview:SetAllPoints()
cavePreview:SetTexture("Interface\\AddOns\\UHCPM\\cave_preview.tga") 
-- Note: A 256x256 image will stretch to fit your monitor. It may look slightly pixelated, 
-- but it provides accurate full-screen contrast and lighting data for calibration.

-- The full-screen darkness overlay
local darkOverlay = calFrame:CreateTexture(nil, "OVERLAY")
darkOverlay:SetAllPoints()

-- ==========================================
-- CONTROL PANEL (Invisible floating frame)
-- ==========================================
local controls = CreateFrame("Frame", "UHCPM_CalControls", calFrame)
controls:SetSize(350, 250) -- Slightly taller to fit the new text
controls:SetPoint("TOPLEFT", calFrame, "TOPLEFT", 40, -40) 

controls.title = controls:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
local titleFont, titleSize = controls.title:GetFont()
controls.title:SetFont(titleFont, titleSize, "OUTLINE")
controls.title:SetPoint("TOPLEFT", controls, "TOPLEFT", 0, 0)
controls.title:SetText("UHCPM Darkness Calibration")

-- The new instructions text
controls.instructions = controls:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
local instFont, instSize = controls.instructions:GetFont()
controls.instructions:SetFont(instFont, instSize, "OUTLINE")
controls.instructions:SetPoint("TOPLEFT", controls.title, "BOTTOMLEFT", 0, -8)
controls.instructions:SetText("Adjust the settings until you can barely see the kobold.")

-- ==========================================
-- 1. THE ALPHA SLIDER (Overlay)
-- ==========================================
local alphaSlider = CreateFrame("Slider", "UHCPM_AlphaSlider", controls, "OptionsSliderTemplate")
alphaSlider:SetPoint("TOPLEFT", controls, "TOPLEFT", 10, -70) -- Pushed down to clear instructions
alphaSlider:SetMinMaxValues(0.90, 0.99) 
alphaSlider:SetValueStep(0.01)
alphaSlider:SetObeyStepOnDrag(true)

_G[alphaSlider:GetName() .. 'Low']:SetText('Brighter')
_G[alphaSlider:GetName() .. 'High']:SetText('Darker')
_G[alphaSlider:GetName() .. 'Text']:SetText('Addon Darkness Limit')

alphaSlider:SetScript("OnValueChanged", function(self, value)
    darkOverlay:SetColorTexture(0, 0, 0, value)
    if UHCPM_Config then
        UHCPM_Config.darknessAlpha = value 
    end
end)

-- ==========================================
-- 2. THE GAMMA SLIDER (System Setting)
-- ==========================================
local gammaSlider = CreateFrame("Slider", "UHCPM_GammaSlider", controls, "OptionsSliderTemplate")
gammaSlider:SetPoint("TOPLEFT", controls, "TOPLEFT", 10, -130) -- Pushed down
gammaSlider:SetMinMaxValues(0.3, 2.8)
gammaSlider:SetValueStep(0.05)
gammaSlider:SetObeyStepOnDrag(true)

_G[gammaSlider:GetName() .. 'Low']:SetText('')
_G[gammaSlider:GetName() .. 'High']:SetText('')
_G[gammaSlider:GetName() .. 'Text']:SetText('Game System Gamma')

gammaSlider:SetScript("OnValueChanged", function(self, value)
    SetCVar("gamma", tostring(value))
    _G[self:GetName() .. 'Text']:SetText(string.format("Game System Gamma: %.2f", value))
end)

-- ==========================================
-- 3. RESET DEFAULTS BUTTON
-- ==========================================
local resetButton = CreateFrame("Button", "UHCPM_ResetButton", controls, "UIPanelButtonTemplate")
resetButton:SetPoint("TOPLEFT", controls, "TOPLEFT", 10, -190) -- Pushed down
resetButton:SetSize(120, 26)
resetButton:SetText("Reset Defaults")

resetButton:SetScript("OnClick", function()
    if UHCPM_Config then
        UHCPM_Config.darknessAlpha = 0.95
        alphaSlider:SetValue(0.95)
    end
    
    SetCVar("gamma", "1.0")
    gammaSlider:SetValue(1.0)
end)

-- ==========================================
-- 4. SAVE & CLOSE BUTTON
-- ==========================================
local closeButton = CreateFrame("Button", "UHCPM_CalCloseButton", controls, "UIPanelButtonTemplate")
closeButton:SetPoint("LEFT", resetButton, "RIGHT", 15, 0)
closeButton:SetSize(120, 26)
closeButton:SetText("Save & Close")

closeButton:SetScript("OnClick", function()
    calFrame:Hide()
end)

local escText = controls:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
escText:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -15)
escText:SetText("(You can also press ESC to save and exit)")

-- ==========================================
-- INITIALIZATION
-- ==========================================
calFrame:SetScript("OnShow", function(self)
    local savedAlpha = (UHCPM_Config and UHCPM_Config.darknessAlpha) or 0.95
    alphaSlider:SetValue(savedAlpha)
    darkOverlay:SetColorTexture(0, 0, 0, savedAlpha)
    
    local currentGamma = tonumber(GetCVar("gamma")) or 1.0
    gammaSlider:SetValue(currentGamma)
end)

SLASH_UHCPMCAL1 = "/uhcpm"
SlashCmdList["UHCPMCAL"] = function(msg)
    if msg == "cal" then
        if calFrame:IsShown() then calFrame:Hide() else calFrame:Show() end
    else
        print("UHCPM: Type '/uhcpm cal' to open the darkness calibration menu.")
    end
end