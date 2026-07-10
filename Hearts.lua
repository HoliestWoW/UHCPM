local addonName, UHCPM = ...

UHCPM.UI.heartFrame = CreateFrame("Frame", "UHPMHearts", UIParent); UHCPM.UI.heartFrame:SetSize(520, 50); UHCPM.UI.heartFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 350, 90); UHCPM.UI.heartFrame:SetFrameStrata("LOW")
local hearts = {}
local lastHalfHearts = -1
local lastPoisonState = nil
local lastShowHearts = nil

local function CreateHeart(index)
    local f = CreateFrame("Frame", nil, UHCPM.UI.heartFrame); f:SetSize(48, 48)
    if index == 1 then f:SetPoint("LEFT", UHCPM.UI.heartFrame, "LEFT", 0, 0) else f:SetPoint("LEFT", hearts[index-1].frame, "RIGHT", 4, 0) end
    local b = f:CreateTexture(nil, "BACKGROUND"); b:SetAllPoints(); b:SetTexture("Interface\\AddOns\\UHCPM\\heart.tga"); b:SetVertexColor(0.15, 0.15, 0.15) 
    local fg = f:CreateTexture(nil, "ARTWORK"); fg:SetPoint("LEFT", f, "LEFT", 0, 0); fg:SetSize(48, 48); fg:SetTexture("Interface\\AddOns\\UHCPM\\heart.tga")
    return { frame = f, bgTex = b, fgTex = fg }
end
for i = 1, UHCPM.constants.MAX_HEARTS do table.insert(hearts, CreateHeart(i)) end

function UHCPM.UpdateHeartVisuals()
    local state = UHCPM.state
    if state.playerMaxHealth > 0 and not UnitIsDeadOrGhost("player") then
        local activeHalfHearts = math.ceil((state.playerHealth / state.playerMaxHealth) * (UHCPM.constants.MAX_HEARTS * 2))
        local showHearts = not (UHCPM_Config and UHCPM_Config.combatHearts and not InCombatLockdown() and (state.playerHealth >= state.playerMaxHealth))
        
        if activeHalfHearts == lastHalfHearts and state.isToxified == lastPoisonState and showHearts == lastShowHearts then return end
        lastHalfHearts = activeHalfHearts; lastPoisonState = state.isToxified; lastShowHearts = showHearts
        
        if showHearts then
            UHCPM.UI.heartFrame:SetAlpha(1)
            for i = 1, UHCPM.constants.MAX_HEARTS do
                local h = hearts[i]; local lh = (i * 2) - 1; local rh = i * 2
                if activeHalfHearts >= rh then h.fgTex:SetWidth(48); h.fgTex:SetTexCoord(0, 1, 0, 1); h.fgTex:SetAlpha(1); h.fgTex:SetVertexColor(state.isToxified and 0.4 or 0.85, state.isToxified and 0.8 or 0.1, state.isToxified and 0.2 or 0.1)
                elseif activeHalfHearts == lh then h.fgTex:SetWidth(24); h.fgTex:SetTexCoord(0, 0.5, 0, 1); h.fgTex:SetAlpha(1); h.fgTex:SetVertexColor(state.isToxified and 0.4 or 0.85, state.isToxified and 0.8 or 0.1, state.isToxified and 0.2 or 0.1)
                else h.fgTex:SetAlpha(0) end
            end
            UHCPM.UI.heartFrame:Show()
        else UHCPM.UI.heartFrame:SetAlpha(0); UHCPM.UI.heartFrame:Hide() end
    else UHCPM.UI.heartFrame:Hide() end
end