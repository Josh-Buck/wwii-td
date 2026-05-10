# Changelog

All notable changes per milestone.

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
