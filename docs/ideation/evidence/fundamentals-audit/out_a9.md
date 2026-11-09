## Model check: replay each player's real results through the Health model

Predicted death = first round modelled Health <= 0 (places 5-8: no Last Stand; places 2-4: one save allowed once 4 or fewer are alive, which we approximate as rounds after the 5th-place exit).

| place | players | predicted round exact | within 1 | mean error (pred-actual) | model says still alive at end |
|---:|---:|---:|---:|---:|---:|
| 1 | 400 | 0% | 20% | -3.86 | 356 |
| 2 | 400 | 77% | 90% | -0.52 | 12 |
| 3 | 400 | 77% | 86% | -0.49 | 25 |
| 4 | 400 | 75% | 88% | -0.46 | 15 |
| 5 | 400 | 85% | 94% | -0.23 | 29 |
| 6 | 400 | 83% | 95% | -0.21 | 33 |
| 7 | 400 | 88% | 99% | -0.14 | 47 |
| 8 | 400 | 89% | 99% | -0.12 | 124 |
