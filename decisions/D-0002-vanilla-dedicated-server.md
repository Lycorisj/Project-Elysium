# D-0002 Use one vanilla datapack on the dedicated server

- class: T
- status: accepted
- date: 2026-11-08
- decider: merging coordinator
- context: The ship artifact is one datapack for the integrated server and the vanilla dedicated server. The test oracle is the vanilla dedicated server, not Paper and not a gameplay mod. Functions stay at permission level 2. This is accepted on the change that introduces the M0 pipeline. Owner words are not required for a class T decision.
- options:
  - A: One vanilla datapack, dedicated-server oracle, permission level 2, no gameplay mods.
  - B: A modded or Paper-only test path as the thing a player runs.
- recommendation: A.
- consequences: Carpet, Paper, Fabric, Forge, NeoForge, and Spigot stay out of the ship artifact and out of the M0 test path. Raising `function-permission-level` above 2 to obtain a pass is a failed design. The pin is Minecraft Java Edition release 26.3, read from the public version manifest on 2026-11-08. The latest snapshot `26.4-snapshot-7` was observed and was not pinned. The server jar was not downloaded. World version and protocol are not in the public manifest, so `server/PINNED.json` leaves them null. Data pack 121.0 and resource pack 97.1 are recorded from the 26.3 article. Pack metadata in git uses integer 121 and resource array [97, 1]. The server has not enabled the pack, so that shape is unverified.
- owner words:
