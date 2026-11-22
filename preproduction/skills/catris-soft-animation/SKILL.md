---
name: catris-soft-animation
description: Design and implement soft cat deformation, expression, pickup, drag, rotation and settling for Catris without changing puzzle occupancy. Use for authored clips, procedural secondary motion, interruption handling and animation fidelity reviews.
---

# Catris soft animation

Use [the master prompt](../../../CATRIS_MASTER_PROMPT.md) for scope/mode. Preparation produces contracts, timing proposals and reference analysis; runtime code/rig work starts only when requested.

Read [presentation design](../../features/presentation/design.md), [packing state](../../features/packing/design.md) and [motion frames](../../references/motion-pickup-labeled.jpg). Timing values are starting proposals, not extracted engine values.

## Invariants

- Puzzle placement, orientation and occupancy live in the domain. Squash, lag, wobble, eye movement and shadow cannot alter them.
- Assign a single writer to visual root and each bone/layer. Separate authored pose, additive expression and secondary motion; avoid Animator and spring both overwriting the same transform.
- The touch root must track quickly. Put most lag in belly/tail/ears, not in input responsiveness.
- Deformation preserves volume sufficiently and stays bounded. The final silhouette remains recognizable, without joints opening or eyes sliding across the mesh.

## Workflow

1. Inventory rest, pickup, drag, rotate, drop, invalid return, pet and solve transitions. Record which may interrupt others and the expected return state.
2. Define rig/clip responsibilities and use Generic animation. When authoring clips, read the bundled Blender animation and facial shape-key skills for the actual installed version.
3. Tune anticipation, root response, secondary lag and damping independently. Test slow/fast drag, sudden direction changes, 90-degree rotation while holding, and repeated pickup before the previous settle ends.
4. Integrate with delta-time-safe damping or a fixed-step/substep spring. Clamp/resynchronize after background resume; compare 30 and 60 fps and a long interrupted frame.
5. Give idle behaviors per-cat seeds/phase and cooldowns. Do not animate every cat's head/ears constantly or in synchrony.
6. Check skinned bounds and deformation parity in color, depth, shadow and outline passes. Follow-through must not disappear at the screen edge.
7. Provide Reduce Motion while preserving selected/valid/invalid cues.

## Review evidence

Capture idle, lift/drag/rotate/drop, invalid return and interruption sequences at phone scale. Inspect poses and time-continuous motion, contact/shadow and hand responsiveness. Apply [quality gates](../../QUALITY_GATES.md); a still image cannot pass the animation gate.
