# Catris — Asset Provenance & Licenses

All runtime assets shipped inside `Sources/CatrisApp/Assets/` have clean, documented provenance and are safe for offline redistribution. No frames, textures, meshes, or audio from the reference video `Game.mp4` are included in the runtime app or IPA.

## 1. Original Procedural / Sculpted Catris Assets (MIT / Original Authoring)
Generated deterministically via `tools/CatrisAssetBuilder/` and `tools/verify_levels.py`:
- **12 Sculpted 3D Organic Cat Meshes** (`Meshes/cat_*.cmesh`, Surface Nets SDF + Taubin smoothing, 4.7k–11.6k tris/cat, smooth analytical normals & soft-rig vertex weights)
- **15 Sculpted 3D Diorama Props & Obstacles** (`Meshes/prop_*.cmesh`: plush rug, acoustic guitar, broadleaf monstera plant, ceramic pot, pleated linen curtain, cushion, book, teacup, yarn ball, milk bowl, acorn, oak roots, desk lamp, fish plushie, ear bow)
- **Stylized PBR Textures, Rug Patterns, Window Gobos & AppIcon** (`Textures/*.png`)
- **Mastered 48 kHz / 16-bit PCM Cozy Audio Suite** (`Audio/*.wav`: day/night acoustic Rhodes loops, 5 map ambience beds, tactile foley, formant cat voices & purr)
- **60 Verified Solvable Boards** (`Data/levels.json`, mathematically verified by exact-cover backtracking)

## 2. Third-Party CC0 Source Assets
- **Autumn Field Pure Sky 1K HDRI** (`Sources/CatrisApp/Assets/Textures/sky_ibl.hdr`):
  - Source: [Poly Haven — Autumn Field Pure Sky](https://polyhaven.com/a/autumn_field_puresky)
  - Authors: Sergej Majboroda (Original), Jarod Guest (Sky Edits)
  - License: [CC0 1.0 Universal](https://polyhaven.com/license)
- Reference materials (`wood_floor`, `fabric_pattern_07`) archived in `preproduction/assets/source-materials/` are also [Poly Haven CC0 1.0](https://polyhaven.com/license) (authors Dimitrios Savva and Rob Tuytel).
