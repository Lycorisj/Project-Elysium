# Project charter

Project Elysium exists to ship an original Minecraft Java Edition Complete-the-Monument map. The owner makes strategic and creative decisions, accepts milestones, and approves a release. Agents do the routine building, programming, testing, balancing inside an accepted spec, and debugging.

No creative direction is accepted yet. No creative canon is accepted.

## Authority

The owner owns class S decisions, listed in `AGENTS.md`. Agents own class T decisions by merge, listed there and indexed in `DECISIONS.md`. Agents may write a one-page proposal with two or three options and one recommendation. They do not enact a class S proposal.

The owner is not asked to compile, run Java, read a stack trace, resolve a git conflict, pick a pack format, or playtest as the condition for routine work. If the owner plays of their own accord, those notes are human-playtest evidence and are filed verbatim.

## Genre contract

The genre contract is structural. The map is a sequence of areas. Each area has a challenge. Each area contributes visible progress toward a monument. A player can start fresh and reach a victory state in single-player and on a dedicated server.

The setting, the monument's meaning, the piece count, the tone, the difficulty intent, and the victory fiction are creative canon. They do not exist until the owner accepts them in a class S decision. Until then, agents build pipeline and non-canon slices. They do not invent the game in order to have something to build.

## Shipping target

- Minecraft Java Edition, one datapack and one world, playable in single-player and on a vanilla dedicated server.
- The automated oracle is the vanilla dedicated server. Single-player is not a second codebase.
- Functions stay within permission level 2, the integrated-server cap and the dedicated-server default. A pass at level 2 is the evidence that the same function is legal in single-player. Raising the level to make a test pass is a failed design.
- One ship datapack, namespace `elysium`.
- Adventure mode is the intended play mode once canon areas exist.
- No gameplay mod, plugin, or loader in the thing a player runs. Carpet, Paper, Fabric, Forge, NeoForge, and Spigot stay out of the ship artifact and out of the M0 test path. Paper may later be a second host. It is never the oracle.

## Originality

Agents do not import another map's world, schematic, quest text, scoring script, or distinctive set piece. Vanilla block and item ids are available. Textures and sounds stay inside the game jar and are not copied into git. F-0001 is original work of small scope written for this project. It is not, by itself, an original map, and documents must not describe it as one.

Sibling research in the project store is pattern research, not a content bible. Language, objective count, and region count are class S. M0 does not build that framing and does not treat it as accepted.

## Success

The project succeeds when the owner approves a release whose packet keeps the evidence labels straight: automated correctness, simulated player analysis, and human playtesting. Owner acceptance does not convert an unverified creative claim into a playtest.

## Non-goals

- Cloning an existing map.
- An always-on public server.
- Agent-certified fun, fairness, beauty, or clarity.
- Requiring the owner to play, compile, or debug.
- Shipping a gameplay mod.
- Treating F-0001 as the monument or as a finished puzzle.
