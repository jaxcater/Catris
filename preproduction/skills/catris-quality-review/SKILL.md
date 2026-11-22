---
name: catris-quality-review
description: Review Catris against its video reference, organic 3D art requirements, portrait usability, puzzle invariants and measured iPhone performance. Use for milestone acceptance and evidence-based handoff without treating a successful build or concept render as finished game quality.
---

# Catris quality review

Read [quality gates](../../QUALITY_GATES.md) and [the master prompt](../../../CATRIS_MASTER_PROMPT.md). During preparation, review the pack and readiness only; runtime gates remain unproven.

## Evidence hierarchy

Use source/mesh reports for asset structure, domain tests for puzzle rules, runtime frames/clips for appearance and motion, real-device measurements for performance, and archive inspection for IPA structure. None substitutes for the others.

## Review order

1. Check current user scope, five-map cap, true 3D assets and portrait target.
2. Compare M01 at equivalent visual roles with the timestamped reference: resting cat, lifted cat, window light, peripheral wind. Do not require literal landscape/portrait pixel alignment.
3. Score silhouette/materials, light/contact, motion/feel, atmosphere and phone readability using the shared rubric. Name concrete defects and evidence paths.
4. Check state transitions and puzzle/undo/hint/save invariants, including interrupted touch. Distinguish tests run from tests merely proposed.
5. Inspect worst-map device capture and measured frame pacing, CPU/GPU, memory and thermal behavior against budgets. Record device model/OS, build revision, quality tier and test duration.
6. Verify provenance, final asset status and unsigned bundle report before handoff.

If a hero cat still reads as crude primitive assembly, fix that asset before multiplying maps. If rendering is expensive, use profiler evidence and preserve face/silhouette/contact readability while reducing peripheral cost.

Mark unobserved criteria as unproven with the missing evidence. If only self-review was available, say so. Do not declare absolute visual identity, solvability of unvalidated boards, or device compatibility from a skill's upstream claims.
