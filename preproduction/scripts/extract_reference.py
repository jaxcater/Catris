"""Extract reference evidence only; this script does not create game assets or code."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path


def run(command):
    result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode:
        raise RuntimeError(result.stderr)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ffmpeg", required=True)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    metadata = subprocess.run([args.ffmpeg, "-hide_banner", "-i", str(args.input)], capture_output=True, text=True).stderr
    duration_match = re.search(r"Duration: (\d+):(\d+):([\d.]+)", metadata)
    if not duration_match:
        raise RuntimeError("FFmpeg did not report a readable duration")
    hours, minutes, seconds = map(float, duration_match.groups())
    duration = hours * 3600 + minutes * 60 + seconds
    samples = [float(t) for t in range(0, int(duration), 2)]
    if duration - samples[-1] > 0.5:
        samples.append(round(duration - 0.2, 3))
    records = []
    groups = [("frames", samples, 4, 6)]
    groups += [("motion-pickup", [5 + n * 0.25 for n in range(16)], 4, 4),
               ("motion-invalid", [17 + n * 0.25 for n in range(16)], 4, 4),
               ("motion-settle", [28 + n * 0.25 for n in range(16)], 4, 4)]
    for group, times, columns, rows in groups:
        folder = args.output / group
        folder.mkdir(exist_ok=True)
        for index, time in enumerate(times, 1):
            target = folder / f"frame-{index:02d}.jpg"
            run([args.ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-ss", str(time),
                 "-i", str(args.input), "-frames:v", "1", "-q:v", "2", str(target)])
            records.append({"group": group, "frame": index, "requested_seconds": time,
                            "path": str(target.relative_to(args.output)).replace("\\", "/")})
        sheet = args.output / ("contact-sheet.jpg" if group == "frames" else group + ".jpg")
        run([args.ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-framerate", "1",
             "-i", str(folder / "frame-%02d.jpg"), "-vf",
             f"scale=480:270,tile={columns}x{rows}:padding=4:margin=4:color=0x171b1c",
             "-frames:v", "1", "-q:v", "2", str(sheet)])
    digest = hashlib.file_digest(args.input.open("rb"), "sha256").hexdigest()
    data = {"source_filename": args.input.name, "source_bytes": args.input.stat().st_size,
            "sha256": digest, "duration_seconds": duration,
            "sampling_note": "Seek targets in seconds; frame selection is limited by source frame rate. Overview row-major.",
            "ffmpeg_metadata": metadata, "frames": records}
    (args.output / "video-metadata.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"frames": len(records), "duration_seconds": duration, "sha256": digest}))


if __name__ == "__main__":
    main()
