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
UI.drownTex = UI.drownVignette:CreateTexture(nil, "BACKGROUND"); UI.drownTex:SetAllPoints(); UI.drownTex:SetColorTexture(0.02, 0.08, 0.15)
UI.drownTex:SetAlpha(0.6)

local black = CreateColor(0, 0, 0, 1)
UI.drownTop = UI.drownVignette:CreateTexture(nil, "ARTWORK"); UI.drownTop:SetPoint("TOPLEFT"); UI.drownTop:SetPoint("TOPRIGHT"); UI.drownTop:SetColorTexture(1, 1, 1, 1); UI.drownTop:SetGradient("VERTICAL", colors.transparent, black)
UI.drownBot = UI.drownVignette:CreateTexture(nil, "ARTWORK"); UI.drownBot:SetPoint("BOTTOMLEFT"); UI.drownBot:SetPoint("BOTTOMRIGHT"); UI.drownBot:SetColorTexture(1, 1, 1, 1); UI.drownBot:SetGradient("VERTICAL", black, colors.transparent)
UI.drownLeft = UI.drownVignette:CreateTexture(nil, "ARTWORK"); UI.drownLeft:SetPoint("TOPLEFT"); UI.drownLeft:SetPoint("BOTTOMLEFT"); UI.drownLeft:SetColorTexture(1, 1, 1, 1); UI.drownLeft:SetGradient("HORIZONTAL", black, colors.transparent)
UI.drownRight = UI.drownVignette:CreateTexture(nil, "ARTWORK"); UI.drownRight:SetPoint("TOPRIGHT"); UI.drownRight:SetPoint("BOTTOMRIGHT"); UI.drownRight:SetColorTexture(1, 1, 1, 1); UI.drownRight:SetGradient("HORIZONTAL", colors.transparent, black)

UI.drownVignette:SetAlpha(0)

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

function UHCPM.UpdateActionBarArt(isHidden)
    local targetAlpha = isHidden and 0 or 1
    
    -- These textures are dynamically sized by the WoW client. 
    -- Forcing them to :Show() or :Hide() breaks their layout. We only touch their alpha.
    local dynamicTextures = {StanceBarLeft, StanceBarMiddle, StanceBarRight, SlidingActionBarTexture0, SlidingActionBarTexture1}
    for _, tex in ipairs(dynamicTextures) do
        if tex then 
            tex:SetAlpha(targetAlpha) 
        end
    end

    local staticArt = {MainMenuBarLeftEndCap, MainMenuBarRightEndCap, MainMenuBarTexture0, MainMenuBarTexture1, MainMenuBarTexture2, MainMenuBarTexture3, MainMenuMaxLevelBar0, MainMenuMaxLevelBar1, MainMenuMaxLevelBar2, MainMenuMaxLevelBar3, ActionBarUpButton, ActionBarDownButton}
    for _, art in ipairs(staticArt) do
        if art then
            art:SetAlpha(targetAlpha)
            if isHidden then art:Hide() else art:Show() end
        end
    end

    if MainMenuBarPerformanceBarFrame then
        if isHidden then MainMenuBarPerformanceBarFrame:Hide() else MainMenuBarPerformanceBarFrame:Show() end
        if not MainMenuBarPerformanceBarFrame.UHCPMHooked then
            MainMenuBarPerformanceBarFrame:HookScript("OnShow", function(s)
                if UHCPM_Config and UHCPM_Config.hideActionBarArt then s:Hide() end
            end)
            MainMenuBarPerformanceBarFrame.UHCPMHooked = true
        end
    end

    if MainMenuBarArtFrame and MainMenuBarArtFrame.PageNumber then
        MainMenuBarArtFrame.PageNumber:SetAlpha(targetAlpha)
        if isHidden then MainMenuBarArtFrame.PageNumber:Hide() else MainMenuBarArtFrame.PageNumber:Show() end
    end
end

function UHCPM.EnforceCameraAndPurgeUI()
    UIParent:UnregisterEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED")
    if not InCombatLockdown() then for _, f in ipairs({TargetFrame, PartyMemberFrame1, CompactRaidFrameManager, PlayerFrame, ComboFrame}) do KillProtectedFrame(f) end end
    
    -- Removed BuffFrame from the hide list
    for _, f in ipairs({MinimapCluster, Minimap}) do if f and f.Hide and not f.UHCPMHooked then f:Hide(); f:SetAlpha(0); f:EnableMouse(false); f:HookScript("OnShow", function(s) s:Hide() end); f.UHCPMHooked = true end end
    
    BuffFrame:ClearAllPoints(); BuffFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20); hooksecurefunc("BuffFrame_Update", function() for i=1, BUFF_MAX_DISPLAY do local b = _G["BuffButton"..i.."Border"]; if b then b:Hide() end end end)
    for _, bar in ipairs({"ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarLeftButton", "MultiBarRightButton"}) do
        for i=1, 12 do local m = _G[bar..i.."Name"]; if m then m:SetAlpha(0) end; local c = _G[bar..i.."Cooldown"]; if c then c:SetDrawBling(false); c:SetDrawEdge(false) end end
    end
	local hideArt = (UHCPM_Config and UHCPM_Config.hideActionBarArt)
    if hideArt == nil then hideArt = true end
    UHCPM.UpdateActionBarArt(hideArt)

    if not GameTooltip.UHCPM_TooltipHooked then
        local function FilterUHCPMTooltip(s)
            local owner = s:GetOwner()
            
            if UHCPM_Config and UHCPM_Config.hideChat then
                if owner and owner.GetName then
                    local name = owner:GetName()
                    if name and string.match(name, "^ChatFrame") then
                        s:Hide()
                        return
                    end
                end
            end

            if TaxiFrame and TaxiFrame:IsShown() then return end
            if WorldMapFrame and WorldMapFrame:IsShown() then return end

            local _, item = s:GetItem()
            local _, spell = s:GetSpell()
            if item or spell then return end 

            if owner and owner.GetName and owner:GetName() then
                local name = owner:GetName()
                if string.match(name, "Talent") or string.match(name, "PlayerSpells") then
                    return
                end
            end

            local _, unit = s:GetUnit()
            if owner and (owner == UIParent or owner == WorldFrame) and not unit then 
                return 
            end

            s:Hide()
        end

        GameTooltip:HookScript("OnShow", FilterUHCPMTooltip)

        if TooltipDataProcessor then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
                if tooltip == GameTooltip then FilterUHCPMTooltip(tooltip) end
            end)
        else
            GameTooltip:HookScript("OnTooltipSetUnit", FilterUHCPMTooltip)
        end
        
        GameTooltip.UHCPM_TooltipHooked = true
    end
    
    BuffFrame:Show()
end

local restingFrame = CreateFrame("Frame", "UHPMResting", UIParent); restingFrame:SetSize(24, 24); restingFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -80); restingFrame:Hide()
local restTex = restingFrame:CreateTexture(nil, "OVERLAY"); restTex:SetAllPoints(); restTex:SetTexture("Interface\\CharacterFrame\\UI-StateIcon"); restTex:SetTexCoord(0, 0.5, 0, 0.421875); restTex:SetAlpha(0.8) 
restingFrame:RegisterEvent("PLAYER_UPDATE_RESTING"); restingFrame:SetScript("OnEvent", function() if IsResting() then restingFrame:Show() else restingFrame:Hide() end end)
if IsResting() then restingFrame:Show() end

local CVarProtector = CreateFrame("Frame"); CVarProtector:RegisterEvent("PLAYER_ENTERING_WORLD"); CVarProtector:RegisterEvent("CVAR_UPDATE")
local updateTimer = 0; CVarProtector:SetScript("OnUpdate", function(self, elapsed) if updateTimer > 0 then updateTimer = updateTimer - elapsed; if updateTimer <= 0 then CVarProtector:SetScript("OnUpdate", nil) end end end)
CVarProtector:SetScript("OnEvent", function(self, event, cvarName)
    if UHCPM.isLoggingOut then return end  
    local pitchAndHeadBob = (UHCPM_Config and UHCPM_Config.reduceCameraMotion) and "0" or "1"
    local targetTracking = (UHCPM_Config and UHCPM_Config.disableTargetTracking) and "0" or "1"
    local expectedNPCNames = (UHCPM_Config and UHCPM_Config.showNPCNames) and "1" or "0" 
    local protectedCVars = { 
        ["nameplateShowEnemies"] = "0", ["nameplateShowFriends"] = "0", ["nameplateShowAll"] = "0", 
        ["test_cameraDynamicPitch"] = pitchAndHeadBob, 
        ["test_cameraHeadMovementStrength"] = pitchAndHeadBob, 
        ["UnitNameNPC"] = expectedNPCNames,
        ["test_cameraOverShoulder"] = "1.2", 
        ["test_cameraTargetFocusEnemyEnable"] = targetTracking, 
        ["test_cameraTargetFocusInteractEnable"] = targetTracking, 
        ["CameraKeepCharacterCentered"] = "0", ["CameraReduceUnexpectedMovement"] = "0", 
        ["cameraSmoothStyle"] = "2", ["cameraYawMoveSpeed"] = "0", 
        ["test_cameraTargetFocusEnemyStrengthYaw"] = "1.0", ["test_cameraTargetFocusEnemyStrengthPitch"] = "0.75", 
        ["cameraZoomSpeed"] = "0", ["cameraDistanceMaxZoomFactor"] = "1", ["nameplateMaxDistance"] = "5", 
        ["enableFloatingCombatText"] = "0", ["CombatDamage"] = "0", ["CombatHealing"] = "0" 
    }
    
    if event == "PLAYER_ENTERING_WORLD" then for cvar, val in pairs(protectedCVars) do SetCVar(cvar, val) end elseif event == "CVAR_UPDATE" and updateTimer <= 0 then local expected = protectedCVars[cvarName]; if expected and GetCVar(cvarName) ~= expected then SetCVar(cvarName, expected); updateTimer = 0.1 end end
end)