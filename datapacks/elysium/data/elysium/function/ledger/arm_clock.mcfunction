# F-0001. Unverified until boot.
# schedule is the 20-tick delay. The first evaluate is one cadence later, then every 20 ticks.

data modify storage elysium:slice clock.loop set value 1b
schedule function elysium:ledger/cadence 20t replace
