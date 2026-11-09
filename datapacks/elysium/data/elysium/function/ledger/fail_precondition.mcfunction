# F-0001. Unverified until boot.
# Preconditions failed: done 0, marker tuff. Do not increment awards or rejects.

data modify storage elysium:slice ledger.done set value 0
setblock 0 100 2 minecraft:tuff
