---
name: catris-portrait-packing
description: Specify and build Catris deterministic polyomino packing, portrait safe-area layout, one-hand touch, solver-aware hints, undo and local save. Use for puzzle logic and iPhone interactions, keeping mesh deformation separate from board state.
---

# Catris portrait packing

Read the mode in [the master prompt](../../../CATRIS_MASTER_PROMPT.md). In preparation, produce rule/data/UI specifications only. Use [packing design](../../features/packing/design.md) as the home for rules and tunable numbers.

## Domain

Represent board mask and piece footprints as integer cells with stable IDs. Rotate in 90-degree steps and normalize origin/pivot consistently. Validity uses mask containment and occupancy excluding the piece's old placement; visual mesh/bone bounds do not decide legality.

Commit one transaction on valid release, return safely on invalid/cancel, and record one undo entry per placement. Winning requires exact coverage and all required pieces. Persist committed state with version/validation/backup; do not serialize mid-spring transforms as truth.

For authored/generated levels retain a checked solution witness. Hint searches from the current state; if placements block every completion, propose a specific change or undo. Never overlay an incompatible original witness as a supposedly valid hint.

## Touch and portrait

Derive layout from the current safe rect. Keep readable square cells, reachable controls and every required piece discoverable in the tray. A landscape crop is not responsive layout. Separate tray preview scale from world asset scale.

Capture one pointer owner for the drag, prioritize UI starts, preserve grab anchor during rotation and compensate finger occlusion without changing quantization. A tap, drag, rotate-button press and pet action must not fire simultaneously by accident. Secondary touches, leaving the screen, opening settings and backgrounding must have explicit cancellation behavior.

## Checks when implemented

Test rotations/invariants, out-of-mask/overlap rejection, self-occupancy, undo/cancel, valid/invalid hints, solvability, save migration/corruption recovery and interrupted input. Then verify on-device hit regions and safe areas. Use pure domain tests for logic and device evidence for touch; neither replaces the other.

Keep the relaxing loop: no default timer, energy, lives, streak penalty or ad-gated hints. Respect the five-map cap and distinguish maps from individual puzzle boards.
