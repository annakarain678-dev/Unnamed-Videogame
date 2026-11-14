# The giant forest (first terrain)

A greybox-plus world to fly around in as the wisp. Nothing here is final art.

- **Size:** an uneven basin about 4 to 5 km across (radius about 1.4 to 2.4 km, wandering), ringed by terraced cliffs and then mountains that rise well above any flying height. Terrain is generated out to about 3.5 km from the center.
- **Land:** rolling hills, narrow ravines, and five flat **clearings** for buildings (the main one is at the center, 170 m radius). The other four are spare sites for villages and camps.
- **Plants:** redwood-sized giants (about 95 to 170 m tall), smaller conifers beneath them, bushes, sword ferns, grass and boulders. Open meadows in clearings, red-brown needle duff under the trees.
- **How it's built:** all from code, in `scripts/forest/`. The land is a pure function of (x, z) (`forest_terrain.gd`), streamed in patches that get coarser with distance (`forest_chunks.gd`, `forest_builder.gd`), with shaders in `shaders/forest_*.gdshader`.
- **Sky:** a warm, hazy day with drifting clouds (`cloud_cover` in `atmosphere.gd`, 0 clear to 1 overcast), a golden-orange sunset with a wide sun glow and thicker forest mist at dawn and dusk, and a starry night with clouds. Colors live at the top of `day_night_cycle.gd`; the clouds are drawn in `sky.gdshader`.
- **Form pillar:** a ruined obelisk about 2.1 m tall near the trees (`scripts/form_pillar.gd`, `shaders/forest_pillar.gdshader`). It carries the **form glyph**, a ring around a diamond (`assets/symbols/form_glyph.png`). Reuse that glyph on anything else that offers forms. Its wheel is `scripts/form_wheel.gd`, with the five species symbols in `assets/symbols/`.
- **Lake:** a small lake carved into the main clearing. Water exists only there (`ForestTerrain.in_lake`), so bodies and the camera only swim or go underwater inside it.
- **Detail distance:** full-detail trees only within about 400 m, simpler ones out to about 1.5 km, then simple cones. Raise or lower `SPLIT_K` in `forest_chunks.gd`.
- **Known issues, parked for later:** a few trees float on steep ground; a trunk's collision doesn't follow its flared foot; cliffs are smooth; the pillar's look is a first pass.
- **Not in yet:** water, buildings, creatures, weather, collision for bushes and rocks, weather changes (rain, storms), and a moon phase.

To change the size or the rim, see the constants at the top of `scripts/forest/forest_terrain.gd`.

## Fayran stamina (tuned for the big world)

Flapping now costs about a quarter as much (about 70 seconds of nonstop flapping), gliding refills faster, and the flight ceiling is much higher. Flying within about 30 feet (9 m) of gentle ground or of the lake's surface refills energy quickly even while flapping, so a Fayran can cross the whole map by skimming low. Steep ground (a cliff face) doesn't count. See the constants near the top of `scripts/form_body.gd`.
