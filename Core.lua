local _, F = ...
FelBot = F
F.version = "0.5.15"
F.maxIndicators = 15
F.defaults = {
    enabled = true, size = 16, spacing = 3, offset = 31, selfOffset = 15,
    priority = { "armor", "sense", "detect", "breath" },
    selfPriority = { "armor", "sense", "detect", "breath", "soul", "weapon", "health", "items" },
    itemsEnabled = true, items = {}, iconVertical = 0, selfIconVertical = 0,
    soulModifier = "ctrl", windowScale = .85,
    buffs = { armor = true, sense = true, detect = true, breath = true, soul = true, weapon = false, health = false },
    healthstoneHealth = 25,
    healthstoneSeparate = false, healthstoneSize = 32, healthstonePlacement = "top",
    healthstoneAlign = "center", healthstoneOffset = 0, healthstoneVertical = 8,
    buffTargets = { self = true, group = true },
    classes = { PRIEST = true, PALADIN = true, DRUID = true, SHAMAN = true, WARRIOR = true },
    rolesOnly = true, armorChoice = "auto", combatClicks = false, combatOpacity = 60,
    frameModifier = "shift",
    soulSelf = true, stoneCreation = true, modifierStones = true,
    createStones = { soul = true, fire = false, spell = false, health = true }, weaponStone = "choose",
    placement = "right", selfPlacement = "right", topAlign = "right", selfTopAlign = "right",
    raidPlacement = "right", vertical = 3, selfVertical = 3,
    raidPartyPlacement="right", raidPartySize=16, raidPartyOffset=31, raidPartyIconVertical=0, raidPartyTopAlign="right", raidPartyVertical=3,
    raidSize=16, raidOffset=31, raidIconVertical=0, raidTopAlign="right", raidVertical=3,
}
F.spells = {
    armor = { ids = { 11735, 11734, 11733, 1086, 706 }, selfOnly = true },
    sense = { ids = { 5500 }, selfOnly = true },
    detect = { ids = { 11743, 11742, 132 } },
    breath = { ids = { 5697 } },
    soul = { ids = { 20757, 20756, 20755, 20752, 693 } },
}
F.stones = { 16896, 16895, 16893, 16892, 5232 }
F.skin = { ids = { 696, 687 } }
F.stoneTypes = {
    soul = { ids = F.spells.soul.ids, items = F.stones },
    fire = { ids = {17953,17952,17951,6366}, items = {13701,13700,13699,1254} },
    spell = { ids = {17728,17727,2362}, items = {13603,13602,5522} },
    health = { ids = {11730,11729,5699,6202,6201},
        -- Each tier: Improved Healthstone 2/2, 1/2, then untalented.
        items = {19013,19012,9421,19011,19010,5510,19009,19008,5509,
            19007,19006,5511,19005,19004,5512} },
}
F.overlays = {}
local function public(value)
    return not (issecretvalue and issecretvalue(value))
end
function F:IsSelf(unit)
    if not public(unit) or not unit then return false end
    if unit == "player" then return true end
    local same = UnitIsUnit(unit, "player")
    -- Unit comparisons can be restricted in instances, including between
    -- range ticks. Never branch on an opaque result or treat it as self.
    return public(same) and (same==true or same==1) or false
end
local defaults
function F:ResetDefaults()
    if InCombatLockdown() then return end
    local settings = {}
    defaults(settings, self.defaults)
    settings.selfSize = settings.size
    if not self.editingOptions then FelBotDB = settings end
    self.db = settings
    if self.options then
        self.options:ClearAllPoints(); self.options:SetPoint("CENTER")
        if self.options.SyncFields then self.options:SyncFields() end
    end
    self:Refresh()
    self:Print(self.editingOptions and "Default settings previewed. Click Save to keep them." or "Default settings restored.")
end
function F:CarriedStone(kind)
    for _, id in ipairs(self.stoneTypes[kind].items) do
        if C_Item.GetItemCount(id) > 0 then return id end
    end
end
function F:KeepsStone(kind)
    -- Existing creation choices become keep-stock choices. Turning them
    -- off must not disable a missing buff's create-then-use workflow.
    return self.db.stoneCreation and self.db.createStones[kind]
end
function F:PaintIcon(square, spellID, itemID, creation)
    local texture
    if itemID and C_Item.GetItemIconByID then texture = C_Item.GetItemIconByID(itemID) end
    if not texture and spellID then
        if C_Spell.GetSpellTexture then texture = C_Spell.GetSpellTexture(spellID) end
        if not texture then
            local info = C_Spell.GetSpellInfo(spellID)
            texture = info and info.iconID
        end
    end
    square.texture:SetTexture(public(texture) and texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    -- Stage opacity composes with range/combat and opaque health alpha.
    square.texture:SetAlpha(creation and .75 or 1)
    square.text:SetText(creation and "+" or "")
end
function F:ItemReady(id)
    local start,duration,enabled=C_Item.GetItemCooldown(id)
    return public(start) and public(duration) and public(enabled)
        and (enabled == true or enabled == 1)
        and (start == 0 or start + duration <= GetTime())
end
function F:HealthstoneRecommended()
    if InCombatLockdown() or not self.db.buffs.health then return false end
    local health, maximum = UnitHealth("player"), UnitHealthMax("player")
    if not public(health) or not public(maximum) or maximum <= 0 then return false end
    return health * 100 / maximum < self.db.healthstoneHealth
end
function F:HealthstoneAlpha()
    if not self.db.buffs.health then return 0 end
    if UnitHealthPercent and C_CurveUtil and C_CurveUtil.CreateCurve and Enum
        and Enum.LuaCurveType and Enum.LuaCurveType.Step then
        if not self.healthCurve or self.healthCurveThreshold ~= self.db.healthstoneHealth then
            local curve = C_CurveUtil.CreateCurve()
            curve:SetType(Enum.LuaCurveType.Step)
            curve:AddPoint(0, 1)
            curve:AddPoint(self.db.healthstoneHealth / 100, 0)
            if self.db.healthstoneHealth < 100 then curve:AddPoint(1, 0) end
            self.healthCurve, self.healthCurveThreshold = curve, self.db.healthstoneHealth
        end
        -- This result may be secret. Pass it directly to the display API;
        -- never inspect it to choose or change a protected action.
        return UnitHealthPercent("player", false, self.healthCurve)
    end
    return self:HealthstoneRecommended() and 1 or 0
end
function F:SetAction(button, prefix, action)
    for _, key in ipairs({"type", "spell", "item", "macrotext"}) do
        button:SetAttribute(prefix .. key .. "1", key == "type" and "" or nil)
    end
    if not action then return end
    button:SetAttribute(prefix .. "type1", action.type)
    if action.spell then button:SetAttribute(prefix .. "spell1", action.spell) end
    if action.item then button:SetAttribute(prefix .. "item1", action.item) end
    if action.macrotext then button:SetAttribute(prefix .. "macrotext1", action.macrotext) end
end
function F:UpdateActivation()
    if not self.activate then
        local button = CreateFrame("Button", "FelBotActivateButton", UIParent,
            "SecureActionButtonTemplate,SecureHandlerStateTemplate")
        button:SetSize(1,1); button:SetPoint("TOPLEFT"); button:SetAlpha(0); button:EnableMouse(false)
        -- Native CLICK bindings deliver a key-down event. Execute exactly
        -- that edge instead of relying on a key-up callback being delivered.
        button:RegisterForClicks("AnyDown")
        button:SetAttribute("useOnKeyDown", true)
        button:SetAttribute("unit", "player")
        button:SetAttribute("checkselfcast", false)
        button:SetAttribute("checkfocuscast", false)
        button:SetAttribute("_onstate-combat", [[
            if newstate == "combat" then
                -- Health-dependent priority cannot be evaluated securely here.
                self:SetAttribute("type1", "")
                self:SetAttribute("item1", nil)
            else
                self:SetAttribute("type1", self:GetAttribute("next-type") or "")
                self:SetAttribute("item1", self:GetAttribute("next-item"))
            end
        ]])
        RegisterStateDriver(button, "combat", "[combat] combat; safe")
        self.activate = button
    end
    local action = self.selfAction
    local button = self.activate
    button:SetAttribute("next-type", action and action.type or "")
    button:SetAttribute("next-item", action and action.item)
    self:SetAction(button, "", action)
end
function F:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffaa66ddFelBot:|r " .. message)
end
defaults = function(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            defaults(target[key], value)
        elseif target[key] == nil then target[key] = value end
    end
end
function F:LearnedSpell(ids)
    for _, id in ipairs(ids) do
        -- Spell info exists for unlearned spells too: always check the book.
        if (IsPlayerSpell and IsPlayerSpell(id)) or (IsSpellKnown and IsSpellKnown(id)) then
            local info = C_Spell.GetSpellInfo(id)
            if info then return info.name, id end
        end
    end
end
function F:Spell(key)
    if key == "armor" then
        local choice = self.db.armorChoice
        if choice ~= "skin" then
            local name, id = self:LearnedSpell(self.spells.armor.ids)
            if name then return name, "armor", id end
        end
        if choice ~= "armor" then
            local name, id = self:LearnedSpell(self.skin.ids)
            if name then return name, "skin", id end
        end
        return
    end
    local name, id = self:LearnedSpell(self.spells[key].ids)
    return name, nil, id
end
function F:HasBuff(unit, name)
    for index = 1, 255 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL")
        if not aura then break end
        if not public(aura.name) then return true end -- unknown: do not recommend a cast
        if aura.name == name then return true end
    end
    return false
end
function F:Tracking(name)
    if not C_Minimap or not C_Minimap.GetNumTrackingTypes then return true end
    for index = 1, C_Minimap.GetNumTrackingTypes() do
        local info = C_Minimap.GetTrackingInfo(index)
        if info and info.name == name then return info.active end
    end
    return false
end
function F:Stone()
    local id = self:CarriedStone("soul")
    if id and self:ItemReady(id) then return id end
end
function F:SoulEligible(unit)
    if self:IsSelf(unit) then return self.db.soulSelf end
    if self.db.rolesOnly then
        local role = UnitGroupRolesAssigned(unit)
        return role == "TANK" or role == "HEALER"
    end
    local _, class = UnitClass(unit)
    return self.db.classes[class]
end
-- A fixed @unit macro has no default-target clause, so failed targeting
-- cannot fall back to the player's current target or automatic self-cast.
function F:TargetMacro(unit, spellID, itemID)
    if not unit or not (unit == "player" or unit:match("^party%d+$") or unit:match("^raid%d+$")) then return end
    local condition = "[@" .. unit .. ",exists,help,nodead] "
    if itemID then return "/use " .. condition .. "item:" .. itemID end
    local info = C_Spell.GetSpellInfo(spellID)
    if not info then return end
    local rank = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellID)
    local spell = info.name .. (rank and rank ~= "" and ("(" .. rank .. ")") or "")
    return "/cast " .. condition .. spell
end
function F:RangeStatus(unit, spellID, itemID)
    if self:IsSelf(unit) then return true end
    local exists = UnitExists(unit)
    if public(exists) and not exists then return false end
    if UnitIsVisible then
        local visible = UnitIsVisible(unit)
        if public(visible) and not visible then return false end
    end
    local result
    if itemID and C_Item.IsItemInRange then result = C_Item.IsItemInRange(itemID, unit)
    elseif spellID and C_Spell.IsSpellInRange then result = C_Spell.IsSpellInRange(spellID, unit) end
    if public(result) and result ~= nil then return result end
    -- A remote unit can yield nil for spell range; group range is a fallback.
    if UnitInRange then
        local inRange, checked = UnitInRange(unit)
        if public(inRange) and public(checked) and checked and not inRange then return false end
    end
end
function F:Modifiers()
    local regular = self.db.frameModifier
    if regular ~= "shift" and regular ~= "ctrl" and regular ~= "alt" then regular = nil end
    local soul = self.db.soulModifier
    if soul ~= "shift" and soul ~= "ctrl" and soul ~= "alt" then soul = "ctrl" end
    return regular, soul
end
function F:NormalizeSelfPriority(order)
    local result, seen = {}, {}
    local valid = {armor=true,sense=true,detect=true,breath=true,soul=true,weapon=true,items=true,health=true}
    for _, source in ipairs({order or {}, self.defaults.selfPriority}) do
        for _, key in ipairs(source) do
            if valid[key] and not seen[key] then
                result[#result+1], seen[key] = key, true
            end
        end
    end
    return result
end
function F:UpgradeSettings(settings)
    local order, soul, regular = settings.selfPriority, settings.soulModifier, settings.frameModifier
    if type(settings.buffs)~="table" then settings.buffs={} end
    if settings.weaponStone=="off" then
        settings.buffs.weapon=false
        settings.weaponStone="choose"
    elseif settings.weaponStone=="fire" or settings.weaponStone=="spell" then
        if settings.buffs.weapon==nil then settings.buffs.weapon=true end
    else
        settings.weaponStone="choose"
    end
    local raidPlacement = settings.raidPlacement or settings.placement or "right"
    for _,prefix in ipairs({"raidParty","raid"}) do
        local legacy={Size="size",Offset="offset",IconVertical="iconVertical",TopAlign="topAlign",Vertical="vertical"}
        for suffix,oldKey in pairs(legacy) do
            local key=prefix..suffix
            if settings[key]==nil then settings[key]=settings[oldKey] or self.defaults[oldKey] end
        end
    end
    if settings.raidPartyPlacement==nil then settings.raidPartyPlacement=raidPlacement end
    defaults(settings, self.defaults)
    settings.raidPlacement = raidPlacement
    settings.actualIcons, settings.colors = nil, nil -- obsolete square-art settings
    settings.items = self:NormalizeItems(settings.items)
    settings.selfPriority = self:NormalizeSelfPriority(order or settings.priority)
    if soul == nil then settings.soulModifier = regular == "ctrl" and "shift" or "ctrl" end
    return settings
end
function F:SelfActionScore(key, extra)
    local group = (key == "fire" or key == "spell") and "weapon" or key
    for index, entry in ipairs(self.db.selfPriority) do
        if entry == group then
            local within = group=="items" and (extra.itemIndex or 1)
                or (group=="health" and not extra.healthstoneReminder and 1)
                or (group == "weapon" and key ~= self.db.weaponStone and 1 or 0)
            return index + within/(within+1)
        end
    end
    return 900
end
function F:Missing(key, unit)
    if not self.db.buffs[key] then return end
    if key ~= "soul" and not self.db.buffTargets[self:IsSelf(unit) and "self" or "group"] then return end
    if self.spells[key].selfOnly and not self:IsSelf(unit) then return end
    local name, appearance, spellID = self:Spell(key)
    if not name then return end
    if key == "sense" then return not self:Tracking(name), name, nil, spellID end
    if key == "soul" then
        if not self:SoulEligible(unit) then return end
        local carried = self:CarriedStone("soul")
        if carried then
            if not self:ItemReady(carried) then return end
        elseif self:KeepsStone("soul") then return end
        -- Soulstone Resurrection is distinct from the ranked creation spells.
        local aura = C_Spell.GetSpellInfo(20707)
        if self:HasBuff(unit, aura and aura.name or name) then return end
        for i = 1, 255 do
            local buff = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
            if not buff then break end
            if not public(buff.spellId) then return end
            if buff.spellId == 20707 or buff.spellId == 20762 or buff.spellId == 20763
                or buff.spellId == 20764 or buff.spellId == 20765 then return end
        end
        local stone = self:Stone()
        local itemName = stone and C_Item.GetItemNameByID and C_Item.GetItemNameByID(stone)
        return true, itemName or name
    end
    return not self:HasBuff(unit, name), name, appearance, spellID
end
-- Range fading lives on a visual child, so it composes with the secure
-- combat alpha without changing protected attributes during combat.
function F:UpdateRange()
    if not self.db then return end
    for _, overlay in pairs(self.overlays) do
        for _, button in ipairs(overlay.indicators.squares) do
            if button:IsShown() and button.buffUnit then
                local inRange = self:RangeStatus(button.buffUnit, button.buffSpellID, button.rangeItem)
                button.outOfRange = inRange == false
                -- nil/secret means unknown, not out of range.
                local out = public(inRange) and inRange == false
                if button.customItem then self:UpdateCustomItemVisual(button) end
                if button.healthstoneReminder then
                    if button.isCreation and InCombatLockdown() then
                        button.visual:SetAlpha(0) -- no ready Healthstone to use in combat
                    else
                        button.visual:SetAlpha(self:HealthstoneAlpha())
                    end
                else
                    button.visual:SetAlpha(out and 0.5 or 1)
                end
                if not InCombatLockdown() then
                    button:SetAttribute("type1", out and "" or (button:GetAttribute("buff-action") or ""))
                end
            end
        end
    end
end
function F:IndicatorCapacity(frame)
    local count=0
    for _,entry in ipairs(self.db.items) do
        if frame==PlayerFrame or entry.party then count=count+1 end
    end
    return math.max(self.maxIndicators,9+count)
end
function F:EnsureIndicators(frame,indicators,needed)
    for i = #indicators.squares+1, needed do
        local square = CreateFrame("Button", nil, indicators,
            "SecureActionButtonTemplate,SecureHandlerStateTemplate")
        square:SetFrameLevel(frame:GetFrameLevel() + 21)
        square:RegisterForClicks("AnyUp", "AnyDown")
        square:SetAttribute("useOnKeyDown", false)
        square:SetAttribute("checkselfcast", false)
        square:SetAttribute("checkfocuscast", false)
        -- Combat uses the actions assigned out of combat; never retarget or
        -- rebuild protected buttons during combat.
        square:SetAttribute("_onstate-combat", [[
            if newstate == "combat" then
                if self:GetAttribute("combat-clicks") then
                    self:SetAttribute("type1", self:GetAttribute("buff-action") or "")
                else
                    self:SetAttribute("type1", "")
                end
                self:SetAlpha(self:GetAttribute("combat-alpha") or 0.6)
            else
                self:SetAttribute("type1", self:GetAttribute("buff-action") or "")
                self:SetAlpha(1)
            end
        ]])
        RegisterStateDriver(square, "combat", "[combat] combat; safe")
        square:SetScript("OnEnter", function(button)
            if not button.buffName then return end
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(button.buffName, 1, 1, 1)
            local target = (not button.customItem or button.customParty) and button.buffUnit and UnitName(button.buffUnit)
            if public(target) and target then GameTooltip:AddLine("Target: " .. target, .8, .8, .8) end
            if button.customItem then
                local data=F:CustomItemData(button.customItem,button.buffUnit)
                GameTooltip:AddLine(not data.usable and data.status or (data.count==0 and "Not carried." or
                    (button.customParty and "Left-click to use on this party / raid member." or "Left-click to use from your bags.")),.8,.8,.8)
                if data.usable and data.count>0 then GameTooltip:AddLine(data.status,.8,.8,.8) end
            end
            if InCombatLockdown() and (button.isCreation or not F.db.combatClicks) then
                GameTooltip:AddLine(button.isCreation and "Create stones before combat." or "Casting disabled in combat.", 1, .65, .2)
            elseif button.outOfRange then
                GameTooltip:AddLine("Out of range or in another zone.", 1, .4, .2)
            elseif button.customItem then
                -- Custom-item instructions are shown above.
            elseif button.isCreation then
                GameTooltip:AddLine("Left-click to create this stone (requires a Soul Shard).", .4, 1, .4)
                if button.onDemand then
                    GameTooltip:AddLine("Once created, click this icon again to use it. Prepare stones before combat.", .8, .8, .8, true)
                end
            elseif button.weaponItem then
                GameTooltip:AddLine("Left-click to apply to your main-hand weapon.", .4, 1, .4)
            elseif button.consumeItem then
                GameTooltip:AddLine("Left-click to consume your Healthstone.", .4, 1, .4)
            else
                GameTooltip:AddLine("Left-click to apply this buff.", .4, 1, .4)
            end
            if button.buffKey == "soul" and not button.isCreation then
                GameTooltip:AddLine("Uses a Soulstone already in your bags.", .8, .8, .8)
            end
            GameTooltip:Show()
        end)
        square:SetScript("OnLeave", function() GameTooltip:Hide() end)
        square:SetScript("OnHide", function(button)
            if GameTooltip:GetOwner() == button then GameTooltip:Hide() end
        end)
        square.visual = CreateFrame("Frame", nil, square)
        square.visual:SetAllPoints()
        square.texture = square.visual:CreateTexture(nil, "BACKGROUND")
        square.texture:SetAllPoints()
        square.text = square.visual:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        square.text:SetPoint("CENTER")
        square.text:SetTextColor(1, 1, 1)
        self:CreateItemSlash(square)
        indicators.squares[i] = square
    end
end
function F:Attach(frame, kind)
    if kind==true then kind="raidParty" end
    local compact=kind=="raidParty" or kind=="raid"
    if self.overlays[frame] then
        if kind then self.overlays[frame].frameKind=kind; self.overlays[frame].compact=compact end
        return
    end
    local indicators = CreateFrame("Frame", nil, frame)
    indicators:SetPoint("LEFT", frame, "RIGHT", 3, 0)
    indicators:SetSize(1, 1)
    indicators.squares = {}
    self:EnsureIndicators(frame,indicators,self:IndicatorCapacity(frame))
    -- Modifier layer is out of combat only. Secure state changes clear all
    -- actions during combat so no stale Healthstone bypasses its threshold.
    local click = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate,SecureHandlerStateTemplate")
    click:SetAllPoints(frame)
    click:SetFrameLevel(frame:GetFrameLevel() + 20)
    click:RegisterForClicks("AnyUp", "AnyDown")
    click:SetAttribute("useOnKeyDown", false)
    click:SetAttribute("checkselfcast", false)
    click:SetAttribute("checkfocuscast", false)
    -- Restricted snippets reject literal tables, even as loop inputs.
    -- Use numeric loops and scalar names instead of allocating tables.
    click:SetAttribute("_onstate-combat", [[
        for i = 1, 3 do
            local modifier = i == 1 and "shift" or (i == 2 and "ctrl" or "alt")
            for j = 1, 4 do
                local key = j == 1 and "type1" or (j == 2 and "spell1" or (j == 3 and "item1" or "macrotext1"))
                local attribute = modifier .. "-" .. key
                if newstate == "combat" then
                    self:SetAttribute(attribute, key == "type1" and "" or nil)
                else
                    self:SetAttribute(attribute, self:GetAttribute("safe-" .. attribute))
                end
            end
        end
    ]])
    RegisterStateDriver(click, "combat", "[combat] combat; safe")
    self.overlays[frame] = { indicators = indicators, click = click, compact = compact, frameKind=kind or "party" }
end
function F:Discover()
    local function consider(frame, kind)
        if frame and not frame:IsForbidden() then self:Attach(frame, kind) end
    end
    consider(PlayerFrame,"self")
    if CompactPartyFrame and CompactPartyFrame.memberUnitFrames then
        for _, member in ipairs(CompactPartyFrame.memberUnitFrames) do consider(member, "raidParty") end
    end
    for i = 1, 4 do
        consider(_G["PartyMemberFrame" .. i],"party")
        if PartyFrame then consider(PartyFrame["MemberFrame" .. i],"party") end
    end
    for i = 1, 5 do consider(_G["CompactPartyFrameMember" .. i], "raidParty") end
    for i = 1, 40 do consider(_G["CompactRaidFrame" .. i], "raid") end
    for group = 1, 8 do
        local raidGroup = _G["CompactRaidGroup" .. group]
        if raidGroup and raidGroup.memberUnitFrames then
            for _, member in ipairs(raidGroup.memberUnitFrames) do consider(member, "raid") end
        end
        for member = 1, 5 do consider(_G["CompactRaidGroup" .. group .. "Member" .. member], "raid") end
    end
end
function F:Refresh()
    if not self.db or InCombatLockdown() then return end
    self:RefreshItemBuffs()
    self:Discover()
    self.selfAction = nil
    for frame, overlay in pairs(self.overlays) do
        local unit = frame.unit or frame:GetAttribute("unit")
        if frame == PlayerFrame then unit = "player" end
        local click = overlay.click
        local regular, soulModifier = self:Modifiers()
        local isSelf = public(unit) and self:IsSelf(unit)
        local mainPlayer = frame==PlayerFrame
        local driver = "hide"
        if self.db.enabled and not self.testUI then
            driver = "[combat] hide; " .. (regular and ("[mod:" .. regular .. "] show; ") or "")
                .. "[mod:" .. soulModifier .. "] show; hide"
        end
        if overlay.driver ~= driver then
            RegisterStateDriver(click, "visibility", driver)
            overlay.driver = driver
        end
        self:EnsureIndicators(frame,overlay.indicators,self:IndicatorCapacity(frame))
        for _, square in ipairs(overlay.indicators.squares) do
            square:SetAttribute("combat-clicks", self.db.combatClicks and not self.testUI)
            square:SetAttribute("combat-alpha", self.db.combatOpacity / 100)
        end
        for _, modifier in ipairs({ "shift", "ctrl", "alt" }) do
            click:SetAttribute(modifier .. "-type1", "")
            click:SetAttribute(modifier .. "-spell1", nil)
            click:SetAttribute(modifier .. "-item1", nil)
            click:SetAttribute(modifier .. "-macrotext1", nil)
        end
        click:SetAttribute("unit", unit)
        local count, nextSpell, selfAction, soulAction, frameAction, partyItemAction = 0, nil, nil, nil, nil, nil
        local displayed = {}
        local groupMember = false
        if public(unit) and unit then
            local party = UnitInParty and UnitInParty(unit)
            local raid = UnitInRaid and UnitInRaid(unit)
            groupMember = (public(party) and party) or (public(raid) and raid) or false
        end
        local valid = not self.testUI and self.db.enabled and unit and public(unit) and (UnitExists(unit) or groupMember)
            and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit)
            and (groupMember or UnitIsFriend("player", unit))
        local function indicator(key, spell, appearance, spellID, extra)
            extra = extra or {}
            count = count + 1
            local square = overlay.indicators.squares[count]
            displayed[count] = square
            square.buffName, square.buffUnit, square.buffKey = spell, extra.creation and "player" or unit, key
            square.buffSpellID = spellID
            square.rangeItem = nil
            square.isCreation, square.weaponItem, square.consumeItem = extra.creation, extra.weaponItem, extra.consumeItem
            square.healthstoneReminder, square.onDemand = extra.healthstoneReminder, extra.onDemand
            square.customItem, square.itemIndex = extra.customItem, extra.itemIndex
            square.customParty = extra.customItem and not mainPlayer or false
            square.missingSlash:Hide()
            square:SetAttribute("unit", extra.creation and "player" or unit)
            square:SetAttribute("spell", nil)
            square:SetAttribute("item", nil)
            square:SetAttribute("macrotext", nil)
            local action = extra.creation and "spell" or (extra.weaponItem or not isSelf) and "macro"
                or ((extra.consumeItem or (key == "soul" and not extra.creation)) and "item" or "spell")
            -- Keep the fixed item binding even when a consumable is missing,
            -- like an action-bar slot. The game checks inventory on use, and
            -- a restock in combat needs no protected-attribute changes.
            local customMacro
            if extra.customItem then
                customMacro=mainPlayer and ("/use item:"..extra.customItem) or self:TargetMacro(unit,nil,extra.customItem)
                action=extra.itemUsable and customMacro and "macro" or ""
            end
            square:SetAttribute("combat-clicks", self.db.combatClicks and not extra.creation and action~="")
            square:SetAttribute("buff-action", action)
            square:SetAttribute("type1", action)
            if extra.customItem then
                -- Match a bag right-click, without forcing the item onto self
                -- or requiring the client to expose its associated spell.
                square:SetAttribute("macrotext",customMacro)
                if not mainPlayer then square.rangeItem=extra.customItem end
            elseif extra.weaponItem then
                square:SetAttribute("macrotext", "/use item:" .. extra.weaponItem .. "\n/use 16")
            elseif extra.consumeItem then
                square:SetAttribute("item", "item:" .. extra.consumeItem)
            elseif key == "soul" and not extra.creation then
                square.rangeItem = self:Stone()
                square:SetAttribute("item", "item:" .. square.rangeItem)
                if not isSelf then square:SetAttribute("macrotext", self:TargetMacro(unit, nil, square.rangeItem)) end
            else
                -- Explicit rank ID avoids name resolution/downranking ambiguity.
                square:SetAttribute("spell", spellID)
                if not isSelf and not extra.creation then square:SetAttribute("macrotext", self:TargetMacro(unit, spellID)) end
            end
            self:PaintIcon(square, spellID, extra.customItem or extra.weaponItem or extra.consumeItem or square.rangeItem, extra.creation)
            square:Show()
            if not isSelf and extra.customItem and extra.queueEligible and not partyItemAction
                and self:RangeStatus(unit,nil,extra.customItem)~=false then
                partyItemAction={type=action,macrotext=customMacro}
            end
            -- Unknown/restricted health is not permission to choose HS.
            if isSelf and (not extra.healthstoneReminder or self:HealthstoneRecommended())
                and (not extra.customItem or extra.queueEligible) then
                local score = self:SelfActionScore(key, extra)
                local candidate={score=score,type=action,spell=spellID,
                    item=square:GetAttribute("item"),macrotext=square:GetAttribute("macrotext")}
                if not selfAction or score < selfAction.score then
                    selfAction = candidate
                end
                if (not self.stoneTypes[key] or self.db.modifierStones) and (not frameAction or score<frameAction.score) then
                    frameAction=candidate
                end
            end
        end
        if valid then
            for _, key in ipairs(self.db.priority) do
                local missing, spell, appearance, spellID = self:Missing(key, unit)
                if missing then indicator(key, spell, appearance, spellID); nextSpell = nextSpell or spellID end
            end
            local soulMissing, soulName = self:Missing("soul", unit)
            if soulMissing then
                local stone = self:Stone()
                if stone then
                    indicator("soul", soulName)
                    soulAction = isSelf and {type="item",item="item:" .. stone}
                        or {type="macro",macrotext=self:TargetMacro(unit, nil, stone)}
                else
                    local name, id = self:LearnedSpell(self.stoneTypes.soul.ids)
                    indicator("soul", name, "soul", id, {creation=true,onDemand=true})
                    soulAction = {type="macro",macrotext=self:TargetMacro("player", id)}
                end
                if soulModifier ~= regular then self:SetAction(click, soulModifier .. "-", soulAction) end
            end
            if isSelf then
                for _, kind in ipairs({"soul", "fire", "spell", "health"}) do
                    local stoneType = self.stoneTypes[kind]
                    local name, id = self:LearnedSpell(stoneType.ids)
                    local enabled = (kind == "soul" and self.db.buffs.soul)
                        or kind == "health" -- creation is independent of the use indicator
                        or ((kind == "fire" or kind == "spell") and self.db.buffs.weapon)
                    if enabled and (kind~="health" or mainPlayer) and name and self:KeepsStone(kind)
                        and not self:CarriedStone(kind) then
                        indicator(kind, name, "create", id, {creation=true})
                    end
                end
                if mainPlayer and self.db.buffs.health and self.db.buffTargets.self then
                    local item = self:CarriedStone("health")
                    local name, id = self:LearnedSpell(self.stoneTypes.health.ids)
                    -- Reserve the fixed Healthstone action independently of health.
                    -- Its visual child can then update safely during combat.
                    if name and item and self:ItemReady(item) then
                        local itemName = C_Item.GetItemNameByID and C_Item.GetItemNameByID(item)
                        indicator("health", itemName or name, "health", nil, {consumeItem=item,healthstoneReminder=true})
                    elseif name and not item and not self:KeepsStone("health") then
                        indicator("health", name, "health", id, {creation=true,onDemand=true,healthstoneReminder=true})
                    end
                end
                local kind = self.db.weaponStone
                if self.db.buffs.weapon and self.db.buffTargets.self and (kind == "fire" or kind == "spell") then
                    local item = self:CarriedStone(kind)
                    local name, id = self:LearnedSpell(self.stoneTypes[kind].ids)
                    local enchanted = GetWeaponEnchantInfo()
                    -- Preserve existing oils/imbues, including the other stone.
                    if public(enchanted) and not enchanted and name and GetInventoryItemID("player",16) then
                        if item and self:ItemReady(item) then
                            local itemName = C_Item.GetItemNameByID and C_Item.GetItemNameByID(item)
                            indicator(kind, itemName or name, kind, nil,
                                {weaponItem=item})
                        elseif not item and not self:KeepsStone(kind) then
                            indicator(kind, name, kind, id,
                                {creation=true,onDemand=true})
                        end
                    end
                end
            end
            if self.db.itemsEnabled and self.db.buffTargets[mainPlayer and "self" or "group"] then
                for index,entry in ipairs(self.db.items) do
                    if entry.enabled and (mainPlayer or entry.party) then
                        local data=self:CustomItemData(entry.id,unit)
                        if not data.buffActive then
                            indicator("items",data.name,nil,nil,{customItem=entry.id,itemIndex=index,
                                itemUsable=data.usable,queueEligible=entry.queue and data.ready})
                        end
                    end
                end
            end
        end
        if nextSpell and regular then
            click:SetAttribute(regular .. "-type1", "spell")
            click:SetAttribute(regular .. "-spell1", nextSpell)
            if not isSelf then
                click:SetAttribute(regular .. "-type1", "macro")
                click:SetAttribute(regular .. "-macrotext1", self:TargetMacro(unit, nextSpell))
            end
        elseif soulAction and regular == soulModifier and not isSelf then
            -- Self uses its configurable queue below. Party frames retain
            -- the ordinary buff order, then Soulstone when sharing a modifier.
            self:SetAction(click, regular .. "-", soulAction)
        elseif partyItemAction and regular and not isSelf then
            self:SetAction(click,regular.."-",partyItemAction)
        end
        overlay.selfAction = selfAction
        if isSelf then
            if frame == PlayerFrame or not self.selfAction then self.selfAction = selfAction end
            if regular then self:SetAction(click, regular .. "-", frameAction) end
        end
        for _, modifier in ipairs({"shift", "ctrl", "alt"}) do
            for _, key in ipairs({"type1", "spell1", "item1", "macrotext1"}) do
                local attribute = modifier .. "-" .. key
                click:SetAttribute("safe-" .. attribute, click:GetAttribute(attribute))
            end
        end
        for i = count + 1, #overlay.indicators.squares do overlay.indicators.squares[i]:Hide() end
        self:LayoutIndicators(overlay.indicators, frame, isSelf, displayed, overlay.frameKind)
    end
    self:UpdateRange()
    self:UpdateActivation()
    if self.RefreshTestUI then self:RefreshTestUI() end
    if self.options and self.options.UpdateTargetControls then self.options:UpdateTargetControls() end
    if self.options and self.options.UpdateItemRows then self.options:UpdateItemRows() end
    if self.options and self.options.itemBuffEditor and self.options.itemBuffEditor:IsShown() then self.options:UpdateItemBuffEditor() end
    if self.options and self.options.UpdatePriorityRows then self.options:UpdatePriorityRows() end
    if self.UpdateSaveButton then self:UpdateSaveButton() end
end
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event, name, success)
    if event=="UNIT_INVENTORY_CHANGED" and (not public(name) or name~="player") then return end
    if event=="GET_ITEM_INFO_RECEIVED" and F.itemRequests then F.itemRequests[name]=success and "loaded" or "failed" end
    if event == "ADDON_LOADED" then
        if name ~= "FelBot" then return end
        local _, class = UnitClass("player")
        if class ~= "WARLOCK" then return end
        FelBotDB = F:UpgradeSettings(FelBotDB or {})
        FelBotDB.enabled = true -- disabling is now handled by the game's AddOns menu
        FelBotDB.healthstoneLimit = nil -- superseded by the single Healthstone toggle
        -- Preserve the existing self appearance when upgrading to split layouts.
        if FelBotDB.selfSize == nil then FelBotDB.selfSize = FelBotDB.size end
        if FelBotDB.selfOffset == nil then FelBotDB.selfOffset = FelBotDB.offset end
        F.db = FelBotDB
        for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "UNIT_AURA",
            "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "SPELLS_CHANGED", "BAG_UPDATE_DELAYED", "SPELL_UPDATE_COOLDOWN",
            "MINIMAP_UPDATE_TRACKING", "PLAYER_ROLES_ASSIGNED", "GET_ITEM_INFO_RECEIVED", "UNIT_INVENTORY_CHANGED" }) do events:RegisterEvent(e) end
        C_Timer.NewTicker(1, function() F:Refresh() end)
        C_Timer.NewTicker(0.2, function() F:UpdateRange() end)
        F:CreateOptions()
        F:Print("v" .. F.version .. " loaded. /felbot for settings and frame-click modifiers.")
    end
    if event == "PLAYER_REGEN_DISABLED" then
        F.awaitingOptionsDecision = false
        if F.savePrompt then F.savePrompt:Hide() end
        if F.options then F.options:Hide() end
        GameTooltip:Hide()
    end
    F:Refresh()
end)
BINDING_HEADER_FELBOT = "FelBot"
_G["BINDING_NAME_CLICK FelBotActivateButton:LeftButton"] = "Activate FelBot (Buff Order Queue)"
