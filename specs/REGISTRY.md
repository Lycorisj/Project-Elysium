# Registry

Creative direction 《折潮》 is accepted in D-0005. The setting is not yet built. Claiming a row is part of the feature diff. M0 has one non-canon region, `slice-origin`. Scoreboard objectives are none: storage is the state channel. No direction regions are reserved here.

## Storage roots

| Storage | Path | Spec | State |
| --- | --- | --- | --- |
| elysium:slice | ledger | F-0001 | implemented |
| elysium:slice | seen.items | F-0001 | implemented |
| elysium:slice | clock | F-0001 | implemented |
| elysium:slice | tmp.now | F-0001 | implemented |
| elysium:slice | tmp.n | F-0001 | implemented |
| elysium:slice | tmp.witnesses | F-0001 | implemented |
| elysium:slice | tmp.changed | F-0001 | implemented |

`ledger` is the document `{done, awards, rejects}`. `seen.items` is the edge-trigger copy. `clock` arms the 20-tick cadence. `tmp.*` is scratch for one evaluate.

## Functions

| Id | Spec | State |
| --- | --- | --- |
| elysium:load | F-0001 | implemented |
| elysium:tick | F-0001 | implemented |
| elysium:ledger/init | F-0001 | implemented |
| elysium:ledger/arm_clock | F-0001 | implemented |
| elysium:ledger/cadence | F-0001 | implemented |
| elysium:ledger/place_room | F-0001 | implemented |
| elysium:ledger/evaluate | F-0001 | implemented |
| elysium:ledger/fail_precondition | F-0001 | implemented |
| elysium:ledger/succeed | F-0001 | implemented |
| elysium_test:reset | F-0001 | implemented |

## Advancements

| Id | Spec | State |
| --- | --- | --- |
| elysium:slice/ledger_cleared | F-0001 | implemented |

## Entity tags

| Tag | Spec | State |
| --- | --- | --- |
| elysium.witness | F-0001 | implemented |

## Scoreboard objectives

None.

## Regions

Inclusive block bounds. Placements outside a reserved region fail review. Overlapping reservations fail review.

| Id | x0 | y0 | z0 | x1 | y1 | z1 | Spec | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| slice-origin | -6 | 99 | -6 | 6 | 104 | 6 | F-0001 | implemented |
