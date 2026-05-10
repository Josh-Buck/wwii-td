# Changelog

All notable changes per milestone.

## v0.2.0-M1 — 2026-05-10

Milestone 1 — first full eco-TD playable loop.

- **4 named figures.** Patton (US, anti-armor), Eisenhower (US, slow + heavy single-target — AoE deferred to PLANNED_FEATURES.md), Churchill (UK, ground+air support), Anne Frank (Resistance, wide-range universal spotter — only tower that hits camo).
- **3 enemy types.** Wehrmacht infantry, Panzer III (armored, slower, leaks 2 lives), Stuka Ju-87 (flying, fast — only Eisenhower/Anne Frank can shoot it).
- **8 waves** mixing all three types; wave 4 is an all-Stuka wave that punishes anti-ground-only builds.
- **Hotkey selection (1–4)** with HUD selection label showing active tower + cost.
- **Projectiles** replace M0 instant-hit damage — yellow tracers travel from tower to target.
- **Click placed tower → info panel.** Name + lore, target priority cycle (First / Last / Strong / Close), Sell (75% refund), Close.
- **Tooltip lore on hover** for towers and enemies (foundation for M2 codex).
- **Pause button + P hotkey** with full-screen overlay; works during waves and between.
- **Between-wave shop ("War Room")** starts after wave 2:
  - Open store with 3 War Bond tiers, buy any/all you can afford.
  - War Loan: 100g → 150g in 3 waves.
  - Victory Bond: 250g → 425g in 4 waves.
  - Lend-Lease: 500g → 900g in 5 waves.
  - Held-bond ledger shows maturity countdown each shop visit.
- **PLANNED_FEATURES.md** captures deferred ideas (War Stocks, Eisenhower AoE, shop variants b/c/d, M2 systems) so we don't lose track.
- Live at https://josh-buck.github.io/wwii-td/.

## v0.1.0-M0 — 2026-05-10

Scaffold milestone. Project is browser-playable end-to-end.

- Godot 4.6 project with autoloads (`GameState`, `MetaProgress`, `EventBus`, `AudioMan`, `SaveSystem`).
- Custom Resource subclasses for static data (`TowerStats`, `EnemyStats`, `WaveSet`).
- Systems: `TargetingSystem`, `WaveDirector` (loads waves from JSON).
- Scenes: `Main` → `m0_field` (1 hand-built map with curved path + 5 placement slots), `Tower`, `Enemy`, `HUD`.
- Content: 1 tower (George S. Patton, US), 1 enemy (Wehrmacht infantry), 3 hand-tuned waves.
- HTML5 export configured single-threaded for GitHub Pages compatibility.
- GitHub Actions deploy pipeline (`Godot 4.6 headless export → gh-pages → Pages`).
- Live at https://josh-buck.github.io/wwii-td/.
