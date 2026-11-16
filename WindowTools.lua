local _, F = ...
local bindingAction="CLICK FelBotActivateButton:LeftButton"
local function currentKeys()
    return GetBindingKey and {GetBindingKey(bindingAction)} or {}
end
function F:BindingDirty()
    if not self.bindingDraft then return false end
    local actual=currentKeys()
    if #actual~=#self.bindingDraft.keys then return true end
    for index,key in ipairs(actual) do if key~=self.bindingDraft.keys[index] then return true end end
    return false
end
function F:StageFelBotBinding(key)
    if InCombatLockdown() or not self.editingOptions then return false,"Edit bindings outside combat." end
    local action=key and GetBindingAction(key)
    if action and action~="" and action~=bindingAction then return false,"That key is already bound. Choose another key." end
    local old=self.bindingDraft and self.bindingDraft.keys or currentKeys()
    local keys={}
    if key then
        keys[1]=key
        for index=2,#old do if old[index]~=key then keys[#keys+1]=old[index] end end
    end
    self.bindingDraft={keys=keys,set=GetCurrentBindingSet()}
    self:UpdateSaveButton()
    if self.options.UpdateBindingControl then self.options:UpdateBindingControl() end
    return true
end
function F:SaveFelBotBinding()
    if not self:BindingDirty() then self.bindingDraft=nil; return true end
    if InCombatLockdown() then return false end
    local draft=self.bindingDraft
    if GetCurrentBindingSet()~=draft.set then self:Print("Binding profile changed. Choose the FelBot key again."); return false end
    for _,key in ipairs(draft.keys) do
        local action=GetBindingAction(key)
        if action and action~="" and action~=bindingAction then self:Print("FelBot key is now assigned to another action. Choose another key."); return false end
    end
    local old=currentKeys()
    local function restore()
        for _,key in ipairs(currentKeys()) do SetBinding(key) end
        for _,key in ipairs(old) do SetBindingClick(key,"FelBotActivateButton","LeftButton") end
        self:Print("Could not save the FelBot binding. Your previous keys were restored.")
        return false
    end
    for _,key in ipairs(old) do if not SetBinding(key) then return restore() end end
    for _,key in ipairs(draft.keys) do if not SetBindingClick(key,"FelBotActivateButton","LeftButton") then return restore() end end
    if SaveBindings(draft.set)==false then return restore() end
    self.bindingDraft=nil
    return true
end
function F:CreateBindingControls(panel,page)
    panel.keyboardHeading=F:AddOptionsHeading(page,"Keyboard shortcut",0,-350,325)
    local description=F:AddOptionsText(page,"Using the key will apply buffs one by one in the order defined by Buff Order Queue.",0,-380,325)
    local label=F:AddOptionsText(page,"",0,-435,325)
    F:AddOptionsText(page,"Change the primary key here. Alternate keys are kept. Click Save to apply binding changes.",0,-510,325)
    local status=F:AddOptionsText(page,"",0,-560,325)
    local capture=CreateFrame("Button","FelBotSetBinding",page,"UIPanelButtonTemplate")
    capture:SetPoint("TOPLEFT",0,-470); capture:SetSize(145,26); capture:SetText("Set binding")
    capture:EnableKeyboard(false)
    local clear=CreateFrame("Button","FelBotClearBinding",page,"UIPanelButtonTemplate")
    clear:SetPoint("TOPLEFT",160,-470); clear:SetSize(145,26); clear:SetText("Clear bindings")
    function panel:UpdateBindingControl()
        local keys=F.bindingDraft and F.bindingDraft.keys or currentKeys()
        local labels={}
        for _,key in ipairs(keys) do labels[#labels+1]=GetBindingText and GetBindingText(key) or key end
        label:SetText("Current: "..(#labels>0 and table.concat(labels," / ") or "Not bound")..(F:BindingDirty() and " (unsaved)" or ""))
        capture:SetEnabled(not InCombatLockdown()); clear:SetEnabled(not InCombatLockdown() and #keys>0)
    end
    function panel:CancelBindingCapture()
        capture.capturing=false; capture:EnableKeyboard(false); capture:SetText("Set binding"); status:SetText("")
    end
    capture:SetScript("OnClick",function()
        if InCombatLockdown() then return end
        if capture.capturing then panel:CancelBindingCapture(); return end
        capture.capturing=true; capture:EnableKeyboard(true); capture:SetPropagateKeyboardInput(false)
        capture:SetText("Press a key..."); status:SetText("Press a key with optional Shift, Ctrl or Alt. Escape cancels.")
    end)
    capture:SetScript("OnKeyDown",function(_,key)
        if not capture.capturing then return end
        if InCombatLockdown() or key=="ESCAPE" then panel:CancelBindingCapture(); return end
        if IsKeyPressIgnoredForBinding(key) then return end
        local chord=CreateKeyChordStringUsingMetaKeyState(key)
        local ok,reason=F:StageFelBotBinding(chord)
        if ok then panel:CancelBindingCapture() else status:SetText(reason) end
    end)
    clear:SetScript("OnClick",function() panel:CancelBindingCapture(); F:StageFelBotBinding(nil) end)
    capture:RegisterEvent("UPDATE_BINDINGS"); capture:RegisterEvent("PLAYER_REGEN_DISABLED")
    capture:SetScript("OnEvent",function(_,event)
        if event=="PLAYER_REGEN_DISABLED" then panel:CancelBindingCapture() end
        panel:UpdateBindingControl(); F:UpdateSaveButton()
    end)
    panel.bindingLabel,panel.bindingStatus,panel.bindingCapture=label,status,capture
    panel.bindingDescription=description
    panel.syncers[#panel.syncers+1]=function() panel:UpdateBindingControl() end
    panel:UpdateBindingControl()
end
function F:MoveSelfPriority(index, direction)
    if InCombatLockdown() or type(index)~="number" or (direction ~= -1 and direction ~= 1) then return end
    local order = self.db.selfPriority
    local other = index + direction
    while order[other]=="items" and not self:HasCustomItems() do other=other+direction end
    if not order[index] or not order[other] then return end
    local moved=table.remove(order,index)
    table.insert(order,other,moved)
    self:Refresh()
    if self.options.UpdatePriorityRows then self.options:UpdatePriorityRows() end
end
function F:CreatePriorityEditor(panel)
    local editor = CreateFrame("Frame", "FelBotPriorityEditor", panel, "BasicFrameTemplateWithInset")
    editor:SetPoint("TOPLEFT", 20, -230); editor:SetSize(720, 400)
    editor:SetFrameLevel(panel:GetFrameLevel() + 50)
    editor.TitleText:SetText("Buff Order Queue")
    editor:EnableMouse(true)
    local function text(value,x,y,width)
        local label=editor:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        label:SetPoint("TOPLEFT",x,y); label:SetWidth(width); label:SetJustifyH("LEFT"); label:SetText(value)
        return label
    end
    text("Choose the self action and icon order. Each stone's creation and use move together. The keybinding, frame modifier and displayed self icons follow this list.",20,-42,675)
    local names={armor="Demon Armor / Demon Skin",sense="Sense Demons",detect="Detect Invisibility",
        breath="Unending Breath",soul="Soulstone",weapon="Firestone / Spellstone",items="Pots / Items",health="Healthstone"}
    local rows={}
    for i=1,8 do
        local index=i
        local row={label=text("",25,-90-(i-1)*26,420)}
        local function button(x,direction)
            local control=CreateFrame("Button",nil,editor)
            control:SetSize(26,26); control:SetPoint("TOPLEFT",x,-82-(index-1)*26)
            local arrow=direction==-1 and "Up" or "Down"
            local path="Interface\\Buttons\\UI-ScrollBar-Scroll"..arrow.."Button-"
            control:SetNormalTexture(path.."Up"); control:SetPushedTexture(path.."Down")
            control:SetDisabledTexture(path.."Disabled"); control:SetHighlightTexture(path.."Highlight")
            control:SetScript("OnEnter",function()
                GameTooltip:SetOwner(control,"ANCHOR_RIGHT"); GameTooltip:SetText(direction==-1 and "Move up" or "Move down"); GameTooltip:Show()
            end)
            control:SetScript("OnLeave",function() GameTooltip:Hide() end)
            control:SetScript("OnClick",function() F:MoveSelfPriority(row.orderIndex,direction) end)
            return control
        end
        row.up=button(555,-1); row.down=button(600,1)
        rows[i]=row
    end
    function panel:UpdatePriorityRows()
        local visible={}
        for index,key in ipairs(F.db.selfPriority) do
            if key~="items" or F:HasCustomItems() then visible[#visible+1]={index=index,key=key} end
        end
        for index,row in ipairs(rows) do
            local entry=visible[index]
            row.label:SetShown(entry~=nil); row.up:SetShown(entry~=nil); row.down:SetShown(entry~=nil)
            if entry then
                row.orderIndex=entry.index
                row.label:SetText(index .. ". " .. names[entry.key])
                row.up:SetEnabled(index>1 and not InCombatLockdown())
                row.down:SetEnabled(index<#visible and not InCombatLockdown())
            end
        end
    end
    text("Healthstone creation and use follow its position here; the health threshold still controls its use reminder. Order individual Pots / Items on their tab. Self-frame stone actions require Include stones in self-frame modifier clicks.",20,-310,675)
    local close=CreateFrame("Button",nil,editor,"UIPanelButtonTemplate")
    close:SetSize(110,24); close:SetPoint("BOTTOMLEFT",20,18); close:SetText("Back")
    close:SetScript("OnClick",function() editor:Hide() end)
    editor:SetScript("OnShow",function() panel:UpdatePriorityRows() end)
    panel.priorityEditor, panel.priorityRows=editor,rows
    editor:Hide()
end
function F:ApplyWindowScale(value, anchor)
    local panel=self.options
    if not panel then return end
    local maximum=math.min(1.2, UIParent:GetWidth()/760, UIParent:GetHeight()/690)
    local minimum=math.min(.6,maximum)
    value=math.max(minimum,math.min(maximum,math.floor(value*1000+.5)/1000))
    panel:SetScale(value)
    self:RefreshOptionsUnderlines()
    self.db.windowScale=value
    if anchor then
        local scale=panel:GetEffectiveScale()
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",anchor.left/scale,anchor.top/scale)
        local point,_,relativePoint,x,y=panel:GetPoint()
        self.db.windowPosition={point=point,relativePoint=relativePoint,x=x,y=y}
    end
    self:UpdateSaveButton()
end
function F:CreateResizeGrip(panel)
    local grip=CreateFrame("Button","FelBotResizeGrip",panel)
    grip:SetSize(18,18); grip:SetPoint("BOTTOMRIGHT",-1,1)
    local artwork=grip:CreateTexture(nil,"OVERLAY")
    artwork:SetAllPoints(); artwork:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:EnableMouse(true)
    grip:SetScript("OnEnter",function()
        GameTooltip:SetOwner(grip,"ANCHOR_LEFT")
        GameTooltip:SetText("Drag to resize the whole window. Save to keep the size.",1,1,1)
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave",function() GameTooltip:Hide() end)
    function panel:StopResizing()
        self.resizeStart=nil; grip:SetScript("OnUpdate",nil)
    end
    grip:SetScript("OnMouseDown",function(_,button)
        if button~="LeftButton" or InCombatLockdown() then return end
        local x,y=GetCursorPosition()
        local scale=panel:GetEffectiveScale()
        panel.resizeStart={x=x,y=y,scale=F.db.windowScale,root=UIParent:GetEffectiveScale(),
            left=panel:GetLeft()*scale,top=panel:GetTop()*scale}
        grip:SetScript("OnUpdate",function()
            if InCombatLockdown() or not panel:IsShown()
                or (IsMouseButtonDown and not IsMouseButtonDown("LeftButton")) then panel:StopResizing(); return end
            local start=panel.resizeStart
            local cursorX,cursorY=GetCursorPosition()
            local dx=(cursorX-start.x)/(760*start.root)
            local dy=(start.y-cursorY)/(690*start.root)
            F:ApplyWindowScale(start.scale+(math.abs(dx)>math.abs(dy) and dx or dy),start)
        end)
    end)
    grip:SetScript("OnMouseUp",function() panel:StopResizing() end)
    panel.resizeGrip=grip
end
