#!/usr/bin/env bash
# F-0001 layer 2 and layer 3 runner.
# The first action is the D-0001 gate. While that decision is proposed this
# script does not download a jar, write eula=true, or launch Java.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

cleanup() {
  if [[ -f run/server.pid ]]; then
    local pgid
    pgid="$(cat run/server.pid)"
    if [[ -n "${pgid}" ]]; then
      kill -TERM -- "-${pgid}" 2>/dev/null || true
      sleep 1
      kill -KILL -- "-${pgid}" 2>/dev/null || true
    fi
  fi
}
trap cleanup EXIT INT TERM

eula_status="$(python3 -c '
import re
from pathlib import Path
text = Path("decisions/D-0001-minecraft-eula.md").read_text(encoding="utf-8")
match = re.search(r"(?m)^- status:\s*(\S+)\s*$", text)
print(match.group(1) if match else "missing")
')"

if [[ "${eula_status}" != "accepted" ]]; then
  echo "D-0001 status is ${eula_status}."
  echo "Refusing to download the server jar, write eula=true, or launch a server."
  echo "simulation: not_run"
  echo "human_playtest: none"
  exit 2
fi

python3 - "$ROOT" <<'PY'
import hashlib
import json
import os
import re
import shutil
import signal
import socket
import subprocess
import sys
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(ROOT / "tools"))
from rcon import RconClient, RconError  # noqa: E402

GAME_PORT = 25565
RCON_PORT = 25575
BOOT_TIMEOUT = 180
REJECT_TOKENS = (
    "unknown or incomplete",
    "incorrect argument",
    "expected whitespace",
    "unknown command",
)


def now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha1_file(path: Path) -> str:
    digest = hashlib.sha1()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def git_sha() -> str:
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()


def git_dirty() -> bool:
    status = subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True)
    return bool(status.strip())


def java_major() -> int:
    try:
        result = subprocess.run(
            ["java", "-version"],
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as exc:
        raise SystemExit("environment: java is not installed") from exc
    text = (result.stdout or "") + (result.stderr or "")
    match = re.search(r'version "(?:1\.)?(\d+)', text)
    if match is None:
        raise SystemExit(f"environment: could not read Java version from {text!r}")
    return int(match.group(1))


def load_pin() -> dict:
    return json.loads((ROOT / "server" / "PINNED.json").read_text(encoding="utf-8"))


def ensure_jar(pin: dict) -> Path:
    jars = ROOT / "server" / "jars"
    jars.mkdir(parents=True, exist_ok=True)
    dest = jars / f"server-{pin['version_id']}.jar"
    expected = pin["server_sha1"]
    size = pin["server_size"]
    if not dest.is_file() or dest.stat().st_size != size or sha1_file(dest) != expected:
        urllib.request.urlretrieve(pin["server_download_url"], dest)
    if dest.stat().st_size != size or sha1_file(dest) != expected:
        raise SystemExit("jar hash mismatch")
    return dest


def port_busy(port: int) -> bool:
    probe = socket.socket()
    probe.settimeout(0.5)
    try:
        return probe.connect_ex(("127.0.0.1", port)) == 0
    finally:
        probe.close()


def property_keys(text: str) -> dict[str, str]:
    found = {}
    for line in text.splitlines():
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        found[key] = value
    return found


def overlay_properties(text: str, updates: dict[str, str]) -> str:
    lines = []
    for line in text.splitlines():
        if not line or line.startswith("#") or "=" not in line:
            lines.append(line)
            continue
        key, value = line.split("=", 1)
        lines.append(f"{key}={updates[key]}" if key in updates else f"{key}={value}")
    return "\n".join(lines) + "\n"


def allowlist_lines() -> set[str]:
    allowed = set()
    for line in (ROOT / "tools" / "log-allowlist.txt").read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        allowed.add(line)
    return allowed


def scan_log(text: str) -> list[str]:
    pattern = re.compile(r"exception|failed to load|error", re.IGNORECASE)
    allowed = allowlist_lines()
    return [line for line in text.splitlines() if pattern.search(line) and line not in allowed]


def redact(text: str, password: str) -> str:
    if password:
        text = text.replace(password, "[REDACTED]")
    text = re.sub(r"(?m)^([A-Za-z0-9.-]*(?:password|secret)=).+$", r"\1[REDACTED]", text)
    return re.sub(r"\b[A-Za-z0-9]{40}\b", "[REDACTED-40]", text)


def looks_rejected(reply: str) -> bool:
    lowered = reply.lower()
    return any(token in lowered for token in REJECT_TOKENS)


class Server:
    def __init__(self, run_dir: Path, jar: Path) -> None:
        self.run_dir = run_dir
        self.jar = jar
        self.proc: subprocess.Popen | None = None
        self.log_handle = None
        self.console_path = run_dir / "console.log"
        self.log_path = run_dir / "logs" / "latest.log"

    def start(self) -> None:
        self.console_path.parent.mkdir(parents=True, exist_ok=True)
        self.log_handle = self.console_path.open("a", encoding="utf-8", errors="replace")
        self.proc = subprocess.Popen(
            ["java", "-Xms1G", "-Xmx2G", "-jar", str(self.jar), "--nogui"],
            cwd=self.run_dir,
            stdin=subprocess.PIPE,
            stdout=self.log_handle,
            stderr=subprocess.STDOUT,
            start_new_session=True,
            text=True,
        )
        (self.run_dir / "server.pid").write_text(str(self.proc.pid), encoding="utf-8")

    def stop(self) -> None:
        proc = self.proc
        if proc is None:
            return
        try:
            if proc.poll() is None and proc.stdin is not None:
                try:
                    proc.stdin.write("stop\n")
                    proc.stdin.flush()
                except OSError:
                    pass
            deadline = time.time() + 30
            while time.time() < deadline and proc.poll() is None:
                time.sleep(0.5)
        finally:
            if proc.poll() is None:
                try:
                    os.killpg(proc.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                time.sleep(1)
                if proc.poll() is None:
                    try:
                        os.killpg(proc.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
            if self.log_handle is not None:
                self.log_handle.close()
                self.log_handle = None
            pid_file = self.run_dir / "server.pid"
            if pid_file.exists():
                pid_file.unlink()
            self.proc = None

    def wait_for_exit_or_properties(self) -> None:
        deadline = time.time() + BOOT_TIMEOUT
        while time.time() < deadline:
            properties = self.run_dir / "server.properties"
            if self.proc is not None and self.proc.poll() is not None:
                return
            if properties.is_file() and self.proc is not None and self.proc.poll() is None:
                time.sleep(2)
                return
            time.sleep(0.5)
        raise SystemExit("environment: server boot exceeded 180 seconds")


def accept_eula_after_false_exit(run_dir: Path) -> None:
    eula_path = run_dir / "eula.txt"
    if not eula_path.is_file():
        return
    if not eula_path.resolve().is_relative_to(run_dir.resolve()):
        raise SystemExit("refusing to write an eula file outside run/")
    text = eula_path.read_text(encoding="utf-8", errors="replace")
    if re.search(r"(?m)^eula=false\s*$", text):
        eula_path.write_text("eula=true\n", encoding="utf-8")


def prepare_properties(run_dir: Path, password: str) -> None:
    path = run_dir / "server.properties"
    if not path.is_file():
        raise SystemExit("server.properties was not generated")
    original = path.read_text(encoding="utf-8", errors="replace")
    keys = property_keys(original)
    if "enable-rcon" not in keys:
        raise SystemExit("enable-rcon is absent from generated server.properties; command channel is missing")
    if "rcon.password" not in keys:
        raise SystemExit("rcon.password key is absent; a blank password refuses to start RCON")
    if "server-ip" not in keys:
        raise SystemExit("server-ip key is absent; refusing to boot without a localhost bind key")
    wanted = {
        "white-list": "false",
        "online-mode": "true",
        "enable-rcon": "true",
        "broadcast-rcon-to-ops": "false",
        "rcon.password": password,
        "server-ip": "127.0.0.1",
        "server-port": str(GAME_PORT),
        "rcon.port": str(RCON_PORT),
        "gamemode": "adventure",
        "difficulty": "peaceful",
        "spawn-monsters": "false",
        "view-distance": "2",
        "simulation-distance": "2",
        "enable-query": "false",
        "prevent-proxy-connections": "true",
        "management-server-enabled": "false",
        "level-name": "world",
        "function-permission-level": "2",
    }
    if "pause-when-empty-seconds" in keys:
        wanted["pause-when-empty-seconds"] = "0"
    applied = {key: value for key, value in wanted.items() if key in keys}
    path.write_text(overlay_properties(original, applied), encoding="utf-8")


def copy_datapacks(run_dir: Path) -> None:
    level = "world"
    properties = run_dir / "server.properties"
    if properties.is_file():
        level = property_keys(properties.read_text(encoding="utf-8", errors="replace")).get("level-name", "world") or "world"
    destination = run_dir / level / "datapacks"
    destination.mkdir(parents=True, exist_ok=True)
    for name in ("elysium", "elysium_test"):
        target = destination / name
        if target.exists():
            shutil.rmtree(target)
        shutil.copytree(ROOT / "datapacks" / name, target)


def wait_for_list(password: str, proc: subprocess.Popen) -> str:
    deadline = time.time() + BOOT_TIMEOUT
    last_error: Exception | None = None
    while time.time() < deadline:
        if proc.poll() is not None:
            raise SystemExit("server exited before RCON accepted list")
        try:
            with RconClient("127.0.0.1", RCON_PORT, password, timeout=5) as client:
                return client.command("list")
        except (OSError, RconError) as exc:
            last_error = exc
            time.sleep(1)
    raise SystemExit(f"readiness probe failed: RCON list was not accepted ({last_error})")


def run_cases(password: str) -> tuple[list[dict], str, list[str]]:
    payload = json.loads((ROOT / "tools" / "cases" / "F-0001.json").read_text(encoding="utf-8"))
    transcript: list[str] = []
    results: list[dict] = []
    clock_case = "not_run"
    with RconClient("127.0.0.1", RCON_PORT, password, timeout=10) as client:
        for probe in ("help item", "help tick"):
            reply = client.command(probe)
            transcript.append(f"$ {probe}\n{reply}")
        # Freeze so the 20-tick cadence cannot run between setup commands.
        freeze_reply = client.command("tick freeze")
        transcript.append(f"$ tick freeze\n{freeze_reply}")
        for case in payload["cases"]:
            case_notes = [f"case {case['id']}"]
            rejected = False
            for command in case.get("setup", []):
                reply = client.command(command)
                case_notes.append(f"$ {command}\n{reply}")
                rejected = rejected or looks_rejected(reply)
            if case.get("advance_ticks"):
                # 26.3: tick step advances a frozen game and returns when the ticks
                # have run. tick sprint returns before its ticks finish.
                command = "tick step 40t"
                reply = client.command(command)
                case_notes.append(f"$ {command}\n{reply}")
                if looks_rejected(reply):
                    command = payload["clock"]["prefer_command"]
                    reply = client.command(command)
                    case_notes.append(f"$ {command}\n{reply}")
                    if looks_rejected(reply):
                        time.sleep(3)
                        clock_case = payload["clock"]["fallback_manifest_value"]
                        case_notes.append("tick step and tick sprint were rejected; waited 3 seconds; clock_case: wall_clock")
                    else:
                        clock_case = payload["clock"]["prefer_manifest_value"]
                        time.sleep(1.0)
                else:
                    clock_case = "tick_step"
            queries = payload["queries"]
            patterns = payload.get("reply_patterns", {})
            expected = case.get("expect", {})
            prefix = patterns.get("storage_prefix", "")
            passed_text = patterns.get("test_passed", "")
            mismatches = []

            def run_query(key: str) -> str:
                query_reply = client.command(queries[key])
                case_notes.append(f"$ {queries[key]}\n{query_reply}")
                return query_reply

            def storage_number(query_reply: str) -> str:
                text = query_reply.strip()
                if prefix and text.startswith(prefix):
                    return text[len(prefix):].strip()
                return ""

            if "chest" in expected:
                if run_query("chest").strip() != passed_text:
                    mismatches.append("chest")
            if expected.get("marker") == "minecraft:tuff":
                if run_query("marker_tuff").strip() != passed_text:
                    mismatches.append("marker")
            if expected.get("marker") == "minecraft:prismarine":
                if run_query("marker_prismarine").strip() != passed_text:
                    mismatches.append("marker")
            for field in ("done", "awards", "rejects"):
                if field in expected:
                    if storage_number(run_query(field)) != str(expected[field]):
                        mismatches.append(field)
            if "witness_count" in expected:
                run_query("witness_store")
                if storage_number(run_query("witness_get")) != str(expected["witness_count"]):
                    mismatches.append("witness_count")
            if "forceload_chunks" in expected:
                loaded = run_query("forceload")
                count_text = patterns.get("forceload_count", "")
                chunks = patterns.get("forceload_chunks", [])
                if count_text not in loaded or any(chunk not in loaded for chunk in chunks):
                    mismatches.append("forceload")
            if rejected:
                status = "fail"
                reason = "command_rejected"
            elif not payload.get("reply_patterns_locked"):
                status = "fail"
                reason = "reply_pattern_unverified"
            elif mismatches:
                status = "fail"
                reason = "mismatch:" + ",".join(mismatches)
            else:
                status = "pass"
                reason = "matched"
            results.append({"id": case["id"], "result": status, "reason": reason})
            transcript.extend(case_notes)
            transcript.append(f"result {case['id']}: {status} ({reason})")
    return results, "\n".join(transcript) + "\n", clock_case


def attempt_evidence_dir(attempt: int) -> Path:
    override = os.environ.get("ELYSIUM_EVIDENCE_DIR", "").strip()
    if override:
        dest = Path(override) / f"attempt-{attempt}"
    else:
        dest = ROOT / "evidence" / "m0" / "attempts" / f"attempt-{attempt}"
    dest.mkdir(parents=True, exist_ok=True)
    return dest


def one_attempt(pin: dict, jar: Path, attempt: int, password: str) -> dict:
    run_dir = ROOT / "run"
    if run_dir.exists():
        shutil.rmtree(run_dir)
    run_dir.mkdir(parents=True)
    server = Server(run_dir, jar)
    try:
        server.start()
        server.wait_for_exit_or_properties()
        server.stop()
        eula_path = run_dir / "eula.txt"
        eula_text = eula_path.read_text(encoding="utf-8", errors="replace") if eula_path.is_file() else ""
        if re.search(r"(?m)^eula=false\s*$", eula_text):
            accept_eula_after_false_exit(run_dir)
        if not (run_dir / "server.properties").is_file():
            server.start()
            server.wait_for_exit_or_properties()
            server.stop()
            if eula_path.is_file() and re.search(r"(?m)^eula=false\s*$", eula_path.read_text(encoding="utf-8", errors="replace")):
                accept_eula_after_false_exit(run_dir)
        prepare_properties(run_dir, password)
        copy_datapacks(run_dir)
        server.start()
        assert server.proc is not None
        ready = wait_for_list(password, server.proc)
        cases, transcript, clock_case = run_cases(password)
        client_stop = ""
        with RconClient("127.0.0.1", RCON_PORT, password, timeout=10) as client:
            client_stop = client.command("stop")
        deadline = time.time() + 30
        while time.time() < deadline and server.proc is not None and server.proc.poll() is None:
            time.sleep(0.5)
        # Scan the test boot's own log. The first boot of an empty run/
        # logs a missing server.properties stack before it creates the file.
        # That text stays in console.log and is stored, and it is not the test log.
        log_text = ""
        if server.log_path.is_file():
            log_text = server.log_path.read_text(encoding="utf-8", errors="replace")
        elif server.console_path.is_file():
            log_text = server.console_path.read_text(encoding="utf-8", errors="replace")
        properties = (run_dir / "server.properties").read_text(encoding="utf-8", errors="replace")
        transcript = f"readiness list:\n{ready}\nstop:\n{client_stop}\n" + transcript
        redacted_transcript = redact(transcript, password)
        redacted_log = redact(log_text, password)
        redacted_properties = redact(properties, password)
        if password in redacted_transcript or password in redacted_log or password in redacted_properties:
            raise SystemExit("refusing to store a transcript that still contains the RCON password")
        evidence = attempt_evidence_dir(attempt)
        (evidence / "transcript.txt").write_text(redacted_transcript, encoding="utf-8")
        (evidence / "server.log").write_text(redacted_log, encoding="utf-8")
        (evidence / "server.properties").write_text(redacted_properties, encoding="utf-8")
        log_failures = scan_log(redacted_log)
        return {
            "attempt": attempt,
            "cases": cases,
            "clock_case": clock_case,
            "log_failures": log_failures,
            "log_sha256": sha256_text(redacted_log),
            "transcript_sha256": sha256_text(redacted_transcript),
            "readiness_probe": "rcon list",
        }
    except Exception as exc:
        message = f"{type(exc).__name__}: {exc}"
        evidence = attempt_evidence_dir(attempt)
        (evidence / "runner-error.txt").write_text(message + "\n", encoding="utf-8")
        if server.log_path.is_file():
            (evidence / "server.log").write_text(
                redact(server.log_path.read_text(encoding="utf-8", errors="replace"), password),
                encoding="utf-8",
            )
        return {
            "attempt": attempt,
            "cases": [{"id": "runner", "result": "fail", "reason": message}],
            "clock_case": "not_run",
            "log_failures": [message],
            "log_sha256": None,
            "transcript_sha256": None,
            "readiness_probe": "rcon list",
        }
    finally:
        server.stop()


def main() -> int:
    started = now()
    pin = load_pin()
    major = java_major()
    if major < int(pin["java_major"]):
        raise SystemExit(f"environment: Java {major} is older than pinned Java {pin['java_major']}")
    if port_busy(GAME_PORT) or port_busy(RCON_PORT):
        raise SystemExit("environment: default game or RCON port is already in use")
    jar = ensure_jar(pin)
    import secrets

    password = secrets.token_urlsafe(18)
    dirty = git_dirty()
    attempt_count = int(os.environ.get("ELYSIUM_ATTEMPTS", "2"))
    attempts = []
    try:
        for number in range(1, attempt_count + 1):
            attempts.append(one_attempt(pin, jar, number, password))
    finally:
        password = ""
    failed = dirty or any(
        case["result"] != "pass" or attempt["log_failures"]
        for attempt in attempts
        for case in attempt["cases"]
    ) or len(attempts) != attempt_count
    manifest = {
        "run_id": f"{git_sha()}-author",
        "role": "author",
        "git_sha": git_sha(),
        "git_dirty": dirty,
        "spec": "F-0001",
        "game_version": pin["version_id"],
        "server_jar_sha1": pin["server_sha1"],
        "java_version": major,
        "started_at": started,
        "ended_at": now(),
        "exit_code": 1 if failed else 0,
        "attempts": [
            {
                "attempt": attempt["attempt"],
                "clock_case": attempt["clock_case"],
                "cases": attempt["cases"],
                "log_failures": attempt["log_failures"],
                "log_sha256": attempt["log_sha256"],
                "transcript_sha256": attempt["transcript_sha256"],
            }
            for attempt in attempts
        ],
        "clock_case": attempts[-1]["clock_case"] if attempts else "not_run",
        "readiness_probe": "rcon list",
        "management_protocol": "not_used",
        "human_playtest": "none",
        "simulation": "not_run",
        "log_sha256": attempts[-1]["log_sha256"] if attempts else None,
        "transcript_sha256": attempts[-1]["transcript_sha256"] if attempts else None,
        "release_zip_sha256": None,
        "secrets_redacted": True,
        "unverified": [
            "discovery",
            "visual quality",
            "difficulty feel",
            "narrative",
            "client behavior",
            "fun",
        ],
        "runtime_pass": False if failed else True,
    }
    rendered = json.dumps(manifest, indent=2) + "\n"
    if os.environ.get("ELYSIUM_WRITE_MANIFEST", "1") == "0":
        print(rendered)
        return int(manifest["exit_code"])
    out = ROOT / "evidence" / "m0" / f"{manifest['git_sha']}-author.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(rendered, encoding="utf-8")
    print(json.dumps({"exit_code": manifest["exit_code"], "manifest": str(out)}, indent=2))
    return int(manifest["exit_code"])


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SystemExit:
        raise
    finally:
        pid = ROOT / "run" / "server.pid"
        if pid.is_file():
            try:
                os.killpg(int(pid.read_text(encoding="utf-8").strip()), signal.SIGKILL)
            except (OSError, ValueError):
                pass
PY
