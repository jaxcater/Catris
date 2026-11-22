import SceneKit

/// Production Metal SCNShaderModifiers for Catris 3D runtime.
/// All uniforms use scalar float arguments for 100% deterministic Metal binding across iOS versions.
enum MetalShaderModifiers {

    /// Organic soft-body liquid cat deformation:
    /// - `_geometry.color.r`: spineT (0 at head -> 1 at tail)
    /// - `_geometry.color.g`: tailWeight (0 body -> 1 tail tip)
    /// - `_geometry.color.b`: breathWeight (0 resting contact -> 1 chest/back dome)
    /// - `_geometry.color.a`: headWeight (1 head -> 0 torso)
    static let catSoftBodyGeometry: String = """
    #pragma arguments
    float u_breathPhase;
    float u_breathAmp;
    float u_squash;
    float u_bendX;
    float u_bendZ;
    float u_tailAmp;
    float u_reduceMotion;

    #pragma body
    float motionScale = (u_reduceMotion > 0.5) ? 0.25 : 1.0;
    float spineT   = _geometry.color.r;
    float tailW    = _geometry.color.g;
    float breathW  = _geometry.color.b;
    float headW    = _geometry.color.a;

    float3 pos = _geometry.position.xyz;

    // 1. Cozy idle chest breathing (grounded paws stay locked to rug!)
    float breathWave = sin(scn_frame.time * 1.45 + u_breathPhase) * u_breathAmp * motionScale;
    pos.y += breathWave * breathW * 0.014;
    pos.xz *= (1.0 + breathWave * breathW * 0.018);

    // 2. Volume-preserving squash & stretch on pickup / drop settle / petting
    float s = clamp(u_squash * motionScale, -0.22, 0.22);
    float yScale = 1.0 - s;
    float xzScale = 1.0 / sqrt(max(0.55, yScale));
    pos.y *= yScale;
    pos.x *= mix(1.0, xzScale, smoothstep(0.005, 0.055, _geometry.position.y));
    pos.z *= mix(1.0, xzScale, smoothstep(0.005, 0.055, _geometry.position.y));

    // 3. Soft liquid-cat lag bend during drag/rotation (belly & tail trail gracefully!)
    float bendFactor = (0.35 + 0.65 * spineT) * (0.25 + 0.75 * smoothstep(0.004, 0.06, _geometry.position.y));
    pos.x += u_bendX * bendFactor * motionScale;
    pos.z += u_bendZ * bendFactor * motionScale;

    // 4. Organic subtle tail sway & ear/head micro-bob
    float tailSway = sin(scn_frame.time * 2.1 + u_breathPhase * 1.7) * u_tailAmp * tailW * motionScale;
    pos.x += tailSway * 0.012;
    pos.z += cos(scn_frame.time * 1.8 + u_breathPhase) * u_tailAmp * tailW * 0.006 * motionScale;
    pos.y += sin(scn_frame.time * 0.9 + u_breathPhase) * headW * 0.0018 * motionScale;

    _geometry.position.xyz = pos;
    """

    /// Stylized soft matte-satin storybook shading + grazing rim + animated red-black warning stripes (matches Game.mp4!).
    static let catSurfaceAndWarning: String = """
    #pragma arguments
    float u_invalidMix;
    float u_hintPulse;
    float u_rimDarken;

    #pragma body
    float3 V = normalize(_surface.view);
    float3 N = normalize(_surface.normal);
    float ndotv = saturate(dot(N, V));

    // Soft warm storybook dark-ink silhouette edge (subtle at grazing angles so silhouettes pop like Game.mp4!)
    float edgeInk = smoothstep(0.08, 0.42, ndotv);
    float rimWarm = pow(1.0 - ndotv, 2.6) * 0.14;
    float3 baseCol = _surface.diffuse.rgb * mix(1.0 - u_rimDarken, 1.0, edgeInk) + float3(1.0, 0.94, 0.85) * rimWarm;

    // Optional soft golden hint shimmer
    if (u_hintPulse > 0.01) {
        float pulse = 0.5 + 0.5 * sin(scn_frame.time * 4.5);
        baseCol = mix(baseCol, float3(1.0, 0.88, 0.48), u_hintPulse * (0.18 + 0.16 * pulse));
    }

    // Animated diagonal red-and-black warning stripes when hovering/dropping on invalid cell!
    if (u_invalidMix > 0.01) {
        float diag = (_surface.position.x + _surface.position.y) * 14.5 - scn_frame.time * 3.1;
        float stripe = step(0.5, fract(diag));
        float3 redCol = float3(0.92, 0.21, 0.25);
        float3 blkCol = float3(0.13, 0.10, 0.12);
        float3 warn = mix(blkCol, redCol, stripe);
        baseCol = mix(baseCol, warn, u_invalidMix * 0.82);
    }

    _surface.diffuse.rgb = baseCol;
    """

    /// Inverted-hull silhouette white sticker outline! Runs the EXACT same soft-body deformation
    /// so the crisp warm-white outline hugs the bending cat silhouette smoothly!
    static let whiteOutlineGeometry: String = """
    #pragma arguments
    float u_breathPhase;
    float u_breathAmp;
    float u_squash;
    float u_bendX;
    float u_bendZ;
    float u_tailAmp;
    float u_reduceMotion;
    float u_outlineWidth;

    #pragma body
    float motionScale = (u_reduceMotion > 0.5) ? 0.25 : 1.0;
    float spineT   = _geometry.color.r;
    float tailW    = _geometry.color.g;
    float breathW  = _geometry.color.b;
    float headW    = _geometry.color.a;

    float3 pos = _geometry.position.xyz + normalize(_geometry.normal) * u_outlineWidth;

    float breathWave = sin(scn_frame.time * 1.45 + u_breathPhase) * u_breathAmp * motionScale;
    pos.y += breathWave * breathW * 0.014;
    pos.xz *= (1.0 + breathWave * breathW * 0.018);

    float s = clamp(u_squash * motionScale, -0.22, 0.22);
    float yScale = 1.0 - s;
    float xzScale = 1.0 / sqrt(max(0.55, yScale));
    pos.y *= yScale;
    pos.x *= mix(1.0, xzScale, smoothstep(0.005, 0.055, _geometry.position.y));
    pos.z *= mix(1.0, xzScale, smoothstep(0.005, 0.055, _geometry.position.y));

    float bendFactor = (0.35 + 0.65 * spineT) * (0.25 + 0.75 * smoothstep(0.004, 0.06, _geometry.position.y));
    pos.x += u_bendX * bendFactor * motionScale;
    pos.z += u_bendZ * bendFactor * motionScale;

    float tailSway = sin(scn_frame.time * 2.1 + u_breathPhase * 1.7) * u_tailAmp * tailW * motionScale;
    pos.x += tailSway * 0.012;
    pos.z += cos(scn_frame.time * 1.8 + u_breathPhase) * u_tailAmp * tailW * 0.006 * motionScale;
    pos.y += sin(scn_frame.time * 0.9 + u_breathPhase) * headW * 0.0018 * motionScale;

    _geometry.position.xyz = pos;
    """

    /// Environmental Wind Sway for 3D Monstera plants, vines, and pleated linen curtains!
    /// `_geometry.color.r` = anchored wind weight (0 at stem/curtain rod -> 1 at leaf tip/curtain hem).
    /// `_geometry.color.g` = per-leaf/pleat phase variation so foliage NEVER moves in unison!
    static let windSwayGeometry: String = """
    #pragma arguments
    float u_windStrength;
    float u_windSpeed;
    float u_reduceMotion;

    #pragma body
    float w = _geometry.color.r;
    float ph = _geometry.color.g * 6.2831;
    float m = (u_reduceMotion > 0.5) ? 0.15 : 1.0;
    float t = scn_frame.time * u_windSpeed;
    float gust = 0.65 * sin(t + ph) + 0.35 * sin(t * 0.43 + ph * 0.5);
    float ripple = sin(t * 1.85 + _geometry.position.x * 8.0 + ph) * 0.25;
    _geometry.position.x += (gust + ripple) * u_windStrength * w * m;
    _geometry.position.y += sin(t * 0.8 + ph) * u_windStrength * 0.35 * w * m;
    """

    /// Rainy window glass droplets & trails for Map 4 (Ô Cửa Ngày Mưa) — strictly on the top window pane!
    static let rainGlassFragment: String = """
    #pragma body
    float2 uv = _surface.diffuseTexcoord;
    float t = scn_frame.time * 0.65;
    float2 grid = float2(14.0, 6.0);
    float2 gv = fract(uv * grid) - 0.5;
    float2 id = floor(uv * grid);
    float n = fract(sin(dot(id, float2(127.1, 311.7))) * 43758.5453);
    float yDrop = fract(t * (0.45 + n * 0.55) + n) - 0.5;
    float xWiggle = sin(uv.y * 20.0 + n * 6.28) * 0.12;
    float d = length(gv - float2(xWiggle, yDrop));
    float drop = smoothstep(0.14, 0.05, d);
    float trail = smoothstep(0.06, 0.015, abs(gv.x - xWiggle)) * smoothstep(yDrop + 0.38, yDrop, gv.y) * smoothstep(yDrop - 0.04, yDrop, gv.y) * 0.35;
    float wet = saturate(drop + trail);
    _output.color.rgb = mix(_output.color.rgb, float3(0.84, 0.91, 0.98), wet * 0.55);
    _output.color.a = clamp(0.32 + wet * 0.42, 0.0, 0.85);
    """
}
