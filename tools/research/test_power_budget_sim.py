"""Tests for the rows-study combat engine in power_budget.py (rulebook 8.x and 9.x).

Run from the repo root. With -I the current folder is not on sys.path, so
`python -I -m unittest tools/research/test_power_budget_sim.py` can't import the file;
use one of these:

    python -I tools/research/test_power_budget_sim.py
    python -I -m unittest discover -s tools/research -p test_power_budget_sim.py
"""
import os
import random
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import power_budget as pb  # noqa: E402

F1, F2, F3, F4, B1, B2, B3 = range(7)


def wall(atk=1, hp=1000, **kw):
    return pb.card("Wall", atk, hp, **kw)


def board(**slots):
    """board(F1=card, B2=card) -> list of 7."""
    names = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]
    return [slots.get(n) for n in names]


def proto(name):
    return next(c for c in pb.POSITION_CARDS + pb.SUMMON_CARDS if c["name"] == name)


def attacks(trace, side):
    return [e for e in trace if e[0] == "attack" and e[1] == side]


def kill(f, s, j):
    f.S[s][j].hp = 0


class AttackOrder(unittest.TestCase):
    def test_front_left_to_right_then_back(self):
        # Side A: F1, F3, B2. Nobody dies (huge Health), so the cycle repeats.
        A = board(F1=wall(), F3=wall(), B2=wall())
        B = board(F1=wall(), F2=wall(), F3=wall())
        trace = []
        pb.Fight(A, B, random.Random(1), trace).run()
        order = [e[2] for e in attacks(trace, 0)][:9]
        self.assertEqual(order, [F1, F3, B2] * 3)

    def test_more_units_attacks_first(self):
        A = board(F1=wall(), F2=wall())
        B = board(F1=wall())
        for seed in range(20):
            trace = []
            pb.Fight(A, B, random.Random(seed), trace).run()
            first_attack = next(e for e in trace if e[0] == "attack")
            self.assertEqual(first_attack[1], 0)

    def test_zero_attack_units_skipped_and_stall_is_a_tie(self):
        A = board(F1=wall(atk=0), B1=wall())
        B = board(F1=wall(atk=0))
        trace = []
        result = pb.Fight(A, B, random.Random(3), trace).run()
        self.assertTrue(all(e[2] == B1 for e in attacks(trace, 0)))
        self.assertEqual(result, 0.5)   # 200-attack limit (9.10.1)

    def test_summon_into_attackers_slot_attacks_next(self):
        # Rulebook 9.4.8 worked example, driven through attack(): A has F1, F3, B2.
        # F1 attacks, then F3 attacks and dies; its Deathrattle summons two tokens,
        # into F3 (own slot, = pointer, so not flagged) and F4 (nearest, above the pointer).
        tok = pb.card("Tok", 1, 50)
        dier = pb.card("Dier", 1, 1, dr=(("summon", 2, tok),))
        f = pb.Fight(board(F1=wall(), F3=dier, B2=wall()), board(F1=wall(atk=1)), random.Random(0))
        seq = []
        for _ in range(6):
            j = f.pick(0)
            seq.append(j)
            f.attack(0, j)
        self.assertEqual(seq, [F1, F3, F3, F4, B2, F1])
        self.assertEqual((f.S[0][F3].c["name"], f.S[0][F4].c["name"]), ("Tok", "Tok"))

    def test_summon_below_pointer_waits(self):
        f = pb.Fight(board(F3=wall(), B2=wall()), board(F1=wall()), random.Random(0))
        f.attack(0, F3)
        f.place(0, pb.Unit(wall()), (F2,))
        self.assertTrue(f.S[0][F2].flag)
        self.assertEqual(f.pick(0), B2)


class Targeting(unittest.TestCase):
    def test_back_row_protected_while_front_lives(self):
        A = board(F1=wall(atk=1))
        B = board(F2=wall(atk=1), B1=wall(), B2=wall(), B3=wall())
        for seed in range(30):
            trace = []
            pb.Fight(A, B, random.Random(seed), trace).run()
            self.assertTrue(all(e[3] == F2 for e in attacks(trace, 0)))

    def test_back_row_attackable_once_front_is_empty(self):
        A = board(F1=wall(atk=1))
        B = board(B1=wall(), B3=wall())
        hit = set()
        for seed in range(30):
            trace = []
            pb.Fight(A, B, random.Random(seed), trace).run()
            hit |= {e[3] for e in attacks(trace, 0)}
        self.assertEqual(hit, {B1, B3})

    def test_front_taunt_draws_attacks(self):
        A = board(F1=wall())
        B = board(F1=wall(), F2=wall(taunt=True), F3=wall())
        for seed in range(30):
            trace = []
            pb.Fight(A, B, random.Random(seed), trace).run()
            self.assertTrue(all(e[3] == F2 for e in attacks(trace, 0)))

    def test_back_taunt_does_not_pull_from_front(self):
        A = board(F1=wall())
        B = board(F1=wall(), F4=wall(), B2=wall(taunt=True))
        hit = set()
        for seed in range(30):
            trace = []
            pb.Fight(A, B, random.Random(seed), trace).run()
            hit |= {e[3] for e in attacks(trace, 0)}
        self.assertEqual(hit, {F1, F4})

    def test_back_taunt_protects_back_row_once_attackable(self):
        A = board(F1=wall())
        B = board(B1=wall(), B2=wall(taunt=True), B3=wall())
        for seed in range(30):
            trace = []
            pb.Fight(A, B, random.Random(seed), trace).run()
            self.assertTrue(all(e[3] == B2 for e in attacks(trace, 0)))

    def test_random_effects_ignore_rows_and_taunt(self):
        # A's F1 has "Deathrattle: deal 1 damage to a random enemy". B has a live Taunt front.
        pinger = pb.card("Pinger", 0, 1, dr=(("ping", 1),))
        B = board(F1=wall(taunt=True), B1=wall(), B2=wall(), B3=wall())
        hit = set()
        for seed in range(60):
            f = pb.Fight(board(F1=pinger), B, random.Random(seed), [])
            kill(f, 0, F1)
            f.resolve_deaths(0)
            hit |= {e[2] for e in f.trace if e[0] == "ping"}
        self.assertEqual(hit, {F1, B1, B2, B3})


class SummonPlacement(unittest.TestCase):
    RULEBOOK_TABLE = {  # rulebook 8.4.2
        "F1": "F2 F3 F4 B1 B2 B3", "F2": "F3 F1 F4 B2 B1 B3", "F3": "F4 F2 F1 B3 B2 B1",
        "F4": "F3 F2 F1 B3 B2 B1", "B1": "B2 B3 F2 F1 F3 F4", "B2": "B3 B1 F3 F2 F4 F1",
        "B3": "B2 B1 F4 F3 F2 F1",
    }

    def test_nearest_empty_slot_table(self):
        names = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]
        for src, want in self.RULEBOOK_TABLE.items():
            got = " ".join(names[j] for j in pb.SUMMON_ORDER[names.index(src)])
            self.assertEqual(got, want, src)

    def test_deathrattle_first_summon_takes_own_slot(self):
        ooze = pb.card("Ooze", 1, 1, dr=(("summon", 3, pb.SPORE),))
        A = board(F1=wall(), F2=ooze, F4=wall(), B1=wall(), B3=wall())
        f = pb.Fight(A, board(F1=wall()), random.Random(0))
        kill(f, 0, F2)
        f.resolve_deaths(0)
        names = [u.c["name"] if u else None for u in f.S[0]]
        # own slot F2, then nearest empty: F3 (same row), then B2 (other row).
        self.assertEqual(names, ["Wall", "Spore", "Spore", "Wall", "Wall", "Spore", "Wall"])

    def test_full_board_summon_is_lost(self):
        ooze = pb.card("Ooze", 1, 1, dr=(("summon", 2, pb.SPORE),))
        A = [wall() for _ in range(7)]
        A[F1] = ooze
        f = pb.Fight(A, board(F1=wall()), random.Random(0))
        kill(f, 0, F1)
        f.resolve_deaths(0)
        self.assertEqual(sum(1 for u in f.S[0] if u), 7)
        self.assertEqual(f.S[0][F1].c["name"], "Spore")

    def test_reborn_returns_to_own_slot_with_one_health(self):
        hare = pb.card("Hare", 3, 3, reborn=True)
        f = pb.Fight(board(B2=hare), board(F1=wall()), random.Random(0))
        kill(f, 0, B2)
        f.resolve_deaths(0)
        u = f.S[0][B2]
        self.assertEqual((u.c["name"], u.atk, u.hp, u.reborn), ("Hare", 3, 1, False))

    def test_reborn_after_own_deathrattle_goes_nearest(self):
        both = pb.card("Both", 1, 1, reborn=True, dr=(("summon", 1, pb.SPORE),))
        f = pb.Fight(board(F3=both), board(F1=wall()), random.Random(0))
        kill(f, 0, F3)
        f.resolve_deaths(0)
        self.assertEqual(f.S[0][F3].c["name"], "Spore")
        self.assertEqual(f.S[0][F4].c["name"], "Both")

    def test_named_slot_summon_fails_if_slot_is_full(self):
        # 8.4.6: the front unit's own Deathrattle fills F3 first, so Sapling Keeper's
        # "summon into its slot" fails and keeps its use.
        ooze = pb.card("Ooze", 1, 1, dr=(("summon", 1, pb.SPORE),))
        f = pb.Fight(board(F3=ooze, B3=proto("Sapling Keeper")), board(F1=wall()), random.Random(0))
        kill(f, 0, F3)
        f.resolve_deaths(0)
        self.assertEqual(f.S[0][F3].c["name"], "Spore")
        self.assertEqual(f.S[0][B3].uses, 2)
        self.assertEqual(sum(1 for u in f.S[0] if u), 2)

    def test_active_side_deaths_resolve_first(self):
        # 9.7.3: both F1s die in one exchange; the attacking side's Deathrattle resolves first.
        dr = pb.card("Dr", 5, 1, dr=(("summon", 1, pb.SPORE),))
        for attacker in (0, 1):
            trace = []
            f = pb.Fight(board(F1=dr), board(F1=dr), random.Random(0), trace)
            f.attack(attacker, F1)
            dies = [e[1] for e in trace if e[0] == "dies"]
            self.assertEqual(dies, [attacker, 1 - attacker])


class PositionEffects(unittest.TestCase):
    def test_aura_reaches_only_units_in_front(self):
        f = pb.Fight(board(F1=wall(), F2=wall(), F3=wall(), B1=proto("Lantern Moth")), board(F1=wall()),
                     random.Random(0))
        self.assertEqual([f.eff_atk(0, j) for j in (F1, F2, F3)], [2, 2, 1])

    def test_when_front_dies_trigger_and_after_death_summon(self):
        f = pb.Fight(board(F2=wall(), F3=wall(), B2=proto("Vigil Vole"), B3=proto("Sapling Keeper")),
                     board(F1=wall()), random.Random(0))
        kill(f, 0, F3)
        f.resolve_deaths(0)
        self.assertEqual((f.S[0][B2].atk, f.S[0][B2].hp), (3, 4))
        self.assertEqual(f.S[0][F3].c["name"], "Sapling")
        self.assertEqual(f.S[0][B3].uses, 1)

    def test_start_of_combat_behind_and_lone(self):
        f = pb.Fight(board(F2=proto("Hearthguard Badger"), F4=proto("Lone Stag"), B1=wall(), B2=wall()),
                     board(F1=wall()), random.Random(0))
        f.start_of_combat()
        self.assertEqual([f.S[0][j].atk for j in (B1, B2)], [3, 3])
        self.assertEqual((f.S[0][F4].atk, f.S[0][F4].hp), (5, 4))   # B3 empty: Stag gains +3/+3

    def test_lone_stag_in_back_row_does_not_trigger(self):
        f = pb.Fight(board(F1=wall(), B2=proto("Lone Stag")), board(F1=wall()), random.Random(0))
        f.start_of_combat()
        self.assertEqual((f.S[0][B2].atk, f.S[0][B2].hp), (2, 1))

    def test_drummer_hare_buffs_units_behind_when_it_attacks(self):
        f = pb.Fight(board(F2=proto("Drummer Hare"), B1=wall(), B2=wall(), B3=wall()),
                     board(F1=wall(atk=0)), random.Random(0))
        f.attack(0, F2)
        self.assertEqual([(f.S[0][j].atk, f.S[0][j].hp) for j in (B1, B2, B3)],
                         [(2, 1001), (2, 1001), (1, 1000)])

    def test_spotter_rook_pings_only_when_a_unit_in_front_attacks(self):
        trace = []
        f = pb.Fight(board(F1=wall(), F3=wall(), B1=proto("Spotter Rook")), board(F1=wall(), B1=wall()),
                     random.Random(0), trace)
        f.attack(0, F1)
        self.assertEqual(sum(1 for e in trace if e[0] == "ping"), 1)
        f.attack(0, F3)                       # F3 is not in front of B1
        self.assertEqual(sum(1 for e in trace if e[0] == "ping"), 1)

    def test_ping_that_kills_the_defender_cancels_the_attack(self):
        # 9.6.1: if the defender is gone after step 2, no damage exchange.
        f = pb.Fight(board(F1=pb.card("Att", 1, 10), B1=proto("Spotter Rook")),
                     board(F1=pb.card("Def", 5, 1)), random.Random(0))
        f.attack(0, F1)
        self.assertIsNone(f.S[1][F1])
        self.assertEqual(f.S[0][F1].hp, 10)

    def test_deaths_checked_after_each_ping(self):
        # 9.6.3: two Rooks behind F2. The first ping kills a 1-Health Reborn unit; it returns
        # before the second ping, which can then hit it. Resolving deaths together would
        # leave the returned copy alive.
        rook = proto("Spotter Rook")
        reb = pb.card("Reb", 0, 1, reborn=True)
        f = pb.Fight(board(F2=wall(), B1=rook, B2=rook), board(F1=reb), random.Random(0))
        f.attack(0, F2)
        self.assertTrue(all(u is None for u in f.S[1]))

    def test_martyr_hedgehog_deathrattle_buffs_units_behind(self):
        f = pb.Fight(board(F2=proto("Martyr Hedgehog"), B1=wall(), B2=wall(), B3=wall()),
                     board(F1=wall()), random.Random(0))
        kill(f, 0, F2)
        f.resolve_deaths(0)
        self.assertEqual([f.S[0][j].atk for j in (B1, B2, B3)], [2, 2, 1])

    def test_start_of_combat_side_is_random_and_deaths_resolve_between(self):
        # 9.3.2 and 9.3.5: two Acorn Slingers face each other in B1 with 3 Health or less.
        # Whichever side goes first kills the other before it fires.
        sl = dict(proto("Acorn Slinger"), hp=2)
        firsts = set()
        for seed in range(40):
            trace = []
            f = pb.Fight(board(F1=wall(), B1=sl), board(F1=wall(), B1=sl), random.Random(seed), trace)
            f.start_of_combat()
            first = next(e[1] for e in trace if e[0] == "soc_first")
            firsts.add(first)
            self.assertEqual([e[1] for e in trace if e[0] == "soc_hit"], [first])
            self.assertIsNone(f.S[1 - first][B1])
            self.assertIsNotNone(f.S[first][B1])
        self.assertEqual(firsts, {0, 1})

    def test_tortoise_gains_only_as_the_only_front_unit(self):
        t = proto("Shellback Tortoise")
        f = pb.Fight(board(F2=t, B1=wall(), B2=wall()), board(F1=wall()), random.Random(0))
        f.start_of_combat()
        self.assertEqual(f.S[0][F2].hp, 6)
        f = pb.Fight(board(F2=t, F3=wall()), board(F1=wall()), random.Random(0))
        f.start_of_combat()
        self.assertEqual(f.S[0][F2].hp, 3)

    def test_nest_robin_recruit_buffs_land_on_units_in_front(self):
        f = pb.Fight(board(F1=wall(), F2=wall(), F3=wall(), B1=proto("Nest Robin")), board(F1=wall()),
                     random.Random(0))
        self.assertEqual([f.S[0][j].hp for j in (F1, F2, F3)], [1002, 1002, 1000])

    def test_golden_doubles_effects_not_counts(self):
        g = pb.golden_card(proto("Sapling Keeper"))
        self.assertEqual((g["atk"], g["hp"], g["fx"][1]["atk"], g["fx"][2]), (2, 6, 4, 2))
        r = pb.golden_card(proto("Nest Robin"))
        self.assertEqual(r["fx"], ("eot_front_buff", 0, 2, 2))


class OneRowBaseline(unittest.TestCase):
    def test_every_enemy_is_a_target(self):
        hit = set()
        for seed in range(40):
            trace = []
            pb.Fight(board(F1=wall()), board(F1=wall(), B3=wall()), random.Random(seed), trace, mode="line").run()
            hit |= {e[3] for e in attacks(trace, 0)}
        self.assertEqual(hit, {F1, B3})

    def test_position_text_reads_as_adjacent(self):
        # In the line geometry slot 5 (B2) is adjacent to slots 4 and 6.
        f = pb.Fight(board(F4=wall(), B1=wall(), B2=proto("Lantern Moth"), B3=wall()), board(F1=wall()),
                     random.Random(0), mode="line")
        self.assertEqual([f.eff_atk(0, j) for j in (F4, B1, B3)], [1, 2, 2])

    def test_summons_go_to_nearest_empty_slot_tie_right(self):
        ooze = pb.card("Ooze", 1, 1, dr=(("summon", 3, pb.SPORE),))
        f = pb.Fight(board(F1=wall(), F2=wall(), F3=ooze, F4=wall()), board(F1=wall()), random.Random(0),
                     mode="line")
        kill(f, 0, F3)
        f.resolve_deaths(0)
        self.assertEqual([u.c["name"] if u else None for u in f.S[0]],
                         ["Wall", "Wall", "Spore", "Wall", "Spore", "Spore", None])


class RulesOfThumb(unittest.TestCase):
    def test_rule_v2_keeps_at_most_three_in_front_and_fills_behind_badger(self):
        units = [proto("Hearthguard Badger")] + [pb.card("Plain", a, 3) for a in (5, 4, 3, 2)]
        pl = pb.heuristic_placement(units)
        self.assertEqual(sum(1 for j in range(4) if pl[j] >= 0), 3)
        self.assertEqual(pl[F2], 0)
        self.assertTrue(pl[B1] >= 0 and pl[B2] >= 0)
        v1 = pb.heuristic_placement(units, version=1)
        self.assertEqual(sum(1 for j in range(4) if v1[j] >= 0), 4)

    def test_line_rule_is_packed(self):
        units = [pb.card("Plain", a, 3) for a in (1, 5, 3, 2, 4)]
        pl = pb.heuristic_line(units)
        self.assertEqual(pl[5:], (-1, -1))
        self.assertEqual([units[k]["atk"] for k in pl[:5]], [5, 4, 3, 2, 1])

    def test_line_rule_puts_attack_cards_early_and_support_late(self):
        units = [proto("Drummer Hare"), proto("Vigil Vole")] + [pb.card("Plain", a, 3) for a in (5, 4, 3, 2, 1)]
        pl = pb.heuristic_line(units)
        self.assertEqual((pl.index(0), pl.index(1)), (1, 5))

    def test_small_board_fit_layout(self):
        others = [pb.card("Plain", a, 3) for a in (3, 2, 1)]
        tort = pb.fit_layout(proto("Shellback Tortoise"), others, F2)
        self.assertEqual(sorted(j for j in range(7) if tort[j] >= 0), [B1, B2, B3])
        stag = pb.fit_layout(proto("Lone Stag"), others, F1)
        self.assertEqual(stag[B1], -1)


if __name__ == "__main__":
    unittest.main()
