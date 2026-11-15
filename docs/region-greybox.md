# The first region, grey-box

`scenes/region.tscn` (code in `scripts/region/`). Positions follow [chapter-one-map.md](chapter-one-map.md), with
changes below. North is -Z. Metres from the town unless noted. All grey on purpose: contour lines every 10 m
(heavier every 50 m), a faint 100 m grid, pale roads, name tags on everything.

## Layout
| Place | Position | Notes |
|---|---|---|
| Starting Town | (0, 0) | level clearing; pillar, tavern, scholar, market stalls, duel ground, crier |
| Flower mesa | (120, -520) | 75 m sheer-sided mesa, flat top: fly up for the flowers |
| Road fork, footprints | (190, -650) | 150 m from the mesa; the north road passes the mesa's west foot |
| Darkling area | (-330, -1000) | sunken clearing, ring of 12 stones, Lucifer marker, dragon-egg mural |
| Bandit camp | (950, -100) | quarry sunk 8 m, walled on the east; pillar; loot; captives |
| Ancient ruins | (-800, 400) | 45 m hill with a flat top; dragon egg; hatchery below |
| Lake statues | (-100, 850) | 62 m radius, 24 m deep; four statue pillars and a form pillar |
| Qoi-Kash village | (270, 1105) | a cavern under a 70 m hollow hill; pillar, houses, the pit, the king's mural |

Roads: town to the fork (by the mesa), fork to the darkling area, fork to the bandit camp, ruins to the lake
(the stone path). The rim is a wandering wall of cliffs, mean radius 1450 m (+/-110), about 190 m high.

## Caves (no loading)
- The terrain is still a height-field. Caves are separate meshes under it (a signed-distance field turned
  into a mesh by surface nets, in 48 m cubes, on worker threads) in the same world, so you just walk in.
- Where a cave meets the surface, the terrain has a hole: a round shaft in the lake floor, a slot (a mine ramp)
  on the ruins hill, and a slot (a ramp) in the quarry floor.
- **The underwater way (the "U-bend"):** from the lake floor, down a shaft, 46 m below the surface, along a
  drowned tunnel, and up through a pool into the village cavern. The pool is at the same level as the lake, and
  the cavern floor rises out of it. Water exists wherever you are under the lake level inside the lake, the
  tunnel's footprint and the pool.
- **Hatchery arm:** ramp on the ruins hill, the hatchery chamber, then about 1.3 km of tunnel to the village.
- **Smugglers' way:** from the village cavern, about 1.4 km, to a ramp in the bandit quarry.
- Underground there is no sun, moon or sky light: a dim even glow and dark fog (`Atmosphere.cave_amount`).
  Real lighting (lamps, glow-moss) comes later.
- Checked: a ball the size of a body can be swept along every tunnel segment without hitting anything.

## Not done yet
- The pit (the Black) is only a dark disc; the village is boxes; cave mouths are plain holes, not arches.
- The wheel still shows all five forms (Qoi-Kash should be locked until it is met). Drowning is real: only
  Qoi-Kash can take the drowned tunnel.
- Only the town's own pillar and three more exist; no NPCs, quests or rumours yet.
- Trees and plants are not in the grey-box. The caves show nothing for the swim itself in screenshots
  (underwater fog is thick); the real swim is untested by hand.
- The map (M) is top-down; it does not show cave routes yet.
