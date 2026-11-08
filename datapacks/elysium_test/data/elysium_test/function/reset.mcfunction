# F-0001 test helper. Not shipped. Unverified until boot.
# Restores the ledger document and the marker. Does not move the room.
# Clears the edge-trigger fingerprint so the next chest change can count once.

data modify storage elysium:slice ledger set value {done:0,awards:0,rejects:0}
data modify storage elysium:slice seen.items set value []
data remove storage elysium:slice tmp
setblock 0 100 2 minecraft:tuff
