# BusSimulator 🚌

A 3D **bus simulator** mobile game inspired by *Ultimate Bus Simulator* and
*Euro Truck Simulator 2*, built with **Godot 4.4** (Forward+ / PBR)
for **Android** (landscape, 1280×720, 60 physics FPS).

The bus uses the real Godot **vehicle physics** (`VehicleBody3D` +
`VehicleWheel3D`): it is **heavy, slow to accelerate, has a long braking
distance, a wide turning radius, speed-capped at 80 km/h** — it drives
like a bus, not a race car.

---

## Features

| System | File | Highlights |
| --- | --- | --- |
| Bus physics & controls | `scripts/bus_controller.gd` | RWD, 4 wheels, smoothed steering, fuel-gated, reverse, doors |
| Cameras | `scripts/camera_system.gd` | Chase (clipping-safe), interior, top-down ortho |
| Traffic AI | `scripts/traffic_ai.gd` | Looping colored cars on the grid |
| Passengers | `scripts/passenger_system.gd` | Board at stops, deliver for coins |
| Fuel | `scripts/fuel_system.gd` | Drains while driving, refuel at stations |
| HUD / touch UI | `scripts/ui_manager.gd` | Money, fuel bar, speedo, passengers, big thumb buttons |
| Day / night | `scripts/day_night_cycle.gd` | Sun rotates over 5 minutes |
| City | `scripts/build_city.gd` | 18 PBR buildings + sidewalks (CSG) |
| Shared state | `scripts/game_state.gd` | Autoload singleton (money/fuel/inputs) |

Scenes: `Main.tscn`, `Bus.tscn`, `BusStop.tscn`, `TrafficCar.tscn`,
`HUD.tscn`, `World.tscn`.

### Materials (all `StandardMaterial3D`, PBR)
- Bus body — `metallic 0.4`, `roughness 0.35`, red
- Windows — `metallic 0.9`, `roughness 0.05`, dark blue, transparent
- Wheels — `metallic 0.1`, `roughness 0.8`, dark gray
- Road / ground — `roughness 0.9`, `metallic 0.0`
- Buildings — `roughness 0.7`, `metallic 0.0`, muted colors
- WorldEnvironment — `ProceduralSky`, ACES tonemap, SSAO, SSR, glow, fog

The horn beep is **generated programmatically** (`assets/audio/horn.wav`
is synthesized by a Python script / at load) — no external sound files.

---

## Controls

**Touch (mobile):** left/right steering arrows · hold GAS · hold BRAKE ·
HORN · DOOR (open/close) · CAM (cycle camera) · FUEL (refuel when
parked at a station). Buttons are large and semi-transparent.

**Keyboard (desktop testing):** `↑`/space = throttle/brake ·
`←`/`→` = steer · `C` = camera · `E` = door ·
`H` = horn.

### How to play
1. Drive to a **bus stop** (blue shelter with waiting passengers).
2. Stop, open the **DOOR**, and passengers **board** (passenger count
   rises).
3. Drive to the **next stop**, open the door, and they **alight** →
   you earn **10–50 coins per passenger**.
4. Watch the **fuel bar** — pull into a **fuel station** (green sign) and
   tap **FUEL** to refuel for coins.
5. Switch cameras with **CAM**.

---

## Open & run (desktop)

```bash
# from this folder
godot --editor            # import & open the project
godot --headless --path . --quit   # headless import sanity check
```

Set `res://scenes/Main.tscn` as the main scene (already configured in
`project.godot` → `application/run/main_scene`).

---

## Export the Android APK

> ⚠️ **Build note:** this repository was authored in a sandboxed
> environment **without outbound access to the Godot release CDN**, so the
> engine binary / Android export templates could not be downloaded here.
> The **entire Godot 4 project** (scenes, scripts, materials, config,
> export preset) is complete and committed. To produce the APK, run the
> steps below on a machine with network access + the Android SDK.

```bash
# 1. Open the project in Godot 4 and install the Android export
#    templates (Editor ▸ Manage Export Templates ▸ Download) and the
#    Android build template (Project ▸ Export ▸ Android ▸ Install).
# 2. Ensure the ANDROID_SDK_ROOT / ANDROID_HOME env var points at a
#    valid SDK, then:
godot --headless --export-release "Android" BusSimulator.apk
# or simply:
./tools/export_apk.sh
```

`export_presets.cfg` already defines the `Android` preset
(package `com.bussimulator.game`, landscape, arm64).

---

## Project layout

```
BusSimulator/
├── project.godot            # engine config (Forward+, 1280×720, 60fps)
├── export_presets.cfg      # Android export preset
├── icon.svg
├── assets/
│   ├── audio/horn.wav      # programmatic beep
│   ├── models/  textures/  environment/   # (PBR material hosts)
├── scenes/                 # Main, Bus, BusStop, TrafficCar, HUD, World
├── scripts/                # one .gd per system (see table above)
├── ui/                    # UI theme/icon resources
└── tools/                 # export_apk.sh, validate.py
```

Run the offline structural checker any time:

```bash
python3 tools/validate.py
```
