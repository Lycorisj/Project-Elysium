# Testing strategy

No creative direction is accepted yet. No creative canon is accepted.

Layers run in order. M0 is specified to run the first three. Layer 4 waits. On this change only layer 1 can run, because D-0001 is proposed.

## Layer 1 — static

`tools/static_validate.py` uses the Python 3 standard library only. It parses JSON under `datapacks/`, `tools/cases/`, and `resourcepacks/`. It requires `pack.mcmeta` on each datapack, rejects legacy plural `functions/` and `advancements/` directories, rejects illegal namespace characters, checks that tag function ids and registry rows have files, rejects tracked `.jar`, `.mca`, and `eula.txt` files, and rejects `elysium_test` references inside `datapacks/elysium`.

It also checks the F-0001 case list, the unlocked reply patterns, the Chinese-primary advancement strings, the pin metadata, and that `place_room` stays inside `slice-origin`.

A static failure skips the server. Fix the files or the validator. Do not start Java to see whether JSON is really wrong.

A zero exit is `automated: pass` with scope `static_files_only`. It is not a dedicated-server result.

## Layer 2 — dedicated server

`tools/run_tests.sh` does not reach this layer while D-0001 is `proposed`. It must not write `eula=true` ahead of that decision, and it must not download the jar.

After D-0001 is `accepted`, the script:

1. Reads `server/PINNED.json` and downloads the jar into `server/jars/` only when the local SHA-1 or size does not match. A mismatch after download is a failed run.
2. Requires at least the pinned Java major. An older major is a failed run.
3. Wipes `run/`, generates an RCON password for that process, binds the game and RCON to `127.0.0.1`, and uses ports `25565` and `25575` because M0 is a single agent.
4. Boots `nogui` with memory `1G`–`2G` and a 180 second timeout. If the server exits while `run/eula.txt` is still false, the script writes `eula=true` inside `run/` only and boots again.
5. Overlays test values onto keys the generated `server.properties` already contains. If `enable-rcon` is absent, it stops. It does not claim a pass. `function-permission-level` stays 2. `pause-when-empty-seconds=0` is set only when that key exists. The management server stays off.
6. Copies both datapacks into the run world and boots again. Readiness is the first successful RCON login and a reply to `list`. A `Done` log line is not required.
7. Runs every case, scans the log, sends `stop`, and kills the process group on a timeout. The shell `trap` is installed before the gate returns and before any later boot.
8. Redacts the RCON password and any 40-character token before writing evidence. A transcript that still contains the password is not stored.
9. Exits non-zero when a case fails, the log scan fails, the tree was dirty, the jar hash drifts, or reply patterns are not locked.

The release property template is not used by the suite.

## Layer 3 — cases

State is storage `elysium:slice` key `ledger`. The runner reads `data get storage elysium:slice ledger.done` and the sibling award and reject paths, and it reads the marker with a block query that names the coordinates. Expected reply patterns are not locked. They are recorded after the pinned server answers. Until `reply_patterns_locked` is true, the runner stores the raw replies and marks every case failed with `reply_pattern_unverified`. That failure is intentional. It blocks a false runtime pass.

The runner executes every case even after a failure.

| Case | Setup | Expect |
| --- | --- | --- |
| `place_room` | Run `elysium:ledger/place_room` twice | Chest at the origin, exactly one witness, marker is tuff, `done` 0, `awards` 0, `rejects` 0, and `forceload query` lists the four room chunks |
| `empty` | Empty chest, evaluate once | `done` 0, marker tuff, `rejects` 0 |
| `wrong_item` | Slot 0 is one cobblestone, evaluate twice | `done` 0, marker tuff, `rejects` 1 |
| `success` | Success pattern, evaluate once | `done` 1, `awards` 1, marker prismarine |
| `idempotent` | Evaluate again with no chest change | `awards` stays 1, `done` stays 1 |
| `locked` | After success, fill the chest with cobblestone, evaluate | `done` stays 1, marker stays prismarine, `awards` stays 1 |
| `witness_missing` | Reset, success pattern, remove the witness, evaluate | `done` 0, `awards` 0 |
| `clock_stable` | Reset, wrong item once, advance 40 ticks if `/tick sprint` works, otherwise wait 3 seconds and say so | `rejects` is 1, not a per-tick climb |

`elysium_test:reset` restores the ledger and the marker. It does not move the room. Cases that name a reset call it first. The other cases run in the order above and keep world state.

Chest edits in `tools/cases/F-0001.json` use `/item override` and `/item fill`. They are not a 1.21 `/item replace` snippet. Emptying uses `data remove` because the public `/item` forms place an item. All of those commands are unverified until boot. If the server rejects one, change the command, keep the behavior, and quote the server's error. If `amethyst_shard` or `echo_shard` is not an item on the pin, stop and file a class T amendment. Do not swap in a different item and call the case green.

Tick advance prefers `tick sprint 40` when the server accepts it. If the reply is a rejection, the runner waits 3 seconds and records `clock_case: wall_clock`. A failure of only that case still fails the run. This change did not choose either clock value, because the server did not run.

## Layer 4 — simulated player

Not in M0. A protocol bot would be simulation. It is not a dependency. The manifest value is `simulation: not_run`. Do not add a bot to produce a playtest paragraph.

## What a green suite means

A green server suite would mean the pinned vanilla server loaded this datapack and the scripted chest states produced the scripted storage and block results, twice, and a second party re-ran that. It would not mean a person can understand the room, that the room looks finished, or that the monument map exists.

That suite has not gone green. The static validator is the only automated result this change can claim, and only when it exits 0.

## Redaction

Evidence copies drop the process RCON password and 40-character tokens before they are written. The committed tree must not contain `run/`, `dist/`, the jar, `eula.txt`, or a live password. The test template leaves `rcon.password` empty.
