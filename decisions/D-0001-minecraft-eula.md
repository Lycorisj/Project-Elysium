# D-0001 Accept the Minecraft EULA for dedicated-server runs

- class: S
- status: accepted
- date: 2026-11-09
- decider: Project Owner
- context: Running Mojang's dedicated server requires accepting the Minecraft EULA (https://www.minecraft.net/eula). The automated oracle for this project is that server. The decision was proposed on 2026-11-08. On 2026-11-09 the Project Owner answered in writing and named option A. The words below are quoted exactly.
- options:
  - A: Accept the Minecraft EULA for local and CI dedicated-server test runs.
  - B: Do not accept the EULA. Do not download the server jar and do not launch the dedicated server.
- recommendation: Accept A. The test loop needs the vanilla server.
- consequences: Option A is accepted. `eula=true` is authorized for local and automated test servers only, and only inside `run/`. It does not authorize a public server. `tools/run_tests.sh` may download the pinned jar and launch the vanilla dedicated server after this acceptance is in a commit. The jar is still not committed. No license for the game is granted by this repository.
- owner words: 「接受 EULA，可以跑专用服测试」
