"""Validate the preparation pack, not the game. Standard library only."""
import ast
import hashlib
import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote

PREP = Path(__file__).resolve().parents[1]
ROOT = PREP.parent


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path):
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def main():
    errors = []
    checks = {}
    pack = read_json(PREP / "pack.json")
    manifest = read_json(PREP / "assets/asset-manifest.json")
    maps = {entry["id"] for entry in pack["maps"]}
    if len(maps) != len(pack["maps"]) or not (1 <= len(maps) <= pack["max_maps"] == 5):
        errors.append("Map IDs/count violate the five-map limit")
    if pack["mode"] != "PREPARATION_ONLY" or any(pack[key] for key in ["game_implementation_started", "github_mutations", "ipa_built"]):
        errors.append("Preparation state is inconsistent")
    checks["maps"] = len(maps)
    ids = set()
    for asset in manifest["assets"]:
        if asset["id"] in ids:
            errors.append("Duplicate asset: " + asset["id"])
        ids.add(asset["id"])
        if not set(asset["maps"]).issubset(maps):
            errors.append("Unknown map for " + asset["id"])
        if asset["status"] not in manifest["asset_status_meanings"]:
            errors.append("Unknown status for " + asset["id"])
        if asset["runtime_approved"] or asset["technical_checks_passed"]:
            errors.append("Unproven production approval: " + asset["id"])
        if asset.get("local_directory") and not (ROOT / asset["local_directory"]).is_dir():
            errors.append("Missing source directory for " + asset["id"])
    checks["asset_entries"] = len(ids)

    downloaded = read_json(PREP / "assets/downloaded-materials.json")["files"]
    for record in downloaded:
        path = ROOT / record["local_path"]
        if not path.is_file() or path.stat().st_size != record["bytes"] or digest(path) != record["sha256"]:
            errors.append("Downloaded material integrity failed: " + record["local_path"])
    if len(downloaded) != pack["downloaded_material_files"]:
        errors.append("Downloaded material count mismatch")
    checks["downloaded_materials_verified"] = len(downloaded)

    metadata = read_json(PREP / "references/video-metadata.json")
    if digest(PREP / "references/Game.mp4") != metadata["sha256"]:
        errors.append("Reference video checksum mismatch")
    for frame in metadata["frames"]:
        if not (PREP / "references" / frame["path"]).is_file():
            errors.append("Missing reference frame: " + frame["path"])
    if len(metadata["frames"]) != pack["reference_frames"]:
        errors.append("Reference frame count mismatch")
    checks["reference_frames"] = len(metadata["frames"])

    vendor = read_json(PREP / "research/vendor-lock.json")["files"]
    for record in vendor:
        path = ROOT / record["local_path"]
        if not path.is_file():
            errors.append("Missing vendor file: " + record["local_path"])
            continue
        blob = path.read_bytes()
        actual = hashlib.sha1(b"blob " + str(len(blob)).encode() + b"\0" + blob).hexdigest()
        if actual != record["git_blob_sha"]:
            errors.append("Vendor differs from pinned upstream blob: " + record["local_path"])
    checks["pinned_vendor_blobs_verified"] = len(vendor)
    custom = sorted((PREP / "skills").glob("*/SKILL.md"))
    vendor_skills = sorted((PREP / "vendor").glob("*/skills/*/SKILL.md"))
    if len(custom) != pack["custom_skills"] or len(vendor_skills) != pack["vendor_skills"]:
        errors.append("Skill counts differ from pack manifest")
    checks["custom_skills"] = len(custom)
    checks["vendor_skills"] = len(vendor_skills)
    skill_report = read_json(PREP / "research/skill-validation.json")
    if {row["skill"] for row in skill_report["results"]} != {path.parent.name for path in custom} or not all(row["passed"] for row in skill_report["results"]):
        errors.append("Custom skill validator evidence is incomplete")
    for path in PREP.rglob("*.py"):
        try:
            ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        except (SyntaxError, UnicodeError) as exc:
            errors.append("Python syntax/encoding: " + str(exc))
    checks["python_helpers_parsed_without_execution"] = len(list(PREP.rglob("*.py")))

    # Create checksums before link checks; generated reports are intentionally excluded.
    excluded = {"research/checksums.json", "research/validation-report.json"}
    members = [ROOT / "CATRIS_MASTER_PROMPT.md"] + sorted(path for path in PREP.rglob("*")
        if path.is_file() and path.relative_to(PREP).as_posix() not in excluded and "__pycache__" not in path.parts)
    checksum_data = {"algorithm": "sha256", "excludes": sorted(excluded), "files": {
        path.relative_to(ROOT).as_posix(): digest(path) for path in members}}
    (PREP / "research/checksums.json").write_text(json.dumps(checksum_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    docs = [ROOT / "CATRIS_MASTER_PROMPT.md"] + sorted(path for path in PREP.rglob("*.md") if "vendor" not in path.relative_to(PREP).parts)
    links_checked = 0
    for doc in docs:
        content = doc.read_text(encoding="utf-8")
        if "\ufffd" in content:
            errors.append("Replacement character in " + str(doc))
        content = re.sub(r"```.*?```", "", content, flags=re.S)
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", content):
            target = target.strip().strip("<>")
            if re.match(r"[a-zA-Z][a-zA-Z0-9+.-]*:", target) or target.startswith("#"):
                continue
            relative = unquote(target.split("#", 1)[0])
            if not relative:
                continue
            links_checked += 1
            if not (doc.parent / relative).exists():
                errors.append("Broken link: " + str(doc.relative_to(ROOT)) + " -> " + target)
    checks["authored_markdown_documents"] = len(docs)
    checks["local_document_links_checked"] = links_checked
    checks["checksummed_files"] = len(members)
    report = {"date": "2026-11-22", "scope": "preparation files only; no engine/game/device execution",
              "passed": not errors, "checks": checks, "errors": errors}
    (PREP / "research/validation-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
