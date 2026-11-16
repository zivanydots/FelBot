# Changelog

## 0.5.15 - 2026-11-16

Changes since the previous public release, 0.5.10:

- Added the square green/purple FB graffiti icon for the in-game addon list and a 400 x 400 PNG for CurseForge.
- Reorganised Buffs into Buff reminders, Frame click modifiers, Buff application order, Keyboard shortcut and Combat sections. Keyboard shortcut and Combat share a two-column row.
- Armor preference now sits below the armor checkbox and is disabled when that reminder is off, while retaining the selected armor family.
- Added current-key display and Set binding / Clear bindings controls on Buffs. Changes apply with Save, preserve alternate bindings, support discard, and reject keys assigned to other actions. Capture stops on Escape, tab/window close or combat.
- Reorganised Stones into bag-stock reminders, stone-use reminders, frame shortcuts and a compact Healthstone section. The weapon-stone dropdown follows its Use checkbox and offers only Firestone and Spellstone. New/reset settings default weapon-stone use off and require a choice; existing valid selections are retained.
- Removed the arbitrary six-item limit. Editor rows and protected icon pools grow outside combat as needed; large item lists retain correct queue ordering, party targeting and Test UI behaviour.
- Frame Placement hides irrelevant alignment/gap controls and collapses their space. Raid-style party and raid overlays support left, centre and right alignment in live and Test UI.
- Standardised thin green heading underlines and kept them visible at fractional scales. Added text gutters and adjusted columns to prevent right-edge clipping. Moved range-opacity guidance beside Icon spacing.
- `/felbot` now checks the player's class before opening settings or executing subcommands. Non-Warlocks receive: "Access denied. For warlocks only. Use Buff Rag instead."
- Updated the user guide and screenshots. Combat restrictions are unchanged: queue shortcuts remain out of combat; direct prepared icons use the combat-click option. Range and combat fading continue to multiply.

Validation: the full mocked regression suite passes, including 24-item queues, expanded icon pools, binding conflicts/save/discard, setting migration, class checks, conditional layouts and combat/range opacity. In-game testing and feedback remain important.

## 0.5.10

- Default Buff Order Queue ends with Healthstone, then Pots / Items; existing saved orders are preserved.
- Added four independent layout categories: self, standard party, raid-style party and raid frames, with Right, Above and raid Overlay placement options.
- Kept Healthstone creation/use indicators on the main self frame, including Test UI.
- Added a raid-frame preview when real raid frames are unavailable.
- Distributed the MIT licence and third-party asset notices with the addon.
