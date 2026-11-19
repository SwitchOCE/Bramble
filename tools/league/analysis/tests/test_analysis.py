import contextlib
import gzip
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from behaviours import behaviour_stats
from cards import card_stats
from match_data import BANDS, Match, Stat, aligned, band
from split_team import split
from tribes import tribe_stats


def unit(card, slot, golden=False):
    return dict(card=card, slot=slot, attack=2, health=2, golden=golden)


def shop(g, pid, colour, rd, offers, buys):
    return dict(game=g, seat=pid, colour=colour, bot=colour, round=rd,
                offers=[dict(card=c, spell=c=="spell", index=i, buyable=can) for i,(c,can) in enumerate(offers)],
                bought=[dict(card=c, spell=c=="spell", index=i) for i,c in enumerate(buys)])


class Fixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path(__file__).resolve().parent)
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)
        def save(name, obj):
            (self.path / (name+".json")).write_text(json.dumps(obj))
        save("summary", dict(schema=1, complete=True, games=4, red="red", blue="blue",
                             red_avg_place=4.5, blue_avg_place=4.5, gap_red_minus_blue=0))
        save("analysis", {"games":4, "seed_pairs":2, "score":{
            "red_avg_place":4.5, "blue_avg_place":4.5, "gap_red_minus_blue":0, "gap_ci95":0,
            "red_ci95":0, "blue_ci95":0, "winner":"none outside the noise"}})
        save("library", [dict(id=c, spell=c=="spell", tribes=ts) for c,ts in
                         [("bread",["Mouse"]),("shield",["Badger"]),("spy",["Mouse"]),
                          ("unseen",["Mouse"]),("spell",[])]])
        games, decisions = [], []
        for g in range(4):
            red = ({0,2,5,7} if g<2 else {0,3,4,6})
            if g%2:
                red = set(range(8))-red
            seats = []
            for pid in range(8):
                colour = "red" if pid in red else "blue"
                t,c = ("Badger","shield") if colour=="red" else ("Mouse","spy")
                final = [unit(c,i) for i in range(4)]
                if g==0 and pid==0:
                    final += [unit("bread",4,True),unit("bread",5)]
                early = [unit("spy",0)]
                def snap(rd,board,counts):
                    return dict(round=rd, board=board, tribes=counts, board_attack=2*len(board),
                                board_health=2*len(board), hand=[], heaps={}, tier=1, gold_left=3,
                                gold_from_cards=0, triple=rd==1, slot_buff=False, golden_gained=False)
                seats.append(dict(seat=pid,colour=colour,bot=colour,place=pid+1,
                                  main_tribe=t,final_board=final,pivots=[],commit_round=13,
                                  rounds=[snap(1,early,{"Mouse":1}),snap(12,early,{"Mouse":1}),
                                          snap(13,final,{t:4,**({"Mouse":2} if len(final)>4 else {})})]))
                decisions.append(dict(game=g,seat=pid,round=1,colour=colour,bot=colour,chosen=0,
                                      result="",legal=[{"type":"end_turn","marker":colour+"-only-marker"}]))
            games.append(dict(game=g,seed="repeated-seed",swapped=bool(g%2),red_seats=sorted(red),
                              seats=seats,fights=[]))
        self.lines("games", games)
        self.lines("decisions", decisions, zipped=True)
        self.shops = [
            shop(0,0,"red",1,[("bread",True),("bread",True),("unseen",False)],["bread","bread"]),
            shop(0,0,"red",2,[("bread",False)],["bread"]),
            shop(0,0,"red",3,[("bread",True)],[]),
            shop(0,0,"red",4,[("bread",True),("spell",True)],["spell"]),
            shop(1,0,"blue",7,[("bread",True)],["bread"]),
            shop(2,0,"red",10,[("bread",True)],["bread"]),
            shop(3,0,"blue",13,[("spy",True)],["spy"]),
        ]
        self.lines("shops", self.shops, zipped=True)
        self.lines("discovers",[dict(game=0,seat=0,colour="red",bot="red",round=1,
                                     options=["bread","bread","shield"],card="shield")])
        self.lines("reports", [dict(game=0,seat=0,colour="red",bot="red",round=1,kind="shop",
                                    strategy="collect",offered=["bread","bread","unseen"],
                                    values=[["bread",2],["bread",2],["unseen",3]])])
        self.m = Match(self.path)

    def lines(self, name, rows, zipped=False):
        path = self.path / (name + (".jsonl.gz" if zipped else ".jsonl"))
        with (gzip.open(path,"wt") if zipped else path.open("w")) as f:
            for row in rows:
                print(json.dumps(row),file=f)

    def test_buyable_only_per_shop(self):
        red = card_stats(self.m)["red"]
        self.assertEqual((red["bread"]["buy"]["hits"],red["bread"]["buy"]["count"]), (2,4))
        self.assertIsNone(red["unseen"]["never_bought"])
        self.assertEqual(red["bread"]["among_buying_shops"]["Badger"]["count"],3)
        self.assertIsNone(red["bread"]["band_and_final_tribe"].get("7-9"))

    def test_round_band_boundaries(self):
        self.assertEqual([band(i) for i in (1,3,4,6,7,9,10,12,13,100)],
                         [b for b in BANDS for _ in range(2)])
        d = card_stats(self.m)["both"]["bread"]["by_band"]
        self.assertEqual([(d[b]["hits"],d[b]["count"]) for b in BANDS],[(1,2),(0,1),(1,1),(1,1),(0,0)])

    def test_final_main_tribe_and_colour_swap(self):
        d = card_stats(self.m)
        self.assertEqual(d["red"]["bread"]["by_final_tribe"]["Badger"]["rate"],.5)
        self.assertEqual(d["red"]["bread"]["by_final_tribe"]["Mouse"]["count"],0)
        self.assertEqual(d["blue"]["bread"]["by_final_tribe"]["Mouse"]["rate"],1)
        self.assertEqual(d["both"]["bread"]["by_final_tribe"]["Badger"]["count"],4)

    def test_verdicts_require_all_tribes_and_keep_both_denominators(self):
        rows = [shop(0,0,"red",1,[("bread",True)],["bread"])] + [
            shop(1,0,"blue",1,[("bread",True)],["bread"])] * 4 + [
            shop(1,0,"blue",1,[("bread",True)],[])]
        self.lines("reports",[])
        self.lines("shops",rows,True)
        d=card_stats(self.m)
        self.assertFalse(d["both"]["bread"]["always_bought"])  # exactly 80% in Mouse
        self.assertTrue(d["both"]["bread"]["always_among_buying_shops"])
        self.assertIsNone(d["red"]["bread"]["always_bought"])
        self.lines("shops",[shop(0,0,"red",1,[("bread",True)],[])]*49 + rows[:1],True)
        self.assertFalse(card_stats(self.m)["red"]["bread"]["never_bought"])  # exactly 2%

    def test_discover_golden_rank_and_placement_lift(self):
        d = card_stats(self.m)["red"]
        self.assertEqual((d["bread"]["discover"]["hits"],d["bread"]["discover"]["count"]),(0,1))
        self.assertEqual(d["shield"]["discover"]["rate"],1)
        self.assertEqual(d["bread"]["golden"]["rate"],.5)
        self.assertEqual(d["bread"]["value_rank"]["mean"],2)
        self.assertEqual(d["bread"]["value_rank_when_buyable"]["mean"],2)
        self.assertIsNone(d["unseen"]["value_rank_when_buyable"]["mean"])
        self.assertEqual(d["bread"]["lift_places"]["mean"],3.5)  # cohort 4.5, presence place 1
        self.assertEqual(d["bread"]["lift_places"]["count"],1)

    def test_split_owns_every_decision_and_is_invariant_to_opposing_choices(self):
        for team in ("red","blue"):
            out=self.path/team
            with contextlib.redirect_stdout(io.StringIO()):
                split(self.m,team,out)
            self.assertEqual({p.name for p in out.iterdir()},{"team.json","team.md","decisions.jsonl.gz"})
            data=json.loads((out/"team.json").read_bytes())
            self.assertEqual(set(data),{"team","score","decision_lines","cards","pooled_tribes"})
            self.assertTrue(all(set(v)=={"share","placement"} for v in data["pooled_tribes"].values()))
            self.assertEqual(data["cards"],card_stats(self.m)[team])
            raw=gzip.decompress((out/"decisions.jsonl.gz").read_bytes())
            expected=b"".join(l for l in self.m.lines("decisions") if json.loads(l)["colour"]==team)
            self.assertEqual(raw,expected)
            self.assertEqual(len(raw.splitlines()),16)
            foe = "red" if team=="blue" else "blue"
            self.assertNotIn((foe+"-only-marker").encode(),raw)
        self.shops[4]["bought"]=[]
        self.lines("shops", self.shops, True)
        with contextlib.redirect_stdout(io.StringIO()):
            split(self.m,"red",self.path/"red2")
        self.assertEqual((self.path/"red/team.json").read_bytes(), (self.path/"red2/team.json").read_bytes())

    def test_identity_mismatch_aborts_export(self):
        rows=list(self.m.rows("decisions"))
        rows[8]["colour"]="red"  # seat 0 is blue after swap
        self.lines("decisions",rows,True)
        with self.assertRaisesRegex(ValueError,"identity"):
            split(self.m,"red",self.path/"bad")
        self.assertFalse((self.path/"bad").exists())

    def test_commit_mixed_and_reports(self):
        d=tribe_stats(self.m)["red"]
        self.assertEqual(d["commit"]["Badger"]["round"]["mean"],13)
        self.assertEqual(d["commit"]["Badger"]["previous_triple"]["rate"],0)
        self.assertEqual(d["mixed"]["rate"],1/16)
        self.assertEqual(d["mixed_placement"]["mean"],1)
        self.assertEqual(d["reports"]["bought_highest_reported"]["rate"],0)

    def test_pair_weighted_interval(self):
        d=card_stats(self.m)["red"]["bread"]["buy"]
        self.assertEqual(d["pairs"],2)  # same seed text, different pairs
        # Pair (1/3, 1/1); pooled rate .5. Residuals -.5 and +.5.
        self.assertAlmostEqual(d["ci95"][0],.5-1.96/4)
        self.assertAlmostEqual(d["ci95"][1],.5+1.96/4)
        s=Stat()
        s.add(0,3)
        self.assertIsNone(s.result()["ci95"])

    def test_current_tribe_tie_breaks(self):
        snap={"tribes":{"Badger":1,"Mouse":1},"board":[unit("bread",0),unit("shield",1)]}
        self.assertEqual(self.m.main(snap),"Badger")
        snap["board"][0]["attack"]+=1
        self.assertEqual(self.m.main(snap),"Mouse")

    def test_optional_reports_are_not_assigned_arbitrarily(self):
        report={"offered":["bread"]}
        self.assertEqual(aligned([report],[["bread"],["bread"]]),[None])
        self.assertEqual(aligned([report,report],[["bread"],["bread"]]),[0,1])

    def test_fight_sides_draws_ghosts_and_death_counts(self):
        games=list(self.m.games())
        for pid,card in ((0,"gleaner"),(2,"the-colonel")):
            self.m.library[card]=dict(id=card,spell=False,tribes=["Badger"])
            games[0]["seats"][pid]["rounds"][-1]["board"][0]["card"]=card
        games[0]["seats"][2]["rounds"][-1]["hand"]=["spell","bread"]
        def fight(a,b,w):
            return dict(a=a,b=b,winner=w,ghost_of=1 if b==-1 else None,result={"deaths":[3,8],"outnumbered_by":[0,2]})
        games[0]["fights"]=[{"round":13,"fights":[fight(0,2,None),fight(5,-1,-1)]}]
        self.lines("games",games)
        t=tribe_stats(self.m)["red"]
        self.assertEqual(t["fight_win"]["Badger"]["13+"]["count"],3)
        self.assertEqual(t["head_to_head"]["Badger"]["Badger"]["count"],2)
        d=behaviour_stats(self.m)["red"]
        self.assertEqual(d["gleaners"]["1"]["friendly_deaths"]["mean"],3)
        self.assertEqual(d["colonel_win_by_hand_units"]["1"]["rate"],0)
        self.assertEqual(d["colonel_win_by_hand_cards"]["2"]["count"],1)
        self.assertAlmostEqual(d["outnumbered_by"]["mean"],2/3)


    def test_sells_zero_seats_and_observed_eater_opportunities(self):
        for card in ("hopper","granary-glutton","gorger"):
            self.m.library[card]={"tribes":["Locust"],"spell":False}
        options=[{"type":"sell","card":card,"slot":i} for i,card in enumerate(("hopper","granary-glutton","gorger"))]
        sale=dict(game=0,seat=0,colour="red",bot="red",board_n=7,legal=options,chosen=0,result="")
        self.lines("decisions",[sale,{**sale,"result":"refused"},{**sale,"chosen":1}],True)
        result=behaviour_stats(self.m)
        red=result["red"]
        self.assertEqual(red["per_game"]["sells"]["mean"],2/4)
        self.assertEqual(red["per_seat_game"]["sells"]["mean"],2/16)
        self.assertEqual(red["per_seat_game"]["full_board_sells"]["mean"],2/16)
        self.assertEqual(red["per_game"]["sales_with_gorger"]["mean"],2/4)
        self.assertEqual(red["per_game"]["locust_sales_with_glutton"]["mean"],1/4)
        self.assertEqual(result["blue"]["per_game"]["sells"]["mean"],0)
        (self.path/"decisions.jsonl.gz").unlink()
        self.assertNotIn("per_game",behaviour_stats(self.m)["red"])

    def test_measured_slot_growth_and_gorger_marks_exclude_ghosts(self):
        folder=self.path/"records"
        folder.mkdir()
        def player(pid,stats,cards):
            return {"id":pid,"board":cards,"slots":[{"attack":stats,"health":stats}]}
        officer={"def":"colour-sergeant"}
        gorger={"def":"gorger","turn_counters":{"locust_ate":1}}
        for g in range(4):
            rows=[] if g else [
                {"op":"fight_boards","turn":1,"players":[player(0,2,[officer])]},
                {"op":"fight_boards","turn":12,"players":[player(0,3,[officer,gorger]),player(-1,100,[officer])]}]
            (folder/f"game-{g:05}.jsonl").write_text("".join(json.dumps(r)+"\n" for r in rows))
        d=behaviour_stats(self.m)["red"]
        deltas=d["slot_stat_change_by_sergeants"]["colour-sergeant"]
        self.assertEqual((deltas["mean"],deltas["count"]),(3,2)) # +4 then +2
        self.assertEqual(d["surviving_gorgers_marked_ate"]["hits"],1)

    def test_uncompressed_shop_fallback(self):
        (self.path/"shops.jsonl.gz").unlink()
        self.lines("shops",self.shops)
        self.assertEqual(card_stats(self.m)["both"]["bread"]["buy"]["count"],5)

    def test_odd_run_preserves_harness_pair_weighted_score(self):
        manifest=self.m.summary
        manifest["games"]=3
        manifest["red_avg_place"]=4.75
        a=self.m.read("analysis")
        a["games"]=3
        (self.path/"analysis.json").write_text(json.dumps(a))
        self.assertEqual(self.m.score()["red_avg_place"],4.5)

    def band_match(self, early_counts=(30, 30, 30, 29, 0), early_hits=(27, 27, 27, 0, 0)):
        # The same seats play each tribe on both colours after the swap.
        names = ["Badger", "Briar", "Locust", "Mouse", "Pigeon"]
        library = self.m.read("library")
        library += [dict(id=t, spell=False, tribes=[t]) for t in names]
        (self.path / "library.json").write_text(json.dumps(library))
        games = list(self.m.games())
        shops = []
        for game in games[:2]:
            for pid, (t, n, hits) in enumerate(zip(names, early_counts, early_hits)):
                seat = game["seats"][pid]
                seat["main_tribe"] = t
                seat["final_board"] = [unit(t, i) for i in range(4)]
                seat["rounds"][-1].update(board=seat["final_board"], tribes={t: 4})
                for rd, count, buys in ((1, n, hits), (12, 30, 0)):
                    shops.extend(shop(game["game"], pid, seat["colour"], rd, [("bread", True)],
                                      ["bread"] if i < buys else []) for i in range(count))
        self.lines("games", games)
        self.lines("shops", shops, True)
        self.lines("reports", [])
        return Match(self.path)

    def test_early_band_verdict_survives_late_decline(self):
        from cards import cards_markdown
        match = self.band_match()
        data = card_stats(match)
        d = data["red"]["bread"]
        self.assertTrue(d["always_bought_in_band"]["1-3"])
        self.assertFalse(d["always_bought"])
        self.assertFalse(d["never_bought"])
        self.assertIn("90.0% (27/30)", cards_markdown(data, match.tribes))

    def test_band_names_tribes_with_29_or_zero_shops(self):
        # Each of the first three tribes buys 27/30. The fourth skips all 29.
        d = card_stats(self.band_match(), ("red",))["red"]["bread"]
        e = d["band_evidence"]["1-3"]
        self.assertEqual(e["excluded_tribes"], ["Mouse", "Pigeon"])
        self.assertEqual(e["minimum_rate"], .9)
        self.assertEqual(e["by_final_tribe"]["Mouse"]["count"], 29)
        self.assertEqual(e["by_final_tribe"]["Mouse"]["rate"], 0)
        self.assertIsNone(e["by_final_tribe"]["Pigeon"]["rate"])

    def test_two_sampled_tribes_do_not_rank_or_qualify(self):
        from cards import high_everywhere
        m = self.band_match((30, 30, 29, 0, 0), (30, 30, 29, 0, 0))
        d = card_stats(m, ("red",))["red"]
        self.assertFalse(d["bread"]["always_bought_in_band"]["1-3"])
        self.assertIsNone(d["bread"]["band_evidence"]["1-3"]["minimum_rate"])
        self.assertNotIn("bread", high_everywhere(d, "1-3"))

    def test_band_always_threshold_is_strict(self):
        d = card_stats(self.band_match(early_hits=(24, 27, 27, 0, 0)), ("red",))["red"]["bread"]
        self.assertFalse(d["always_bought_in_band"]["1-3"])  # one qualifying tribe at exactly 80%

    def test_band_agreement_is_independent_of_pooled_verdict(self):
        from agree import agreement
        match = self.band_match()
        d = agreement(match)
        # Pooled Mouse has 0/58, but each team's Mouse has only 29 opportunities.
        self.assertFalse(card_stats(match, ("both",))["both"]["bread"]["always_bought_in_band"]["1-3"])
        for team in ("red", "blue"):
            evidence = d["both_always_in_band"]["1-3"]["bread"][team]
            self.assertEqual(evidence["excluded_tribes"], ["Mouse", "Pigeon"])
        shops = list(match.rows("shops"))
        for row in shops:
            if row["colour"] == "blue" and row["round"] == 1:
                row["bought"] = []
        self.lines("shops", shops, True)
        self.assertNotIn("bread", agreement(match)["both_always_in_band"]["1-3"])

    def test_pooled_band_rows_flag_only_above_ninety_percent(self):
        from cards import cards_markdown
        match = self.band_match((30, 30, 30, 0, 0), (27, 27, 27, 0, 0))
        shops = list(match.rows("shops"))
        early_blue = [s for s in shops if s["round"] == 1 and s["colour"] == "blue"]
        other = [s for s in shops if s["round"] != 1 or s["colour"] != "blue"]
        for blue_count, flagged in ((10, None), (9, "red"), (0, "red")):
            with self.subTest(blue=blue_count):
                self.lines("shops", sorted(other + early_blue[:blue_count], key=lambda s: s["game"]), True)
                stats = card_stats(match)
                card = stats["both"]["bread"]
                self.assertTrue(card["always_bought_in_band"]["1-3"])
                shares = card["band_evidence"]["1-3"]["team_share"]
                self.assertEqual(shares["red"], {"count": 90, "share": 90 / (90 + blue_count)})
                self.assertEqual(shares["blue"], {"count": blue_count, "share": blue_count / (90 + blue_count)})
                self.assertEqual(shares["over_90_percent"], flagged)
                self.assertIsNone(card["band_evidence"]["13+"]["team_share"]["red"]["share"])
                self.assertNotIn("team_share", stats["red"]["bread"]["band_evidence"]["1-3"])
                band_text = cards_markdown(stats, match.tribes).split("## Rounds 1-3\n")[1].split("### High everywhere · red")[0]
                for prefix in ("| both | bread |", "| bread |"):
                    row = next(line for line in band_text.splitlines() if line.startswith(prefix))
                    self.assertIn(f"({blue_count}/{90 + blue_count})", row)
                    self.assertEqual("**red >90%**" in row, bool(flagged))

    def test_pooled_all_round_shares_follow_verdict_denominators(self):
        # Seat 0 was red in game 0. Its three eligible shops now have no final tribe.
        games = list(self.m.games())
        seat = games[0]["seats"][0]
        seat["main_tribe"] = None
        seat["final_board"] = []
        seat["rounds"][-1].update(board=[], tribes={})
        self.lines("games", games)
        stats = card_stats(self.m, ("both",))["both"]["bread"]
        shares = stats["team_share"]
        self.assertEqual(shares["never_bought"]["red"], {"count": 4, "share": 4/5})
        for flag in ("always_bought", "always_among_buying_shops"):
            self.assertEqual(shares[flag]["red"], {"count": 1, "share": .5})
        self.assertEqual(stats["band_evidence"]["1-3"]["team_share"]["red"], {"count": 2, "share": 1})
