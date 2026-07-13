local addonName, UHCPM = ...

local timeSinceLastSpawn = 0; local timeSinceLastHeartbeat = 0; local activeHeartbeatHandle = nil; local leftClickHoldTime = 0; local lastPreparingState = false; local cameraLockTimer = 0.25; local zoomTimer = 0; local flutterTimer = 0; local targetFlutter = 0; local currentFlutter = 0; local currentDarknessAlpha = 0; local currentComboRatio = 0; local mapTimer = 0; local lastRedIntensity = -1

UHCPM.coreFrame:SetScript("OnUpdate", function(self, elapsed)
    local state = UHCPM.state; local UI = UHCPM.UI; local now = GetTime()

    -- Camera Lock: Prevents panning while holding left click
    if IsMouseButtonDown("LeftButton") and not IsMouseButtonDown("RightButton") then
        leftClickHoldTime = leftClickHoldTime + elapsed
        if leftClickHoldTime > 0.15 and not CursorHasItem() and not CursorHasSpell() and not IsMouselooking() then
            cameraLockTimer = cameraLockTimer + elapsed
            if cameraLockTimer >= 0.25 then 
                SetView(5) -- Force the view
				SetView(5)
                cameraLockTimer = 0 
            end
        end
    else leftClickHoldTime = 0; cameraLockTimer = 0.25 end

    zoomTimer = zoomTimer + elapsed
    if zoomTimer > 0.05 then
        zoomTimer = 0; local curZ = GetCameraZoom(); local targetZ = 2.125
        if math.abs(curZ - targetZ) > 0.01 then if curZ > targetZ then CameraZoomIn(curZ - targetZ) else CameraZoomOut(targetZ - curZ) end end
    end

    if UnitIsDeadOrGhost("player") then
        UI.healthVignette:SetAlpha(0); timeSinceLastHeartbeat = 0; if activeHeartbeatHandle then StopSound(activeHeartbeatHandle); activeHeartbeatHandle = nil end; UHCPM.MuffleAudio(false)
    elseif state.playerMaxHealth > 0 then
        local hpRatio = state.playerHealth / state.playerMaxHealth
        if hpRatio < 0.50 then 
            local base = (0.50 - hpRatio) / 0.50; local throb = (math.sin(now * (4 + (base * 10))) * 0.08) * base; local ani = math.max(base + throb, 0)
            if UHCPM_Config.lowHealthAudio then UHCPM.MuffleAudio(base) end
            timeSinceLastHeartbeat = timeSinceLastHeartbeat + elapsed
            if timeSinceLastHeartbeat >= (1.2 - (base * 0.8)) then
                if activeHeartbeatHandle then StopSound(activeHeartbeatHandle) end
                local willPlay, handle = PlaySoundFile("Interface\\AddOns\\UHCPM\\Heartbeat sound.ogg", "Dialog"); if willPlay then activeHeartbeatHandle = handle end; timeSinceLastHeartbeat = 0
            end
            local sw, sh = UIParent:GetWidth(), UIParent:GetHeight(); local th = math.min((sh * 1.25) * ani, sh * 0.75); local tw = math.min((sw * 1.25) * ani, sw * 0.75)
            UI.topTex:SetHeight(th); UI.botTex:SetHeight(th); UI.leftTex:SetWidth(tw); UI.rightTex:SetWidth(tw); UI.healthVignette:SetAlpha(1)
        else UI.healthVignette:SetAlpha(0); timeSinceLastHeartbeat = 0; UHCPM.MuffleAudio(false); if activeHeartbeatHandle then StopSound(activeHeartbeatHandle); activeHeartbeatHandle = nil end end
    end

    local ambientDarkness = 0
    if state.isIndoors and state.entranceX then
        local maxDarkness = (UHCPM_Config and UHCPM_Config.darknessAlpha) or 0.95
        local px, py = UnitPosition("player"); local distSq = ((px - state.entranceX) ^ 2) + ((py - state.entranceY) ^ 2); 
        ambientDarkness = math.min(math.max(0, math.sqrt(distSq) - 2.0) * 0.15, maxDarkness)
    end

    local targetAlpha = UnitIsDeadOrGhost("player") and 0 or ambientDarkness
    if ambientDarkness > 0.10 then 
        targetAlpha = math.min(targetAlpha, UHCPM.GetEquippedLightLevel())
        if state.isCastingMagic then targetAlpha = 0.0 end
    end
    
    if state.lightPulse > 0 then
        state.lightPulse = math.max(0, state.lightPulse - (elapsed * 0.5))
        targetAlpha = math.max(0, targetAlpha - state.lightPulse)
    end
    
    if currentDarknessAlpha < targetAlpha then 
        currentDarknessAlpha = math.min(currentDarknessAlpha + (elapsed * 0.3), targetAlpha)
    elseif currentDarknessAlpha > targetAlpha then 
        if state.isCastingMagic or state.lightPulse > 0 then 
            currentDarknessAlpha = math.max(currentDarknessAlpha - (elapsed * 5.0), targetAlpha)
        elseif ambientDarkness > 0.10 then 
            currentDarknessAlpha = math.max(currentDarknessAlpha - (elapsed * 0.05), targetAlpha) 
        else 
            currentDarknessAlpha = math.max(currentDarknessAlpha - (elapsed * 2.5), targetAlpha) 
        end 
    end
    
    local finalAlpha = currentDarknessAlpha
    if currentDarknessAlpha > 0.05 then
        if state.isCastingMagic then finalAlpha = math.max(math.min(currentDarknessAlpha + (math.sin(now * 30) * 0.04), 1), 0)
        else flutterTimer = flutterTimer + elapsed; if flutterTimer > 0.1 then targetFlutter = (UHCPM.RandomFloat() - 0.5) * 0.02; flutterTimer = 0 end; currentFlutter = currentFlutter + (targetFlutter - currentFlutter) * (elapsed * 10); finalAlpha = math.max(math.min(currentDarknessAlpha + (math.sin(now * 3) * 0.015) + (math.cos(now * 7) * 0.01) + currentFlutter, 1), 0) end
    end
    UI.darknessTex:SetAlpha(finalAlpha); UHCPM.UpdateParticles(elapsed)
    
    if currentComboRatio < state.targetCpRatio then currentComboRatio = math.min(currentComboRatio + (elapsed * 5), state.targetCpRatio) elseif currentComboRatio > state.targetCpRatio then currentComboRatio = math.max(currentComboRatio - (elapsed * 2), state.targetCpRatio) end
    if currentComboRatio > 0 then
        UI.comboTex:SetHeight(UIParent:GetHeight() * 0.10); local ri = 0.3 + (currentComboRatio * 0.7)
        if math.abs(ri - lastRedIntensity) > 0.01 then 
            UI.comboTex:SetGradient("VERTICAL", CreateColor(ri, 0, 0, 0), CreateColor(ri, 0, 0, 0.9)); 
            lastRedIntensity = ri 
        end
        local finalAlpha = currentComboRatio; if state.targetCpRatio >= 1.0 then finalAlpha = math.max(math.min(finalAlpha + (math.sin(now * 8) * 0.15), 1.0), 0) end; UI.comboVignette:SetAlpha(finalAlpha)
    else UI.comboVignette:SetAlpha(0) end

    timeSinceLastSpawn = timeSinceLastSpawn + elapsed; UI.resVignette:SetAlpha(state.playerPowerRatio)
    local shouldSpawn, intensity = false, 0
    if state.playerPowerType == 1 then if state.playerCurrentPower >= 15 then shouldSpawn = true; intensity = (state.playerCurrentPower - 15) / math.max(state.playerMaxPower - 15, 1) end
    elseif state.playerPowerType == 0 or state.playerPowerType == 3 then if state.playerPowerRatio >= 0.50 then shouldSpawn = true; intensity = (state.playerPowerRatio - 0.50) * 2 end end
    if shouldSpawn and timeSinceLastSpawn >= (0.10 - (intensity * 0.09)) then UHCPM.SpawnParticle(state.playerPowerType, state.playerPowerRatio); timeSinceLastSpawn = 0 end
    
    local targetDrownAlpha = 0
    local tunnelThickness = 0
    local at = ""
    
    for i = 1, 3 do 
        local timer, value, maxvalue, scale = GetMirrorTimerInfo(i)
        if (timer == "BREATH" or timer == "EXHAUSTION") and maxvalue and maxvalue > 0 then 
            at = timer
            local currentValue = GetMirrorTimerProgress(timer)
            if not currentValue then currentValue = value end
            
            if scale and scale < 0 then
                local missingRatio = 1 - (currentValue / maxvalue)
                
                targetDrownAlpha = missingRatio ^ 3 
                
                tunnelThickness = missingRatio ^ 5
            else
                targetDrownAlpha = 0 
                tunnelThickness = 0
            end
            break 
        end 
    end

    if at == "BREATH" then 
        UI.drownTex:SetColorTexture(0.02, 0.08, 0.15) 
    elseif at == "EXHAUSTION" then 
        UI.drownTex:SetColorTexture(0.1, 0.1, 0.1) 
    end

    targetDrownAlpha = math.max(0, math.min(0.95, targetDrownAlpha))
    
    local currentDrownAlpha = UI.drownVignette:GetAlpha()
    if currentDrownAlpha < targetDrownAlpha then
        currentDrownAlpha = math.min(currentDrownAlpha + (elapsed * 0.5), targetDrownAlpha)
    elseif currentDrownAlpha > targetDrownAlpha then
        currentDrownAlpha = math.max(currentDrownAlpha - (elapsed * 1.5), targetDrownAlpha)
    end
    
    UI.drownVignette:SetAlpha(currentDrownAlpha)

    if UI.drownTop then
        local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
        local th = math.max(1, sh * 0.75 * tunnelThickness)
        local tw = math.max(1, sw * 0.75 * tunnelThickness)
        
        UI.drownTop:SetHeight(th)
        UI.drownBot:SetHeight(th)
        UI.drownLeft:SetWidth(tw)
        UI.drownRight:SetWidth(tw)
    end
    
    if not InCombatLockdown() then
        local isPrep = ((SpellBookFrame and SpellBookFrame:IsShown()) or (CharacterFrame and CharacterFrame:IsShown()) or CursorHasSpell() or CursorHasItem() or CursorHasMacro()) and true or false
        if isPrep ~= lastPreparingState then UHCPM.UpdateActionBars(isPrep); lastPreparingState = isPrep end
        if MainMenuBar and MainMenuBar:GetAlpha() ~= (isPrep and 1 or 0) then UHCPM.UpdateActionBars(isPrep) end
    end
end)