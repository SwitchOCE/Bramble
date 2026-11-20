//! Direct combat integration tests, independent of session round flow.
use bramble_engine::{
    Array, Dictionary, ToState, Variant,
    core::{
        board::board_geometry::BoardGeometry,
        combat::combat::{Combat, CombatRef},
        rules::game_config::{GameConfig, GameConfigRef},
        units::unit::{Unit, UnitRef},
        util::rng::Rng,
    },
    game::game_content::{GameContent, GameContentRef},
    util::godot_json,
};
use std::{cell::RefCell, path::Path, rc::Rc};
struct Fight {
    content: GameContentRef,
    config: GameConfigRef,
    boards: Array<Array<Option<UnitRef>>>,
}
impl Fight {
    fn new() -> Self {
        let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
        let content = GameContent::load_folders(&root, &Array::new());
        assert!(
            content.borrow().errors.is_empty(),
            "{:?}",
            content.borrow().errors
        );
        Self {
            content,
            config: Rc::new(RefCell::new(GameConfig::new())),
            boards: Array::from(vec![Array::from(vec![None; 7]), Array::from(vec![None; 7])]),
        }
    }
    fn put(&self, side: usize, slot: usize, id: &str) -> UnitRef {
        let c = self.content.borrow();
        let card = c.library.borrow().get_card(id).expect("standin card");
        let u = Unit::create(
            &card,
            (side * 100 + slot + 1) as i64,
            false,
            &c.registry,
            self.config.borrow().stat_max,
        );
        u.borrow_mut().slot = slot as i64;
        self.boards.get(side).unwrap().borrow_mut()[slot] = Some(u.clone());
        u
    }
    fn stats(u: &UnitRef, attack: i64, health: i64) {
        let s = u.borrow().stats.clone().unwrap();
        s.borrow_mut().base_attack = attack;
        s.borrow_mut().base_health = health;
    }
    fn run(&self, seed: i64) -> (Dictionary, CombatRef) {
        let before = godot_json::stringify(&self.boards.to_state());
        let c = self.content.borrow();
        let combat = Combat::create(
            &BoardGeometry::standard(4, 3),
            &self.config,
            &c.registry,
            &c.library,
            seed,
        );
        drop(c);
        let result = combat.borrow_mut().run(
            &self.boards,
            &Array::from(vec![11, 22]),
            &Array::new(),
            &Array::from(vec![false, false]),
            &Array::new(),
        );
        assert_eq!(
            before,
            godot_json::stringify(&self.boards.to_state()),
            "recruit units changed, seed {seed}"
        );
        let es = combat.borrow().events.clone();
        assert_eq!(es.get(0).unwrap().get("type").as_text(), "combat_start");
        let end = es.get(es.len() - 1).unwrap();
        assert_eq!(end.get("type").as_text(), "combat_end");
        let end = end.duplicate();
        end.borrow_mut().shift_remove("type");
        assert_eq!(json(&result), json(&end));
        (result, combat)
    }
}
fn json(d: &Dictionary) -> String {
    godot_json::stringify(&Variant::Dictionary(d.clone()))
}
fn events(c: &CombatRef, kind: &str) -> Vec<Dictionary> {
    c.borrow()
        .events
        .to_vec()
        .into_iter()
        .filter(|e| e.get("type").as_text() == kind)
        .collect()
}
fn exact(r: &Dictionary, s: &str) {
    assert_eq!(
        godot_json::parse_string(&json(r)),
        godot_json::parse_string(s)
    );
}

#[test]
fn omitted_events_preserve_results_triggers_and_rng() {
    let f = Fight::new();
    for side in 0..2 {
        for (slot, id) in ["t5_bomber", "t4_phoenix", "t4_cleaver", "t2_shield"]
            .iter()
            .enumerate()
        {
            f.put(side, slot, id);
        }
    }
    for limit in [0, 1, 1000] {
        f.config.borrow_mut().combat_trigger_limit = limit;
        for seed in 0..20 {
            let (expected, logged) = f.run(seed);
            let c = f.content.borrow();
            let silent = Combat::create(
                &BoardGeometry::standard(4, 3),
                &f.config,
                &c.registry,
                &c.library,
                seed,
            );
            silent.borrow_mut().keep_events = false;
            let actual = silent.borrow_mut().run(
                &f.boards,
                &Array::from(vec![11, 22]),
                &Array::new(),
                &Array::from(vec![false, false]),
                &Array::new(),
            );
            assert_eq!(json(&actual), json(&expected));
            assert!(silent.borrow().events.is_empty());
            assert_eq!(
                godot_json::stringify(&silent.borrow().effect_rng.to_state()),
                godot_json::stringify(&logged.borrow().effect_rng.to_state())
            );
        }
    }
}
#[test]
fn empty_and_one_sided_fights_have_exact_results() {
    let f = Fight::new();
    let (r, _) = f.run(42);
    exact(
        &r,
        r#"{"winner":-1,"reason":"board_empty","starting":[0,0],"killed":[0,0],"attacks":0,"triggers":0,"survivors":[[],[]],"survivor_recruit_uids":[[],[]],"deaths":[0,0],"outnumbered_by":[0,0]}"#,
    );
    f.put(0, 0, "t1_plain");
    let (r, _) = f.run(42);
    exact(
        &r,
        r#"{"winner":0,"reason":"board_empty","starting":[1,0],"killed":[0,0],"attacks":0,"triggers":0,"survivors":[[1],[]],"survivor_recruit_uids":[[1],[]],"deaths":[0,0],"outnumbered_by":[0,1]}"#,
    );
}
#[test]
fn simultaneous_deaths_have_exact_results() {
    let f = Fight::new();
    f.put(0, 0, "t1_plain");
    f.put(1, 0, "t1_plain");
    let (r, c) = f.run(42);
    exact(
        &r,
        r#"{"winner":-1,"reason":"board_empty","starting":[1,1],"killed":[1,1],"attacks":2,"triggers":0,"survivors":[[],[]],"survivor_recruit_uids":[[],[]],"deaths":[1,1],"outnumbered_by":[0,0]}"#,
    );
    assert_eq!(events(&c, "death").len(), 2);
}
#[test]
fn no_attacks_attack_limit_and_trigger_limit_are_distinct_ties() {
    let f = Fight::new();
    let a = f.put(0, 0, "t1_plain");
    let b = f.put(1, 0, "t1_plain");
    Fight::stats(&a, 0, 100);
    Fight::stats(&b, 0, 100);
    let (r, _) = f.run(4);
    assert_eq!(r.get("reason").as_text(), "no_attacks");
    assert_eq!(r.get("attacks").as_i64(), 0);
    assert_eq!(r.get("winner").as_i64(), -1);
    Fight::stats(&a, 1, 100);
    Fight::stats(&b, 1, 100);
    f.config.borrow_mut().attack_limit = 3;
    let (r, _) = f.run(4);
    assert_eq!(r.get("reason").as_text(), "attack_limit");
    assert_eq!(r.get("attacks").as_i64(), 3);
    assert_eq!(r.get("winner").as_i64(), -1);
    let f = Fight::new();
    f.put(0, 0, "t5_bomber");
    f.put(1, 0, "t5_bomber");
    f.config.borrow_mut().combat_trigger_limit = 0;
    let (r, c) = f.run(4);
    assert_eq!(r.get("reason").as_text(), "trigger_limit");
    assert_eq!(r.get("winner").as_i64(), -1);
    assert_eq!(r.get("attacks").as_i64(), 0);
    assert!(events(&c, "damage").is_empty());
}
#[test]
fn shield_prevents_venom_consumption_until_the_next_hit() {
    let f = Fight::new();
    let a = f.put(0, 0, "t3_viper");
    let b = f.put(1, 0, "t2_shield");
    Fight::stats(&a, 1, 100);
    Fight::stats(&b, 0, 100);
    let (r, c) = f.run(1);
    assert_eq!(r.get("attacks").as_i64(), 2);
    assert_eq!(r.get("winner").as_i64(), 0);
    assert_eq!(
        events(&c, "status")
            .iter()
            .map(|e| e.get("status").as_text())
            .collect::<Vec<_>>(),
        ["divine_shield", "venomous"]
    );
    assert_eq!(events(&c, "damage").len(), 1);
    assert_eq!(r.get("triggers").as_i64(), 1);
}
#[test]
fn cleave_selects_one_occupied_neighbour_in_the_target_row() {
    for neighbours in [&[][..], &[2], &[0, 2]] {
        let f = Fight::new();
        f.config.borrow_mut().attack_limit = 1;
        f.put(0, 0, "t4_cleaver");
        Fight::stats(&f.put(1, 1, "t1_guard"), 0, 4);
        Fight::stats(&f.put(1, 4, "t1_plain"), 0, 4);
        for &slot in neighbours {
            Fight::stats(&f.put(1, slot, "t1_plain"), 0, 4);
        }

        for seed in [1, 2] {
            let (r, c) = f.run(seed);
            assert_eq!(r.get("attacks").as_i64(), 1);
            assert_eq!(events(&c, "attack")[0].get("target_slot").as_i64(), 1);

            let expected_rng = Rng::derive(seed, "effect");
            let mut expected_slots = vec![1];
            if !neighbours.is_empty() {
                let index = expected_rng.borrow_mut().index(neighbours.len() as i64);
                expected_slots.push(neighbours[index as usize] as i64);
            }
            let damaged_slots: Vec<_> = events(&c, "damage")
                .iter()
                .map(|event| event.get("slot").as_i64())
                .collect();
            assert_eq!(damaged_slots, expected_slots);
            assert_eq!(
                godot_json::stringify(&c.borrow().effect_rng.to_state()),
                godot_json::stringify(&Some(expected_rng).to_state())
            );
        }
    }
}
#[test]
fn hidden_taunt_is_skipped_and_stealth_reveals_when_attacking() {
    let f = Fight::new();
    Fight::stats(&f.put(0, 0, "t1_plain"), 20, 100);
    let shade = f.put(1, 0, "t4_shade");
    Fight::stats(&shade, 0, 100);
    assert!(
        shade
            .borrow_mut()
            .grant(&f.content.borrow().registry, "taunt")
    );
    Fight::stats(&f.put(1, 1, "t1_plain"), 0, 100);
    f.config.borrow_mut().attack_limit = 1;
    let (_, c) = f.run(1);
    assert_eq!(events(&c, "attack")[0].get("target_slot").as_i64(), 1);
    let f = Fight::new();
    f.put(0, 0, "t4_shade");
    Fight::stats(&f.put(1, 0, "t1_plain"), 0, 100);
    f.config.borrow_mut().attack_limit = 1;
    let (_, c) = f.run(1);
    let statuses = events(&c, "status");
    assert_eq!(statuses.len(), 1);
    assert_eq!(statuses[0].get("status").as_text(), "stealth");
    assert!(matches!(statuses[0].get("on"), Variant::Bool(false)));
}
#[test]
fn windfury_swings_twice_before_the_other_side() {
    let f = Fight::new();
    f.put(0, 0, "t3_twin");
    Fight::stats(&f.put(0, 1, "t1_plain"), 0, 100);
    Fight::stats(&f.put(1, 0, "t1_plain"), 1, 100);
    f.config.borrow_mut().attack_limit = 3;
    let (_, c) = f.run(1);
    assert_eq!(
        events(&c, "attack")
            .iter()
            .map(|e| e.get("side").as_i64())
            .collect::<Vec<_>>(),
        [0, 0, 1]
    );
}
#[test]
fn reborn_returns_only_once_and_counts_one_starting_unit_killed() {
    let f = Fight::new();
    f.put(0, 0, "t4_phoenix");
    Fight::stats(&f.put(1, 0, "t1_plain"), 100, 100);
    let (r, c) = f.run(1);
    let returns = events(&c, "return");
    assert_eq!(returns.len(), 1);
    assert_eq!(returns[0].get("mechanic").as_text(), "reborn");
    assert_eq!(returns[0].get("health").as_i64(), 1);
    assert_eq!(r.get("killed").as_array().get(0).unwrap().as_i64(), 1);
    assert_eq!(r.get("deaths").as_array().get(0).unwrap().as_i64(), 2);
}
#[test]
fn death_summons_do_not_count_as_starting_survivors() {
    let f = Fight::new();
    f.put(0, 0, "t1_seed");
    Fight::stats(&f.put(1, 0, "t1_plain"), 1, 3);
    let (r, c) = f.run(1);
    assert_eq!(events(&c, "summon").len(), 1);
    assert_eq!(r.get("winner").as_i64(), 0);
    assert_eq!(r.get("killed").as_array().get(0).unwrap().as_i64(), 1);
    assert!(
        r.get("survivor_recruit_uids")
            .as_array()
            .get(0)
            .unwrap()
            .as_array()
            .is_empty()
    );
}
#[test]
fn randomized_standin_fights_are_repeatable_and_preserve_recruit_units() {
    let f = Fight::new();
    let cards: Vec<_> = f
        .content
        .borrow()
        .library
        .borrow()
        .drawable_cards(false)
        .to_vec()
        .into_iter()
        .map(|c| c.borrow().id.clone())
        .collect();
    let mut state = 0x5eed_u64;
    let mut next = || {
        state = state
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        state
    };
    for case in 0..250 {
        for side in 0..2 {
            f.boards.get(side).unwrap().borrow_mut().fill(None);
            for slot in 0..7 {
                if next() % 4 != 0 {
                    f.put(side, slot, &cards[next() as usize % cards.len()]);
                }
            }
        }
        let seed = next() as i64;
        let (a, ca) = f.run(seed);
        let (b, cb) = f.run(seed);
        assert_eq!(json(&a), json(&b), "result case {case}, seed {seed}");
        assert_eq!(
            godot_json::stringify(&ca.borrow().events.to_state()),
            godot_json::stringify(&cb.borrow().events.to_state()),
            "events case {case}, seed {seed}"
        );
        assert!(Combat::REASONS.contains(&a.get("reason").as_text().as_str()));
    }
}
