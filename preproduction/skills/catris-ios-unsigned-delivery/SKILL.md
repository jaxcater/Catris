---
name: catris-ios-unsigned-delivery
description: Plan and produce a Catris unsigned iOS device IPA from Unity through macOS Xcode, with versioned CI, bundle validation and artifact provenance. Use for build readiness, unsigned packaging and distinguishing simulator, device and signed test evidence.
---

# Catris unsigned iOS delivery

Read [the master prompt](../../../CATRIS_MASTER_PROMPT.md) and [build specification](../../IOS_UNSIGNED_IPA.md). In preparation mode, inspect/read and document only; do not create active workflows, install engine stacks, execute builds or publish.

## Before a production build

Inspect the actual repository and preserve existing work. Record Unity patch, package lock, iOS module, license method, host architecture, macOS/Xcode/SDK versions and shared scheme. An available GitHub repo does not imply any of these are ready. Do not choose a Windows-only path for the final Xcode compilation.

## Required stages

1. Validate domain/content, then export Unity iOS Release with Metal, ARM64, IL2CPP and portrait configuration. Inspect BuildReport, logs and real generated paths.
2. On macOS build a device iPhoneOS archive with signing disabled as specified. Resolve target/dependency issues from logs; do not silently enable automatic signing.
3. Locate the actual app product, inspect bundle/executable/frameworks and copy into a fresh staging Payload. Preserve bundle structure, permissions and symlinks.
4. Check device platform as well as ARM64 architecture; an ARM64 Simulator app is not a device IPA.
5. Verify app and nested signing state. Any cleanup applies only to the build staging copy, never installed SDKs or unrelated source files.
6. Package Payload at ZIP root, test archive integrity, compute SHA-256 and emit a report containing source revision/toolchain/signing/device-test status.

No Apple certificate is required merely to prepare an unsigned artifact. Unity licensing remains a separate dependency. Do not request credentials for work that does not require them or place credentials into project files.

## Truthful handoff

An unsigned IPA needs an appropriate signing step before installation on an ordinary iPhone. Bundle validation is not device runtime verification. A signed test build from the same revision can provide device evidence; record the relationship and differences. Never label an unrun build as visually or thermally validated.
