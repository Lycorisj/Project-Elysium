# F-0001. Unverified until boot. Normative behavior, not a runtime transcript.
# If done is 1, return without changing awards, rejects, the marker, or the chest.
# Missing chest Items is normalized to an empty list before the edge-trigger compare.
# data modify success is the change detector: an unchanged copy fails and does not add a reject.
# The add-by-compute line was not executed. Do not treat it as a server-accepted command.

function elysium:ledger/init
execute if data storage elysium:slice ledger{done:1} run return 0

execute unless block 0 100 0 minecraft:chest run return run function elysium:ledger/fail_precondition
execute store result storage elysium:slice tmp.witnesses int 1 if entity @e[type=minecraft:armor_stand,tag=elysium.witness,x=0,y=100,z=0,distance=..3]
execute unless data storage elysium:slice tmp{witnesses:1} run return run function elysium:ledger/fail_precondition

data remove storage elysium:slice tmp.now
data modify storage elysium:slice tmp.now set value []
execute if data block 0 100 0 Items run data modify storage elysium:slice tmp.now set from block 0 100 0 Items
execute store result storage elysium:slice tmp.n int 1 if data storage elysium:slice tmp.now[]

execute if data storage elysium:slice tmp{n:2} if data block 0 100 0 {Items:[{Slot:0b,id:"minecraft:amethyst_shard",count:1}]} if data block 0 100 0 {Items:[{Slot:1b,id:"minecraft:echo_shard",count:1}]} run return run function elysium:ledger/succeed

data modify storage elysium:slice ledger.done set value 0
setblock 0 100 2 minecraft:tuff
execute store success storage elysium:slice tmp.changed byte 1 run data modify storage elysium:slice seen.items set from storage elysium:slice tmp.now
execute if data storage elysium:slice tmp{changed:1b} run data modify storage elysium:slice ledger.rejects set compute default integer {type:"minecraft:add",inputs:[{type:"minecraft:storage",storage:"elysium:slice",path:"ledger.rejects"},{type:"minecraft:constant",value:1}]}
