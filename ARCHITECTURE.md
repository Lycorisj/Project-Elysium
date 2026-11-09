# Architecture

Creative direction 《折潮》 is accepted in D-0005. The setting is not yet built. This file describes the pipeline. F-0001 stays non-canon plumbing.

## Packs

One ship datapack lives in `datapacks/elysium`, namespace `elysium`. It is tested on the vanilla dedicated server and must stay legal on the integrated server at permission level 2. The test datapack `datapacks/elysium_test` is copied into the test world and excluded from the release zip.

`pack.mcmeta` uses `min_format` and `max_format` only. For this pin both are the integer `121`, the major data-pack format from the 26.3 article's `121.0`. There is no legacy `pack_format` field. The server enabling the pack is the proof. That boot has not happened. Bug MC-310337 can make a log demand `pack_format`; do not add the field because of that sentence if the pack already loads.

Feature functions live under `elysium:ledger/…`. A feature does not write another feature's storage root. `elysium:load` and `elysium:tick` only call per-feature functions. They contain no feature logic. Load creates the default ledger when it is missing. Tick arms a 20-tick schedule that calls `elysium:ledger/evaluate`. Evaluate is not called every tick.

The Server Management Protocol does not execute functions and is not the M0 command channel. Tests use RCON, via `tools/rcon.py`, after D-0001 is accepted.

## Strings

F-0001 has one player-facing advancement, `elysium:slice/ledger_cleared`. The title names the ledger and the description names the marker. They do not describe a world, a character, or a victory. Chinese is primary: `resourcepacks/elysium/assets/elysium/lang/zh_cn.json`. English is the fallback language file: `en_us.json`. The advancement `fallback` strings are the Chinese values, so a client without the resource pack still shows Chinese. This resource pack is outside the section 8 datapack tree because the assignment required `zh_cn` and `en_us` files. It is not in the release zip. It does not accept a class S language decision for the map. No client was launched, so the files are static only.

The advancement is a visible root, so it sets `background` to a vanilla texture path. That path is unverified until boot. It is UI chrome, not a setting.

## World

Code-defined rooms are the source until a binary-world decision. The M0 map artifact is `elysium:ledger/place_room`. It fills `slice-origin` and is deterministic. Region files are build output. No `.mca` is committed. Git LFS is not part of M0. A future binary world needs its own class T decision before any `*.mca` is force-added.

Spawn chunks have not existed since 1.21.9. The test server has no player. `place_room` forceloads the four chunk columns the room occupies: `(-1, -1)`, `(-1, 0)`, `(0, -1)`, and `(0, 0)`. The forceload command uses the room's block footprint, which is inside the reserved box. The per-command selection cap is 256 chunks; this room is four. The command is permission level 2. `forceload query` naming those chunks is unverified until boot.

Save model: regenerate the slice by running `place_room` again. A second call does not reset an existing ledger. It kills tagged witnesses and summons one, so the witness count stays one. It places the marker as tuff even if `ledger.done` is already 1. That desync is recorded in the feature spec. Reset is `elysium_test:reset`, and it does not move the room.

## State

State lives in storage `elysium:slice`, not in scoreboard objectives. The ledger document is `{done, awards, rejects}`. `seen.items` is the last chest-item copy used for the edge trigger. `clock` arms the 20-tick cadence. `tmp` is scratch for one evaluate. Numeric increments use the 26.3 `data modify … set compute` integer `add` of a `storage` provider. That command was not executed.

## Coordinates

`specs/REGISTRY.md` owns inclusive block bounds. M0 reserves only `slice-origin`, x `-6..6`, y `99..104`, z `-6..6`. The chest is `(0, 100, 0)`. The marker is `(0, 100, 2)`. The witness is one armor stand tagged `elysium.witness` at `(0, 100, -2)`. Placement outside a reserved region fails review. Overlapping reservations fail review.

The witness is invisible, marker-sized, silent, and has no custom name. Those flags keep it from reading as a character. The NBT is unverified until boot.

## Servers

`server/PINNED.json` is the version pin. Java major, the server URL, SHA-1, and size come from the public version manifest and the linked launcher version JSON, read 2026-11-08. Data pack `121.0` and resource pack `97.1` come from the Minecraft.net 26.3 article read the same day. World version and protocol are null: they are not fields of that manifest, and the jar was not opened. Snapshots are not pinned. The observed latest snapshot was `26.4-snapshot-7`.

`server/server.properties.test.template` is the test overlay, including `pause-when-empty-seconds=0` and `function-permission-level=2`. The release template does not pause-disable the empty server, leaves RCON off, leaves the management server off, and fills in no password. Generated properties exist only under `run/`. The runner overlays a key only when the server's own generated file already has that key. If `enable-rcon` is absent, the run stops. `management-server-enabled` stays false.

`locator_bar` is turned off once a canon area could be spoiled by a waypoint. No canon area exists, so M0 does not set that gamerule.

## What is unverified

Every command in the datapack, the advancement root background, the compute increment, the `data modify` change detector, `/item override`, `/item fill`, `data remove` for an empty chest, `/forceload`, and `/tick sprint` are unverified until a dedicated-server boot accepts them. This architecture does not claim that boot.
