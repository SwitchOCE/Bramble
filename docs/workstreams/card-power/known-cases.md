# Known cases: the owner's calls, used to test the measures

A measure or a process change is run against this list, the way code is run against tests. The calls are the owner's judgement, not facts; where the data disagrees, both are shown.

## Firm calls (owner, 24–25 Nov 2026)

| Card | The owner's call | In the owner's words |
|---|---|---|
| Sword-heir (T3, Badger) | Overpowered | "I knew that both were completely overpowered. Within two seconds of seeing them." "I don't think the question about whether [Sword-heir] is overpowered is really up for debate." |
| Old Brock (T6, Badger) | Overpowered | as above |
| Brock Cub (T1, Badger) | Scales too well for a tier 1 | "It's a tier one unit that scales a bit too well." |
| Overrun (keyword) | Too good into low-Health boards | "Any low health board, Badgers will just clean up with no issues." |

## Gut calls (owner, 25 Nov 2026)

The owner: "A lot of those are far more gut reaction, I'm far less certain on ... They're much more borderline than the other true positives."

| Card | The owner's call |
|---|---|
| Skin-shedder (T4, Locust) | "pretty strong. I'm not sure about overpowered, but on the stronger side" |
| Padre (T3, Pigeon) | "has probably been over-nerfed ... on the weaker side" |
| Gleaner (T3, Locust) | "still probably on the strong side, but I'm not 100% sure" |
| Shrew Harrier (T3, no tribe) | "pretty bad. I don't really see what it does" |
| Wheat Raider (T2, Locust) | "probably one of the stronger tier twos in the game" |
| Colour Ensign (T5, Pigeon) | "probably not very good for a tier five" |
| The Eighth Plague (T5, Locust) | "probably pretty bad for a tier 5. It probably does a worse job than Gleaner, which is doing the same kind of role at tier 3" |
| Twice-shed Veteran (T5, Locust) | "pretty poor for a tier five" |
| Lone Hawthorn (T5, Briar) | "probably not that great [as a tier 5], but I could be wrong on that one" |
| Briar King (T6, Briar) | "pretty poor for a tier six" |
| Regimental Sergeant Major (T6, Pigeon) | "pretty strong" |

*[Editor note: dictated. "Adre" was heard for Padre, "True Harry" for Shrew Harrier, "Colour Onsign" for Colour Ensign and "twice a shared veteran" for Twice-shed Veteran.]*

## What the measures said on 25 Nov

Matches, each 2,000 games: `m1` on the league's climbing field (too weak, as it turned out), `r1` on a field made of the two best bots' games, the left-out matches paired with `r1`, and `r1-no-badger-locust` (every Badger and Locust unit left out of both bots' shops). The fight numbers below are from `r1`; `m1` ranks the cards alike (correlation 0.83 to 0.97 by stage).

| Card | Call | What the data says | Agrees? |
|---|---|---|---|
| Sword-heir | Overpowered | Marked by pick rate (blue buys it on 98% of offers) and by text at every stage (37, 27, 23, 15 fights in 100). Left out, red finishes 1.11 places worse and blue 1.53 | Yes |
| Old Brock | Overpowered | Text first of all cards from round 13 (20 fights in 100); blue buys him on every offer. Left out, blue finishes 0.07 worse: blue reaches tier 6 in 38% of games | Yes in a fight; small over whole games |
| Brock Cub | Scales too well | Marked for growth in rounds 1 to 8 (+1.8/+2.8 a turn). Left out alone, the bots lose nothing; with the other three Grudge cards, blue finishes 0.74 worse | Yes on growth; the strength is the Grudge cards together |
| Overrun | Too good into low-Health boards | Rounds 5 to 8: 14 fights in 100 against low-Health boards, 4 against high. From round 9: 7 against low, nothing measurable against high | Yes |
| Skin-shedder | Strong side | Text fourth or fifth of all cards from round 5; marked on `m1`, under the line on `r1`; red buys it on 55% of offers | Yes |
| Gleaner | Strong side; a tempo card | Text first, second and third of all cards in rounds 1 to 12, then eighth. Red holds it to the end and finishes 0.32 places better without it | Yes, and it falls off |
| Wheat Raider | A stronger tier 2 | Text fifth of all cards in rounds 1 to 4, ordinary from round 9 | Yes, early |
| Padre | Weak | Bought on 0% and 1% of offers even when the bots play Pigeons | Yes |
| Colour Ensign | Weak for tier 5 | Red buys it on 38% of offers when playing Pigeons but holds it on 9% of late boards; text ordinary | Yes |
| Twice-shed Veteran | Poor for tier 5 | Text ordinary; bought on 2% of offers | Yes |
| The Eighth Plague | Pretty bad; worse than Gleaner | On `r1` its text is ordinary (6 then 2 fights in 100; Gleaner 10 then 5). Red still buys it on 67% of offers. On `m1` it had read seventh of 63 | Yes on the card; red over-buys it |
| Shrew Harrier | Pretty bad | Never bought in 11,111 offers, by either bot, in either match | Yes |
| Lone Hawthorn | Not great | Bought on 0% and 1% of offers with the bots playing Briars | Yes |
| Briar King | Poor for tier 6 | Blue buys it on 11% of 63 offers | Leans yes; too few offers |
| Regimental Sergeant Major | Pretty strong | Blue buys it on 83% of 52 offers when playing Pigeons; its effect is outside fights | Leans yes; too few offers |

No call is contradicted. The two "leans" are tier 6 cards: red reaches tier 6 in 2% of its games and blue in 38%, so tier 6 is barely tested.

What the list has taught about the measures:
- Test on a strong field. The weak field over-read The Eighth Plague and made Overrun look four times as deadly (a board of three or more emptied 1 swing in 30, against 1 in 150).
- Left out of the shop overstates for a card a bot is built around: both bots finish better with two whole tribes gone (red 4.65, blue 5.57) than with only Sword-heir gone (4.97, 6.24).
- A card no bot buys is a finding. With two tribes gone, 16 cards of the other tribes are still bought on under 1 offer in 100, and red passes 8 Locust cards while playing Locusts.
