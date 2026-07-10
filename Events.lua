local addonName, UHCPM = ...
local state = UHCPM.state

local StateEngine = CreateFrame("Frame", "UHPMStateEngine")
StateEngine:RegisterEvent("UNIT_HEALTH"); StateEngine:RegisterEvent("UNIT_MAXHEALTH"); StateEngine:RegisterEvent("UNIT_POWER_UPDATE"); StateEngine:RegisterEvent("UNIT_MAXPOWER"); StateEngine:RegisterEvent("UNIT_DISPLAYPOWER"); StateEngine:RegisterEvent("PLAYER_TARGET_CHANGED"); StateEngine:RegisterEvent("PLAYER_REGEN_DISABLED"); StateEngine:RegisterEvent("PLAYER_REGEN_ENABLED"); StateEngine:RegisterEvent("PLAYER_ENTERING_WORLD"); StateEngine:RegisterEvent("ZONE_CHANGED_INDOORS"); StateEngine:RegisterEvent("ZONE_CHANGED"); StateEngine:RegisterEvent("ZONE_CHANGED_NEW_AREA"); StateEngine:RegisterEvent("MIRROR_TIMER_START"); StateEngine:RegisterEvent("MIRROR_TIMER_STOP"); StateEngine:RegisterEvent("UNIT_SPELLCAST_STOP"); StateEngine:RegisterEvent("UNIT_SPELLCAST_FAILED"); StateEngine:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED"); StateEngine:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
StateEngine:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED") -- Added as an absolute failsafe for instant casts

StateEngine:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        UHCPM.EnforceCameraAndPurgeUI()
        C_Timer.After(0.5, function()
            local curZ = GetCameraZoom(); if curZ ~= 3.0 then CameraZoomIn(50); C_Timer.After(0.1, function() CameraZoomOut(3.0); C_Timer.After(0.5, function() SaveView(5) end) end) else SaveView(5) end
        end)
        state.playerHealth = UnitHealth("player"); state.playerMaxHealth = UnitHealthMax("player"); state.playerCurrentPower = UnitPower("player"); state.playerMaxPower = UnitPowerMax("player"); state.playerPowerType = UnitPowerType("player")
        
        local initGrad = UHCPM.colors.powerGrads[state.playerPowerType] or {UHCPM.colors.transparent, UHCPM.colors.transparent}
        UHCPM.UI.resTex:SetGradient("VERTICAL", initGrad[1], initGrad[2])

        local maxCp = UnitPowerMax("player", 4); if maxCp == 0 then maxCp = 5 end; state.targetCpRatio = (GetComboPoints("player", "target") or 0) / maxCp; state.playerPowerRatio = state.playerMaxPower > 0 and (state.playerCurrentPower / state.playerMaxPower) or 0
        local px, py = UnitPosition("player")
        if UHCPM.IsDarkSubZone(GetMinimapZoneText()) then state.isIndoors = true; state.entranceX = px; state.entranceY = py else state.isIndoors = false; state.entranceX = nil; state.entranceY = nil end
        
        UHCPM.UpdateHeartVisuals(); if not InCombatLockdown() then UHCPM.UpdateActionBars(false) end
    elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") and unit == "player" then state.playerHealth = UnitHealth("player"); state.playerMaxHealth = UnitHealthMax("player"); UHCPM.UpdateHeartVisuals()
    elseif (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER") and unit == "player" then
        state.playerCurrentPower = UnitPower("player"); state.playerMaxPower = UnitPowerMax("player"); local oldType = state.playerPowerType; state.playerPowerType = UnitPowerType("player")
        if state.playerPowerType ~= oldType then
            local grad = UHCPM.colors.powerGrads[state.playerPowerType] or {UHCPM.colors.transparent, UHCPM.colors.transparent}
            UHCPM.UI.resTex:SetGradient("VERTICAL", grad[1], grad[2])
        end
        state.playerPowerRatio = state.playerMaxPower > 0 and (state.playerCurrentPower / state.playerMaxPower) or 0; local maxCp = UnitPowerMax("player", 4); if maxCp == 0 then maxCp = 5 end; state.targetCpRatio = (GetComboPoints("player", "target") or 0) / maxCp
    elseif event == "PLAYER_TARGET_CHANGED" then local maxCp = UnitPowerMax("player", 4); if maxCp == 0 then maxCp = 5 end; state.targetCpRatio = (GetComboPoints("player", "target") or 0) / maxCp
    elseif event == "PLAYER_REGEN_DISABLED" then UHCPM.UpdateActionBars(false); UHCPM.UpdateHeartVisuals() elseif event == "PLAYER_REGEN_ENABLED" then UHCPM.UpdateActionBars(true); UHCPM.UpdateHeartVisuals()
    elseif event == "MIRROR_TIMER_START" or event == "MIRROR_TIMER_STOP" then
        local asphyx = false; for i = 1, 3 do local timer, _, maxvalue = GetMirrorTimerInfo(i); if (timer == "BREATH" or timer == "EXHAUSTION") and maxvalue > 0 then asphyx = true end end; state.isAsphyxiating = asphyx
    
    -- Added UNIT_SPELLCAST_SUCCEEDED to fully clear state variables
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit == "player" then state.isCastingMagic = false; state.currentCastSchool = 0 end
    
    elseif (event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA") then
        local px, py = UnitPosition("player"); local isDark = UHCPM.IsDarkSubZone(GetMinimapZoneText())
        if isDark and not state.isIndoors then state.entranceX = px; state.entranceY = py; state.isIndoors = true elseif not isDark and state.isIndoors then state.isIndoors = false; state.entranceX = nil; state.entranceY = nil end
    end
end)