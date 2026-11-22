using System.Text.Json;

namespace CatrisAssetBuilder;

public sealed record CatAnchorRecord(
    string Id,
    float[] HeadPos,
    float[] LeftEyePos,
    float[] RightEyePos,
    float[] EyeNormal,
    float[] NosePos,
    float[] LeftWhiskerPos,
    float[] RightWhiskerPos,
    float[] ZzzPos,
    float FaceYawDeg,
    float EyeSpacing,
    float EyeRadius,
    string EyeStyle,       // "round_gold", "sleepy_amber", "happy_calico", "chill_dark", "big_blue", "emerald", "sky"
    string EyeColorHex,
    bool HasFangs,
    bool HasBlep,
    bool HasFishPlushie,
    float[]? FishPos,
    bool HasEarBow,
    float[]? BowPos,
    float[] BoundsMin,
    float[] BoundsMax
);

public static class CatSculptor
{
    public const float Cell = 0.25f;

    private readonly record struct SpineNode(float X, float Z, float RX, float H);

    private sealed class CatBuildSpec
    {
        public required string Id;
        public required (int c, int r)[] Cells;
        public required SpineNode[] Spine;
        public required Vec2 HeadXZ;
        public float HeadRadius = 0.092f;
        public float HeadHeight = 0.108f;
        public float FaceYawDeg = 0f; // 0 = looking toward +Z (down/forward on portrait screen), ears at -Z!
        public required Vec2[] TailPts;
        public float TailRadius = 0.042f;
        public (Vec2 a, Vec2 b, float r)[] Paws = [];
        public bool FluffyTufts = false;
        public bool RoyalMane = false;
        public string EyeStyle = "round_gold";
        public string EyeColorHex = "#F7C948";
        public bool HasFangs = false;
        public bool HasBlep = false;
        public bool HasFishPlushie = false;
        public Vec2 FishOffset = new(0, 0);
        public bool HasEarBow = false;
        public required Action<Canvas2D, Func<float, float, Vec2>, CatBuildSpec> PaintCoat;
    }

    private static Vec2 CellCenter((int c, int r)[] cells, int c, int r)
    {
        int maxC = cells.Max(p => p.c);
        int maxR = cells.Max(p => p.r);
        float cx = maxC * 0.5f * Cell;
        float cz = -maxR * 0.5f * Cell;
        return new Vec2(c * Cell - cx, -r * Cell - cz);
    }

    private static CatBuildSpec[] GetAllCatSpecs()
    {
        return
        [
            // 1. CAT-01 Nori: 1x4 Long Black Void Cat w/ cute white fangs (exact match to Game.mp4!)
            new CatBuildSpec
            {
                Id = "nori",
                Cells = [(0,0),(0,1),(0,2),(0,3)],
                HeadXZ = new Vec2(0f, -0.355f),
                HeadRadius = 0.098f, HeadHeight = 0.108f, FaceYawDeg = 0f,
                Spine = [
                    new(0f, -0.35f, 0.096f, 0.104f),
                    new(0f, -0.15f, 0.098f, 0.102f),
                    new(0f,  0.10f, 0.102f, 0.104f),
                    new(0f,  0.34f, 0.098f, 0.100f),
                ],
                TailPts = [new(0f, 0.37f), new(-0.045f, 0.425f), new(0.03f, 0.445f)],
                TailRadius = 0.032f,
                Paws = [
                    (new(-0.072f, -0.16f), new(-0.102f, -0.13f), 0.024f),
                    (new( 0.072f, -0.16f), new( 0.102f, -0.13f), 0.024f),
                    (new(-0.075f,  0.22f), new(-0.102f,  0.25f), 0.024f),
                    (new( 0.075f,  0.22f), new( 0.102f,  0.25f), 0.024f),
                ],
                EyeStyle = "round_gold", EyeColorHex = "#F7C948", HasFangs = true,
                PaintCoat = (cv, worldToUv, spec) =>
                {
                    var baseCol = RGBA.FromHex("#24242B");
                    var softSheen = RGBA.FromHex("#33323C");
                    var belly = RGBA.FromHex("#2D2C36");
                    var earPink = RGBA.FromHex("#D68B93");
                    cv.FillFunc((u, v) =>
                    {
                        float n = (Noise2D.Fbm(u * 26f, v * 26f, 3, 11) - 0.5f) * 0.035f;
                        float grad = 1f - 0.10f * v;
                        return new RGBA(
                            SdfMath.Clamp(baseCol.R * grad + n, 0, 1),
                            SdfMath.Clamp(baseCol.G * grad + n, 0, 1),
                            SdfMath.Clamp(baseCol.B * grad + n, 0, 1));
                    });
                    // Soft subtle satin back highlight + velvety sheen
                    var mid = worldToUv(0f, 0.02f);
                    cv.PaintSoftCircle(mid.X, mid.Y, 0.16f, 0.32f, new RGBA(softSheen.R, softSheen.G, softSheen.B, 0.55f), 0.5f);
                    var bPos = worldToUv(0f, 0.12f);
                    cv.PaintSoftCircle(bPos.X, bPos.Y, 0.12f, 0.22f, new RGBA(belly.R, belly.G, belly.B, 0.4f), 0.4f);
                    PaintEars(cv, worldToUv, spec, earPink);
                }
            },

            // 2. CAT-02 Sumi: Fluffy Dark Chocolate-Brown L-Cat w/ spiky head tufts & pink toe beans!
            new CatBuildSpec
            {
                Id = "sumi",
                Cells = [(0,0),(1,0),(0,1),(0,2)],
                HeadXZ = new Vec2(-0.125f, -0.245f),
                HeadRadius = 0.098f, HeadHeight = 0.112f, FaceYawDeg = 0f,
                FluffyTufts = true,
                Spine = [
                    new(-0.125f, -0.23f, 0.096f, 0.108f),
                    new(-0.125f,  0.00f, 0.102f, 0.104f),
                    new(-0.120f,  0.22f, 0.104f, 0.102f),
                    new( 0.035f,  0.255f, 0.092f, 0.092f),
                ],
                TailPts = [new(0.05f, 0.26f), new(0.165f, 0.255f), new(0.185f, 0.185f), new(0.115f, 0.175f)],
                TailRadius = 0.045f,
                Paws = [
                    (new(-0.165f, -0.05f), new(-0.135f,  0.02f), 0.026f),
                    (new(-0.085f, -0.05f), new(-0.105f,  0.02f), 0.026f),
                    (new( 0.075f,  0.21f), new( 0.125f,  0.205f), 0.030f),
                ],
                EyeStyle = "sleepy_amber", EyeColorHex = "#F08C3A",
                PaintCoat = (cv, worldToUv, spec) =>
                {
                    var cocoa = RGBA.FromHex("#4E423D");
                    var warm = RGBA.FromHex("#65554D");
                    var dark = RGBA.FromHex("#3A302C");
                    var pink = RGBA.FromHex("#E28E9C");
                    cv.FillFunc((u, v) =>
                    {
                        float n = (Noise2D.Fbm(u * 28f, v * 28f, 3, 22) - 0.5f) * 0.05f;
                        return new RGBA(
                            SdfMath.Clamp(cocoa.R + n, 0, 1),
                            SdfMath.Clamp(cocoa.G + n, 0, 1),
                            SdfMath.Clamp(cocoa.B + n, 0, 1));
                    });
                    var belly = worldToUv(-0.125f, 0.04f);
                    cv.PaintSoftCircle(belly.X, belly.Y, 0.14f, 0.22f, new RGBA(warm.R, warm.G, warm.B, 0.55f), 0.45f);
                    // Darker tail tip
                    var tt = worldToUv(0.13f, 0.19f);
                    cv.PaintSoftCircle(tt.X, tt.Y, 0.11f, 0.11f, new RGBA(dark.R, dark.G, dark.B, 0.45f), 0.45f);
                    // Cute pink toe beans on curled hind paw!
                    PaintToeBeans(cv, worldToUv(0.11f, 0.205f), pink);
                    PaintEars(cv, worldToUv, spec, RGBA.FromHex("#C87D84"));
                }
            },

            // 3. CAT-03 Pudding: Calico Z-Cat hugging a cute 3D Sky-Blue Fish Plushie + pink blep!
            new CatBuildSpec
            {
                Id = "pudding",
                Cells = [(0,2),(0,1),(1,1),(1,0)],
                HeadXZ = new Vec2(-0.125f, -0.245f),
                HeadRadius = 0.098f, HeadHeight = 0.110f, FaceYawDeg = 0f,
                Spine = [
                    new(-0.125f, -0.23f, 0.096f, 0.106f),
                    new(-0.115f, -0.02f, 0.102f, 0.104f),
                    new( 0.085f,  0.01f, 0.104f, 0.102f),
                    new( 0.135f,  0.17f, 0.092f, 0.094f),
                ],
                TailPts = [new(0.145f, 0.20f), new(0.145f, 0.295f), new(0.065f, 0.305f), new(0.050f, 0.235f)],
                TailRadius = 0.042f,
                Paws = [
                    (new(-0.185f, -0.07f), new(-0.145f, -0.05f), 0.028f),
                    (new(-0.055f, -0.07f), new(-0.095f, -0.05f), 0.028f),
                ],
                EyeStyle = "happy_calico", EyeColorHex = "#3A2C28", HasBlep = true,
                HasFishPlushie = true, FishOffset = new Vec2(-0.125f, -0.085f),
                PaintCoat = (cv, worldToUv, spec) =>
                {
                    var cream = RGBA.FromHex("#FBF6ED");
                    var ginger = RGBA.FromHex("#E48C3C");
                    var dark = RGBA.FromHex("#332D30");
                    var earPink = RGBA.FromHex("#F2A8AE");
                    cv.FillFunc((u, v) =>
                    {
                        float n = (Noise2D.Fbm(u * 24f, v * 24f, 3, 33) - 0.5f) * 0.025f;
                        return new RGBA(
                            SdfMath.Clamp(cream.R + n, 0, 1),
                            SdfMath.Clamp(cream.G + n, 0, 1),
                            SdfMath.Clamp(cream.B + n, 0, 1));
                    });
                    // Calico patches matching Game.mp4!
                    var p1 = worldToUv(-0.05f, -0.26f); // dark right ear & eye patch
                    cv.PaintSoftCircle(p1.X, p1.Y, 0.11f, 0.10f, dark, 0.14f);
                    var p2 = worldToUv(-0.18f, -0.30f); // warm ginger left ear
                    cv.PaintSoftCircle(p2.X, p2.Y, 0.08f, 0.08f, ginger, 0.14f);
                    var p3 = worldToUv(0.05f, -0.06f); // ginger saddle patch
                    cv.PaintSoftCircle(p3.X, p3.Y, 0.12f, 0.10f, ginger, 0.16f);
                    var p4 = worldToUv(-0.06f, 0.04f); // dark spot near chest
                    cv.PaintSoftCircle(p4.X, p4.Y, 0.085f, 0.08f, dark, 0.14f);
                    var p5 = worldToUv(0.14f, 0.12f); // warm brown-ginger hip
                    cv.PaintSoftCircle(p5.X, p5.Y, 0.12f, 0.14f, RGBA.FromHex("#9D5A36"), 0.16f);
                    var p6 = worldToUv(0.13f, 0.28f); // ginger tail ring
                    cv.PaintSoftCircle(p6.X, p6.Y, 0.08f, 0.07f, ginger, 0.15f);
                    PaintEars(cv, worldToUv, spec, earPink);
                }
            },

            // 4. CAT-04 Mochi: Silver-Gray Tabby L-Tromino w/ stretched paws & spiral tail!
            new CatBuildSpec
            {
                Id = "mochi",
                Cells = [(1,0),(0,1),(1,1)],
                HeadXZ = new Vec2(0.115f, -0.120f),
                HeadRadius = 0.096f, HeadHeight = 0.106f, FaceYawDeg = 90f, // face looking left toward stretched paws!
                Spine = [
                    new( 0.115f, -0.11f, 0.095f, 0.104f),
                    new( 0.125f,  0.07f, 0.102f, 0.102f),
                    new( 0.115f,  0.16f, 0.094f, 0.096f),
                ],
                TailPts = [new(0.11f, 0.17f), new(0.175f, 0.195f), new(0.18f, 0.12f), new(0.135f, 0.11f)],
                TailRadius = 0.046f,
                Paws = [
                    // Stretched adorable front paws reaching left into (0,1)!
                    (new(0.05f, -0.175f), new(-0.175f, -0.175f), 0.036f),
                    (new(0.05f, -0.070f), new(-0.175f, -0.070f), 0.036f),
                ],
                EyeStyle = "chill_dark", EyeColorHex = "#2F3036",
                PaintCoat = (cv, worldToUv, spec) =>
                {
                    var silver = RGBA.FromHex("#D4D0C8");
                    var stripe = RGBA.FromHex("#9C9890");
                    var pink = RGBA.FromHex("#EB9BA6");
                    cv.FillFunc((u, v) =>
                    {
                        float n = (Noise2D.Fbm(u * 25f, v * 25f, 3, 44) - 0.5f) * 0.03f;
                        // Gentle curved silver tabby stripes!
                        float wave = MathF.Sin((v * 14f + MathF.Sin(u * 6f) * 0.45f) * MathF.PI);
                        float s = SdfMath.SmoothStep(0.35f, 0.85f, wave) * 0.42f;
                        var c = RGBA.Lerp(silver, stripe, s);
                        return new RGBA(SdfMath.Clamp(c.R + n, 0, 1), SdfMath.Clamp(c.G + n, 0, 1), SdfMath.Clamp(c.B + n, 0, 1));
                    });
                    PaintToeBeans(cv, worldToUv(-0.175f, -0.175f), pink);
                    PaintToeBeans(cv, worldToUv(-0.175f, -0.070f), pink);
                    PaintEars(cv, worldToUv, spec, RGBA.FromHex("#E2A4AC"));
                }
            },

            // 5. CAT-05 Miso: 1x1 Chubby Ginger Loaf w/ big expressive blue eyes & tabby M!
            new CatBuildSpec
            {
                Id = "miso",
                Cells = [(0,0)],
                HeadXZ = new Vec2(0f, -0.015f),
                HeadRadius = 0.096f, HeadHeight = 0.114f, FaceYawDeg = 0f,
                Spine = [
                    new(0f, -0.025f, 0.098f, 0.112f),
                    new(0f,  0.035f, 0.096f, 0.106f),
                ],
                TailPts = [new(0.055f, 0.065f), new(0.102f, 0.025f), new(0.095f, -0.035f)],
                TailRadius = 0.026f,
                Paws = [
                    (new(-0.048f, 0.062f), new(-0.048f, 0.088f), 0.024f),
                    (new( 0.048f, 0.062f), new( 0.048f, 0.088f), 0.024f),
                ],
                EyeStyle = "big_blue", EyeColorHex = "#4B8CEB",
                PaintCoat = (cv, worldToUv, spec) =>
                {
                    var ginger = RGBA.FromHex("#EE9E42");
                    var stripe = RGBA.FromHex("#C46B24");
                    var cream = RGBA.FromHex("#FCE8C8");
                    cv.FillFunc((u, v) =>
                    {
                        float n = (Noise2D.Fbm(u * 24f, v * 24f, 3, 55) - 0.5f) * 0.035f;
                        return new RGBA(SdfMath.Clamp(ginger.R + n, 0, 1), SdfMath.Clamp(ginger.G + n, 0, 1), SdfMath.Clamp(ginger.B + n, 0, 1));
                    });
                    // Cute cream chin & forehead tabby stripes!
                    var chin = worldToUv(0f, 0.035f);
                    cv.PaintSoftCircle(chin.X, chin.Y, 0.22f, 0.16f, cream, 0.45f);
                    for (int k = -1; k <= 1; k++)
                    {
                        var a = worldToUv(k * 0.024f, -0.075f);
                        var b = worldToUv(k * 0.020f, -0.035f);
                        cv.PaintCapsule(a.X, a.Y, b.X, b.Y, 0.022f, stripe, 0.015f);
                    }
                    PaintEars(cv, worldToUv, spec, RGBA.FromHex("#F4A8A4"));
                }
            },

            // 6. CAT-06 Yuzu: 1x2 Cream Siamese Napper
            new CatBuildSpec
            {
                Id = "yuzu",
                Cells = [(0,0),(1,0)],
                HeadXZ = new Vec2(-0.12f, 0f),
                HeadRadius = 0.094f, HeadHeight = 0.106f, FaceYawDeg = 0f,
                Spine = [
                    new(-0.12f, 0f, 0.095f, 0.105f),
                    new( 0.02f, 0f, 0.098f, 0.102f),
                    new( 0.14f, 0f, 0.090f, 0.096f),
                ],
                TailPts = [new(0.16f, 0.02f), new(0.21f, -0.04f), new(0.17f, -0.085f)],
                TailRadius = 0.032f,
                Paws = [
                    (new(-0.16f, 0.06f), new(-0.14f, 0.09f), 0.024f),
                    (new(-0.07f, 0.06f), new(-0.08f, 0.09f), 0.024f),
                ],
                EyeStyle = "sky", EyeColorHex = "#5BA8E6",
                PaintCoat = (cv, worldToUv, spec) =>
                {
                    var cream = RGBA.FromHex("#F2E5D2");
                    var choc = RGBA.FromHex("#6B4F40");
                    cv.FillFunc((u, v) =>
                    {
                        float n = (Noise2D.Fbm(u * 26f, v * 26f, 3, 66) - 0.5f) * 0.025f;
                        return new RGBA(SdfMath.Clamp(cream.R + n, 0, 1), SdfMath.Clamp(cream.G + n, 0, 1), SdfMath.Clamp(cream.B + n, 0, 1));
                    });
                    // Classic Siamese chocolate mask + tail point!
                    var face = worldToUv(-0.12f, 0.01f);
                    cv.PaintSoftCircle(face.X, face.Y, 0.15f, 0.16f, new RGBA(choc.R, choc.G, choc.B, 0.85f), 0.45f);
                    var tail = worldToUv(0.18f, -0.04f);
                    cv.PaintSoftCircle(tail.X, tail.Y, 0.12f, 0.14f, choc, 0.4f);
                    PaintEars(cv, worldToUv, spec, RGBA.FromHex("#523A2E"));
                }
            },

            // 7. CAT-07 Matcha: 1x3 Russian Blue Sleek Lounger w/ cozy mint knit scarf!
            new CatBuildSpec
            {
                Id = "matcha",
                Cells = [(0,0),(1,0),(2,0)],
                HeadXZ = new Vec2(-0.24f, 0f),
                HeadRadius = 0.095f, HeadHeight = 0.106f, FaceYawDeg = 0f,
                Spine = [
                    new(-0.24f, 0f, 0.094f, 0.104f),
                    new(-0.04f, 0f, 0.098f, 0.102f),
                    new( 0.14f, 0f, 0.098f, 0.100f),
                    new( 0.27f, 0f, 0.088f, 0.094f),
                ],
                TailPts = [new(0.28f, 0.02f), new(0.34f, -0.04f), new(0.29f, -0.085f)],
                TailRadius = 0.032f,
                Paws = [
                    (new(-0.28f, 0.06f), new(-0.26f, 0.09f), 0.024f),
                    (new(-0.19f, 0.06f), new(-0.20f, 0.09f), 0.024f),
                ],
                EyeStyle = "emerald", EyeColorHex = "#72C489",
                PaintCoat = (cv, worldToUv, spec) =>
                {
                    var blue = RGBA.FromHex("#7E8E9E");
                    var mint = RGBA.FromHex("#9EE0C2");
                    var mintDark = RGBA.FromHex("#79C2A1");
                    cv.FillFunc((u, v) =>
                    {
                        float n = (Noise2D.Fbm(u * 26f, v * 26f, 3, 77) - 0.5f) * 0.03f;
                        return new RGBA(SdfMath.Clamp(blue.R + n, 0, 1), SdfMath.Clamp(blue.G + n, 0, 1), SdfMath.Clamp(blue.B + n, 0, 1));
                    });
                    // Cute mint knit scarf around neck!
                    var s0 = worldToUv(-0.14f, -0.10f);
                    var s1 = worldToUv(-0.14f,  0.10f);
                    cv.PaintCapsule(s0.X, s0.Y, s1.X, s1.Y, 0.042f, mint, 0.01f);
                    cv.PaintCapsule(s0.X + 0.01f, s0.Y, s1.X + 0.01f, s1.Y, 0.012f, mintDark, 0.008f);
                    PaintEars(cv, worldToUv, spec, RGBA.FromHex("#C7A3AE"));
                }
            },

            // 8. CAT-08 Sesame: 2x2 Mega-Chonk Tuxedo Cloud!
            new CatBuildSpec
            {
                Id = "sesame",
                Cells = [(0,0),(1,0),(0,1),(1,1)],
                HeadXZ = new Vec2(0f, -0.12f),
                HeadRadius = 0.118f, HeadHeight = 0.125f, FaceYawDeg = 0f,
                FluffyTufts = true,
                Spine = [
                    new(-0.09f, -0.10f, 0.122f, 0.122f),
                    new( 0.09f, -0.10f, 0.122f, 0.122f),
                    new( 0.10f,  0.10f, 0.124f, 0.118f),
                    new(-0.10f,  0.10f, 0.124f, 0.118f),
                    new( 0.00f,  0.00f, 0.165f, 0.126f),
                ],
                TailPts = [new(0.14f, 0.14f), new(0.21f, 0.08f), new(0.20f, -0.05f)],
                TailRadius = 0.045f,
                Paws = [
                    (new(-0.12f, 0.16f), new(-0.10f, 0.21f), 0.034f),
                    (new( 0.12f, 0.16f), new( 0.10f, 0.21f), 0.034f),
                ],
                EyeStyle = "round_gold", EyeColorHex = "#F5C64F",
                PaintCoat = (cv, worldToUv, spec) =>
                {
                    var tux = RGBA.FromHex("#2B2D36");
                    var white = RGBA.FromHex("#FAF7F2");
                    var redBow = RGBA.FromHex("#E4686A");
                    cv.FillFunc((u, v) =>
                    {
                        float n = (Noise2D.Fbm(u * 24f, v * 24f, 3, 88) - 0.5f) * 0.03f;
                        return new RGBA(SdfMath.Clamp(tux.R + n, 0, 1), SdfMath.Clamp(tux.G + n, 0, 1), SdfMath.Clamp(tux.B + n, 0, 1));
                    });
                    // Classic fluffy white tuxedo chest bib + white paws + tiny red bowtie!
                    var bib = worldToUv(0f, 0.06f);
                    cv.PaintSoftCircle(bib.X, bib.Y, 0.20f, 0.22f, white, 0.12f);
                    var bow = worldToUv(0f, -0.01f);
                    cv.PaintSoftCircle(bow.X - 0.04f, bow.Y, 0.045f, 0.03f, redBow, 0.12f);
                    cv.PaintSoftCircle(bow.X + 0.04f, bow.Y, 0.045f, 0.03f, redBow, 0.12f);
                    PaintEars(cv, worldToUv, spec, RGBA.FromHex("#E29AA4"));
                }
            },

            // 9. CAT-09 Kinako: T-Tetromino Honey Tabby Sploot!
            new CatBuildSpec
            {
                Id = "kinako",
                Cells = [(0,0),(1,0),(2,0),(1,1)],
                HeadXZ = new Vec2(0f, -0.125f),
                HeadRadius = 0.098f, HeadHeight = 0.110f, FaceYawDeg = 0f,
                Spine = [
                    new( 0.00f, -0.12f, 0.096f, 0.106f),
                    new( 0.00f,  0.11f, 0.104f, 0.104f),
                    new(-0.24f,  0.12f, 0.092f, 0.094f),
                    new( 0.24f,  0.12f, 0.092f, 0.094f),
                ],
                TailPts = [new(0.22f, 0.12f), new(0.32f, 0.16f), new(0.32f, 0.07f)],
                TailRadius = 0.038f,
                Paws = [
                    (new(-0.08f, 0.12f), new(-0.30f, 0.12f), 0.052f),
                    (new( 0.08f, 0.12f), new( 0.30f, 0.12f), 0.052f),
                ],
                EyeStyle = "emerald", EyeColorHex = "#62A85A",
                PaintCoat = (cv, worldToUv, spec) =>
                {
                    var honey = RGBA.FromHex("#DBA56B");
                    var stripe = RGBA.FromHex("#9A6536");
                    var cream = RGBA.FromHex("#FCEFD9");
                    cv.FillFunc((u, v) =>
                    {
                        float n = (Noise2D.Fbm(u * 25f, v * 25f, 3, 99) - 0.5f) * 0.03f;
                        float s = SdfMath.SmoothStep(0.35f, 0.85f, MathF.Sin(u * 18f * MathF.PI)) * 0.35f;
                        var c = RGBA.Lerp(honey, stripe, s);
                        return new RGBA(SdfMath.Clamp(c.R + n, 0, 1), SdfMath.Clamp(c.G + n, 0, 1), SdfMath.Clamp(c.B + n, 0, 1));
                    });
                    var lp = worldToUv(-0.28f, 0.12f);
                    var rp = worldToUv( 0.28f, 0.12f);
                    cv.PaintSoftCircle(lp.X, lp.Y, 0.09f, 0.12f, cream, 0.25f);
                    cv.PaintSoftCircle(rp.X, rp.Y, 0.09f, 0.12f, cream, 0.25f);
                    PaintEars(cv, worldToUv, spec, RGBA.FromHex("#F0A5A2"));
                }
            },

            // 10. CAT-10 Azuki: J-Tetromino Cream Calico w/ Sky-Blue Ear Bow!
            new CatBuildSpec
            {
                Id = "azuki",
                Cells = [(0,0),(1,0),(1,1),(1,2)],
                HeadXZ = new Vec2(0.125f, -0.245f),
                HeadRadius = 0.096f, HeadHeight = 0.108f, FaceYawDeg = 0f,
                Spine = [
                    new( 0.125f, -0.23f, 0.095f, 0.106f),
                    new( 0.125f,  0.00f, 0.102f, 0.104f),
                    new( 0.115f,  0.22f, 0.102f, 0.100f),
                    new(-0.045f,  0.255f, 0.090f, 0.092f),
                ],
                TailPts = [new(-0.05f, 0.26f), new(-0.17f, 0.255f), new(-0.18f, 0.185f), new(-0.11f, 0.18f)],
                TailRadius = 0.044f,
                HasEarBow = true,
                EyeStyle = "happy_calico", EyeColorHex = "#453935",
                PaintCoat = (cv, worldToUv, spec) =>
                {
                    var cream = RGBA.FromHex("#FFF7EE");
                    var peach = RGBA.FromHex("#E8925A");
                    var cocoa = RGBA.FromHex("#59433B");
                    cv.FillFunc((u, v) =>
                    {
                        float n = (Noise2D.Fbm(u * 24f, v * 24f, 3, 101) - 0.5f) * 0.025f;
                        return new RGBA(SdfMath.Clamp(cream.R + n, 0, 1), SdfMath.Clamp(cream.G + n, 0, 1), SdfMath.Clamp(cream.B + n, 0, 1));
                    });
                    var p1 = worldToUv(0.15f, 0.04f);
                    cv.PaintSoftCircle(p1.X, p1.Y, 0.14f, 0.14f, peach, 0.16f);
                    var p2 = worldToUv(-0.12f, 0.24f);
                    cv.PaintSoftCircle(p2.X, p2.Y, 0.12f, 0.10f, cocoa, 0.16f);
                    PaintEars(cv, worldToUv, spec, RGBA.FromHex("#F5AAB2"));
                }
            },

            // 11. CAT-11 Taro: S-Tetromino Lilac-Cream Swirl Cat!
            new CatBuildSpec
            {
                Id = "taro",
                Cells = [(1,0),(0,1),(1,1),(0,2)],
                HeadXZ = new Vec2(0.125f, 0.245f), // Head at bottom-right? No, put head at (0,2) = top-left! Wait (0,2) is (-0.125, -0.25)!
                // Wait let's verify Taro cells [(1,0),(0,1),(1,1),(0,2)] -> wait:
                // (0,2) = (-0.125, -0.25) [Top-Left], (0,1) = (-0.125, 0), (1,1) = (+0.125, 0), (1,0) = (+0.125, +0.25)
                // WAIT! That's the SAME cells as Pudding! Let's check verify_levels.py!
                // In verify_levels.py:
                //   pudding = [[0, 2], [0, 1], [1, 1], [1, 0]]
                //   taro    = [[1, 0], [0, 1], [1, 1], [0, 2]] -> WAIT A SECOND!
                //   THAT'S THE SAME SET OF CELLS! Let's fix Taro to true S-mirror [[0,0],[0,1],[1,1],[1,2]]!!
                HeadRadius = 0.096f, HeadHeight = 0.108f, FaceYawDeg = 0f,
                Spine = [
                    new( 0.125f, -0.23f, 0.095f, 0.106f),
                    new( 0.115f, -0.02f, 0.102f, 0.104f),
                    new(-0.085f,  0.01f, 0.104f, 0.102f),
                    new(-0.135f,  0.17f, 0.092f, 0.094f),
                ],
                TailPts = [new(-0.145f, 0.20f), new(-0.145f, 0.295f), new(-0.065f, 0.305f), new(-0.050f, 0.235f)],
                TailRadius = 0.042f,
                EyeStyle = "sleepy_amber", EyeColorHex = "#E6A94C",
                PaintCoat = (cv, worldToUv, spec) =>
                {
                    var lilac = RGBA.FromHex("#E2D7E8");
                    var swirl = RGBA.FromHex("#AF9BB8");
                    cv.FillFunc((u, v) =>
                    {
                        float n = (Noise2D.Fbm(u * 24f, v * 24f, 3, 111) - 0.5f) * 0.025f;
                        float s = SdfMath.SmoothStep(0.3f, 0.8f, MathF.Sin((u * 8f + v * 10f) * MathF.PI)) * 0.38f;
                        var c = RGBA.Lerp(lilac, swirl, s);
                        return new RGBA(SdfMath.Clamp(c.R + n, 0, 1), SdfMath.Clamp(c.G + n, 0, 1), SdfMath.Clamp(c.B + n, 0, 1));
                    });
                    PaintEars(cv, worldToUv, spec, RGBA.FromHex("#E9A8BA"));
                }
            },

            // 12. CAT-12 Banhmi: U-Pentomino Royal Norwegian Forest King (5 cells!)
            new CatBuildSpec
            {
                Id = "banhmi",
                Cells = [(0,0),(1,0),(2,0),(0,1),(2,1)],
                HeadXZ = new Vec2(0f, 0.115f),
                HeadRadius = 0.108f, HeadHeight = 0.120f, FaceYawDeg = 0f,
                FluffyTufts = true, RoyalMane = true,
                Spine = [
                    new(-0.25f, -0.12f, 0.094f, 0.102f),
                    new(-0.25f,  0.11f, 0.104f, 0.108f),
                    new( 0.00f,  0.12f, 0.112f, 0.116f),
                    new( 0.25f,  0.11f, 0.104f, 0.108f),
                    new( 0.25f, -0.12f, 0.094f, 0.102f),
                ],
                TailPts = [new(0.25f, 0.02f), new(0.26f, -0.14f), new(0.20f, -0.18f)],
                TailRadius = 0.052f,
                Paws = [
                    (new(-0.25f, 0.04f), new(-0.25f, -0.18f), 0.056f),
                ],
                EyeStyle = "round_gold", EyeColorHex = "#E8B84B",
                PaintCoat = (cv, worldToUv, spec) =>
                {
                    var caramel = RGBA.FromHex("#C89B74");
                    var mane = RGBA.FromHex("#FFF6EA");
                    var dark = RGBA.FromHex("#8F6445");
                    cv.FillFunc((u, v) =>
                    {
                        float n = (Noise2D.Fbm(u * 26f, v * 26f, 3, 122) - 0.5f) * 0.04f;
                        float s = SdfMath.SmoothStep(0.4f, 0.85f, MathF.Sin((u * 14f + v * 6f) * MathF.PI)) * 0.25f;
                        var c = RGBA.Lerp(caramel, dark, s);
                        return new RGBA(SdfMath.Clamp(c.R + n, 0, 1), SdfMath.Clamp(c.G + n, 0, 1), SdfMath.Clamp(c.B + n, 0, 1));
                    });
                    var mPos = worldToUv(0f, 0.14f);
                    cv.PaintSoftCircle(mPos.X, mPos.Y, 0.18f, 0.22f, mane, 0.35f);
                    PaintEars(cv, worldToUv, spec, RGBA.FromHex("#EFA7A7"));
                }
            },
        ];
    }

    private static void PaintEars(Canvas2D cv, Func<float, float, Vec2> worldToUv, CatBuildSpec spec, RGBA pink)
    {
        float yaw = spec.FaceYawDeg * MathF.PI / 180f;
        float cosY = MathF.Cos(yaw), sinY = MathF.Sin(yaw);
        Vec2 LocalToWorld(float lx, float lz) => new(
            spec.HeadXZ.X + lx * cosY + lz * sinY,
            spec.HeadXZ.Y - lx * sinY + lz * cosY
        );
        var eL = LocalToWorld(-0.048f, -0.046f);
        var eR = LocalToWorld( 0.048f, -0.046f);
        var uvL = worldToUv(eL.X, eL.Y);
        var uvR = worldToUv(eR.X, eR.Y);
        cv.PaintSoftCircle(uvL.X, uvL.Y, 0.032f, 0.032f, pink, 0.25f);
        cv.PaintSoftCircle(uvR.X, uvR.Y, 0.032f, 0.032f, pink, 0.25f);
    }

    private static void PaintToeBeans(Canvas2D cv, Vec2 uv, RGBA pink)
    {
        cv.PaintSoftCircle(uv.X, uv.Y, 0.022f, 0.018f, pink, 0.15f);
        cv.PaintSoftCircle(uv.X - 0.020f, uv.Y - 0.020f, 0.010f, 0.010f, pink, 0.15f);
        cv.PaintSoftCircle(uv.X,          uv.Y - 0.026f, 0.010f, 0.010f, pink, 0.15f);
        cv.PaintSoftCircle(uv.X + 0.020f, uv.Y - 0.020f, 0.010f, 0.010f, pink, 0.15f);
    }

    private static Func<Vec3, float> BuildCatSdf(CatBuildSpec spec)
    {
        float yaw = spec.FaceYawDeg * MathF.PI / 180f;
        float cosY = MathF.Cos(yaw), sinY = MathF.Sin(yaw);
        Vec3 HeadLocal(float lx, float ly, float lz) => new(
            spec.HeadXZ.X + lx * cosY + lz * sinY,
            ly,
            spec.HeadXZ.Y - lx * sinY + lz * cosY
        );

        // Precompute crisp adorable cat ear tips & bases
        Vec3 earLBase = HeadLocal(-0.048f, spec.HeadHeight * 0.68f, -0.028f);
        Vec3 earLTip  = HeadLocal(-0.072f, spec.HeadHeight + 0.044f, -0.072f);

        Vec3 earRBase = HeadLocal( 0.048f, spec.HeadHeight * 0.68f, -0.028f);
        Vec3 earRTip  = HeadLocal( 0.072f, spec.HeadHeight + 0.044f, -0.072f);

        Vec3 cheekL = HeadLocal(-0.056f, 0.048f, 0.026f);
        Vec3 cheekR = HeadLocal( 0.056f, 0.048f, 0.026f);
        Vec3 headCenter = HeadLocal(0f, spec.HeadHeight * 0.48f, 0f);

        Vec3 tuft1 = HeadLocal( 0.000f, spec.HeadHeight + 0.026f, -0.064f);
        Vec3 tuft2 = HeadLocal(-0.024f, spec.HeadHeight + 0.020f, -0.060f);
        Vec3 tuft3 = HeadLocal( 0.024f, spec.HeadHeight + 0.020f, -0.060f);

        return p =>
        {
            float d = 10f;

            // 1. Continuous organic plush torso spine (sleek & plump, zero bumpy waist pinching!)
            for (int i = 0; i < spec.Spine.Length - 1; i++)
            {
                var a = spec.Spine[i];
                var b = spec.Spine[i + 1];
                float yA = a.H * 0.47f, yB = b.H * 0.47f;
                float seg = SdfMath.SdPlushCapsule(
                    p,
                    new Vec3(a.X, yA, a.Z),
                    new Vec3(b.X, yB, b.Z),
                    a.RX * 1.04f, b.RX * 1.04f,
                    yScale: 0.58f
                );
                d = SdfMath.SMin(d, seg, 0.046f);
            }
            if (spec.Spine.Length == 1)
            {
                var a = spec.Spine[0];
                d = SdfMath.SdEllipsoid(p, new Vec3(a.X, a.H * 0.48f, a.Z), new Vec3(a.RX, a.H * 0.56f, a.RX));
            }
            // Soft cushion fill over occupied cells (skip Mochi's outstretched-paw cell (0,1) so paws stay distinct & adorable!)
            foreach (var (c, r) in spec.Cells)
            {
                if (spec.Id == "mochi" && c == 0 && r == 1) continue;
                var cc = CellCenter(spec.Cells, c, r);
                float cushion = SdfMath.SdEllipsoid(p, new Vec3(cc.X, 0.046f, cc.Y), new Vec3(0.098f, 0.056f, 0.098f));
                d = SdfMath.SMin(d, cushion, 0.044f);
            }

            // 2. Sculpted head + chubby cheeks
            float dHead = SdfMath.SdEllipsoid(p, headCenter, new Vec3(spec.HeadRadius * 1.02f, spec.HeadHeight * 0.56f, spec.HeadRadius * 0.96f));
            dHead = SdfMath.SMin(dHead, SdfMath.SdSphere(p, cheekL, 0.048f), 0.028f);
            dHead = SdfMath.SMin(dHead, SdfMath.SdSphere(p, cheekR, 0.048f), 0.028f);
            d = SdfMath.SMin(d, dHead, 0.036f);

            // 3. Sculpted crisp organic pointed-rounded cat ears (clean smooth volume, zero dimple pinholes!)
            float dEarL = SdfMath.SdCapsule(p, earLBase, earLTip, 0.035f, 0.011f);
            float dEarR = SdfMath.SdCapsule(p, earRBase, earRTip, 0.035f, 0.011f);
            d = SdfMath.SMin(d, dEarL, 0.018f);
            d = SdfMath.SMin(d, dEarR, 0.018f);

            // Optional fluffy head tufts (Sumi & Sesame & Banhmi!)
            if (spec.FluffyTufts)
            {
                d = SdfMath.SMin(d, SdfMath.SdCapsule(p, headCenter + new Vec3(0, 0.04f, 0), tuft1, 0.020f, 0.007f), 0.010f);
                d = SdfMath.SMin(d, SdfMath.SdCapsule(p, headCenter + new Vec3(0, 0.04f, 0), tuft2, 0.017f, 0.006f), 0.010f);
                d = SdfMath.SMin(d, SdfMath.SdCapsule(p, headCenter + new Vec3(0, 0.04f, 0), tuft3, 0.017f, 0.006f), 0.010f);
            }

            // Optional royal fluffy mane ruff (Banhmi)
            if (spec.RoyalMane)
            {
                float mane = SdfMath.SdEllipsoid(p, headCenter + new Vec3(0, -0.005f, 0.02f), new Vec3(0.132f, 0.068f, 0.115f));
                d = SdfMath.SMin(d, mane, 0.025f);
            }

            // 4. Sculpted curled tail spline
            for (int i = 0; i < spec.TailPts.Length - 1; i++)
            {
                float t0 = (float)i / Math.Max(1, spec.TailPts.Length - 1);
                float t1 = (float)(i + 1) / Math.Max(1, spec.TailPts.Length - 1);
                float r0 = spec.TailRadius * (1.0f - 0.25f * t0);
                float r1 = spec.TailRadius * (1.0f - 0.25f * t1);
                var ta = new Vec3(spec.TailPts[i].X, r0 * 0.85f, spec.TailPts[i].Y);
                var tb = new Vec3(spec.TailPts[i + 1].X, r1 * 0.85f, spec.TailPts[i + 1].Y);
                d = SdfMath.SMin(d, SdfMath.SdCapsule(p, ta, tb, r0, r1), 0.018f);
            }

            // 5. Tucked / stretched paws
            foreach (var (pa, pb, pr) in spec.Paws)
            {
                float dp = SdfMath.SdPlushCapsule(
                    p,
                    new Vec3(pa.X, pr * 0.85f, pa.Y),
                    new Vec3(pb.X, pr * 0.80f, pb.Y),
                    pr, pr * 0.92f, 0.78f
                );
                d = SdfMath.SMin(d, dp, 0.014f);
            }

            // 6. Softly flattened resting belly on y = 0.003 so every cat sits plushly on the rug!
            float groundCut = 0.003f - p.Y;
            d = SdfMath.SMax(d, groundCut, 0.014f);

            return d;
        };
    }

    public static (List<CatAnchorRecord> anchors, Dictionary<string, (int verts, int tris)> qa) BuildAllCats(
        string cmeshDir, string objDir, string texDir, string dataDir)
    {
        var specs = GetAllCatSpecs();
        // Fix Taro's cells & HeadXZ cleanly to true S-chirality [(0,0),(0,1),(1,1),(1,2)]!
        // Let's patch Taro in-place cleanly:
        foreach (var s in specs)
        {
            if (s.Id == "taro")
            {
                s.Cells = [(0,0),(0,1),(1,1),(1,2)];
                s.HeadXZ = new Vec2(0.125f, -0.245f);
            }
        }

        var anchors = new List<CatAnchorRecord>();
        var qa = new Dictionary<string, (int, int)>();

        foreach (var spec in specs)
        {
            var sdf = BuildCatSdf(spec);

            // Compute exact spatial bounds from footprint + padding
            float minX = 10f, maxX = -10f, minZ = 10f, maxZ = -10f;
            foreach (var (c, r) in spec.Cells)
            {
                var cc = CellCenter(spec.Cells, c, r);
                minX = MathF.Min(minX, cc.X - 0.145f);
                maxX = MathF.Max(maxX, cc.X + 0.145f);
                minZ = MathF.Min(minZ, cc.Y - 0.145f);
                maxZ = MathF.Max(maxZ, cc.Y + 0.145f);
            }
            foreach (var tp in spec.TailPts)
            {
                minX = MathF.Min(minX, tp.X - 0.08f);
                maxX = MathF.Max(maxX, tp.X + 0.08f);
                minZ = MathF.Min(minZ, tp.Y - 0.08f);
                maxZ = MathF.Max(maxZ, tp.Y + 0.08f);
            }
            Vec3 bMin = new(minX - 0.02f, -0.01f, minZ - 0.02f);
            Vec3 bMax = new(maxX + 0.02f, spec.HeadHeight + 0.065f, maxZ + 0.02f);

            float spanX = MathF.Max(bMax.X - bMin.X, 0.25f);
            float spanZ = MathF.Max(bMax.Z - bMin.Z, 0.25f);
            Vec2 WorldToUv(float wx, float wz) => new(
                SdfMath.Clamp((wx - bMin.X) / spanX, 0.02f, 0.98f),
                SdfMath.Clamp((wz - bMin.Z) / spanZ, 0.02f, 0.98f)
            );

            // Vertex rig weights (R=spineT, G=tailWeight, B=breathWeight, A=headWeight)
            Vec2 tailEnd = spec.TailPts[^1];
            float maxBodyDist = MathF.Max(0.25f, new Vec2(tailEnd.X - spec.HeadXZ.X, tailEnd.Y - spec.HeadXZ.Y).Length);

            Vec4 RigWeights(Vec3 p)
            {
                float dHead = new Vec2(p.X - spec.HeadXZ.X, p.Z - spec.HeadXZ.Y).Length;
                float dTail = new Vec2(p.X - tailEnd.X, p.Z - tailEnd.Y).Length;
                float spineT = SdfMath.Clamp(dHead / maxBodyDist, 0f, 1f);
                float tailW = 1f - SdfMath.SmoothStep(0.03f, 0.14f, dTail);
                float breathW = SdfMath.SmoothStep(0.015f, 0.075f, p.Y) * (1f - tailW * 0.7f);
                float headW = 1f - SdfMath.SmoothStep(0.06f, 0.14f, dHead);
                return new Vec4(spineT, tailW, breathW, headW);
            }

            // Voxel step tuned for ~4,500–8,500 silky-smooth organic triangles!
            float step = spec.Cells.Length >= 5 ? 0.0125f : (spec.Cells.Length >= 4 ? 0.0115f : 0.0095f);

            var mesh = SurfaceNetsExtractor.Extract(
                sdf, bMin, bMax, step,
                p => WorldToUv(p.X, p.Z),
                RigWeights,
                smoothIterations: 4,
                snapToSdf: true
            );

            mesh.SaveCMesh(Path.Combine(cmeshDir, $"cat_{spec.Id}.cmesh"));
            mesh.SaveObj(Path.Combine(objDir, $"cat_{spec.Id}.obj"), $"mat_cat_{spec.Id}");
            qa[spec.Id] = (mesh.VertexCount, mesh.TriangleCount);

            // Paint 512x512 crisp stylized coat albedo texture!
            var canvas = new Canvas2D(512, 512, RGBA.FromHex("#FFFFFF"));
            spec.PaintCoat(canvas, WorldToUv, spec);
            canvas.SavePng(Path.Combine(texDir, $"cat_{spec.Id}_albedo.png"));

            // Raycast exact 3D facial feature anchors onto the final smoothed head surface!
            float yaw = spec.FaceYawDeg * MathF.PI / 180f;
            float cosY = MathF.Cos(yaw), sinY = MathF.Sin(yaw);
            Vec2 FacePt(float lx, float lz) => new(
                spec.HeadXZ.X + lx * cosY + lz * sinY,
                spec.HeadXZ.Y - lx * sinY + lz * cosY
            );

            float eyeSep = 0.034f;
            float eyeFwd = 0.014f;
            var (_, lEyePos, lEyeN) = SdfMath.RaycastDown(sdf, FacePt(-eyeSep, eyeFwd).X, FacePt(-eyeSep, eyeFwd).Y);
            var (_, rEyePos, rEyeN) = SdfMath.RaycastDown(sdf, FacePt( eyeSep, eyeFwd).X, FacePt( eyeSep, eyeFwd).Y);
            var (_, nosePos, _)     = SdfMath.RaycastDown(sdf, FacePt(0f, eyeFwd + 0.025f).X, FacePt(0f, eyeFwd + 0.025f).Y);
            var (_, lwPos, _)       = SdfMath.RaycastDown(sdf, FacePt(-0.072f, eyeFwd + 0.018f).X, FacePt(-0.072f, eyeFwd + 0.018f).Y);
            var (_, rwPos, _)       = SdfMath.RaycastDown(sdf, FacePt( 0.072f, eyeFwd + 0.018f).X, FacePt( 0.072f, eyeFwd + 0.018f).Y);
            Vec3 avgEyeN = (lEyeN + rEyeN).Normalized();

            float[]? fishPos = null;
            if (spec.HasFishPlushie)
            {
                var (_, fp, _) = SdfMath.RaycastDown(sdf, spec.FishOffset.X, spec.FishOffset.Y);
                fishPos = [fp.X, fp.Y + 0.018f, fp.Z];
            }
            float[]? bowPos = null;
            if (spec.HasEarBow)
            {
                var bxz = FacePt(0.055f, -0.042f);
                var (_, bp, _) = SdfMath.RaycastDown(sdf, bxz.X, bxz.Y);
                bowPos = [bp.X, bp.Y + 0.008f, bp.Z];
            }

            anchors.Add(new CatAnchorRecord(
                Id: spec.Id,
                HeadPos: [spec.HeadXZ.X, spec.HeadHeight, spec.HeadXZ.Y],
                LeftEyePos: [lEyePos.X, lEyePos.Y, lEyePos.Z],
                RightEyePos: [rEyePos.X, rEyePos.Y, rEyePos.Z],
                EyeNormal: [avgEyeN.X, avgEyeN.Y, avgEyeN.Z],
                NosePos: [nosePos.X, nosePos.Y, nosePos.Z],
                LeftWhiskerPos: [lwPos.X, lwPos.Y, lwPos.Z],
                RightWhiskerPos: [rwPos.X, rwPos.Y, rwPos.Z],
                ZzzPos: [spec.HeadXZ.X + 0.03f, spec.HeadHeight + 0.06f, spec.HeadXZ.Y - 0.06f],
                FaceYawDeg: spec.FaceYawDeg,
                EyeSpacing: eyeSep * 2f,
                EyeRadius: spec.Id == "nori" || spec.Id == "miso" || spec.Id == "sesame" ? 0.022f : 0.0195f,
                EyeStyle: spec.EyeStyle,
                EyeColorHex: spec.EyeColorHex,
                HasFangs: spec.HasFangs,
                HasBlep: spec.HasBlep,
                HasFishPlushie: spec.HasFishPlushie,
                FishPos: fishPos,
                HasEarBow: spec.HasEarBow,
                BowPos: bowPos,
                BoundsMin: [bMin.X, bMin.Y, bMin.Z],
                BoundsMax: [bMax.X, bMax.Y, bMax.Z]
            ));
        }

        // Also sculpt Pudding's adorable 3D Sky-Blue Fish Plushie & Azuki's Sky-Blue Ear Bow!
        BuildFishPlushie(cmeshDir, objDir, texDir);
        BuildEarBow(cmeshDir, objDir);

        // Write cat_anchors.json cleanly for SceneKit runtime!
        Directory.CreateDirectory(dataDir);
        var jsonOpts = new JsonSerializerOptions { WriteIndented = true, PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower };
        File.WriteAllText(Path.Combine(dataDir, "cat_anchors.json"), JsonSerializer.Serialize(anchors, jsonOpts));

        return (anchors, qa);
    }

    private static void BuildFishPlushie(string cmeshDir, string objDir, string texDir)
    {
        float FishSdf(Vec3 p)
        {
            float body = SdfMath.SdEllipsoid(p, new Vec3(-0.008f, 0f, 0f), new Vec3(0.052f, 0.024f, 0.026f));
            float tail1 = SdfMath.SdCapsule(p, new Vec3(0.035f, 0f, 0f), new Vec3(0.068f, 0f, -0.022f), 0.013f, 0.007f);
            float tail2 = SdfMath.SdCapsule(p, new Vec3(0.035f, 0f, 0f), new Vec3(0.068f, 0f,  0.022f), 0.013f, 0.007f);
            return SdfMath.SMin(body, SdfMath.SMin(tail1, tail2, 0.008f), 0.010f);
        }
        var mesh = SurfaceNetsExtractor.Extract(
            FishSdf, new Vec3(-0.08f, -0.04f, -0.045f), new Vec3(0.09f, 0.04f, 0.045f),
            0.0045f,
            p => new Vec2((p.X + 0.07f) / 0.15f, (p.Z + 0.04f) / 0.08f),
            _ => new Vec4(0, 0, 0, 1), smoothIterations: 3);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_fish_plushie.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_fish_plushie.obj"), "mat_fish");

        var cv = new Canvas2D(256, 256, RGBA.FromHex("#4AA3E8"));
        cv.PaintCapsule(0.45f, 0.25f, 0.45f, 0.75f, 0.03f, RGBA.FromHex("#79C4F7"), 0.01f);
        cv.PaintCapsule(0.60f, 0.25f, 0.60f, 0.75f, 0.03f, RGBA.FromHex("#79C4F7"), 0.01f);
        // Cute stitched X-eye on fish plushie!
        cv.PaintCapsule(0.22f, 0.36f, 0.29f, 0.48f, 0.016f, RGBA.FromHex("#1D334D"), 0.005f);
        cv.PaintCapsule(0.29f, 0.36f, 0.22f, 0.48f, 0.016f, RGBA.FromHex("#1D334D"), 0.005f);
        cv.SavePng(Path.Combine(texDir, "prop_fish_albedo.png"));
    }

    private static void BuildEarBow(string cmeshDir, string objDir)
    {
        float BowSdf(Vec3 p)
        {
            float knot = SdfMath.SdSphere(p, Vec3.Zero, 0.011f);
            float lWing = SdfMath.SdEllipsoid(p, new Vec3(-0.022f, 0f, 0f), new Vec3(0.020f, 0.009f, 0.015f));
            float rWing = SdfMath.SdEllipsoid(p, new Vec3( 0.022f, 0f, 0f), new Vec3(0.020f, 0.009f, 0.015f));
            return SdfMath.SMin(knot, MathF.Min(lWing, rWing), 0.005f);
        }
        var mesh = SurfaceNetsExtractor.Extract(
            BowSdf, new Vec3(-0.05f, -0.02f, -0.025f), new Vec3(0.05f, 0.02f, 0.025f),
            0.0035f, _ => new Vec2(0.5f, 0.5f), _ => new Vec4(0, 0, 0, 1), smoothIterations: 2);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_ear_bow.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_ear_bow.obj"), "mat_bow");
    }
}
