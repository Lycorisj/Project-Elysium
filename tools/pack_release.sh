#!/usr/bin/env bash
# Zip only datapacks/elysium into dist/. The zip is build output and is not committed.
# Fails if the archive contains the test pack, a jar, a world, or a secret.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import hashlib
import sys
import zipfile
from pathlib import Path

root = Path(".").resolve()
source = root / "datapacks" / "elysium"
dist = root / "dist"
dist.mkdir(parents=True, exist_ok=True)
zip_path = dist / "elysium-datapack.zip"
if zip_path.exists():
    zip_path.unlink()

files = sorted(path for path in source.rglob("*") if path.is_file())
if not files:
    print("pack_release: ship datapack is empty", file=sys.stderr)
    sys.exit(1)

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for path in files:
        relative = path.relative_to(source).as_posix()
        info = zipfile.ZipInfo(relative)
        info.date_time = (2026, 11, 8, 0, 0, 0)
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o644 << 16
        archive.writestr(info, path.read_bytes())

forbidden = []
names = []
with zipfile.ZipFile(zip_path) as archive:
    for info in archive.infolist():
        name = info.filename
        names.append(name)
        lowered = name.lower()
        if "elysium_test" in lowered:
            forbidden.append(name)
        if lowered.endswith(".jar") or lowered.endswith(".mca") or lowered.endswith("/eula.txt") or lowered == "eula.txt":
            forbidden.append(name)
        if lowered.startswith("run/") or lowered.startswith("world/") or "/region/" in lowered:
            forbidden.append(name)
        data = archive.read(info)
        if b"eula=true" in data or b"BEGIN OPENSSH PRIVATE KEY" in data or b"BEGIN PRIVATE KEY" in data:
            forbidden.append(name + " (secret-like bytes)")
        if b"rcon.password=" in data and b"rcon.password=\n" not in data and b"rcon.password=\r\n" not in data:
            forbidden.append(name + " (rcon password)")

if forbidden:
    print("pack_release: forbidden entries:", file=sys.stderr)
    for item in forbidden:
        print(item, file=sys.stderr)
    sys.exit(1)

digest = hashlib.sha256(zip_path.read_bytes()).hexdigest()
print(f"zip: {zip_path}")
print(f"sha256: {digest}")
print("files:")
for name in names:
    print(name)
PY
