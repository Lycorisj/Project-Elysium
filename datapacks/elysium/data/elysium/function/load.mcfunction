# F-0001 Ledger Cairn. Non-canon plumbing. No setting, character, or victory fiction.
# Commands in this file are unverified until a dedicated-server boot accepts them.
# This change did not boot a server. D-0001 is proposed.

function elysium:ledger/init
data modify storage elysium:slice clock.loop set value 0b
schedule clear elysium:ledger/cadence
