local _, F = ...
function F:AddOptionsHeading(parent,title,x,y,width)
    local label=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
    label:SetPoint("TOPLEFT",x,y); label:SetText(title); label:SetTextColor(.65,1,.3)
    local line=parent:CreateTexture(nil,"OVERLAY")
    line:SetPoint("TOPLEFT",x,y-18); line:SetSize(width or 325,1); line:SetColorTexture(.3,.5,.25,.5)
    self.optionUnderlines=self.optionUnderlines or {}
    self.optionUnderlines[#self.optionUnderlines+1]={line=line,parent=parent,x=x,y=y-18}
    self:RefreshOptionsUnderlines()
    return label,line
end
function F:RefreshOptionsUnderlines()
    if not PixelUtil or not PixelUtil.GetNearestPixelSize then return end
    for _,entry in ipairs(self.optionUnderlines or {}) do
        local line=entry.line
        local scale=line:GetEffectiveScale()
        -- Retain a thin line, but never let scaling round it to zero pixels.
        line:SetHeight(PixelUtil.GetNearestPixelSize(1,scale,1))
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT",entry.parent,"TOPLEFT",PixelUtil.GetNearestPixelSize(entry.x,scale),PixelUtil.GetNearestPixelSize(entry.y,scale))
    end
end
function F:AddOptionsText(parent,value,x,y,width)
    local font=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    font:SetPoint("TOPLEFT",x,y)
    -- Keep a gutter inside the scroll viewport. Text extending beyond the
    -- child width is clipped, with scale/pixel rounding changing the cutoff.
    font:SetWidth(math.max(1,math.min(width or 330,parent:GetWidth()-x-12)))
    font:SetJustifyH("LEFT"); font:SetText(value)
    return font
end
function F:SizeOptionsContent(content,height)
    content:SetHeight(height)
    local scroll=content.scroll
    if scroll and scroll.GetVerticalScroll then
        scroll:SetVerticalScroll(math.min(scroll:GetVerticalScroll(),math.max(0,height-scroll:GetHeight())))
    end
end
function F:CreateOptions()
    self.optionUnderlines={}
    local panel = CreateFrame("Frame", "FelBotOptions", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(760, 690)
    panel:SetScale(self.db.windowScale)
    local position = self.db.windowPosition
    if position then
        panel:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
    else panel:SetPoint("CENTER") end
    panel.TitleText:SetText("FelBot v" .. self.version)
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function() panel:StartMoving() end)
    panel:SetScript("OnDragStop", function()
        panel:StopMovingOrSizing()
        local point, _, relativePoint, x, y = panel:GetPoint()
        F.db.windowPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
        F:Refresh()
    end)
    panel:Hide()
    panel:SetScript("OnShow", function() F:BeginOptions() end)
    panel:SetScript("OnHide", function()
        panel:StopMovingOrSizing()
        if panel.StopResizing then panel:StopResizing() end
        if panel.priorityEditor then panel.priorityEditor:Hide() end
        if panel.itemBuffEditor then panel.itemBuffEditor:Hide() end
        if panel.CancelBindingCapture then panel:CancelBindingCapture() end
        F:SetTestUI(false)
        if not InCombatLockdown() then
            -- Let Escape finish closing existing special windows before
            -- opening the confirmation, or the same Escape closes it too.
            C_Timer.After(0, function()
                if not panel:IsShown() then F:OptionsHidden() end
            end)
        end
    end)
    panel.syncers = {}
    panel.placementControls = {}
    function panel:SyncFields()
        F:ApplyWindowScale(F.db.windowScale)
        for _, sync in ipairs(self.syncers) do sync() end
        self:UpdateTargetControls()
        if self.UpdatePriorityRows then self:UpdatePriorityRows() end
    end
    tinsert(UISpecialFrames, "FelBotOptions")
    local banner = panel:CreateTexture(nil, "ARTWORK")
    banner:SetPoint("TOPLEFT", 12, -28)
    banner:SetPoint("TOPRIGHT", -12, -28)
    banner:SetHeight(150)
    banner:SetTexture("Interface\\AddOns\\FelBot\\Media\\Header")
    banner:SetTexCoord(0,1,.04,.65)
    local title = panel:CreateTexture(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", 24, -40)
    title:SetSize(270, 90)
    title:SetTexture("Interface\\AddOns\\FelBot\\Media\\Wordmark")
    local function text(parent, value, x, y, width)
        return F:AddOptionsText(parent,value,x,y,width)
    end
    text(panel, "Warlock buffs", 35, -130, 280)
    text(panel, "By Zivany Dots", 35, -152, 280)
    local pages, tabs = {}, {}
    local function selectTab(index)
        if panel.priorityEditor then panel.priorityEditor:Hide() end
        if panel.itemBuffEditor then panel.itemBuffEditor:Hide() end
        if panel.CancelBindingCapture then panel:CancelBindingCapture() end
        panel.selectedTab = index
        for i, page in ipairs(pages) do
            page:SetShown(i == index)
            tabs[i]:SetEnabled(i ~= index)
        end
    end
    for i, name in ipairs({ "Buffs", "Stones", "Pots / Items", "Targets", "Frame Placement", "Icon Placement" }) do
        local index = i
        local page = CreateFrame("Frame", nil, panel)
        page:SetPoint("TOPLEFT", 20, -230)
        page:SetPoint("BOTTOMRIGHT", -20, 60)
        pages[i] = page
        local tab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        tab:SetSize(115, 28)
        tab:SetPoint("TOPLEFT", 20 + (i - 1) * 120, -190)
        tab:SetText(name)
        tab:SetScript("OnClick", function() selectTab(index) end)
        tabs[i] = tab
    end
    panel.pages, panel.tabs = pages, tabs
    local gated = {}
    local function gate(control, enabled, label)
        gated[#gated + 1] = {control=control, enabled=enabled, label=label}
        return control
    end
    local stoneEnabled = function() return F.db.stoneCreation end
    local healthEnabled = function() return F.db.buffs.health end
    local armorEnabled = function() return F.db.buffs.armor end
    local weaponEnabled = function() return F.db.buffs.weapon end
    local separateEnabled = function() return healthEnabled() and F.db.healthstoneSeparate end
    local function check(parent, name, value, x, y, getter, setter, available)
        local button = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
        button:SetPoint("TOPLEFT", x, y)
        button.text:SetText(value)
        button.text:SetWidth(math.max(1,math.min(330,parent:GetWidth()-x-44)))
        button.text:SetJustifyH("LEFT")
        local function sync() button:SetChecked(getter()) end
        button:SetScript("OnShow", sync)
        panel.syncers[#panel.syncers+1] = sync
        button:SetScript("OnClick", function()
            if InCombatLockdown() or (available and not available()) then button:SetChecked(getter()); return end
            setter(button:GetChecked()); F:Refresh()
        end)
        if available then gate(button, available) end
        return button
    end
    local function dropdown(parent, name, titleText, key, choices, x, y, available, placeholder)
        local label = text(parent, titleText, x, y)
        local control = CreateFrame("DropdownButton", name, parent, "WowStyle1DropdownTemplate")
        control.label = label
        control:SetPoint("TOPLEFT", x, y - 24)
        control:SetWidth(math.max(1,math.min(320,parent:GetWidth()-x-12)))
        control:SetDefaultText(placeholder or choices[1][1])
        control:SetupMenu(function(_, root)
            for _, entry in ipairs(choices) do
                root:CreateRadio(entry[1], function(v) return F.db[key] == v end, function(v)
                    if InCombatLockdown() or (available and not available()) then return end
                    F.db[key] = v; F:Refresh()
                end, entry[2])
            end
        end)
        panel.syncers[#panel.syncers+1] = function()
            if control.GenerateMenu then control:GenerateMenu() end
        end
        if available then gate(control, available, label) end
        return control
    end
    local buffs, stones, pots, targets, layout, ui = pages[1], pages[2], pages[3], pages[4], pages[5], pages[6]
    local function scrollContent(page,height)
        local scroll=CreateFrame("ScrollFrame",nil,page,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT"); scroll:SetPoint("BOTTOMRIGHT",-28,0)
        local content=CreateFrame("Frame",nil,scroll)
        content:SetSize(690,height); scroll:SetScrollChild(content)
        content.scroll=scroll
        return content
    end
    layout=scrollContent(layout,650); ui=scrollContent(ui,790)
    buffs=scrollContent(buffs,510); stones=scrollContent(stones,490); pots=scrollContent(pots,510)
    panel.buffContent,panel.stoneContent,panel.itemContent=buffs,stones,pots
    panel.layoutContent,panel.iconContent=layout,ui
    local function heading(parent,title,x,y,width)
        return F:AddOptionsHeading(parent,title,x,y,width)
    end
    heading(buffs,"Buff reminders",0,0)
    heading(buffs,"Frame click modifiers",350,0,325)
    for i, key in ipairs({ "armor", "sense", "detect", "breath" }) do
        local k = key
        check(buffs, k=="armor" and "FelBotArmorBuff" or nil, ({ armor = "Demon Armor / Demon Skin (self)", sense = "Sense Demons (self)",
            detect = "Detect Invisibility", breath = "Unending Breath" })[k],
            0, i==1 and -25 or -185-35*(i-2), function() return F.db.buffs[k] end, function(v) F.db.buffs[k] = v end)
    end
    text(buffs, "Soulstone, weapon stones and the Healthstone reminder are configured on the Stones tab.", 0, -295)
    dropdown(buffs, "FelBotArmorChoice", "Armor preference", "armorChoice", {
        { "Automatic (best learned)", "auto" }, { "Demon Armor", "armor" }, { "Demon Skin", "skin" },
    }, 0, -65,armorEnabled)
    text(buffs, "Automatic prefers Demon Armor, then Demon Skin. Only learned spells appear.", 0, -130,325)
    dropdown(buffs, "FelBotFrameModifier", "Frame buff modifier", "frameModifier", {
        { "Shift (default)", "shift" }, { "Alt", "alt" }, { "Ctrl", "ctrl" }, { "Disabled", "off" },
    }, 350, -25)
    dropdown(buffs, "FelBotSoulModifier", "Soulstone frame modifier", "soulModifier", {
        {"Ctrl (default)","ctrl"}, {"Shift","shift"}, {"Alt","alt"},
    },350,-100)
    text(buffs, "Frame click modifiers: Soulstone modifier bypasses the buff queue. If set the same, Soulstone follows Buff Order Queue.",350,-170)
    heading(buffs,"Buff application order",350,-240,325)
    local priority=CreateFrame("Button","FelBotEditPriority",buffs,"UIPanelButtonTemplate")
    priority:SetPoint("TOPLEFT",350,-270); priority:SetSize(240,28); priority:SetText("Buff Order Queue")
    priority:SetScript("OnClick",function()
        if not InCombatLockdown() then panel.priorityEditor:Show() end
    end)
    panel.queueDescription=text(buffs,"Change the order in which buffs are applied",350,-310)
    heading(targets, "Buff targets", 0, 0,690)
    check(targets, "FelBotBuffSelf", "Self", 0, -25,
        function() return F.db.buffTargets.self end, function(v) F.db.buffTargets.self = v end)
    check(targets, "FelBotBuffGroup", "Party / raid members", 350, -25,
        function() return F.db.buffTargets.group end, function(v) F.db.buffTargets.group = v end)
    heading(targets, "Soulstone targets", 0, -85,690)
    check(targets, "FelBotSoulSelf", "Self (independent of role / class filters)", 0, -110,
        function() return F.db.soulSelf end, function(v) F.db.soulSelf = v end)
    check(targets, "FelBotSoulRoles", "Tank / Healer", 0, -145,
        function() return F.db.rolesOnly end, function(v) F.db.rolesOnly = v end)
    text(targets, "Assigned roles; unassigned players excluded.", 190, -154, 500)
    panel.classChecks = {}
    for i, class in ipairs({ "PRIEST", "PALADIN", "DRUID", "SHAMAN", "WARRIOR", "WARLOCK", "MAGE", "ROGUE", "HUNTER" }) do
        local k = class
        panel.classChecks[k] = check(targets, nil, LOCALIZED_CLASS_NAMES_MALE[k] or k,
            i > 5 and 350 or 0, -185 - ((i - 1) % 5) * 28,
            function() return F.db.classes[k] end, function(v)
                if not F.db.rolesOnly then F.db.classes[k] = v end
            end)
    end
    function panel:UpdateTargetControls()
        for _, button in pairs(self.classChecks) do
            button:SetEnabled(not F.db.rolesOnly)
            button:SetAlpha(F.db.rolesOnly and .4 or 1)
        end
        for _, entry in ipairs(gated) do
            local enabled = entry.enabled()
            entry.control:SetEnabled(enabled)
            entry.control:SetAlpha(enabled and 1 or .4)
            if entry.label then entry.label:SetAlpha(enabled and 1 or .4) end
        end
        for _,entry in ipairs(self.placementControls) do
            local shown=entry.visible()
            entry.control:SetShown(shown)
            if entry.control.label then entry.control.label:SetShown(shown) end
        end
        if self.UpdatePlacementLayout then self:UpdatePlacementLayout() end
    end
    panel:UpdateTargetControls()
    local function slider(titleText, key, minimum, maximum, x, y, parent, available)
        local control = CreateFrame("Slider", "FelBotSlider_" .. key, parent or ui, "OptionsSliderTemplate")
        control:SetPoint("TOPLEFT", x, y)
        control:SetWidth(300)
        control:SetMinMaxValues(minimum, maximum)
        control:SetValueStep(1)
        control:SetObeyStepOnDrag(true)
        local name = control:GetName()
        _G[name .. "Low"]:SetText(minimum)
        _G[name .. "High"]:SetText(maximum)
        local syncing = false
        local function sync()
            syncing = true; control:SetValue(F.db[key])
            _G[name .. "Text"]:SetText(titleText .. ": " .. F.db[key]); syncing = false
        end
        control:SetScript("OnShow", sync)
        panel.syncers[#panel.syncers+1] = sync
        control:SetScript("OnValueChanged", function(_, value)
            if syncing or InCombatLockdown() then return end
            if available and not available() then return end
            value = math.floor(value + .5)
            F.db[key] = value
            _G[name .. "Text"]:SetText(titleText .. ": " .. value)
            F:Refresh()
        end)
        if available then gate(control, available) end
        return control
    end
    local function iconGroup(title,sizeKey,offsetKey,verticalKey,x,y)
        heading(ui,title,x,y)
        slider("Icon size",sizeKey,10,40,x+10,y-45)
        slider("Horizontal position",offsetKey,-400,200,x+10,y-110)
        slider("Vertical position",verticalKey,-200,200,x+10,y-175)
    end
    iconGroup("Self Placement","selfSize","selfOffset","selfIconVertical",0,0)
    iconGroup("Standard party frames","size","offset","iconVertical",350,0)
    iconGroup("Raid style party frames","raidPartySize","raidPartyOffset","raidPartyIconVertical",0,-250)
    iconGroup("Raid Frames","raidSize","raidOffset","raidIconVertical",350,-250)
    heading(ui,"Shared icon settings",0,-510,675)
    slider("Icon spacing","spacing",0,15,10,-555)
    text(ui,"Out-of-range icons use 50% opacity. Combat opacity is applied on top.",350,-540,320)
    panel.combatHeading=heading(buffs,"Combat",350,-350,325)
    slider("Combat opacity (%)", "combatOpacity", 0, 100, 360, -490, buffs)
    check(buffs, "FelBotCombatClicks", "Allow casting in combat", 350, -380,
        function() return F.db.combatClicks end, function(v) F.db.combatClicks = v end)
    text(buffs, "Icons and actions refresh after combat due to Blizzard restrictions. The Healthstone reminder can still update.", 382, -415, 296)
    self:SizeOptionsContent(buffs,630)
    heading(stones,"Keep stones in bags reminders",0,0,325)
    heading(stones,"Stone reminders",350,0,325)
    check(stones, "FelBotStoneCreation", "Enable keep-in-bag creation icons", 0, -25,
        function() return F.db.stoneCreation end, function(v) F.db.stoneCreation = v end)
    for i, kind in ipairs({"soul", "fire", "spell", "health"}) do
        local k = kind
        check(stones, "FelBotKeep_" .. k, "Keep " .. ({soul="Soulstone",fire="Firestone",spell="Spellstone",health="Healthstone"})[k] .. " in bags",
            0, -25 -35 * i, function() return F.db.createStones[k] end,
            function(v) F.db.createStones[k] = v end, stoneEnabled)
    end
    check(stones, "FelBotSoulBuff", "Use Soulstone", 350, -25,
        function() return F.db.buffs.soul end, function(v) F.db.buffs.soul = v end)
    check(stones, "FelBotWeaponBuff", "Use Firestone / Spellstone (self)", 350, -60,
        function() return F.db.buffs.weapon end, function(v) F.db.buffs.weapon = v end)
    heading(stones,"Healthstone reminder (self)",350,-200,325)
    check(stones, "FelBotHealthstoneBuff", "Use Healthstone reminder (self)", 350, -225,
        function() return F.db.buffs.health end, function(v) F.db.buffs.health = v end)
    panel.healthstoneSlider = slider("Show Healthstone below health (%)", "healthstoneHealth", 1, 100, 360, -290, stones, healthEnabled)
    text(stones, "Low-health reminder for combat / PvP. Click the HS icon to use it.", 350, -330,325)
    dropdown(stones, "FelBotWeaponStone", "Weapon stone to apply (self)", "weaponStone", {
        {"Firestone", "fire"}, {"Spellstone", "spell"},
    }, 350, -105,weaponEnabled,"Choose a stone")
    heading(stones,"Frame shortcuts",0,-300,325)
    check(stones, "FelBotModifierStones", "Include stones in self-frame modifier clicks", 0, -325,
        function() return F.db.modifierStones end, function(v) F.db.modifierStones = v end)
    text(stones, "Keep in bags: a + icon prompts you to replace a missing stone.\n\nKeep off, Use on: the missing use icon creates a stone first. Click again after creation to use it.", 0, -210,325)
    text(stones, "Include stone creation and use in your regular self-frame modifier.",0,-385,325)
    check(stones, "FelBotSeparateHealthstone", "Separate Healthstone layout", 350, -375,
        function() return F.db.healthstoneSeparate end, function(v) F.db.healthstoneSeparate = v end, healthEnabled)
    text(stones, "Choose its side in Frame Placement; size and offsets in Icon Placement.", 382, -410, 295)
    text(stones, "Keep a Healthstone ready for combat; click its icon to use it.", 350, -465,325)
    self:SizeOptionsContent(stones,530)
    local alignments={{"Left","left"},{"Centre","center"},{"Right","right"}}
    local positions={{"Right of frame","right"},{"Above frame","top"}}
    local raidPositions={{"Right of frame","right"},{"Above frame","top"},{"On frame (overlay)","overlay"}}
    local groups={}
    local function frameGroup(title,name,key,alignName,alignKey,gapKey,choices)
        local group=CreateFrame("Frame",nil,layout)
        group:SetSize(325,230)
        heading(group,title,0,0)
        dropdown(group,name,"Position",key,choices,0,-25)
        local alignment=dropdown(group,alignName,"Frame alignment",alignKey,alignments,0,-95)
        local gap=slider("Gap above frame",gapKey,0,80,10,-185,group)
        group.placementKey=key
        groups[#groups+1]=group
        panel.placementControls[#panel.placementControls+1]={control=alignment,visible=function() return F.db[key]~="right" end}
        panel.placementControls[#panel.placementControls+1]={control=gap,visible=function() return F.db[key]=="top" end}
        return group
    end
    frameGroup("Self Placement","FelBotSelfPlacement","selfPlacement","FelBotSelfAlign","selfTopAlign","selfVertical",positions)
    frameGroup("Standard party frames","FelBotPartyPlacement","placement","FelBotPartyAlign","topAlign","vertical",positions)
    frameGroup("Raid style party frames","FelBotRaidPartyPlacement","raidPartyPlacement","FelBotRaidPartyAlign","raidPartyTopAlign","raidPartyVertical",raidPositions)
    frameGroup("Raid Frames","FelBotRaidPlacement","raidPlacement","FelBotRaidAlign","raidTopAlign","raidVertical",raidPositions)
    local healthGroup=CreateFrame("Frame",nil,layout)
    healthGroup:SetSize(690,120)
    heading(healthGroup,"Separate Healthstone - self frame only",0,0,675)
    dropdown(healthGroup,"FelBotHealthstonePlacement","Position","healthstonePlacement",{{"Above frame","top"},{"Right of frame","right"}},0,-30,separateEnabled)
    local healthAlignment=dropdown(healthGroup,"FelBotHealthstoneAlign","Frame alignment","healthstoneAlign",alignments,350,-30,separateEnabled)
    panel.placementControls[#panel.placementControls+1]={control=healthAlignment,visible=function() return F.db.healthstonePlacement=="top" end}
    panel.framePlacementGroups,panel.healthPlacementGroup=groups,healthGroup
    function panel:UpdatePlacementLayout()
        local bottom={0,0}
        for index,group in ipairs(groups) do
            local column=(index-1)%2+1
            local mode=F.db[group.placementKey]
            local height=mode=="top" and 230 or (mode=="overlay" and 165 or 90)
            group:ClearAllPoints(); group:SetPoint("TOPLEFT",layout,"TOPLEFT",(column-1)*350,-bottom[column])
            group:SetHeight(height); bottom[column]=bottom[column]+height+25
        end
        local healthTop=math.max(bottom[1],bottom[2])
        healthGroup:ClearAllPoints(); healthGroup:SetPoint("TOPLEFT",layout,"TOPLEFT",0,-healthTop)
        F:SizeOptionsContent(layout,healthTop+125)
    end
    heading(ui,"Separate Healthstone - self frame only",0,-610,675)
    slider("Healthstone size","healthstoneSize",16,80,10,-655,ui,separateEnabled)
    slider("Healthstone horizontal position","healthstoneOffset",-400,200,360,-655,ui,separateEnabled)
    slider("Healthstone vertical position","healthstoneVertical",-100,200,10,-725,ui,separateEnabled)
    text(ui,"Independent of other icons. Enabled by Separate Healthstone layout on Stones.",350,-710,320)
    local reset = CreateFrame("Button", "FelBotResetDefaults", panel, "UIPanelButtonTemplate")
    reset:SetSize(150, 24)
    reset:SetPoint("BOTTOMLEFT", 20, 20)
    reset:SetText("Default settings")
    reset:SetScript("OnClick", function() F:ResetDefaults() end)
    local save = CreateFrame("Button", "FelBotSaveOptions", panel, "UIPanelButtonTemplate")
    save:SetSize(150,24)
    save:SetPoint("BOTTOMRIGHT", -20,20)
    save:SetText("Save")
    save:SetScript("OnClick", function() F:SaveOptions() end)
    local test = CreateFrame("CheckButton", "FelBotTestUI", panel, "UICheckButtonTemplate")
    test:SetPoint("BOTTOM", -30, 16)
    test.text:SetText("Test UI")
    test:SetScript("OnClick", function() F:SetTestUI(test:GetChecked()) end)
    panel.test = test
    panel.save = save
    panel:UpdateTargetControls()
    selectTab(1)
    self.options = panel
    self:CreateBindingControls(panel,buffs)
    self:CreateItemsPage(panel,pots)
    self:CreatePriorityEditor(panel)
    self:CreateResizeGrip(panel)
    self:UpdateSaveButton()
end
