# Contributing

No creative direction is accepted yet. No creative canon is accepted.

Routine contributors are agents. "Contribute" does not mean "ask the owner to try the build." The owner is not the default tester, compiler, or debugger.

## Branches

Use a `cursor/` branch with the suffix the run instructions require. One concern per branch. M0 is serial: one implementer, then one reviewer, then the coordinator merges. Do not fan M0 out across features.

Shared files are edited by one agent at a time: the load tag, the tick tag, `specs/REGISTRY.md`, `VISION.md`, `PROJECT_CHARTER.md`, an accepted class S decision, and the release packer invocation.

## Commits

Commit subjects name the spec id, for example `F-0001: add the non-canon ledger slice`. The subject says what changed. It does not claim a playtest or a runtime pass the commands have not earned.

## Pull requests

The body includes:

- Spec id and task id.
- What changed.
- Commands and exit codes.
- The author manifest path, or a statement that no runtime manifest exists.
- `human_playtest: none` and `simulation: not_run`, unless a real artifact exists.
- The unverified list.
- Confirmation that the server jar, `run/`, and secrets are not in the diff.
- The EULA state. If D-0001 is proposed, say that no server was launched.

A pull request that changes behavior also changes the feature spec. After M0, spec first: a feature pull request that changes behavior without a spec change fails review. The M0 slice lands its spec in the same pull request because the production workflow is the source.

## Review

A different agent, or the coordinator, checks out the SHA, confirms a clean tree, and re-runs the suite that the change actually claims. For a static-only stop, the re-run is `tools/static_validate.py`. A server re-run waits until D-0001 is accepted. The reviewer writes a reviewer manifest and does not push fixes onto the author's branch. The reviewer does not add a play impression.

The author does not supply the reviewer manifest. The coordinator does not treat the author's manifest as the review. If nobody re-runs, the change is not done.

## Merge

The coordinator merges, one pull request at a time, only after the reviewer manifest records the same SHA, a clean tree, and exit code 0, and the diff stays inside the allow-path. The coordinator then moves the tracker. A worker's statement that a task is done does not move the tracker.

Auto-merge is not in use.

## Owner boundary

Class S proposals stop in a decision file. D-0001 is the open M0 question. Do not download the jar or launch the server to "see if the owner would mind." Do not invent the owner's answer so the inbox can be marked clear.
