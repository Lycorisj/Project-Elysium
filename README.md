# Project Elysium

Project Elysium is an original Minecraft Java Edition Complete-the-Monument map: a sequence of areas, each with a challenge, each contributing visible progress toward a monument, playable from a fresh start through a victory state in single-player and on a vanilla dedicated server.

No creative direction is accepted yet. No creative canon is accepted. The current milestone is M0, the pipeline. M0 is not complete. This branch stops at the Minecraft EULA gate in `decisions/D-0001-minecraft-eula.md`. The dedicated server was not downloaded and was not launched.

F-0001 Ledger Cairn is non-canon plumbing used to prove the pipeline. It is not the monument, and it is not a map.

## Evidence on this change

| Label | Value |
| --- | --- |
| Automated | pass, static files only, if `tools/static_validate.py` exits 0. The dedicated-server suite was not run |
| Simulation | not run |
| Human playtest | none |

human playtest: none. simulation: not run.

These labels do not say the slice is fun, fair, clear, or finished. Nobody has played this commit.

## Checks

Static check, from the repository root:

```text
python3 tools/static_validate.py
```

Dedicated-server check:

```text
tools/run_tests.sh
```

`tools/run_tests.sh` reads D-0001 first. While that decision is `proposed`, the script exits before any jar download, before writing `eula=true`, and before launching Java. A developer downloads the pinned jar only after the owner accepts D-0001. The URL, SHA-1, size, and Java major are in `server/PINNED.json`. The jar is not committed. Put it in `server/jars/`, which is gitignored. `tools/run_tests.sh` checks the SHA-1 before it trusts a local file.

`tools/pack_release.sh` writes `dist/elysium-datapack.zip`. That zip is build output and is not committed.

## Documents

- `AGENTS.md` — rules for agents
- `PROJECT_CHARTER.md` — why the project exists and who decides what
- `VISION.md` — creative canon, currently unaccepted
- `ARCHITECTURE.md` — datapack, server, and save model
- `ROADMAP.md` — milestones
- `DECISIONS.md` — decision index
- `QUALITY_STANDARDS.md` — gates and banned claims
- `TESTING_STRATEGY.md` — what the checks mean
- `CONTRIBUTING.md` — branches, reviews, and the owner boundary

## License

No license is granted until a class S decision says otherwise. Do not treat this tree as reusable game content.

## Tree

```text
decisions/          class S and class T records
specs/              feature contracts and the registry
datapacks/elysium/  the ship datapack
datapacks/elysium_test/  the test datapack, excluded from the release zip
resourcepacks/elysium/  zh_cn and en_us strings for the one advancement
map/                points at the placement function; no region files
server/             pin and property templates; no jar
tools/              static validator, test runner, RCON client, packer
evidence/m0/        reserved for a future author manifest
```

`run/`, `dist/`, `server/jars/`, logs, worlds, and `eula.txt` are gitignored.
