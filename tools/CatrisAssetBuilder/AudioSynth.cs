using System.Text;

namespace CatrisAssetBuilder;

/// <summary>
/// Mastered 48 kHz / 16-bit PCM cozy audio synthesizer producing seamless, zero-click WAVs
/// for music, per-map ambience, ASMR foley, and warm formant cat voices/purr.
/// </summary>
public static class AudioSynth
{
    private const int SR = 48000;

    public static void BuildAllAudio(string audioDir)
    {
        Directory.CreateDirectory(audioDir);

        // 1. Seamless Chill Acoustic / Rhodes Music Loops (24s seamless progression)
        SaveWav(Path.Combine(audioDir, "bgm_day.wav"), GenerateCozyBgm(isNight: false));
        SaveWav(Path.Combine(audioDir, "bgm_night.wav"), GenerateCozyBgm(isNight: true));

        // 2. Per-Map Ambience Loops (8s seamless crossfaded beds)
        SaveWav(Path.Combine(audioDir, "amb_m01.wav"), GenerateAmbience("M01"));
        SaveWav(Path.Combine(audioDir, "amb_m02.wav"), GenerateAmbience("M02"));
        SaveWav(Path.Combine(audioDir, "amb_m03.wav"), GenerateAmbience("M03"));
        SaveWav(Path.Combine(audioDir, "amb_m04.wav"), GenerateAmbience("M04"));
        SaveWav(Path.Combine(audioDir, "amb_m05.wav"), GenerateAmbience("M05"));

        // 3. Tactile ASMR Foley & UI SFX
        SaveWav(Path.Combine(audioDir, "sfx_pickup.wav"), GeneratePop(330f, 590f, 0.075f, 0.48f));
        SaveWav(Path.Combine(audioDir, "sfx_rotate.wav"), GeneratePop(420f, 680f, 0.065f, 0.36f));
        SaveWav(Path.Combine(audioDir, "sfx_snap.wav"), GenerateSoftThud());
        SaveWav(Path.Combine(audioDir, "sfx_invalid.wav"), GenerateInvalidBoing());
        SaveWav(Path.Combine(audioDir, "sfx_ui_tap.wav"), GenerateWoodTap());
        SaveWav(Path.Combine(audioDir, "sfx_solve.wav"), GenerateSolveChime());

        // 4. Expressive Cat Voices & Cozy Purr Loop
        SaveWav(Path.Combine(audioDir, "cat_meow_high.wav"), GenerateCatMeow(660f, 540f, 0.24f));
        SaveWav(Path.Combine(audioDir, "cat_meow_mid.wav"), GenerateCatMeow(490f, 385f, 0.29f));
        SaveWav(Path.Combine(audioDir, "cat_meow_low.wav"), GenerateCatMeow(340f, 265f, 0.34f));
        SaveWav(Path.Combine(audioDir, "cat_chirp.wav"), GenerateCatChirp());
        SaveWav(Path.Combine(audioDir, "cat_grumble.wav"), GenerateCatGrumble());
        SaveWav(Path.Combine(audioDir, "cat_purr.wav"), GenerateCatPurrLoop(2.4f));
    }

    private static float[] GenerateCozyBgm(bool isNight)
    {
        // Warm acoustic Rhodes / celesta progression: Fmaj7 -> Em7 -> Dm7 -> Cmaj7 (75 BPM, 12.8s seamless!)
        double beat = 60.0 / 75.0; // 0.8s
        double totalSec = beat * 16.0; // 4 bars of 4 beats = 12.8s
        int n = (int)(totalSec * SR);
        var buf = new float[n];

        double[][] chords = isNight
            ? [
                [174.61, 220.00, 261.63, 329.63], // Fmaj7
                [164.81, 196.00, 246.94, 293.66], // Em7
                [146.83, 220.00, 261.63, 329.63], // Dm9
                [130.81, 196.00, 246.94, 329.63], // Cmaj7
              ]
            : [
                [261.63, 329.63, 392.00, 493.88], // Cmaj7
                [220.00, 261.63, 329.63, 392.00], // Am7
                [174.61, 220.00, 261.63, 329.63], // Fmaj7
                [196.00, 246.94, 293.66, 392.00], // G6
              ];

        double[] melody = isNight
            ? [523.25, 0, 493.88, 440.00, 392.00, 0, 329.63, 0, 440.00, 0, 392.00, 329.63, 293.66, 0, 329.63, 0]
            : [659.25, 0, 587.33, 523.25, 659.25, 0, 783.99, 0, 698.46, 0, 659.25, 523.25, 587.33, 0, 523.25, 0];

        void AddWarmNote(double startSec, double freq, double durSec, float amp)
        {
            int s0 = (int)(startSec * SR);
            int len = (int)(durSec * SR);
            for (int i = 0; i < len; i++)
            {
                double t = (double)i / SR;
                double env = Math.Min(1.0, t / 0.025) * Math.Exp(-t * 2.1);
                double sig = Math.Sin(2.0 * Math.PI * freq * t) * 0.72
                           + Math.Sin(4.0 * Math.PI * freq * t) * 0.22 * Math.Exp(-t * 3.5)
                           + Math.Sin(6.0 * Math.PI * freq * t) * 0.06 * Math.Exp(-t * 5.0);
                int idx = (s0 + i) % n; // Wrap tail cleanly for seamless loop!
                buf[idx] += (float)(sig * env * amp);
            }
        }

        for (int bar = 0; bar < 4; bar++)
        {
            var chord = chords[bar];
            for (int k = 0; k < chord.Length; k++)
                AddWarmNote(bar * 4 * beat + k * 0.045, chord[k], 3.4, 0.11f);
            // Gentle second soft strum on beat 3
            AddWarmNote(bar * 4 * beat + 2.0 * beat, chord[1], 1.8, 0.06f);
            AddWarmNote(bar * 4 * beat + 2.5 * beat, chord[2], 1.8, 0.055f);
        }
        for (int step = 0; step < melody.Length; step++)
        {
            if (melody[step] > 0)
                AddWarmNote(step * beat + 0.02, melody[step], 1.4, 0.085f);
        }

        NormalizePeak(buf, 0.42f);
        return buf;
    }

    private static float[] GenerateAmbience(string mapId)
    {
        int n = SR * 6;
        var buf = new float[n];
        var rng = new Random(mapId.GetHashCode());
        // Pink-ish warm filtered noise bed
        float b0 = 0, b1 = 0, b2 = 0, lp = 0;
        float cutoff = mapId == "M04" ? 0.14f : (mapId == "M02" ? 0.07f : 0.045f);
        float baseGain = mapId == "M04" ? 0.22f : 0.10f;

        for (int i = 0; i < n; i++)
        {
            float white = (float)(rng.NextDouble() * 2.0 - 1.0);
            b0 = 0.997f * b0 + white * 0.029f;
            b1 = 0.985f * b1 + white * 0.032f;
            b2 = 0.950f * b2 + white * 0.048f;
            float pink = b0 + b1 + b2;
            lp += (pink - lp) * cutoff;

            double t = (double)i / SR;
            // Gentle slow breathing wind modulation (integer cycles over 6s for seamless loop!)
            float gust = 0.72f + 0.28f * MathF.Sin((float)(2.0 * Math.PI * t / 6.0));
            buf[i] = lp * baseGain * gust;

            // Map-specific cozy subtle accents
            if (mapId == "M03" && i > SR * 2 && i < SR * 4)
            {
                // Delicate distant glass wind chime harmonic
                double ct = (i - SR * 2) / (double)SR;
                buf[i] += (float)(Math.Sin(2.0 * Math.PI * 1568.0 * ct) * Math.Exp(-ct * 2.4) * 0.045);
            }
            if (mapId == "M05")
            {
                // Ultra-soft warm night shimmer
                double env = Math.Max(0.0, Math.Sin(2.0 * Math.PI * t * 0.5));
                buf[i] += (float)(Math.Sin(2.0 * Math.PI * 220.0 * t) * env * 0.008);
            }
        }
        // Seamless loop crossfade (0.5s)
        int fade = SR / 2;
        for (int i = 0; i < fade; i++)
        {
            float a = (float)i / fade;
            buf[i] = buf[i] * a + buf[n - fade + i] * (1f - a);
        }
        NormalizePeak(buf, mapId == "M04" ? 0.28f : 0.16f);
        return buf;
    }

    private static float[] GeneratePop(float f0, float f1, float dur, float peak)
    {
        int n = (int)(dur * SR);
        var buf = new float[n];
        double phase = 0;
        for (int i = 0; i < n; i++)
        {
            float t = (float)i / n;
            float freq = f0 + (f1 - f0) * MathF.Pow(t, 0.65f);
            phase += 2.0 * Math.PI * freq / SR;
            float env = MathF.Sin(MathF.Min(1f, t / 0.12f) * MathF.PI * 0.5f) * MathF.Exp(-t * 4.8f);
            buf[i] = (float)(Math.Sin(phase) * 0.85 + Math.Sin(phase * 2.0) * 0.15) * env * peak;
        }
        return buf;
    }

    private static float[] GenerateSoftThud()
    {
        int n = (int)(0.12f * SR);
        var buf = new float[n];
        var rng = new Random(77);
        double phase = 0;
        float lp = 0;
        for (int i = 0; i < n; i++)
        {
            float t = (float)i / n;
            float freq = 148f * MathF.Exp(-t * 2.2f) + 52f;
            phase += 2.0 * Math.PI * freq / SR;
            float env = MathF.Sin(MathF.Min(1f, t / 0.08f) * MathF.PI * 0.5f) * MathF.Exp(-t * 5.2f);
            float noise = (float)(rng.NextDouble() * 2.0 - 1.0);
            lp += (noise - lp) * 0.09f;
            buf[i] = ((float)Math.Sin(phase) * 0.78f + lp * 0.35f) * env * 0.55f;
        }
        return buf;
    }

    private static float[] GenerateInvalidBoing()
    {
        int n = (int)(0.19f * SR);
        var buf = new float[n];
        double phase = 0;
        for (int i = 0; i < n; i++)
        {
            float t = (float)i / n;
            float freq = 230f - 80f * t + MathF.Sin(t * 28f) * 18f;
            phase += 2.0 * Math.PI * freq / SR;
            float env = MathF.Min(1f, t / 0.08f) * MathF.Exp(-t * 4.0f);
            buf[i] = (float)(Math.Sin(phase) * 0.72 + Math.Sin(phase * 2.0) * 0.22 + Math.Sin(phase * 3.0) * 0.06) * env * 0.42f;
        }
        return buf;
    }

    private static float[] GenerateWoodTap()
    {
        int n = (int)(0.045f * SR);
        var buf = new float[n];
        for (int i = 0; i < n; i++)
        {
            float t = (float)i / n;
            float env = MathF.Exp(-t * 8.0f);
            buf[i] = (MathF.Sin(2f * MathF.PI * 760f * i / SR) * 0.7f
                    + MathF.Sin(2f * MathF.PI * 1420f * i / SR) * 0.3f) * env * 0.32f;
        }
        return buf;
    }

    private static float[] GenerateSolveChime()
    {
        int n = (int)(1.35f * SR);
        var buf = new float[n];
        double[] notes = [523.25, 659.25, 783.99, 1046.50]; // C5-E5-G5-C6 warm harp arpeggio
        for (int k = 0; k < notes.Length; k++)
        {
            int s0 = (int)(k * 0.11 * SR);
            for (int i = s0; i < n; i++)
            {
                double t = (i - s0) / (double)SR;
                double env = Math.Min(1.0, t / 0.015) * Math.Exp(-t * 2.6);
                buf[i] += (float)((Math.Sin(2.0 * Math.PI * notes[k] * t) * 0.75
                                 + Math.Sin(4.0 * Math.PI * notes[k] * t) * 0.20) * env * 0.24);
            }
        }
        NormalizePeak(buf, 0.55f);
        return buf;
    }

    private static float[] GenerateCatMeow(float fStart, float fEnd, float dur)
    {
        int n = (int)(dur * SR);
        var buf = new float[n];
        double phase = 0;
        for (int i = 0; i < n; i++)
        {
            float t = (float)i / n;
            // Cute upward arch then soft downward sigh ("m-eow")
            float pitchArch = MathF.Sin(t * MathF.PI) * 0.22f;
            float vibrato = MathF.Sin(t * 24f) * 0.018f;
            float f0 = (fStart + (fEnd - fStart) * t) * (1f + pitchArch + vibrato);
            phase += 2.0 * Math.PI * f0 / SR;

            // Vowel formant glide "ee -> aa -> oo" via harmonic weighting!
            float h2 = 0.55f * MathF.Sin(t * MathF.PI);
            float h3 = 0.32f * MathF.Pow(MathF.Sin(t * MathF.PI), 1.5f);
            float h4 = 0.14f * MathF.Exp(-MathF.Pow((t - 0.35f) * 4f, 2f));
            double sig = Math.Sin(phase) * 0.72 + Math.Sin(2 * phase) * h2 + Math.Sin(3 * phase) * h3 + Math.Sin(4 * phase) * h4;
            float env = MathF.Pow(MathF.Sin(t * MathF.PI), 0.75f);
            buf[i] = (float)(sig * env);
        }
        NormalizePeak(buf, 0.48f);
        return buf;
    }

    private static float[] GenerateCatChirp()
    {
        int n = (int)(0.16f * SR);
        var buf = new float[n];
        double phase = 0;
        for (int i = 0; i < n; i++)
        {
            float t = (float)i / n;
            float trill = 1f + 0.14f * MathF.Sin(t * 65f);
            float f0 = (420f + 360f * t) * trill;
            phase += 2.0 * Math.PI * f0 / SR;
            float env = MathF.Sin(t * MathF.PI);
            buf[i] = (float)(Math.Sin(phase) * 0.75 + Math.Sin(2 * phase) * 0.25) * env * 0.42f;
        }
        return buf;
    }

    private static float[] GenerateCatGrumble()
    {
        int n = (int)(0.22f * SR);
        var buf = new float[n];
        double phase = 0;
        for (int i = 0; i < n; i++)
        {
            float t = (float)i / n;
            float f0 = 260f - 85f * t;
            phase += 2.0 * Math.PI * f0 / SR;
            float rasp = 0.72f + 0.28f * MathF.Sin(t * 95f);
            float env = MathF.Sin(t * MathF.PI);
            buf[i] = (float)(Math.Sin(phase) * 0.60 + Math.Sin(2 * phase) * 0.28 + Math.Sin(3 * phase) * 0.12) * rasp * env * 0.42f;
        }
        return buf;
    }

    private static float[] GenerateCatPurrLoop(float dur)
    {
        int n = (int)(dur * SR);
        var buf = new float[n];
        for (int i = 0; i < n; i++)
        {
            double t = (double)i / SR;
            // Inhale / exhale warm low rumble at ~26 Hz carrier!
            double breath = 0.55 + 0.45 * Math.Sin(2.0 * Math.PI * t / dur);
            double carrier = Math.Sin(2.0 * Math.PI * 26.0 * t);
            double pulse = Math.Max(0.0, carrier);
            double warmth = Math.Sin(2.0 * Math.PI * 78.0 * t) * 0.5 + Math.Sin(2.0 * Math.PI * 130.0 * t) * 0.3 + Math.Sin(2.0 * Math.PI * 52.0 * t) * 0.4;
            buf[i] = (float)(warmth * (0.35 + 0.65 * pulse) * breath * 0.26);
        }
        return buf;
    }

    private static void NormalizePeak(float[] buf, float targetPeak)
    {
        float max = 0f;
        for (int i = 0; i < buf.Length; i++) max = MathF.Max(max, MathF.Abs(buf[i]));
        if (max > 1e-5f)
        {
            float s = targetPeak / max;
            for (int i = 0; i < buf.Length; i++) buf[i] *= s;
        }
    }

    private static void SaveWav(string path, float[] samples)
    {
        using var fs = File.Create(path);
        using var bw = new BinaryWriter(fs);
        int dataBytes = samples.Length * 2;
        bw.Write(Encoding.ASCII.GetBytes("RIFF"));
        bw.Write(36 + dataBytes);
        bw.Write(Encoding.ASCII.GetBytes("WAVE"));
        bw.Write(Encoding.ASCII.GetBytes("fmt "));
        bw.Write(16);
        bw.Write((short)1); // PCM
        bw.Write((short)1); // Mono
        bw.Write(SR);
        bw.Write(SR * 2);
        bw.Write((short)2);
        bw.Write((short)16);
        bw.Write(Encoding.ASCII.GetBytes("data"));
        bw.Write(dataBytes);
        for (int i = 0; i < samples.Length; i++)
        {
            short v = (short)SdfMath.Clamp(samples[i] * 32767f, -32767f, 32767f);
            bw.Write(v);
        }
    }
}
