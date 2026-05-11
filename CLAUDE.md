# WWII Tower Defense — project context for Claude

Roguelike tower defense built in **Godot 4.6** (single-threaded HTML5 export → GitHub Pages). Towers are named WWII historical figures whose abilities map to what they actually did historically. A codex of real history is a first-class feature, sourced from primary institutions.

- **Live:** https://josh-buck.github.io/wwii-td/
- **Repo:** https://github.com/Josh-Buck/wwii-td
- **Full design:** [`docs/DESIGN.md`](docs/DESIGN.md)
- **Content guardrails (read before touching content):** [`docs/CONTENT.md`](docs/CONTENT.md)

## Non-negotiables

These rules govern every change. Re-read before content work.

1. **Confront history head-on, never selectively.** Codex includes all major perpetrators (Mengele, Eichmann, Heydrich, Himmler, Tojo, Unit 731 leadership, etc.) sourced from USHMM / Yad Vashem / IWM / NARA / trial records. "Never forget" requires naming names.
2. **The line is glamorization, not inclusion.** Each perpetrator's gameplay representation must earn its place historically. Hitler is silhouette/insignia, never charismatic. Mengele *escapes* his boss encounter (he was never captured) — narrative comment on incomplete justice. Eichmann's defeat narratively maps to the 1960 Mossad capture and 1962 Israeli trial.
3. **No camps as playable maps.** Auschwitz/Treblinka/etc. as TD level layouts crosses the line. Referenced as narrative context, never as battle space.
4. **Manhattan Project ≠ free win button.** Unlocks via codex chain only; one-time use; −50% War Effort points + forced narrative interlude on civilian casualties and Oppenheimer's reflection.
5. **Source standard:** USHMM / Yad Vashem / IWM / NARA / Nuremberg & Tokyo & Eichmann trial records / scholarly work. Wikipedia is a starting point, not a source. Each codex entry ends with a `Sources:` line.

## Strategic design pillars

- **Eco-first.** War Bonds delayed payouts. Every round forces "defend now vs invest in income."
- **Synergies via adjacency**, not deep upgrade trees. Same-faction towers buff each other.
- **Light maze.** 2–3 wall slots per map extend the path; pre-baked alt curves, not A*.
- **One global active ability** (Bombing Run, 90s cd) for skill expression.
- **Roguelike + meta-tree.** Random shop offerings between rounds. Persistent unlocks via War Effort points.

## Architecture conventions

- **Static data → custom Resources** (`.tres`). `TowerStats`, `EnemyStats`, `CodexEntry`. Edited in Inspector.
- **Wave schedules → JSON** at `res://data/waves/*.json`. Bake to `.tres` only before web export.
- **Cross-cutting state → autoloads.** `GameState` (gold/lives/wave), `MetaProgress` (persistent unlocks), `EventBus` (signals), `SaveSystem` (`user://` IndexedDB on web), `AudioMan`.
- **Scenes by domain, not file type.** Tower script + scene + variants live together under `scenes/towers/`.
- **Pathing:** `PathFollow2D` on a `Path2D`. Maze-building uses pre-baked alternate curves, not runtime A*.
- **Adjacency:** recompute on place/sell/upgrade only — never every frame. Radius ~96px.
- **Web export gotchas:** single-threaded only (GH Pages doesn't send COOP/COEP), `.nojekyll` at deploy root, `user://` is IndexedDB. Bake JSON waves to `.tres` before web export (PCK is read-only).

## Repo layout

```
autoload/                 GameState, MetaProgress, EventBus, AudioMan, SaveSystem
scripts/resources/        TowerStats, EnemyStats, WaveSet, ShopOffer, CodexEntry
scripts/systems/          TargetingSystem, AdjacencySystem (M2), WaveDirector,
                          WarBonds (M2), BombingRun (M2), ShopRoller (M2)
scenes/main/              Main, MainMenu (M1)
scenes/map/               Map.gd parent + maps/<name>.tscn
scenes/towers/            Tower.tscn parent (one scene; variants are .tres data)
scenes/enemies/           Enemy.tscn parent (same pattern)
scenes/ui/                HUD, ShopUI (M2), CodexUI (M2), MetaTreeUI (M3)
data/towers/              *.tres TowerStats per figure
data/enemies/             *.tres EnemyStats per unit
data/waves/               *.json wave schedules
data/codex/               *.tres CodexEntry per figure / unit / event
docs/                     DESIGN.md, CONTENT.md, FIGURE_TEMPLATE.md
.github/workflows/deploy.yml  Godot 4.6 headless export → gh-pages branch
```

## Milestones

- **M0** ✅ Scaffold: project, autoloads, 1 map, 1 tower (Patton), 1 enemy (Wehrmacht), 3 waves, deployed.
- **M1** ✅ Core mechanics: 4+ figures, 3+ enemies, multiple waves, between-round shop, sell/refund, projectiles, targeting modes, lore.
- **M2** ✅ MVP: 8+ figures, 5+ enemies, first boss (Rommel), adjacency synergies, Bombing Run, codex, second map (Ardennes).
- **M3** ✅ Full v1: 18 towers (14 figures + Maginot Bunker + 3 air units), 16 enemies (incl. 6 named bosses + Hitler finale), Manhattan Project ultimate, full meta-progression (recruit + rank promotion + perks), roguelike field offers with reroll, endless mode with scaling, polished UI.

Beyond original v1 scope: endless mode with difficulty scaling, per-figure rank promotion across runs, stocks market with risk display, Manhattan codex chain unlock, two-map picker.

**Outstanding:** sound effects + music (deferred).

## Adding a new figure

See [`docs/FIGURE_TEMPLATE.md`](docs/FIGURE_TEMPLATE.md) for the full checklist. Short version:

1. Write `data/towers/<id>.tres` (`TowerStats` fields).
2. Write `data/codex/<id>.tres` (`CodexEntry`, sourced).
3. Add the resource to the active map's `available_towers` list.
4. Verify the ability mechanic ties to a real historical event or role.

## Build / deploy

```sh
# Editor
open ~/wwii-td/project.godot

# Local web export
godot --headless --export-release "Web" build/web/index.html
python3 -m http.server 8000 --directory build/web

# Deploy
git push origin main   # GitHub Actions → gh-pages → Pages auto-redeploy
```

## User preferences

- Minimal commit messages, no co-author footer.
- Spread commits over time, don't batch unrelated work.
- No comments unless WHY is non-obvious.
- No emojis in code or output unless explicitly requested.
