# D-0004 Keep the three evidence labels separate

- class: T
- status: accepted
- date: 2026-11-08
- decider: merging coordinator
- context: An agent sentence that a build is fun, fair, clear, beautiful, or finished is not evidence. Automated correctness, simulated player analysis, and human playtesting stay separate in every spec, pull request, milestone packet, and release. Agent taste is not proof. Owner acceptance is a fourth act and does not convert an unverified creative claim into a playtest.
- options:
  - A: Require the three labels on every change, and ban taste claims as evidence.
  - B: Let a green script or an agent's impression stand in for a playtest.
- recommendation: A.
- consequences: This change reports automated static pass only when `tools/static_validate.py` exits 0, `simulation: not_run`, and `human_playtest: none`. It does not report a dedicated-server pass. Commands not accepted by a boot stay unverified. A later server run needs its own manifest with the same labels. Two agents re-running a script is a real control and is still not CI. Documents say "re-run by a second agent" until an external runner exists.
- owner words:
