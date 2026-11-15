# First region: places, links and layout

Design notes only, nothing built yet. Written from the user's hand-drawn web (stars = main places,
squares = small places, NPCs and quest hooks) plus the follow-up answers.

North is −Z in the game (0° yaw faces north). All distances are metres from the starting town.

## 1. The web

Main places: **Starting Town**, **Darkling Corruption area**, **Bandit Camp**, **Ancient Ruins**
(the sketch is missing its star), **Qoi-Kash Village**. The **Lake Statues** are also a main place
because they hold a form pillar.

| Place | Small things in it | Points onward to |
|---|---|---|
| Starting Town | Town Crier, Market, Scholar, Tavern | everything below |
| Town Crier | lost-child quest hook | Lost Child, Footprints |
| Market | Human Blacksmith (upgrades), Fayran Cartographer (landmarks), Sen-Kash Visitor (rumours of the king's growing evil), Tar'ye Meat Stand (food for health; non-lethal teaching duel) | the cartographer's landmarks |
| Scholar | rumours of the Ancient Ruins | Ancient Ruins |
| Tavern | Knight (friendly duel, or a death duel if angered), Florist (flower quest), Darkling Mayor | Forest, Darkling area |
| Forest | flower picking | Footprints at the road fork |
| Footprints at the road fork | a fork in the road | Bandit Camp or Darkling area |
| Darkling Corruption area | ring of stones, darklings; Lucifer encounter; mural of a dragon egg in ruins | Ancient Ruins (mural), the king (Lucifer) |
| Ancient Ruins | Dragon Egg, Ruin Stone Path | Hidden Hatchery, Lake Statues |
| Hidden Hatchery | hatch the egg; entry is a puzzle | caves to Qoi-Kash Village |
| Lake Statues | form pillar (unlocks Qoi-Kash) | underwater cave to Qoi-Kash Village |
| Qoi-Kash Village | talk to people; the missing Qoi-Kash rumour; the Black (the pit) with the mural of the king | the cave the Qoi-Kash was taken out of, leading to the Bandit Camp |
| Bandit Camp | practice fighting; Gold and Loot (puzzle); captives | back to the town (loot, Lost Child) |

Nothing here is a required quest. Everything is a hint: it adds an entry to the player's **rumour chart**,
and the player decides whether to follow it. The player can find any place first (flying included);
you cannot be sent somewhere you have no rumour of, because the map only fills in as you learn.

## 2. Decisions made

### Story
- **Lucifer is B'nuo Puxarorna.** Same being, not a servant. The darkling-corruption encounter is
  Lucifer himself: two dark, fiery eyes watching you.
- **The king is Lucifer's tool.** He has been corrupted. The mural at the Black hints at this; it must
  not be too obvious, so you only learn it by exploring. The pit means Lucifer is trying to toss
  everyone into the blackness, using the king to do it.
- **The Black** stays lore only; the pit is the sign of it.
- **Lucifer encounter:** if you clear the Darkling area, he notices you. Answering "I'm here to take you
  down" raises the king's **awareness** of you (not your fame). Playing dumb keeps the king less
  concerned. If you do not yet know who he is, playing dumb is just ignorance: no penalty. If you do
  know (it is in your journal) and say you don't, it is a lie and costs **Valor**. The dialogue must
  check the journal.
- **Bandit Camp:** the shared climax. The lost child and the kidnapped Qoi-Kash are both held there.
  Freeing them needs a puzzle. Clearing the camp without killing anyone is possible (lure them out, per
  the commandments). Gold and Loot is behind another puzzle.
- **The loot choice is in the mayor's dialogue.** Hand it over or not. If he is still possessed he keeps
  it; if he has been purified he returns it to the town. This does not depend on the Darkling area.

### The mayor and the darklings
- The Darkling Mayor sits in the Tavern. As a **Sen-Kash** or the **wisp** you can see that he is
  possessed.
- **Purifying him:** as the wisp, shine on him and drive the darkling out. This is the person-possession
  mechanic. The darkling runs away and leaves a **trail** or trace.
- Following the trail leads to the Darkling area. There is a big ring of stones, and you chase the
  darklings out **one by one**. Some have a **bash** attack that tosses you out. This is the same
  mechanic as driving one out of a person, repeated.
- Clearing the area is separate: it is what summons Lucifer.

### Forms
- **Every form can fight.** Tar'ye: strongest (high damage, takes a lot). Human: strong, and has the
  most tools (blacksmith weapons). Sen-Kash: spin and constrict, like a cobra; hides in tight places.
  Qoi-Kash: eel; a drowning attack; hides in tight places and swims. Fayran: swoop and speed, the
  weakest fighter; can fly away.
- **Language:** every species understands Human, and Humans understand all species. Non-human species
  do not easily talk to each other (a Tar'ye and a Fayran struggle). Human is the common tongue.
- **Qoi-Kash starts locked on the wheel.** It unlocks at a pillar you reach after meeting the Qoi-Kash:
  the Lake Statues, the Bandit Camp, or the village. (Assumed: the other four forms are available from
  the first pillar. To confirm.)
- **Fayran gate:** needs something placed high up (a ledge, a high entrance, a flower on a cliff).
- **Routes:** through the ruins and hatchery caves any form except Fayran can pass (assumed). The
  underwater cave to the village needs Qoi-Kash, and is the quiet route. Someone dropped some treasure
  down there.

### The dragon
- Hatching it is the price. The king becomes more aware of you. Your **fame and the weight of your
  decisions rise** (more mythic, in either good or bad direction). In exchange you get a companion and an
  elemental superpower.

### Stats to track
Fame (towns), king's awareness, Valor / Wisdom / Guile (the Way for dialogue). Journal knowledge
decides what counts as a lie.

## 3. Placing it on the map

(Updated in [region-greybox.md](region-greybox.md): the flowers are on a flat-topped mesa beside the road fork,
the lake is 24 m deep with a drowned tunnel that comes up in the village, and the basin is about 2.9 km across.)

Distances are from the starting town. They keep the sketch's arrangement (town in the middle, darklings
up and left, bandits right, ruins left, village below with the lake between).

```
                 N
                 
     DARKLING (-350,-1150)             
                    \                   
                     FORK (150,-600)------- BANDIT CAMP (1000,-50)
                    /                              :
        Forest (-100,-330)                          :
                   |                                :
  RUINS (-850,450)--TOWN (0,0)                      :  (Smugglers' Way)
        |   \                                       :
        |    LAKE STATUES (-100,850)                :
        |       |                                   :
        '- caves- QOI-KASH VILLAGE (250,1100) - - - '
```

| Place | Position | From town | Notes |
|---|---|---|---|
| Starting Town | (0, 0) | – | the big clearing; the first pillar |
| Forest and flowers | (−100, −330) | 350 m | a belt of trees north of the town |
| Road fork, footprints | (150, −600) | 620 m | one way to Bandits, one to Darklings |
| Darkling area | (−350, −1150) | 1200 m | dead-wood clearing, a ring of stones |
| Bandit Camp | (1000, −50) | 1000 m | in a quarry or ravine under a cliff |
| Ancient Ruins | (−850, 450) | 960 m | on a hill; the hatchery is inside it |
| Lake Statues | (−100, 850) | 855 m | a new lake; the statues and a pillar |
| Qoi-Kash Village | (250, 1100) | 1130 m | a large cavern under a hill |

Links that matter:
- Ruins to the Lake: 850 m on the Ruin Stone Path.
- Lake to the village: about 300 m, underwater, with the quiet-route treasure.
- Ruins to the village through the hatchery caves: about 1.3 km of cave.
- Village to the Bandit Camp (the cave the Qoi-Kash was taken out of): about 1.4 km. The two long cave
  arms are the largest build cost. They can wind, and have a chamber halfway, so they feel shorter and
  less empty. If it is too much, move the village nearer the town.
- The four clearings already in the world (-980,620), (1050,-520), (-380,-1250), (1150,1000) can be
  moved to these spots; the terrain code takes their positions from one list.
- The current pillar and pond by the start stay as the town's pillar and a practice pond. The Qoi-Kash
  one is a second lake.

## 4. Caves you can walk into with no transition

Open-height terrain cannot have a cave, but a full voxel world is too heavy for a 5 km world on an M1
with 8 GB. Plan: keep the streamed height-field and add **cave systems as separate meshes that sit
underneath it, in the same world space.**

- The terrain gets **holes** at cave mouths (triangles and plants skipped inside a disc). The mouth is
  placed on a cliff or hillside and framed by a rock arch mesh, so the join is hidden.
- The cave itself is a tube-and-chamber mesh with its own trimesh collider. It is described by a list
  of path points and radii, plus noise; a builder turns that into an organic mesh (marching cubes on a
  small local volume, built on a worker thread like the forest chunks). Big caverns (the village) are
  just a large chamber under a hill.
- The terrain is one-sided, so from inside the cave you see the cave's ceiling, not the terrain; from
  outside you see only terrain. Streaming by distance, so only a few caves are ever loaded.
- **Light and air:** a cave area blends the atmosphere the way underwater already does: no sun, no sky
  light, dark fog, lit by lamps, glow-moss and the wisp itself. Sun shadows from the terrain keep sun out.
- **Water in caves:** the water system is local already; it grows from one lake to a list of water
  bodies. The underwater cave opens through the lake bed.
- **The pit (the Black):** a large hole in the village cavern floor; falling is the normal death and
  respawn at the last pillar.
- **Buildings:** the tavern and the other town interiors are just meshes with doors in the same world,
  so there is no loading anywhere.
- **Terrain landforms needed:** a Ruins hill, a Hollow hill for the village, a quarry at the Bandit
  Camp, a lake basin. All are added as shapes in the height function.

**Risk:** the join between terrain and cave mouth and the cave lighting are the parts I'm not certain
of. A proof of concept comes first (one mouth on one hillside, walk in and out, then a short tunnel,
then lighting) before we commit to the rest.

## 5. Suggested build order

1. Cave proof of concept (above).
2. Character and dialogue system (stats, tags, journal and rumour chart).
3. Greybox town with the tavern, market and crier.
4. Tar'ye duel as the first fight (non-lethal, so no death states yet).
5. Possession mechanic (the mayor) and the stone ring.
6. Bandit Camp with the two captive puzzles.
7. The remaining places and the long cave arms.
8. Art pass.

## 6. Still open
- Which forms start unlocked (assumed: all but Qoi-Kash).
- Whether the Fayran can use the hatchery route (assumed: no).
- Whether the two long cave arms are kept or the village moves nearer the town.
- What the Ruin Stone Path and the Smugglers' Way puzzles actually are.
