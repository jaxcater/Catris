# Catris — Cozy 3D Cat-Packing Puzzle (iOS Portrait)

**Catris** is a native iOS portrait 3D cat-packing puzzle built with **Swift 5.9, SwiftUI, SceneKit (Apple Metal 3D), Custom Metal Shaders, AVAudioEngine, and CoreHaptics**.

Pick up, rotate, and snuggle soft, squishy sculpted 3D cats onto cozy rugs across **5 distinct sunlit, outdoor, conservatory, rainy, and moonlit worlds** — featuring **60 mathematically verified puzzle boards** with zero timers, zero ads, and pure tactile relaxation.

## Highlights & Upgrades

- **True 3D Metal Runtime (Portrait iPhone):**
  - Orthographic 78° elevated diorama camera (`iOS 17+`, `arm64`, portrait-only safe-area layout).
  - **12 Sculpted Organic 3D Cats** (`Nori`, `Sumi`, `Pudding` hugging a 3D blue fish plushie, `Mochi`, `Miso`, `Yuzu`, `Matcha`, `Sesame`, `Kinako`, `Azuki` with sky-blue bow, `Taro`, and 5-cell pentomino boss cat `Banhmi`) — continuous SDF-sculpted, Taubin-smoothed meshes (4.7k–11.6k tris/cat) with vertex soft-rig weights.
  - **Custom Metal Shaders (`MetalShaderModifiers.swift`):** Soft liquid-cat lag bend during drag, volume-preserving squash & settle, grounded chest breathing, animated inverted-hull warm-white sticker outline, animated diagonal red-black invalid warning stripes, anchored wind sway for plants & curtains, and animated rain droplets on Map 4's glass window.
  - **Expressive 3D Faces:** Independent blinking, pupil gaze, surprised pickup eyes, angry invalid brows, happy `^ ^` petting smiles with blush & floating hearts, floating sleepy `Z z z`, cute fangs & tongue blep.
- **5 Bespoke Diorama Maps × 12 Verified Boards = 60 Levels:**
  1. `M01 — Góc Nắng` (Sunlit Corner — honey-oak planks, pink chevron rug, 4×3 window sunbeams, guitar, monstera, curtains; includes Lv 1–3 tutorials and the classic 4×4 5-cat board!)
  2. `M02 — Dưới Tán Sồi` (Under the Oak — meadow grass, gingham picnic blanket, oak roots, acorns, dappled canopy shadows)
  3. `M03 — Hiên Nhà Kính` (Greenhouse Porch — terracotta tiles, sage linen mat, potted plants, fixed sleeping cats)
  4. `M04 — Ô Cửa Ngày Mưa` (Rainy Reading Nook — chestnut floor, dusty-blue knit rug, rainy window glass shader, warm amber lamp)
  5. `M05 — Gác Mái Trăng` (Moonlit Attic — espresso walnut planks, cream sheepskin rug, dormer moonlight, fireflies & 5-cell Forest King `Banhmi`)
- **Upgraded Puzzle Mechanics:**
  - Exact-cover backtracking solver powering **Solver-Aware 3-Tier Hints** (adapts to your current board state and identifies blocking cats if you hit a dead-end!).
  - Unlimited Undo, Left/Right-Handed Portrait Controls, +54 pt finger-clearance drag offset, Pet & Purr mode ("Ngắm mèo"), Interactive 3D Cat Album, and 15 progressive permanent room decor rewards (1 unlocked per 4 boards completed in each map).
  - Multi-bus `AVAudioEngine` (Music, Ambience, Foley, Cats, UI) + `CoreHaptics` rolling purr rumbles + atomic backup-recovered local save (`SaveStore`).

## Architecture Note (Why Native Swift + SceneKit Metal)

To guarantee a **reproducible, zero-license-blocker GitHub Actions `.ipa` build** directly on standard `macos-15` runners (without requiring paid/activated Unity Editor CI licenses or manual Unity Hub setup), Catris uses Apple's native 3D Metal engine (`SceneKit` + custom Metal shaders + `SwiftUI`) paired with a pure-Swift `CatrisCore` logic package and a deterministic `.NET 9` 3D organic sculpting asset pipeline (`tools/CatrisAssetBuilder`).

## Building `Catris-unsigned.ipa`

### Automated GitHub Actions Workflow
Trigger [`.github/workflows/build-ios-ipa.yml`](.github/workflows/build-ios-ipa.yml) automatically on push to `main` or manually via **Actions → Build Catris iOS Unsigned IPA → Run workflow**:
1. Runs `swift test` on `CatrisCore` (verifying all 60 boards, 4× rotation invariants, overlap/self-occupancy rules, undo, solver-aware hints, and save corruption recovery).
2. Generates `Catris.xcodeproj` via `xcodegen generate --spec project.yml`.
3. Archives Release `iphoneos` (`arm64`) with code signing disabled.
4. Runs `scripts/package-unsigned-ipa.sh` to validate `iPhoneOS` (device Mach-O, NOT Simulator), `arm64`, Portrait-only orientation, bundled assets, unsigned state, and outputs:
   - `Catris-unsigned.ipa`
   - `Catris-unsigned.ipa.sha256`
   - `build-report.json`

### Re-Signing for a Physical iPhone
`Catris-unsigned.ipa` is an **unsigned** ARM64 iOS device archive. To install it onto an iPhone, re-sign it with your own Apple Developer certificate & provisioning profile (e.g., via Xcode, AltStore, Sideloadly, or `codesign`). Note that CI bundle validation confirms structural/binary validity and does not replace runtime testing on a physical iPhone.

## Regenerating 3D Assets or Levels Locally
```powershell
# Re-verify and export all 60 mathematical puzzle boards
py tools/verify_levels.py

# Re-sculpt all 12 organic 3D cats, 15 props, 5-map PBR textures, gobos, audio & QA renders
dotnet run --project tools/CatrisAssetBuilder/CatrisAssetBuilder.csproj -c Release -- .
```
