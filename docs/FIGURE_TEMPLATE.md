# Adding a Figure

A "figure" is a named historical person used as a tower (Allied) or boss (Axis). This is the checklist for adding one. Read [`CONTENT.md`](CONTENT.md) first if the figure is a perpetrator.

## Decision criteria

Before adding, verify:

1. **Specific historical action** for the ability hook. Anne Frank → camo detection because she hid for 25 months. Eisenhower → AoE because D-Day. Bletchley → wave preview because Enigma. No abstract stat blocks.
2. **Codex sourcing** is feasible. A primary institutional source must exist (USHMM, Yad Vashem, IWM, NARA, scholarly).
3. **Faction tag** for synergy: `us`, `uk`, `ussr`, `resistance`, `axis_germany`, `axis_japan`, `axis_italy`.

## Files to add

### 1. `data/towers/<id>.tres` (Allied tower)

```
[gd_resource type="Resource" script_class="TowerStats" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/tower_stats.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"<id>"                       # e.g. &"eisenhower"
display_name = "<Full historical name>"
faction = &"<us|uk|ussr|resistance>"
color = Color(<r>, <g>, <b>, 1)    # placeholder fill until art lands
cost = <int>                       # 80–250 typical
damage = <float>
fire_rate = <float>                # shots/sec
range_px = <float>                 # 100–250 typical
can_hit = <int flags>              # 1=Ground 2=Air 4=Armor 8=Camo (bitwise OR)
adjacency_buffs = Array[StringName]([&"<faction>"])
adjacency_consumes = Array[StringName]([&"<faction>"])
tooltip_lore = "<1–2 sentence historical hook>"
codex_id = &"<id>"
```

### 2. `data/codex/<id>.tres` (CodexEntry — when codex system lands in M2)

Sectioned: who they were · what they did · what happened to them · sources. ~150–300 words. Sources line is mandatory.

### 3. Register on the active map

Add the tower to the map scene's `available_towers` list (e.g. `scenes/map/maps/m0_field.tscn`). The fallback in `Map.gd` only loads Patton; everything else needs explicit registration.

## Ability design rules

- **Mechanic ties to a real historical event or role.** No abstract stat blocks.
- **Two upgrade branches** (M2+); both viable late-game.
- **Cost reflects power.** Support and utility cheaper than DPS. Eco towers most expensive (delayed payout).
- **Faction synergy tags** make adjacency meaningful — pair with matching `faction` for buffs.

## Content sensitivity

For perpetrators (Axis bosses, etc.), see [`CONTENT.md`](CONTENT.md). The line is *glamorization*, not *inclusion*. Re-read before designing.

## Test checklist

- [ ] `.tres` file loads in Godot Inspector without errors
- [ ] Tower placed in a slot fires at enemies
- [ ] Tooltip lore displays on hover (M1+)
- [ ] Codex entry unlocks on first use (M2+)
- [ ] Adjacency buff visualizes with same-faction neighbor (M2+)
