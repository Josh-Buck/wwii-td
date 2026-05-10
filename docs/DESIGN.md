# WWII Tower Defense — Project Plan

## Context

Build a browser-playable tower defense game and host it on Josh's `joshbuck` GitHub via GitHub Pages. Goals:

- **Simple to learn but with real strategic depth** — Bloons-inspired but skewing toward eco/risk decisions over pure tower stacking.
- **WWII theme using specific named historical figures** (not ethnic groups) on both sides; each ability tied to something the figure actually did. Doubles as a light "teach some history" angle.
- **Roguelike progression with meta-unlocks** — each run feels fresh; long-term hook beyond a single map.
- **Substantive first project, not a throwaway demo.** Iterative milestones so we can test and adjust as we go (per Josh's "test every once in a while" preference).

## Decisions locked

| Decision | Choice | Why |
|---|---|---|
| Engine | **Godot 4 (4.3+)** | First-class 2D pipeline, lightest HTML5 export (~30MB), GDScript reads close to Python, scene/node system maps directly to TD architecture. Ceiling for 2D is identical to Unity at far lower complexity cost. |
| Hosting | **GitHub Pages** (single-threaded HTML5 export) | Fits the `joshbuck.github.io` goal; free; itch.io as backup if multithreading ever needed. |
| Theme | **WWII named historical figures** — Allies defending, Axis attacking | Specific figures with concrete ability hooks; sidesteps stereotype risk of ethnic-group factions; doubles as history education. |
| Strategic core | **Eco-first** (War Bonds), with adjacency synergies + light maze (wall slots) | Highest skill ceiling per genre research; combines top three user preferences. |
| Progression | **Roguelike runs + meta-tree + endless waves** | Strong replay-to-content ratio for a solo dev. |
| Enemy treatment | **All named historical units & figures** | Maximum flavor; matches user preference. |
| Educational layer | **Tooltip lore + unlockable codex** | Light passive teaching + collection meta-loop. |
| v1 scope | **Full v1 (~2 months)**, iterative milestones | Substantive but contained; iterative milestones de-risk. |

## Iterative build ladder

Each milestone produces a *playable artifact deployed to GitHub Pages* so we can test and adjust.

### Milestone 0 — Scaffold (Week 1)
**Deliverable:** Godot project deployed to GitHub Pages. One map, one tower, one enemy type, gold counter, win after 3 waves.

- Godot 4 project initialized; HTML5 export pipeline working
- GitHub repo created; deploy workflow (GitHub Actions running headless Godot export)
- Core scenes scaffolded: `Main`, `Map`, `Tower`, `Enemy`, `HUD`
- PathFollow2D-based enemy movement; slot-based tower placement
- One placeholder tower, one placeholder enemy
- 3 hardcoded waves
- Gold awarded on kill, spent on placement

**Success:** Josh + a friend each play a 5-minute round in their browsers.

### Milestone 1 — Core mechanics (Week 2–3)
**Deliverable:** 4 named figures with distinct abilities, 3 enemy types, 8 varied waves, between-round shop with eco choices, sell/refund.

- Tower archetypes: single-target (Patton), AoE artillery (Eisenhower), support buff (Churchill), utility (Anne Frank — camo detection)
- Enemies: Wehrmacht infantry (basic), Panzer III (armored), Stuka Ju-87 (flying)
- War Bonds eco mechanic
- Targeting policies (first/last/strong/close) selectable per tower
- Sell/refund at 75%
- Tooltip lore on hover for all units

**Success:** Replayable 10–15 min sessions with real strategic decisions.

### Milestone 2 — MVP (Week 4–5)
**Deliverable:** 8 figures, 5 enemies, first named boss, adjacency synergies, global Bombing Run, codex skeleton, second map.

- +4 figures: Montgomery (defensive aura), FDR (eco passive), Bletchley/Turing (wave preview), 101st Airborne (path-blocking spawn)
- +2 enemies: Tiger I, V-2 rocket
- First boss: Rommel (Wave 8) — fast armored, regenerates while moving
- Adjacency synergy: same-faction towers in adjacent slots gain fire-rate buff
- Global ability: Bombing Run on 90s cooldown
- Codex UI: starts empty, entries unlock on first use
- Second map (different path layout)

**Success:** Feels like a real TD, not a demo. Playtest with a few friends.

### Milestone 3 — Full v1 (Week 6–8)
**Deliverable:** 10–12 figures, 8 enemy types, 4 bosses, full meta-progression tree, roguelike shop, polished UI.

- +4 figures (co-designed during build)
- Full enemy roster: 8 types
- +3 bosses: Yamamoto (aerial swarms), Goering (Stuka rain + tower-line bombing), Hitler (final, multi-phase)
- Meta-progression tree: spend "war effort" points to unlock starting figures, map perks, eco bonuses (~15–20 nodes)
- Roguelike: between-round shop offers 3 random options (recruit / upgrade-branch / eco)
- Codex fully populated
- UI polish, sound effects, period-appropriate music
- v1.0.0 tag, README, screenshots

**Success:** Shareable on Reddit/HN/itch.io as a real game.

## Strategic systems design

### Economy (the primary skill ceiling)
- **Gold:** earned per kill, scales with enemy difficulty.
- **War Bonds:** spend gold for delayed payout (e.g., 100g → 150g in 3 rounds; higher tiers 500g → 800g in 5 rounds).
- Every round forces a "defend now vs invest in income" choice. This is the BTD6-banana-farm equivalent.
- Tuning target: no-eco run survives ~15 waves; eco-heavy run reaches wave 30+.

### Tower upgrades
- 2 branches per figure (Kingdom Rush style — *not* BTD6's 3 branches; keeps complexity tractable for v1).
- 3 tiers per branch.
- Branches are themed: e.g., Patton → "Armor Hunt" (anti-tank specialist) or "Blitzkrieg" (mobile, repositionable).

### Adjacency synergies
- Towers placed in adjacent slots that share a faction (US / UK / USSR / French Resistance) gain mutual buffs.
- Visual: faint colored line between linked towers.
- Example: Churchill + Montgomery (UK) → +15% fire rate to both.

### Light maze
- 2–3 "wall slots" per map can hold a barricade extending the path by one tile.
- Cheap (50g), low HP, destructible by enemies.
- Adds spatial decisions without a full pathfinding rewrite (PathFollow2D handles fixed paths cleanly; pre-baked alternate paths swap when walls placed).

### Global ability — "Bombing Run"
- 90s cooldown. Click 3×3 area; AoE damage after 1.5s warning.
- Adds active-play moments without adding heroes to v1.

### Roguelike shop (between rounds, after wave 2)
- 3 random offerings per visit:
  - Recruit a new figure (random from available pool)
  - Upgrade an existing figure one tier (random branch)
  - Invest in eco (favorable War Bond, +1 starting gold next run, etc.)
- Refresh costs 25g; one refresh per visit.

### Meta-progression
- **War Effort points** earned per run from waves cleared.
- Spent in a small tech tree:
  - Unlock starting figures (start with Patton OR FDR OR Churchill)
  - Map perks (+1 wall slot, +50 starting gold, +10% all gold)
  - Codex completion bonuses
- ~15–20 nodes for v1.

## Figure roster (seed — full roster co-designed during build)

Format: **Name** — *archetype* — ability — historical hook

### Allied — single-target / armor-pierce
- **George S. Patton** — *single-target tank-buster* — High damage to armored, +50% vs Panzers. Branch A (*Armor Hunt*): max anti-tank, weak vs infantry. Branch B (*Blitzkrieg*): repositionable mid-round once. — *Commanded the Third Army's Normandy breakout; aggressive armor doctrine reshaped Allied tank tactics.*
- **Vasily Zaitsev** — *long-range sniper* — Single-target, very high damage, very slow rate, sees camo. Branch A: one-shot high-value targets. Branch B: counter-sniper (silences enemy boss abilities). — *Soviet sniper at Stalingrad; 225 confirmed kills; basis for "Enemy at the Gates."*

### Allied — blocker / hold-the-line
- **101st Airborne (Bastogne)** — *spawns soldier squad* — Spawns 3 paratroopers in a tile that physically block the path. Branch A: more soldiers, less damage. Branch B: bazooka squad (anti-armor). — *Surrounded at Bastogne in the Battle of the Bulge; commander McAuliffe replied "NUTS!" to the German surrender demand.*
- **Bernard Montgomery** — *defensive aura* — Buffs HP/armor of nearby units. Branch A: damage reduction. Branch B: heal pulse every 10s. — *Methodical British general; decisive at El Alamein.*

### Allied — AoE / artillery
- **Dwight D. Eisenhower** — *one-per-run AoE ult* — Massive D-Day-style strike usable once per run. Branch A: larger radius. Branch B: smaller radius + DoT. — *Supreme Commander Allied Expeditionary Force; planned Operation Overlord (D-Day, 6 June 1944).*
- **Jimmy Doolittle** — *cooldown bomber strike* — Long cooldown line strike. Branch A: incendiary (DoT). Branch B: precision (single hard target). — *Led the 1942 Tokyo Raid, a strategic morale strike from carriers.*

### Allied — support / utility / eco
- **Winston Churchill** — *fire-rate buff aura* — Nearby towers +20% fire rate. Branch A: stronger buff in smaller radius. Branch B: also boosts gold-per-kill. — *PM during the Battle of Britain; speeches like "We shall fight on the beaches" credited with sustaining UK morale.*
- **Franklin D. Roosevelt** — *eco passive* — +1 gold/sec while alive. Branch A: gold per kill in radius. Branch B: war bond yield boost. — *32nd US President; New Deal restructured the US economy; Lend-Lease shipped war materiel to UK/USSR.*
- **Bletchley Park (Alan Turing)** — *intel/wave preview* — Reveals next 3 waves; debuffs named bosses (-25% HP). Branch A: also debuffs all enemies in radius. Branch B: extends preview to 5 waves. — *Britain's codebreaking center; cracked Enigma, estimated to have shortened the war 2–4 years.*
- **Anne Frank** — *camo/hidden detection* — Reveals stealth/camouflaged enemies in a wide radius; small fire rate, high range. — *Jewish teenager who hid with her family in an Amsterdam attic for 25 months before betrayal in 1944; her diary is one of the most-read accounts of the Holocaust.*

### Future / co-design pool (M2–M3 and beyond)
Charles De Gaulle (Free French partisans), Lyudmila Pavlichenko (sniper variant — 309 confirmed kills), Audie Murphy, Tuskegee Airmen, Rosie the Riveter (industry/eco), Georgy Zhukov, Chester Nimitz, Curtis LeMay, Bernard Fisher.

## Enemy & boss roster (seed)

### Enemy unit types (named)
- **Wehrmacht infantry** — basic mook, low HP/damage
- **Waffen-SS** — elite armored infantry, faster
- **Panzer III** — light tank, armored
- **Tiger I** — heavy tank, very armored, slow
- **Stuka Ju-87** — flying, fast, strafes towers
- **U-boat** — water-only enemy on coastal maps
- **Italian Bersaglieri** — fast scout infantry
- **Banzai charger** — high-damage rusher, low HP, sprints when low
- **Kamikaze** — aerial suicide unit; takes a tower with it on hit
- **V-2 rocket** — long-range projectile, must be intercepted in flight

### Named bosses (v1)
- **Erwin Rommel** (W8) — fast armored, regenerates while moving (Desert Fox).
- **Isoroku Yamamoto** (W16) — aerial command boss; spawns Stuka/Kamikaze swarms.
- **Hermann Goering** (W24) — Luftwaffe boss; calls a bombing run damaging all towers in a line (player must reposition).
- **Adolf Hitler** (W32, final) — multi-phase: spawns reinforcements, applies aura debuff. Treated visually as silhouette/insignia, not caricature; no glamorization.

### v1+ expansion bosses
Designed per the *Content sensitivity guardrails* section. Each pairs a historically grounded mechanic with a codex narrative arc.

- **Adolf Eichmann** — logistics/transport-themed boss; defeat maps to 1960 Mossad capture & 1962 Israeli trial.
- **Josef Mengele** — escape-themed boss; *escapes* if not pressured fast enough — narrative comment on incomplete justice (he died free in Brazil in 1979).
- **Reinhard Heydrich** — Operation Anthropoid mechanic; defeat maps to the 1942 assassination by Czech/Slovak resistance.
- **Heinrich Himmler** — SS apparatus boss.
- **Hideki Tojo** — Pacific theater command boss; Tokyo Trial codex thread.

## Content sensitivity guardrails

**Principle: confront history head-on, never selectively.** "Never forget" requires naming perpetrators in full historical detail, not airbrushing them. The line is *glamorization*, not *inclusion*. Codex entries are the primary site of historical engagement; gameplay representation requires deliberate, non-glamorizing design.

### Codex — always include, factually, in full
- **All major perpetrators** — Hitler, Himmler, Heydrich, Goering, Goebbels, Eichmann, Mengele, Tojo, Yamamoto, Mussolini, Unit 731 leadership. Sourced from USHMM, Yad Vashem, IWM, official war-crimes records. Entries are explicit about the war crimes, the perpetrators' fates (capture, trial, suicide, escape, death), and historical context.
- **The Holocaust** — referenced honestly. Anne Frank's entry links to the Frank family's fate, the broader extermination network, and camp liberations.
- **Atomic bombs** — Hiroshima, Nagasaki, the Manhattan Project, Oppenheimer, civilian casualties (~200,000), the moral debate among the scientists, the dawn of the nuclear age.
- **Unit 731** — Japanese biological and chemical experimentation; included in full historical accuracy. Often elided from popular WWII narratives; this game does not elide it.
- **Camps and liberations** — referenced where they connect to the historical thread. Liberation events appear as wave-introduction historical beats.

### Gameplay representation — designed with intent
Each perpetrator gets gameplay representation when the mechanic earns its place historically:

- **Adolf Hitler** (W32 final boss, v1) — silhouette/insignia, never charismatic framing. Defeating him represents Allied victory, full stop.
- **Adolf Eichmann** (v1+ boss) — mechanic themed around logistics and transport (his actual role as architect of deportation). His defeat narratively maps to the 1960 Mossad capture in Argentina and the 1962 Israeli trial. Codex entry explicit about the trial and execution.
- **Josef Mengele** (v1+ boss, deliberately atypical) — *does not die*: escapes the encounter if the player doesn't reach a kill threshold in time. Mirrors the historical fact that he was never captured and lived freely in South America until 1979. A deliberate narrative comment on the incompleteness of justice. Codex entry on the Auschwitz "experiments" is unflinching and sourced from USHMM survivor testimony.
- **Reinhard Heydrich** (v1+ boss) — mechanic references the Czech/Slovak resistance (Operation Anthropoid). Defeating him maps to his 1942 assassination; the codex covers the Lidice massacre that followed.
- **Heinrich Himmler** (v1+ boss) — SS apparatus boss; codex covers his suicide post-capture.
- **Hideki Tojo** (v1+ boss) — Pacific theater command; codex includes the Tokyo Trial.
- **Manhattan Project / atomic bomb** (v1+ unlockable Allied ultimate, *not* a free win button):
  - Unlocks only after completing the Manhattan Project codex chain (Oppenheimer, Trinity, Hiroshima, Nagasaki entries)
  - One-time use per run
  - Massive battlefield clear, but applies a narrative cost: −50% War Effort points earned this run, plus a forced codex interlude on civilian casualties and Oppenheimer's "I am become death" reflection
  - Players who use it engage with the moral weight; players who don't are not penalized — full reward is reachable through conventional play

### Excluded from gameplay (still in codex)
- **The camps as playable maps.** Auschwitz, Treblinka, etc. as TD level layouts crosses into territory where gameplay cannot honor the subject. Referenced as narrative context, never as battle space.
- **Mechanics that reward engaging with experimentation, selection, or extermination as game systems.** "Mengele's experiments" as a stat-block ability would gamify the act itself. The escape-themed mechanic above engages with the *aftermath of justice* instead — historically meaningful and confronts the failure to capture him.

### Source standard
Codex entries are short-form research-grade, sourced from primary historical institutions: USHMM, Yad Vashem, Imperial War Museum, NARA, Nuremberg / Tokyo / Eichmann trial records, scholarly work. Wikipedia is a starting point, not a source. Each entry ends with a `Sources:` line.

## Educational content style

- **Tooltip lore (always on, on hover):** 1–2 sentences, factual. *"Anne Frank — Jewish teenager whose diary became one of the most-read accounts of the Holocaust. Hid with her family in an Amsterdam attic for 25 months before betrayal in 1944."*
- **Unlockable codex (collection meta-loop):** ~150–300 words per figure/unit, unlocks on first use. Sectioned: *Who they were · What they did · What happened to them · Sources.*
- **Codex completion bonus:** small starting-gold or perk unlock for completing each faction's codex (incentivizes seeing all the history).

## Art direction

**Recommended:** Stylized public-domain photo cutouts for figures (Wikipedia / NARA / IWM have rich PD WWII photo archives). Apply a uniform painterly filter so they cohere. Pair with simple silhouette enemy units and clean iconographic UI.

**Why:** The figures *should* be recognizable — half the appeal is "Patton with a tank-busting ability." Hand-drawn art is expensive, pixel art weakens the "real history" feel, AI portraits are ethically/legally fraught for a serious-theme game. Photo cutouts get the strongest art at the lowest cost and reinforce the educational tone.

**Alternatives:** Pixel art (indie aesthetic, weakens recognition); flat illustration (clean but expensive in solo time).

## Godot 4 architecture

### Folder structure
Group by domain (towers, enemies, waves), not by file type — each tower's scene/script/resource lives near each other.

```
res://
  project.godot, export_presets.cfg
  autoload/  GameState.gd, MetaProgress.gd, EventBus.gd, AudioMan.gd, SaveSystem.gd
  scenes/
    main/   Main.tscn, MainMenu.tscn, RunSummary.tscn
    map/    Map.tscn (TileMap + Path2D + slot Area2Ds), maps/{ardennes,normandy}.tscn
    towers/ Tower.tscn (parent), variants/{Patton,Eisenhower,...}.tscn
    enemies/ Enemy.tscn (parent), variants/...
    projectiles/, ui/, fx/
  data/
    towers/ *.tres (TowerStats), enemies/ *.tres, waves/ *.json + baked *.tres,
    codex/ *.tres, meta/meta_tree.tres
  scripts/
    resources/ tower_stats.gd, enemy_stats.gd, wave_set.gd, shop_offer.gd, codex_entry.gd
    systems/   AdjacencySystem.gd, TargetingSystem.gd, BombingRun.gd,
               WarBonds.gd, WaveDirector.gd, ShopRoller.gd
  art/, audio/, shaders/
```

### Data: custom Resources for static, JSON for waves
Use **custom `Resource` subclasses** (`.tres`) for tower/enemy/codex stats. Edited in the Inspector (no JSON typos), type-checked at load, baked into the PCK at export. **JSON only for wave schedules** — they change every playtest and need hot-reload during balancing (a debug autoload watches mtime each second and re-parses).

```gdscript
class_name TowerStats extends Resource
@export var display_name: String
@export var portrait: Texture2D
@export var cost: int = 100
@export var damage: float = 10.0
@export var fire_rate: float = 1.0
@export var range_px: float = 160.0
@export var projectile: PackedScene
@export_flags("ground", "air", "armor", "camo") var can_hit: int = 1
@export var adjacency_buffs: Array[StringName] = []
@export var adjacency_consumes: Array[StringName] = []
@export var lore_codex_id: StringName
```

```json
[
  {"wave": 1, "spawns": [{"enemy": "wehrmacht_infantry", "count": 12, "interval": 0.6}]},
  {"wave": 8, "boss": "rommel"}
]
```

**Web caveat:** `res://` is read-only inside the PCK. Hot-reload is editor/desktop only — bake JSON → `.tres` via a one-line script before web export.

### Save system (`user://`)
Godot maps `user://` to **IndexedDB** in the browser — persists across page reloads on same origin (GitHub Pages works). Save only meta-progression (small dict). Save eagerly after each unlock; web tabs can close before async IDB writes flush.

### Pathing — fixed paths + pre-baked alternates
One `Path2D` per map; enemies are `PathFollow2D` children advancing `progress_ratio`. For 2–3 wall slots, **don't switch to A***. Author 2–4 named alternative `Path2D` curves (`PathOpenA`, `PathClosedA_OpenB`); the `Map` script reparents enemies to the active path when walls toggle. If maze-building grows post-v1, migrate to `AStarGrid2D` over the TileMap.

### Targeting (per-instance priority)
Tower's `RangeArea` (Area2D) maintains `targets_in_range`. Each fire tick, `TargetingSystem.pick(targets, priority)` returns one — priority is **per-instance** state, not on the shared TowerStats:

```gdscript
static func pick(targets: Array, mode: StringName) -> Node:
    if targets.is_empty(): return null
    match mode:
        &"first":  return targets.reduce(func(a,b): return b if b.progress > a.progress else a)
        &"last":   return targets.reduce(func(a,b): return b if b.progress < a.progress else a)
        &"strong": return targets.reduce(func(a,b): return b if b.hp > a.hp else a)
        &"close":  return targets.reduce(func(a,b): return b if b.dist < a.dist else a)
        &"camo":   return targets.filter(func(e): return e.is_camo).front()
```

### Adjacency synergies
On place / sell / upgrade only (never every frame), scan towers within `RADIUS = 96px` (~1.5 slot widths):

```gdscript
const RADIUS := 96.0
func recompute(t: Tower) -> void:
    t.active_buffs.clear()
    for other in get_tree().get_nodes_in_group("towers"):
        if other == t: continue
        if t.global_position.distance_to(other.global_position) > RADIUS: continue
        for tag in other.stats.adjacency_buffs:
            if tag in t.stats.adjacency_consumes:
                t.active_buffs[tag] = other
    t.apply_buffs()
```

Visual: each buffed tower spawns a subtle pulsing ring; selecting a tower draws `Line2D`s to its synergy partners.

### Web export to GitHub Pages

**Mandatory:** export with **Threads disabled** (single-threaded HTML5). GitHub Pages does not send the COOP/COEP headers required for `SharedArrayBuffer` — threaded builds fail to start with a cross-origin isolation error.

**Size budget <30MB:**
- Don't preload every variant at boot — use `ResourceLoader.load_threaded_request()` from the map intro
- Audio: `.ogg` Vorbis 96 kbps mono SFX, 128 kbps stereo music; cap to 2 looped tracks for v1
- 2D art: PNG `Lossless` + `Filter=Off`
- `.nojekyll` file at deployment root or Pages strips files starting with `_`

### Web gotchas (flagged)

1. **SharedArrayBuffer / threading** disabled by default on Pages → single-threaded export only.
2. **`.nojekyll`** must exist at deployment root.
3. **`user://` is IndexedDB** — cleared if user clears site data; never store run-critical state mid-run.
4. **Audio autoplay**: browsers block audio until first user gesture — start music on first click, not in MainMenu's `_ready()`.
5. **`OS.shell_open` and most `OS.*` calls** are no-ops on web. Use `JavaScriptBridge.eval()` if you need to open windows.
6. **`get_modified_time()`** for JSON hot-reload doesn't work on web (PCK read-only). Dev-only.
7. **Stretch Mode** `canvas_items` + `expand`, base `1280×720`. iPhone Safari clips the address bar dynamically — test on a real phone.
8. **Initial load** is ~12–18MB just for engine WASM. Edit the export shell template for a custom HTML loading screen.
9. **Web heap** defaults to 64MB; raise to 256MB in export preset's "Initial Memory" if you spawn 200+ enemies.
10. **GDExtension is web-incompatible** unless compiled to WASM yourself. Stick to pure GDScript for v1.

### Per-milestone scene/script checklist

| Week | Phase | Must exist |
|------|-------|-----------|
| 1 | Scaffold | `Main.tscn`, `MainMenu.tscn`, 5 autoload stubs, `Map.tscn` with one `Path2D` + 4 slots, `Enemy.tscn` walking the path, web export working locally |
| 3 | Mechanics | `Tower.tscn` + 3 variants firing projectiles, `RangeArea` targeting (first/last/close), `HUD.tscn` (gold/lives), `WaveDirector.gd` reading JSON, kill rewards, slot-click placement |
| 5 | MVP | `ShopUI.tscn` 3-card reroll, `WarBonds.gd` delayed payout, `AdjacencySystem.gd` (one synergy pair), `BombingRun.gd` global ability, `SaveSystem.gd` on web, 1 map + 6 towers + 5 enemies + 1 boss, win/lose screens |
| 8 | Full v1 | 2 maps, 10–12 towers with synergy tags, 8 enemies + 3–4 bosses, `MetaTreeUI.tscn`, `CodexUI.tscn` + hover tooltips, endless mode toggle, touch controls, JSON waves baked to `.tres`, deployed to `gh-pages` with `.nojekyll`, <30MB |

## Critical files (initial scaffold)

```
res://scenes/main/Main.tscn
res://scenes/map/Map.tscn
res://scenes/towers/Tower.tscn               # parent; @export stats: TowerStats
res://scenes/enemies/Enemy.tscn              # parent (PathFollow2D)
res://autoload/GameState.gd                  # gold, wave, run state
res://autoload/MetaProgress.gd               # persistent unlocks
res://autoload/EventBus.gd                   # global signals
res://autoload/SaveSystem.gd                 # user:// → IndexedDB on web
res://scripts/resources/tower_stats.gd       # custom Resource pattern
res://scripts/resources/wave_set.gd
res://scripts/systems/AdjacencySystem.gd     # synergy compute (place/sell/upgrade only)
res://scripts/systems/TargetingSystem.gd
res://scripts/systems/WaveDirector.gd        # JSON in dev, .tres in export
res://scripts/systems/WarBonds.gd            # eco delayed-payout
res://scripts/systems/BombingRun.gd          # global active ability
res://scripts/systems/ShopRoller.gd          # 3-card random offerings
res://data/towers/patton.tres
res://data/enemies/wehrmacht_infantry.tres
res://data/waves/map1.json                   # baked to .tres before web export
.github/workflows/deploy.yml                  # Godot headless export → gh-pages
```

## Verification

### Per-milestone testing
- **M0:** Open `https://joshbuck.github.io/<repo>/` in Chrome/Firefox/Safari. Place tower, kill enemies, win 3 waves.
- **M1:** Full ~15-min session. Verify: each tower's ability, eco shop offerings, sell/refund.
- **M2:** Adjacency synergy visualizes; Bombing Run cooldown displays; codex entry unlocks on first use.
- **M3:** Wave 1→32, beat Hitler. Meta-tree persists across runs (close browser, reopen, points retained).

### Local web export test
```bash
# Inside Godot editor: Project → Export → HTML5 → Export Project to build/web/
python3 -m http.server 8000 --directory build/web
# Open http://localhost:8000
```

### Cross-browser smoke
Chrome desktop, Firefox desktop, Safari iOS, Chrome Android.

### Deploy to GitHub Pages
GitHub Action runs Godot 4 headless export on push to `main`, commits result to `gh-pages` branch.

## Open questions (co-design during build)

- **Working title.** Placeholder "WWII Tower Defense." Riff candidates: *Lend-Lease*, *The Long War*, *Allies*, *Theatre of War*.
- **Repo name** on `joshbuck` — pick once title is set.
- **Other eras post-v1** (Cold War, Roman vs Visigoth, Napoleonic) — sequencing.
- **Music/sound** — period-appropriate (big-band swing, marches) vs modern cinematic.
- **Full figure roster beyond the 10 in v1** — collaborative session per milestone.
- **v1+ expansion boss design** — per-mechanic detail and codex sourcing for Eichmann, Mengele, Heydrich, Himmler, Tojo (see Content sensitivity guardrails).
- **Manhattan Project unlock chain** — exact codex prerequisites and the specific narrative interlude text.
