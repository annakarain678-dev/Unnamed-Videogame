# Unnamed Videogame

A video game in the making, set in the world of Lenhavu.

- [Game design document](docs/design.md)

## Playing the prototype

1. Open **Godot** (version 4.7).
2. Click **Import**, choose this folder's `project.godot`, then open the project.
3. Press the **▶ Play** button (top right) or **F5**.

Or just double-click the **Lenhavu** launcher on the Desktop.

| Key | As the wisp | In a body |
|---|---|---|
| WASD | Drift | Walk |
| Double-tap W | Dash | Run |
| Space | Rise | Jump (swim up in water). Fayran: Space again in mid-air to take off; then steer with the mouse, W to flap forward |
| Shift | Sink | Dive (in water) |
| Tab | Enter a nearby statue | Leave the body |
| Left Mouse or F (hold) | Shine: drive darklings away | |
| Right Mouse (hold) | Draw a line of light (inside a heart, darklings can't cross it) | Push a boulder (only a Tar'ye can move it) |
| Mouse | Look | Look |
| Esc | Pause menu (Resume, Journal, Options, Save, Quit) | |

## The first region, grey-box (the scene that opens now)

`scenes/region.tscn`: a mostly round basin about 2.9 km across with every place of the first chapter marked
(boxes and name tags), roads, a deep lake, a flower mesa, and walk-in caves (no loading). Same controls as the
forest. See [docs/region-greybox.md](docs/region-greybox.md). The terrain takes about 10 s to build in the
background (the area around you first). To go back to the forest, set `scenes/forest.tscn` as the main scene.

## The giant forest

You start as the wisp, in daylight, in a clearing at the edge of a redwood-sized forest. The basin is about
4 to 5 km across, ringed by an uneven wall of cliffs and mountains. It has only land, trees, bushes, ferns,
grass and rocks, plus several open clearings kept free for buildings (marked yellow on the map).

| Key | What it does |
|---|---|
| 1 to 5 | Fly faster (1 = normal, 5 = about 50 times, for crossing the map) |
| M | Map. Click anywhere to fly there |
| V | Daylight preview as the wisp (the wisp normally sees in spirit view) |
| [ and ] | Move the clock back or forward an hour |
| T | Time-lapse the day and night |
| H | Hide the text on screen |

The old test island is still in `scenes/main.tscn`. To play it, set it as the main scene in Project Settings.

### The form pillar and the lake

- Fly to the ruined stone **pillar** at the edge of the trees. As the wisp, press **Right Mouse** beside it to open the **wheel of forms**.
- A highlight travels round the wheel: move the mouse right or left, scroll, or press A / D (or Q / E). **Left Click** picks a form; **Right Click** closes it.
- The pillar is also your **save point**. If a body drowns or crashes, it is gone for good and the wisp wakes at the last pillar it used.
- A small **lake** in the main clearing is for trying out swimming (Human, Tar'ye, Sen-Kash, Qoi-Kash; a Fayran can't swim).

## Characters, dialogue and the journal

Talk to people with E while in a body (not as the wisp). Stats, learned facts, people and places are tracked in `GameState` and shown in the pause menu journal. See [docs/character-system.md](docs/character-system.md).
