# Planned Features

Features intentionally deferred. **Add to this list whenever we decide "good idea, but later"** so we don't lose track. Move items to *Done* when shipped.

## Backlog

### Eco / shop

- **War Stocks (alongside War Bonds).** Real-stock-market analogue: not guaranteed; price fluctuates each wave; buy/sell anytime; long-term average is positive but with variance. Adds risk-tolerance dimension on top of bonds (which are guaranteed). Source: Josh request, 2026-05-10. Notes: needs a price-walk model per wave (e.g., random walk with positive drift), sell button on held shares, ticker UI.
- **Shop offer (b): Discount card.** Next tower purchase –30%. Add to shop pool once we have more eco depth.
- **Shop offer (c): Stat boost.** Chosen tower gets +damage or +rate for the run. Precursor to upgrade trees in M2.
- **Shop offer (d): New tower variant unlock for this run only.** Roguelike flavor. Probably ties into the meta-progression unlock pool.

### Combat

- **Active "Bombing Run" global ability** (per design plan, M2): 90s cooldown, click 3×3 area, AoE after 1.5s warning.
- **Tower upgrade tree** (Kingdom Rush / Bloons hybrid; Josh request 2026-05-10): 2 branches per figure × 3 tiers each, themed per figure. Patton → "Armor Hunt" (anti-tank specialist) vs "Blitzkrieg" (mobile, repositionable). Likely ties into the click-tower info panel as a third tab.
- **Aura / radial-buff towers** (Josh request 2026-05-10): towers whose primary effect is buffing all towers within a radius (e.g., Churchill aura-buffs fire rate to all neighbors, not just same-faction). Distinct from the current adjacency synergy (which only triggers on shared faction tag). Probably driven by new `aura_radius` + `aura_buff_tags` fields on TowerStats.
- **Adjacency synergy line visualization** — golden ring on buffed towers ships, but the linking lines between same-faction neighbors are still TODO.
- **Stuka strafing towers** — currently Stukas just walk the path with `flying` flag. Should periodically strafe a tower in range, damaging it (towers would need HP). Combos with Montgomery's planned defensive aura.

### Content

- **Codex with unlock-on-use** (M2 per plan): unlocks an entry the first time you place / fight that figure or unit. Sourced from primary historical institutions per `docs/CONTENT.md`.
- **More figures** (M2-M3): De Gaulle, Pavlichenko, Audie Murphy, Tuskegee Airmen, Rosie the Riveter, Zhukov, Nimitz, LeMay, Bletchley/Turing, 101st Airborne, Montgomery, FDR.
- **More enemies** (M2): Tiger I, Waffen-SS, U-boat (water maps), Bersaglieri, Banzai charger, Kamikaze, V-2 rocket.
- **Bosses** (M2-M3): Rommel (W8), Yamamoto (W16), Goering (W24), Hitler (W32) for v1; Eichmann / Mengele / Heydrich / Himmler / Tojo as v1+ expansion (per `docs/CONTENT.md`).
- **Manhattan Project unlockable ultimate** (v1+): codex-chain gated; one-time-use; –50% War Effort points + forced narrative interlude. See `docs/CONTENT.md`.

### Polish

- **Custom HTML loading screen** for the web export (replaces Godot default).
- **Touch-friendly controls** (mobile browser playtest).
- **Sound effects + music** — period-appropriate per design plan (big-band swing, marches) over modern cinematic.
- **Range preview when picking a tower** — hover a slot or palette button while a tower is selected to see its placement range, not just after it's down.
- **Detailed defender menu** (Josh request 2026-05-10) — instead of the compact palette buttons, a full menu showing each tower's strengths, weaknesses, ability description, current upgrade tree (when implemented), and what enemies it counters. Click a palette button → expanded info panel. Pairs with the upgrade-tree feature.

### Maps & placement (deferred — Josh request 2026-05-10)

- **More complex paths** — multi-branch, looping, longer maps with more chokepoints. m0_field is intentionally simple as the tutorial map; M3 should add at least one map (e.g. *Ardennes*) with a longer / forking path.
- **Free placement** instead of fixed slots — let the player place towers anywhere not on the path itself, with terrain-based constraints. Significant rework to `PlacementSlot` and `Map.gd`. Likely paired with **per-tower footprint** so heavy towers (Eisenhower) take up more space than light ones (Anne Frank).
- **Variable tower size / footprint** — towers occupy different physical extents on the map; affects placement and adjacency radius computation.

## Done

- M0 scaffold + GitHub Pages deploy
- M1: 4 towers, 3 enemies, 8 waves, hotkey selection, projectiles, sell/refund, target priority, tooltip lore
- M1: pause, between-wave shop with 3-tier War Bonds
- M2 systems: adjacency synergies, aura towers (Churchill), Eisenhower AoE, codex (27 entries), 36 themed tower upgrades, upgrade specials (pierce/instakill/multi-target), projectile variety (bullet/shell/laser, color-tinted), slow + knockback effects, War Stocks (4 sectors), free placement, button-driven wave start, click-to-pin range, defender sidebar with collapsible cards + info panel, shop drawer that leaves board visible, synergy lines, wave preview from Bletchley
- M2 content: 14 figures + 13 enemies (5 v1+ bosses with themed mechanics — Eichmann logistics, Heydrich speed, Mengele escape, Himmler bodyguards, Tojo air support)
- M2 v1+ bosses on waves 11-15; Tiger I / Waffen-SS / Banzai / Bersaglieri sprinkled across the wave list
