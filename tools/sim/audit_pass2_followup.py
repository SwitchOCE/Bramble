#!/usr/bin/env python3
"""Check the constructed follow-up fixtures' arithmetic, inventory and stat receipts.

This is a static audit, not an action replay or a shop-probability calculation.
Run from any working directory: python3 tools/sim/audit_pass2_followup.py
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = ROOT / "docs/ideation/evidence/pass2-followup-boards.json"


def card(unit_id):
    return json.loads((ROOT / "content/units" / f"{unit_id}.json").read_text())


def inventory(board):
    def visit(path, spec):
        if spec is None:
            return
        yield path, spec
        for index, inner in enumerate(spec.get("held", [])):
            yield from visit(f"{path}/held/{index}", inner)

    for path, spec in board["slots"].items():
        yield from visit(path, spec)
    for entry in board.get("away", []):
        yield from visit("away:" + entry["unit"]["def_id"], entry["unit"])


def main():
    data = json.loads(FIXTURES.read_text())
    assert len(data["boards"]) == 12
    assert len({b["id"] for b in data["boards"]}) == 12
    for roll in ("high", "low"):
        assert sum(b["roll"] == roll for b in data["boards"]) == 6
    for board in data["boards"]:
        label = board["id"]
        specs = dict(inventory(board))
        receipts = {r["path"]: r for r in board["stat_receipts"]}
        assert specs.keys() == receipts.keys(), label
        copies = 0
        for path, spec in specs.items():
            definition = card(spec["def_id"])
            assert definition["tier"] <= board["tier"] <= 5, (label, path)
            factor = 2 if spec.get("golden") else 1
            receipt = receipts[path]
            assert receipt["unit"] == spec["def_id"], (label, path)
            assert receipt["printed"] == [definition[k] * factor for k in ("attack", "health")]
            expected = [
                receipt["printed"][axis] + sum(layer[key] for layer in receipt["layers"])
                for axis, key in enumerate(("attack", "health"))
            ]
            assert expected == receipt["effective"] == [spec["attack"], spec["health"]], (label, path)
            assert len(spec.get("held", [])) <= max(
                (m.get("size", 0) for m in definition["mechanics"] if m["id"] == "belly"),
                default=0,
            ), (label, path)
            if definition.get("pool"):
                copies += 3 if spec.get("golden") else 1
            if any(m["id"] == "shy" for m in definition["mechanics"]):
                assert expected == receipt["printed"], (label, path, "unearned Shy growth")
        ledger = board["economy_ledger"]
        extra_bought = 3 if label == "fairies_high" else 1 if label == "fairies_low" else 0
        assert ledger["bought_copies_retained_or_historically_required"] == copies + extra_bought, label
        temporary = ledger["temporary_bought_and_sold_copies"]
        for unit_id in temporary:
            assert card(unit_id)["pool"] and card(unit_id)["tier"] == 1
        assert ledger["unit_buys_gold"] == (copies + extra_bought + len(temporary)) * 3, label
        assert ledger["bought_unit_sale_gold"] == len(temporary) + (label == "fairies_low"), label
        assert ledger["refresh_gold"] == ledger["refresh_count"], label
        assert ledger["discount_gold"] == 0, label
        expected_climbs = [2, 4, 6, 8] if board["roll"] == "high" else [3, 6, 8]
        assert ledger["climb_rounds"] == expected_climbs, label
        assert ledger["upgrade_gold"] == (24 if board["roll"] == "high" else 13), label
        for spell in ledger["spells"]:
            definition = json.loads((ROOT / "content/spells" / f"{spell['id']}.json").read_text())
            assert spell["unit_cost"] == definition["cost"], label
            assert spell["gold"] == spell["count"] * spell["unit_cost"], label
        spent = sum(ledger[k] for k in ("unit_buys_gold", "upgrade_gold", "refresh_gold"))
        spent += sum(s["gold"] for s in ledger["spells"])
        spent -= ledger["bought_unit_sale_gold"] + ledger["discount_gold"]
        assert spent == ledger["net_spend_gold"] and 59 <= spent <= 65, label
        total_income = 62 + sum(r["gold"] for r in ledger["extra_income_receipts"])
        assert ledger["closing_bank_from_listed_income"] == total_income - spent >= 0, label
        supper = sum(s["count"] for s in ledger["spells"] if s["id"] == "harvest_supper")
        expected_supper = 2 if board["roll"] == "high" else 0
        assert supper == expected_supper, label
        assert board.get("tribe_bonuses", {}).get(board["tribe"], 0) == expected_supper, label
        assert board["growth_layer"], label
        if board["roll"] == "low":
            assert sum(board["pinch_targets"].values()) == 8, label
        print(f"{label}: {len(specs)} bodies; {spent} net gold; {supper} Suppers; receipts match")
    toad = next(b for b in data["boards"] if b["id"] == "bog_low")["slots"]["F1"]
    assert (toad["attack"], toad["health"]) == (4, 6)
    print("PASS: all 12 fixture inventories, gold ledgers and stat receipts agree.")


if __name__ == "__main__":
    main()
