local addonName, UHCPM = ...

local playerGUID = nil

local function GetUnitIDFromGUID(guid)
    if UnitGUID("target") == guid then return "target" end
    if UnitGUID("focus") == guid then return "focus" end
    for i = 1, 4 do if UnitGUID("party"..i) == guid then return "party"..i end end
    return nil
end

local function GetDistanceMultiplier(unitID)
    if not unitID then return 0.2 end 
    if CheckInteractDistance(unitID, 3) then return 1.0 end
    if CheckInteractDistance(unitID, 1) then return 0.5 end
    return 0.2
end

local activeToxins = {}; local CombatTracker = CreateFrame("Frame"); CombatTracker:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED"); CombatTracker:RegisterEvent("UNIT_AURA"); CombatTracker:RegisterEvent("PLAYER_ENTERING_WORLD")

local function UpdateToxinState()
    local hasTox = false; for k, v in pairs(activeToxins) do if v then hasTox = true; break end end; UHCPM.state.isToxified = hasTox; UHCPM.UpdateHeartVisuals()
end

CombatTracker:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then playerGUID = UnitGUID("player")
    elseif event == "UNIT_AURA" then
        if unit ~= "player" then return end
        local currentDebuffs = {}
        for i = 1, 40 do local name = UnitDebuff("player", i); if not name then break end; currentDebuffs[name] = true end
        for spellName in pairs(activeToxins) do if not currentDebuffs[spellName] then activeToxins[spellName] = nil end end
        UpdateToxinState()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, _, arg13, arg14, _, _, _, arg18, _, arg20, arg21, _, arg23 = CombatLogGetCurrentEventInfo()
        
        if sourceGUID == playerGUID then
            if subEvent == "SPELL_CAST_START" then
                if type(arg14) == "number" then UHCPM.state.currentCastSchool = arg14; UHCPM.state.isCastingMagic = (bit.band(arg14, UHCPM.constants.LIGHT_SCHOOLS) ~= 0) end
            end
        end
        if destGUID == playerGUID then
            if subEvent == "SPELL_PERIODIC_DAMAGE" then if not activeToxins[arg13] then activeToxins[arg13] = true; UpdateToxinState() end
            elseif subEvent == "SPELL_AURA_REMOVED" then if activeToxins[arg13] then activeToxins[arg13] = nil; UpdateToxinState() end end
        end
        
        -- Burn away the ambient darkness dynamically
        if subEvent == "SPELL_CAST_SUCCESS" or subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_HEAL" then
            if type(arg14) == "number" and (bit.band(arg14, UHCPM.constants.LIGHT_SCHOOLS) ~= 0) and UHCPM.state.isIndoors then
                local intensity = 1.0 
                if sourceGUID ~= playerGUID and destGUID ~= playerGUID then
                    local casterIntensity = GetDistanceMultiplier(GetUnitIDFromGUID(sourceGUID)); local targetIntensity = GetDistanceMultiplier(GetUnitIDFromGUID(destGUID)); intensity = math.max(casterIntensity, targetIntensity)
                end
                -- Send the pulse to Physics.lua to fade the darkness away
                if intensity > UHCPM.state.lightPulse then
                    UHCPM.state.lightPulse = intensity
                end
            end
        end
        
        if destGUID == playerGUID then
            local critical, crushing = false, false
            if subEvent == "SWING_DAMAGE" then critical = arg18; crushing = arg20 elseif subEvent == "SPELL_DAMAGE" or subEvent == "RANGE_DAMAGE" then critical = arg21; crushing = arg23 end
            if critical or crushing then
                if not UHCPM.UI.heartFrame.shakeAnim then
                    UHCPM.UI.heartFrame.shakeAnim = UHCPM.UI.heartFrame:CreateAnimationGroup(); local a1 = UHCPM.UI.heartFrame.shakeAnim:CreateAnimation("Translation"); a1:SetOffset(15, 0); a1:SetDuration(0.05); a1:SetOrder(1); local a2 = UHCPM.UI.heartFrame.shakeAnim:CreateAnimation("Translation"); a2:SetOffset(-30, 0); a2:SetDuration(0.05); a2:SetOrder(2); local a3 = UHCPM.UI.heartFrame.shakeAnim:CreateAnimation("Translation"); a3:SetOffset(15, 0); a3:SetDuration(0.05); a3:SetOrder(3)
                end
                UHCPM.UI.heartFrame.shakeAnim:Stop(); UHCPM.UI.heartFrame.shakeAnim:Play()
            end
        end
    end
end)

local TriageFrame = CreateFrame("Frame", "UHPMTriage", UIParent); TriageFrame:SetSize(200, 150); TriageFrame:SetPoint("LEFT", UIParent, "LEFT", 40, 0)
local triageLines = {}
for i = 1, 4 do
    local text = TriageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); if i == 1 then text:SetPoint("TOPLEFT", TriageFrame, "TOPLEFT", 0, 0) else text:SetPoint("TOPLEFT", triageLines[i-1], "BOTTOMLEFT", 0, -12) end; text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE"); text:SetJustifyH("LEFT"); text:SetAlpha(0); triageLines[i] = text
end
TriageFrame:RegisterEvent("GROUP_ROSTER_UPDATE"); TriageFrame:RegisterEvent("UNIT_HEALTH"); TriageFrame:RegisterEvent("UNIT_MAXHEALTH"); TriageFrame:RegisterEvent("UNIT_CONNECTION")
TriageFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_CONNECTION" then if not (unit and string.match(unit, "^party%d$")) then return end end
    for i = 1, 4 do
        local partyUnit = "party"..i; local line = triageLines[i]
        if UnitExists(partyUnit) then
            local name = UnitName(partyUnit)
            if not UnitIsConnected(partyUnit) then line:SetText(name .. " - OFFLINE"); line:SetTextColor(0.5, 0.5, 0.5); line:SetAlpha(1)
            elseif UnitIsDeadOrGhost(partyUnit) then line:SetText(name .. " - DEAD"); line:SetTextColor(0.4, 0.4, 0.4); line:SetAlpha(1)
            else
                local hp = UnitHealth(partyUnit); local maxHp = UnitHealthMax(partyUnit)
                if maxHp > 0 then local ratio = hp / maxHp; if ratio <= 0.50 then line:SetText(name .. " - " .. math.floor(ratio * 100) .. "%"); line:SetTextColor(ratio <= 0.20 and 1 or 0.85, ratio <= 0.20 and 0 or 0.1, 0.1); line:SetAlpha(1) else line:SetAlpha(0) end end
            end
        else line:SetAlpha(0) end
    end
end)