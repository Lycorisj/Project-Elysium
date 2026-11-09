# F-0001 test helper. Not shipped.
# Restores the ledger document and the marker. Does not move the room.
# Clears the edge-trigger fingerprint so the next chest change can count once.
# Ensures one witness at the room point when none is there. A 26.3 run showed
# clock_stable stays at rejects 0 if witness_missing has removed the witness.

data modify storage elysium:slice ledger set value {done:0,awards:0,rejects:0}
data modify storage elysium:slice seen.items set value []
data remove storage elysium:slice tmp
setblock 0 100 2 minecraft:tuff
execute unless entity @e[type=minecraft:armor_stand,tag=elysium.witness,x=0,y=100,z=-2,distance=..1] run summon minecraft:armor_stand 0 100 -2 {Tags:["elysium.witness"],Marker:1b,Invisible:1b,NoGravity:1b,Silent:1b,Invulnerable:1b}
