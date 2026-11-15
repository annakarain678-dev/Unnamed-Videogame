# Art direction

Reference: Outer Wilds (and similar hand-painted fantasy props). Twelve reference images were shared in the session of 2026-11-14: painted wood-grain and cracked-stone textures, a crooked shingled house, a worn cowboy-hatted alien, a spiny monster, a lantern-lit ruin, a pit-and-boards mine site.

## The look in one line
Low-poly, hand-painted, **worn and cinematic**: simple and plain, never bright or candy-coloured.

## Rules to build by
- **Shapes:** broad, readable silhouettes made of a few big forms; slightly crooked, never perfectly geometric. Exaggerated proportions.
- **Textures:** hand-painted look, visible colour variation inside one material (several related browns in wood, patchy grey-greens in stone), painted cracks, knots and highlights. No photo textures, no micro-detail.
- **Surfaces:** mostly matte; gloss only where it says something (metal, wet things, creatures).
- **Detail hierarchy:** silhouette, then big shapes, then material, then small character details. Spend detail on faces, doors, signs and focal props, not everywhere.
- **Colour and light:** muted and warm-earthy (rust, ochre, dusty blue-grey), with lamplight and a strong sun or moon as the accent. Dim, moody, lived-in, not overly bright.
- **Wear:** patched cloth, weathered boards, moss, dents.

## What this means for the game (not done yet)
- Replace the grey boxes with crooked wooden and stone buildings (tavern, library, stalls) using painted wood and stone textures.
- Tile painted textures into `region_ground.gdshader` (rock cliffs, roads) instead of flat noise colour.
- Repaint the species models (Sen-Kash and Qoi-Kash especially) with spotted skin, clothing, hats and patches; keep the pill-person proportions readable.
- Soften and warm the daylight, deepen the shadows, add lamps at night.

## Town Crier (first custom character)
`scripts/crier_model.gd` (`CrierModel`), built from the reference sheet: rust hood and tabard, slouch cap, rolled sleeves, scroll in the left hand, cuffed boots. Joint-hierarchy rig (`joints` dictionary: hips, spine, chest, neck, head, mouth, shoulder/elbow/wrist L and R, hip/knee/ankle L and R). Idle: breathing, weight shift, looking about. Shout: right hand cups the mouth, chest fills, head tips back, mouth opens in bursts, every 6 to 11 s or on `shout()`. Look at him alone with `scenes/crier_preview.tscn` (Space shouts, arrows turn him). Painted textures are not applied yet; colours are flat.
