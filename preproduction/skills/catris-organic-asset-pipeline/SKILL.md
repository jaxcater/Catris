---
name: catris-organic-asset-pipeline
description: Prepare and produce Catris organic cat meshes, props, UVs, textures, rigs and Unity FBX exports. Use for real 3D game assets and import QA; concept images and primitive assemblies do not satisfy the final asset contract.
---

# Catris organic asset pipeline

Honor preparation mode in [the master prompt](../../../CATRIS_MASTER_PROMPT.md). During preparation, write briefs/manifests and inspect sources; do not create production meshes or game scenes.

## Asset contract

Read [asset briefs](../../ASSET_BRIEFS.md), [manifest](../../assets/asset-manifest.json), [art bible](../../ART_BIBLE.md) and [budgets](../../TECHNICAL_PLAN.md). Read the target cat's footprint in [packing](../../features/packing/design.md). The footprint constrains occupied space, not visible cube boundaries.

One cell is 0.25 m, one Unity unit is 1 m. Preserve a continuous sculpted silhouette, camera-readable face, soft shoulders/belly/tail transitions and meaningful rest/contact points. No final sphere/capsule chains, sticker-only cats or render-only assets.

## Production route when authorized

1. Inspect DCC version and the current file. Read [Blender core](../../vendor/blender/skills/blender-core/SKILL.md); this vendor snapshot targets 5.2+/5.3, so verify actual APIs before use.
2. Establish one hero concept and silhouette at the game camera. If headless sculpt operators are unsuitable, use safe object-level workflows or a human/DCC handoff; do not claim brush sculpting happened when it did not.
3. Sculpt/refine primary forms, retopologize around deformation regions, UV and establish texel density. Read the bundled sculpting and retopology skills only for those tasks.
4. Bake/paint a coherent material family. Separate color from lighting; map roughness/normal channels to the actual URP shader convention.
5. Rig as Generic. Define root/pivot, deform bones, facial shapes and corrective deformation. Limit weights and material slots according to budgets; do not choose a Humanoid avatar for cats.
6. Test extreme lift/rotate/squash poses, seams, normals, detached geometry and weight collapse. Produce rest/pose previews plus numeric mesh/rig reports.
7. Build LODs preserving face and silhouette. Bake constraints and export named clips with FBX and separate textures. Keep editable source outside runtime asset import.
8. Use [export pipelines](../../vendor/blender/skills/blender-export-pipelines/SKILL.md) and [asset QA](../../vendor/blender/skills/blender-asset-qa/SKILL.md); re-import the FBX and then validate in Unity/Metal. A successful Blender export is not Unity compatibility proof.

## Provenance and status

Record source, author, license/tool, editable files, export files and checks. Advance `planned` → `authored` → `imported` → `runtime-approved` only with evidence. Downloaded Poly Haven files remain source materials until adapted and reviewed. Generated concepts/meshes receive the same topology, rig, licensing and runtime checks.
