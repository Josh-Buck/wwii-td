# WWII Tower Defense — Test Plan

Run through these in order after each deploy. If anything breaks, capture the **browser DevTools Console** output (F12 → Console) — many click / signal flows print there now.

## A. Main menu (first thing you see)

- [ ] Title "WWII Tower Defense" displays with War Effort total.
- [ ] Lifetime stats line beneath WEP if you've played before (`N runs · N victories · highest wave X · …`).
- [ ] Achievements counter shows `N / 11`.
- [ ] Map picker — click Normandy / Ardennes; selected button greys out, label updates.
- [ ] Recruit Center button opens overlay; all 14 figures listed with rank pips. Close with Back.
- [ ] Start Run launches the chosen map.

## B. Tower upgrade panel (the recurring bug — verify thoroughly)

- [ ] Place any tower (palette card → click map). Verify drop-in pop animation.
- [ ] Click the placed tower (the figure, not the sidebar). All three should happen at once:
  - [ ] Bottom toast: `Selected <Name> — upgrade panel open`
  - [ ] Cyan halo around the tower
  - [ ] Defender Info Panel pops up near the tower (opposite side of screen edge)
- [ ] Panel shows: name `<Figure> #1 (this unit)`, faction, stats, Hits/Strengths/Weaknesses, lore, Upgrades grid (2×3), Target / Sell buttons at the bottom.
- [ ] Buy upgrade T1 in either branch → gold pip appears on top edge of tower.
- [ ] Buy T2 → 2 pips. Buy T3 → pips become a star.
- [ ] Close panel via the × button.
- [ ] Open DevTools (F12) → Console before clicking. On each tower click you should see:
  - `[Tower] click registered: <id>`
  - `[HUD] _on_tower_clicked received for: <id>`
  - `[HUD] def_info_panel.visible=true pos=… size=…`
- [ ] If `[Tower] click registered` appears but no `[HUD] ... received` follows → signal-routing bug.
- [ ] If nothing appears in the console → click isn't reaching the tower (Area2D / mouse_filter issue).

## C. Combat juice (start a wave, watch closely)

- [ ] Tower recoil — visible kickback every shot, scale punch.
- [ ] Projectile smoke trail behind every moving projectile (not laser).
- [ ] Hit flash — enemy briefly turns white when hit.
- [ ] Damage numbers float up from hits.
- [ ] Impact spark — small yellow star burst at every projectile hit.
- [ ] Death poof with debris specks flying outward + inner smoke puff.
- [ ] +Ng gold floater rises from killed enemies.
- [ ] Kill streaks — kill 3+ enemies fast → top-left `Combo x3 (+2g bonus)` appears for ~1.5s.
- [ ] Health bars hidden on full-HP enemies; show only after first damage.

## D. Wave / boss intro cards

- [ ] Every wave start → center band shows `WAVE N` for ~1.2s (or `ENDLESS +N` past wave 15).
- [ ] Wave 8 (Rommel) → BOSS card: name + subtitle `Desert Fox — regenerates on the move`. Brief screen shake.
- [ ] Waves 11–15 each get a unique boss intro card with subtitle.

## E. Shop / War Room

- [ ] Survive past wave 1. Shop drawer slides in on the left.
- [ ] Minimize button (`—` next to "War Room") hides shop; `▸ War Room` tab appears bottom-left to reopen.
- [ ] Field Offers appear ~40% of shops with up to 3 cards. Claim one — the others lock. Reroll (25g) works once per visit.
- [ ] Bonds — buy War Loan (100g → 150g in 3 waves). Shows in "Held Bonds".
- [ ] Stocks — see "Risk: HIGH/MED/LOW" and drift % per stock. Buy 1 / Buy 5 / Sell 1 / Sell all all work.
- [ ] Next Wave closes shop, starts wave.

## F. Bombing Run

- [ ] Press B during a wave (or click TopBar button) → enter targeting mode.
- [ ] Cursor shows blast-radius circle indicator.
- [ ] Click on the map → red telegraph circle holds 1.5s → big AoE damage + screen shake.
- [ ] Button now reads `Bombing Run: 90s`.
- [ ] Between waves the timer does NOT tick — button reads `Bombing Run: Xs (during wave)`.
- [ ] Start next wave → cooldown resumes.

## G. Achievements (most should fire in a single full run)

- [ ] First kill → `First Blood`, +1 WEP.
- [ ] 100 kills in a run → `Hundred Down`, +3 WEP.
- [ ] Kill any boss → `Boss Fall`, +5 WEP.
- [ ] Hit combo 10 → `Streak x10`, +5 WEP.
- [ ] Fully upgrade both branches of a tower → `Fully Decorated`, +5 WEP.
- [ ] Hold 2000+ gold → `Gold Hoarder`, +4 WEP.
- [ ] Recruit a figure → `Roll Call`, +2 WEP.
- [ ] Promote any figure to Rank 2 → `Field Promotion`, +3 WEP.
- [ ] Read all 4 Manhattan entries (clear waves 5/8/11/13) → `Manhattan Read`, +5 WEP.
- [ ] Reach Endless +5 (wave 20) → `Beyond the End`, +10 WEP.
- [ ] Defeat Hitler at wave 15 → `VE Day`, +20 WEP.

## H. Manhattan Project

- [ ] Survive past wave 13 (after reading the 4 codex entries) → button appears in TopBar.
- [ ] Click → confirmation dialog. Confirm → all enemies clear + massive screen shake + toast.
- [ ] End screen shows -50% WEP penalty applied.

## I. End-of-run

- [ ] Die or beat wave 15 → end screen shows Victory/Defeat, waves cleared, WEP earned, stats line, Recruit Center button, perk button, Restart.
- [ ] Restart returns to main menu.
- [ ] Lifetime stats updated on main menu after the run ends.

## J. Maps

- [ ] Pick Ardennes — winding 11-point path, snow palette, snow-capped pines + rocks.
- [ ] Pick Normandy — bocage hedgerows, sandbags, craters, grass tufts.
- [ ] Path drawn with dark outline + faint centerline (not one flat colour).

## K. Known fragile spots / common breakages

- The tower-click bug has been chased multiple times. The DevTools console prints are the ground truth — if they fire, the click is reaching the tower and the issue is elsewhere.
- Achievement pop-ups should queue if multiple fire at once.
- Endless mode after wave 15 — verify HP scaling is felt but not punishing past +3 or so.
- Manhattan button visibility depends on persistent codex_seen — needs all 4 entries in user:// save.

## L. Diagnostic dump

If you need to share state with me, the browser console will show:

```
[Tower] click registered: <id>
[HUD] _on_tower_clicked received for: <id>
[HUD] def_info_panel.visible=<bool> pos=<x>,<y> size=<w>x<h>
```

Paste those lines verbatim — they answer almost any "did the click fire" question without further investigation.
