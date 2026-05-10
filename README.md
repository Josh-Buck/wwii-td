# WWII Tower Defense

Roguelike tower defense built in Godot 4 and exported to the browser. Towers are named WWII historical figures whose abilities map to what they actually did. Every figure and unit ships with a codex entry sourced from primary historical institutions (USHMM, Yad Vashem, IWM, NARA).

## Status

In development — Milestone 0 (scaffold).

## Build & run

Requires [Godot 4.3+](https://godotengine.org/).

```sh
# Open in Godot editor
godot --editor --path .

# Run from CLI
godot --path .
```

## HTML5 export

```sh
mkdir -p build/web
godot --headless --export-release "Web" build/web/index.html

# Test locally
python3 -m http.server 8000 --directory build/web
# Open http://localhost:8000
```

## Project structure

See `/Users/joshbuck/.claude/plans/i-like-the-cozy-gosling.md` for the full design plan.

## Content note

This game engages with WWII history including the Holocaust, perpetrators of atrocities, and the atomic bombings. Codex entries are factual and sourced. Gameplay representation is designed to confront, not glamorize. See *Content sensitivity guardrails* in the plan document.
