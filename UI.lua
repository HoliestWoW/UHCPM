local addonName, UHCPM = ...
local UI = UHCPM.UI; local colors = UHCPM.colors

UI.healthVignette = CreateFrame("Frame", nil, UIParent); UI.healthVignette:SetAllPoints(); UI.healthVignette:SetFrameStrata("FULLSCREEN")
UI.topTex = UI.healthVignette:CreateTexture(nil, "BACKGROUND"); UI.topTex:SetPoint("TOPLEFT"); UI.topTex:SetPoint("TOPRIGHT"); UI.topTex:SetColorTexture(1, 1, 1, 1); UI.topTex:SetGradient("VERTICAL", colors.transparent, colors.bloodDark)
UI.botTex = UI.healthVignette:CreateTexture(nil, "BACKGROUND"); UI.botTex:SetPoint("BOTTOMLEFT"); UI.botTex:SetPoint("BOTTOMRIGHT"); UI.botTex:SetColorTexture(1, 1, 1, 1); UI.botTex:SetGradient("VERTICAL", colors.bloodDark, colors.transparent)
UI.leftTex = UI.healthVignette:CreateTexture(nil, "BACKGROUND"); UI.leftTex:SetPoint("TOPLEFT"); UI.leftTex:SetPoint("BOTTOMLEFT"); UI.leftTex:SetColorTexture(1, 1, 1, 1); UI.leftTex:SetGradient("HORIZONTAL", colors.bloodDark, colors.transparent)
UI.rightTex = UI.healthVignette:CreateTexture(nil, "BACKGROUND"); UI.rightTex:SetPoint("TOPRIGHT"); UI.rightTex:SetPoint("BOTTOMRIGHT"); UI.rightTex:SetColorTexture(1, 1, 1, 1); UI.rightTex:SetGradient("HORIZONTAL", colors.transparent, colors.bloodDark); UI.healthVignette:SetAlpha(0)

UI.darknessOverlay = CreateFrame("Frame", nil, UIParent); UI.darknessOverlay:SetAllPoints(); UI.darknessOverlay:SetFrameStrata("FULLSCREEN") 
UI.darknessTex = UI.darknessOverlay:CreateTexture(nil, "BACKGROUND"); UI.darknessTex:SetAllPoints(); UI.darknessTex:SetColorTexture(0, 0, 0); UI.darknessTex:SetAlpha(0)

UI.drownVignette = CreateFrame("Frame", nil, UIParent); UI.drownVignette:SetAllPoints(); UI.drownVignette:SetFrameStrata("FULLSCREEN") 
UI.drownTex = UI.drownVignette:CreateTexture(nil, "BACKGROUND"); UI.drownTex:SetAllPoints(); UI.drownTex:SetColorTexture(0.02, 0.08, 0.15); UI.drownVignette:SetAlpha(0)

UI.resVignette = CreateFrame("Frame", nil, UIParent); UI.resVignette:SetAllPoints(); UI.resVignette:SetFrameStrata("LOW"); UI.resVignette:SetFrameLevel(1)
UI.resTex = UI.resVignette:CreateTexture(nil, "BACKGROUND"); UI.resTex:SetPoint("BOTTOMLEFT"); UI.resTex:SetPoint("BOTTOMRIGHT"); UI.resTex:SetHeight(UIParent:GetHeight() * 0.35); UI.resTex:SetColorTexture(1, 1, 1, 1); UI.resTex:SetGradient("VERTICAL", colors.transparent, colors.transparent); UI.resVignette:SetAlpha(0)

UI.comboVignette = CreateFrame("Frame", nil, UIParent); UI.comboVignette:SetAllPoints(); UI.comboVignette:SetFrameStrata("LOW"); UI.comboVignette:SetFrameLevel(2)
UI.comboTex = UI.comboVignette:CreateTexture(nil, "BACKGROUND"); UI.comboTex:SetPoint("TOPLEFT"); UI.comboTex:SetPoint("TOPRIGHT"); UI.comboTex:SetColorTexture(1, 1, 1, 1); UI.comboVignette:SetAlpha(0)

function UHCPM.UpdateActionBars(isPreparing)
    local inCombat = InCombatLockdown()
    local showBars = isPreparing and not inCombat

    local parentBars = { "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft", "MicroButtonAndBagsBar" }
    for _, b in ipairs(parentBars) do if _G[b] then _G[b]:SetAlpha(showBars and 1 or 0); _G[b]:EnableMouse(showBars) end end
    
    local buttonPrefixes = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton", "StanceButton", "PetActionButton" }
    for _, prefix in ipairs(buttonPrefixes) do 
        for i = 1, 12 do 
            local btn = _G[prefix..i]
            if btn then 
                btn:EnableMouse(showBars) 
                local hk = _G[prefix..i.."HotKey"]
                if hk then hk:SetAlpha(showBars and 1 or 0) end
                
                local cd = _G[prefix..i.."Cooldown"]
                if cd then
                    cd:SetAlpha(showBars and 1 or 0)
                    cd:SetDrawBling(showBars)
                    cd:SetDrawEdge(showBars)
                end
            end 
        end 
    end
    
    local bags = { "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot" }
    for _, b in ipairs(bags) do local f = _G[b]; if f then f:EnableMouse(showBars) end end
    
    local micro = { "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton", "LFDMicroButton", "EJMicroButton", "CollectionsMicroButton", "MainMenuMicroButton", "StoreMicroButton", "HelpMicroButton" }
    for _, m in ipairs(micro) do local f = _G[m]; if f then f:EnableMouse(showBars) end end

    if BuffFrame then
        BuffFrame:SetAlpha(showBars and 1 or 0)
        if showBars then BuffFrame:Show() end
    end
end

local function KillProtectedFrame(frame)
    if frame and type(frame) == "table" and frame.Hide then frame:UnregisterAllEvents(); frame:Hide(); frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", 10000, -10000) end
end

function UHCPM.EnforceCameraAndPurgeUI()
    UIParent:UnregisterEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED")
    if not InCombatLockdown() then for _, f in ipairs({TargetFrame, PartyMemberFrame1, CompactRaidFrameManager, PlayerFrame, ComboFrame}) do KillProtectedFrame(f) end end
    
    -- Removed BuffFrame from the hide list
    for _, f in ipairs({MinimapCluster, Minimap}) do if f and f.Hide and not f.UHCPMHooked then f:Hide(); f:SetAlpha(0); f:EnableMouse(false); f:HookScript("OnShow", function(s) s:Hide() end); f.UHCPMHooked = true end end
    
    BuffFrame:ClearAllPoints(); BuffFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20); hooksecurefunc("BuffFrame_Update", function() for i=1, BUFF_MAX_DISPLAY do local b = _G["BuffButton"..i.."Border"]; if b then b:Hide() end end end)
    for _, art in ipairs({MainMenuBarLeftEndCap, MainMenuBarRightEndCap, MainMenuBarTexture0, MainMenuBarTexture1, MainMenuBarTexture2, MainMenuBarTexture3, MainMenuMaxLevelBar0, MainMenuMaxLevelBar1, MainMenuMaxLevelBar2, MainMenuMaxLevelBar3, ActionBarUpButton, ActionBarDownButton, SlidingActionBarTexture0, SlidingActionBarTexture1, StanceBarLeft, StanceBarMiddle, StanceBarRight}) do if art then art:Hide(); art:SetAlpha(0) end end
    if MainMenuBarPerformanceBarFrame then MainMenuBarPerformanceBarFrame:Hide(); MainMenuBarPerformanceBarFrame:SetScript("OnShow", function(s) s:Hide() end) end
    for _, bar in ipairs({"ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarLeftButton", "MultiBarRightButton"}) do
        for i=1, 12 do local m = _G[bar..i.."Name"]; if m then m:SetAlpha(0) end; local c = _G[bar..i.."Cooldown"]; if c then c:SetDrawBling(false); c:SetDrawEdge(false) end end
    end
    if MainMenuBarArtFrame then if MainMenuBarArtFrame.PageNumber then MainMenuBarArtFrame.PageNumber:Hide(); MainMenuBarArtFrame.PageNumber:SetAlpha(0) end; for i=1, MainMenuBarArtFrame:GetNumRegions() do local r = select(i, MainMenuBarArtFrame:GetRegions()); if r and r:GetObjectType() == "Texture" then r:SetTexture(nil) end end end
    GameTooltip:HookScript("OnShow", function(s) local _, i = s:GetItem(); local _, sp = s:GetSpell(); if not i and not sp then s:Hide() end end)
    BuffFrame:Show()
end

local restingFrame = CreateFrame("Frame", "UHPMResting", UIParent); restingFrame:SetSize(24, 24); restingFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -80); restingFrame:Hide()
local restTex = restingFrame:CreateTexture(nil, "OVERLAY"); restTex:SetAllPoints(); restTex:SetTexture("Interface\\CharacterFrame\\UI-StateIcon"); restTex:SetTexCoord(0, 0.5, 0, 0.421875); restTex:SetAlpha(0.8) 
restingFrame:RegisterEvent("PLAYER_UPDATE_RESTING"); restingFrame:SetScript("OnEvent", function() if IsResting() then restingFrame:Show() else restingFrame:Hide() end end)
if IsResting() then restingFrame:Show() end

local CVarProtector = CreateFrame("Frame"); CVarProtector:RegisterEvent("PLAYER_ENTERING_WORLD"); CVarProtector:RegisterEvent("CVAR_UPDATE")
local updateTimer = 0; CVarProtector:SetScript("OnUpdate", function(self, elapsed) if updateTimer > 0 then updateTimer = updateTimer - elapsed; if updateTimer <= 0 then CVarProtector:SetScript("OnUpdate", nil) end end end)
CVarProtector:SetScript("OnEvent", function(self, event, cvarName)
    local protectedCVars = { ["nameplateShowEnemies"] = "0", ["nameplateShowFriends"] = "0", ["nameplateShowAll"] = "0", ["test_cameraActionCamMode"] = "basic", ["test_cameraOverShoulder"] = "1.2", ["test_cameraTargetFocusEnemyEnable"] = "1", ["CameraKeepCharacterCentered"] = "0", ["CameraReduceUnexpectedMovement"] = "0", ["cameraSmoothStyle"] = "2", ["cameraYawMoveSpeed"] = "0", ["test_cameraTargetFocusInteractEnable"] = "1", ["test_cameraTargetFocusEnemyStrengthYaw"] = "1.0", ["test_cameraTargetFocusEnemyStrengthPitch"] = "0.75", ["cameraZoomSpeed"] = "0", ["cameraDistanceMaxZoomFactor"] = "1", ["nameplateMaxDistance"] = "5", ["enableFloatingCombatText"] = "0", ["CombatDamage"] = "0", ["CombatHealing"] = "0" }
    if event == "PLAYER_ENTERING_WORLD" then for cvar, val in pairs(protectedCVars) do SetCVar(cvar, val) end elseif event == "CVAR_UPDATE" and updateTimer <= 0 then local expected = protectedCVars[cvarName]; if expected and GetCVar(cvarName) ~= expected then SetCVar(cvarName, expected); updateTimer = 0.1 end end
end)