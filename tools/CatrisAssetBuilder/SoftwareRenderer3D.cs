using System.Buffers.Binary;
using System.IO.Compression;
using System.Text;

namespace CatrisAssetBuilder;

/// <summary>
/// Fast Z-buffered 3D orthographic software rasterizer to visually QA our exact `.cmesh`
/// sculpted cats, textures, facial anchors, lighting, and M01 portrait diorama right on Windows!
/// </summary>
public static class SoftwareRenderer3D
{
    private struct LoadedMesh
    {
        public Vec3[] Pos;
        public Vec3[] Norm;
        public Vec2[] UV;
        public int[] Indices;
    }

    private struct LoadedTex
    {
        public int W, H;
        public RGBA[] Px;
        public RGBA Sample(float u, float v, bool repeat = false)
        {
            if (repeat)
            {
                u = u - MathF.Floor(u);
                v = v - MathF.Floor(v);
            }
            else
            {
                u = SdfMath.Clamp(u, 0f, 0.999f);
                v = SdfMath.Clamp(v, 0f, 0.999f);
            }
            int x = Math.Clamp((int)(u * W), 0, W - 1);
            int y = Math.Clamp((int)(v * H), 0, H - 1);
            return Px[y * W + x];
        }
    }

    public static void RenderQAPreviews(string cmeshDir, string texDir, string dataDir, string previewDir)
    {
        Directory.CreateDirectory(previewDir);
        var anchorsJson = File.ReadAllText(Path.Combine(dataDir, "cat_anchors.json"));
        var anchors = System.Text.Json.JsonSerializer.Deserialize<List<CatAnchorRecord>>(
            anchorsJson,
            new System.Text.Json.JsonSerializerOptions { PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.SnakeCaseLower }
        ) ?? [];
        var anchorMap = anchors.ToDictionary(a => a.Id);

        // Render 1: M01 Sunlit Corner Classic 4x4 Portrait View (390x844 @ 2x -> 585x1266)
        RenderM01Portrait(cmeshDir, texDir, anchorMap, Path.Combine(previewDir, "render_m01_portrait.png"));

        // Render 2: All 12 Sculpted 3D Cats Showcase Grid
        RenderAll12Cats(cmeshDir, texDir, anchorMap, Path.Combine(previewDir, "render_all_12_cats.png"));
    }

    private static void RenderM01Portrait(string cmeshDir, string texDir, Dictionary<string, CatAnchorRecord> anchorMap, string outPath)
    {
        const int W = 540, H = 1170;
        var fb = new Canvas2D(W, H, RGBA.FromHex("#DF9C56"));
        var zbuf = new float[W * H];
        Array.Fill(zbuf, float.PositiveInfinity);

        // Camera matching CatrisSceneController: 78 deg elevation orthographic portrait!
        Vec3 camPos = new(0f, 4.4f, 0.96f);
        Vec3 camTarget = new(0f, 0f, 0.04f);
        float orthoHalfH = 1.38f;
        float orthoHalfW = orthoHalfH * ((float)W / H);

        var (right, up, fwd) = LookBasis(camPos, camTarget);

        // 1. Honey-oak wood floor + window sunbeam gobo!
        var floorTex = LoadPng(Path.Combine(texDir, "floor_m01.png"));
        var goboTex  = LoadPng(Path.Combine(texDir, "gobo_window_m01.png"));
        DrawFloor(fb, zbuf, W, H, camPos, right, up, fwd, orthoHalfW, orthoHalfH, floorTex, goboTex);

        // 2. Plush Pink Chevron Rug at z = -0.22
        float boardZ = -0.22f;
        var rugMesh = LoadCMesh(Path.Combine(cmeshDir, "prop_rug.cmesh"));
        var rugTex  = LoadPng(Path.Combine(texDir, "rug_m01.png"));
        DrawMesh(fb, zbuf, W, H, rugMesh, rugTex, null, new Vec3(0, 0.001f, boardZ), new Vec3(1.22f, 1.0f, 1.20f), 0f,
            camPos, right, up, fwd, orthoHalfW, orthoHalfH, goboTex);

        // 3. Crisp 4x4 white/green grid lines on rug!
        DrawGridLines(fb, zbuf, W, H, 4, 4, boardZ, camPos, right, up, fwd, orthoHalfW, orthoHalfH);

        // 4. Peripheral 3D Props: Acoustic Guitar, Green Cushion, Potted Monstera, Pleated Curtains!
        DrawMesh(fb, zbuf, W, H, LoadCMesh(Path.Combine(cmeshDir, "prop_guitar.cmesh")),
            LoadPng(Path.Combine(texDir, "prop_guitar_albedo.png")), null,
            new Vec3(-0.46f, 0.002f, 0.88f), new Vec3(0.85f, 0.85f, 0.85f), 0.42f,
            camPos, right, up, fwd, orthoHalfW, orthoHalfH, goboTex);

        DrawMesh(fb, zbuf, W, H, LoadCMesh(Path.Combine(cmeshDir, "prop_ceramic_pot.cmesh")),
            null, RGBA.FromHex("#C97E5D"),
            new Vec3(0.56f, 0f, 0.72f), new Vec3(0.92f, 0.92f, 0.92f), 0f,
            camPos, right, up, fwd, orthoHalfW, orthoHalfH, goboTex);

        DrawMesh(fb, zbuf, W, H, LoadCMesh(Path.Combine(cmeshDir, "prop_monstera.cmesh")),
            LoadPng(Path.Combine(texDir, "prop_leaf_albedo.png")), null,
            new Vec3(0.56f, 0.04f, 0.72f), new Vec3(0.95f, 0.95f, 0.95f), 0f,
            camPos, right, up, fwd, orthoHalfW, orthoHalfH, goboTex);

        DrawMesh(fb, zbuf, W, H, LoadCMesh(Path.Combine(cmeshDir, "prop_curtain.cmesh")),
            null, RGBA.FromHex("#FAF1E2"),
            new Vec3(-0.34f, 0.14f, -1.46f), new Vec3(0.85f, 0.85f, 0.85f), 0f,
            camPos, right, up, fwd, orthoHalfW, orthoHalfH, goboTex);

        // 5. Place the exact 5 video hero cats in the solved classic 4x4 formation!
        (string id, float x, float z)[] placements = [
            ("nori",    -0.375f, boardZ + 0.000f),
            ("sumi",     0.000f, boardZ + 0.125f),
            ("pudding",  0.250f, boardZ + 0.125f),
            ("mochi",    0.250f, boardZ - 0.250f),
            ("miso",    -0.125f, boardZ - 0.375f),
        ];
        foreach (var (id, x, z) in placements)
        {
            DrawFullCat(fb, zbuf, W, H, cmeshDir, texDir, id, anchorMap[id],
                new Vec3(x, 0.017f, z), 1.0f, camPos, right, up, fwd, orthoHalfW, orthoHalfH, goboTex);
        }

        fb.SavePng(outPath);
    }

    private static void RenderAll12Cats(string cmeshDir, string texDir, Dictionary<string, CatAnchorRecord> anchorMap, string outPath)
    {
        const int W = 900, H = 1200;
        var fb = new Canvas2D(W, H, RGBA.FromHex("#F4D4DE"));
        var zbuf = new float[W * H];
        Array.Fill(zbuf, float.PositiveInfinity);

        Vec3 camPos = new(0f, 4.4f, 0.96f);
        Vec3 camTarget = new(0f, 0f, 0.0f);
        float orthoHalfH = 1.45f;
        float orthoHalfW = orthoHalfH * ((float)W / H);
        var (right, up, fwd) = LookBasis(camPos, camTarget);

        string[] ids = ["nori","sumi","pudding","mochi","miso","yuzu","matcha","sesame","kinako","azuki","taro","banhmi"];
        for (int i = 0; i < ids.Length; i++)
        {
            int col = i % 3;
            int row = i / 3;
            float x = (col - 1) * 0.68f;
            float z = (row - 1.5f) * 0.72f;
            DrawFullCat(fb, zbuf, W, H, cmeshDir, texDir, ids[i], anchorMap[ids[i]],
                new Vec3(x, 0.01f, z), 0.72f, camPos, right, up, fwd, orthoHalfW, orthoHalfH, null);
        }

        fb.SavePng(outPath);
    }

    private static void DrawFullCat(
        Canvas2D fb, float[] zbuf, int W, int H,
        string cmeshDir, string texDir, string id, CatAnchorRecord a,
        Vec3 pos, float scale,
        Vec3 camPos, Vec3 right, Vec3 up, Vec3 fwd, float halfW, float halfH, LoadedTex? gobo)
    {
        var mesh = LoadCMesh(Path.Combine(cmeshDir, $"cat_{id}.cmesh"));
        var tex  = LoadPng(Path.Combine(texDir, $"cat_{id}_albedo.png"));
        DrawMesh(fb, zbuf, W, H, mesh, tex, null, pos, new Vec3(scale, scale, scale), 0f,
            camPos, right, up, fwd, halfW, halfH, gobo, isCat: true);

        // Draw expressive 3D face features (eyes, pupils, catchlights, nose, fangs, blep, fish, bow)!
        void DrawDot(float[] localP, float r, RGBA col, float yBoost = 0.005f)
        {
            Vec3 wp = new(pos.X + localP[0] * scale, pos.Y + (localP[1] + yBoost) * scale, pos.Z + localP[2] * scale);
            var (sx, sy, depth) = Project(wp, camPos, right, up, fwd, halfW, halfH, W, H);
            float pr = r * scale * (H / (2f * halfH));
            int x0 = Math.Max(0, (int)(sx - pr - 2)), x1 = Math.Min(W - 1, (int)(sx + pr + 2));
            int y0 = Math.Max(0, (int)(sy - pr - 2)), y1 = Math.Min(H - 1, (int)(sy + pr + 2));
            for (int y = y0; y <= y1; y++)
            for (int x = x0; x <= x1; x++)
            {
                float d = MathF.Sqrt((x - sx) * (x - sx) + (y - sy) * (y - sy));
                if (d <= pr && depth - 0.04f < zbuf[y * W + x])
                {
                    float cov = 1f - SdfMath.SmoothStep(pr - 1.2f, pr, d);
                    fb.BlendPixel(x, y, col, cov);
                }
            }
        }

        var eyeCol = RGBA.FromHex(a.EyeColorHex);
        var pupilCol = RGBA.FromHex("#18161C");
        var white = RGBA.FromHex("#FFFFFF");
        foreach (var ep in new[] { a.LeftEyePos, a.RightEyePos })
        {
            if (a.EyeStyle == "big_blue")
            {
                DrawDot(ep, a.EyeRadius * 1.15f, white);
                DrawDot(ep, a.EyeRadius * 0.78f, eyeCol, 0.008f);
                DrawDot([ep[0] - 0.004f, ep[1], ep[2] - 0.004f], a.EyeRadius * 0.28f, white, 0.011f);
            }
            else
            {
                DrawDot(ep, a.EyeRadius, eyeCol);
                DrawDot(ep, a.EyeRadius * 0.56f, pupilCol, 0.008f);
                DrawDot([ep[0] - 0.004f, ep[1], ep[2] - 0.004f], a.EyeRadius * 0.24f, white, 0.011f);
            }
        }
        DrawDot(a.NosePos, 0.009f, RGBA.FromHex(a.HasBlep ? "#8A3A3A" : "#E07F89"), 0.007f);
        if (a.HasFangs)
        {
            DrawDot([a.NosePos[0] - 0.009f, a.NosePos[1], a.NosePos[2] + 0.013f], 0.0045f, white, 0.007f);
            DrawDot([a.NosePos[0] + 0.009f, a.NosePos[1], a.NosePos[2] + 0.013f], 0.0045f, white, 0.007f);
        }
        if (a.HasBlep)
        {
            DrawDot([a.NosePos[0], a.NosePos[1], a.NosePos[2] + 0.013f], 0.0085f, RGBA.FromHex("#F27D8C"), 0.006f);
        }
        if (a.HasFishPlushie && a.FishPos != null)
        {
            var fishMesh = LoadCMesh(Path.Combine(cmeshDir, "prop_fish_plushie.cmesh"));
            var fishTex  = LoadPng(Path.Combine(texDir, "prop_fish_albedo.png"));
            Vec3 fp = new(pos.X + a.FishPos[0] * scale, pos.Y + a.FishPos[1] * scale, pos.Z + a.FishPos[2] * scale);
            DrawMesh(fb, zbuf, W, H, fishMesh, fishTex, null, fp, new Vec3(scale, scale, scale), 0.22f,
                camPos, right, up, fwd, halfW, halfH, gobo);
        }
        if (a.HasEarBow && a.BowPos != null)
        {
            var bowMesh = LoadCMesh(Path.Combine(cmeshDir, "prop_ear_bow.cmesh"));
            Vec3 bp = new(pos.X + a.BowPos[0] * scale, pos.Y + a.BowPos[1] * scale, pos.Z + a.BowPos[2] * scale);
            DrawMesh(fb, zbuf, W, H, bowMesh, null, RGBA.FromHex("#6BB6F0"), bp, new Vec3(scale, scale, scale), -0.3f,
                camPos, right, up, fwd, halfW, halfH, gobo);
        }
    }

    private static void DrawFloor(
        Canvas2D fb, float[] zbuf, int W, int H,
        Vec3 camPos, Vec3 right, Vec3 up, Vec3 fwd, float halfW, float halfH,
        LoadedTex floorTex, LoadedTex goboTex)
    {
        for (int y = 0; y < H; y++)
        {
            float ny = 1f - 2f * ((y + 0.5f) / H);
            for (int x = 0; x < W; x++)
            {
                float nx = 2f * ((x + 0.5f) / W) - 1f;
                Vec3 rayOrig = camPos + right * (nx * halfW) + up * (ny * halfH);
                float t = -rayOrig.Y / fwd.Y;
                Vec3 hit = rayOrig + fwd * t;
                var c = floorTex.Sample(hit.X * 0.65f + 0.5f, hit.Z * 0.65f + 0.5f, repeat: true);
                var g = goboTex.Sample(hit.X * 0.42f + 0.5f, hit.Z * 0.36f + 0.52f, repeat: false);
                float sun = 0.55f + 0.65f * g.R;
                fb.Pixels[y * W + x] = new RGBA(
                    SdfMath.Clamp(c.R * sun * 1.02f, 0, 1),
                    SdfMath.Clamp(c.G * sun * 0.99f, 0, 1),
                    SdfMath.Clamp(c.B * sun * 0.92f, 0, 1));
                zbuf[y * W + x] = t;
            }
        }
    }

    private static void DrawGridLines(Canvas2D fb, float[] zbuf, int W, int H, int cols, int rows, float boardZ,
        Vec3 camPos, Vec3 right, Vec3 up, Vec3 fwd, float halfW, float halfH)
    {
        float cell = 0.25f;
        var col = new RGBA(1f, 1f, 1f, 0.85f);
        void Line(Vec3 a, Vec3 b)
        {
            var (x0, y0, d0) = Project(a, camPos, right, up, fwd, halfW, halfH, W, H);
            var (x1, y1, d1) = Project(b, camPos, right, up, fwd, halfW, halfH, W, H);
            int steps = (int)MathF.Max(MathF.Abs(x1 - x0), MathF.Abs(y1 - y0)) + 1;
            for (int i = 0; i <= steps; i++)
            {
                float t = (float)i / Math.Max(1, steps);
                int px = (int)(x0 + (x1 - x0) * t), py = (int)(y0 + (y1 - y0) * t);
                float depth = d0 + (d1 - d0) * t;
                for (int dy = -1; dy <= 1; dy++)
                for (int dx = -1; dx <= 1; dx++)
                {
                    int xx = px + dx, yy = py + dy;
                    if ((uint)xx < (uint)W && (uint)yy < (uint)H && depth - 0.01f < zbuf[yy * W + xx])
                        fb.BlendPixel(xx, yy, col, 0.85f);
                }
            }
        }
        float halfWBoard = cols * cell * 0.5f;
        float halfHBoard = rows * cell * 0.5f;
        for (int c = 0; c <= cols; c++)
        {
            float x = -halfWBoard + c * cell;
            Line(new Vec3(x, 0.020f, boardZ - halfHBoard), new Vec3(x, 0.020f, boardZ + halfHBoard));
        }
        for (int r = 0; r <= rows; r++)
        {
            float z = boardZ - halfHBoard + r * cell;
            Line(new Vec3(-halfWBoard, 0.020f, z), new Vec3(halfWBoard, 0.020f, z));
        }
    }

    private static void DrawMesh(
        Canvas2D fb, float[] zbuf, int W, int H,
        LoadedMesh mesh, LoadedTex? tex, RGBA? solidColor,
        Vec3 pos, Vec3 scale, float yawRad,
        Vec3 camPos, Vec3 right, Vec3 up, Vec3 fwd, float halfW, float halfH,
        LoadedTex? gobo, bool isCat = false)
    {
        float cy = MathF.Cos(yawRad), sy = MathF.Sin(yawRad);
        Vec3 lightDir = new Vec3(0.35f, 0.88f, -0.32f).Normalized();
        Vec3 viewDir = (-fwd).Normalized();

        int vc = mesh.Pos.Length;
        var sx = new float[vc]; var syA = new float[vc]; var sz = new float[vc];
        var wPos = new Vec3[vc]; var wNorm = new Vec3[vc];
        for (int i = 0; i < vc; i++)
        {
            var lp = new Vec3(mesh.Pos[i].X * scale.X, mesh.Pos[i].Y * scale.Y, mesh.Pos[i].Z * scale.Z);
            var wp = new Vec3(lp.X * cy + lp.Z * sy + pos.X, lp.Y + pos.Y, -lp.X * sy + lp.Z * cy + pos.Z);
            var ln = mesh.Norm[i];
            var wn = new Vec3(ln.X * cy + ln.Z * sy, ln.Y, -ln.X * sy + ln.Z * cy).Normalized();
            wPos[i] = wp; wNorm[i] = wn;
            (sx[i], syA[i], sz[i]) = Project(wp, camPos, right, up, fwd, halfW, halfH, W, H);
        }

        for (int t = 0; t < mesh.Indices.Length; t += 3)
        {
            int i0 = mesh.Indices[t], i1 = mesh.Indices[t + 1], i2 = mesh.Indices[t + 2];
            float x0 = sx[i0], y0 = syA[i0], x1 = sx[i1], y1 = syA[i1], x2 = sx[i2], y2 = syA[i2];
            float area = (x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0);
            if (MathF.Abs(area) < 1e-4f) continue;

            int minX = Math.Max(0, (int)MathF.Floor(MathF.Min(x0, MathF.Min(x1, x2))));
            int maxX = Math.Min(W - 1, (int)MathF.Ceiling(MathF.Max(x0, MathF.Max(x1, x2))));
            int minY = Math.Max(0, (int)MathF.Floor(MathF.Min(y0, MathF.Min(y1, y2))));
            int maxY = Math.Min(H - 1, (int)MathF.Ceiling(MathF.Max(y0, MathF.Max(y1, y2))));

            float invArea = 1f / area;
            for (int py = minY; py <= maxY; py++)
            for (int px = minX; px <= maxX; px++)
            {
                float fx = px + 0.5f, fy = py + 0.5f;
                float w0 = ((x1 - fx) * (y2 - fy) - (y1 - fy) * (x2 - fx)) * invArea;
                float w1 = ((x2 - fx) * (y0 - fy) - (y2 - fy) * (x0 - fx)) * invArea;
                float w2 = 1f - w0 - w1;
                if (w0 < -1e-4f || w1 < -1e-4f || w2 < -1e-4f) continue;

                float depth = w0 * sz[i0] + w1 * sz[i1] + w2 * sz[i2];
                int idx = py * W + px;
                if (depth >= zbuf[idx]) continue;
                zbuf[idx] = depth;

                Vec3 n = (wNorm[i0] * w0 + wNorm[i1] * w1 + wNorm[i2] * w2).Normalized();
                Vec3 wp = wPos[i0] * w0 + wPos[i1] * w1 + wPos[i2] * w2;
                float u = mesh.UV[i0].X * w0 + mesh.UV[i1].X * w1 + mesh.UV[i2].X * w2;
                float v = mesh.UV[i0].Y * w0 + mesh.UV[i1].Y * w1 + mesh.UV[i2].Y * w2;

                RGBA baseCol = tex.HasValue ? tex.Value.Sample(u, v) : (solidColor ?? RGBA.FromHex("#FFFFFF"));

                float ndotl = SdfMath.Clamp(Vec3.Dot(n, lightDir), 0f, 1f);
                float ndotv = SdfMath.Clamp(Vec3.Dot(n, viewDir), 0f, 1f);
                float goboSun = gobo.HasValue ? (0.78f + 0.36f * gobo.Value.Sample(wp.X * 0.42f + 0.5f, wp.Z * 0.36f + 0.52f).R) : 1.0f;
                float shade = (0.56f + 0.54f * ndotl) * goboSun;

                if (isCat)
                {
                    // Soft stylized storybook ink rim matching MetalShaderModifiers!
                    float edgeInk = SdfMath.SmoothStep(0.08f, 0.42f, ndotv);
                    shade *= (0.76f + 0.24f * edgeInk);
                }

                fb.Pixels[idx] = new RGBA(
                    SdfMath.Clamp(baseCol.R * shade, 0, 1),
                    SdfMath.Clamp(baseCol.G * shade * 0.99f, 0, 1),
                    SdfMath.Clamp(baseCol.B * shade * 0.96f, 0, 1));
            }
        }
    }

    private static (Vec3 right, Vec3 up, Vec3 fwd) LookBasis(Vec3 pos, Vec3 target)
    {
        Vec3 fwd = (target - pos).Normalized();
        Vec3 right = Vec3.Cross(fwd, new Vec3(0, 1, 0)).Normalized();
        Vec3 up = Vec3.Cross(right, fwd).Normalized();
        return (right, up, fwd);
    }

    private static (float sx, float sy, float depth) Project(
        Vec3 wp, Vec3 camPos, Vec3 right, Vec3 up, Vec3 fwd, float halfW, float halfH, int W, int H)
    {
        Vec3 d = wp - camPos;
        float cx = Vec3.Dot(d, right);
        float cy = Vec3.Dot(d, up);
        float cz = Vec3.Dot(d, fwd);
        float sx = (cx / halfW * 0.5f + 0.5f) * W;
        float sy = (0.5f - cy / halfH * 0.5f) * H;
        return (sx, sy, cz);
    }

    private static LoadedMesh LoadCMesh(string path)
    {
        byte[] bytes = File.ReadAllBytes(path);
        int vc = (int)BinaryPrimitives.ReadUInt32LittleEndian(bytes.AsSpan(8, 4));
        int ic = (int)BinaryPrimitives.ReadUInt32LittleEndian(bytes.AsSpan(12, 4));
        var pos = new Vec3[vc]; var norm = new Vec3[vc]; var uv = new Vec2[vc];
        int off = 16;
        for (int i = 0; i < vc; i++)
        {
            pos[i]  = new Vec3(BitConverter.ToSingle(bytes, off), BitConverter.ToSingle(bytes, off + 4), BitConverter.ToSingle(bytes, off + 8));
            norm[i] = new Vec3(BitConverter.ToSingle(bytes, off + 12), BitConverter.ToSingle(bytes, off + 16), BitConverter.ToSingle(bytes, off + 20));
            uv[i]   = new Vec2(BitConverter.ToSingle(bytes, off + 24), BitConverter.ToSingle(bytes, off + 28));
            off += 48;
        }
        var idx = new int[ic];
        for (int i = 0; i < ic; i++)
        {
            idx[i] = (int)BinaryPrimitives.ReadUInt32LittleEndian(bytes.AsSpan(off, 4));
            off += 4;
        }
        return new LoadedMesh { Pos = pos, Norm = norm, UV = uv, Indices = idx };
    }

    private static LoadedTex LoadPng(string path)
    {
        byte[] b = File.ReadAllBytes(path);
        int pos = 8, w = 0, h = 0;
        using var idat = new MemoryStream();
        while (pos + 8 <= b.Length)
        {
            int len = BinaryPrimitives.ReadInt32BigEndian(b.AsSpan(pos, 4));
            string type = Encoding.ASCII.GetString(b, pos + 4, 4);
            pos += 8;
            if (type == "IHDR")
            {
                w = BinaryPrimitives.ReadInt32BigEndian(b.AsSpan(pos, 4));
                h = BinaryPrimitives.ReadInt32BigEndian(b.AsSpan(pos + 4, 4));
            }
            else if (type == "IDAT") idat.Write(b, pos, len);
            pos += len + 4;
        }
        idat.Position = 0;
        using var z = new ZLibStream(idat, CompressionMode.Decompress);
        int rowBytes = 1 + w * 4;
        byte[] raw = new byte[rowBytes * h];
        int read = 0;
        while (read < raw.Length)
        {
            int r = z.Read(raw, read, raw.Length - read);
            if (r <= 0) break;
            read += r;
        }
        var px = new RGBA[w * h];
        for (int y = 0; y < h; y++)
        {
            int rOff = y * rowBytes + 1;
            for (int x = 0; x < w; x++)
            {
                int o = rOff + x * 4;
                px[y * w + x] = new RGBA(raw[o] / 255f, raw[o + 1] / 255f, raw[o + 2] / 255f, raw[o + 3] / 255f);
            }
        }
        return new LoadedTex { W = w, H = h, Px = px };
    }
}
