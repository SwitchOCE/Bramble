//! Godot-generated script-variable lists are checked against declarations and serialized keys.
use bramble_engine::{ToState, Variant, core};
use std::{
    collections::BTreeSet,
    path::{Path, PathBuf},
};

fn check<T: ToState>(path: &str, object: T, oracle: &serde_json::Value) {
    let expected: Vec<String> = oracle[path]
        .as_array()
        .unwrap_or_else(|| panic!("missing Godot oracle for {path}"))
        .iter()
        .map(|v| v.as_str().unwrap().to_owned())
        .collect();
    let expected: BTreeSet<_> = expected.into_iter().collect();
    let declared: BTreeSet<_> = T::field_names().iter().map(|v| (*v).to_owned()).collect();
    assert_eq!(
        declared.len(),
        T::field_names().len(),
        "duplicate declared fields in {path}"
    );
    assert_eq!(
        declared, expected,
        "Rust field_names differs from Godot for {path}"
    );
    let Variant::Dictionary(state) = object.script_state() else {
        panic!("script_state must be a dictionary for {path}")
    };
    let serialized: BTreeSet<_> = state.borrow().keys().cloned().collect();
    assert_eq!(
        serialized, expected,
        "Rust script_state keys differ from Godot for {path}"
    );
}

#[test]
fn every_core_script_lists_exactly_godots_script_variables() {
    let oracle: serde_json::Value =
        serde_json::from_str(include_str!("../../gd/core_fields.json")).unwrap();
    check(
        "src/core/board/board_geometry.gd",
        core::board::board_geometry::BoardGeometry::default(),
        &oracle,
    );
    check(
        "src/core/board/selectors.gd",
        core::board::selectors::Selectors::default(),
        &oracle,
    );
    check(
        "src/core/bots/bot.gd",
        core::bots::bot::Bot::default(),
        &oracle,
    );
    check(
        "src/core/bots/random_bot.gd",
        core::bots::random_bot::RandomBot::default(),
        &oracle,
    );
    check(
        "src/core/bots/simple_bot.gd",
        core::bots::simple_bot::SimpleBot::default(),
        &oracle,
    );
    check(
        "src/core/combat/combat.gd",
        core::combat::combat::Combat::default(),
        &oracle,
    );
    check(
        "src/core/combat/combat_unit.gd",
        core::combat::combat_unit::CombatUnit::default(),
        &oracle,
    );
    check(
        "src/core/combat/fight_arrivals.gd",
        core::combat::fight_arrivals::FightArrivals::default(),
        &oracle,
    );
    check(
        "src/core/combat/fight_auras.gd",
        core::combat::fight_auras::FightAuras::default(),
        &oracle,
    );
    check(
        "src/core/combat/fight_deaths.gd",
        core::combat::fight_deaths::FightDeaths::default(),
        &oracle,
    );
    check(
        "src/core/combat/fight_side.gd",
        core::combat::fight_side::FightSide::default(),
        &oracle,
    );
    check(
        "src/core/content/content_set.gd",
        core::content::content_set::ContentSet {
            record_paths: Default::default(),
            registry: core::mechanics::mechanic_registry::MechanicRegistry::with_built_ins(),
            library: std::rc::Rc::new(std::cell::RefCell::new(
                core::units::unit_library::UnitLibrary::default(),
            )),
            display: Default::default(),
            standing: Default::default(),
            folders: Default::default(),
            errors: Default::default(),
        },
        &oracle,
    );
    check(
        "src/core/mechanics/bound_mechanic.gd",
        core::mechanics::bound_mechanic::BoundMechanic {
            id: String::new(),
            mechanic: Some(std::rc::Rc::new(core::mechanics::mechanic::BaseMechanic)),
            params: core::mechanics::mechanic_params::MechanicParams::new(),
            granted: false,
        },
        &oracle,
    );
    check(
        "src/core/mechanics/effects/attacked_gain.gd",
        core::mechanics::effects::attacked_gain::AttackedGain,
        &oracle,
    );
    check(
        "src/core/mechanics/effects/aura_attack.gd",
        core::mechanics::effects::aura_attack::AuraAttack,
        &oracle,
    );
    check(
        "src/core/mechanics/effects/avenge_buff.gd",
        core::mechanics::effects::avenge_buff::AvengeBuff,
        &oracle,
    );
    check(
        "src/core/mechanics/effects/death_summon.gd",
        core::mechanics::effects::death_summon::DeathSummon,
        &oracle,
    );
    check(
        "src/core/mechanics/effects/discover.gd",
        core::mechanics::effects::discover::Discover,
        &oracle,
    );
    check(
        "src/core/mechanics/effects/end_turn_buff.gd",
        core::mechanics::effects::end_turn_buff::EndTurnBuff,
        &oracle,
    );
    check(
        "src/core/mechanics/effects/kill_gain.gd",
        core::mechanics::effects::kill_gain::KillGain,
        &oracle,
    );
    check(
        "src/core/mechanics/effects/play_buff.gd",
        core::mechanics::effects::play_buff::PlayBuff,
        &oracle,
    );
    check(
        "src/core/mechanics/effects/rally_gain.gd",
        core::mechanics::effects::rally_gain::RallyGain,
        &oracle,
    );
    check(
        "src/core/mechanics/effects/sell_bonus.gd",
        core::mechanics::effects::sell_bonus::SellBonus,
        &oracle,
    );
    check(
        "src/core/mechanics/effects/start_combat_damage.gd",
        core::mechanics::effects::start_combat_damage::StartCombatDamage,
        &oracle,
    );
    check(
        "src/core/mechanics/effects/start_turn_gold.gd",
        core::mechanics::effects::start_turn_gold::StartTurnGold,
        &oracle,
    );
    check(
        "src/core/mechanics/effects/triple_reward.gd",
        core::mechanics::effects::triple_reward::TripleReward,
        &oracle,
    );
    check(
        "src/core/mechanics/keywords/cleave.gd",
        core::mechanics::keywords::cleave::Cleave,
        &oracle,
    );
    check(
        "src/core/mechanics/keywords/divine_shield.gd",
        core::mechanics::keywords::divine_shield::DivineShield,
        &oracle,
    );
    check(
        "src/core/mechanics/keywords/reborn.gd",
        core::mechanics::keywords::reborn::Reborn,
        &oracle,
    );
    check(
        "src/core/mechanics/keywords/stealth.gd",
        core::mechanics::keywords::stealth::Stealth,
        &oracle,
    );
    check(
        "src/core/mechanics/keywords/taunt.gd",
        core::mechanics::keywords::taunt::Taunt,
        &oracle,
    );
    check(
        "src/core/mechanics/keywords/venomous.gd",
        core::mechanics::keywords::venomous::Venomous,
        &oracle,
    );
    check(
        "src/core/mechanics/keywords/windfury.gd",
        core::mechanics::keywords::windfury::Windfury,
        &oracle,
    );
    check(
        "src/core/mechanics/mechanic.gd",
        core::mechanics::mechanic::BaseMechanic,
        &oracle,
    );
    check(
        "src/core/mechanics/mechanic_params.gd",
        core::mechanics::mechanic_params::MechanicParams::default(),
        &oracle,
    );
    check(
        "src/core/mechanics/mechanic_registry.gd",
        core::mechanics::mechanic_registry::MechanicRegistry::default(),
        &oracle,
    );
    check(
        "src/core/mechanics/mechanic_spec.gd",
        core::mechanics::mechanic_spec::MechanicSpec::default(),
        &oracle,
    );
    check(
        "src/core/records/fight_snapshot.gd",
        core::records::fight_snapshot::FightSnapshot,
        &oracle,
    );
    check(
        "src/core/records/game_record.gd",
        core::records::game_record::GameRecord::default(),
        &oracle,
    );
    check(
        "src/core/records/record_build.gd",
        core::records::record_build::RecordBuild::default(),
        &oracle,
    );
    check(
        "src/core/records/record_replay.gd",
        core::records::record_replay::RecordReplay,
        &oracle,
    );
    check(
        "src/core/records/record_state.gd",
        core::records::record_state::RecordState,
        &oracle,
    );
    check(
        "src/core/recruit/legal_actions.gd",
        core::recruit::legal_actions::LegalActions,
        &oracle,
    );
    check(
        "src/core/recruit/player_state.gd",
        core::recruit::player_state::PlayerState::default(),
        &oracle,
    );
    check(
        "src/core/recruit/recruit.gd",
        core::recruit::recruit::Recruit::new(&std::rc::Rc::new(std::cell::RefCell::new(
            core::session::game_session::GameSession::default(),
        ))),
        &oracle,
    );
    check(
        "src/core/recruit/recruit_context.gd",
        core::recruit::recruit_context::RecruitContext::default(),
        &oracle,
    );
    check(
        "src/core/rules/game_config.gd",
        core::rules::game_config::GameConfig::default(),
        &oracle,
    );
    check(
        "src/core/rules/rules.gd",
        core::rules::rules::Rules::new(&std::rc::Rc::new(std::cell::RefCell::new(
            core::rules::game_config::GameConfig::default(),
        ))),
        &oracle,
    );
    check(
        "src/core/session/game_session.gd",
        core::session::game_session::GameSession::default(),
        &oracle,
    );
    check(
        "src/core/session/matchmaking.gd",
        core::session::matchmaking::Matchmaking,
        &oracle,
    );
    check(
        "src/core/state/aura_context.gd",
        core::state::aura_context::AuraContext::default(),
        &oracle,
    );
    check(
        "src/core/state/card_heap.gd",
        core::state::card_heap::CardHeap::default(),
        &oracle,
    );
    check(
        "src/core/state/fight_report.gd",
        core::state::fight_report::FightReport::default(),
        &oracle,
    );
    check(
        "src/core/state/slot_state.gd",
        core::state::slot_state::SlotState::default(),
        &oracle,
    );
    check(
        "src/core/units/shop_odds.gd",
        core::units::shop_odds::ShopOdds::default(),
        &oracle,
    );
    check(
        "src/core/units/stat_block.gd",
        core::units::stat_block::StatBlock::default(),
        &oracle,
    );
    check(
        "src/core/units/unit.gd",
        core::units::unit::Unit::default(),
        &oracle,
    );
    check(
        "src/core/units/unit_def.gd",
        core::units::unit_def::UnitDef::default(),
        &oracle,
    );
    check(
        "src/core/units/unit_library.gd",
        core::units::unit_library::UnitLibrary::default(),
        &oracle,
    );
    check(
        "src/core/units/unit_text.gd",
        core::units::unit_text::UnitText::default(),
        &oracle,
    );
    check(
        "src/core/util/core_util.gd",
        core::util::core_util::CoreUtil,
        &oracle,
    );
    check(
        "src/core/util/rng.gd",
        core::util::rng::Rng::default(),
        &oracle,
    );
    assert_eq!(oracle.as_object().unwrap().len(), 62);
}

fn collect_scripts(path: &Path, out: &mut Vec<PathBuf>) {
    for entry in std::fs::read_dir(path).unwrap() {
        let entry = entry.unwrap();
        let path = entry.path();
        if path.is_dir() {
            collect_scripts(&path, out);
        } else if path.extension().is_some_and(|extension| extension == "gd") {
            out.push(path);
        }
    }
}

#[test]
fn every_core_script_and_function_has_a_rust_counterpart() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
    let mut paths = Vec::new();
    collect_scripts(&root.join("src/core"), &mut paths);
    let oracle: serde_json::Value =
        serde_json::from_str(include_str!("../../gd/core_fields.json")).unwrap();
    let mut function_count = 0;
    for path in &paths {
        let relative = path.strip_prefix(&root).unwrap();
        let name = relative.to_string_lossy();
        assert!(
            oracle.get(name.as_ref()).is_some(),
            "new core script requires a Godot field oracle: {name}"
        );
        let rust = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join(relative)
            .with_extension("rs");
        let rust_text = std::fs::read_to_string(&rust)
            .unwrap_or_else(|error| panic!("{}: {error}", rust.display()));
        let gd_text = std::fs::read_to_string(path).unwrap();
        for line in gd_text.lines() {
            let Some(function) = line
                .strip_prefix("func ")
                .or_else(|| line.strip_prefix("static func "))
            else {
                continue;
            };
            let function = function.split('(').next().unwrap();
            let function = if function == "_init" { "new" } else { function };
            assert!(
                (rust_text.contains(&format!("fn {function}("))
                    || rust_text.contains(&format!("fn {function}<"))),
                "missing {name}:{function} signature"
            );
            function_count += 1;
        }
    }
    assert_eq!(paths.len(), oracle.as_object().unwrap().len());
    assert!(
        function_count >= 350,
        "unexpectedly few core functions: {function_count}"
    );
    eprintln!(
        "core source coverage: {} files, {} functions",
        paths.len(),
        function_count
    );
}
