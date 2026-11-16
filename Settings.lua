local _, F = ...
function F:CopySettings(source)
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = type(value) == "table" and self:CopySettings(value) or value
    end
    return copy
end
local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do if not equal(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
function F:OptionsDirty()
    return self.editingOptions and (not equal(self.db, FelBotDB) or self:BindingDirty()) or false
end
function F:UpdateSaveButton()
    if self.options and self.options.save then
        self.options.save:SetEnabled(self:OptionsDirty() and not InCombatLockdown())
    end
end
function F:BeginOptions()
    if not self.editingOptions then
        self.db = self:CopySettings(FelBotDB)
        self.editingOptions = true
    end
    if self.options.SyncFields then self.options:SyncFields() end
    self:UpdateSaveButton()
end
function F:SaveOptions()
    if InCombatLockdown() then return false end
    if not self:SaveFelBotBinding() then return false end
    if self.editingOptions then FelBotDB = self:CopySettings(self.db) end
    if self.options.UpdateBindingControl then self.options:UpdateBindingControl() end
    self:UpdateSaveButton()
    return true
end
function F:FinishOptions(save)
    if InCombatLockdown() then return end
    if save and not self:SaveOptions() then return end
    self.bindingDraft=nil
    self.editingOptions, self.awaitingOptionsDecision = false, false
    self.db = FelBotDB
    local position = self.db.windowPosition
    self.options:ClearAllPoints()
    self:ApplyWindowScale(self.db.windowScale)
    if position then
        self.options:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
    else self.options:SetPoint("CENTER") end
    if self.savePrompt then self.savePrompt:Hide() end
    self.options:Hide()
    self:Refresh()
end
function F:OptionsHidden()
    if InCombatLockdown() then return end -- keep the draft for reopening
    if not self.editingOptions then return end
    if not self:OptionsDirty() then self:FinishOptions(false); return end
    if not self.savePrompt then
        local prompt = CreateFrame("Frame", "FelBotSavePrompt", UIParent, "BasicFrameTemplateWithInset")
        prompt:SetSize(420,150); prompt:SetPoint("CENTER")
        prompt:SetFrameStrata("FULLSCREEN_DIALOG"); prompt:SetClampedToScreen(true)
        prompt.TitleText:SetText("Unsaved FelBot settings")
        local message = prompt:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        message:SetPoint("TOPLEFT",20,-40); message:SetWidth(380)
        message:SetText("Save your changes before closing?")
        local function button(label,x,callback)
            local control = CreateFrame("Button",nil,prompt,"UIPanelButtonTemplate")
            control:SetSize(115,26); control:SetPoint("BOTTOMLEFT",x,18)
            control:SetText(label); control:SetScript("OnClick",callback)
        end
        button("Save",20,function() F:FinishOptions(true) end)
        button("Don't save",152,function() F:FinishOptions(false) end)
        button("Cancel",284,function() prompt:Hide() end)
        prompt:SetScript("OnHide",function()
            if F.awaitingOptionsDecision then
                F.awaitingOptionsDecision=false
                if not InCombatLockdown() then F.options:Show() end
            end
        end)
        tinsert(UISpecialFrames,"FelBotSavePrompt")
        self.savePrompt=prompt
    end
    self.awaitingOptionsDecision=true
    self.savePrompt:Show()
end
