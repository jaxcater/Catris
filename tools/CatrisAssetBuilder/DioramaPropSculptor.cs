namespace CatrisAssetBuilder;

public static class DioramaPropSculptor
{
    public static void BuildAllPropsAndTextures(string cmeshDir, string objDir, string texDir)
    {
        // =====================================================================
        // 1. SCULPTED 3D DIORAMA PROPS (.cmesh + .obj)
        // =====================================================================
        BuildPlushRug(cmeshDir, objDir);
        BuildAcousticGuitar(cmeshDir, objDir, texDir);
        BuildMonsteraPlant(cmeshDir, objDir, texDir);
        BuildCeramicPot(cmeshDir, objDir);
        BuildPleatedCurtain(cmeshDir, objDir);
        BuildThrowCushion(cmeshDir, objDir);
        BuildHardcoverBook(cmeshDir, objDir);
        BuildTeacup(cmeshDir, objDir);
        BuildYarnBall(cmeshDir, objDir);
        BuildMilkBowl(cmeshDir, objDir);
        BuildAcorn(cmeshDir, objDir);
        BuildOakRoots(cmeshDir, objDir);
        BuildDeskLamp(cmeshDir, objDir);

        // =====================================================================
        // 2. ALL 5 MAP STYLIZED 1024x1024 FLOORS, RUGS, NORMALS & GOBOS
        // =====================================================================
        BuildMap01Textures(texDir);
        BuildMap02Textures(texDir);
        BuildMap03Textures(texDir);
        BuildMap04Textures(texDir);
        BuildMap05Textures(texDir);
        BuildAppIcon(texDir);
    }

    /// <summary>Soft beveled pillowy rounded rug mesh (unit size 1x1m, scaled dynamically per board!).</summary>
    private static void BuildPlushRug(string cmeshDir, string objDir)
    {
        float RugSdf(Vec3 p)
        {
            float box = SdfMath.SdRoundBox(p, new Vec3(0, 0.008f, 0), new Vec3(0.455f, 0.006f, 0.455f), 0.045f);
            float ground = -p.Y;
            return SdfMath.SMax(box, ground, 0.003f);
        }
        var mesh = SurfaceNetsExtractor.Extract(
            RugSdf, new Vec3(-0.54f, -0.01f, -0.54f), new Vec3(0.54f, 0.042f, 0.54f),
            0.015f,
            p => new Vec2(SdfMath.Clamp(p.X + 0.5f, 0f, 1f), SdfMath.Clamp(p.Z + 0.5f, 0f, 1f)),
            _ => new Vec4(0, 0, 0, 0), smoothIterations: 2, snapToSdf: true);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_rug.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_rug.obj"), "mat_rug");
    }

    /// <summary>Stylized 3D Acoustic Guitar (signature bottom-left prop from Game.mp4!).</summary>
    private static void BuildAcousticGuitar(string cmeshDir, string objDir, string texDir)
    {
        float GuitarSdf(Vec3 p)
        {
            // Waisted figure-8 acoustic body lying flat in XZ
            float lowerBout = SdfMath.SdVerticalCylinder(p, new Vec3(-0.08f, 0.045f, 0f), 0.165f, 0.045f, 0.014f);
            float upperBout = SdfMath.SdVerticalCylinder(p, new Vec3( 0.13f, 0.045f, 0f), 0.125f, 0.045f, 0.014f);
            float body = SdfMath.SMin(lowerBout, upperBout, 0.032f);
            // Neck & Headstock extending along +X
            float neck = SdfMath.SdRoundBox(p, new Vec3(0.40f, 0.055f, 0f), new Vec3(0.18f, 0.014f, 0.028f), 0.006f);
            float head = SdfMath.SdRoundBox(p, new Vec3(0.61f, 0.055f, 0f), new Vec3(0.05f, 0.014f, 0.040f), 0.008f);
            float bridge = SdfMath.SdRoundBox(p, new Vec3(-0.11f, 0.095f, 0f), new Vec3(0.016f, 0.008f, 0.055f), 0.004f);
            float d = SdfMath.SMin(body, SdfMath.SMin(neck, head, 0.010f), 0.012f);
            d = MathF.Min(d, bridge);
            // Recessed circular soundhole!
            float hole = SdfMath.SdVerticalCylinder(p, new Vec3(0.055f, 0.095f, 0f), 0.048f, 0.032f, 0.004f);
            d = SdfMath.SMax(d, -hole, 0.004f);
            return d;
        }
        var mesh = SurfaceNetsExtractor.Extract(
            GuitarSdf, new Vec3(-0.27f, -0.01f, -0.20f), new Vec3(0.68f, 0.12f, 0.20f),
            0.014f,
            p => new Vec2(SdfMath.Clamp((p.X + 0.26f) / 0.94f, 0f, 1f), SdfMath.Clamp((p.Z + 0.19f) / 0.38f, 0f, 1f)),
            _ => new Vec4(0, 0, 0, 0), smoothIterations: 3);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_guitar.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_guitar.obj"), "mat_guitar");

        var cv = new Canvas2D(512, 512, RGBA.FromHex("#D68A47"));
        cv.FillFunc((u, v) =>
        {
            float wood = (Noise2D.Fbm(u * 6f, v * 28f, 3, 210) - 0.5f) * 0.07f;
            var col = u > 0.54f ? RGBA.FromHex("#593928") : RGBA.FromHex("#DF944E");
            return new RGBA(SdfMath.Clamp(col.R + wood, 0, 1), SdfMath.Clamp(col.G + wood, 0, 1), SdfMath.Clamp(col.B + wood, 0, 1));
        });
        // Soundhole dark interior & rosette ring
        cv.PaintSoftCircle(0.335f, 0.50f, 0.060f, 0.145f, RGBA.FromHex("#3A2116"), 0.06f);
        cv.PaintSoftCircle(0.335f, 0.50f, 0.048f, 0.118f, RGBA.FromHex("#1D100A"), 0.05f);
        // Dark wood bridge
        cv.PaintRoundedRect(0.16f, 0.50f, 0.022f, 0.16f, 0.008f, RGBA.FromHex("#3E261C"));
        // 6 delicate guitar strings!
        for (int s = 0; s < 6; s++)
        {
            float sy = 0.44f + s * 0.024f;
            cv.PaintCapsule(0.16f, sy, 0.90f, sy, 0.003f, RGBA.FromHex("#E8DFC8"), 0.002f);
        }
        cv.SavePng(Path.Combine(texDir, "prop_guitar_albedo.png"));
    }

    /// <summary>Sculpted Broadleaf Houseplant w/ individual arching leaves & vertex wind weights!</summary>
    private static void BuildMonsteraPlant(string cmeshDir, string objDir, string texDir)
    {
        var mesh = new MeshData();
        // 7 lush arching leaves radiating outward from stem center!
        (float angle, float len, float width, float lift, float phase)[] leaves = [
            (0.0f,  0.32f, 0.085f, 0.22f, 0.10f),
            (0.85f, 0.28f, 0.078f, 0.26f, 0.28f),
            (1.75f, 0.34f, 0.090f, 0.20f, 0.45f),
            (2.55f, 0.26f, 0.072f, 0.25f, 0.62f),
            (3.45f, 0.31f, 0.082f, 0.23f, 0.78f),
            (4.35f, 0.29f, 0.078f, 0.27f, 0.90f),
            (5.25f, 0.25f, 0.070f, 0.29f, 0.35f),
        ];

        foreach (var (ang, len, width, lift, phase) in leaves)
        {
            float ca = MathF.Cos(ang), sa = MathF.Sin(ang);
            Vec3 Dir(float r, float side, float y) => new(
                ca * r - sa * side,
                y,
                sa * r + ca * side
            );

            int segL = 12, segW = 4;
            int baseIdx = mesh.Positions.Count;
            for (int i = 0; i <= segL; i++)
            {
                float t = (float)i / segL;
                // Stem from 0..0.3, plump leaf blade from 0.3..1.0
                float r = t * len;
                float archY = 0.08f + MathF.Sin(t * MathF.PI * 0.78f) * lift;
                float halfW = t < 0.28f
                    ? 0.006f
                    : width * MathF.Sin(((t - 0.28f) / 0.72f) * MathF.PI) * (0.65f + 0.35f * MathF.Sin(t * 5f));
                float windW = MathF.Pow(t, 1.6f); // Anchored at pot base (0), gently swaying at leaf tip (1)!

                for (int j = 0; j <= segW; j++)
                {
                    float s = ((float)j / segW) * 2f - 1f; // -1..+1
                    float cupY = (1f - s * s) * 0.012f * (t > 0.28f ? 1f : 0f);
                    Vec3 p = Dir(r, s * halfW, archY - cupY);
                    mesh.Positions.Add(p);
                    mesh.UVs.Add(new Vec2(s * 0.5f + 0.5f, t));
                    mesh.Colors.Add(new Vec4(windW, phase, 0f, 1f));
                }
            }
            int stride = segW + 1;
            for (int i = 0; i < segL; i++)
            for (int j = 0; j < segW; j++)
            {
                int a = baseIdx + i * stride + j;
                int b = a + 1;
                int c = baseIdx + (i + 1) * stride + j;
                int d = c + 1;
                mesh.Indices.Add(a); mesh.Indices.Add(b); mesh.Indices.Add(c);
                mesh.Indices.Add(b); mesh.Indices.Add(d); mesh.Indices.Add(c);
            }
        }
        mesh.RecomputeSmoothNormals();
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_monstera.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_monstera.obj"), "mat_leaf");

        var cv = new Canvas2D(256, 256, RGBA.FromHex("#5EA34B"));
        cv.FillFunc((u, v) =>
        {
            var baseG = RGBA.FromHex("#5DA449");
            var tipG  = RGBA.FromHex("#7CC25C");
            var vein  = RGBA.FromHex("#3B7230");
            var c = RGBA.Lerp(baseG, tipG, v);
            float centerDist = MathF.Abs(u - 0.5f);
            float midrib = 1f - SdfMath.SmoothStep(0.012f, 0.028f, centerDist);
            float sideVein = MathF.Abs(MathF.Sin((v * 14f - centerDist * 10f) * MathF.PI));
            float veinMask = MathF.Max(midrib, (1f - SdfMath.SmoothStep(0.0f, 0.08f, sideVein)) * 0.45f);
            return RGBA.Lerp(c, vein, veinMask * 0.6f);
        });
        cv.SavePng(Path.Combine(texDir, "prop_leaf_albedo.png"));
    }

    private static void BuildCeramicPot(string cmeshDir, string objDir)
    {
        var mesh = SurfaceNetsExtractor.CreateLathe([
            (0.001f, 0.000f), (0.085f, 0.000f), (0.105f, 0.045f), (0.118f, 0.125f),
            (0.126f, 0.145f), (0.122f, 0.158f), (0.104f, 0.158f), (0.100f, 0.125f), (0.001f, 0.125f)
        ], 28);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_ceramic_pot.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_ceramic_pot.obj"), "mat_pot");
    }

    /// <summary>Soft multi-pleated hanging linen curtain anchored at top edge (`windWeight = 0` at top, `1` at hem!).</summary>
    private static void BuildPleatedCurtain(string cmeshDir, string objDir)
    {
        var mesh = new MeshData();
        int segX = 24, segZ = 18;
        float width = 0.72f, length = 0.48f;
        for (int iz = 0; iz <= segZ; iz++)
        {
            float tz = (float)iz / segZ; // 0 = anchored window rod edge, 1 = billowy free edge
            for (int ix = 0; ix <= segX; ix++)
            {
                float tx = (float)ix / segX;
                float pleat = MathF.Sin(tx * MathF.PI * 7f) * (0.018f + 0.020f * tz);
                float x = (tx - 0.5f) * width;
                float z = tz * length;
                float y = 0.24f - tz * 0.04f + pleat;
                mesh.Positions.Add(new Vec3(x, y, z));
                mesh.UVs.Add(new Vec2(tx, tz));
                // R = windWeight (strictly 0 at anchor tz=0!), G = wave phase
                mesh.Colors.Add(new Vec4(MathF.Pow(tz, 1.4f), tx, 0f, 1f));
            }
        }
        int stride = segX + 1;
        for (int iz = 0; iz < segZ; iz++)
        for (int ix = 0; ix < segX; ix++)
        {
            int a = iz * stride + ix, b = a + 1, c = (iz + 1) * stride + ix, d = c + 1;
            mesh.Indices.Add(a); mesh.Indices.Add(c); mesh.Indices.Add(b);
            mesh.Indices.Add(b); mesh.Indices.Add(c); mesh.Indices.Add(d);
        }
        mesh.RecomputeSmoothNormals();
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_curtain.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_curtain.obj"), "mat_curtain");
    }

    private static void BuildThrowCushion(string cmeshDir, string objDir)
    {
        float CushionSdf(Vec3 p)
        {
            float d = SdfMath.SdEllipsoid(p, new Vec3(0, 0.065f, 0), new Vec3(0.18f, 0.072f, 0.16f));
            float box = SdfMath.SdRoundBox(p, new Vec3(0, 0.065f, 0), new Vec3(0.145f, 0.045f, 0.130f), 0.038f);
            return SdfMath.SMin(d, box, 0.03f);
        }
        var mesh = SurfaceNetsExtractor.Extract(
            CushionSdf, new Vec3(-0.22f, -0.01f, -0.20f), new Vec3(0.22f, 0.16f, 0.20f),
            0.014f, p => new Vec2(p.X * 2.5f + 0.5f, p.Z * 2.5f + 0.5f), _ => new Vec4(0, 0, 0, 0), 3);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_cushion.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_cushion.obj"), "mat_cushion");
    }

    private static void BuildHardcoverBook(string cmeshDir, string objDir)
    {
        float BookSdf(Vec3 p) => SdfMath.SdRoundBox(p, new Vec3(0, 0.028f, 0), new Vec3(0.088f, 0.024f, 0.115f), 0.008f);
        var mesh = SurfaceNetsExtractor.Extract(
            BookSdf, new Vec3(-0.12f, -0.01f, -0.14f), new Vec3(0.12f, 0.07f, 0.14f),
            0.009f, p => new Vec2(p.X * 4f + 0.5f, p.Z * 4f + 0.5f), _ => new Vec4(0, 0, 0, 0), 2);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_book.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_book.obj"), "mat_book");
    }

    private static void BuildTeacup(string cmeshDir, string objDir)
    {
        var mesh = SurfaceNetsExtractor.CreateLathe([
            (0.001f, 0.000f), (0.075f, 0.002f), (0.090f, 0.014f), (0.048f, 0.014f),
            (0.056f, 0.045f), (0.062f, 0.082f), (0.054f, 0.082f), (0.048f, 0.025f), (0.001f, 0.025f)
        ], 24);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_teacup.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_teacup.obj"), "mat_teacup");
    }

    private static void BuildYarnBall(string cmeshDir, string objDir)
    {
        float YarnSdf(Vec3 p)
        {
            float baseBall = SdfMath.SdSphere(p, new Vec3(0, 0.072f, 0), 0.074f);
            // Subtle organic yarn-strand wrap ridges!
            float ridges = MathF.Sin(p.X * 75f + p.Z * 35f) * 0.0025f + MathF.Sin(p.Y * 70f - p.X * 40f) * 0.0025f;
            float strand = SdfMath.SdCapsule(p, new Vec3(0.05f, 0.015f, 0.03f), new Vec3(0.105f, 0.012f, 0.075f), 0.009f, 0.006f);
            return SdfMath.SMax(MathF.Min(baseBall + ridges, strand), -p.Y, 0.005f);
        }
        var mesh = SurfaceNetsExtractor.Extract(
            YarnSdf, new Vec3(-0.10f, -0.01f, -0.10f), new Vec3(0.13f, 0.16f, 0.11f),
            0.008f, p => new Vec2(p.X * 5f + 0.5f, p.Z * 5f + 0.5f), _ => new Vec4(0, 0, 0, 0), 2);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_yarn_ball.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_yarn_ball.obj"), "mat_yarn");
    }

    private static void BuildMilkBowl(string cmeshDir, string objDir)
    {
        var mesh = SurfaceNetsExtractor.CreateLathe([
            (0.001f, 0.000f), (0.088f, 0.000f), (0.082f, 0.048f), (0.074f, 0.052f),
            (0.068f, 0.036f), (0.001f, 0.036f)
        ], 24);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_milk_bowl.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_milk_bowl.obj"), "mat_bowl");
    }

    private static void BuildAcorn(string cmeshDir, string objDir)
    {
        var mesh = SurfaceNetsExtractor.CreateLathe([
            (0.001f, 0.000f), (0.025f, 0.012f), (0.056f, 0.048f), (0.062f, 0.072f),
            (0.070f, 0.076f), (0.064f, 0.100f), (0.030f, 0.115f), (0.010f, 0.135f), (0.001f, 0.135f)
        ], 20);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_acorn.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_acorn.obj"), "mat_acorn");
    }

    private static void BuildOakRoots(string cmeshDir, string objDir)
    {
        float RootSdf(Vec3 p)
        {
            float trunk = SdfMath.SdVerticalCylinder(p, new Vec3(-0.25f, 0.12f, -0.25f), 0.24f, 0.18f, 0.04f);
            float r1 = SdfMath.SdPlushCapsule(p, new Vec3(-0.18f, 0.05f, -0.18f), new Vec3(0.24f, 0.02f, -0.16f), 0.095f, 0.035f, 0.7f);
            float r2 = SdfMath.SdPlushCapsule(p, new Vec3(-0.18f, 0.05f, -0.18f), new Vec3(-0.12f, 0.02f, 0.26f), 0.095f, 0.035f, 0.7f);
            float r3 = SdfMath.SdPlushCapsule(p, new Vec3(-0.15f, 0.04f, -0.15f), new Vec3(0.08f, 0.02f, 0.12f), 0.075f, 0.025f, 0.7f);
            return SdfMath.SMin(trunk, SdfMath.SMin(r1, SdfMath.SMin(r2, r3, 0.04f), 0.04f), 0.05f);
        }
        var mesh = SurfaceNetsExtractor.Extract(
            RootSdf, new Vec3(-0.52f, -0.02f, -0.52f), new Vec3(0.32f, 0.30f, 0.34f),
            0.020f, p => new Vec2(p.X + 0.5f, p.Z + 0.5f), _ => new Vec4(0, 0, 0, 0), 3);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_oak_roots.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_oak_roots.obj"), "mat_oak");
    }

    private static void BuildDeskLamp(string cmeshDir, string objDir)
    {
        var mesh = SurfaceNetsExtractor.CreateLathe([
            (0.001f, 0.000f), (0.095f, 0.000f), (0.092f, 0.022f), (0.022f, 0.028f),
            (0.018f, 0.220f), (0.125f, 0.230f), (0.095f, 0.310f), (0.032f, 0.335f), (0.001f, 0.335f)
        ], 24);
        mesh.SaveCMesh(Path.Combine(cmeshDir, "prop_lamp.cmesh"));
        mesh.SaveObj(Path.Combine(objDir, "prop_lamp.obj"), "mat_lamp");
    }

    // =========================================================================
    // MAP 1 — GÓC NẮNG (Exact Honey-Oak Planks + Pink Chevron Rug + 4x3 Window Gobo!)
    // =========================================================================
    private static void BuildMap01Textures(string texDir)
    {
        const int sz = 1024;
        var wood = new Canvas2D(sz, sz, RGBA.FromHex("#DF9C56"));
        var woodH = new float[sz * sz];
        RGBA[] plankTones = [
            RGBA.FromHex("#E8A860"), RGBA.FromHex("#D9914A"),
            RGBA.FromHex("#ECAE68"), RGBA.FromHex("#CF853F"),
            RGBA.FromHex("#E29D54"), RGBA.FromHex("#D58B44"),
        ];
        var seam = RGBA.FromHex("#A9652B");

        Parallel.For(0, sz, y =>
        {
            float v = (float)y / sz;
            for (int x = 0; x < sz; x++)
            {
                float u = (float)x / sz;
                int plankCols = 10;
                float px = u * plankCols;
                int pIdx = (int)MathF.Floor(px);
                float fx = px - pIdx;
                // Stagger horizontal butt joints per column
                float stagger = ((pIdx * 37) % 10) * 0.1f;
                float py = (v + stagger) * 3f;
                int rowIdx = (int)MathF.Floor(py);
                float fy = py - rowIdx;

                var tone = plankTones[(pIdx * 3 + rowIdx * 5) % plankTones.Length];
                float grain = (Noise2D.Fbm(u * 42f + pIdx * 3.1f, v * 5.5f + rowIdx * 2.7f, 4, 1) - 0.5f) * 0.085f;
                float edgeX = MathF.Min(fx, 1f - fx);
                float edgeY = MathF.Min(fy, 1f - fy);
                float seamMask = MathF.Max(1f - SdfMath.SmoothStep(0.008f, 0.025f, edgeX),
                                           1f - SdfMath.SmoothStep(0.003f, 0.010f, edgeY));
                var c = RGBA.Lerp(new RGBA(SdfMath.Clamp(tone.R + grain, 0, 1),
                                           SdfMath.Clamp(tone.G + grain * 0.85f, 0, 1),
                                           SdfMath.Clamp(tone.B + grain * 0.65f, 0, 1)), seam, seamMask * 0.62f);
                wood.Pixels[y * sz + x] = c;
                woodH[y * sz + x] = (1f - seamMask * 0.7f) + grain * 0.4f;
            }
        });
        wood.SavePng(Path.Combine(texDir, "floor_m01.png"));
        Canvas2D.HeightToNormalMap(woodH, sz, sz, 1.6f).SavePng(Path.Combine(texDir, "floor_m01_norm.png"));

        // Exact Bright Pastel Pink Chevron Zigzag Rug from Game.mp4!
        var rug = new Canvas2D(sz, sz, RGBA.FromHex("#F597B7"));
        var rugH = new float[sz * sz];
        var pinkBase = RGBA.FromHex("#F495B6");
        var pinkLight = RGBA.FromHex("#FDE0EA");
        var pinkRim = RGBA.FromHex("#7B374C");

        Parallel.For(0, sz, y =>
        {
            float v = (float)y / sz;
            for (int x = 0; x < sz; x++)
            {
                float u = (float)x / sz;
                // Vertical chevron zigzag columns (matching frame-01.jpg!)
                float zig = MathF.Abs(((v * 6f) % 1f) * 2f - 1f) * 0.09f;
                float stripe = ((u + zig) * 4.5f) % 1f;
                float isLight = SdfMath.SmoothStep(0.47f, 0.50f, stripe) * (1f - SdfMath.SmoothStep(0.95f, 0.98f, stripe));
                var c = RGBA.Lerp(pinkBase, pinkLight, isLight * 0.86f);

                // Soft woven linen fabric micro-grain
                float weave = (MathF.Sin(u * 380f) * MathF.Sin(v * 380f)) * 0.014f
                            + (Noise2D.Fbm(u * 50f, v * 50f, 2, 17) - 0.5f) * 0.022f;
                // Crisp thin hand-drawn perimeter stitch border
                float borderDist = MathF.Min(MathF.Min(u, 1f - u), MathF.Min(v, 1f - v));
                float border = 1f - SdfMath.SmoothStep(0.008f, 0.017f, borderDist);
                float innerShade = (1f - SdfMath.SmoothStep(0.017f, 0.055f, borderDist)) * 0.05f;

                c = RGBA.Lerp(c.Shade(1f - innerShade + weave), pinkRim, border * 0.85f);
                rug.Pixels[y * sz + x] = c;
                rugH[y * sz + x] = 0.5f + weave * 5f - border * 0.4f;
            }
        });
        rug.SavePng(Path.Combine(texDir, "rug_m01.png"));
        Canvas2D.HeightToNormalMap(rugH, sz, sz, 1.2f).SavePng(Path.Combine(texDir, "rug_m01_norm.png"));

        // Golden Afternoon 4x3 Window Mullion Sunbeam Gobo!
        var gobo = new Canvas2D(512, 512, new RGBA(0.32f, 0.25f, 0.28f, 1f));
        gobo.FillFunc((u, v) =>
        {
            // Diagonal shear matching sunlight entering from upper-right window!
            float su = u * 0.92f + v * 0.22f - 0.08f;
            float sv = v * 0.94f - u * 0.14f + 0.06f;
            // Warm sunlit window panes separated by mullion bars
            bool inWindow = su > 0.08f && su < 0.92f && sv > 0.05f && sv < 0.92f;
            float gx = MathF.Abs(((su - 0.08f) / 0.84f * 4f) % 1f - 0.5f);
            float gy = MathF.Abs(((sv - 0.05f) / 0.87f * 3f) % 1f - 0.5f);
            float paneX = 1f - SdfMath.SmoothStep(0.36f, 0.45f, gx);
            float paneY = 1f - SdfMath.SmoothStep(0.35f, 0.44f, gy);
            float softEdge = SdfMath.SmoothStep(0.05f, 0.13f, su) * (1f - SdfMath.SmoothStep(0.86f, 0.95f, su))
                           * SdfMath.SmoothStep(0.02f, 0.10f, sv) * (1f - SdfMath.SmoothStep(0.86f, 0.96f, sv));
            float sun = inWindow ? paneX * paneY * softEdge : 0f;
            // Warm golden highlight vs lavender-warm shadow (never harsh black!)
            return RGBA.Lerp(new RGBA(0.46f, 0.39f, 0.42f, 1f), new RGBA(1.0f, 0.95f, 0.82f, 1f), sun);
        });
        gobo.SavePng(Path.Combine(texDir, "gobo_window_m01.png"));
    }

    // =========================================================================
    // MAP 2 — DƯỚI TÁN SỒI (Sunlit Meadow Grass + Coral Gingham Picnic Blanket)
    // =========================================================================
    private static void BuildMap02Textures(string texDir)
    {
        const int sz = 1024;
        var grass = new Canvas2D(sz, sz, RGBA.FromHex("#82B36B"));
        grass.FillFunc((u, v) =>
        {
            float n1 = Noise2D.Fbm(u * 12f, v * 12f, 4, 201);
            float n2 = Noise2D.Fbm(u * 48f, v * 48f, 3, 202);
            var c = RGBA.Lerp(RGBA.FromHex("#6FA059"), RGBA.FromHex("#95C37A"), n1 * 0.7f + n2 * 0.3f);
            return c;
        });
        // Scatter tiny white meadow daisies!
        var rng = new Random(2026);
        for (int i = 0; i < 65; i++)
        {
            float dx = (float)rng.NextDouble(), dy = (float)rng.NextDouble();
            for (int p = 0; p < 5; p++)
            {
                float a = p * MathF.PI * 2f / 5f;
                grass.PaintSoftCircle(dx + MathF.Cos(a) * 0.008f, dy + MathF.Sin(a) * 0.008f, 0.006f, 0.006f, RGBA.FromHex("#FFFDF5"), 0.2f);
            }
            grass.PaintSoftCircle(dx, dy, 0.0045f, 0.0045f, RGBA.FromHex("#F5CA58"), 0.2f);
        }
        grass.SavePng(Path.Combine(texDir, "floor_m02.png"));

        // Coral & Cream Gingham Picnic Blanket!
        var blanket = new Canvas2D(sz, sz, RGBA.FromHex("#FFF6E5"));
        var cream = RGBA.FromHex("#FFF7E8");
        var coral = RGBA.FromHex("#E9967B");
        var coralDeep = RGBA.FromHex("#D8785B");
        var stitch = RGBA.FromHex("#8C4B38");
        blanket.FillFunc((u, v) =>
        {
            bool sx = ((int)(u * 14f)) % 2 == 0;
            bool sy = ((int)(v * 14f)) % 2 == 0;
            var c = (sx && sy) ? coralDeep : (sx || sy) ? coral : cream;
            float weave = (Noise2D.Fbm(u * 60f, v * 60f, 2, 205) - 0.5f) * 0.03f;
            float bd = MathF.Min(MathF.Min(u, 1f - u), MathF.Min(v, 1f - v));
            float border = 1f - SdfMath.SmoothStep(0.012f, 0.022f, bd);
            return RGBA.Lerp(c.Shade(1f + weave), stitch, border * 0.8f);
        });
        blanket.SavePng(Path.Combine(texDir, "rug_m02.png"));

        // Soft Dappled Oak Canopy Gobo!
        var gobo = new Canvas2D(512, 512, new RGBA(0.55f, 0.58f, 0.50f, 1f));
        gobo.FillFunc((u, v) =>
        {
            float n = Noise2D.Fbm(u * 5.5f, v * 5.5f, 4, 208);
            float dapple = SdfMath.SmoothStep(0.40f, 0.64f, n);
            return RGBA.Lerp(new RGBA(0.48f, 0.53f, 0.46f, 1f), new RGBA(1.0f, 0.96f, 0.84f, 1f), dapple);
        });
        gobo.SavePng(Path.Combine(texDir, "gobo_oak_m02.png"));
    }

    // =========================================================================
    // MAP 3 — HIÊN NHÀ KÍNH (Terracotta Tiles + Sage Woven Linen Mat)
    // =========================================================================
    private static void BuildMap03Textures(string texDir)
    {
        const int sz = 1024;
        var tiles = new Canvas2D(sz, sz, RGBA.FromHex("#D69176"));
        var grout = RGBA.FromHex("#EAD9C9");
        tiles.FillFunc((u, v) =>
        {
            float tx = u * 8f, ty = v * 8f;
            int ix = (int)MathF.Floor(tx), iy = (int)MathF.Floor(ty);
            float fx = tx - ix, fy = ty - iy;
            var baseT = ((ix + iy) % 2 == 0) ? RGBA.FromHex("#D9967B") : RGBA.FromHex("#CC856A");
            float clay = (Noise2D.Fbm(u * 28f, v * 28f, 3, 301) - 0.5f) * 0.06f;
            float edge = MathF.Min(MathF.Min(fx, 1f - fx), MathF.Min(fy, 1f - fy));
            float gm = 1f - SdfMath.SmoothStep(0.015f, 0.040f, edge);
            return RGBA.Lerp(baseT.Shade(1f + clay), grout, gm * 0.85f);
        });
        tiles.SavePng(Path.Combine(texDir, "floor_m03.png"));

        var sageBase = RGBA.FromHex("#A7C2A2");
        var sage = new Canvas2D(sz, sz, sageBase);
        var sageLight = RGBA.FromHex("#BED4B9");
        var trim = RGBA.FromHex("#556E52");
        sage.FillFunc((u, v) =>
        {
            float stripe = MathF.Sin(v * 22f * MathF.PI) * 0.5f + 0.5f;
            var c = RGBA.Lerp(sageBase, sageLight, stripe * 0.35f);
            float weave = (MathF.Sin(u * 320f) * MathF.Sin(v * 320f)) * 0.02f;
            float bd = MathF.Min(MathF.Min(u, 1f - u), MathF.Min(v, 1f - v));
            float border = 1f - SdfMath.SmoothStep(0.012f, 0.024f, bd);
            return RGBA.Lerp(c.Shade(1f + weave), trim, border * 0.78f);
        });
        sage.SavePng(Path.Combine(texDir, "rug_m03.png"));

        var gobo = new Canvas2D(512, 512, new RGBA(0.60f, 0.62f, 0.58f, 1f));
        gobo.FillFunc((u, v) =>
        {
            float su = u * 0.95f + v * 0.12f;
            float gx = MathF.Abs((su * 5f) % 1f - 0.5f);
            float gy = MathF.Abs((v * 4f) % 1f - 0.5f);
            float bar = MathF.Max(SdfMath.SmoothStep(0.43f, 0.48f, gx), SdfMath.SmoothStep(0.44f, 0.48f, gy));
            return RGBA.Lerp(new RGBA(1.0f, 0.97f, 0.90f, 1f), new RGBA(0.55f, 0.58f, 0.54f, 1f), bar);
        });
        gobo.SavePng(Path.Combine(texDir, "gobo_greenhouse_m03.png"));
    }

    // =========================================================================
    // MAP 4 — Ô CỬA NGÀY MƯA (Chestnut Wood Floor + Dusty-Blue Cable-Knit Rug)
    // =========================================================================
    private static void BuildMap04Textures(string texDir)
    {
        const int sz = 1024;
        var floor = new Canvas2D(sz, sz, RGBA.FromHex("#825B45"));
        RGBA[] tones = [RGBA.FromHex("#8C644C"), RGBA.FromHex("#7B5540"), RGBA.FromHex("#926A51"), RGBA.FromHex("#734E3A")];
        var seam = RGBA.FromHex("#4A3024");
        floor.FillFunc((u, v) =>
        {
            float px = u * 9f; int idx = (int)MathF.Floor(px); float fx = px - idx;
            float grain = (Noise2D.Fbm(u * 40f, v * 6f, 4, 401) - 0.5f) * 0.08f;
            float sm = 1f - SdfMath.SmoothStep(0.008f, 0.025f, MathF.Min(fx, 1f - fx));
            return RGBA.Lerp(tones[idx % tones.Length].Shade(1f + grain), seam, sm * 0.7f);
        });
        floor.SavePng(Path.Combine(texDir, "floor_m04.png"));

        var rug = new Canvas2D(sz, sz, RGBA.FromHex("#8BA6C0"));
        var light = RGBA.FromHex("#B1C7DB");
        var rim = RGBA.FromHex("#43586E");
        rug.FillFunc((u, v) =>
        {
            float cable = MathF.Sin(u * 26f * MathF.PI + MathF.Sin(v * 34f * MathF.PI) * 0.8f) * 0.5f + 0.5f;
            var c = RGBA.Lerp(RGBA.FromHex("#88A3BD"), light, cable * 0.42f);
            float bd = MathF.Min(MathF.Min(u, 1f - u), MathF.Min(v, 1f - v));
            float border = 1f - SdfMath.SmoothStep(0.012f, 0.024f, bd);
            return RGBA.Lerp(c, rim, border * 0.82f);
        });
        rug.SavePng(Path.Combine(texDir, "rug_m04.png"));
    }

    // =========================================================================
    // MAP 5 — GÁC MÁI TRĂNG (Deep Walnut Planks + Plush Cream Sheepskin Rug!)
    // =========================================================================
    private static void BuildMap05Textures(string texDir)
    {
        const int sz = 1024;
        var floor = new Canvas2D(sz, sz, RGBA.FromHex("#483A47"));
        RGBA[] tones = [RGBA.FromHex("#4D3E4C"), RGBA.FromHex("#413440"), RGBA.FromHex("#544453"), RGBA.FromHex("#3B2E3A")];
        var seam = RGBA.FromHex("#271E27");
        floor.FillFunc((u, v) =>
        {
            float px = u * 9f; int idx = (int)MathF.Floor(px); float fx = px - idx;
            float grain = (Noise2D.Fbm(u * 38f, v * 6f, 4, 501) - 0.5f) * 0.07f;
            float sm = 1f - SdfMath.SmoothStep(0.008f, 0.024f, MathF.Min(fx, 1f - fx));
            return RGBA.Lerp(tones[idx % tones.Length].Shade(1f + grain), seam, sm * 0.72f);
        });
        floor.SavePng(Path.Combine(texDir, "floor_m05.png"));

        // Bright soft warm cream sheepskin rug so black & brown cats pop effortlessly at night!
        var rug = new Canvas2D(sz, sz, RGBA.FromHex("#F4ECE3"));
        var fluff = RGBA.FromHex("#E6DACB");
        var rim = RGBA.FromHex("#8E7B74");
        rug.FillFunc((u, v) =>
        {
            float n = Noise2D.Fbm(u * 26f, v * 26f, 4, 505);
            var c = RGBA.Lerp(fluff, RGBA.FromHex("#F9F3EC"), n);
            float bd = MathF.Min(MathF.Min(u, 1f - u), MathF.Min(v, 1f - v));
            float border = 1f - SdfMath.SmoothStep(0.012f, 0.025f, bd);
            return RGBA.Lerp(c, rim, border * 0.72f);
        });
        rug.SavePng(Path.Combine(texDir, "rug_m05.png"));

        var gobo = new Canvas2D(512, 512, new RGBA(0.36f, 0.38f, 0.50f, 1f));
        gobo.FillFunc((u, v) =>
        {
            float su = u * 0.90f + v * 0.16f - 0.05f;
            float pane = SdfMath.SmoothStep(0.15f, 0.25f, su) * (1f - SdfMath.SmoothStep(0.78f, 0.88f, su))
                       * SdfMath.SmoothStep(0.10f, 0.20f, v) * (1f - SdfMath.SmoothStep(0.82f, 0.92f, v));
            float bar = MathF.Max(1f - SdfMath.SmoothStep(0.015f, 0.04f, MathF.Abs(su - 0.51f)),
                                  1f - SdfMath.SmoothStep(0.015f, 0.04f, MathF.Abs(v - 0.50f)));
            float moon = pane * (1f - bar);
            return RGBA.Lerp(new RGBA(0.45f, 0.44f, 0.55f, 1f), new RGBA(0.86f, 0.91f, 1.0f, 1f), moon);
        });
        gobo.SavePng(Path.Combine(texDir, "gobo_moon_m05.png"));
    }

    /// <summary>1024x1024 Cozy Catris AppIcon (warm honey sunbeams + pink chevron rug + adorable Miso & Nori!).</summary>
    private static void BuildAppIcon(string texDir)
    {
        const int sz = 1024;
        var icon = new Canvas2D(sz, sz, RGBA.FromHex("#E6A35B"));
        // Honey oak background + golden sunbeam
        icon.FillFunc((u, v) =>
        {
            int p = (int)(u * 6f);
            var wood = (p % 2 == 0) ? RGBA.FromHex("#E8A75E") : RGBA.FromHex("#DC964D");
            float sun = SdfMath.SmoothStep(0.25f, 0.65f, u * 0.7f + (1f - v) * 0.6f) * 0.22f;
            return new RGBA(SdfMath.Clamp(wood.R + sun, 0, 1), SdfMath.Clamp(wood.G + sun * 0.9f, 0, 1), SdfMath.Clamp(wood.B + sun * 0.5f, 0, 1));
        });
        // Rounded pink chevron rug center
        icon.PaintRoundedRect(0.50f, 0.52f, 0.39f, 0.37f, 0.09f, RGBA.FromHex("#6B3143"), 0.005f);
        icon.PaintRoundedRect(0.50f, 0.52f, 0.37f, 0.35f, 0.08f, RGBA.FromHex("#F18FB0"), 0.005f);
        // Cute chubby ginger cat Miso silhouette in center with warm white sticker border!
        icon.PaintSoftCircle(0.50f, 0.56f, 0.26f, 0.24f, RGBA.FromHex("#FFFDF7"), 0.03f);
        icon.PaintSoftCircle(0.34f, 0.36f, 0.09f, 0.11f, RGBA.FromHex("#FFFDF7"), 0.03f);
        icon.PaintSoftCircle(0.66f, 0.36f, 0.09f, 0.11f, RGBA.FromHex("#FFFDF7"), 0.03f);
        // Ginger head & ears
        icon.PaintSoftCircle(0.35f, 0.38f, 0.072f, 0.095f, RGBA.FromHex("#EE9E42"), 0.03f);
        icon.PaintSoftCircle(0.65f, 0.38f, 0.072f, 0.095f, RGBA.FromHex("#EE9E42"), 0.03f);
        icon.PaintSoftCircle(0.35f, 0.39f, 0.038f, 0.052f, RGBA.FromHex("#F4A8AE"), 0.04f);
        icon.PaintSoftCircle(0.65f, 0.39f, 0.038f, 0.052f, RGBA.FromHex("#F4A8AE"), 0.04f);
        icon.PaintSoftCircle(0.50f, 0.56f, 0.235f, 0.215f, RGBA.FromHex("#EE9E42"), 0.03f);
        // Forehead tabby stripes
        icon.PaintCapsule(0.50f, 0.36f, 0.50f, 0.44f, 0.018f, RGBA.FromHex("#C46B24"), 0.008f);
        icon.PaintCapsule(0.43f, 0.37f, 0.44f, 0.43f, 0.015f, RGBA.FromHex("#C46B24"), 0.008f);
        icon.PaintCapsule(0.57f, 0.37f, 0.56f, 0.43f, 0.015f, RGBA.FromHex("#C46B24"), 0.008f);
        // Cream muzzle
        icon.PaintSoftCircle(0.50f, 0.62f, 0.11f, 0.07f, RGBA.FromHex("#FCE8C8"), 0.2f);
        // Big adorable sparkling eyes!
        icon.PaintSoftCircle(0.41f, 0.54f, 0.048f, 0.052f, RGBA.FromHex("#FFFFFF"), 0.04f);
        icon.PaintSoftCircle(0.59f, 0.54f, 0.048f, 0.052f, RGBA.FromHex("#FFFFFF"), 0.04f);
        icon.PaintSoftCircle(0.42f, 0.54f, 0.034f, 0.038f, RGBA.FromHex("#2E4A7D"), 0.04f);
        icon.PaintSoftCircle(0.58f, 0.54f, 0.034f, 0.038f, RGBA.FromHex("#2E4A7D"), 0.04f);
        icon.PaintSoftCircle(0.405f, 0.525f, 0.013f, 0.013f, RGBA.FromHex("#FFFFFF"), 0.05f);
        icon.PaintSoftCircle(0.565f, 0.525f, 0.013f, 0.013f, RGBA.FromHex("#FFFFFF"), 0.05f);
        // Rosy cheeks + cute nose
        icon.PaintSoftCircle(0.34f, 0.60f, 0.038f, 0.024f, new RGBA(0.95f, 0.52f, 0.58f, 0.65f), 0.3f);
        icon.PaintSoftCircle(0.66f, 0.60f, 0.038f, 0.024f, new RGBA(0.95f, 0.52f, 0.58f, 0.65f), 0.3f);
        icon.PaintSoftCircle(0.50f, 0.59f, 0.020f, 0.014f, RGBA.FromHex("#C95C66"), 0.08f);

        icon.SavePng(Path.Combine(texDir, "AppIcon.png"));
    }
}
