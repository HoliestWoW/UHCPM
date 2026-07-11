local addonName, UHCPM = ...
local defaults = { hideChat = false, combatHearts = false, hideErrors = false, lowHealthAudio = false }
local OptionsPanel = CreateFrame("Frame", "UHCPMOptionsPanel"); OptionsPanel.name = "Ultra Hardcore Pro Max"
local title = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 16, -16); title:SetText("UHCPM - Immersion Settings")

local function CreateCheckbox(name, labelText, yOffset, dbKey, callback)
    local cb = CreateFrame("CheckButton", name, OptionsPanel, "UICheckButtonTemplate"); cb:SetPoint("TOPLEFT", 16, yOffset); _G[name .. "Text"]:SetText(labelText)
    cb:SetScript("OnClick", function(self) UHCPM_Config[dbKey] = self:GetChecked(); if callback then callback(self:GetChecked()) end end); return cb
end

local function UpdateChatVisibility(isHidden)
    local targetAlpha = isHidden and 0 or 1
    for i = 1, NUM_CHAT_WINDOWS do 
        local chat = _G["ChatFrame"..i]
        local tab = _G["ChatFrame"..i.."Tab"]
        
        if chat then 
            chat:EnableMouse(not isHidden)
            chat:SetAlpha(targetAlpha)
            
            -- Prevent the game from forcing the chat window alpha back up
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
            
            -- Prevent the game from forcing the tab alpha back up, without breaking docking
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

    if isHidden then SetCVar("chatBubbles", "1") end
end

local function UpdateErrorMessages(isHidden)
    if isHidden then UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE"); SetCVar("Sound_EnableErrorSpeech", "0") else UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE"); SetCVar("Sound_EnableErrorSpeech", "1") end
end

-- Capture the returned checkbox frames so we can update them later
local chatCb = CreateCheckbox("UHCPMChatToggle", "Hide Chat Box", -50, "hideChat", UpdateChatVisibility)
local heartCb = CreateCheckbox("UHCPMHeartToggle", "Fade Hearts Out of Combat", -80, "combatHearts", function() UHCPM.UpdateHeartVisuals() end)
local errorCb = CreateCheckbox("UHCPMErrorToggle", "Disable UI Error Text", -110, "hideErrors", UpdateErrorMessages)
local audioCb = CreateCheckbox("UHCPMAudioToggle", "Muffle Audio on Low Health", -140, "lowHealthAudio", nil)

if Settings and Settings.RegisterCanvasLayoutCategory then local category = Settings.RegisterCanvasLayoutCategory(OptionsPanel, OptionsPanel.name); Settings.RegisterAddOnCategory(category) else InterfaceOptions_AddCategory(OptionsPanel) end

local EventFrame = CreateFrame("Frame"); EventFrame:RegisterEvent("PLAYER_LOGIN"); EventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
EventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        UHCPM_Config = UHCPM_Config or {}; for k, v in pairs(defaults) do if UHCPM_Config[k] == nil then UHCPM_Config[k] = v end end
        
        -- Sync the visual checkboxes with your loaded saved variables
        chatCb:SetChecked(UHCPM_Config.hideChat)
        heartCb:SetChecked(UHCPM_Config.combatHearts)
        errorCb:SetChecked(UHCPM_Config.hideErrors)
        audioCb:SetChecked(UHCPM_Config.lowHealthAudio)

        UHCPM.UpdateHeartVisuals(); UpdateChatVisibility(UHCPM_Config.hideChat); UpdateErrorMessages(UHCPM_Config.hideErrors)
    elseif event == "PLAYER_LEAVING_WORLD" then UHCPM.MuffleAudio(false) end
end)