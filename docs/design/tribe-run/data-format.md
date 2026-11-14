# Tribe run: how designs, versions and reviews are stored

Every agent in the run except the designers reads and writes this format (designers write `v1.md` with the tested prompt and read nothing else), and the portal reads only this. It is fixed before the run starts so that the history of every design and every card can be shown later.
- `tools/tribe-run/validate.py` checks the files. Run it after every write. It also checks that v1's card names and texts are copied word for word from `v1.md`.
- `tools/tribe-run/decide.py --write` rebuilds each `design.json` from the files present and says what each design needs next.

## Folder

```
docs/design/tribe-run/run/
  run.json                         the run: routes, committee, rules, waves
  seeds/<seed>.json                one per seed
  seeds/<seed>.BRIEF.md            the designer brief for that seed (Parts A, B, C)
  designs/<seed>--<route>/
    design.json                    the index for one design: status and versions
    v1.md                          the design as the designer wrote it (the tested prompt's output)
    v1.json v2.json v3.json        each version, structured, with stable card ids; revisers write v2/v3 here directly
    reviews/v<n>--<member>.json    one per committee member per version
  rankings/seed--<seed>.json       the seed's designs compared
  rankings/overall.json            the run's best picks
```

IDs are lower-case kebab: seed `moss-oozes`, route `surgical`, design `moss-oozes--surgical`, member `combo`.

## Stable card ids (the key to the history)

Every unit, token, spell and trinket has a `uid` that never changes across versions, even when the card is renamed, retiered or rewritten. Units are `u01`–`u19` in v1, in tier order. Extras are `x01`… A card added in a later version takes the next free number (`u20`). A removed card keeps its uid in that version's `changes` and drops out of `units`, and its uid is never reused. This is what lets the portal show one card's story: "v1 → v2: 3/2 → 2/3; text changed; why: …".

## `run.json`

```json
{
  "run_id": "tribe-run-2026-11-14",
  "shape": {"1": 2, "2": 3, "3": 4, "4": 4, "5": 3, "6": 3},
  "min_versions": 1,
  "max_versions": 3,
  "portal_url": "the artifact link, kept so a resumed run republishes to the same page",
  "routes": [{"id": "surgical", "name": "Surgical", "tested": true, "block": "text of the route block"}],
  "committee": [{"id": "combo", "name": "The combo player", "lens": "one line"}],
  "criteria": [{"id": "fun", "name": "Fun to draft and grow"}, {"id": "distinct", "name": "Distinctive"}],
  "waves": [{"id": 1, "seeds": ["moss-oozes"], "status": "planned|running|done"}]
}
```

## `seeds/<seed>.json`

```json
{"id": "moss-oozes", "name": "Moss Oozes", "source": "folio|new", "folio_ref": "seed title in the folio or null",
 "pitch": "one line: the play it suggests", "routes": ["surgical", "bottom-up-mech", "player-story"]}
```

## `designs/<id>/design.json`

```json
{
  "id": "moss-oozes--surgical", "seed": "moss-oozes", "route": "surgical",
  "tribe_name": "the name the designer gave it",
  "status": "drafting|reviewing|revising|settled|capped|failed",
  "final_version": 2,
  "stop_reason": "one line: why it stopped here",
  "versions": [
    {"v": 1, "author": "designer|reviser",
     "summary": "two lines: the tribe in short (v1) or what changed and why (v2+)",
     "reviews": ["v1--combo", "v1--climber", "v1--reader"],
     "ratings": {"fun": 7.3, "distinct": 8.0},
     "votes": {"settle": 1, "iterate": 2}}
  ]
}
```

`decide.py` writes `versions`, `ratings`, `votes`, `status`, `final_version` and `stop_reason`; agents write only `summary`. `ratings` is the mean of that version's reviews. `status` is `settled` when the committee voted it in a good spot (never before `min_versions`), and `capped` when it reached `max_versions`. A design whose units don't match `shape` is still valid: the validator warns and the portal shows its shape.

## `designs/<id>/v<n>.json`

```json
{
  "design_id": "moss-oozes--surgical", "v": 2,
  "identity": {"tribe_name": "", "mechanic": "the core mechanic in a few lines",
               "keywords": [{"name": "", "text": ""}], "plays": "the paragraph on how it plays"},
  "units": [{"uid": "u01", "name": "", "tier": 1, "attack": 2, "health": 3,
             "text": "", "golden": ""}],
  "extras": [{"uid": "x01", "kind": "token|spell|trinket|other", "name": "", "text": ""}],
  "builds": [{"name": "", "text": ""}],
  "risks": [""],
  "tier_check": [{"tier": 1, "note": ""}],
  "rationale": [""],
  "changes": [
    {"uid": "u04", "kind": "changed|added|removed|renamed|retiered",
     "what": "short: what changed", "why": "short: why",
     "from": ["v1--combo#p2"]},
    {"uid": "identity", "what": "short: what changed in the mechanic or keywords", "why": "short", "from": ["own"]}
  ],
  "declined": [{"point": "v1--climber#p1", "why": "short: why the reviser kept it"}]
}
```

- v1 has empty `changes` and `declined`. The portal shows the exact before and after by comparing the two versions, so `changes` holds only the what and the why.
- A change to the tribe as a whole (its mechanic, keywords or how it plays) uses `uid: "identity"`.
- From v2, every unit that differs from the previous version has one `changes` entry, with `what` and `why` of at most about 20 words each. `from` lists the review points behind it, or `["own"]`.
- Every review point marked `fix` in the previous version's reviews appears in `changes[].from` or in `declined`.

## `designs/<id>/reviews/v<n>--<member>.json`

```json
{
  "id": "v1--combo", "design_id": "moss-oozes--surgical", "v": 1, "member": "combo",
  "ratings": {"fun": 7, "distinct": 8},
  "ratings_why": {"fun": "one line", "distinct": "one line"},
  "verdict": "settle|iterate",
  "verdict_why": "one line",
  "points": [{"pid": "p1", "uid": "u04", "kind": "fix|idea", "text": "short"}],
  "standouts": [{"uid": "u12", "why": "short"}],
  "weakest": [{"uid": "u03", "why": "short"}],
  "flags": [{"uid": "u17", "kind": "broken|watch|unclear", "note": "short"}]
}
```

Ratings are whole numbers from 1 to 10. A review has at most 5 points, 3 standouts, 3 weakest and any number of flags. `uid` may be null for a point about the whole tribe. A `fix` is only for something broken (a loop with no counterplay, a choice that is always right) or unclear (a card a player can't read); everything else is an `idea`.

## `rankings/seed--<seed>.json` and `rankings/overall.json`

```json
{"seed": "moss-oozes", "order": ["moss-oozes--surgical", "moss-oozes--player-story", "moss-oozes--bottom-up-mech"],
 "why": [{"design": "moss-oozes--surgical", "line": "one line"}],
 "iteration_helped": [{"design": "", "line": "did v2/v3 beat v1, in one line"}]}
```

`overall.json` has `"picks": [{"design": "", "version": 1, "rank": 1, "line": ""}]`, up to 12 picks. A pick can name any version, v1 included.

## `designs/<id>/pitch.json` (the quick-read layer, added 14 Nov)

A short pitch of one design, written by a pitch writer after the design has stopped. It sits on top of the files above and changes none of them: the versions, reviews and rankings stay the record, and the portal's full view still shows them. The portal opens a design with this pitch, so the owner can understand a tribe in two or three minutes. `tools/tribe-run/check_pitch.py` checks it.

```json
{
  "design_id": "moss-oozes--surgical", "v": 2,
  "hook": "one sentence, at most 20 words: what playing this tribe is like",
  "loop": ["what you do each turn", "what that builds", "how it pays off"],
  "growth": {"shape": "tall|wide|economy|burst|slow-burn|in-fight|mixed", "line": "at most 18 words on how the numbers grow"},
  "feel": {"early": "at most 10 words", "mid": "at most 10 words", "late": "at most 10 words"},
  "stars": [{"uid": "u12", "why": "at most 12 words"}],
  "roles": {"u01": "body|engine|buff|economy|multiplier|payoff|utility"},
  "card_short": {"u01": "at most 10 words: what the card does, in plain words"},
  "builds": [{"name": "", "line": "at most 12 words"}],
  "liked": ["at most 14 words"],
  "worries": ["at most 14 words"],
  "changed": ["at most 14 words"],
  "verdict": "one sentence, at most 18 words: who would enjoy this tribe and what kind of game it gives them"
}
```

- `v` is the version the pitch describes: the design's final version.
- `loop` has exactly 3 steps of at most 12 words each. `stars` has exactly 3 cards: the ones that best show what the tribe is.
- `roles` and `card_short` have one entry for every unit and extra in that version, by uid. The portal's card table shows each card's full rules text (owner's pick, 14 Nov: "Full rules text"); `card_short` stays in the file as the short form. Roles: **body** (stats and tempo), **engine** (makes or moves the thing the tribe runs on), **buff** (gives stats), **economy** (gold, the shop, extra cards), **multiplier** (makes other effects bigger or repeat), **payoff** (turns the tribe's build-up into power; capstones), **utility** (protection, targeting and everything else).
- `builds` has up to 3. `liked` and `worries` have up to 2 each, taken from that version's reviews; a `broken` or `watch` flag that still stands belongs in `worries`. `changed` has up to 3: the biggest changes since v1, or an empty list for a design that was never revised.
- `verdict` carries no ratings, rank or pick number: the page shows those itself, beside the verdict.
- The pitch never names the design method, and adds no opinion of its own: it reports the design and what the reviewers and the ranker said.

## `rankings/takes--<seed>.json` (the three takes on a seed, side by side; added 14 Nov)

A small comparison of a seed's three designs, so the owner can choose which to open. Like `pitch.json` it is a layer on top: it changes no other file. `tools/tribe-run/check_takes.py` checks it.

```json
{
  "seed": "changelings",
  "shared": "one sentence, at most 18 words: what all three designs have in common",
  "differ": "one sentence, at most 18 words: the main way the three differ",
  "takes": [
    {"design": "changelings--surgical",
     "label": "2 to 4 words: a nickname for this take",
     "line": "at most 22 words: what this take does that the other two don't",
     "look_if": "at most 12 words, finishing the sentence 'Look at this one if you want…'"}
  ]
}
```

- `takes` has one entry for each of the seed's designs, in the seed ranking's order (best first).
- `label`, `line` and `look_if` contrast: each says what sets this take apart from the other two, not what it shares with them.
- It never names the design method, and adds no ranking of its own: the order and the ratings come from the files above.
