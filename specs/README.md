# Specifications

Creative direction 《折潮》 is accepted in D-0005. The setting is not yet built. F-0001 stays non-canon plumbing.

Every mechanic, area, and player-facing system has a spec under `specs/features/` before implementation. The M0 slice is the exception: its spec lands in the same pull request as its code because the production workflow is the source. After M0, a feature pull request that changes behavior without a spec change fails review.

## Frontmatter

```yaml
id: F-0001
title: Ledger Cairn
status: draft   # draft | accepted | implemented | superseded
class: technical-slice   # technical-slice | canon
canon: false
depends_on: []
regions: [slice-origin]
storage: ["elysium:slice ledger"]
functions: ["elysium:ledger/evaluate", "elysium:ledger/place_room"]
advancements: ["elysium:slice/ledger_cleared"]
```

`status: accepted` on a `canon: false` slice is a class T merge. `status: accepted` on `canon: true` requires a class S decision that is already accepted. `implemented` is set only in the pull request that merges the code and the green reviewer manifest. `superseded` points at the replacement id.

F-0001 stays `draft` on this change. D-0003 accepts that the slice is non-canon plumbing. The feature spec is not `implemented`: no dedicated-server run and no reviewer manifest exist. Unverified commands are not promoted by a static pass.

## Body

A spec has these headings:

- Player-visible behavior.
- Non-goals.
- Normative mechanics.
- Failure and edge cases.
- Automated checks.
- Simulation checks, or "not run".
- Human questions, which stay unanswered until a human writes an answer.
- Evidence required.

The spec is the contract the test cases encode. If the server makes the contract impossible, amend the spec in the same pull request and record a class T decision. Do not leave the spec describing behavior the tests no longer check.

## Registry

`specs/REGISTRY.md` is the live index of storage roots, function ids, advancement ids, entity tags, scoreboard objectives, and inclusive region bounds. A feature pull request edits the registry in the same diff that introduces a name. A collision on rebase is a failed merge until one side renames or the coordinator serializes the edit.
