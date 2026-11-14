# The giant forest (first terrain)

A greybox-plus world to fly around in as the wisp. Nothing here is final art.

- **Size:** an uneven basin about 4 to 5 km across (radius about 1.4 to 2.4 km, wandering), ringed by terraced cliffs and then mountains that rise well above any flying height. Terrain is generated out to about 3.5 km from the center.
- **Land:** rolling hills, narrow ravines, and five flat **clearings** for buildings (the main one is at the center, 170 m radius). The other four are spare sites for villages and camps.
- **Plants:** redwood-sized giants (about 95 to 170 m tall), smaller conifers beneath them, bushes, sword ferns, grass and boulders. Open meadows in clearings, red-brown needle duff under the trees.
- **How it's built:** all from code, in `scripts/forest/`. The land is a pure function of (x, z) (`forest_terrain.gd`), streamed in patches that get coarser with distance (`forest_chunks.gd`, `forest_builder.gd`), with shaders in `shaders/forest_*.gdshader`.
- **Not in yet:** water, buildings, creatures, weather, collision for bushes and rocks, and any tuning of the sky or day-night look.

To change the size or the rim, see the constants at the top of `scripts/forest/forest_terrain.gd`.
