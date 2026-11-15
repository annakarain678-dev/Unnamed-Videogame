# Character system

What the game remembers about the player, and how people talk to them.

## Where things live
| File | Job |
|---|---|
| `scripts/game_state.gd` (autoload `GameState`) | Stats (Fame, the king's Awareness, Valor, Wisdom, Guile), learned facts, people met, places found, flags. `check()` and `apply()` run the condition and effect strings used by dialogue. `to_dict`/`from_dict` are the hooks for real saving. |
| `scripts/dialogue/lore.gd` | Every fact the player can learn: journal text, and for a rumour, where it came from and the place it points to. |
| `scripts/dialogue/dialogues.gd` | The conversations (data only): crier, scholar, Sen-Kash visitor, Tar'ye meat stand, Fayran cartographer. |
| `scripts/dialogue/dialogue_box.gd` | The box at the bottom of the screen. E/Space/Enter continue, 1-4 or click to answer, Esc to walk away. |
| `scripts/dialogue/npc.gd` | A person standing in the world (same body model as the forms), who turns to face you. |
| `scripts/pause_menu.gd` | Journal tabs: Standing, Memories, People, Places, Rumours (rumours show `from -> to`, and "(found)" once you have been there). |

## Rules built in
- **Talking needs a body.** As the wisp you get "take a form to speak".
- **Language:** everyone understands Human, and a species understands itself. Two different non-human forms cannot talk, so a Tar'ye cannot speak with the Sen-Kash visitor until it takes the Human form.
- **Lying:** an answer carrying `lie_if_knows:<fact>` costs 1 Valor only if the player really knows the fact. Real ignorance costs nothing. (The scholar tests this once you have learned the name B'nuo Puxarorna.)
- **Places** are found by getting within 70 m of one; a rumour pointing at it is then marked found.

## Adding content
- New fact: one entry in `Lore.FACTS`.
- New person: one entry in `Dialogues.TREES`, then `_npc("id", Vector2(x, z))` in `RegionWorld._build_places`.
- Conditions: `knows:x`, `flag:x`, `form:Human`, `stat:valor>=2`, any with a leading `!`. Effects: `learn:x`, `flag:x`, `unflag:x`, `stat:fame+1`, `lie_if_knows:x`.

## Dev flags
`--enter=Human@10` (become a form at the nearest pillar), `--talk=crier@14`, `--menu=journal@3`, used with `--screenshot=`.

## Not done yet
Saving to disk; the mayor and possession; Awareness and Guile have no source yet; the cartographer's map filling in; Lucifer encounter dialogue; tavern people (knight, florist, mayor).
