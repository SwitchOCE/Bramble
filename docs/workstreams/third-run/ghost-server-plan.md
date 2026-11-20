# Ghost server plan

The local folder store and matchmaker serve the game during development. Server work is for a later step. The owner said, “I don't want the networking wired up yet” and “And we just have other interfaces in that we used during development up until we go for a server architecture.” [Ghost plan](ghost-plan.md)

## What the server keeps and checks

Keep the exact run file bytes under their SHA-256 id and the source game record under its own hash. Index the rules hash, patch, card fingerprints, source and player or bot, available strength metadata, placement, last turn and date. Keep runs referenced by saved records available for replay even after they leave matchmaking.

Replay each submitted run's finished source record with the matching engine rules and card data. For async records, load the recorded opponent ids and check each file's hash before replay. Check action results, fight boards and state hashes through the end of the game. Cut the submitted seat's run from the verified record and check that it matches the submission before making it available for matchmaking.

## From local interfaces to server calls

| Interface | On the server |
|---|---|
| `GhostStore.add` | Upload the run and its record. Verify by replay and return the run id on acceptance. |
| `GhostStore.fetch` | Download the exact run bytes by id. The reader checks their SHA-256 before using them. |
| `GhostStore.find` | Query the server's run index by rules hash, source, label, placement and excluded ids. Return matching run summaries. |
| `LocalMatchmaker.pick` | Pick seven distinct runs on the server from the matching rules and strength band, excluding runs already seen in the session. Return the ids in seat order. |

## Game and replay

GDScript and Rust keep the same run and record formats. The game plays the chosen runs under the same async rules, and its record names the run id at each seat so replay can use the same opponents. The live game's cross-patch policy is still open. [Recorded runs across patches](ghost-patches-long-term.md)
