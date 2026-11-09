#!/usr/bin/env python3
"""Validates the prototype's unit files in content/units/ against docs/prototype/SPEC.md ("Unit files").

Checks every *.json file: required fields and their types, tier 1-6, known mechanic ids with exactly
the parameters the spec lists for them, known tribes, unique ids, and that death_summon names a unit
that exists. The mechanic table here must match the spec's mechanic table.

Usage: python3 tools/checks/check_units.py [units dir]. Exit 0 = all valid, 1 = problems (listed).
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

UNITS_DIR = Path("content/units")
REFERENCE_DIR = Path("content/reference/quilboar")
TRIBES = {"Fairies", "Oozes", "Hedgerow folk", "Hunters", "Birds", "Bog folk", "Hive"}
ROW_HINTS = {"front", "back", None}
SOURCE_KINDS = {"library", "filler", "token", "slice"}
FAST_ACTIONS = {"refresh", "buy", "sell"}

# The one list of triggers, selectors, conditions, effects and mechanic parameters.
# Kinds: "number" doubles on golden, "threshold" keeps its value, "unit" is a unit id, "tribe" a tribe
# name, "action" a Fast action, "bool" a flag.
SCHEMA_PATH = Path("content/schema/effects.json")
SCHEMA: dict = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
MECHANICS: dict[str, dict[str, str]] = SCHEMA["mechanics"]
EFFECT_KEYS = {"id", "name", "trigger", "subject", "subject_tribe", "if", "target", "do", "every", "counter"}
EFFECT_KEYS |= {"count_amount", "limit", "once", "lifetime"}
SELECTOR_KEYS = {"select", "of", "tribe", "not_tribe", "other", "golden", "tier_at_most", "pick", "count", "row"}
PER_WORDS = {"gold", "tier", "hand", "amount", "carried", "empty_adjacent"}
SUMMON_PLACES = {"behind", "behind_or_nearest", "empty_rings", "subject_slot"}
CARD_SETS = {"slice"}
KEYWORDS: dict[str, str] = SCHEMA["keywords"]
PICKS = {"first", "random", "highest_attack", "lowest_attack", "highest_health", "lowest_health", "biggest"}
SUBJECTS = {"self", "other", "any"}
# A number that appears in rules text may be written as a word.
NUMBER_WORDS = {1: {"1", "a", "an", "one"}, 2: {"2", "two", "twice"}, 3: {"3", "three"}, 4: {"4", "four"}}

# Field -> allowed Python types (None means JSON null is allowed).
FIELDS: dict[str, tuple[type | None, ...]] = {
    "id": (str,),
    "name": (str,),
    "tier": (int,),
    "attack": (int,),
    "health": (int,),
    "tribes": (list,),
    "text": (str,),
    "golden_text": (str,),
    "mechanics": (list,),
    "keywords": (list,),
    "row_hint": (str, None),
    "pool": (bool,),
    "priority": (int, None),
    "skeleton": (bool,),
    "source": (dict,),
}


# details / golden_details: rulings kept off the card, shown on the details panel's second layer
# (docs/ideation/wording-guide.md).
OPTIONAL_FIELDS = {
    "sample",
    "set",
    "turns_goal",
    "turns_repeat",
    "permanent_buff_cap",
    "details",
    "golden_details",
    "mechanic_text",
    "overlay_text",
}


def type_ok(value: object, allowed: tuple[type | None, ...]) -> bool:
    if value is None:
        return None in allowed
    if isinstance(value, bool) and bool not in allowed:
        return False
    return any(t is not None and isinstance(value, t) for t in allowed)


# Parameter kinds check_param can judge alone (the rest are checked where they're used).
PARAM_KINDS = {"number", "threshold", "bool", "tribe", "action", "unit", "selector", "tier_cap", "ratio"}


def check_param(kind: str, value: object) -> str | None:
    if kind == "string":
        return None if isinstance(value, str) and value else "must be non-empty text"
    if kind == "ratio":
        ok = isinstance(value, int) and not isinstance(value, bool) and value >= 0
        return None if ok else "must be a non-negative integer"
    if kind == "tier_cap":
        return None if value in ("tier", "tier_plus_2") else check_param("threshold", value)
    if kind in {"number", "threshold"}:
        ok = isinstance(value, int) and not isinstance(value, bool) and value >= 1
        return None if ok else "must be an integer of at least 1"
    if kind == "selector":
        return None if isinstance(value, str) and value in SCHEMA["selectors"] else "must name a known selector"
    if kind == "bool":
        return None if isinstance(value, bool) else "must be true or false"
    if kind == "tribe":
        return None if value in TRIBES else f"unknown tribe {value!r}"
    if kind == "action":
        return None if value in FAST_ACTIONS else f"must be one of {sorted(FAST_ACTIONS)}"
    if kind == "unit":
        return None if isinstance(value, str) and value else "must be a unit id"
    return f"unknown parameter kind {kind}"


def check_unit(path: Path, unit: object) -> list[str]:
    if not isinstance(unit, dict):
        return [f"{path.name}: top level must be an object"]
    reference = path.resolve().parent == (REFERENCE_DIR / "units").resolve()
    problems: list[str] = []
    for field, allowed in FIELDS.items():
        if field not in unit:
            problems.append(f"{path.name}: missing field '{field}'")
        elif not type_ok(unit[field], allowed):
            problems.append(f"{path.name}: field '{field}' has the wrong type")
    for field in unit:
        optional_fields = OPTIONAL_FIELDS | ({"modes", "tags"} if reference else set())
        if field not in FIELDS and field not in optional_fields:
            problems.append(f"{path.name}: unknown field '{field}'")
    if problems:
        return problems
    if unit["id"] != path.stem:
        problems.append(f"{path.name}: id '{unit['id']}' must match the file name")
    if not 1 <= unit["tier"] <= 6:
        problems.append(f"{path.name}: tier {unit['tier']} is outside 1-6")
    if unit["attack"] < 0 or unit["health"] < 1:
        problems.append(f"{path.name}: attack must be >= 0 and health >= 1")
    tribes = TRIBES | ({"quilboar"} if reference else set())
    problems += [f"{path.name}: unknown tribe {t!r}" for t in unit["tribes"] if t not in tribes]
    problems += check_reference_namespace(path, unit, reference)
    if reference:
        problems += check_modes(unit)
    if unit["row_hint"] not in ROW_HINTS:
        problems.append(f"{path.name}: row_hint must be front, back or null")
    if unit["source"].get("kind") not in SOURCE_KINDS:
        problems.append(f"{path.name}: source.kind must be one of {sorted(SOURCE_KINDS)}")
    if unit["source"].get("kind") == "library" and not isinstance(unit["source"].get("entry"), int):
        problems.append(f"{path.name}: a library unit needs source.entry (the library entry number)")
    for field in ("details", "golden_details"):
        if field in unit and (not isinstance(unit[field], str) or not unit[field]):
            problems.append(f"{path.name}: {field} must be non-empty text")
    if "permanent_buff_cap" in unit:
        problem = check_param("threshold", unit["permanent_buff_cap"])
        if problem:
            problems.append(f"{path.name}: permanent_buff_cap {problem}")
    for mech in unit["mechanics"]:
        problems += [f"{path.name}: {p}" for p in check_mechanic(mech)]
    problems += [f"{path.name}: {p}" for p in check_mechanic_text(unit)]
    problems += check_set(path.name, unit)
    problems += check_overlay_text(unit)
    if not problems:
        problems += check_golden_text(path.name, unit)
    return problems


def check_overlay_text(card: dict) -> list[str]:
    """Authored display-only wording for semantic changes generic removal cannot express."""
    if "overlay_text" not in card:
        return []
    branches = card["overlay_text"]
    if not isinstance(branches, dict) or not branches:
        return ["overlay_text must map size/rate/both to text fragments"]
    problems = []
    for key, fragments in branches.items():
        if key not in {"size", "rate", "both"}:
            problems.append(f"overlay_text has unknown combination {key!r}")
        if not isinstance(fragments, dict) or not fragments:
            problems.append(f"overlay_text {key} must contain text fragments")
            continue
        for field, words in fragments.items():
            if field not in {"text", "golden_text", "details", "golden_details"}:
                problems.append(f"overlay_text {key} cannot replace {field!r}")
            if not isinstance(words, str) or not words:
                problems.append(f"overlay_text {key} {field} must be non-empty text")
    return problems


def can_lend(entry: dict) -> bool:
    """The same exclusions as RecruitUnit._can_lend: display metadata never changes this choice."""
    return entry.get("id") not in {"belly", "belly_discount", "fly_south", "shy", "borrows_text"} and entry.get(
        "trigger"
    ) not in {"on_play", "on_sell", "on_home"}


def check_mechanic_text(card: dict) -> list[str]:
    """Mixed cards bind each borrowed fragment to its actual mechanic, never to parsed prose."""
    entries = card["mechanics"]
    lendable = {str(index) for index, entry in enumerate(entries) if isinstance(entry, dict) and can_lend(entry)}
    mixed = bool(lendable) and len(lendable) != len(entries)
    fragments = card.get("mechanic_text", {})
    if not isinstance(fragments, dict):
        return ["mechanic_text must map mechanic indexes to rules fragments"]
    expected = lendable if mixed else set()
    if set(fragments) != expected:
        return [f"mechanic_text needs exactly the mixed card's borrowed indexes: {sorted(expected)}"]
    problems: list[str] = []
    for index, fragment in fragments.items():
        if not isinstance(fragment, dict):
            problems.append(f"mechanic_text {index} must be a rules fragment")
            continue
        entry = entries[int(index)]
        fields = {"id", "text", "golden_text"} | ({"trigger"} if "trigger" in entry else set())
        if set(fragment) != fields:
            problems.append(f"mechanic_text {index} needs exactly {sorted(fields)}")
        if fragment.get("id") != entry.get("id") or fragment.get("trigger") != entry.get("trigger"):
            problems.append(f"mechanic_text {index} must match that mechanic's id and trigger")
        for key in ("text", "golden_text"):
            if not isinstance(fragment.get(key), str) or not fragment[key].strip():
                problems.append(f"mechanic_text {index} {key} must be non-empty text")
    return problems


def check_set(name: str, card: dict) -> list[str]:
    """A card of a set says which, and every keyword it shows has a reminder in the schema."""
    if "set" not in card:
        return []
    problems = [] if card["set"] in CARD_SETS else [f"{name}: unknown set {card['set']!r}"]
    keywords = card.get("keywords", [])
    return problems + [
        f"{name}: keyword {word!r} has no reminder in the schema" for word in keywords if word not in KEYWORDS
    ]


def phase_fits(what: str, phase: str, kind: str, name: str, trigger: str) -> list[str]:
    """An entry usable in one phase can't sit on a trigger of the other phase."""
    fits = phase in {"both", what} or what == "both"
    return [] if fits else [f"{kind} '{name}' is for the {phase} phase; trigger '{trigger}' isn't"]


def check_selector(spec: object, phase: str, trigger: str) -> list[str]:
    if not isinstance(spec, dict):
        return ["a target must be an object"]
    problems = [f"unknown target field '{key}'" for key in spec if key not in SELECTOR_KEYS]
    name = spec.get("select", "self")
    entry = SCHEMA["selectors"].get(name)
    if entry is None:
        return [*problems, f"unknown selector {name!r}"]
    problems += phase_fits(entry["phase"], phase, "selector", name, trigger)
    if "pick" in spec and spec["pick"] not in PICKS:
        problems.append(f"unknown pick {spec['pick']!r}")
    return problems


def check_conditions(conditions: object, phase: str, trigger: str) -> list[str]:
    if not isinstance(conditions, list):
        return ["'if' must be a list"]
    problems: list[str] = []
    for condition in conditions:
        name = condition.get("kind") if isinstance(condition, dict) else None
        entry = SCHEMA["conditions"].get(name)
        if entry is None:
            problems.append(f"unknown condition {name!r}")
            continue
        problems += phase_fits(entry["phase"], phase, "condition", name, trigger)
        if "target" in condition:
            problems += check_selector(condition["target"], phase, trigger)
    return problems


def steps_of(entry: dict) -> list:
    steps = entry.get("do", [])
    return [steps] if isinstance(steps, dict) else steps


def check_step(step: object, phase: str, trigger: str, default_target: bool) -> list[str]:
    if not isinstance(step, dict):
        return ["each step of 'do' must be an object"]
    name = step.get("effect")
    entry = SCHEMA["effects"].get(name)
    if entry is None:
        return [f"unknown effect {name!r}"]
    problems = phase_fits(entry["phase"], phase, "effect", name, trigger)
    for key in step:
        if key not in {"effect", "target", "per", "per_div", "per_max"} and key not in entry["params"]:
            problems.append(f"effect {name}: unknown parameter '{key}'")
    if "per" in step and not isinstance(step["per"], dict) and step["per"] not in PER_WORDS:
        problems.append(f"effect {name}: 'per' must be a selector or one of {sorted(PER_WORDS)}")
    if name == "stat_fraction":
        if step.get("stat", "both") not in {"attack", "health", "both"}:
            problems.append("effect stat_fraction: unknown stat")
        if step.get("operation", "set") not in {"set", "reduce", "gain"}:
            problems.append("effect stat_fraction: unknown operation")
    if name == "summon" and "at" in step and step["at"] not in SUMMON_PLACES:
        problems.append(f"effect summon: 'at' must be one of {sorted(SUMMON_PLACES)}")
    for key, kind in entry["params"].items():
        # A step's number may be 0 or negative (-1 Attack, a rule's -1); thresholds may not.
        if key in step and kind == "number":
            if not isinstance(step[key], int) or isinstance(step[key], bool):
                problems.append(f"effect {name}: '{key}' must be a whole number")
        elif key in step and kind in PARAM_KINDS and (error := check_param(kind, step[key])):
            problems.append(f"effect {name}: '{key}' {error}")
    if "target" in step:
        problems += check_selector(step["target"], phase, trigger)
    if name == "add_card" and "random" in step:
        problems += check_random_card_filter(step["random"])
        if "card" in step:
            problems.append("effect add_card: choose a fixed card or random filter, not both")
    if name == "rule" and step.get("query") not in SCHEMA["queries"]:
        problems.append(f"effect rule: query must be one of {SCHEMA['queries']}")
    if name in {"grant", "slot_effect"} and "mechanic" in step:
        problems += check_mechanic(step["mechanic"])
    return problems


def check_effect(mech: dict, *, allowed_triggers: set[str] | None = None) -> list[str]:
    """A data effect: {"id": "effect", "trigger", "if"?, "target"?, "do"}."""
    problems = [f"effect: unknown field '{key}'" for key in mech if key not in EFFECT_KEYS]
    trigger = mech.get("trigger")
    entry = SCHEMA["triggers"].get(trigger)
    if entry is None or (allowed_triggers is not None and trigger not in allowed_triggers):
        return [*problems, f"effect: unknown trigger {trigger!r}"]
    phase = entry["phase"]
    if "subject" in mech and mech["subject"] not in SUBJECTS:
        problems.append(f"effect: subject must be one of {sorted(SUBJECTS)}")
    problems += check_conditions(mech.get("if", []), phase, trigger)
    if "target" in mech:
        problems += check_selector(mech["target"], phase, trigger)
    steps = steps_of(mech)
    if not steps:
        problems.append("effect: 'do' needs at least one step")
    for step in steps:
        problems += check_step(step, phase, trigger, "target" in mech)
    return problems


def word_in(number: int, text: str) -> bool:
    """Whether the number appears in rules text as digits, or as a small number word."""
    words = NUMBER_WORDS.get(number, {str(number)})
    found = re.findall(r"[a-z]+|\d+", text.lower())
    return any(word in found for word in words)


def numbers_of(mech: dict) -> list[tuple[str, int]]:
    """The (name, value) pairs of a mechanic entry that double on golden (rulebook 7.3.5)."""
    # Pass 3's factor preserves the originating text's golden strength when stolen. It
    # scales authored rates, rather than representing a number printed on the card.
    if mech.get("id") in {"pass3_bird", "pass3_fairy", "pass3_bog", "pass3_hunter", "reference_quilboar"}:
        return []
    out: list[tuple[str, int]] = []
    if mech.get("id") == "effect":
        for step in steps_of(mech):
            kinds = SCHEMA["effects"].get(step.get("effect"), {}).get("params", {})
            out += [(f"{step['effect']}.{k}", step[k]) for k, kind in kinds.items() if kind == "number" and k in step]
        return out
    kinds = MECHANICS.get(mech.get("id"), {})
    return [(f"{mech['id']}.{k}", mech[k]) for k, kind in kinds.items() if kind == "number" and k in mech]


def check_golden_text(name: str, unit: dict) -> list[str]:
    """Rules text is hand-written: every doubling number must be in it, doubled on the golden card."""
    problems: list[str] = []
    for mech in unit["mechanics"]:
        for label, value in numbers_of(mech):
            if not isinstance(value, int) or value == 0:
                continue
            note = unit["source"].get("note") or ""
            details = unit.get("details", "")
            golden = f"{unit['golden_text']} {unit.get('golden_details', details)}"
            if not word_in(abs(value), f"{unit['text']} {note} {details}"):
                problems.append(f"{name}: {label} is {value}, but the text doesn't say it")
            if not word_in(abs(value) * 2, golden):
                problems.append(f"{name}: {label} doubles to {value * 2}, but golden_text doesn't say it")
    return problems


def check_mechanic(mech: object) -> list[str]:
    if not isinstance(mech, dict) or "id" not in mech:
        return ["each mechanic must be an object with an 'id'"]
    if mech["id"] == "effect":
        return check_effect(mech)
    params = MECHANICS.get(mech["id"])
    if params is None:
        return [f"unknown mechanic id {mech['id']!r}"]
    problems: list[str] = []
    given = {k for k in mech if k != "id"}
    optional = set(SCHEMA.get("optional_mechanic_params", {}).get(mech["id"], []))
    if mech.get("id") == "bitter" and mech.get("pass3") is True:
        optional.update({"n", "once_per_enemy"})
    if "percent" in mech:
        optional.update(SCHEMA.get("mechanic_percent_replaces", {}).get(mech["id"], []))
    choices = set(SCHEMA.get("mechanic_one_of", {}).get(mech["id"], []))
    if choices and not given.intersection(choices):
        problems.append(f"mechanic {mech['id']}: needs one of {sorted(choices)}")
    problems += [f"mechanic {mech['id']}: missing parameter '{p}'" for p in sorted(set(params) - given - optional)]
    problems += [f"mechanic {mech['id']}: unknown parameter '{p}'" for p in sorted(given - set(params))]
    for name, kind in params.items():
        if mech["id"] == "vault" and name == "attack" and mech.get(name) == 0:
            continue
        if name in mech and (error := check_param(kind, mech[name])):
            problems.append(f"mechanic {mech['id']}: '{name}' {error}")
    return problems


CARD_KINDS = {"spell", "item"}
AIMS = {"none", "unit", "tribe_unit", "empty_slot", "any_slot", "front_unit", "back_unit", "shop_unit"}
RULE_OPS = {"add", "set", "min", "max"}


def check_card(path: Path, card: object) -> list[str]:
    """A spell or hand item in content/spells/."""
    if not isinstance(card, dict):
        return ["not a JSON object"]
    out: list[str] = []
    if card.get("id") != path.stem:
        out.append("id doesn't match the file name")
    for field in ("name", "text"):
        if not isinstance(card.get(field), str) or not card.get(field):
            out.append(f"needs a {field}")
    if card.get("kind") not in CARD_KINDS:
        out.append(f"kind must be one of {sorted(CARD_KINDS)}")
    if card.get("aim", "none") not in AIMS:
        out.append(f"aim must be one of {sorted(AIMS)}")
    tier = card.get("tier")
    if not isinstance(tier, int) or not 1 <= tier <= 6:
        out.append("tier must be 1-6")
    if not isinstance(card.get("cost"), int) or card["cost"] < 0:
        out.append("cost must be a whole number, 0 or more")
    entry = {key: card[key] for key in EFFECT_KEYS if key in card}
    reference = path.resolve().parent == (REFERENCE_DIR / "spells").resolve()
    out += check_reference_namespace(path, card, reference)
    if "modes" in card:
        out += check_modes(card)
    # A choice spell resolves its mode steps rather than a separate cast body.
    if not ("modes" in card and entry.get("do") == []):
        out += check_effect({**entry, "trigger": "cast"}, allowed_triggers={"cast"})
    out += check_set(path.name, card)
    out += check_overlay_text(card)
    if "gold_value" in card and (not isinstance(card["gold_value"], int) or card["gold_value"] < 1):
        out.append("gold_value must be a whole number, 1 or more")
    if "combines_into" in card and not (path.parent / f"{card['combines_into']}.json").exists():
        out.append(f"combines_into names unknown card {card['combines_into']!r}")
    return out


def check_hero(path: Path, hero: object) -> list[str]:
    """A hero in content/heroes/."""
    if not isinstance(hero, dict):
        return ["not a JSON object"]
    out: list[str] = []
    if hero.get("id") != path.stem:
        out.append("id doesn't match the file name")
    for field in ("name", "text"):
        if not isinstance(hero.get(field), str) or not hero.get(field):
            out.append(f"needs a {field}")
    power = hero.get("power")
    if not isinstance(power, dict):
        return [*out, "needs a power"]
    kind = power.get("kind")
    if kind == "activated":
        if not isinstance(power.get("cost"), int) or power["cost"] < 0:
            out.append("an activated power needs a cost")
        if power.get("aim", "none") not in AIMS:
            out.append(f"aim must be one of {sorted(AIMS)}")
        entry = {key: power[key] for key in EFFECT_KEYS if key in power}
        out += check_effect({**entry, "trigger": "activated"}, allowed_triggers={"activated"})
    elif kind != "passive":
        out.append("power kind must be passive or activated")
    out += check_set(path.name, hero)
    out += check_overlay_text(hero)
    allowed = {name for name, info in SCHEMA["triggers"].items() if info["phase"] != "combat"}
    allowed |= {"start_of_combat", "on_friendly_death"}
    for entry in power.get("effects", []):
        out += check_effect(entry, allowed_triggers=allowed)
    for rule in power.get("rules", []):
        if rule.get("query") not in SCHEMA["queries"]:
            out.append(f"rule query must be one of {SCHEMA['queries']}")
        if rule.get("op") not in RULE_OPS:
            out.append(f"rule op must be one of {sorted(RULE_OPS)}")
        if not isinstance(rule.get("value"), int):
            out.append("rule value must be a whole number")
        out += check_conditions(rule.get("if", []), "recruit", "rule")
    return out


def check_extra(directory: Path, check) -> list[str]:
    failures: list[str] = []
    for path in sorted(directory.glob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            failures.append(f"{path}: {error}")
            continue
        failures += [f"{path}: {problem}" for problem in check(path, data)]
    return failures


def check_reference_namespace(path: Path, card: dict, reference: bool) -> list[str]:
    """Reference IDs/mechanics belong only to the separately opted-in directory."""
    problems: list[str] = []
    is_qb = str(card.get("id", "")).startswith("qb_")
    native = any(
        isinstance(entry, dict) and entry.get("id") == "reference_quilboar" for entry in card.get("mechanics", [])
    )
    if reference:
        if not is_qb or not path.stem.startswith("qb_"):
            problems.append(f"{path.name}: reference IDs and filenames must start qb_")
        if "tribes" in card and card["tribes"] != ["quilboar"]:
            problems.append(f"{path.name}: reference units must belong only to quilboar")
        if card.get("kind") == "spell" and card.get("scaling_exempt") is not True:
            problems.append(f"{path.name}: reference spells must be scaling_exempt")
        for entry in card.get("mechanics", []):
            if (
                isinstance(entry, dict)
                and entry.get("id") == "reference_quilboar"
                and entry.get("kind") != str(card.get("id", ""))[3:]
            ):
                problems.append(f"{path.name}: native kind must match the reference card ID")
    elif is_qb or native:
        problems.append(f"{path.name}: Quilboar reference content is outside its test-only directory")
    return problems


def check_random_card_filter(value: object) -> list[str]:
    if not isinstance(value, dict) or not value:
        return ["effect add_card: random must be a non-empty filter"]
    problems = [
        f"effect add_card: unknown random filter {key!r}"
        for key in value
        if key not in {"tag", "tribe", "tier_at_most"}
    ]
    if not ({"tag", "tribe"} & value.keys()):
        problems.append("effect add_card: random needs a tag or tribe")
    for key in ("tag", "tribe"):
        if key in value and (not isinstance(value[key], str) or not value[key]):
            problems.append(f"effect add_card: random {key} must be non-empty text")
    if "tribe" in value and value["tribe"] not in TRIBES | {"quilboar"}:
        problems.append(f"effect add_card: unknown random tribe {value['tribe']!r}")
    if "tier_at_most" in value:
        tier = value["tier_at_most"]
        if tier != "tier" and (not isinstance(tier, int) or isinstance(tier, bool) or not 1 <= tier <= 6):
            problems.append("effect add_card: random tier_at_most must be tier or 1-6")
    return problems


def check_modes(card: dict) -> list[str]:
    """Choose One has two explicitly named, recursively checked recruit effects."""
    if "modes" not in card and "tags" not in card:
        return []
    modes = card.get("modes")
    tags = card.get("tags", [])
    problems: list[str] = []
    if not isinstance(tags, list) or not all(isinstance(tag, str) and tag for tag in tags):
        problems.append("choice tags must be a list of non-empty strings")
    elif "choose_one" not in tags:
        problems.append("choice card needs the choose_one tag")
    if not isinstance(modes, list) or len(modes) != 2:
        return [*problems, "Choose One needs exactly two modes"]
    available = 0
    for index, mode in enumerate(modes):
        label = f"mode {index}"
        if not isinstance(mode, dict):
            problems.append(f"{label} must be an object")
            continue
        problems += [
            f"{label}: unknown field {key!r}" for key in mode if key not in {"name", "text", "effects", "unavailable"}
        ]
        for key in ("name", "text"):
            if not isinstance(mode.get(key), str) or not mode[key]:
                problems.append(f"{label}: needs non-empty {key}")
        unavailable = mode.get("unavailable", False)
        if not isinstance(unavailable, bool):
            problems.append(f"{label}: unavailable must be boolean")
        steps = mode.get("effects")
        if not isinstance(steps, list):
            problems.append(f"{label}: effects must be a list")
            continue
        if unavailable:
            if steps:
                problems.append(f"{label}: an unavailable mode must have no effects")
            continue
        available += 1
        if not steps:
            problems.append(f"{label}: needs at least one effect")
        for step in steps:
            problems += [
                f"{label}: {problem}" for problem in check_step(step, "recruit", "on_choose_one_played", False)
            ]
    if not available:
        problems.append("Choose One needs at least one available mode")
    return problems


def check_reference() -> list[str]:
    """Validate reference files in the gate without adding them to the release inventory."""
    problems: list[str] = []
    for directory, checker in ((REFERENCE_DIR / "units", check_unit), (REFERENCE_DIR / "spells", check_card)):
        if not directory.is_dir() or not list(directory.glob("*.json")):
            problems.append(f"{directory}: missing reference content")
        else:
            problems += check_extra(directory, checker)
    return problems


def main(argv: list[str]) -> int:
    units_dir = Path(argv[1]) if len(argv) > 1 else UNITS_DIR
    files = sorted(units_dir.glob("*.json"))
    if units_dir == UNITS_DIR:
        files += sorted((units_dir.parent / "levers").glob("*.json"))
    if not files:
        print(f"check_units: no unit files in {units_dir}")
        return 1
    problems: list[str] = []
    units: dict[str, dict] = {}
    for path in files:
        try:
            unit = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            problems.append(f"{path.name}: invalid JSON ({error})")
            continue
        found = check_unit(path, unit)
        problems += found
        if not found:
            units[unit["id"]] = unit
    for unit in units.values():
        for mech in unit["mechanics"]:
            if mech["id"] == "death_summon" and mech["unit"] not in units:
                problems.append(f"{unit['id']}.json: death_summon names unknown unit {mech['unit']!r}")
    problems += check_extra(units_dir.parent / "spells", check_card)
    problems += check_extra(units_dir.parent / "heroes", check_hero)
    if units_dir == UNITS_DIR:
        problems += check_reference()
    for line in problems:
        print(line)
    pool = [u for u in units.values() if u["pool"]]
    by_tier = [sum(1 for u in pool if u["tier"] == t) for t in range(1, 7)]
    print(f"check_units: {len(files)} files, {len(pool)} pool units by tier {by_tier}, {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
