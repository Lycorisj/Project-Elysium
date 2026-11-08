---
id: F-0001
title: Ledger Cairn
status: draft
class: technical-slice
canon: false
depends_on: []
regions: [slice-origin]
storage: ["elysium:slice ledger", "elysium:slice seen.items", "elysium:slice clock"]
functions: ["elysium:ledger/evaluate", "elysium:ledger/place_room"]
advancements: ["elysium:slice/ledger_cleared"]
---

# F-0001 Ledger Cairn

No creative direction is accepted yet. No creative canon is accepted. This slice is non-canon plumbing. D-0003 records that. The status stays `draft` until a reviewer manifest exists, and it is not `implemented` on this change. Every command below is unverified until a dedicated-server boot accepts it.

## Player-visible behavior

A chest sits at `(0, 100, 0)` on a deepslate-tile floor. A marker block sits at `(0, 100, 2)`. It is tuff until the success pattern is met, then it is prismarine. One armor stand tagged `elysium.witness` stands at `(0, 100, -2)`. It has no custom name.

When the pattern succeeds and a player is online, that player is granted advancement `elysium:slice/ledger_cleared`. The title is the ledger and the description is the marker. Chinese is the primary string (`账本`, `标记`). English is the fallback language file (`Ledger`, `Marker`). The text does not describe a world, a character, or a victory. If no player is online, the advancement is not granted and the command must not error. The marker still changes. Awards still increment.

There is no other player-facing string.

## Non-goals

- A setting, a story, a character, or a victory fiction.
- The monument, a region count, or a piece count.
- A class S language decision for the map. The `zh_cn` / `en_us` pair is plumbing for this advancement.
- A claim that the slice is fun, fair, clear, or worth playing.
- Scoreboard objectives.
- A protocol bot, a client render, or a human playtest.
- Shipping the test datapack or the resource pack inside the M0 release zip.

## Normative mechanics

Origin is the chest at `(0, 100, 0)`. Bounds are `slice-origin`: x `-6..6`, y `99..104`, z `-6..6`, inclusive.

`elysium:ledger/place_room`:

- Forceloads the chunks touched by x `-6..6` and z `-6..6`. Those columns are `(-1, -1)`, `(-1, 0)`, `(0, -1)`, and `(0, 0)`. The command in git is `forceload add -6 -6 6 6`, using block coordinates of the room. `forceload query` must show those four chunks. This was not queried.
- Fills x `-6..6`, y `100..104`, z `-6..6` with air.
- Fills x `-6..6`, y `99`, z `-6..6` with deepslate tiles.
- Places a chest at `(0, 100, 0)`.
- Places tuff at `(0, 100, 2)`.
- Removes every armor stand tagged `elysium.witness` and summons one at `(0, 100, -2)` with that tag. A second call does not leave a second stand. The stand is invisible, marker, silent, invulnerable, and has no gravity. Those flags are technical. They are unverified NBT.
- Initializes `storage elysium:slice` key `ledger` to `{done:0, awards:0, rejects:0}` when the key is missing. A second call does not reset a ledger that already exists. It also creates `seen.items` as an empty list and `clock` as `{loop:0b}` when those keys are missing. It does not clear them when they already exist.

`elysium:ledger/evaluate`:

- If `ledger.done` is 1, return immediately. Awards, rejects, the marker, and the chest stay as they are.
- Preconditions: the origin is a chest, and exactly one `elysium.witness` armor stand is within 3 blocks of the origin. If either fails, set `done` 0, set the marker to tuff, and do not increment awards or rejects.
- Missing chest `Items` counts as an empty list.
- Success pattern: the item list has length 2, slot 0 is exactly one `minecraft:amethyst_shard`, and slot 1 is exactly one `minecraft:echo_shard`. Every other slot is empty because an empty slot is absent from `Items`.
- On success: set `done` 1, increment `awards` by 1, set the marker to prismarine, and copy the current item list into `seen.items`. Grant the advancement only if a player exists. Awards increment whether or not a player exists.
- On pattern failure with preconditions met: set the marker to tuff and set `done` 0. Increment `rejects` only when the chest's item list changed since the last compare. The compare is `execute store success … run data modify` from the normalized item list into `seen.items`. An unchanged copy fails that command and does not increment. Two evaluates of an unchanged wrong chest yield `rejects` 1. The first evaluate of an empty chest, with `seen.items` still empty, yields `rejects` 0.
- The increment uses `data modify … set compute default integer` with an `add` of the current storage value and the constant 1. That syntax is taken from the 26.3 command notes. It was not executed. If the server rejects it, stop and record the real result in a class T note, then implement the same increment with a method the server demonstrated. Do not add a scoreboard objective to get around a failure without that note.

`elysium:load` calls init, clears the clock loop flag, and clears any scheduled cadence.

`elysium:tick` calls `elysium:ledger/arm_clock` once. That function schedules `elysium:ledger/cadence` for 20 ticks. The cadence runs evaluate and schedules itself again for 20 ticks. A clock that calls evaluate every tick and increments rejects every call is a defect. The edge trigger is what keeps an unchanged chest from climbing. The cadence is what keeps evaluate off the per-tick path.

`elysium_test:reset` sets the ledger back to `{done:0, awards:0, rejects:0}`, sets `seen.items` to `[]`, removes `tmp`, and sets the marker to tuff. It does not move the room, the chest, or the witness.

There is no tuning table. Counts are the integers in this section: one shard in slot 0, one shard in slot 1, a 20-tick cadence, and a 3-block witness radius.

## Failure and edge cases

- `done` 1 ignores later chest edits, including a chest full of cobblestone. The marker stays prismarine and `awards` stays where it was.
- A missing chest or a witness count other than 1 does not increment `awards` or `rejects`.
- A second `place_room` after success sets the marker back to tuff and does not clear `done`. The next evaluate returns immediately, so the marker can stay tuff while `done` is 1. No case covers that order. Do not "fix" it by resetting the ledger inside `place_room`.
- `place_room` does not clear `seen.items` when the ledger already exists. Tests that need a clean edge trigger call `elysium_test:reset`.
- If the item list order or extra item components makes an identical chest look changed, `rejects` can climb. That result is unverified. If a boot shows it, keep the edge-trigger behavior and change the compare in the same pull request as the spec.
- If `amethyst_shard` or `echo_shard` is missing on the pin, stop. Do not substitute another item.

## Automated checks

Static: `tools/static_validate.py` must exit 0. That check is the only automated check this change runs.

Server, after D-0001 is accepted, and not run on this change: the eight cases in `TESTING_STRATEGY.md` and `tools/cases/F-0001.json`. Reply patterns are unlocked, so the runner must not report those cases as passed. Chest edits use `/item override` and `/item fill`, not `/item replace`. Emptying the chest in the `empty` case uses `data remove block 0 100 0 Items`. The block queries name `0 100 0` and `0 100 2`.

`clock_stable` advances 40 ticks with `tick sprint 40` when the server accepts that command. Otherwise the runner waits 3 seconds, says so, and records `clock_case: wall_clock`. This change records neither value.

## Simulation checks

Not run. Mineflayer is not a dependency, and protocol support for the pin was not established.

## Human questions

Unanswered. No human has played this commit. Discovery is unverified. Do not write an answer here on an agent's behalf.

## Evidence required

- `automated`: pass only if `tools/static_validate.py` exits 0, scoped to static files. Dedicated-server automated result: not run.
- `simulation`: `not_run`.
- `human_playtest`: `none`.
- Unverified: the commands in this spec, reply patterns, discovery, visual quality, difficulty feel, narrative, client behavior, and fun.
- A runtime pass is not claimed.
