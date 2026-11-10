# Frozen H1 measurement checkpoints

Each arm is archived only after its complete predeclared sample. The root plan
is `../quilboar-h1-plan.json`; all reference/core/policy source hashes are pinned
there. This is separate from the four excluded smoke seeds.

Rebuild a completed arm's archive and three-round accounting checkpoint with:

```sh
python3 tools/sim/evidence/drivers/checkpoint_quilboar_h1.py B
```

`receipt.json` contains the compact/capture hashes and measured scope time;
`accounting-checkpoint.json` contains whole-seed bootstrap intervals, body/tier
context, and Hogrider acquisition by R12. Final H1 metrics are rebuilt from all
four arms by `tools/sim/quilboar_h1.py report`.

At the B checkpoint, R9/R12/R15 real/paper ratios are 0.461/0.240/0.573. No
lessons about the native tribes should be read from this unqualified reference.
One policy difference is being clarified with the orchestrator: this frozen
implementation counts both Created and shop-bought cycled units toward the
four-unit budget; the paper applies its shop-cycle budget separately from
Created Tunneler cards. Sources are unchanged while that call is pending.
Roadboar is absent until Phase 2, another stated early accounting limitation.
