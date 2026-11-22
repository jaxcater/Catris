using System.Diagnostics;
using System.Text.Json;

namespace CatrisAssetBuilder;

public static class Program
{
    public static void Main(string[] args)
    {
        var sw = Stopwatch.StartNew();
        string repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        if (args.Length > 0) repoRoot = Path.GetFullPath(args[0]);

        string assetsRoot = Path.Combine(repoRoot, "Sources", "CatrisApp", "Assets");
        string cmeshDir   = Path.Combine(assetsRoot, "Meshes");
        string texDir     = Path.Combine(assetsRoot, "Textures");
        string audioDir   = Path.Combine(assetsRoot, "Audio");
        string dataDir    = Path.Combine(assetsRoot, "Data");
        string objDir     = Path.Combine(repoRoot, "tools", "preview", "obj");

        Console.WriteLine($"[CatrisAssetBuilder] Repo root: {repoRoot}");

        Console.WriteLine("[1/4] Sculpting 12 organic 3D cats (.cmesh + .obj + 512px coats + face anchors)...");
        var (anchors, catQa) = CatSculptor.BuildAllCats(cmeshDir, objDir, texDir, dataDir);

        Console.WriteLine("[2/4] Sculpting 3D diorama props & painting 5-map PBR textures + gobos + AppIcon...");
        DioramaPropSculptor.BuildAllPropsAndTextures(cmeshDir, objDir, texDir);

        Console.WriteLine("[3/4] Synthesizing 48 kHz mastered cozy WAV audio suite...");
        AudioSynth.BuildAllAudio(audioDir);

        // Copy CC0 Poly Haven HDRI for authentic SceneKit PBR IBL lighting!
        string srcHdri = Path.Combine(repoRoot, "preproduction", "assets", "source-materials", "autumn_field_puresky", "autumn_field_puresky_1k.hdr");
        if (File.Exists(srcHdri))
        {
            File.Copy(srcHdri, Path.Combine(texDir, "sky_ibl.hdr"), overwrite: true);
            Console.WriteLine("[4/4] Copied CC0 Poly Haven HDRI -> sky_ibl.hdr");
        }

        // Write AppIcon into Asset Catalog too!
        string appIconDir = Path.Combine(assetsRoot, "Assets.xcassets", "AppIcon.appiconset");
        Directory.CreateDirectory(appIconDir);
        File.Copy(Path.Combine(texDir, "AppIcon.png"), Path.Combine(appIconDir, "AppIcon-1024.png"), overwrite: true);
        File.WriteAllText(Path.Combine(assetsRoot, "Assets.xcassets", "Contents.json"),
            """{"info":{"author":"xcode","version":1}}""");
        File.WriteAllText(Path.Combine(appIconDir, "Contents.json"), """
        {
          "images": [
            {
              "filename": "AppIcon-1024.png",
              "idiom": "universal",
              "platform": "ios",
              "size": "1024x1024"
            }
          ],
          "info": {
            "author": "xcode",
            "version": 1
          }
        }
        """);

        // Emit Asset QA Report
        var report = new
        {
            generated_utc = DateTime.UtcNow.ToString("O"),
            elapsed_ms = sw.ElapsedMilliseconds,
            cats = catQa.ToDictionary(kv => kv.Key, kv => new { vertices = kv.Value.verts, triangles = kv.Value.tris }),
            anchor_count = anchors.Count,
            cmesh_files = Directory.GetFiles(cmeshDir, "*.cmesh").Length,
            texture_files = Directory.GetFiles(texDir, "*.png").Length,
            audio_files = Directory.GetFiles(audioDir, "*.wav").Length,
        };
        File.WriteAllText(
            Path.Combine(dataDir, "asset-qa-report.json"),
            JsonSerializer.Serialize(report, new JsonSerializerOptions { WriteIndented = true })
        );

        Console.WriteLine($"[DONE] Built all Catris 3D assets in {sw.ElapsedMilliseconds} ms!");
        foreach (var kv in catQa)
            Console.WriteLine($"   - cat_{kv.Key,-8}: {kv.Value.verts,5} verts, {kv.Value.tris,5} tris");

        Console.WriteLine("[QA] Rendering 3D orthographic visual QA previews...");
        SoftwareRenderer3D.RenderQAPreviews(cmeshDir, texDir, dataDir, Path.Combine(repoRoot, "tools", "preview"));
        Console.WriteLine("[QA] Saved render_m01_portrait.png and render_all_12_cats.png!");
    }
}
