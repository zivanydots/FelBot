local _, F = ...
F.maxItems = 6
function F:NormalizeItems(items)
    local result,seen={},{}
    for _,entry in ipairs(type(items)=="table" and items or {}) do
        local raw=type(entry)=="table" and entry.id
        local id=(type(raw)=="number" or type(raw)=="string") and tonumber(raw)
        if id and id>0 and id<=2147483647 and id==math.floor(id) and not seen[id] and #result<self.maxItems then
            local mode=(entry.buffMode=="spell" or entry.buffMode=="off") and entry.buffMode or "auto"
            local buffID=tonumber(type(entry.buffSpellID)=="number" and entry.buffSpellID or "")
            if buffID and (buffID<=0 or buffID>2147483647 or buffID~=math.floor(buffID)) then buffID=nil end
            result[#result+1]={id=id,enabled=entry.enabled~=false,queue=entry.queue~=false,party=entry.party==true,buffMode=mode,buffSpellID=buffID,
                buffName=type(entry.buffName)=="string" and entry.buffName or nil}; seen[id]=true
        end
    end
    return result
end
function F:IsCustomItemEquipment(id)
    if C_Item.IsEquippableItem then
        local equipment=C_Item.IsEquippableItem(id)
        if issecretvalue and issecretvalue(equipment) then return true end
        if equipment==true or equipment==1 then return true end
    end
    if C_Item.GetItemInfoInstant then
        local _,_,_,location=C_Item.GetItemInfoInstant(id)
        return type(location)=="string" and location~="INVTYPE_NON_EQUIP_IGNORE" and location:match("^INVTYPE_")~=nil
    end
    return false
end
function F:HasCustomItems()
    if not self.db.itemsEnabled then return false end
    for _,entry in ipairs(self.db.items) do if entry.enabled then return true end end
    return false
end
function F:CustomItemCount(id)
    local count=C_Item.GetItemCount(id)
    if issecretvalue and issecretvalue(count) then return 0 end
    if count and count>0 then return count end
    return 0
end
function F:BagItemReady(id)
    local start,duration=C_Item.GetItemCooldown(id)
    if issecretvalue and (issecretvalue(start) or issecretvalue(duration)) then return false end
    if start==nil and duration==nil then return true end -- no exposed bag-use timer
    if type(start)~="number" or type(duration)~="number" then return false end
    -- Bag-use effects can have no cooldown timer or a disabled timer flag.
    -- Neither use-spell metadata nor that flag is needed for a normal /use.
    return duration==0 or start==0 or start+duration<=GetTime()
end
function F:CustomItemData(id,unit)
    local name=C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
    self.itemRequests=self.itemRequests or {}
    if not name and not self.itemRequests[id] and C_Item.RequestLoadItemDataByID then
        self.itemRequests[id]="pending"; C_Item.RequestLoadItemDataByID(id)
    end
    local usable=not self:IsCustomItemEquipment(id)
    local count=self:CustomItemCount(id)
    local buffActive=usable and self:IsCustomItemBuffActive(id,name,unit or "player") or false
    local ready=usable and not buffActive and count>0 and self:BagItemReady(id)
    local status=buffActive and "Buff active" or (not usable and "Equipment unsupported" or (not name and (self.itemRequests[id]=="failed" and "Unknown item" or "Loading...")
        or (count==0 and "Not carried" or (ready and "Ready" or "Cooldown"))))
    return {name=name or ("Item #"..id),count=count,ready=ready,usable=usable,status=status,buffActive=buffActive}
end
function F:AddCustomItem(input)
    if InCombatLockdown() then return false,"Edit items outside combat." end
    local value=tostring(input or "")
    local id=tonumber(value:match("item:(%d+)") or value:match("^%s*(%d+)%s*$"))
    if not id or id<=0 or id>2147483647 or id~=math.floor(id) then return false,"Drop an item here, or paste its item link / ID." end
    if self:IsCustomItemEquipment(id) then return false,"Equipment is not supported. Add an item used from your bags." end
    for _,stone in pairs(self.stoneTypes) do
        for _,stoneID in ipairs(stone.items) do if stoneID==id then return false,"Configure warlock stones on the Stones tab." end end
    end
    for _,entry in ipairs(self.db.items) do if entry.id==id then return false,"That item is already in your list." end end
    if #self.db.items>=self.maxItems then return false,"You can configure up to six items." end
    self.db.items[#self.db.items+1]={id=id,enabled=true,queue=true,party=false,buffMode="auto"}
    self.db.selfPriority=self:NormalizeSelfPriority(self.db.selfPriority)
    self:Refresh()
    return true
end
function F:MoveCustomItem(index,direction)
    if InCombatLockdown() or (direction~=-1 and direction~=1) then return end
    local entries=self.db.items; local other=index+direction
    if entries[index] and entries[other] then entries[index],entries[other]=entries[other],entries[index]; self:Refresh() end
end
function F:RemoveCustomItem(index)
    if InCombatLockdown() then return end
    if self.db.items[index] then table.remove(self.db.items,index); self:Refresh() end
end
function F:CreateItemSlash(button)
    local slash=button.visual:CreateTexture(nil,"OVERLAY")
    slash:SetPoint("CENTER"); slash:SetColorTexture(1,.1,.1,1); slash:SetRotation(-math.pi/4)
    slash:Hide(); button.missingSlash=slash
end
function F:UpdateCustomItemVisual(button)
    local count=self:CustomItemCount(button.customItem)
    button.itemMissing=count==0
    button.texture:SetAlpha(count==0 and .4 or 1)
    button.text:SetText(count==0 and "0" or (count>1 and tostring(count) or ""))
    button.missingSlash:SetSize(button:GetWidth()*1.2,2)
    button.missingSlash:SetShown(count==0)
end
function F:CreateItemsPage(panel,page)
    local function text(value,x,y,width)
        local label=page:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        label:SetPoint("TOPLEFT",x,y); label:SetWidth(width or 680); label:SetJustifyH("LEFT"); label:SetText(value)
        return label
    end
    local master=CreateFrame("CheckButton","FelBotItemsEnabled",page,"UICheckButtonTemplate")
    master:SetPoint("TOPLEFT",0,0); master.text:SetText("Show Pots / Items")
    master:SetScript("OnClick",function()
        if not InCombatLockdown() then F.db.itemsEnabled=master:GetChecked(); F:Refresh() end
    end)
    text("Drop a bag-use item here, or paste its item link / ID. Equipment is not supported. Up to six items.",0,-40)
    local input=CreateFrame("EditBox","FelBotItemInput",page,"InputBoxTemplate")
    input:SetPoint("TOPLEFT",8,-72); input:SetSize(495,24); input:SetAutoFocus(false)
    local message=text("",0,-108); message:SetTextColor(1,.4,.3)
    local function add(value)
        local ok,reason=F:AddCustomItem(value)
        message:SetText(reason or "")
        if ok then input:SetText(""); input:ClearFocus() end
    end
    local function drop()
        if InCombatLockdown() then return end
        local kind,id=GetCursorInfo()
        if kind=="item" then ClearCursor(); add(id) end
    end
    input:SetScript("OnReceiveDrag",drop)
    input:SetScript("OnMouseDown",function() if GetCursorInfo()=="item" then drop() end end)
    input:SetScript("OnEnterPressed",function() add(input:GetText()) end)
    input:SetScript("OnEscapePressed",function() input:ClearFocus() end)
    local addButton=CreateFrame("Button","FelBotAddItem",page,"UIPanelButtonTemplate")
    addButton:SetPoint("TOPLEFT",530,-72); addButton:SetSize(150,24); addButton:SetText("Add item")
    addButton:SetScript("OnClick",function() add(input:GetText()) end)
    text("Item",38,-133,210); text("Status",260,-133,82); text("Queue",350,-133,45); text("Party",395,-133,45)
    local empty=text("Add your first item to build a quick-use list.",38,-190,600)
    local rows={}
    for i=1,self.maxItems do
        local index=i
        local row=CreateFrame("Frame",nil,page); row:SetPoint("TOPLEFT",0,-150-(i-1)*36); row:SetSize(690,34)
        row.enabled=CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate"); row.enabled:SetPoint("LEFT",0,0)
        row:EnableMouse(true)
        row:SetScript("OnEnter",function()
            local entry=F.db.items[index]
            if not entry then return end
            GameTooltip:SetOwner(row,"ANCHOR_RIGHT")
            if GameTooltip.SetItemByID then GameTooltip:SetItemByID(entry.id) else GameTooltip:SetText(F:CustomItemData(entry.id).name) end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        row:SetScript("OnHide",function() if GameTooltip:GetOwner()==row then GameTooltip:Hide() end end)
        row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(26,26); row.icon:SetPoint("LEFT",36,0)
        row.name=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.name:SetPoint("LEFT",70,0); row.name:SetWidth(180); row.name:SetJustifyH("LEFT")
        row.status=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.status:SetPoint("LEFT",260,0); row.status:SetWidth(82); row.status:SetJustifyH("LEFT")
        row.queue=CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate"); row.queue:SetPoint("LEFT",350,0)
        row.party=CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate"); row.party:SetPoint("LEFT",395,0)
        row.party:SetScript("OnClick",function()
            if not InCombatLockdown() and F.db.items[index] then F.db.items[index].party=row.party:GetChecked(); F:Refresh() end
        end)
        row.party:SetScript("OnEnter",function()
            GameTooltip:SetOwner(row.party,"ANCHOR_RIGHT"); GameTooltip:SetText("Allow on party / raid frames")
            GameTooltip:AddLine("Enable for items that can target others, such as scrolls. Leave off for potions and self-use items.",.8,.8,.8,true); GameTooltip:Show()
        end)
        row.party:SetScript("OnLeave",function() GameTooltip:Hide() end)
        row.buff=CreateFrame("Button",nil,row,"UIPanelButtonTemplate"); row.buff:SetPoint("LEFT",440,0); row.buff:SetSize(56,24); row.buff:SetText("Buff")
        row.buff:SetScript("OnClick",function()
            local entry=F.db.items[index]
            if entry then F:OpenItemBuffEditor(entry.id) end
        end)
        row.buff:SetScript("OnEnter",function()
            GameTooltip:SetOwner(row.buff,"ANCHOR_RIGHT"); GameTooltip:SetText("Hide while its buff is active"); GameTooltip:Show()
        end)
        row.buff:SetScript("OnLeave",function() GameTooltip:Hide() end)
        row.queue:SetScript("OnEnter",function()
            GameTooltip:SetOwner(row.queue,"ANCHOR_RIGHT"); GameTooltip:SetText("Include in Buff Order Queue")
            GameTooltip:AddLine("Ready items can be used at any health.",.8,.8,.8); GameTooltip:Show()
        end)
        row.queue:SetScript("OnLeave",function() GameTooltip:Hide() end)
        row.enabled:SetScript("OnClick",function()
            if not InCombatLockdown() and F.db.items[index] then F.db.items[index].enabled=row.enabled:GetChecked(); F:Refresh() end
        end)
        row.queue:SetScript("OnClick",function()
            if not InCombatLockdown() and F.db.items[index] then F.db.items[index].queue=row.queue:GetChecked(); F:Refresh() end
        end)
        local function arrow(x,direction)
            local button=CreateFrame("Button",nil,row); button:SetSize(24,24); button:SetPoint("LEFT",x,0)
            local path="Interface\\Buttons\\UI-ScrollBar-Scroll"..(direction==-1 and "Up" or "Down").."Button-"
            button:SetNormalTexture(path.."Up"); button:SetPushedTexture(path.."Down"); button:SetDisabledTexture(path.."Disabled"); button:SetHighlightTexture(path.."Highlight")
            button:SetScript("OnClick",function() F:MoveCustomItem(index,direction) end)
            return button
        end
        row.up=arrow(505,-1); row.down=arrow(540,1)
        row.remove=CreateFrame("Button",nil,row,"UIPanelButtonTemplate"); row.remove:SetSize(90,24); row.remove:SetPoint("LEFT",580,0); row.remove:SetText("Remove")
        row.remove:SetScript("OnClick",function() F:RemoveCustomItem(index) end)
        rows[i]=row
    end
    text("Party is opt-in for targetable items. Queue has no health threshold; uncheck for icon-only use. Active buffs hide the target's icon; use Buff to adjust detection. Missing items show a red slash.",0,-372,690)
    function panel:UpdateItemRows()
        master:SetChecked(F.db.itemsEnabled); master:SetEnabled(not InCombatLockdown()); addButton:SetEnabled(not InCombatLockdown())
        empty:SetShown(#F.db.items==0)
        for index,row in ipairs(rows) do
            local entry=F.db.items[index]; row:SetShown(entry~=nil)
            if entry then
                local data=F:CustomItemData(entry.id)
                row.enabled:SetChecked(entry.enabled); row.queue:SetChecked(entry.queue); row.party:SetChecked(entry.party==true)
                row.name:SetText(data.name); row.status:SetText(data.status..(data.count>0 and (" ("..data.count..")") or ""))
                row.icon:SetTexture(C_Item.GetItemIconByID and C_Item.GetItemIconByID(entry.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.up:SetEnabled(index>1); row.down:SetEnabled(index<#F.db.items)
                row:SetAlpha(entry.enabled and 1 or .5)
            end
        end
    end
    panel.itemRows=rows
    self:CreateItemBuffEditor(panel)
    panel.syncers[#panel.syncers+1]=function() panel:UpdateItemRows(); message:SetText("") end
    panel:UpdateItemRows()
end
