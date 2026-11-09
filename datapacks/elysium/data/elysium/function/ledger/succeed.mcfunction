# F-0001. Unverified until boot.
# done 1, awards +1, marker prismarine. Advancement only if a player exists.
# The compute increment is the 26.3 storage provider. It was not executed.

data modify storage elysium:slice ledger.done set value 1
data modify storage elysium:slice ledger.awards set compute default integer {type:"minecraft:add",inputs:[{type:"minecraft:storage",storage:"elysium:slice",path:"ledger.awards"},{type:"minecraft:constant",value:1}]}
setblock 0 100 2 minecraft:prismarine
execute if entity @a[limit=1] run advancement grant @a only elysium:slice/ledger_cleared
data modify storage elysium:slice seen.items set from storage elysium:slice tmp.now
