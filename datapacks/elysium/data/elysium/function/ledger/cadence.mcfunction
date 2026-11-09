# F-0001. Unverified until boot.
# Re-arms itself for 20 ticks after evaluate so the edge-trigger is not a per-tick reject climb.

function elysium:ledger/evaluate
schedule function elysium:ledger/cadence 20t replace
