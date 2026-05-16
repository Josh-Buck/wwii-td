# WWII Tower Defense — Test Plan (Priority-Ranked)

Walk these top-to-bottom. The order is from "if this is broken, the game is unplayable" down to "minor polish edge case." Stop and capture detail any time something fails — especially the **DevTools console output** (F12 → Console) for click-related issues.

---

## P1 — CRITICAL: must work or the game is broken

### P1.1  Click a placed tower → upgrade panel opens
*Largest recurring bug. Verify thoroughly.*

1. Start any run, place any tower.
2. **Left-click the placed tower** (the figure itself, not the sidebar).
3. All three should happen at once:
   - Bottom toast: `Selected <Name> — upgrade panel open`
   - Cyan halo ring around the tower
   - Defender Info Panel appears on the **opposite side of the screen** from the tower (auto-clamped)
4. **DevTools (F12 → Console)** must print on every click:
   ```
   [Tower] click registered: patton
   [HUD] _on_tower_clicked received for: patton
   [HUD] def_info_panel.visible=true pos=... size=...
   ```
5. Buy upgrades (T1 → T2 → T3) — pips appear on top of the tower, become a star at T3.

**If `[Tower] click registered` doesn't appear in console → click isn't reaching the tower (Area2D / mouse_filter regression).**
**If `[Tower] click registered` appears but no `[HUD] ... received` → signal-routing bug.**
**If panel becomes visible but you can't see it → off-screen positioning bug.**

### P1.2  Main menu loads and starts a run
1. App opens to the WWII Tower Defense title.
2. War Effort total, lifetime stats, achievements count all show.
3. Pick a map (Normandy / Ardennes) and a difficulty (Easy / Normal / Hard) — buttons disable for the active selection.
4. Start Run loads the chosen map without errors in console.

### P1.3  Place / sell / target on a tower
1. Pick a tower from the sidebar, click on the map to place. Drop-in pop animation plays.
2. Click placed tower → Sell button refunds correctly (75% of base + every upgrade).
3. Cycle Target: First → Last → Strong → Close.
4. Right-click a sidebar card → opens the info panel without entering placement.

### P1.4  Hero abilities fire (newest big system)
1. Place a Patton, Churchill, Eisenhower, or Pavlichenko.
2. Click it → an **Activate Ability** button appears at the top of the panel.
3. Press it.
   - **Patton CHARGE!** — all placed Pattons should briefly fire much faster.
   - **Churchill Finest Hour** — all UK towers fire faster for 10s.
   - **Eisenhower D-Day Strike** — big AoE burst at the current target, screen shake.
   - **Pavlichenko White Death** — next 5 shots crit (look for big damage numbers).
4. Button shows `<Label> — ready in Xs` while cooldown counts down.
5. Cooldown should *not* tick between waves.

---

## P2 — IMPORTANT: core loop quality

### P2.1  Audio loads correctly
1. Main menu loads → orchestral march music starts within a couple seconds.
2. Click anywhere if there's no audio (web autoplay policy blocks audio until first click).
3. SFX play on tower fire (per-style), enemy hit, enemy kill, wave start.
4. Mute button (🔊 / 🔇) silences both SFX and music.
5. Pause overlay has Master / Music volume sliders that adjust live.

### P2.2  Combat juice
1. Tower fires → recoil animation + muzzle flash flare + projectile with smoke trail.
2. Projectile impacts → spark burst at hit point.
3. Enemy gets hit → flashes white briefly + colored damage number floats up.
4. Enemy dies → death poof with debris specks + `+Ng` gold floater rises.
5. Kill streak → top-left `Combo xN (+Mg bonus)` pops with a scale punch.
6. Health bars only appear on damaged enemies.

### P2.3  Wave + boss intro cards
1. Each wave starts with a `WAVE N` card AND a one-line historical briefing (W1 mentions Atlantic Wall, W5 mentions D-Day, W15 mentions Berlin / end of Reich).
2. Bosses (W8/11/12/13/14/15) get a dedicated `BOSS` card with their name and a subtitle, plus brief screen shake + low growl SFX.

### P2.4  Shop / War Room between waves
1. After wave 1, shop opens on the left.
2. **Minimize** button (`—`) hides it, leaves a `▸ War Room` tab at bottom-left to reopen.
3. War Bonds + Stocks tabs show prices and let you transact.
4. Stocks show `Risk: HIGH/MED/LOW` and drift %.
5. Field Offers panel appears ~40% of shops with up to 3 cards. You can claim ONE; others lock.
6. Reroll button (25g) shuffles offers once per visit.
7. Next Wave button advances.

### P2.5  Bombing Run global ability
1. Press **B** during a wave or click the TopBar button → targeting mode.
2. Cursor shows the blast circle.
3. Click on the map → red telegraph for 1.5s → AoE damage + screen shake.
4. Button shows cooldown; **does not tick between waves** (button reads "during wave").

### P2.6  End screen
1. Die or beat wave 15 → end screen shows.
2. VICTORY (gold) or DEFEAT (red) title scale-punches in.
3. Shows: waves cleared, WEP earned, lifetime WEP, run stats line, **Top defender**, **Final score** with thousands separators, **map star rating**, `NEW STAR EARNED` callout if applicable.
4. Restart returns to main menu.
5. Main menu now shows updated lifetime stats + new star count on map buttons.

---

## P3 — IMPORTANT: retention hooks (newer systems)

### P3.1  Achievements firing
- 26 achievements total. Most should fire in a single full run. Pop-up at top-left for each + WEP awarded.
- Tier examples: kill 1 / 100 / 500 / 2000 / 10000. Combo 10 / 25 / 50. Recruit 1 / 5. Codex 1 / 20 / all.
- Skill challenges: beat Hitler without using Bombing Run, beat Hitler on Hard.

### P3.2  Star ratings on maps
- Victory earns 1-3 stars: 1 for win, +1 for no lives lost, +1 for no Manhattan + no Bombing Run (or Hard win).
- Stars persist; map buttons on main menu show `★★☆ Normandy` etc.
- Star count refreshes when you switch difficulty.

### P3.3  Final score + top-3 leaderboard
- End screen prints final score (`waves * 200 + kills * 5 + lives * 100 + best_combo * 25 × diff_mult`).
- If you make top-3 for that (map, difficulty), a medal tag (🥇/🥈/🥉) shows.

### P3.4  Codex viewer
- Main menu → Codex button opens overlay listing 37 entries with read/unread status + portrait + body + sources.
- Selecting an entry marks it read.
- Reading entries can unlock achievements (codex chain, half-briefed, historian).

### P3.5  Recruit Center
- End screen + main menu both have a Recruit Center button.
- 14 figures listed with current rank pips. Buttons say Recruit (NN WEP) or Promote to Rank N (M WEP).
- Promoting to Rank 2 / 3 fires achievements.

### P3.6  Manhattan Project
- After reading all 4 Manhattan codex entries (auto-unlocked at waves 5/8/11/13), a Manhattan Project button appears in the TopBar.
- Click → confirmation dialog. Confirm → all enemies clear, massive screen shake, -50% WEP penalty flag set.

---

## P4 — IMPORTANT: visuals + atmosphere

### P4.1  Maps look distinct
- Normandy: tiled grass background, brown dirt-road path with dark outline, bocage hedgerows + sandbags + craters + oil barrels + tank treads, drifting brown leaves.
- Ardennes: tiled snow background, lighter dirt path with snow centerline, snow-capped pines + rocks + bushes, falling snowflakes.

### P4.2  Tower base plates render
- Each ground tower sits on the octagonal Kenney CC0 stone base sprite.
- Air units (Spitfire / Mustang / B-17) skip the base and draw a flying shadow ellipse instead.

### P4.3  Synergy preview on placement ghost
- Pick a tower with matching faction tags (Patton, Eisenhower, Audie Murphy, etc. all share `us`).
- Move the ghost near an existing same-faction tower.
- Faint gold line connects them showing the would-be synergy.

### P4.4  Tower target line + idle bob
- Selected tower draws a faint cyan line to its current target (tracks as enemies move).
- All towers gently bob ~1 px when not firing.

---

## P5 — NICE TO HAVE: edge cases + smaller features

### P5.1  Difficulty actually scales
- Easy: enemies feel softer, +5 lives buffer, +80 starting gold, -25% WEP at end.
- Hard: enemies feel tankier, -5 lives, -30 starting gold, +60% WEP at end.

### P5.2  Endless mode
- After wave 15, header reads `ENDLESS +N`. Each subsequent wave has +10% enemy HP. Bosses recur from the boss pool every 5 endless waves.

### P5.3  Stock market
- 4 stocks with different volatility / drift profiles. Prices walk on each wave start. Trend arrows update.

### P5.4  Pause / settings / help
- P pause. Pause overlay shows volume sliders + restart + quit-to-menu.
- ? button on TopBar opens a controls cheat sheet.

### P5.5  Map decorations distribute well
- No decor sprites overlap the path corridor.
- Decor doesn't overlap with tower placement spots (towers can still be placed in their slots).

---

## P6 — DIAGNOSTIC

If anything in P1 fails, paste:
- The contents of the DevTools console (F12 → Console)
- A brief description of which step failed and what happened
- Browser + OS version

The console prints will tell us exactly where the failure is in the chain.

---

## Reporting back

For each failing item, just give me:
- Section number (e.g. P1.1)
- What you saw vs what was expected
- Any console error / print

That's enough for me to diagnose and fix.
