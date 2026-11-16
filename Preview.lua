local _, F = ...
local points = {left={"BOTTOMLEFT","TOPLEFT"}, center={"BOTTOM","TOP"}, right={"BOTTOMRIGHT","TOPRIGHT"}}
local overlayPoints = {left="LEFT",center="CENTER",right="RIGHT"}
function F:FrameLayout(frame,kind)
    local db=self.db
    if frame==PlayerFrame then
        return {size=db.selfSize,offset=db.selfOffset,shift=db.selfIconVertical,placement=db.selfPlacement,align=db.selfTopAlign,gap=db.selfVertical}
    elseif kind=="raidParty" or kind==true then
        return {size=db.raidPartySize,offset=db.raidPartyOffset,shift=db.raidPartyIconVertical,placement=db.raidPartyPlacement,align=db.raidPartyTopAlign,gap=db.raidPartyVertical}
    elseif kind=="raid" then
        return {size=db.raidSize,offset=db.raidOffset,shift=db.raidIconVertical,placement=db.raidPlacement,align=db.raidTopAlign,gap=db.raidVertical}
    end
    return {size=db.size,offset=db.offset,shift=db.iconVertical,placement=db.placement,align=db.topAlign,gap=db.vertical}
end
function F:LayoutIndicators(row, frame, isSelf, buttons, kind)
    local config=self:FrameLayout(frame,kind)
    local size,offset=config.size,config.offset
    for index,button in ipairs(buttons) do button.layoutIndex=index end
    if isSelf then
        table.sort(buttons,function(a,b)
            local first=F:SelfActionScore(a.buffKey,{healthstoneReminder=a.healthstoneReminder,itemIndex=a.itemIndex})
            local second=F:SelfActionScore(b.buffKey,{healthstoneReminder=b.healthstoneReminder,itemIndex=b.itemIndex})
            return first<second or (first==second and a.layoutIndex<b.layoutIndex)
        end)
    end
    local count=0
    for _,button in ipairs(buttons) do
        button:ClearAllPoints()
        if frame==PlayerFrame and button.healthstoneReminder and self.db.healthstoneSeparate then
            self:PositionHealthstone(button,frame)
        else
            button:SetSize(size,size)
            button:SetPoint("LEFT",row,"LEFT",count*(size+self.db.spacing),0)
            count=count+1
        end
    end
    row.displayOrder=buttons
    row:ClearAllPoints()
    row:SetSize(math.max(1,count*size+math.max(0,count-1)*self.db.spacing),size)
    local placement=config.placement
    local verticalShift=config.shift
    if placement=="top" then
        local point=points[config.align] or points.right
        row:SetPoint(point[1],frame,point[2],offset,config.gap+verticalShift)
    elseif placement=="overlay" then
        local point=overlayPoints[config.align] or "RIGHT"
        row:SetPoint(point,frame,point,offset,verticalShift)
    else
        row:SetPoint("LEFT",frame,"RIGHT",offset,verticalShift)
    end
end
function F:PositionHealthstone(button, frame)
    if frame~=PlayerFrame then return false end
    button:ClearAllPoints()
    button:SetSize(self.db.healthstoneSize, self.db.healthstoneSize)
    if self.db.healthstonePlacement == "top" then
        local point = points[self.db.healthstoneAlign] or points.center
        button:SetPoint(point[1], frame, point[2], self.db.healthstoneOffset, self.db.healthstoneVertical)
    else
        button:SetPoint("LEFT", frame, "RIGHT", self.db.healthstoneOffset, self.db.healthstoneVertical)
    end
end
function F:SetTestUI(enabled)
    if enabled and InCombatLockdown() then return end
    self.testUI = enabled and true or false
    if self.options and self.options.test then self.options.test:SetChecked(self.testUI) end
    if not self.testUI then
        for _, preview in pairs(self.previews or {}) do preview:Hide() end
        for _,frame in ipairs(self.previewParties or {}) do frame:Hide() end
        if self.previewRaid then self.previewRaid:Hide() end
    end
    if not InCombatLockdown() then self:Refresh() end
end
function F:RefreshTestUI()
    if not self.testUI then return end
    self.previews = self.previews or {}
    for _, preview in pairs(self.previews) do preview:Hide() end
    local function draw(frame, isSelf, kind)
        local row = self.previews[frame]
        if not row then
            row = CreateFrame("Frame", nil, UIParent)
            row:SetFrameStrata("DIALOG")
            row:EnableMouse(false)
            row.squares = {}
            self.previews[frame] = row
        end
        row:Show()
        local count, displayed = 0, {}
        local function icon(key, appearance, creation, reminder, itemID, itemIndex)
            count = count + 1
            local square = row.squares[count]
            if not square then
                square = CreateFrame("Frame", nil, row)
                square:EnableMouse(false) -- artwork only: no secure actions or click handlers
                square.texture = square:CreateTexture(nil, "BACKGROUND")
                square.texture:SetAllPoints()
                square.text = square:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                square.text:SetPoint("CENTER")
                square.text:SetTextColor(1,1,1)
                square.visual=square
                F:CreateItemSlash(square)
                row.squares[count] = square
            end
            square.buffKey, square.healthstoneReminder = key,reminder
            square.customItem,square.itemIndex=itemID,itemIndex
            square.missingSlash:Hide()
            displayed[count]=square
            local stone = F.stoneTypes[key]
            local ids = not itemID and (stone and stone.ids or (appearance == "skin" and F.skin.ids or F.spells[key].ids))
            local spellID
            if ids then local _; _,spellID=F:LearnedSpell(ids) end
            F:PaintIcon(square, spellID or (ids and ids[1]),itemID or (stone and not creation and stone.items[1] or nil), creation)
            square:Show()
        end
        if self.db.buffTargets[isSelf and "self" or "group"] then
            for _, key in ipairs(self.db.priority) do
                if self.db.buffs[key] and (isSelf or not self.spells[key].selfOnly) then
                    local skin = key == "armor" and self.db.armorChoice == "skin"
                    icon(key, skin and "skin" or key)
                end
            end
        end
        if self.db.buffs.soul and (not isSelf or self.db.soulSelf) then icon("soul") end
        if isSelf then
            if self.db.stoneCreation then
                for _, kind in ipairs({"soul", "fire", "spell", "health"}) do
                    local enabled = kind == "health" or (kind == "soul" and self.db.buffs.soul)
                        or ((kind == "fire" or kind == "spell") and self.db.buffs.weapon)
                    if enabled and (kind~="health" or frame==PlayerFrame) and self.db.createStones[kind] then icon(kind, nil, true) end
                end
            end
            if self.db.buffTargets.self then
                if frame==PlayerFrame and self.db.buffs.health then icon("health", nil, false, true) end
                if self.db.buffs.weapon and (self.db.weaponStone=="fire" or self.db.weaponStone=="spell") then
                    icon(self.db.weaponStone)
                end
            end
        end
        local mainPlayer=frame==PlayerFrame
        if self.db.itemsEnabled and self.db.buffTargets[mainPlayer and "self" or "group"] then
            for index,entry in ipairs(self.db.items) do
                if entry.enabled and (mainPlayer or entry.party) then icon("items",nil,false,false,entry.id,index) end
            end
        end
        for i = count + 1, #row.squares do row.squares[i]:Hide() end
        F:LayoutIndicators(row,frame,isSelf,displayed,kind)
        for _,button in ipairs(displayed) do if button.customItem then F:UpdateCustomItemVisual(button) end end
    end
    local groupShown,raidShown = false,false
    for frame,overlay in pairs(self.overlays) do
        if frame:IsVisible() then
            local unit = frame == PlayerFrame and "player" or frame.unit or frame:GetAttribute("unit")
            if unit and not (issecretvalue and issecretvalue(unit)) then
                local isSelf = F:IsSelf(unit)
                draw(frame, isSelf, overlay.frameKind)
                if overlay.frameKind=="raid" then raidShown=true end
                if not isSelf then groupShown = true end
            end
        end
    end
    -- Solo players can still configure party placement without joining a group.
    if not groupShown then
        self.previewParties=self.previewParties or {}
        for index=1,2 do
            local sample=self.previewParties[index]
            if not sample then
                sample = CreateFrame("Frame", nil, UIParent)
                sample:SetFrameStrata("DIALOG"); sample:SetSize(150, 40); sample:EnableMouse(false)
                local background = sample:CreateTexture(nil, "BACKGROUND")
                background:SetAllPoints(); background:SetColorTexture(.12,.12,.12,.95)
                local label = sample:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
                label:SetPoint("CENTER"); label:SetText(index==1 and "Party frame preview" or "Raid-style party preview")
                self.previewParties[index]=sample
            end
            sample:ClearAllPoints()
            sample:SetPoint("LEFT",UIParent,"LEFT",80,index==1 and 45 or -45)
            sample:Show()
            draw(sample,false,index==2 and "raidParty" or "party")
        end
    else
        for _,sample in ipairs(self.previewParties or {}) do sample:Hide() end
    end
    if not raidShown then
        if not self.previewRaid then
            local sample=CreateFrame("Frame",nil,UIParent)
            sample:SetFrameStrata("DIALOG"); sample:SetSize(110,45); sample:EnableMouse(false)
            local background=sample:CreateTexture(nil,"BACKGROUND")
            background:SetAllPoints(); background:SetColorTexture(.12,.12,.12,.95)
            local label=sample:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            label:SetPoint("CENTER"); label:SetText("Raid frame preview")
            self.previewRaid=sample
        end
        self.previewRaid:ClearAllPoints(); self.previewRaid:SetPoint("LEFT",UIParent,"LEFT",80,-125)
        self.previewRaid:Show(); draw(self.previewRaid,false,"raid")
    elseif self.previewRaid then self.previewRaid:Hide() end
end
