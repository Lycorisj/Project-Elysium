# Map source

Creative direction 《折潮》 is accepted in D-0005. The setting is not yet built. There is no map yet. F-0001 stays non-canon plumbing.

The M0 world artifact is the function `elysium:ledger/place_room`, not a region file. It builds the non-canon slice inside the reserved region `slice-origin`: x from -6 to 6, y from 99 to 104, z from -6 to 6, inclusive. The chest is at `(0, 100, 0)`, the marker is at `(0, 100, 2)`, and one witness armor stand is at `(0, 100, -2)`.

`place_room` is deterministic. Running it twice still leaves one chest, one tuff marker, and one witness. It does not reset a ledger that already exists. The behavior is specified in `specs/features/F-0001-ledger-cairn.md`. The commands are unverified until a dedicated server accepts them. No server was launched for this change.

Region files are build output. They are not source. A future binary world needs its own class T decision before any `*.mca` is force-added. Git LFS is not part of M0. Do not commit a generated world to satisfy the pipeline.

F-0001 is non-canon plumbing. It is not the monument.
