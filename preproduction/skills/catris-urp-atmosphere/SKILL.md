---
name: catris-urp-atmosphere
description: Direct Catris Unity URP lighting, contact shadows, anchored foliage and curtain wind, subtle particles and mobile rendering. Use for the five map light rigs, shaders, post effects and iPhone graphics profiling.
---

# Catris URP atmosphere

Respect preparation mode in [the master prompt](../../../CATRIS_MASTER_PROMPT.md); plans and tuning proposals do not authorize game shader/scene implementation.

Read [art bible](../../ART_BIBLE.md), the target [map](../../MAPS.md), [wind contract](../../features/presentation/design.md) and [technical budgets](../../TECHNICAL_PLAN.md). Verify Unity/URP versions from the actual project before choosing APIs.

## Light and material workflow

1. Make silhouette, key/fill and contact shadow work before post-processing. M01 requires a readable warm window-light pattern and textured wood/cloth.
2. Bake static environment lighting where appropriate. Dynamic cats need matching illumination and grounded shadows; eliminate doubled blob/dynamic shadows.
3. Check black/white cats in key and shade. Maintain face and grid readability. Keep BaseColor free of directional window shadows.
4. Add tone mapping/grade and only necessary bloom. Avoid puzzle-area DOF, motion blur, chromatic aberration and fog overlays.
5. If using the bundled URP postprocessing skill, its CLI prerequisites must actually exist. Its suggestion to omit screenshots does not apply to Catris visual acceptance: this task explicitly requires visual comparison.

## Wind

Use a common direction and slow gust envelope per map; per-object phase, stiffness and anchor masks produce variation. Curtain tops and plant roots remain fixed. Leaves/cloth need shaped geometry, not a giant flat card translating rigidly.

Implement matching displacement in shadow/depth/outline paths where they are used, and expand bounds to cover motion. Synchronize ambience/chimes loosely to gusts with cooldowns. Rain belongs outside the window in M04; particle effects stay away from the active board.

## Mobile decisions

Measure fillrate, overdraw, skinning, shadow passes, framebuffer copies and thermal behavior on iPhone. Alpha cutout versus alpha blending, half versus float, MSAA and Forward variants are measured choices, not universal bans. Shader Graph node count is not a hardware instruction limit; Built-in surface-shader directives do not configure URP.

Prefer simple material/pass structure. If a custom Renderer Feature is necessary, read [Render Graph validation](../../vendor/unity/skills/validate-urp-render-graph-renderer-feature/SKILL.md) and installed-package docs. Record quality tiers; reduce peripheral cost while preserving cat silhouette, face and contact.

Deliver runtime captures plus measured GPU/CPU/memory evidence, stating the device and settings. Do not call a Blender viewport or desktop Game view an iPhone test.
