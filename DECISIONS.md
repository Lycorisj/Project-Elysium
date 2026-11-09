# Decisions

Creative direction 《折潮》 is accepted in D-0005. The setting is not yet built. F-0001 stays non-canon plumbing.

One file per decision lives in `decisions/` and is indexed here. Status values are `proposed`, `accepted`, `rejected`, and `superseded`.

Class S stays `proposed` until a commit quotes the owner's words and names the option. The agent who records the quote is the agent who received the words. A worker who did not receive the words does not flip the status.

Class T may be `accepted` in the change that introduces it. The decider is the merging coordinator. `owner words` stays empty.

`superseded` names the replacement id and does not delete the old file.

Template:

```markdown
# D-0001 Title
- class: S
- status: proposed
- date: YYYY-MM-DD
- decider: Project Owner
- context:
- options:
  - A: ...
  - B: ...
- recommendation:
- consequences:
- owner words:
```

## Index

| Id | Class | Status | File |
| --- | --- | --- | --- |
| D-0001 | S | proposed | `decisions/D-0001-minecraft-eula.md` |
| D-0002 | T | accepted | `decisions/D-0002-vanilla-dedicated-server.md` |
| D-0003 | T | accepted | `decisions/D-0003-noncanon-first-slice.md` |
| D-0004 | T | accepted | `decisions/D-0004-evidence-classes.md` |
| D-0005 | S | accepted | `decisions/D-0005-folded-tide.md` |

D-0001 is accepted. Owner words are in that file and are not paraphrased here. Acceptance authorizes `eula=true` for local and automated test servers only. D-0005 accepts the creative direction and does not build its setting.
