# F-0001 Ledger Cairn. The map artifact for slice-origin. Non-canon plumbing.
# Commands are unverified until a dedicated-server boot accepts them.
# Second call keeps an existing ledger and still leaves exactly one witness.

forceload add -6 -6 6 6
fill -6 100 -6 6 104 6 minecraft:air
fill -6 99 -6 6 99 6 minecraft:deepslate_tiles
# A second call in the same tick cannot see the armor stand summoned by the first.
# gametime storage changes only on a new tick, so the summon runs once per tick.
execute store result storage elysium:slice tmp.now_tick int 1 run time query gametime
execute store success storage elysium:slice tmp.new_tick byte 1 run data modify storage elysium:slice witness.tick set from storage elysium:slice tmp.now_tick
execute if data storage elysium:slice tmp{new_tick:1b} run kill @e[type=minecraft:armor_stand,tag=elysium.witness]
execute if data storage elysium:slice tmp{new_tick:1b} run summon minecraft:armor_stand 0 100 -2 {Tags:["elysium.witness"],Marker:1b,Invisible:1b,NoGravity:1b,Silent:1b,Invulnerable:1b}
setblock 0 100 0 minecraft:chest
setblock 0 100 2 minecraft:tuff
function elysium:ledger/init
