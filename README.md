![FelBot green graffiti logo](Artwork/FelBot-wordmark.png)

# FelBot — Warlock Buffs

**By Zivany Dots · Guide for version 0.5.10 · WoW Forever**

FelBot puts missing-buff reminders and clickable spell and item icons alongside your Blizzard unit frames. Keep your Warlock buffs active, manage your stones, choose Soulstone targets, and build a quick-use list of potions and other bag items.

It supports the player frame, standard party frames, raid-style party frames and raid frames, with separate layout settings for each. Icons use the game's spell and item artwork, and hovering over them shows a tooltip. Unlearned spells are not reported as missing, and spell actions use the highest learned rank.

**FelBot does not cast automatically.** Every spell or item use requires a click or key press. It is built around Blizzard unit frames; replacement frames supplied by other UI addons are not currently supported.

<!-- Add an in-game overview screenshot here. -->

## Getting started

Type **`/felbot`** outside combat to open the settings window. Drag the window to move it, or drag its lower-right corner to scale the whole window.

- **Save** keeps your changes. It greys out when there are no unsaved changes.
- **Default settings** previews the defaults. Click Save to keep them.
- Closing with unsaved changes offers **Save**, **Don't save**, or **Cancel**.
- **Test UI** displays non-interactive sample icons using your current settings. It switches off when you close the window or enter combat. Layout edits still need saving.

Settings are stored in the game's SavedVariables under the client's **WTF** settings folder, outside the FelBot addon folder. Replacing the addon folder during an update preserves those settings. Existing choices are retained when defaults change in a new release.

## Buffs

Choose which regular buffs FelBot should track:

- **Demon Armor / Demon Skin (self)**
- **Sense Demons (self)**
- **Detect Invisibility**
- **Unending Breath**

**Self armor preference** can be Automatic, Demon Armor, or Demon Skin. Automatic prefers Demon Armor when learned, otherwise Demon Skin. Only one armor reminder is shown at a time. Stone options are on the Stones tab.

### Frame modifiers and keyboard binding

The **Frame buff modifier** defaults to **Shift**. Hold it and click a unit frame to apply the next eligible action for that unit. You can choose Shift, Ctrl, Alt, or disable this shortcut.

The **Soulstone frame modifier** defaults to **Ctrl**. A different modifier lets you create or use Soulstone directly, bypassing the regular buff queue. If both modifiers are the same, self Soulstone follows Buff Order Queue; party frames apply their missing regular buffs before Soulstone.

Assign **Activate FelBot (Buff Order Queue)** in the game's **Keybindings → FelBot** section for a keyboard shortcut to the self queue.

### Buff Order Queue

Use the up/down arrows to change the order of self buffs, stone creation/use, Healthstone, and Pots / Items. Displayed self icons follow this order too, except for a separately positioned Healthstone reminder.

The default order is:

1. Demon Armor / Demon Skin
2. Sense Demons
3. Detect Invisibility
4. Unending Breath
5. Soulstone
6. Firestone / Spellstone
7. Healthstone
8. Pots / Items

Each stone's creation and use share one queue position. Pots / Items appears in the editor when enabled custom items are configured; individual items also have their own order. This editor changes the **self** queue, not the order of normal buffs on other players.

### Casting in combat

**Allow casting in combat** enables direct clicks on the prepared spell/item icons. **Combat opacity** controls how faded those icons appear during combat.

**Combat limitations:** Blizzard restrictions prevent FelBot from rebuilding its protected icon list or changing assigned actions during combat. Treat the icons as the actions prepared before combat: ordinary missing-buff icons may remain after casting, and newly missing buffs may not appear until combat ends. Clicking an icon still requires a valid target, range, resources, an available item, and any applicable cooldown.

The **keyboard queue and frame-modifier shortcuts are disabled in combat**. The Healthstone reminder can still become visible as health drops, but it cannot change the shortcut queue during combat. Use its icon directly, with Allow casting in combat enabled and a Healthstone ready in your bags.

<!-- Add a Buffs tab screenshot here. -->

## Stones

Configure Soulstone, Firestone, Spellstone and Healthstone here. Keeping a spare stone in your bags is separate from enabling its use reminder.

### Keep stones in bags

**Enable keep-in-bag creation icons** controls the stock reminders. Choose which stones to keep using the individual **Keep … in bags** checkboxes. Turning the master option off disables those keep controls; it does not disable the separate Use options.

- **Keep enabled:** a creation icon prompts you to replace a missing stone.
- **Keep disabled, Use enabled:** when the relevant buff is missing, the icon creates a stone first. After creation finishes and the icon updates, click again to use it.

Creation icons have a **+** badge and slightly faded artwork. Once the stone is carried, the use icon has full artwork opacity before any range/combat fading. Creation still needs the spell's normal reagents and available bag space.

Soulstone and Healthstone default to keeping one in bags. Firestone and Spellstone default to keeping no spare.

### Use options

- **Use Soulstone** enables Soulstone reminders for the targets chosen on Targets.
- **Use Firestone / Spellstone (self)** enables weapon-stone reminders. Select Firestone or Spellstone in **Weapon stone to apply (self)**; Disabled applies neither.
- **Include stones in self-frame modifier clicks** includes eligible stone actions in the regular self-frame shortcut. This defaults on. Direct icon clicks remain available independently.

### Healthstone reminder

**Use Healthstone reminder (self)** is a low-health visual prompt, disabled by default. When enabled, **Show Healthstone below health (%)** sets the threshold, default **25%**. This controls the use reminder; keeping a spare Healthstone is a separate choice.

Enable **Separate Healthstone layout** to make the reminder larger or place it independently, like a combat/PvP alert. Choose its side on Frame Placement and its size/offsets on Icon Placement. Healthstone indicators appear only on the **main self frame**, including in Test UI.

**For combat use, carry a Healthstone beforehand and enable Allow casting in combat on Buffs.** Click the reminder itself when it appears. Its changing visibility does not enable the keyboard or frame-modifier queue during combat.

<!-- Add a Stones tab screenshot here. -->

## Pots / Items

Add up to **six items** that can be used directly from your bags: potions, scrolls, and other usable items. Drop a bag item into the input box, or paste its item link or numeric ID and click **Add item**.

**Equipment that must be worn to activate is not supported.** Configure Warlock stones on the Stones tab instead.

| Control | What it does |
| --- | --- |
| Show Pots / Items | Shows or hides the group without deleting your list. |
| Row checkbox | Enables or disables that item. |
| Queue | Includes the item in shortcut actions. Uncheck for direct icon clicks only. |
| Party | Opts the item into party/raid frames. Defaults off; enable only for items that can target other players, such as scrolls. |
| Buff | Configures when an active buff should hide the icon. |
| Up/down arrows | Changes the order within the item group. |
| Remove | Deletes the configuration entry, not the item in your bags. |

Icons show stack counts. A missing item stays visible with faded artwork and a **red slash**, but is skipped by the queue. Known cooldowns are skipped too. **Queued items have no health or mana threshold:** a ready potion can be used whenever its turn is reached. Leave Queue off if you want to decide when to use it by clicking its icon.

Party is an explicit opt-in because FelBot cannot reliably determine whether every bag item can target others. Leave it off for self-only potions and items. Opted-in group icons target that frame's player; party modifier clicks reach queued items after missing regular buffs and any shared-modifier Soulstone action.

### Hiding items while their buff is active

The **Buff** button offers:

- **Automatic (match item or effect):** hides the icon while a matching buff is detected on the relevant player.
- **Track a selected buff:** use the item on yourself, then select its active buff if automatic matching misses it.
- **Always show the icon:** disables buff-based hiding for that item.

An icon returns when its tracked buff expires or is removed. Instant healing/mana potions generally have no lasting buff to hide against. Combat icon lists refresh after combat, so a successful use does not necessarily remove an icon immediately while fighting.

<!-- Add a Pots / Items tab screenshot here. -->

## Targets

**Buff targets** enables regular reminders for **Self**, **Party / raid members**, or both. Self-only spells remain self-only.

**Soulstone targets** has separate controls:

- **Self** includes you independently of the role/class filters.
- **Tank / Healer** uses assigned group roles, not classes. It defaults on; players without an assigned role are excluded by this filter.
- With Tank / Healer off, choose eligible classes individually. The class checkboxes are disabled while the role filter is enabled.

This selects who is eligible for a reminder; it does not automatically cast Soulstone. Party/raid item permissions remain per-item on Pots / Items.

<!-- Add a Targets tab screenshot here. -->

## Frame Placement

Choose where each icon row sits relative to its frame. Four independent sections match the groups on Icon Placement:

| Section | Position choices |
| --- | --- |
| Self Placement | Right of frame, Above frame |
| Standard party frames | Right of frame, Above frame |
| Raid style party frames | Right of frame, Above frame, On frame (overlay) |
| Raid Frames | Right of frame, Above frame, On frame (overlay) |

**Above frame** supports left, centre or right alignment and a gap above the frame. **On frame (overlay)** places the icons inside a raid-style frame. Your own entry in a raid frame uses the raid layout, independently of the main self frame.

The **Separate Healthstone** section chooses Above or Right of the main self frame, with alignment for Above. Enable Separate Healthstone layout on Stones first.

Use Test UI to see the placement while editing. When solo, sample frames let you preview standard party, raid-style party and raid layouts. Scroll within the tab to reach the lower sections.

<!-- Add a Frame Placement tab screenshot here. -->

## Icon Placement

Fine-tune **icon size**, **horizontal position** and **vertical position** separately for Self, Standard party frames, Raid style party frames, and Raid Frames. These are the same four groups as Frame Placement. **Icon spacing** is shared across the ordinary rows.

The **Separate Healthstone** section has independent size, horizontal and vertical controls for the main self-frame reminder. Enable it on Stones first.

Out-of-range icons fade to **50% opacity**, with combat fading applied on top. Unavailable or cross-zone targets are treated as out of range when the game supplies that information. Fading is a visual cue; a successful action still depends on the game's target and range checks.

Test UI uses the current layout settings and mock icons that cannot be clicked or modifier-clicked. Adjust the sliders, switch Test UI off, and **Save** when happy. Test mode automatically stops when the settings window closes or combat begins.

<!-- Add an Icon Placement tab screenshot here. -->

## Licence

FelBot's original code, documentation and custom artwork are available under the [MIT licence](LICENSE), copyright © 2026 Zivany Dots. This licence does not grant rights to Blizzard's game artwork, trademarks or other third-party assets. Spell and item icons are supplied by the game client and are not bundled with FelBot.
