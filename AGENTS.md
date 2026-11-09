# Agent rules

Agents build, program, test, and debug inside an accepted spec. They do not invent creative canon, and they do not declare a build fun, fair, clear, beautiful, or finished.

Creative direction 《折潮》 is accepted in D-0005. The setting is not yet built. F-0001 stays non-canon plumbing. Git is the authority for what ships after these documents merge. If `internal/production-workflow.md` in the project store disagrees with git, git wins.

## Read order

Read these before editing the game:

1. `AGENTS.md`
2. `PROJECT_CHARTER.md`
3. `VISION.md`
4. `QUALITY_STANDARDS.md`
5. `TESTING_STRATEGY.md`
6. The feature spec
7. `specs/REGISTRY.md`
8. Every decision the spec cites

## Decisions

Class S belongs to the Project Owner: setting, tone, difficulty philosophy, what the monument is, how many pieces it has, victory and failure fiction, scope cuts, license, whether the shipped game may require a mod, opening a playtest that distributes the map, accepting a milestone, approving a release, and accepting the Minecraft EULA for dedicated-server runs.

Class T belongs to agents and is accepted when the pull request merges: file layout inside the workflow, the test runner's language, registry names for an accepted feature, a non-canon slice's block ids when an id is missing from the pinned version, an allowlist line for a benign log line, and the exact command syntax the pinned server accepts.

When unsure, treat the decision as class S and stop that task. Write one proposal. Do not guess the owner's answer.

D-0001 stays `proposed` until a commit quotes the owner's words and names the option. Do not download the server jar, write `eula=true`, or launch a server while it is proposed. D-0001 is accepted. The quoted words are in `decisions/D-0001-minecraft-eula.md`. That acceptance authorizes `eula=true` for local and automated test servers only.

## Honesty

Every change states `automated`, `simulation`, and `human_playtest`.

- `simulation: not_run` until a bot run exists.
- `human_playtest: none` until a human note exists. The note is filed verbatim.
- A static validator exit of 0 is `automated: pass` for files only. It is not a dedicated-server pass.
- Commands the server has not accepted stay marked unverified. Do not report them as a runtime pass.
- A skipped case is not a pass. A fail followed by a pass is not stable. Two clean runs on wiped `run/` directories, then a different agent's re-run, are the server bar.
- Do not say the map is fun, boring, fair, unfair, scary, funny, beautiful, clear, confusing, or complete.
- Do not say "I played it," "a player would," "playtesters will," or "this feels better."
- Do not describe a generated image as a frame from the game.
- Do not paraphrase a log without the redacted output.
- Do not call a simulation playtested.

Allowed statements restate a tool result, including a result that did not run.

## Allow-path

Edit only the paths the brief names. M0's allow-path is the repository layout in the production workflow plus `.gitignore`. The deny-path is the server jar, `run/`, `dist/`, secrets, imported maps, and the store copy of the workflow.

Shared files are serial. One agent at a time edits the load tag, the tick tag, `specs/REGISTRY.md`, `VISION.md`, `PROJECT_CHARTER.md`, an accepted class S decision, or the release packer invocation.

The ship datapack must not reference `elysium_test`.

## Evidence

A pull request includes the spec id, the commands and exit codes, the manifest path when one exists, `human_playtest: none` and `simulation: not_run` unless a real artifact exists, the unverified list, and a confirmation that the diff has no jar, world, `eula.txt`, or secret.

M0's definition of done is the checklist in the production workflow, section 19. A stop at the EULA gate is a completed escalation, not a completed M0.

## Git, store, tracker

Merged git says what ships, what the code does, and what canon is accepted. The project tracker says who is assigned and which task is blocked. Workers do not move tracker tasks. The project store holds the process spec, large logs, and owner-question drafts. Scratch in the store is not canon.

## Branches and pull requests

Use the `cursor/` branch name the run requires. One concern per branch. Commit subjects name the spec id. The coordinator merges. Routine contributors are agents. Contributing does not mean asking the owner to try the build.

## Escalation

On a class S question, stop the task and write one owner-inbox entry:

```markdown
## YYYY-MM-DD — D-0001
Blocking: server launch
Question: one paragraph
Options: A, B
Recommendation: one line
Reply needed: accept A, accept B, or reject
```

Do not ask the owner to compile, run Java, read a stack trace, resolve a git conflict, pick a pack format, or playtest. Do not send a second copy of the same question inside a bug report.

## Recovery

A task is reassigned at most twice. After that the coordinator splits the brief. A class S block is not a reassignment. Environment failures stay on the same branch. Do not weaken a test to make a suite green. Do not blend two mechanics into one function to hide a registry conflict. An escaped defect is reverted on the default branch; a postmortem does not by itself change the tests.

## M0 server gate

While D-0001 is `proposed`, `tools/run_tests.sh` must refuse to launch. D-0001 is accepted, so the runner may download the pinned jar and launch a local test server. `eula=true` is written only inside `run/`. Reply patterns stay unlocked until a boot records them. A static pass is not a runtime pass.
