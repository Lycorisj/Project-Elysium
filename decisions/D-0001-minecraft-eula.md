# D-0001 Accept the Minecraft EULA for dedicated-server runs

- class: S
- status: proposed
- date: 2026-11-08
- decider: Project Owner
- context: Running Mojang's dedicated server requires accepting the Minecraft EULA (https://www.minecraft.net/eula). The automated oracle for this project is that server. Repository text, the datapack, and the static validator do not need the server. Launching it does. This file does not record an owner answer.
- options:
  - A: Accept the Minecraft EULA for local and CI dedicated-server test runs.
  - B: Do not accept the EULA. Do not download the server jar and do not launch the dedicated server.
- recommendation: Accept A. The test loop needs the vanilla server. This recommendation is not an acceptance.
- consequences: While this status is proposed, agents do not download the server jar, do not write eula=true, and do not launch a server. Static validation can still be green. Accepting A later unblocks `tools/run_tests.sh`. Rejecting or accepting B leaves the project on static checks only. No license for the game is granted by this repository.
- owner words:
