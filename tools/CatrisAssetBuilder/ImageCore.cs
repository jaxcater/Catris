using System.Buffers.Binary;
using System.IO.Compression;

namespace CatrisAssetBuilder;

public readonly struct RGBA(float r, float g, float b, float a = 1f)
{
    public readonly float R = r, G = g, B = b, A = a;

    public static RGBA FromHex(string hex, float a = 1f)
    {
        hex = hex.TrimStart('#');
        byte r = Convert.ToByte(hex.Substring(0, 2), 16);
        byte g = Convert.ToByte(hex.Substring(2, 2), 16);
        byte b = Convert.ToByte(hex.Substring(4, 2), 16);
        return new RGBA(r / 255f, g / 255f, b / 255f, a);
    }

    public static RGBA Lerp(RGBA x, RGBA y, float t)
    {
        t = SdfMath.Clamp(t, 0f, 1f);
        return new RGBA(
            x.R + (y.R - x.R) * t,
            x.G + (y.G - x.G) * t,
            x.B + (y.B - x.B) * t,
            x.A + (y.A - x.A) * t
        );
    }

    public RGBA Shade(float factor) => new(
        SdfMath.Clamp(R * factor, 0f, 1f),
        SdfMath.Clamp(G * factor, 0f, 1f),
        SdfMath.Clamp(B * factor, 0f, 1f),
        A
    );
}

public static class Noise2D
{
    private static uint Hash(int x, int y, int seed)
    {
        unchecked
        {
            uint h = (uint)(x * 374761393 + y * 668265263 + seed * 1442695041);
            h = (h ^ (h >> 13)) * 1274126177u;
            return h ^ (h >> 16);
        }
    }

    public static float Value(float x, float y, int seed = 0)
    {
        int ix = (int)MathF.Floor(x), iy = (int)MathF.Floor(y);
        float fx = x - ix, fy = y - iy;
        float ux = fx * fx * (3f - 2f * fx);
        float uy = fy * fy * (3f - 2f * fy);
        float n00 = (Hash(ix, iy, seed) & 0xFFFF) / 65535f;
        float n10 = (Hash(ix + 1, iy, seed) & 0xFFFF) / 65535f;
        float n01 = (Hash(ix, iy + 1, seed) & 0xFFFF) / 65535f;
        float n11 = (Hash(ix + 1, iy + 1, seed) & 0xFFFF) / 65535f;
        float nx0 = n00 + (n10 - n00) * ux;
        float nx1 = n01 + (n11 - n01) * ux;
        return nx0 + (nx1 - nx0) * uy;
    }

    public static float Fbm(float x, float y, int octaves = 4, int seed = 0)
    {
        float sum = 0f, amp = 0.5f, norm = 0f;
        for (int i = 0; i < octaves; i++)
        {
            sum += Value(x, y, seed + i * 31) * amp;
            norm += amp;
            x *= 2.03f; y *= 2.03f; amp *= 0.5f;
        }
        return sum / norm;
    }
}

public sealed class Canvas2D
{
    public readonly int Width;
    public readonly int Height;
    public readonly RGBA[] Pixels;

    public Canvas2D(int width, int height, RGBA fill)
    {
        Width = width;
        Height = height;
        Pixels = new RGBA[width * height];
        Array.Fill(Pixels, fill);
    }

    public void BlendPixel(int x, int y, RGBA src, float coverage = 1f)
    {
        if ((uint)x >= (uint)Width || (uint)y >= (uint)Height) return;
        float alpha = SdfMath.Clamp(src.A * coverage, 0f, 1f);
        if (alpha <= 1e-4f) return;
        int idx = y * Width + x;
        var dst = Pixels[idx];
        float outA = alpha + dst.A * (1f - alpha);
        if (outA <= 1e-5f) return;
        float r = (src.R * alpha + dst.R * dst.A * (1f - alpha)) / outA;
        float g = (src.G * alpha + dst.G * dst.A * (1f - alpha)) / outA;
        float b = (src.B * alpha + dst.B * dst.A * (1f - alpha)) / outA;
        Pixels[idx] = new RGBA(r, g, b, outA);
    }

    public void FillFunc(Func<float, float, RGBA> fn)
    {
        Parallel.For(0, Height, y =>
        {
            float v = (y + 0.5f) / Height;
            for (int x = 0; x < Width; x++)
            {
                float u = (x + 0.5f) / Width;
                Pixels[y * Width + x] = fn(u, v);
            }
        });
    }

    public void PaintSoftCircle(float cx, float cy, float rx, float ry, RGBA col, float softness = 0.08f)
    {
        int x0 = Math.Max(0, (int)((cx - rx - softness) * Width) - 2);
        int x1 = Math.Min(Width - 1, (int)((cx + rx + softness) * Width) + 2);
        int y0 = Math.Max(0, (int)((cy - ry - softness) * Height) - 2);
        int y1 = Math.Min(Height - 1, (int)((cy + ry + softness) * Height) + 2);
        for (int y = y0; y <= y1; y++)
        {
            float v = (y + 0.5f) / Height;
            for (int x = x0; x <= x1; x++)
            {
                float u = (x + 0.5f) / Width;
                float dx = (u - cx) / MathF.Max(rx, 1e-4f);
                float dy = (v - cy) / MathF.Max(ry, 1e-4f);
                float d = MathF.Sqrt(dx * dx + dy * dy);
                float cov = 1f - SdfMath.SmoothStep(1f - softness, 1f + softness, d);
                if (cov > 0f) BlendPixel(x, y, col, cov);
            }
        }
    }

    public void PaintCapsule(float x0, float y0, float x1, float y1, float radius, RGBA col, float softness = 0.006f)
    {
        float pad = radius + softness + 0.01f;
        int px0 = Math.Max(0, (int)((MathF.Min(x0, x1) - pad) * Width));
        int px1 = Math.Min(Width - 1, (int)((MathF.Max(x0, x1) + pad) * Width));
        int py0 = Math.Max(0, (int)((MathF.Min(y0, y1) - pad) * Height));
        int py1 = Math.Min(Height - 1, (int)((MathF.Max(y0, y1) + pad) * Height));
        float dx = x1 - x0, dy = y1 - y0;
        float lenSq = MathF.Max(dx * dx + dy * dy, 1e-7f);
        for (int y = py0; y <= py1; y++)
        {
            float v = (y + 0.5f) / Height;
            for (int x = px0; x <= px1; x++)
            {
                float u = (x + 0.5f) / Width;
                float t = SdfMath.Clamp(((u - x0) * dx + (v - y0) * dy) / lenSq, 0f, 1f);
                float d = MathF.Sqrt((u - (x0 + dx * t)) * (u - (x0 + dx * t)) + (v - (y0 + dy * t)) * (v - (y0 + dy * t)));
                float cov = 1f - SdfMath.SmoothStep(radius - softness, radius + softness, d);
                if (cov > 0f) BlendPixel(x, y, col, cov);
            }
        }
    }

    public void PaintRoundedRect(float cx, float cy, float hw, float hh, float r, RGBA col, float softness = 0.004f)
    {
        float pad = softness + 0.01f;
        int px0 = Math.Max(0, (int)((cx - hw - pad) * Width));
        int px1 = Math.Min(Width - 1, (int)((cx + hw + pad) * Width));
        int py0 = Math.Max(0, (int)((cy - hh - pad) * Height));
        int py1 = Math.Min(Height - 1, (int)((cy + hh + pad) * Height));
        for (int y = py0; y <= py1; y++)
        {
            float v = (y + 0.5f) / Height;
            for (int x = px0; x <= px1; x++)
            {
                float u = (x + 0.5f) / Width;
                float qx = MathF.Abs(u - cx) - (hw - r);
                float qy = MathF.Abs(v - cy) - (hh - r);
                float d = MathF.Sqrt(MathF.Max(qx, 0f) * MathF.Max(qx, 0f) + MathF.Max(qy, 0f) * MathF.Max(qy, 0f))
                        + MathF.Min(MathF.Max(qx, qy), 0f) - r;
                float cov = 1f - SdfMath.SmoothStep(-softness, softness, d);
                if (cov > 0f) BlendPixel(x, y, col, cov);
            }
        }
    }

    public static Canvas2D HeightToNormalMap(float[] heightField, int w, int h, float strength = 2.0f)
    {
        var img = new Canvas2D(w, h, new RGBA(0.5f, 0.5f, 1f, 1f));
        Parallel.For(0, h, y =>
        {
            int ym = (y - 1 + h) % h, yp = (y + 1) % h;
            for (int x = 0; x < w; x++)
            {
                int xm = (x - 1 + w) % w, xp = (x + 1) % w;
                float dx = (heightField[y * w + xp] - heightField[y * w + xm]) * strength;
                float dy = (heightField[yp * w + x] - heightField[ym * w + x]) * strength;
                var n = new Vec3(-dx, -dy, 1f).Normalized();
                img.Pixels[y * w + x] = new RGBA(n.X * 0.5f + 0.5f, n.Y * 0.5f + 0.5f, n.Z * 0.5f + 0.5f, 1f);
            }
        });
        return img;
    }

    /// <summary>Zero-dependency IEEE-compliant 32-bit RGBA PNG writer.</summary>
    public void SavePng(string path)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        using var fs = File.Create(path);
        // PNG signature
        fs.Write([137, 80, 78, 71, 13, 10, 26, 10]);

        // IHDR
        byte[] ihdr = new byte[13];
        BinaryPrimitives.WriteInt32BigEndian(ihdr.AsSpan(0, 4), Width);
        BinaryPrimitives.WriteInt32BigEndian(ihdr.AsSpan(4, 4), Height);
        ihdr[8] = 8; // bit depth
        ihdr[9] = 6; // RGBA
        WriteChunk(fs, "IHDR", ihdr);

        // Scanlines: filter byte 0 (None) + RGBA
        int rowBytes = 1 + Width * 4;
        byte[] raw = new byte[rowBytes * Height];
        for (int y = 0; y < Height; y++)
        {
            int rowOff = y * rowBytes;
            raw[rowOff] = 0;
            int srcOff = y * Width;
            for (int x = 0; x < Width; x++)
            {
                var p = Pixels[srcOff + x];
                int o = rowOff + 1 + x * 4;
                raw[o + 0] = (byte)SdfMath.Clamp(p.R * 255f + 0.5f, 0f, 255f);
                raw[o + 1] = (byte)SdfMath.Clamp(p.G * 255f + 0.5f, 0f, 255f);
                raw[o + 2] = (byte)SdfMath.Clamp(p.B * 255f + 0.5f, 0f, 255f);
                raw[o + 3] = (byte)SdfMath.Clamp(p.A * 255f + 0.5f, 0f, 255f);
            }
        }

        using var ms = new MemoryStream();
        using (var zlib = new ZLibStream(ms, CompressionLevel.Fastest, leaveOpen: true))
            zlib.Write(raw, 0, raw.Length);
        WriteChunk(fs, "IDAT", ms.ToArray());
        WriteChunk(fs, "IEND", []);
    }

    private static readonly uint[] CrcTable = BuildCrcTable();
    private static uint[] BuildCrcTable()
    {
        var t = new uint[256];
        for (uint n = 0; n < 256; n++)
        {
            uint c = n;
            for (int k = 0; k < 8; k++) c = (c & 1) != 0 ? 0xedb88320u ^ (c >> 1) : (c >> 1);
            t[n] = c;
        }
        return t;
    }

    private static void WriteChunk(Stream s, string type, byte[] data)
    {
        byte[] len = new byte[4];
        BinaryPrimitives.WriteInt32BigEndian(len, data.Length);
        s.Write(len);
        byte[] tb = System.Text.Encoding.ASCII.GetBytes(type);
        s.Write(tb);
        if (data.Length > 0) s.Write(data);
        uint crc = 0xffffffffu;
        foreach (byte b in tb) crc = CrcTable[(crc ^ b) & 0xff] ^ (crc >> 8);
        foreach (byte b in data) crc = CrcTable[(crc ^ b) & 0xff] ^ (crc >> 8);
        crc ^= 0xffffffffu;
        byte[] cb = new byte[4];
        BinaryPrimitives.WriteUInt32BigEndian(cb, crc);
        s.Write(cb);
    }
}
