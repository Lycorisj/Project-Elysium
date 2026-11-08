# F-0001 Ledger Cairn. The map artifact for slice-origin. Non-canon plumbing.
# Commands are unverified until a dedicated-server boot accepts them.
# Second call keeps an existing ledger and still leaves exactly one witness.

forceload add -6 -6 6 6
fill -6 100 -6 6 104 6 minecraft:air
fill -6 99 -6 6 99 6 minecraft:deepslate_tiles
kill @e[type=minecraft:armor_stand,tag=elysium.witness]
summon minecraft:armor_stand 0 100 -2 {Tags:["elysium.witness"],Marker:1b,Invisible:1b,NoGravity:1b,Silent:1b,Invulnerable:1b}
setblock 0 100 0 minecraft:chest
setblock 0 100 2 minecraft:tuff
function elysium:ledger/init
