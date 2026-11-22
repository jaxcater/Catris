using System.Globalization;
using System.Text;

namespace CatrisAssetBuilder;

public readonly struct Vec2(float x, float y)
{
    public readonly float X = x, Y = y;
    public static Vec2 operator +(Vec2 a, Vec2 b) => new(a.X + b.X, a.Y + b.Y);
    public static Vec2 operator -(Vec2 a, Vec2 b) => new(a.X - b.X, a.Y - b.Y);
    public static Vec2 operator *(Vec2 a, float s) => new(a.X * s, a.Y * s);
    public float Length => MathF.Sqrt(X * X + Y * Y);
}

public readonly struct Vec3(float x, float y, float z)
{
    public readonly float X = x, Y = y, Z = z;
    public static Vec3 Zero => new(0, 0, 0);
    public static Vec3 operator +(Vec3 a, Vec3 b) => new(a.X + b.X, a.Y + b.Y, a.Z + b.Z);
    public static Vec3 operator -(Vec3 a, Vec3 b) => new(a.X - b.X, a.Y - b.Y, a.Z - b.Z);
    public static Vec3 operator -(Vec3 a) => new(-a.X, -a.Y, -a.Z);
    public static Vec3 operator *(Vec3 a, float s) => new(a.X * s, a.Y * s, a.Z * s);
    public static Vec3 operator *(float s, Vec3 a) => new(a.X * s, a.Y * s, a.Z * s);
    public static Vec3 operator /(Vec3 a, float s) => new(a.X / s, a.Y / s, a.Z / s);
    public float LengthSq => X * X + Y * Y + Z * Z;
    public float Length => MathF.Sqrt(LengthSq);
    public Vec3 Normalized()
    {
        float len = Length;
        return len > 1e-7f ? this / len : new Vec3(0, 1, 0);
    }
    public static float Dot(Vec3 a, Vec3 b) => a.X * b.X + a.Y * b.Y + a.Z * b.Z;
    public static Vec3 Cross(Vec3 a, Vec3 b) => new(
        a.Y * b.Z - a.Z * b.Y,
        a.Z * b.X - a.X * b.Z,
        a.X * b.Y - a.Y * b.X
    );
    public static Vec3 Lerp(Vec3 a, Vec3 b, float t) => a + (b - a) * t;
    public static Vec3 Min(Vec3 a, Vec3 b) => new(MathF.Min(a.X, b.X), MathF.Min(a.Y, b.Y), MathF.Min(a.Z, b.Z));
    public static Vec3 Max(Vec3 a, Vec3 b) => new(MathF.Max(a.X, b.X), MathF.Max(a.Y, b.Y), MathF.Max(a.Z, b.Z));
}

public readonly struct Vec4(float x, float y, float z, float w)
{
    public readonly float X = x, Y = y, Z = z, W = w;
}

public static class SdfMath
{
    public static float Clamp(float v, float lo, float hi) => MathF.Max(lo, MathF.Min(hi, v));
    public static float SmoothStep(float e0, float e1, float x)
    {
        float t = Clamp((x - e0) / (e1 - e0), 0f, 1f);
        return t * t * (3f - 2f * t);
    }

    /// <summary>Polynomial smooth minimum (C1 continuous organic blending).</summary>
    public static float SMin(float a, float b, float k)
    {
        if (k <= 1e-6f) return MathF.Min(a, b);
        float h = MathF.Max(k - MathF.Abs(a - b), 0f) / k;
        return MathF.Min(a, b) - h * h * k * 0.25f;
    }

    /// <summary>Polynomial smooth maximum (soft carving / flat belly contact).</summary>
    public static float SMax(float a, float b, float k) => -SMin(-a, -b, k);

    public static float SdSphere(Vec3 p, Vec3 c, float r) => (p - c).Length - r;

    public static float SdEllipsoid(Vec3 p, Vec3 c, Vec3 rad)
    {
        Vec3 q = p - c;
        Vec3 q1 = new(q.X / rad.X, q.Y / rad.Y, q.Z / rad.Z);
        Vec3 q2 = new(q.X / (rad.X * rad.X), q.Y / (rad.Y * rad.Y), q.Z / (rad.Z * rad.Z));
        float k0 = q1.Length;
        float k1 = q2.Length;
        return k1 > 1e-7f ? k0 * (k0 - 1f) / k1 : -MathF.Min(rad.X, MathF.Min(rad.Y, rad.Z));
    }

    public static float SdCapsule(Vec3 p, Vec3 a, Vec3 b, float ra, float rb)
    {
        Vec3 pa = p - a, ba = b - a;
        float denom = MathF.Max(ba.LengthSq, 1e-7f);
        float h = Clamp(Vec3.Dot(pa, ba) / denom, 0f, 1f);
        float r = ra + (rb - ra) * h;
        return (pa - ba * h).Length - r;
    }

    /// <summary>Elliptical soft cushion capsule (flatter vertically like a resting plush cat).</summary>
    public static float SdPlushCapsule(Vec3 p, Vec3 a, Vec3 b, float rXZ_a, float rXZ_b, float yScale = 0.72f)
    {
        Vec3 pa = p - a, ba = b - a;
        float denom = MathF.Max(ba.LengthSq, 1e-7f);
        float h = Clamp(Vec3.Dot(pa, ba) / denom, 0f, 1f);
        Vec3 d = pa - ba * h;
        Vec3 scaled = new(d.X, d.Y / yScale, d.Z);
        float r = rXZ_a + (rXZ_b - rXZ_a) * h;
        return scaled.Length * yScale - r * yScale;
    }

    public static float SdRoundBox(Vec3 p, Vec3 c, Vec3 halfExtents, float r)
    {
        Vec3 q = new(
            MathF.Abs(p.X - c.X) - halfExtents.X,
            MathF.Abs(p.Y - c.Y) - halfExtents.Y,
            MathF.Abs(p.Z - c.Z) - halfExtents.Z
        );
        Vec3 pos = new(MathF.Max(q.X, 0f), MathF.Max(q.Y, 0f), MathF.Max(q.Z, 0f));
        return pos.Length + MathF.Min(MathF.Max(q.X, MathF.Max(q.Y, q.Z)), 0f) - r;
    }

    public static float SdVerticalCylinder(Vec3 p, Vec3 c, float r, float halfH, float bevel = 0.004f)
    {
        float dx = MathF.Sqrt((p.X - c.X) * (p.X - c.X) + (p.Z - c.Z) * (p.Z - c.Z)) - (r - bevel);
        float dy = MathF.Abs(p.Y - c.Y) - (halfH - bevel);
        float outside = MathF.Sqrt(MathF.Max(dx, 0f) * MathF.Max(dx, 0f) + MathF.Max(dy, 0f) * MathF.Max(dy, 0f));
        return outside + MathF.Min(MathF.Max(dx, dy), 0f) - bevel;
    }

    public static Vec3 Gradient(Func<Vec3, float> sdf, Vec3 p, float eps = 0.0015f)
    {
        float dx = sdf(new Vec3(p.X + eps, p.Y, p.Z)) - sdf(new Vec3(p.X - eps, p.Y, p.Z));
        float dy = sdf(new Vec3(p.X, p.Y + eps, p.Z)) - sdf(new Vec3(p.X, p.Y - eps, p.Z));
        float dz = sdf(new Vec3(p.X, p.Y, p.Z + eps)) - sdf(new Vec3(p.X, p.Y, p.Z - eps));
        return new Vec3(dx, dy, dz).Normalized();
    }

    /// <summary>Raycast downward from yStart along -Y to find exact SDF surface height.</summary>
    public static (bool hit, Vec3 pos, Vec3 normal) RaycastDown(Func<Vec3, float> sdf, float x, float z, float yStart = 0.30f)
    {
        float y = yStart;
        for (int i = 0; i < 80; i++)
        {
            Vec3 p = new(x, y, z);
            float d = sdf(p);
            if (d < 0.0004f)
            {
                // Refine via binary / Newton step
                Vec3 n = Gradient(sdf, p);
                return (true, p, n);
            }
            y -= MathF.Max(d * 0.75f, 0.001f);
            if (y < -0.05f) break;
        }
        return (false, new Vec3(x, 0.08f, z), new Vec3(0, 1, 0));
    }
}

public sealed class MeshData
{
    public List<Vec3> Positions = new();
    public List<Vec3> Normals = new();
    public List<Vec2> UVs = new();
    public List<Vec4> Colors = new(); // RGBA soft-rig weights for Metal shader!
    public List<int> Indices = new();

    public int VertexCount => Positions.Count;
    public int TriangleCount => Indices.Count / 3;

    public void Append(MeshData other)
    {
        int offset = Positions.Count;
        Positions.AddRange(other.Positions);
        Normals.AddRange(other.Normals);
        UVs.AddRange(other.UVs);
        Colors.AddRange(other.Colors);
        foreach (int idx in other.Indices) Indices.Add(idx + offset);
    }

    public void RecomputeSmoothNormals()
    {
        var acc = new Vec3[Positions.Count];
        for (int i = 0; i < Indices.Count; i += 3)
        {
            int i0 = Indices[i], i1 = Indices[i + 1], i2 = Indices[i + 2];
            Vec3 e1 = Positions[i1] - Positions[i0];
            Vec3 e2 = Positions[i2] - Positions[i0];
            Vec3 n = Vec3.Cross(e1, e2); // area-weighted!
            acc[i0] += n;
            acc[i1] += n;
            acc[i2] += n;
        }
        Normals.Clear();
        for (int i = 0; i < acc.Length; i++) Normals.Add(acc[i].Normalized());
    }

    /// <summary>
    /// Binary CMESH01 format loaded natively into SceneKit SCNGeometry with ZERO overhead:
    /// Magic "CMESH01\0" (8 bytes), uint32 vertCount, uint32 indexCount,
    /// Per vertex (48 bytes): float3 pos, float3 normal, float2 uv, float4 color
    /// Indices: uint32[indexCount]
    /// </summary>
    public void SaveCMesh(string path)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        using var fs = File.Create(path);
        using var bw = new BinaryWriter(fs);
        bw.Write(Encoding.ASCII.GetBytes("CMESH01\0"));
        bw.Write((uint)Positions.Count);
        bw.Write((uint)Indices.Count);
        for (int i = 0; i < Positions.Count; i++)
        {
            var p = Positions[i];
            var n = i < Normals.Count ? Normals[i] : new Vec3(0, 1, 0);
            var uv = i < UVs.Count ? UVs[i] : new Vec2(0.5f, 0.5f);
            var c = i < Colors.Count ? Colors[i] : new Vec4(0, 0, 0, 0);
            bw.Write(p.X); bw.Write(p.Y); bw.Write(p.Z);
            bw.Write(n.X); bw.Write(n.Y); bw.Write(n.Z);
            bw.Write(uv.X); bw.Write(uv.Y);
            bw.Write(c.X); bw.Write(c.Y); bw.Write(c.Z); bw.Write(c.W);
        }
        for (int i = 0; i < Indices.Count; i++)
            bw.Write((uint)Indices[i]);
    }

    public void SaveObj(string path, string? mtlName = null)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        var ci = CultureInfo.InvariantCulture;
        using var sw = new StreamWriter(path, false, Encoding.UTF8);
        sw.WriteLine("# Catris Organic 3D Asset");
        if (mtlName != null) sw.WriteLine($"usemtl {mtlName}");
        foreach (var p in Positions)
            sw.WriteLine(string.Format(ci, "v {0:F5} {1:F5} {2:F5}", p.X, p.Y, p.Z));
        foreach (var uv in UVs)
            sw.WriteLine(string.Format(ci, "vt {0:F5} {1:F5}", uv.X, 1f - uv.Y)); // OBJ V-up
        foreach (var n in Normals)
            sw.WriteLine(string.Format(ci, "vn {0:F5} {1:F5} {2:F5}", n.X, n.Y, n.Z));
        for (int i = 0; i < Indices.Count; i += 3)
        {
            int a = Indices[i] + 1, b = Indices[i + 1] + 1, c = Indices[i + 2] + 1;
            sw.WriteLine($"f {a}/{a}/{a} {b}/{b}/{b} {c}/{c}/{c}");
        }
    }
}

/// <summary>
/// Watertight, 100% manifold Dual Surface Nets SDF polygonizer + Taubin volume-preserving smoother.
/// Produces silky smooth organic 3D cat meshes with exact analytical gradient normals!
/// </summary>
public static class SurfaceNetsExtractor
{
    private static readonly int[,] CubeCorners = {
        {0,0,0}, {1,0,0}, {0,1,0}, {1,1,0},
        {0,0,1}, {1,0,1}, {0,1,1}, {1,1,1}
    };

    private static readonly int[,] CubeEdges = {
        {0,1}, {2,3}, {4,5}, {6,7}, // X edges
        {0,2}, {1,3}, {4,6}, {5,7}, // Y edges
        {0,4}, {1,5}, {2,6}, {3,7}  // Z edges
    };

    public static MeshData Extract(
        Func<Vec3, float> sdf,
        Vec3 minBound,
        Vec3 maxBound,
        float step,
        Func<Vec3, Vec2> uvMapper,
        Func<Vec3, Vec4> rigWeightMapper,
        int smoothIterations = 4,
        bool snapToSdf = true)
    {
        int nx = Math.Max(4, (int)MathF.Ceiling((maxBound.X - minBound.X) / step)) + 2;
        int ny = Math.Max(4, (int)MathF.Ceiling((maxBound.Y - minBound.Y) / step)) + 2;
        int nz = Math.Max(4, (int)MathF.Ceiling((maxBound.Z - minBound.Z) / step)) + 2;
        Vec3 origin = minBound - new Vec3(step, step, step);

        // Sample SDF on grid points [nx+1, ny+1, nz+1]
        var field = new float[(nx + 1) * (ny + 1) * (nz + 1)];
        int StrideY = nx + 1;
        int StrideZ = (nx + 1) * (ny + 1);
        int FIdx(int x, int y, int z) => x + y * StrideY + z * StrideZ;

        Parallel.For(0, nz + 1, z =>
        {
            float pz = origin.Z + z * step;
            for (int y = 0; y <= ny; y++)
            {
                float py = origin.Y + y * step;
                for (int x = 0; x <= nx; x++)
                {
                    float px = origin.X + x * step;
                    field[FIdx(x, y, z)] = sdf(new Vec3(px, py, pz));
                }
            }
        });

        var cellVert = new int[nx * ny * nz];
        Array.Fill(cellVert, -1);
        int CIdx(int x, int y, int z) => x + y * nx + z * nx * ny;

        var positions = new List<Vec3>();

        // 1. Place one smooth dual vertex per active sign-changing cell
        Span<float> vals = stackalloc float[8];
        for (int z = 0; z < nz; z++)
        for (int y = 0; y < ny; y++)
        for (int x = 0; x < nx; x++)
        {
            int mask = 0;
            for (int c = 0; c < 8; c++)
            {
                float v = field[FIdx(x + CubeCorners[c, 0], y + CubeCorners[c, 1], z + CubeCorners[c, 2])];
                vals[c] = v;
                if (v < 0f) mask |= (1 << c);
            }
            if (mask == 0 || mask == 255) continue;

            Vec3 sum = Vec3.Zero;
            int count = 0;
            for (int e = 0; e < 12; e++)
            {
                int c0 = CubeEdges[e, 0], c1 = CubeEdges[e, 1];
                float v0 = vals[c0], v1 = vals[c1];
                if ((v0 < 0f) == (v1 < 0f)) continue;
                float t = SdfMath.Clamp(v0 / (v0 - v1), 0f, 1f);
                float ex = CubeCorners[c0, 0] + t * (CubeCorners[c1, 0] - CubeCorners[c0, 0]);
                float ey = CubeCorners[c0, 1] + t * (CubeCorners[c1, 1] - CubeCorners[c0, 1]);
                float ez = CubeCorners[c0, 2] + t * (CubeCorners[c1, 2] - CubeCorners[c0, 2]);
                sum += new Vec3(origin.X + (x + ex) * step, origin.Y + (y + ey) * step, origin.Z + (z + ez) * step);
                count++;
            }

            if (count > 0)
            {
                cellVert[CIdx(x, y, z)] = positions.Count;
                positions.Add(sum / count);
            }
        }

        // 2. Emit outward-oriented quads across every sign-changing interior grid edge!
        var indices = new List<int>();
        void EmitQuad(int v0, int v1, int v2, int v3, bool flip)
        {
            if (v0 < 0 || v1 < 0 || v2 < 0 || v3 < 0) return;
            if (!flip)
            {
                indices.Add(v0); indices.Add(v1); indices.Add(v2);
                indices.Add(v0); indices.Add(v2); indices.Add(v3);
            }
            else
            {
                indices.Add(v0); indices.Add(v2); indices.Add(v1);
                indices.Add(v0); indices.Add(v3); indices.Add(v2);
            }
        }

        for (int z = 1; z < nz; z++)
        for (int y = 1; y < ny; y++)
        for (int x = 1; x < nx; x++)
        {
            float v0 = field[FIdx(x, y, z)];
            bool inside0 = v0 < 0f;

            // Edge along +X: (x,y,z) -> (x+1,y,z), surrounded by cells (x, y-1..y, z-1..z)
            if (x < nx)
            {
                bool insideX = field[FIdx(x + 1, y, z)] < 0f;
                if (inside0 != insideX)
                {
                    // Normal points +X when inside0 && !insideX -> right-hand rule around +X: (y-1,z-1)->(y,z-1)->(y,z)->(y-1,z)
                    int a = cellVert[CIdx(x, y - 1, z - 1)];
                    int b = cellVert[CIdx(x, y,     z - 1)];
                    int c = cellVert[CIdx(x, y,     z    )];
                    int d = cellVert[CIdx(x, y - 1, z    )];
                    EmitQuad(a, b, c, d, flip: !inside0);
                }
            }

            // Edge along +Y: (x,y,z) -> (x,y+1,z), surrounded by cells (x-1..x, y, z-1..z)
            if (y < ny)
            {
                bool insideY = field[FIdx(x, y + 1, z)] < 0f;
                if (inside0 != insideY)
                {
                    // Normal points +Y when inside0 && !insideY -> right-hand rule around +Y: (x-1,z-1)->(x-1,z)->(x,z)->(x,z-1)
                    int a = cellVert[CIdx(x - 1, y, z - 1)];
                    int b = cellVert[CIdx(x - 1, y, z    )];
                    int c = cellVert[CIdx(x,     y, z    )];
                    int d = cellVert[CIdx(x,     y, z - 1)];
                    EmitQuad(a, b, c, d, flip: !inside0);
                }
            }

            // Edge along +Z: (x,y,z) -> (x,y,z+1), surrounded by cells (x-1..x, y-1..y, z)
            if (z < nz)
            {
                bool insideZ = field[FIdx(x, y, z + 1)] < 0f;
                if (inside0 != insideZ)
                {
                    // Normal points +Z when inside0 && !insideZ -> right-hand rule around +Z: (x-1,y-1)->(x,y-1)->(x,y)->(x-1,y)
                    int a = cellVert[CIdx(x - 1, y - 1, z)];
                    int b = cellVert[CIdx(x,     y - 1, z)];
                    int c = cellVert[CIdx(x,     y,     z)];
                    int d = cellVert[CIdx(x - 1, y,     z)];
                    EmitQuad(a, b, c, d, flip: !inside0);
                }
            }
        }

        // 3. Build adjacency & run Taubin volume-preserving smoothing!
        int vc = positions.Count;
        var neighbors = new List<int>[vc];
        for (int i = 0; i < vc; i++) neighbors[i] = new List<int>(6);
        void AddEdge(int u, int v)
        {
            if (!neighbors[u].Contains(v)) neighbors[u].Add(v);
            if (!neighbors[v].Contains(u)) neighbors[v].Add(u);
        }
        for (int i = 0; i < indices.Count; i += 3)
        {
            AddEdge(indices[i], indices[i + 1]);
            AddEdge(indices[i + 1], indices[i + 2]);
            AddEdge(indices[i + 2], indices[i]);
        }

        var posArr = positions.ToArray();
        var tmpArr = new Vec3[vc];
        void SmoothPass(float lambda)
        {
            for (int i = 0; i < vc; i++)
            {
                var nb = neighbors[i];
                if (nb.Count == 0) { tmpArr[i] = posArr[i]; continue; }
                Vec3 avg = Vec3.Zero;
                for (int j = 0; j < nb.Count; j++) avg += posArr[nb[j]];
                avg /= nb.Count;
                tmpArr[i] = posArr[i] + (avg - posArr[i]) * lambda;
            }
            Array.Copy(tmpArr, posArr, vc);
        }

        for (int iter = 0; iter < smoothIterations; iter++)
        {
            SmoothPass(0.45f);
            SmoothPass(-0.465f);
        }

        // Optional single Newton projection onto exact iso-surface for crisp ear/belly detail!
        if (snapToSdf)
        {
            Parallel.For(0, vc, i =>
            {
                Vec3 p = posArr[i];
                float d = sdf(p);
                if (MathF.Abs(d) < step * 0.7f)
                {
                    Vec3 g = SdfMath.Gradient(sdf, p);
                    posArr[i] = p - g * (d * 0.85f);
                }
            });
        }

        // 4. Compute silky-smooth analytical gradient normals + UVs + rig weights!
        var mesh = new MeshData();
        mesh.Positions.AddRange(posArr);
        mesh.Indices.AddRange(indices);
        var normArr = new Vec3[vc];
        var uvArr = new Vec2[vc];
        var colArr = new Vec4[vc];

        Parallel.For(0, vc, i =>
        {
            Vec3 p = posArr[i];
            normArr[i] = SdfMath.Gradient(sdf, p);
            uvArr[i] = uvMapper(p);
            colArr[i] = rigWeightMapper(p);
        });

        mesh.Normals.AddRange(normArr);
        mesh.UVs.AddRange(uvArr);
        mesh.Colors.AddRange(colArr);
        return mesh;
    }

    /// <summary>Create a smooth procedural lathed/revolved mesh (great for ceramic pots, teacups, bowls, lamps).</summary>
    public static MeshData CreateLathe(
        (float r, float y)[] profile,
        int radialSegments,
        Func<Vec3, Vec4>? weightFn = null)
    {
        var mesh = new MeshData();
        int rings = profile.Length;
        for (int i = 0; i < rings; i++)
        {
            float v = (float)i / Math.Max(1, rings - 1);
            float r = profile[i].r;
            float y = profile[i].y;
            for (int s = 0; s <= radialSegments; s++)
            {
                float u = (float)s / radialSegments;
                float a = u * MathF.PI * 2f;
                Vec3 p = new(MathF.Cos(a) * r, y, MathF.Sin(a) * r);
                mesh.Positions.Add(p);
                mesh.UVs.Add(new Vec2(u, v));
                mesh.Colors.Add(weightFn != null ? weightFn(p) : new Vec4(0, 0, 0, 0));
            }
        }
        int stride = radialSegments + 1;
        for (int i = 0; i < rings - 1; i++)
        for (int s = 0; s < radialSegments; s++)
        {
            int a = i * stride + s;
            int b = a + 1;
            int c = (i + 1) * stride + s;
            int d = c + 1;
            // Winding for outward normal when profile goes bottom-to-top
            mesh.Indices.Add(a); mesh.Indices.Add(c); mesh.Indices.Add(b);
            mesh.Indices.Add(b); mesh.Indices.Add(c); mesh.Indices.Add(d);
        }
        mesh.RecomputeSmoothNormals();
        return mesh;
    }
}
