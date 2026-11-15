# The first region (grey-box layout, now coloured and planted)

`scenes/region.tscn` (code in `scripts/region/`). Positions follow [chapter-one-map.md](chapter-one-map.md), with
changes below. North is -Z. Metres from the town unless noted. All grey on purpose: contour lines every 10 m
(heavier every 50 m), a faint 100 m grid, pale roads, name tags on everything.

## Layout (tightened by about 30% after the first play-test)
| Place | Position | Notes |
|---|---|---|
| Starting Town | (0, 0) | level clearing; pillar, tavern, library (across the street), market stalls, duel ground, crier near the pillar |
| Flower mesa | (85, -365) | 75 m sheer-sided mesa, flat top: fly up for the flowers |
| Road fork, footprints | (130, -455) | 100 m from the mesa; the north road hugs the mesa's west foot |
| Darkling area | (-230, -700) | sunken clearing, 60 m ring of 14 stones, Lucifer marker, dragon-egg mural, a save pillar in the trees nearby |
| Bandit camp | (620, 40) | quarry sunk 8 m, walled on the east; pillar; loot; captives |
| Ancient ruins | (-480, 330) | 45 m hill with a flat top; dragon egg; hatchery below |
| Lake | (-150, 560) | 62 m radius, 24 m deep; a ruined colonnade of statues on the north shore and a form pillar |
| Qoi-Kash village | (200, 660) | a cavern under a 60 m hollow hill; pillar, houses; the Black is far below it |

Roads: town to the fork (by the mesa), fork to the darkling area, fork to the bandit camp, ruins to the lake
(the stone path). The rim is a wandering wall of cliffs, mean radius 1000 m (+/-80), about 190 m high.
Town to every main place is 580 to 740 m.

## Caves (no loading)
- The terrain is still a height-field. Caves are separate meshes under it (a signed-distance field turned
  into a mesh by surface nets, in 48 m cubes, on worker threads) in the same world, so you just walk in.
- **Cave mouths are carved, not cut.** Around each opening, the cave mesh builds the ground too (the terrain skips
  those 48 m squares). The tunnel simply dips below the ground and the ground becomes its roof. (The first
  version cut holes in the ground and left a closed, solid dome over each one: you could not get in.)
- **The underwater way (the "U-bend"):** from the lake floor, down a shaft, 46 m below the surface, along a
  300 m drowned tunnel, and up through a pool into the village cavern. The pool is at the same level as the
  lake, and the cavern floor rises out of it. Water exists wherever you are under the lake level inside the
  lake, the tunnel's footprint and the pool.
- **Hatchery arm:** a ramp into the ruins hill, the hatchery chamber, then about 770 m of tunnel to the village.
- **Smugglers' way:** from the village cavern, about 730 m, to a ramp in the bandit quarry floor.
- **The Black:** a winding passage from the village cavern's east side, down about 60 m to a deep chamber with a
  dark disc (the pit) and the king's mural.
- Underground there is no sun, moon or sky light: a dim even glow and dark fog (`Atmosphere.cave_amount`).
  Real lighting (lamps, glow-moss) comes later.
- Checked by script: a ball the size of a body can be swept along every tunnel segment, and walked in from the
  open at all three surface mouths, without hitting anything; and 25,000 rays dropped over the whole region
  found no hole in the ground.

## Second pass (after the second play-test)
- **Colour and planting:** the ground is meadow, forest floor, dead wood round the darklings, bare earth in the
  town and quarry, dirt roads, sand round the lake, layered rock, and snow on the rim. Giant conifers (60 to
  120 m) grow thick toward the rim and in a belt north of the town, with small conifers and rocks between; the
  clearings, roads, mesa, ruins hilltop, lake and cave mouths are kept clear. Trunks are solid. G turns the
  grey-box contour lines and 100 m grid back on.
- **No way out into the void:** caves are now cut off just below the ground wherever they are not at a mouth (they
  used to be able to poke up through it), and the terrain has an invisible wall down from every edge that meets
  a cave-built square. A scan of 25,000 rays over the region finds no gap.
- **Shores you can climb out of:** the lake bowl is a gentle parabola, and the pool in the village is a round
  bowl with a beach instead of a straight-sided well.
- **Change form at any pillar, in any form:** Right Mouse near a pillar while inside a body opens the wheel; picking
  another form leaves the old body (it goes away) and enters the new one.

## On screen
- Place names are flat screen text (`PlaceTags`), so fog and the wisp's colours never wash them out. Names for
  things underground only show while you are underground.
- The UI now scales with the window (base 1600 x 900, stretch mode `canvas_items`), so the menu, wheel and text
  no longer jump in size when the window changes.

## Not done yet
- The pit (the Black) is only a dark disc; the village is boxes; cave mouths are natural but plain (no arches or timber).
- The wheel still shows all five forms (Qoi-Kash should be locked until it is met). Drowning is real: only
  Qoi-Kash can take the drowned tunnel.
- Only the town's own pillar and three more exist; no NPCs, quests or rumours yet.
- Trees and plants are not in the grey-box. The caves show nothing for the swim itself in screenshots
  (underwater fog is thick); the real swim is untested by hand.
- The map (M) is top-down; it does not show cave routes yet.
