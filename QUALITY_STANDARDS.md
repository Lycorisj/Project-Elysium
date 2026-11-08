# Quality standards

No creative direction is accepted yet. No creative canon is accepted. These are rules a reviewer can apply. They are not a judgment that a build is good to play.

## Evidence labels

Every pull request and manifest uses these values or a real artifact. Silence is a review failure.

- `automated: pass` or `automated: fail`, with the manifest or validator output.
- `simulation: not_run` until a bot run exists. Then `simulation: pass` or `fail`, with the script id, the tool version, and the transcript path.
- `human_playtest: none` until a human note exists. Then the path of the verbatim note, the commit the person played, and whether they were given hints.

A human note is that person's text. Agents may wrap it with the commit SHA and the date. They do not rewrite it. A summary is a second document that links the verbatim file.

On this change the automated label is a static pass only when `tools/static_validate.py` exits 0. Simulation is not run. Human playtest is none.

## Banned as evidence

Stating any of these as fact is a review failure:

- The map is fun, boring, fair, unfair, scary, funny, beautiful, clear, confusing, or complete.
- "I played it," "a player would," "playtesters will," or "this feels better."
- A screenshot or video that is a generated mockup, described as if it came from the game.
- A log the author paraphrases without attaching the redacted output.
- A skipped case reported as a pass.
- A suite that failed once and passed once, reported as stable.
- Simulated success described with the word playtested.

An allowed observation restates a tool result. "No human has played this commit" is allowed. "Simulation was not run" is allowed. "The static validator exited 0" is allowed. "The dedicated server accepted this command" is allowed only with the redacted transcript.

## Required manifest fields

A runtime author manifest, written only after a real server run, has:

- `run_id`, `role`, `git_sha`, `git_dirty`, `spec`
- `game_version`, `server_jar_sha1`, `java_version`
- `started_at`, `ended_at`, `exit_code`, `attempts`
- `cases` with id and pass/fail for all eight
- `clock_case`: `tick_sprint` or `wall_clock`
- `readiness_probe`: `rcon list`
- `management_protocol`: `not_used`
- `human_playtest`: `none` until a note exists
- `simulation`: `not_run` until a bot run exists
- `log_sha256`, `transcript_sha256`, `release_zip_sha256`
- `secrets_redacted`: true
- `unverified`: discovery, visual quality, difficulty feel, narrative, client behavior, fun

This change has no runtime manifest. Writing one that claims the eight cases passed would be false. `tools/run_tests.sh` refuses to start the server while D-0001 is proposed, and it refuses to mark a case passed while reply patterns are unlocked.

## Technical gates

These block merge to the default branch.

| Id | Gate |
| --- | --- |
| T1 | The diff cites a spec id, and the spec's normative text matches the tests |
| T2 | The diff stays inside the brief's allow-path |
| T3 | `tools/static_validate.py` exits 0 |
| T4 | The pinned jar's SHA-1 matches, and the server process reaches the RCON probe |
| T5 | `tools/run_tests.sh` exits 0, every case in the spec ran, and the redacted transcript is stored |
| T6 | `specs/REGISTRY.md` includes every new id and bound |
| T7 | Two consecutive runs on wiped `run/` directories pass, and every attempt is recorded. A mixed fail/pass is not green |
| T8 | The author manifest has the required fields, a clean `git status`, and the SHA of the commit under test |
| T9 | A different agent, or the coordinator, re-ran the suite on that SHA and stored a reviewer manifest with exit code 0 |
| T10 | The diff contains no jar, world, log, `eula.txt`, password, or management secret |
| T11 | `tools/pack_release.sh` exits 0 and its file list omits the test pack |

The pass signal for a server run is the RCON cases, not a quiet log. After a run, scan the log. A line matching `exception`, `failed to load`, or `error` fails the run unless that exact line is in `tools/log-allowlist.txt` with a one-line reason. The allowlist starts empty of patterns. Do not loosen the regex to obtain a pass. Absence of those lines is not itself a pass.

A change that deletes or weakens a case also edits the spec and says why. A case is not removed because it failed.

Two clean runs plus a reviewer re-run are the server bar. A flake is a failure.

On this change, T3 is the gate that can already be green. T4, T5, T7, T8, and T9 are not met, because no server was launched. T11 can be checked by the packer without a server; a packer exit of 0 is not a runtime pass.

## Creative gates

| Id | Rule | Effect |
| --- | --- | --- |
| C1 | Player-facing text in a `canon: false` feature invents no setting, character, or victory fiction | Blocks merge |
| C2 | A player-facing feature names a completion signal the server can set and a person could see. M0's signal is the marker block | Blocks merge |
| C3 | The pull request states the simulation value | Blocks merge. `not_run` is valid |
| C4 | The pull request states the human-playtest value | Blocks merge. `none` is valid |
| C5 | Numeric balance changes edit the spec's tuning table and the tests | Blocks merge |
| C6 | Content-accepted and release packets include the unverified list and the three labels | Blocks those packets. Does not block an M0 engineering merge |

No gate turns a green suite into a judgment that the map is good to play. The word "playtested" is reserved for a human note.

## Residual risk

Two agents can invent a transcript that looks like a run. The reviewer re-run is still required. Until a runner outside the author's VM exists, documents say "re-run by a second agent." They do not say "independently verified by CI." GitHub Actions is not part of M0 and is not already gating merges.
