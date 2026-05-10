# Planned Features

Features intentionally deferred. **Add to this list whenever we decide "good idea, but later"** so we don't lose track. Move items to *Done* when shipped.

## Backlog

### Eco / shop

- **War Stocks (alongside War Bonds).** Real-stock-market analogue: not guaranteed; price fluctuates each wave; buy/sell anytime; long-term average is positive but with variance. Adds risk-tolerance dimension on top of bonds (which are guaranteed). Source: Josh request, 2026-05-10. Notes: needs a price-walk model per wave (e.g., random walk with positive drift), sell button on held shares, ticker UI.
- **Shop offer (b): Discount card.** Next tower purchase –30%. Add to shop pool once we have more eco depth.
- **Shop offer (c): Stat boost.** Chosen tower gets +damage or +rate for the run. Precursor to upgrade trees in M2.
- **Shop offer (d): New tower variant unlock for this run only.** Roguelike flavor. Probably ties into the meta-progression unlock pool.

### Combat

- **Eisenhower AoE projectile.** D-Day strike currently fires single-target like other towers. Should explode on impact, damaging all enemies in a small radius. Touches `Projectile.gd`, `TowerStats` (add `aoe_radius` field), Eisenhower's `.tres`.
- **Active "Bombing Run" global ability** (per design plan, M2): 90s cooldown, click 3×3 area, AoE after 1.5s warning.
- **Tower upgrade branches** (Kingdom Rush model, M2): 2 branches per figure, 3 tiers each. Themed (Patton → Armor Hunt vs Blitzkrieg).
- **Adjacency synergies** (M2): same-faction towers in adjacent slots gain mutual buffs. Visualized with subtle linking line.

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
- **Speed toggle** (1×/2×/4×) via `Engine.time_scale`.

## Done

- M0 scaffold + GitHub Pages deploy
- M1: 4 towers (Patton, Eisenhower, Churchill, Anne Frank), 3 enemies (Wehrmacht, Panzer III, Stuka), 8 waves
- M1: hotkey selection (1-4), projectiles, sell/refund, target priority cycling, tooltip lore on hover
