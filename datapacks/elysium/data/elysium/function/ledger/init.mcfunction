# F-0001. Unverified until boot.
# Creates the ledger document only when the key is missing. Does not reset an existing ledger.

execute unless data storage elysium:slice ledger run data modify storage elysium:slice ledger set value {done:0,awards:0,rejects:0}
execute unless data storage elysium:slice seen.items run data modify storage elysium:slice seen.items set value []
execute unless data storage elysium:slice clock run data modify storage elysium:slice clock set value {loop:0b}
