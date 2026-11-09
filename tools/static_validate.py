#!/usr/bin/env python3
"""Layer 1 static checks. Python 3 standard library only.

A zero exit means the files match these checks. It does not mean a dedicated
server loaded the datapack, a bot ran, or a person played.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
NS_RE = re.compile(r"^[a-z0-9_.-]+$")
SPEC_RE = re.compile(r"^F-\d+$")
LEGACY_DIRS = {"functions", "advancements"}
LEGACY_PHRASE = "pinned server required the legacy plural directories"
PACK_FORMAT_PHRASE = "pinned server required the legacy pack_format field"

FILL_RE = re.compile(
    r"^fill\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\b"
)
SETBLOCK_RE = re.compile(r"^setblock\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\b")
SUMMON_RE = re.compile(r"^summon\s+\S+\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\b")
FORCELOAD_RE = re.compile(
    r"^forceload\s+add\s+(-?\d+)\s+(-?\d+)(?:\s+(-?\d+)\s+(-?\d+))?\b"
)


class Report:
    def __init__(self) -> None:
        self.failures: list[str] = []

    def fail(self, message: str) -> None:
        self.failures.append(message)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def architecture_text() -> str:
    path = ROOT / "ARCHITECTURE.md"
    if not path.is_file():
        return ""
    return read_text(path)


def tracked_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", "-co", "--exclude-standard"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return [line for line in result.stdout.splitlines() if line]


def parse_markdown_tables(text: str) -> dict[str, list[dict[str, str]]]:
    sections: dict[str, list[dict[str, str]]] = {}
    current = None
    headers: list[str] | None = None
    for line in text.splitlines():
        if line.startswith("## "):
            current = line[3:].strip().lower()
            headers = None
            sections.setdefault(current, [])
            continue
        if current is None or not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if headers is None:
            headers = [cell.lower() for cell in cells]
            continue
        if all(set(cell) <= set("-: ") for cell in cells):
            continue
        if len(cells) != len(headers):
            continue
        sections[current].append(dict(zip(headers, cells)))
    return sections


def section_rows(sections: dict[str, list[dict[str, str]]], prefix: str) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for title, table in sections.items():
        if title.startswith(prefix):
            rows.extend(table)
    return rows


def function_path(function_id: str) -> Path | None:
    if ":" not in function_id:
        return None
    namespace, relative = function_id.split(":", 1)
    relative_path = Path(*relative.split("/"))
    for pack in (ROOT / "datapacks").iterdir() if (ROOT / "datapacks").is_dir() else []:
        candidate = pack / "data" / namespace / "function" / relative_path
        candidate = candidate.with_suffix(".mcfunction")
        if candidate.is_file():
            return candidate
    return None


def advancement_path(advancement_id: str) -> Path | None:
    if ":" not in advancement_id:
        return None
    namespace, relative = advancement_id.split(":", 1)
    relative_path = Path(*relative.split("/"))
    for pack in (ROOT / "datapacks").iterdir() if (ROOT / "datapacks").is_dir() else []:
        candidate = pack / "data" / namespace / "advancement" / relative_path
        candidate = candidate.with_suffix(".json")
        if candidate.is_file():
            return candidate
    return None


def iter_json_files() -> list[Path]:
    found: list[Path] = []
    for folder in ("datapacks", "tools/cases", "resourcepacks"):
        base = ROOT / folder
        if base.is_dir():
            found.extend(sorted(base.rglob("*.json")))
    return found


def check_json(report: Report) -> None:
    files = iter_json_files()
    if not files:
        report.fail("no JSON files found under datapacks/ or tools/cases/")
    for path in files:
        try:
            json.loads(read_text(path))
        except json.JSONDecodeError as exc:
            report.fail(f"{path.relative_to(ROOT)}: invalid JSON: {exc}")


def check_pack_mcmeta(report: Report) -> None:
    datapacks = ROOT / "datapacks"
    if not datapacks.is_dir():
        report.fail("datapacks/ is missing")
        return
    packs = [path for path in datapacks.iterdir() if path.is_dir()]
    if not packs:
        report.fail("datapacks/ has no packs")
    for pack in packs:
        meta = pack / "pack.mcmeta"
        if not meta.is_file():
            report.fail(f"{pack.relative_to(ROOT)}: missing pack.mcmeta")
            continue
        try:
            payload = json.loads(read_text(meta))
        except json.JSONDecodeError:
            continue
        body = payload.get("pack", {})
        if "min_format" not in body or "max_format" not in body:
            report.fail(f"{meta.relative_to(ROOT)}: min_format and max_format are required")
        if "pack_format" in body and PACK_FORMAT_PHRASE not in architecture_text():
            report.fail(f"{meta.relative_to(ROOT)}: legacy pack_format is set")
        if body.get("min_format") != 121 or body.get("max_format") != 121:
            report.fail(f"{meta.relative_to(ROOT)}: data pack format must be integer 121")


def check_resource_pack(report: Report) -> None:
    meta_path = ROOT / "resourcepacks" / "elysium" / "pack.mcmeta"
    zh_path = ROOT / "resourcepacks" / "elysium" / "assets" / "elysium" / "lang" / "zh_cn.json"
    en_path = ROOT / "resourcepacks" / "elysium" / "assets" / "elysium" / "lang" / "en_us.json"
    advancement = (
        ROOT
        / "datapacks"
        / "elysium"
        / "data"
        / "elysium"
        / "advancement"
        / "slice"
        / "ledger_cleared.json"
    )
    for path in (meta_path, zh_path, en_path, advancement):
        if not path.is_file():
            report.fail(f"missing in-game string file {path.relative_to(ROOT)}")
            return
    meta = json.loads(read_text(meta_path))
    body = meta.get("pack", {})
    if body.get("min_format") != [97, 1] or body.get("max_format") != [97, 1]:
        report.fail("resource pack format must be [97, 1] for the 97.1 pin")
    if "pack_format" in body:
        report.fail("resource pack sets legacy pack_format")
    zh = json.loads(read_text(zh_path))
    en = json.loads(read_text(en_path))
    keys = (
        "elysium.slice.ledger_cleared.title",
        "elysium.slice.ledger_cleared.description",
    )
    for key in keys:
        if key not in zh or key not in en:
            report.fail(f"language files must both define {key}")
            return
        if not isinstance(zh[key], str) or not zh[key].strip():
            report.fail(f"zh_cn value for {key} is empty")
        if not isinstance(en[key], str) or not en[key].strip():
            report.fail(f"en_us value for {key} is empty")
    display = json.loads(read_text(advancement)).get("display", {})
    title = display.get("title", {})
    description = display.get("description", {})
    if title.get("fallback") != zh[keys[0]] or description.get("fallback") != zh[keys[1]]:
        report.fail("advancement fallback text must match zh_cn, the primary language")
    if title.get("translate") != keys[0] or description.get("translate") != keys[1]:
        report.fail("advancement translate keys must match the language files")
    allowed = {zh[keys[0]], zh[keys[1]], en[keys[0]], en[keys[1]]}
    if allowed != {"账本", "标记", "Ledger", "Marker"}:
        report.fail("advancement strings must name only the ledger and the marker")


def check_legacy_dirs(report: Report) -> None:
    if LEGACY_PHRASE in architecture_text():
        return
    for path in tracked_files():
        parts = set(Path(path).parts)
        found = sorted(parts & LEGACY_DIRS)
        if found:
            report.fail(f"{path}: legacy plural directory {found[0]}")


def check_namespaces(report: Report) -> None:
    data_roots = list((ROOT / "datapacks").glob("*/data")) if (ROOT / "datapacks").is_dir() else []
    for data_root in data_roots:
        if not data_root.is_dir():
            continue
        for namespace in data_root.iterdir():
            if namespace.is_dir() and not NS_RE.fullmatch(namespace.name):
                report.fail(f"namespace outside [a-z0-9_.-]: {namespace.relative_to(ROOT)}")


def tag_function_ids(payload: object) -> list[str]:
    if not isinstance(payload, dict):
        return []
    values = payload.get("values", [])
    found = []
    if not isinstance(values, list):
        return found
    for entry in values:
        if isinstance(entry, str):
            found.append(entry)
        elif isinstance(entry, dict) and isinstance(entry.get("id"), str):
            found.append(entry["id"])
    return found


def check_tags(report: Report) -> None:
    for path in sorted((ROOT / "datapacks").glob("*/data/*/tags/function/*.json")):
        try:
            payload = json.loads(read_text(path))
        except json.JSONDecodeError:
            continue
        for function_id in tag_function_ids(payload):
            if function_path(function_id) is None:
                report.fail(f"{path.relative_to(ROOT)}: {function_id} has no .mcfunction")


def mcfunction_text() -> str:
    chunks = []
    for path in sorted((ROOT / "datapacks").rglob("*.mcfunction")):
        chunks.append(read_text(path))
    return "\n".join(chunks)


def contains_token(haystack: str, token: str) -> bool:
    """Match a storage path or tag without letting tmp.n pass because tmp.now exists."""
    pattern = rf"(?<![A-Za-z0-9_.]){re.escape(token)}(?![A-Za-z0-9_])"
    return re.search(pattern, haystack) is not None


def check_registry(report: Report) -> dict[str, tuple[int, int, int, int, int, int]]:
    registry_path = ROOT / "specs" / "REGISTRY.md"
    regions: dict[str, tuple[int, int, int, int, int, int]] = {}
    if not registry_path.is_file():
        report.fail("specs/REGISTRY.md is missing")
        return regions
    sections = parse_markdown_tables(read_text(registry_path))
    bodies = mcfunction_text()
    known_functions: set[str] = set()

    for row in section_rows(sections, "function"):
        function_id = row.get("id", "")
        state = row.get("state", "")
        spec = row.get("spec", "")
        if not function_id:
            continue
        known_functions.add(function_id)
        namespace = function_id.split(":", 1)[0]
        if not NS_RE.fullmatch(namespace):
            report.fail(f"registry function namespace is illegal: {function_id}")
        if state == "reserved-not-implemented":
            if not SPEC_RE.fullmatch(spec):
                report.fail(f"{function_id} is reserved without a spec id")
            continue
        if state != "implemented":
            report.fail(f"{function_id} has unknown registry state {state}")
            continue
        if function_path(function_id) is None:
            report.fail(f"registry function has no file: {function_id}")

    for path in sorted((ROOT / "datapacks").rglob("*.mcfunction")):
        relative = path.relative_to(ROOT).parts
        # datapacks/<pack>/data/<namespace>/function/<...>.mcfunction
        try:
            data_index = relative.index("data")
        except ValueError:
            report.fail(f"{path.relative_to(ROOT)} is not under a data directory")
            continue
        namespace = relative[data_index + 1]
        function_parts = relative[data_index + 3 :]
        function_name = "/".join(function_parts).removesuffix(".mcfunction")
        function_id = f"{namespace}:{function_name}"
        if function_id not in known_functions:
            report.fail(f"{function_id} is not listed in specs/REGISTRY.md")

    for row in section_rows(sections, "advancement"):
        advancement_id = row.get("id", "")
        state = row.get("state", "")
        spec = row.get("spec", "")
        if not advancement_id:
            continue
        if state == "reserved-not-implemented":
            if not SPEC_RE.fullmatch(spec):
                report.fail(f"{advancement_id} is reserved without a spec id")
            continue
        if advancement_path(advancement_id) is None:
            report.fail(f"registry advancement has no file: {advancement_id}")

    for row in section_rows(sections, "storage"):
        storage = row.get("storage", "")
        path = row.get("path", "")
        state = row.get("state", "")
        spec = row.get("spec", "")
        if state == "reserved-not-implemented":
            if not SPEC_RE.fullmatch(spec):
                report.fail(f"storage {storage} {path} is reserved without a spec id")
            continue
        if storage and not contains_token(bodies, storage):
            report.fail(f"storage root {storage} is not referenced by a function")
        if path and not contains_token(bodies, path):
            report.fail(f"storage path {storage} {path} is not referenced by a function")

    for row in section_rows(sections, "entity tag"):
        tag = row.get("tag", "")
        state = row.get("state", "")
        spec = row.get("spec", "")
        if not tag:
            continue
        if state == "reserved-not-implemented":
            if not SPEC_RE.fullmatch(spec):
                report.fail(f"entity tag {tag} is reserved without a spec id")
            continue
        if not contains_token(bodies, tag):
            report.fail(f"entity tag {tag} is not referenced by a function")

    for row in section_rows(sections, "region"):
        try:
            bounds = (
                int(row["x0"]),
                int(row["y0"]),
                int(row["z0"]),
                int(row["x1"]),
                int(row["y1"]),
                int(row["z1"]),
            )
        except (KeyError, ValueError):
            report.fail(f"region row is not an inclusive integer box: {row}")
            continue
        if bounds[0] > bounds[3] or bounds[1] > bounds[4] or bounds[2] > bounds[5]:
            report.fail(f"region {row.get('id', '')} has inverted bounds")
        regions[row.get("id", "")] = bounds
    return regions


def inside(value: int, low: int, high: int) -> bool:
    return low <= value <= high


def check_place_room(report: Report, regions: dict[str, tuple[int, int, int, int, int, int]]) -> None:
    bounds = regions.get("slice-origin")
    if bounds is None:
        report.fail("registry has no slice-origin region")
        return
    x0, y0, z0, x1, y1, z1 = bounds
    path = ROOT / "datapacks" / "elysium" / "data" / "elysium" / "function" / "ledger" / "place_room.mcfunction"
    if not path.is_file():
        report.fail("place_room.mcfunction is missing")
        return
    for line_number, raw in enumerate(read_text(path).splitlines(), start=1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        fill = FILL_RE.match(line)
        if fill:
            xs = [int(fill.group(1)), int(fill.group(4))]
            ys = [int(fill.group(2)), int(fill.group(5))]
            zs = [int(fill.group(3)), int(fill.group(6))]
            if not all(inside(value, x0, x1) for value in xs) or not all(inside(value, y0, y1) for value in ys) or not all(inside(value, z0, z1) for value in zs):
                report.fail(f"place_room:{line_number} fill leaves slice-origin")
            continue
        block = SETBLOCK_RE.match(line)
        if block:
            x, y, z = (int(block.group(i)) for i in (1, 2, 3))
            if not (inside(x, x0, x1) and inside(y, y0, y1) and inside(z, z0, z1)):
                report.fail(f"place_room:{line_number} setblock leaves slice-origin")
            continue
        summon = SUMMON_RE.match(line)
        if summon:
            x, y, z = (int(summon.group(i)) for i in (1, 2, 3))
            if not (inside(x, x0, x1) and inside(y, y0, y1) and inside(z, z0, z1)):
                report.fail(f"place_room:{line_number} summon leaves slice-origin")
            continue
        loaded = FORCELOAD_RE.match(line)
        if loaded:
            coords = [int(group) for group in loaded.groups() if group is not None]
            xs = coords[0::2]
            zs = coords[1::2]
            if not all(inside(value, x0, x1) for value in xs) or not all(inside(value, z0, z1) for value in zs):
                report.fail(f"place_room:{line_number} forceload leaves slice-origin")


def check_tracked_artifacts(report: Report) -> None:
    for path in tracked_files():
        name = Path(path).name
        if name.endswith(".jar") or name.endswith(".mca") or name == "eula.txt":
            report.fail(f"tracked forbidden file: {path}")


def check_ship_isolation(report: Report) -> None:
    ship = ROOT / "datapacks" / "elysium"
    if not ship.is_dir():
        report.fail("datapacks/elysium is missing")
        return
    for path in ship.rglob("*"):
        if not path.is_file():
            continue
        if "elysium_test" in read_text(path):
            report.fail(f"{path.relative_to(ROOT)} references elysium_test")


def check_pin(report: Report) -> None:
    path = ROOT / "server" / "PINNED.json"
    if not path.is_file():
        report.fail("server/PINNED.json is missing")
        return
    try:
        pin = json.loads(read_text(path))
    except json.JSONDecodeError:
        return
    if pin.get("channel") != "release":
        report.fail("PINNED.json channel must be release")
    version = str(pin.get("version_id", ""))
    if not version or "snapshot" in version:
        report.fail("PINNED.json version_id must be a release, not a snapshot")
    sha1 = str(pin.get("server_sha1", ""))
    if not re.fullmatch(r"[0-9a-f]{40}", sha1):
        report.fail("PINNED.json server_sha1 is not a SHA-1")
    if not isinstance(pin.get("server_size"), int) or pin["server_size"] <= 0:
        report.fail("PINNED.json server_size must be a positive integer")
    if pin.get("java_major") != 25:
        report.fail("PINNED.json java_major must be 25 for the observed 26.3 manifest")
    if pin.get("data_pack_version") != "121.0" or pin.get("resource_pack_version") != "97.1":
        report.fail("PINNED.json pack versions must match the 26.3 article values read for this pin")
    if not isinstance(pin.get("jar_downloaded"), bool):
        report.fail("PINNED.json jar_downloaded must be a boolean")
    for key in ("version_json_url", "server_download_url", "version_manifest_url"):
        value = str(pin.get(key, ""))
        if not value.startswith("https://"):
            report.fail(f"PINNED.json {key} must be an https URL")


def check_case_file(report: Report) -> None:
    path = ROOT / "tools" / "cases" / "F-0001.json"
    if not path.is_file():
        report.fail("tools/cases/F-0001.json is missing")
        return
    try:
        payload = json.loads(read_text(path))
    except json.JSONDecodeError:
        return
    cases = payload.get("cases", [])
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    expected = [
        "place_room",
        "empty",
        "wrong_item",
        "success",
        "idempotent",
        "locked",
        "witness_missing",
        "clock_stable",
    ]
    if ids != expected:
        report.fail(f"F-0001 cases must be {expected}")
    if payload.get("verified_on_server") is not True or payload.get("reply_patterns_locked") is not True:
        report.fail("F-0001 reply patterns must be locked from the 26.3 boot")
    patterns = payload.get("reply_patterns", {})
    if patterns.get("storage_prefix") != "Storage elysium:slice has the following contents: ":
        report.fail("locked storage reply prefix does not match the 26.3 boot")
    if patterns.get("test_passed") != "Test passed":
        report.fail("locked block-query reply does not match the 26.3 boot")
    if patterns.get("forceload_count") != "4 force loaded chunks":
        report.fail("locked forceload count does not match the 26.3 boot")
    chunks = patterns.get("forceload_chunks")
    if chunks != ["[-1, -1]", "[-1, 0]", "[0, -1]", "[0, 0]"]:
        report.fail("locked forceload chunks do not match the 26.3 boot")
    for case in cases:
        if not isinstance(case, dict):
            continue
        for command in case.get("setup", []):
            if isinstance(command, str) and re.search(r"(^|\s)item\s+replace\b", command):
                report.fail(f"case {case.get('id')} copies a 1.21 /item replace command")


def check_documents(report: Report) -> None:
    required = [
        "README.md",
        "AGENTS.md",
        "PROJECT_CHARTER.md",
        "VISION.md",
        "ARCHITECTURE.md",
        "ROADMAP.md",
        "DECISIONS.md",
        "QUALITY_STANDARDS.md",
        "TESTING_STRATEGY.md",
        "CONTRIBUTING.md",
        "map/README.md",
        "decisions/D-0001-minecraft-eula.md",
        "decisions/D-0002-vanilla-dedicated-server.md",
        "decisions/D-0003-noncanon-first-slice.md",
        "decisions/D-0004-evidence-classes.md",
        "decisions/D-0005-folded-tide.md",
        "specs/README.md",
        "specs/REGISTRY.md",
        "specs/features/F-0001-ledger-cairn.md",
    ]
    for relative in required:
        if not (ROOT / relative).is_file():
            report.fail(f"missing required file {relative}")
    vision = ROOT / "VISION.md"
    if vision.is_file():
        text = read_text(vision)
        if "accepted: true" not in text or "《折潮》" not in text:
            report.fail("VISION.md must record accepted direction 《折潮》")
        if "The setting is not yet built." not in text:
            report.fail("VISION.md must say the setting is not yet built")
        if "「选 A《折潮》」" not in text:
            report.fail("VISION.md must quote the owner words exactly")
    decisions = {
        "decisions/D-0001-minecraft-eula.md": "accepted",
        "decisions/D-0002-vanilla-dedicated-server.md": "accepted",
        "decisions/D-0003-noncanon-first-slice.md": "accepted",
        "decisions/D-0004-evidence-classes.md": "accepted",
        "decisions/D-0005-folded-tide.md": "accepted",
    }
    for relative, status in decisions.items():
        path = ROOT / relative
        if not path.is_file():
            continue
        match = re.search(r"(?m)^- status:\s*(\S+)\s*$", read_text(path))
        if match is None or match.group(1) != status:
            report.fail(f"{relative} status must be {status}")
    d0001 = read_text(ROOT / "decisions" / "D-0001-minecraft-eula.md")
    if "「接受 EULA，可以跑专用服测试」" not in d0001:
        report.fail("D-0001 must quote the owner words exactly")
    d0005 = read_text(ROOT / "decisions" / "D-0005-folded-tide.md")
    if "「选 A《折潮》」" not in d0005:
        report.fail("D-0005 must quote the owner words exactly")


def main() -> int:
    report = Report()
    check_documents(report)
    check_json(report)
    check_pack_mcmeta(report)
    check_resource_pack(report)
    check_legacy_dirs(report)
    check_namespaces(report)
    check_tags(report)
    regions = check_registry(report)
    check_place_room(report, regions)
    check_tracked_artifacts(report)
    check_ship_isolation(report)
    check_pin(report)
    check_case_file(report)
    if report.failures:
        print("static_validate: fail")
        for message in report.failures:
            print(f"- {message}")
        return 1
    print("static_validate: pass")
    print("automated: pass")
    print("automated_scope: static_files_only")
    print("simulation: not_run")
    print("human_playtest: none")
    return 0


if __name__ == "__main__":
    sys.exit(main())
