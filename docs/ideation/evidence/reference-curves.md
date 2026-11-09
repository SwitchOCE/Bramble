# Reference curves: board stats by turn (9 Nov 2026)

Board stats = Attack + Health summed over every unit on the board. Turn = combat number = Bramble round. Columns A to E are the sources below.

| Turn | A. BG Sep 2025 mean | B. BG Nov 2026 mean | C. BG Nov 2026 median | C. p90 | C. boards at 2x median or more | C. biggest unit, median | C. biggest unit's share, median | D. BG top 0.4% games, median / p90 | E. Bramble bots median | E. p90 | E. boards at 2x median or more | E. Bramble lobby winners, median |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 4 | 24 | 27 | 24 | 40 | 6% | 10 | 47% | 34 / 51 | 30 | 36 | 0% | 31 |
| 5 | 36 | 44 | 36 | 58 | 2% | 14 | 41% | 52 / 81 | 42 | 51 | 0% | 44 |
| 6 | 53 | 74 | 62 | 85 | 1% | 22 | 35% | 84 / 143 | 52 | 63 | 0% | 56 |
| 7 | 79 | 127 | 106 | 172 | 3% | 36 | 32% | 146 / 286 | 64 | 80 | 0% | 71 |
| 8 | 123 | 230 | 149 | 343 | 13% | 54 | 33% | 269 / 535 | 80 | 98 | 0% | 89 |
| 9 | 194 | 490 | 380 | 929 | 14% | 139 | 34% | 604 / 1,461 | 92 | 113 | 0% | 105 |
| 10 | 305 | 1,008 | 714 | 1,565 | 14% | 240 | 32% | 1,415 / 4,682 | 107 | 132 | 0% | 121 |
| 11 | 482 | 1,994 | 1,212 | 3,278 | 16% | 438 | 34% | 3,390 / 13,473 | 121 | 148 | 0% | 136 |
| 12 | 759 | 3,505 | 2,598 | 6,572 | 23% | 897 | 34% | 7,598 / 29,844 | 133 | 163 | 0% | 149 |
| 13 | 1,177 | 5,243 | 4,993 | 18,022 | 24% | 1,828 | 34% | 12,376 / 66,174 | 145 | 178 | 0% | 162 |
| 14 | 1,751 | 6,850 | 7,980 | 31,933 | 23% | 2,857 | 35% | 21,440 / 141,333 | 155 | 194 | 0% | 172 |
| Growth a turn, 8 to 14 | x1.56 | x1.76 | x1.94 | | | | | x2.07 (median) | x1.12 | | | x1.12 |

## Sources and limits

- **A. September 2025: means only.** Firestone's public hero-stats file, the Wayback copy of 8 Sep 2025 (1,782,847 games, all ratings). It gives each hero's mean board per turn; I weighted heroes by game count, since per-turn counts aren't published. No median, spread, biggest unit or share exists for this era. It counts players still alive, so late turns lean to survivors. Board measured as sent to combat.
- **B. November 2026 mean.** The same file for the current patch (288,790 games, to 8 Nov). Compare this column, not C, with A: both are means.
- **C. November 2026 spread and carry: replays from one kind of game.** 129 parsed replays of "perfect games" (1st place without losing hero health, about 0.36% of games), patch 37.0, 3-9 Nov 2026. Ordinary boards are the winners' opponents at each turn, ghosts dropped: 106-127 boards a turn to turn 12, 100 at 13, 60 at 14 (survivors only, so 13-14 lean high). Snapshot at the first attack, after Start of Combat. Biggest unit and its share are separate medians across boards; turn 4-5 boards hold only 3-4 units, so their share runs high. Check: at turn 12 the replay mean (3,522) matches Firestone's (3,505).
- **D. The tail.** The perfect-game winners themselves (70-129 a turn). It is the only tail data; there is no separate top-1% cut.
- **E. Bramble bots.** 400 complete 8-seat lobbies on the pass 2 follow-up build (`free_choice_plain`). The board is the recruit board after each round's fights: printed, permanent and tribe stats, with no auras, Rings, Eggs, held bodies or fight-only buffs, so it reads lower than C's snapshot. Boards fall from 3,200 to 1,874 by round 14 as players die. Winners are each lobby's eventual 1st (12.5% of seats), not a top-0.4% cut. Bots play below human level, never save and never buy answers. The biggest unit isn't logged; the card audits estimate a typical biggest unit at 10-19 stats at round 8 and 17-33 at round 12 (13-25% of the board, against 14% for an even board).

## What it shows

- Bramble is level with Battlegrounds to turn 6 (to turn 7 against September 2025). From turn 8 Battlegrounds compounds and Bramble adds about +13 a round. At turn 12 the Nov 2026 median is 20 times ours and the September 2025 mean about 6 times.
- The target era, September 2025, has a turn-12 mean of 759: about 108 a unit, or 54/54. Its median and spread are unmeasured. If it had Nov 2026's median-to-mean ratio (0.74), its turn-12 median was about 560. Its spread may have been narrower, since its curve was flatter.
- Battlegrounds' tail opens at turn 8: from then on 13-24% of ordinary boards sit at twice the median, and from turn 10 the top tenth of the top 0.4% reach 7-18 times it. No Bramble board ever reached twice the median.
- Battlegrounds keeps about a third of the board in one unit from turn 6 on: one carry plus six supports.
- Skill: top-1%-rating players average 1.8 times the all-player mean at turns 10-12 (Firestone, Nov 2026). Bots understate any curve.

Files: `fundamentals-audit/stat-scale-bg-galaxy.md`, `perfect_combats_table.txt`, `shape.txt`, `bramble_rounds.txt`, `chart_stat_curve.json`, card audits for the Bramble biggest-unit estimates. Raw Firestone files: `build/orchestrator/fundamentals/web/` (not committed).
