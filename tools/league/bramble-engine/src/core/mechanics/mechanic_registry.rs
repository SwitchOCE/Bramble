//! Mechanic id -> its shared, stateless script instance. Registration never replaces ids.
use super::{
    bound_mechanic::{BoundMechanic, BoundMechanicRef},
    mechanic::{Mechanic, combine},
    mechanic_params::MechanicParams,
    mechanic_spec::{MechanicSpec, MechanicSpecRef},
};
use crate::core::util::core_util::CoreUtil;
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};

#[derive(Clone, Default)]
pub struct MechanicRegistry {
    pub errors: Array<String>,
    pub prefixes: Array<String>,
    pub _named: Dictionary<bool>,
    pub _scripts: Dictionary<Rc<dyn Mechanic>>,
}
pub type MechanicRegistryRef = Rc<RefCell<MechanicRegistry>>;
impl MechanicRegistry {
    pub fn new() -> MechanicRegistryRef {
        Rc::new(RefCell::new(Self::default()))
    }
    pub fn with_built_ins() -> MechanicRegistryRef {
        let registry = Self::new();
        for (id, script) in built_ins() {
            registry.borrow_mut().register(id, script);
        }
        registry
    }
    pub fn register(&mut self, mechanic_id: &str, mechanic: Rc<dyn Mechanic>) -> bool {
        if self._scripts.borrow().contains_key(mechanic_id) {
            self.errors
                .push(format!("mechanic id {mechanic_id} is registered twice"));
            return false;
        }
        self._scripts
            .borrow_mut()
            .insert(mechanic_id.to_owned(), mechanic);
        true
    }
    /// Aura grants combine in insertion order. Only integer grants add, as TYPE_INT in Godot.
    pub fn bind_grants(&self, grants: &Array<Variant>) -> Array<BoundMechanicRef> {
        let merged: Dictionary<Dictionary> = Dictionary::new();
        for value in grants.borrow().iter() {
            let Variant::Dictionary(grant) = value else {
                panic!("bind_grants requires Dictionary entries")
            };
            let mechanic_id = grant.get_or("mechanic", Variant::from("")).as_text();
            if !self.has(&mechanic_id) {
                continue;
            }
            let raw = merged
                .borrow()
                .get(&mechanic_id)
                .cloned()
                .unwrap_or_default();
            for (key, amount) in grant.borrow().iter() {
                if key == "mechanic" {
                    continue;
                }
                if matches!(amount, Variant::Int(_)) && raw.has(key) {
                    let had = CoreUtil::to_int(&raw.get(key));
                    let now = CoreUtil::to_int(amount);
                    let mechanic = self
                        .get_mechanic(&mechanic_id)
                        .expect("registered mechanic");
                    raw.insert(
                        key,
                        Variant::Int(combine(mechanic.grant_combine(key), had, now)),
                    );
                } else {
                    raw.insert(key, amount.clone());
                }
            }
            merged.borrow_mut().insert(mechanic_id, raw);
        }
        let out = Array::new();
        for (mechanic_id, raw) in merged.borrow().iter() {
            let problems = Array::new();
            let params =
                MechanicParams::parse(raw, &self.kinds_of(mechanic_id), "aura grant", &problems);
            if let Some(params) = params {
                out.push(self.bind(&MechanicSpec::new(mechanic_id, Some(params)), false, true));
            }
        }
        out
    }
    /// Given numbers are already the giver's values, so the target's golden never doubles them.
    pub fn bind_given(&self, mechanic_id: &str, raw: &Dictionary) -> Option<BoundMechanicRef> {
        if !self.has(mechanic_id) {
            return None;
        }
        let problems = Array::new();
        let params =
            MechanicParams::parse(raw, &self.kinds_of(mechanic_id), mechanic_id, &problems)?;
        Some(self.bind(&MechanicSpec::new(mechanic_id, Some(params)), false, true))
    }
    /// ADDING-A-TRIBE naming rules: report an unprefixed name once, then remember it.
    pub fn check_name(&mut self, name: &str, what: &str) {
        if self.prefixes.is_empty() || self._named.borrow().contains_key(name) {
            return;
        }
        self._named.borrow_mut().insert(name.to_owned(), true);
        let problem = Self::name_problem(&self.prefixes, name, what);
        if !problem.is_empty() {
            self.errors.push(problem.clone());
            eprintln!("{problem}");
        }
    }
    pub fn name_problem(known: &Array<String>, name: &str, what: &str) -> String {
        if name.starts_with("core_") {
            return String::new();
        }
        for prefix in known.borrow().iter() {
            if name.starts_with(prefix) {
                return String::new();
            }
        }
        format!(
            "{what} name '{name}' has no content prefix ({})",
            known.borrow().join(", ")
        )
    }
    pub fn has(&self, mechanic_id: &str) -> bool {
        self._scripts.borrow().contains_key(mechanic_id)
    }
    pub fn get_mechanic(&self, mechanic_id: &str) -> Option<Rc<dyn Mechanic>> {
        self._scripts.borrow().get(mechanic_id).cloned()
    }
    pub fn kinds_of(&self, mechanic_id: &str) -> Dictionary {
        self.get_mechanic(mechanic_id)
            .map_or_else(Dictionary::new, |mechanic| mechanic.param_kinds())
    }
    pub fn bind(&self, spec: &MechanicSpecRef, golden: bool, granted: bool) -> BoundMechanicRef {
        let spec = spec.borrow();
        let params = spec.params.borrow().with_golden(golden);
        BoundMechanic::new(&spec.id, self.get_mechanic(&spec.id), params, granted)
    }
}
impl ToState for MechanicRegistry {
    fn to_state(&self) -> Variant {
        crate::state_dict! {"errors"=>&self.errors,"prefixes"=>&self.prefixes,"_named"=>&self._named,"_scripts"=>&self._scripts}
    }
    fn field_names() -> &'static [&'static str] {
        &["errors", "prefixes", "_named", "_scripts"]
    }
}

fn built_ins() -> Vec<(&'static str, Rc<dyn Mechanic>)> {
    vec![
        (
            "taunt",
            Rc::new(crate::core::mechanics::keywords::taunt::Taunt),
        ),
        (
            "divine_shield",
            Rc::new(crate::core::mechanics::keywords::divine_shield::DivineShield),
        ),
        (
            "windfury",
            Rc::new(crate::core::mechanics::keywords::windfury::Windfury),
        ),
        (
            "reborn",
            Rc::new(crate::core::mechanics::keywords::reborn::Reborn),
        ),
        (
            "venomous",
            Rc::new(crate::core::mechanics::keywords::venomous::Venomous),
        ),
        (
            "stealth",
            Rc::new(crate::core::mechanics::keywords::stealth::Stealth),
        ),
        (
            "cleave",
            Rc::new(crate::core::mechanics::keywords::cleave::Cleave),
        ),
        (
            "play_buff",
            Rc::new(crate::core::mechanics::effects::play_buff::PlayBuff),
        ),
        (
            "death_summon",
            Rc::new(crate::core::mechanics::effects::death_summon::DeathSummon),
        ),
        (
            "end_turn_buff",
            Rc::new(crate::core::mechanics::effects::end_turn_buff::EndTurnBuff),
        ),
        (
            "start_turn_gold",
            Rc::new(crate::core::mechanics::effects::start_turn_gold::StartTurnGold),
        ),
        (
            "sell_bonus",
            Rc::new(crate::core::mechanics::effects::sell_bonus::SellBonus),
        ),
        (
            "aura_attack",
            Rc::new(crate::core::mechanics::effects::aura_attack::AuraAttack),
        ),
        (
            "rally_gain",
            Rc::new(crate::core::mechanics::effects::rally_gain::RallyGain),
        ),
        (
            "attacked_gain",
            Rc::new(crate::core::mechanics::effects::attacked_gain::AttackedGain),
        ),
        (
            "kill_gain",
            Rc::new(crate::core::mechanics::effects::kill_gain::KillGain),
        ),
        (
            "start_combat_damage",
            Rc::new(crate::core::mechanics::effects::start_combat_damage::StartCombatDamage),
        ),
        (
            "avenge_buff",
            Rc::new(crate::core::mechanics::effects::avenge_buff::AvengeBuff),
        ),
        (
            "discover",
            Rc::new(crate::core::mechanics::effects::discover::Discover),
        ),
        (
            "triple_reward",
            Rc::new(crate::core::mechanics::effects::triple_reward::TripleReward),
        ),
    ]
}

/// ContentSet chooses these implementations by the source folder and filename.
pub fn content_mechanic(tribe: &str, file: &str) -> Option<Rc<dyn Mechanic>> {
    match (tribe, file.trim_end_matches(".gd")) {
        ("badger", "arms_master") => Some(Rc::new(
            crate::content::badger::mechanics::arms_master::ArmsMaster,
        )),
        ("badger", "dame") => Some(Rc::new(crate::content::badger::mechanics::dame::Dame)),
        ("badger", "fury") => Some(Rc::new(crate::content::badger::mechanics::fury::Fury)),
        ("badger", "gate_warden") => Some(Rc::new(
            crate::content::badger::mechanics::gate_warden::GateWarden,
        )),
        ("badger", "greatsword") => Some(Rc::new(
            crate::content::badger::mechanics::greatsword::Greatsword,
        )),
        ("badger", "grudge") => Some(Rc::new(crate::content::badger::mechanics::grudge::Grudge)),
        ("badger", "grudge_keeper") => Some(Rc::new(
            crate::content::badger::mechanics::grudge_keeper::GrudgeKeeper,
        )),
        ("badger", "grudge_pay") => Some(Rc::new(
            crate::content::badger::mechanics::grudge_pay::GrudgePay,
        )),
        ("badger", "herald") => Some(Rc::new(crate::content::badger::mechanics::herald::Herald)),
        ("badger", "lance") => Some(Rc::new(crate::content::badger::mechanics::lance::Lance)),
        ("badger", "lend_attack") => Some(Rc::new(
            crate::content::badger::mechanics::lend_attack::LendAttack,
        )),
        ("badger", "lend_health") => Some(Rc::new(
            crate::content::badger::mechanics::lend_health::LendHealth,
        )),
        ("badger", "marshal") => Some(Rc::new(crate::content::badger::mechanics::marshal::Marshal)),
        ("badger", "oakfeller") => Some(Rc::new(
            crate::content::badger::mechanics::oakfeller::Oakfeller,
        )),
        ("badger", "old_brock") => Some(Rc::new(
            crate::content::badger::mechanics::old_brock::OldBrock,
        )),
        ("badger", "overrun") => Some(Rc::new(crate::content::badger::mechanics::overrun::Overrun)),
        ("badger", "relic") => Some(Rc::new(crate::content::badger::mechanics::relic::Relic)),
        ("badger", "sexton") => Some(Rc::new(crate::content::badger::mechanics::sexton::Sexton)),
        ("badger", "squire") => Some(Rc::new(crate::content::badger::mechanics::squire::Squire)),
        ("badger", "sword_heir") => Some(Rc::new(
            crate::content::badger::mechanics::sword_heir::SwordHeir,
        )),
        ("badger", "tourney") => Some(Rc::new(crate::content::badger::mechanics::tourney::Tourney)),
        ("locust", "brood") => Some(Rc::new(crate::content::locust::mechanics::brood::Brood)),
        ("locust", "death_damage_all") => Some(Rc::new(
            crate::content::locust::mechanics::death_damage_all::DeathDamageAll,
        )),
        ("locust", "death_damage_random") => Some(Rc::new(
            crate::content::locust::mechanics::death_damage_random::DeathDamageRandom,
        )),
        ("locust", "dirge") => Some(Rc::new(crate::content::locust::mechanics::dirge::Dirge)),
        ("locust", "drum") => Some(Rc::new(crate::content::locust::mechanics::drum::Drum)),
        ("locust", "glean") => Some(Rc::new(crate::content::locust::mechanics::glean::Glean)),
        ("locust", "glut") => Some(Rc::new(crate::content::locust::mechanics::glut::Glut)),
        ("locust", "gorge") => Some(Rc::new(crate::content::locust::mechanics::gorge::Gorge)),
        ("locust", "hopper_to_hand") => Some(Rc::new(
            crate::content::locust::mechanics::hopper_to_hand::HopperToHand,
        )),
        ("locust", "hoppers_on_death") => Some(Rc::new(
            crate::content::locust::mechanics::hoppers_on_death::HoppersOnDeath,
        )),
        ("locust", "molt") => Some(Rc::new(crate::content::locust::mechanics::molt::Molt)),
        ("locust", "mother") => Some(Rc::new(crate::content::locust::mechanics::mother::Mother)),
        ("locust", "plague") => Some(Rc::new(crate::content::locust::mechanics::plague::Plague)),
        ("locust", "shed") => Some(Rc::new(crate::content::locust::mechanics::shed::Shed)),
        ("locust", "sky_darken") => Some(Rc::new(
            crate::content::locust::mechanics::sky_darken::SkyDarken,
        )),
        ("locust", "swarm") => Some(Rc::new(crate::content::locust::mechanics::swarm::Swarm)),
        ("locust", "swarm_lord") => Some(Rc::new(
            crate::content::locust::mechanics::swarm_lord::SwarmLord,
        )),
        ("locust", "tide_end_turn") => Some(Rc::new(
            crate::content::locust::mechanics::tide_end_turn::TideEndTurn,
        )),
        ("locust", "tide_on_death") => Some(Rc::new(
            crate::content::locust::mechanics::tide_on_death::TideOnDeath,
        )),
        ("locust", "veteran") => Some(Rc::new(crate::content::locust::mechanics::veteran::Veteran)),
        ("mouse", "ballista") => Some(Rc::new(
            crate::content::mouse::mechanics::ballista::Ballista,
        )),
        ("mouse", "bodkin") => Some(Rc::new(crate::content::mouse::mechanics::bodkin::Bodkin)),
        ("mouse", "captain") => Some(Rc::new(crate::content::mouse::mechanics::captain::Captain)),
        ("mouse", "catapult") => Some(Rc::new(
            crate::content::mouse::mechanics::catapult::Catapult,
        )),
        ("mouse", "cook") => Some(Rc::new(crate::content::mouse::mechanics::cook::Cook)),
        ("mouse", "cutpurse") => Some(Rc::new(
            crate::content::mouse::mechanics::cutpurse::Cutpurse,
        )),
        ("mouse", "edgewright") => Some(Rc::new(
            crate::content::mouse::mechanics::edgewright::Edgewright,
        )),
        ("mouse", "engines") => Some(Rc::new(crate::content::mouse::mechanics::engines::Engines)),
        ("mouse", "fencing_master") => Some(Rc::new(
            crate::content::mouse::mechanics::fencing_master::FencingMaster,
        )),
        ("mouse", "grindstone") => Some(Rc::new(
            crate::content::mouse::mechanics::grindstone::Grindstone,
        )),
        ("mouse", "kettle_drummer") => Some(Rc::new(
            crate::content::mouse::mechanics::kettle_drummer::KettleDrummer,
        )),
        ("mouse", "king_speck") => Some(Rc::new(
            crate::content::mouse::mechanics::king_speck::KingSpeck,
        )),
        ("mouse", "pikeman") => Some(Rc::new(crate::content::mouse::mechanics::pikeman::Pikeman)),
        ("mouse", "pile_on") => Some(Rc::new(crate::content::mouse::mechanics::pile_on::PileOn)),
        ("mouse", "piper") => Some(Rc::new(crate::content::mouse::mechanics::piper::Piper)),
        ("mouse", "scout") => Some(Rc::new(crate::content::mouse::mechanics::scout::Scout)),
        ("mouse", "standard_bearer") => Some(Rc::new(
            crate::content::mouse::mechanics::standard_bearer::StandardBearer,
        )),
        ("mouse", "whetstone") => Some(Rc::new(
            crate::content::mouse::mechanics::whetstone::Whetstone,
        )),
        ("pigeon", "adjutant") => Some(Rc::new(
            crate::content::pigeon::mechanics::adjutant::Adjutant,
        )),
        ("pigeon", "brigadier") => Some(Rc::new(
            crate::content::pigeon::mechanics::brigadier::Brigadier,
        )),
        ("pigeon", "bugler") => Some(Rc::new(crate::content::pigeon::mechanics::bugler::Bugler)),
        ("pigeon", "campaigner") => Some(Rc::new(
            crate::content::pigeon::mechanics::campaigner::Campaigner,
        )),
        ("pigeon", "colonel") => Some(Rc::new(crate::content::pigeon::mechanics::colonel::Colonel)),
        ("pigeon", "colour_ensign") => Some(Rc::new(
            crate::content::pigeon::mechanics::colour_ensign::ColourEnsign,
        )),
        ("pigeon", "colour_sergeant") => Some(Rc::new(
            crate::content::pigeon::mechanics::colour_sergeant::ColourSergeant,
        )),
        ("pigeon", "field_marshal") => Some(Rc::new(
            crate::content::pigeon::mechanics::field_marshal::FieldMarshal,
        )),
        ("pigeon", "flying_ace") => Some(Rc::new(
            crate::content::pigeon::mechanics::flying_ace::FlyingAce,
        )),
        ("pigeon", "grenadier") => Some(Rc::new(
            crate::content::pigeon::mechanics::grenadier::Grenadier,
        )),
        ("pigeon", "guard_post") => Some(Rc::new(
            crate::content::pigeon::mechanics::guard_post::GuardPost,
        )),
        ("pigeon", "lance_corporal") => Some(Rc::new(
            crate::content::pigeon::mechanics::lance_corporal::LanceCorporal,
        )),
        ("pigeon", "lieutenant") => Some(Rc::new(
            crate::content::pigeon::mechanics::lieutenant::Lieutenant,
        )),
        ("pigeon", "padre") => Some(Rc::new(crate::content::pigeon::mechanics::padre::Padre)),
        ("pigeon", "recruiting_sergeant") => Some(Rc::new(
            crate::content::pigeon::mechanics::recruiting_sergeant::RecruitingSergeant,
        )),
        ("pigeon", "reserve") => Some(Rc::new(crate::content::pigeon::mechanics::reserve::Reserve)),
        ("pigeon", "sentry") => Some(Rc::new(crate::content::pigeon::mechanics::sentry::Sentry)),
        ("pigeon", "sergeant_major") => Some(Rc::new(
            crate::content::pigeon::mechanics::sergeant_major::SergeantMajor,
        )),
        ("pigeon", "sortie") => Some(Rc::new(crate::content::pigeon::mechanics::sortie::Sortie)),
        ("pigeon", "squadron_leader") => Some(Rc::new(
            crate::content::pigeon::mechanics::squadron_leader::SquadronLeader,
        )),
        ("pigeon", "stiff_upper_lip") => Some(Rc::new(
            crate::content::pigeon::mechanics::stiff_upper_lip::StiffUpperLip,
        )),
        ("pigeon", "wing_commander") => Some(Rc::new(
            crate::content::pigeon::mechanics::wing_commander::WingCommander,
        )),
        ("thorn", "briar_king") => Some(Rc::new(
            crate::content::thorn::mechanics::briar_king::BriarKing,
        )),
        ("thorn", "bury_feed") => Some(Rc::new(
            crate::content::thorn::mechanics::bury_feed::BuryFeed,
        )),
        ("thorn", "bury_gold") => Some(Rc::new(
            crate::content::thorn::mechanics::bury_gold::BuryGold,
        )),
        ("thorn", "bury_twice") => Some(Rc::new(
            crate::content::thorn::mechanics::bury_twice::BuryTwice,
        )),
        ("thorn", "compost") => Some(Rc::new(crate::content::thorn::mechanics::compost::Compost)),
        ("thorn", "coppicer") => Some(Rc::new(
            crate::content::thorn::mechanics::coppicer::Coppicer,
        )),
        ("thorn", "elder_mother") => Some(Rc::new(
            crate::content::thorn::mechanics::elder_mother::ElderMother,
        )),
        ("thorn", "grow") => Some(Rc::new(crate::content::thorn::mechanics::grow::Grow)),
        ("thorn", "holly_knight") => Some(Rc::new(
            crate::content::thorn::mechanics::holly_knight::HollyKnight,
        )),
        ("thorn", "ivy") => Some(Rc::new(crate::content::thorn::mechanics::ivy::Ivy)),
        ("thorn", "lone_hawthorn") => Some(Rc::new(
            crate::content::thorn::mechanics::lone_hawthorn::LoneHawthorn,
        )),
        ("thorn", "old_hedge") => Some(Rc::new(
            crate::content::thorn::mechanics::old_hedge::OldHedge,
        )),
        ("thorn", "old_stump") => Some(Rc::new(
            crate::content::thorn::mechanics::old_stump::OldStump,
        )),
        ("thorn", "pip") => Some(Rc::new(crate::content::thorn::mechanics::pip::Pip)),
        ("thorn", "root") => Some(Rc::new(crate::content::thorn::mechanics::root::Root)),
        ("thorn", "sapling") => Some(Rc::new(crate::content::thorn::mechanics::sapling::Sapling)),
        ("thorn", "seed") => Some(Rc::new(crate::content::thorn::mechanics::seed::Seed)),
        ("thorn", "sweetbriar") => Some(Rc::new(
            crate::content::thorn::mechanics::sweetbriar::Sweetbriar,
        )),
        ("thorn", "thorns") => Some(Rc::new(crate::content::thorn::mechanics::thorns::Thorns)),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn duplicate_ids_and_names_are_reported_once() {
        let registry = MechanicRegistry::with_built_ins();
        let taunt = registry.borrow().get_mechanic("taunt").unwrap();
        assert!(!registry.borrow_mut().register("taunt", taunt));
        registry.borrow().prefixes.push("thorn_".into());
        registry.borrow_mut().check_name("unprefixed", "counter");
        registry.borrow_mut().check_name("unprefixed", "heap");
        registry.borrow_mut().check_name("thorn_compost", "heap");
        registry.borrow_mut().check_name("core_fixture", "counter");
        assert_eq!(
            registry.borrow().errors.to_vec(),
            vec![
                "mechanic id taunt is registered twice",
                "counter name 'unprefixed' has no content prefix (thorn_)"
            ]
        );
    }
    #[test]
    fn grants_use_each_mechanics_combination_and_skip_invalid_parameters() {
        let registry = MechanicRegistry::with_built_ins();
        registry
            .borrow_mut()
            .register("thorn_root", content_mechanic("thorn", "root").unwrap());
        let grant = |id: &str, param: &str, amount: Variant| {
            let d = Dictionary::new();
            d.insert("mechanic", Variant::from(id));
            d.insert(param, amount);
            Variant::Dictionary(d)
        };
        let grants = Array::from(vec![
            grant("aura_attack", "amount", Variant::Int(2)),
            grant("aura_attack", "amount", Variant::Int(3)),
            grant("thorn_root", "cost", Variant::Int(5)),
            grant("thorn_root", "cost", Variant::Int(2)),
            grant("unknown", "amount", Variant::Int(99)),
            grant("play_buff", "attack", Variant::Int(99)),
        ]);
        let bound = registry.borrow().bind_grants(&grants);
        assert_eq!(bound.len(), 2);
        assert_eq!(
            bound.get(0).unwrap().borrow().params.borrow().num("amount"),
            5
        );
        assert_eq!(
            bound.get(1).unwrap().borrow().params.borrow().num("cost"),
            2
        );
        assert!(bound.get(0).unwrap().borrow().granted);
        // Godot checks TYPE_INT before merging, so a JSON float overwrites an earlier integer.
        let overwritten = registry.borrow().bind_grants(&Array::from(vec![
            grant("aura_attack", "amount", Variant::Int(2)),
            grant("aura_attack", "amount", Variant::Float(3.0)),
        ]));
        assert_eq!(
            overwritten
                .get(0)
                .unwrap()
                .borrow()
                .params
                .borrow()
                .num("amount"),
            3
        );
    }
}
