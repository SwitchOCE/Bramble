# Pigeon and Mouse reworks: build plan (draft, 19 Nov 2026)

Drafted by a planning agent for the balance orchestrator, from the pitches in this folder and the code on `dev`. The owner approved the designs (all the designers' picks, and Active as a gold cost and a colon: `docs/design/sources/2026-11-19b-tribe-rework-directions.md`, last section). This plan is how to build them. It is a proposal; the open decisions and their defaults are in section 2.

## Facts from the code that shape it

- **Snapshots.** `RecordState.fields()` saves every script variable it reaches, so a new `SlotState.renown` goes into the `fight_boards` payload (`slots`) and the state hash by itself, and so do unit `counters`. Nothing on dev yet rebuilds a player's slots from a payload; the ghost orchestrator's async-game step will need to.
- **Bots.** The frozen league bots compile against league-api. Active must keep the existing `ability` action type and the `has_ability`/`ability_cost` API, and change only how it is shown. TribeBot (tools/league/gd/tribe_bot.gd on orch/ghost-system) already uses abilities (SimpleBot scores them 2.0), never deliberately holds Reserve units in hand, and places units by matching card text.
- **Tests.** tests/glass/test_unit_art.gd requires art for every shipped card and asserts exactly 5 tribe folders; new cards without art, or a neutral folder, fail it.
- **Card pool.** `CardPool` lets tribeless cards into every lobby, so a live neutral folder would change every game's shop; this collides with the pool removal.

## 1. Steps

- **S0 Rules text** (docs, no port): rulebook 3.3 Active, 8.5 Renown, new entries for Charge/Supply, Reserve limit and fill order, Pile on N and Hand-me-down, each quoting the owner; SHARED-RULES entries. Parallel with S1, S1b.
- **S1 Active display** (UI + card text; no Rust code): `KeywordText` draws an inline gold coin for a leading `{cost}:` (free shows 0); the ability button shows the coin (red when unaffordable, dimmed when used); "Order (N)" and "Ability · costs N" go; a shared `active` display entry; Lance Corporal and Grenadier text "{cost}: …"; Bury keeps its word. Tests: keyword layout, tooltips, recruit screen; a look screenshot.
- **S1b Art placeholders** (tests/UI; no port): a waiting-for-art list; listed cards pass the art test with the stand-in tribe panel; the test fails if a listed card has real art.
- **S2 Charge and Supply in core** (rules; port): new param kinds CHARGE/SUPPLY that golden leaves alone; a core `use_charge`; fight uses in `fight_counts`, turn uses in `turn_counters`; Supply as uses left in `Unit.counters["supply:<mechanic>"]` (triples add them); pips (round for Charge, square crates for Supply). New snapshot field: `counters.supply:*`. All existing reference games must stay hash-identical.
- **S3 Renown and the Reserve limit in core** (rules; port; the hardest step): `SlotState.renown`, applied only to starting units and reservists; `combat.step_in()` marks Privates as reservists outside the limit; a `from_hand` flag for the Colonel; Renown gained in a fight is written to the real slot only (counts from the next fight); `FightArrivals._step_in` gets the limit (base 2, raised by a query), fill order (Guard post, most Renown, reading order) and the reservist Renown percent; a `renown` display entry and slot banners. New snapshot field: `slots[].renown`. Every hash changes. Parallel with S2.
- **S4 Ghost state proof** (tests, records README, the Rust field lists; port): a payload → restore → fight round-trip proving slot Renown and Supply left survive; Format 2 table. The gate before any bot measurement. **Every step's commit message names any new snapshot fields.**
- **S5 Pigeon rework** (rules; port): 20 units plus the Private as pitched; delete Medals, Adjutant, Brigadier, Field Marshal, Stiff Upper Lip; new Quartermaster, Group Captain, Air Marshal; Home Guard as data; Colonel and Sergeant Major rewritten; Pigeon and cross tests rewritten. After S3 and S4.
- **S6 Pile on N and Hand-me-down** (rules; port): Pile on becomes a counted effect; a `mouse_hand_me_down` death effect passing own Attack. Needs S2.
- **S7 Mouse rework, Kin** (rules; port): 19 units plus the Cousin; six displaced cards to docs/archive; Harrier and Ballista to docs/archive/neutral-pool-candidates/ with a README row (owner chose them for the neutral pool; the pool's rules are undecided); the Kin's Health exception (Thimble Sentinel) written into the tribe doc, quoting the owner. Parallel with S5.
- **S8 Bots** (port): TribeBot holds up to the limit of Reserve units in hand once it has 5+ on board, plays its best unit into the most-Renown slot, and refreshes text matches for the new cards; agree with the ghost orchestrator how this is tagged. A 50-game soak per tribe where a Reserve unit is held at least once.
- **S9 (later) Retire slot buffs** once nothing uses them.

Order: S0, S1, S1b → S2 ∥ S3 → S4 → S5 ∥ (S6 → S7) → S8.

Other tribes' limits move to Charge later (Gorger with the Locust work, Sett Sexton with the Badgers), to keep port and measurement noise out of tribes being tuned.

## 2. Open decisions, with defaults

1. A free Active shows a coin with 0.
2. An Active with Charge reads "{1}, Charge 2: …" (no approved card needs it yet).
3. The Mice's "(N a fight)" limits become Charge N (Thimble Captain, Needle Sister, Grandmother Hob, Old Mother Needle).
4. Golden doesn't double Pile on N, matching Charge (the pitch contradicts itself; ask the owner).
5. Charge on an effect that fires in both phases: one count, refilled at the start of each fight and each turn.
6. A golden from Discover gets full Supply N.
7. "Nearest friendly Mouse": shortest board distance among living units, ties in reading order.
8. Reserve given by the Quartermaster is a permanent granted effect (saved in `grants`).
9. Renown shows in the slot-buff layer's colour with a number on a slot banner; no company names until the owner picks.
10. Hand banners for the limit show only when a Reserve unit is in hand.
11. A ghost's Renown gains are not written back.
12. Flying Ace's Cleave from the start: build as pitched, show the owner at the check.
13. New-card count is 12 (4 Pigeon, 8 Mouse), not 28; reworked cards keep their art.

## 3. Player-facing check at the end

Screenshots (tools/look): Lance Corporal's "1:" coin (normal, red, dimmed), Grenadier's "0:", Sentry's Supply crates emptying, Padre's pips, Renown banners including empty slots, the reserve banners. A filmed fight (tools/feel): a reservist steps into the post with its Renown; the Colonel doubles it; a Private steps in after both reservists; a Hopper gets no Renown; a Mouse death passes Attack; the T6 Pikeman spreads +2. Then the owner plays a game as each tribe, and records.sh replays it.

## 4. Size and worker

S0 small, Claude. S1 medium, Claude. S1b small, Codex Sol. S2 medium, Codex Astra. S3 large, Claude. S4 small, Codex Sol. S5 large, Codex Astra with Claude review. S6 medium, Codex Sol. S7 large, Codex Astra with Claude review. S8 small, Claude with the ghost orchestrator. S9 small, Codex Sol. Every Rust port is the ghost orchestrator's.

## Revised after the plan interrogation (19 Nov 2026)

A fresh agent challenged this plan (`plan-interrogation.txt` in this folder). The balance orchestrator adopted its smaller plan; the owner said to go with recommendations.

1. S0 rules text, S1 the gold-coin Active (the shared `active` display entry is hidden, so no card prints the word "Active"), and S1b art stand-ins, in parallel. Show the owner the coin.
2. S3 Renown and the Reserve limit, with a payload test that slot Renown and Supply survive in the fight snapshot. The reservist Renown multiplier is built only as the Colonel's.
3. S5 Pigeons, with Charge written as card text over the existing never-doubled limit params and per-fight counts (no new param kinds), and Supply on the Sentry only. In parallel, S6 Pile on N and Hand-me-down (no wait on S2), then S7 the Mice.
4. Retire slot buffs right after S5 and S7.
5. Two Rust ports by the ghost orchestrator: Pigeons (S1–S5), then Mice (S6–S7).
6. S8 TribeBot and the soak.
7. The end check: the owner plays each tribe.
8. A balance measurement: TribeBot with tribe-locked seats, old against new, plus the league bots' readings marked as understated (they can't hold reservists or use Actives on purpose).

Deferred until a card needs it: Charge refilling each turn, Charge in both phases, Active with Charge, a general reservist Renown percent. Restoring slots from a snapshot is the ghost orchestrator's async-game step. Art for the 12 new cards waits until they survive the first measurement; company names wait for the owner.
