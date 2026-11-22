"""Fetch a small, explicit CC0 source-material set. Does not import or build a game."""
import hashlib
import json
import urllib.request
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
HEADERS = {"User-Agent": "Catris-Preproduction/1.0 (local asset preparation)"}


def download(url):
    if urlparse(url).hostname not in {"api.polyhaven.com", "dl.polyhaven.org"}:
        raise ValueError("Unexpected download host")
    request = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=45) as response:
        body = response.read(25_000_001)
    if len(body) > 25_000_000:
        raise ValueError("Source file exceeds preparation size limit")
    return body


def main():
    records = []
    for asset_id in ["wood_floor", "fabric_pattern_07", "autumn_field_puresky"]:
        files = json.loads(download("https://api.polyhaven.com/files/" + asset_id))
        info = json.loads(download("https://api.polyhaven.com/info/" + asset_id))
        folder = ROOT / "assets" / "source-materials" / asset_id
        folder.mkdir(parents=True, exist_ok=True)
        (folder / "source-info.json").write_text(json.dumps(info, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        (folder / "source-files.json").write_text(json.dumps(files, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        if asset_id.endswith("puresky"):
            chosen = [("hdri", files["hdri"]["1k"]["hdr"])]
        else:
            color = next((key for key in ["Diffuse", "col_1", "col_03", "col_2"] if key in files), None)
            if color is None:
                raise ValueError("No recognized color channel for " + asset_id)
            chosen = [(channel, files[channel]["1k"]["jpg"]) for channel in [color, "nor_gl", "Rough"]]
        for channel, file in chosen:
            target = folder / Path(urlparse(file["url"]).path).name
            body = download(file["url"])
            if len(body) != file["size"] or hashlib.md5(body).hexdigest() != file["md5"]:
                raise ValueError("Source integrity mismatch: " + target.name)
            target.write_bytes(body)
            records.append({"asset_id": asset_id, "channel": channel, "source_url": file["url"],
                "source_page": "https://polyhaven.com/a/" + asset_id,
                "license": "CC0-1.0", "license_url": "https://polyhaven.com/license",
                "authors": info.get("authors", {}), "downloaded_on": "2026-11-22",
                "local_path": str(target.relative_to(ROOT.parent)).replace("\\", "/"),
                "bytes": len(body), "sha256": hashlib.sha256(body).hexdigest(),
                "status": "downloaded-source-not-game-ready", "visual_approval": False})
    output = ROOT / "assets" / "downloaded-materials.json"
    output.write_text(json.dumps({"files": records}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"files": len(records), "bytes": sum(row["bytes"] for row in records)}))


if __name__ == "__main__":
    main()
