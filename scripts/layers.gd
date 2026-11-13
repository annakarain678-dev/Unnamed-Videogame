class_name Layers
## Physics layers, as bit values. Names match Project Settings > Layer Names > 3D Physics.

## Big solid things: ground, cliffs, walls, tree trunks. The camera pulls in to avoid clipping into them.
const WORLD := 1
## Small or narrow things: statues, bodies, small rocks, plinths. They block movement,
## but the camera passes through them instead of jumping in close.
const THIN := 2
## The wisp itself.
const WISP := 4
