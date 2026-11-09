# F-0001. Unverified until boot. Arms a 20-tick cadence. Does not call evaluate every tick.
# A clock that calls evaluate every tick and increments rejects every call is a defect.

execute unless data storage elysium:slice clock{loop:1b} run function elysium:ledger/arm_clock
