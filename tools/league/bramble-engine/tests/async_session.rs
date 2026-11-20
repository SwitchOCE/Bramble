use bramble_engine::core::{
    bots::{bot::Bot, simple_bot::SimpleBot},
    combat::{combat::Combat, combat_unit::CombatUnitRef, fight_side::FightSide},
    ghosts::{
        ghost_run::{GhostRun, RunsBySeat},
        ghost_store::GhostStore,
    },
    mechanics::{mechanic::Mechanic, mechanic_params::MechanicParamsRef},
    records::{
        fight_snapshot::FightSnapshot, game_record::GameRecord, record_replay::RecordReplay,
        record_state::RecordState,
    },
    recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext},
    session::{
        game_session::{GameSession, GameSessionRef},
        matchmaking::Matchmaking,
    },
    state::fight_report::FightReportRef,
    units::unit::UnitRef,
    util::rng::Rng,
};
use bramble_engine::{
    Array, Dictionary, ToState, Variant,
    game::game_content::{GameContent, GameContentRef},
};
use serde_json::{Value, json};
use std::{
    collections::BTreeSet,
    fs,
    path::{Path, PathBuf},
    rc::Rc,
    sync::{Mutex, MutexGuard},
};

const FLOW: &str = "2a32d19657c0179f64f9be3060b2c6431d92072d158dfa3d55e25d7f398a12ac";
const RANDOM: &str = "02f918a6e3c6876ddf88edee1b9a3a9753093adb5f56155348a29a28ac701789";

fn root() -> &'static Path {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(3)
        .unwrap()
}

fn field() -> PathBuf {
    root().join("tools/league/proof/fixtures/async-store")
}

fn run_path(store: &Path, id: &str) -> PathBuf {
    store.join("runs").join(&id[..2]).join(format!("{id}.json"))
}

fn fetch(content: &GameContentRef, id: &str) -> GhostRun {
    let content = content.borrow();
    GhostStore::new(field())
        .fetch(
            id,
            Some(&content.library.borrow()),
            Some(&content.registry.borrow()),
        )
        .unwrap()
}

fn fixture(id: &str) -> Value {
    serde_json::from_slice(&fs::read(run_path(&field(), id)).unwrap()).unwrap()
}

fn parse(content: &GameContentRef, data: &Value) -> GhostRun {
    let content = content.borrow();
    GhostRun::parse(
        &serde_json::to_vec(data).unwrap(),
        Some(&content.library.borrow()),
        Some(&content.registry.borrow()),
    )
    .unwrap()
}

fn lobby(content: &GameContentRef, other: GhostRun) -> RunsBySeat {
    let flow = fetch(content, FLOW);
    (1..8)
        .map(|seat| {
            (
                seat,
                if seat == 1 {
                    other.clone()
                } else {
                    flow.clone()
                },
            )
        })
        .collect()
}

struct Records {
    directory: PathBuf,
    _settings: MutexGuard<'static, ()>,
}

impl Records {
    fn new() -> Self {
        static SETTINGS: Mutex<()> = Mutex::new(());
        let settings = SETTINGS.lock().unwrap_or_else(|error| error.into_inner());
        let directory = root().join(format!(".copies/async-session-test-{}", std::process::id()));
        GameRecord::configure(root(), &directory);
        Self {
            directory,
            _settings: settings,
        }
    }
}

impl Drop for Records {
    fn drop(&mut self) {
        if self.directory.exists() {
            fs::remove_dir_all(&self.directory).unwrap();
        }
    }
}

fn new_game(seed: i64, id: &str) -> GameSessionRef {
    let content = GameContent::load_default(root());
    let runs = lobby(&content, fetch(&content, id));
    content
        .borrow()
        .new_async_session(seed, runs, &Array::new())
        .unwrap()
}

fn run_rounds(game: &GameSessionRef, count: i64) {
    for _ in 0..count {
        GameSession::start_round(game);
        GameSession::finish_round(game);
    }
}

fn path(game: &GameSessionRef) -> PathBuf {
    let game = game.borrow();
    let record = game.record.as_ref().unwrap().borrow();
    assert!(record.error.is_empty(), "{}", record.error);
    record.path.clone().into()
}

fn entries(game: &GameSessionRef) -> Array<Dictionary> {
    RecordReplay::read_entries(&path(game)).unwrap_or_else(|error| panic!("{}", error.message))
}

fn fight_boards(game: &GameSessionRef, turn: i64) -> Dictionary {
    entries(game)
        .to_vec()
        .into_iter()
        .find(|entry| {
            entry.get("op").as_text() == "fight_boards" && entry.get("turn").as_i64() == turn
        })
        .unwrap()
}

fn take_turn(
    game: &GameSessionRef,
    id: i64,
    mut choose: impl FnMut(&PlayerStateRef) -> Dictionary,
) {
    let player = game.borrow().player(id);
    for _ in 0..Bot::MAX_ACTIONS {
        if player.borrow().turn_ended || !player.borrow().alive {
            return;
        }
        assert_eq!(GameSession::act(game, id, &choose(&player)), "");
    }
    GameSession::end_turn(game, id);
}

#[test]
fn the_lobby_plays_out_after_the_live_seat_is_eliminated() {
    let game = new_game(1001, RANDOM);
    game.borrow_mut().record_recipe = Dictionary::new();
    game.borrow_mut().keep_fight_events = false;
    {
        let game = game.borrow();
        let config = game.config.as_ref().unwrap().borrow();
        for player in game.players.to_vec() {
            assert_eq!(player.borrow().health, config.starting_health);
            assert_eq!(player.borrow().armor, config.starting_armor);
        }
    }
    while !game.borrow().over {
        GameSession::start_round(&game);
        for seat in 1..8 {
            let player = game.borrow().player(seat);
            let player = player.borrow();
            assert_eq!(player.gold, 0);
            assert!(player.turn_ended);
            assert!(player.shop_units.is_empty());
            assert!(game.borrow().legal_actions(seat).is_empty());
        }
        GameSession::finish_round(&game);
    }
    let game = game.borrow();
    let player = game.player(0);
    assert!(!player.borrow().alive);
    assert!(player.borrow().eliminated_round < game.round_number);
    let mut places: Vec<_> = game
        .placements()
        .borrow()
        .values()
        .map(Variant::as_i64)
        .collect();
    places.sort_unstable();
    assert_eq!(places, (1..=8).collect::<Vec<_>>());
}

#[test]
fn async_replay_matches_all_hashes_and_relocates_content_paths() {
    let _records = Records::new();
    let game = new_game(1002, RANDOM);
    game.borrow()
        .config
        .as_ref()
        .unwrap()
        .borrow_mut()
        .round_limit = 5;
    let mut bot = SimpleBot::new(&Rng::derive(1002, "bot:0"));
    while !game.borrow().over {
        GameSession::start_round(&game);
        take_turn(&game, 0, |player| bot.choose(&game, player));
        GameSession::finish_round(&game);
    }
    let entries = entries(&game);
    let header = entries.get(0).unwrap();
    assert_eq!(header.get("format").as_i64(), 4);
    assert_eq!(header.get("mode").as_text(), "async");
    assert_eq!(header.get("runs").as_array().len(), 7);
    for entry in entries.to_vec() {
        if matches!(entry.get("op").as_text().as_str(), "act" | "end") {
            assert_eq!(entry.get("player").as_i64(), 0);
        }
    }
    let replay = RecordReplay::read_with_store(root(), &path(&game), Some(&field()));
    assert!(replay.ok, "{}", replay.message);
    assert!(replay.complete);
    assert_eq!(replay.checkpoints, game.borrow().round_number * 3);
    let rebuilt = replay.session.unwrap();
    assert_eq!(
        RecordState::state_hash(&rebuilt.borrow()),
        RecordState::state_hash(&game.borrow())
    );
    assert_eq!(rebuilt.borrow().run_ids, game.borrow().run_ids);
    let recipe = header.get("recipe").as_dict();
    for path in recipe.get("paths").as_array().borrow_mut().iter_mut() {
        let text = path.as_text();
        let folder = Path::new(&text).file_name().unwrap().to_str().unwrap();
        *path = format!("/another-checkout/src/content/{folder}").into();
    }
    let relocated = RecordReplay::rebuild_to_with_store(root(), &entries, None, Some(&field()));
    assert!(relocated.ok, "{}", relocated.message);
}

#[test]
fn swapping_a_valid_run_id_fails_at_the_initial_hash() {
    let _records = Records::new();
    let game = new_game(1003, RANDOM);
    run_rounds(&game, 1);
    let entries = entries(&game);
    let header = entries.get(0).unwrap();
    let first_run = header.get("runs").as_array().get(0).unwrap().as_dict();
    first_run.insert("id", FLOW.into());
    let replay = RecordReplay::rebuild_to_with_store(root(), &entries, None, Some(&field()));
    assert!(!replay.ok);
    assert_eq!(replay.turn, 0);
    assert_eq!(
        replay.message,
        "first differing turn 0: initial state differs"
    );
}

#[test]
fn missing_and_tampered_runs_fail_before_turn_one_and_name_the_run() {
    let records = Records::new();
    let game = new_game(1004, RANDOM);
    run_rounds(&game, 1);
    let store = records.directory.join("store");
    let missing = RecordReplay::read_with_store(root(), &path(&game), Some(&store));
    assert!(!missing.ok);
    assert_eq!(missing.turn, 0);
    assert!(
        missing
            .message
            .contains(&format!("run {RANDOM}: cannot open")),
        "{}",
        missing.message
    );

    let tampered = run_path(&store, RANDOM);
    fs::create_dir_all(tampered.parent().unwrap()).unwrap();
    let original = fs::read(run_path(&field(), RANDOM)).unwrap();
    let mut bytes = original.clone();
    if bytes.last() == Some(&b'\n') {
        *bytes.last_mut().unwrap() = b' ';
    } else {
        bytes.push(b' ');
    }
    assert_eq!(
        serde_json::from_slice::<Value>(&bytes).unwrap(),
        serde_json::from_slice::<Value>(&original).unwrap()
    );
    fs::write(tampered, bytes).unwrap();
    let altered = RecordReplay::read_with_store(root(), &path(&game), Some(&store));
    assert!(!altered.ok);
    assert_eq!(altered.turn, 0);
    assert!(
        altered
            .message
            .contains(&format!("run {RANDOM}: SHA-256 mismatch")),
        "{}",
        altered.message
    );
}

#[test]
fn an_ended_run_keeps_its_final_board_and_records_the_reason() {
    let _records = Records::new();
    let content = GameContent::load_default(root());
    let mut data = fixture(FLOW);
    data["turns"].as_array_mut().unwrap().truncate(2);
    data["last_turn"] = 2.into();
    let held: BTreeSet<_> = data["turns"]
        .as_array()
        .unwrap()
        .iter()
        .flat_map(|turn| {
            ["board", "hand"]
                .into_iter()
                .flat_map(|kind| turn["payload"][kind].as_array().unwrap().iter())
        })
        .filter_map(|unit| unit["def"].as_str().map(str::to_owned))
        .collect();
    data["cards"]
        .as_object_mut()
        .unwrap()
        .retain(|id, _| held.contains(id));
    let runs = lobby(&content, parse(&content, &data));
    let game = content
        .borrow()
        .new_async_session(1005, runs, &Array::new())
        .unwrap();
    run_rounds(&game, 1);
    let player = game.borrow().player(1);
    let board = || FightSnapshot::units(&player.borrow().board);
    let first = board();
    let first_tier = player.borrow().tier;
    GameSession::start_round(&game);
    assert_eq!(board(), first);
    assert_eq!(player.borrow().tier, first_tier);
    assert!(
        !GameSession::act(
            &game,
            1,
            &bramble_engine::state_dict! {"type"=>"end_turn"}.as_dict()
        )
        .is_empty()
    );
    GameSession::end_turn(&game, 1);
    GameSession::finish_round(&game);
    let last = board();
    assert_ne!(last, first);
    assert_eq!(
        player.borrow().board_units().get(0).unwrap().borrow().uid,
        GhostRun::UID_STRIDE + 29
    );
    let slots = RecordState::value(&player.borrow().slots.to_state());
    // The recorded Sentry already applied its end-of-turn Renown in slot 3.
    assert_eq!(player.borrow().slots.get(3).unwrap().borrow().renown, 1);
    run_rounds(&game, 1);
    assert_eq!(board(), last);
    assert_eq!(RecordState::value(&player.borrow().slots.to_state()), slots);
    let recorded = fight_boards(&game, 3)
        .get("run_boards")
        .as_array()
        .get(0)
        .unwrap()
        .as_dict();
    assert_eq!(recorded.get("seat").as_i64(), 1);
    assert_eq!(recorded.get("run_turn").as_i64(), 2);
    assert_eq!(recorded.get("reason").as_text(), "run_ended");
    let events = game.borrow().events.to_vec();
    for (round, reason) in [(2, "same_turn"), (3, "run_ended")] {
        assert!(events.iter().any(|event| {
            event.get("type").as_text() == "run_board"
                && event.get("round").as_i64() == round
                && event.get("seat").as_i64() == 1
                && event.get("run_turn").as_i64() == 2
                && event.get("reason").as_text() == reason
        }));
    }
}

struct FightProbe;

impl ToState for FightProbe {
    fn to_state(&self) -> Variant {
        bramble_engine::state_dict! {}
    }
}

impl Mechanic for FightProbe {
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _: &MechanicParamsRef,
    ) {
        let side = unit.unwrap().borrow().side;
        let bridge = combat.bridge(side);
        FightSide::add_gold(&bridge, combat, 1, unit);
        combat._log(&bramble_engine::state_dict! {"type"=>"async_probe", "side"=>&side}.as_dict());
        combat.buff(unit, 1, 1, unit, true);
    }

    fn on_start_of_turn(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        report: Option<&FightReportRef>,
        _: &MechanicParamsRef,
    ) {
        if report.is_some() {
            ctx.pay_fight_reward(|ctx| ctx.buff(unit.unwrap(), 1, 1, true, unit));
        }
    }
}

#[test]
fn run_against_run_fights_have_no_persistent_effects_and_use_distinct_uids() {
    let content = GameContent::load_default(root());
    content
        .borrow()
        .registry
        .borrow_mut()
        .register("core_async_probe", Rc::new(FightProbe));
    let mut data = fixture(FLOW);
    let unit = data["turns"][0]["payload"]["board"]
        .as_array_mut()
        .unwrap()
        .iter_mut()
        .find(|unit| !unit.is_null())
        .unwrap();
    let uid = unit["uid"].as_i64().unwrap();
    let saved_attack = unit["stats"]["perm_attack"].as_i64().unwrap_or(0);
    unit["grants"] = json!([["core_async_probe"]]);
    let run = parse(&content, &data);
    let runs = (1..8).map(|seat| (seat, run.clone())).collect();
    let game = content
        .borrow()
        .new_async_session(1006, runs, &Array::new())
        .unwrap();
    game.borrow_mut().record_recipe = Dictionary::new();
    GameSession::start_round(&game);
    let fights = GameSession::finish_round(&game);
    let mut tested = 0;
    for fight in fights.to_vec() {
        let seats: Vec<_> = fight
            .get("players")
            .as_array()
            .borrow()
            .iter()
            .map(Variant::as_i64)
            .collect();
        if seats.contains(&0) {
            continue;
        }
        let mut buffed = Vec::new();
        let events = fight.get("events").as_array().to_vec();
        for pair in events.windows(2) {
            let probe = pair[0].as_dict();
            if probe.get("type").as_text() != "async_probe" {
                continue;
            }
            let buff = pair[1].as_dict();
            assert_eq!(buff.get("type").as_text(), "buff");
            assert_eq!(buff.get("permanent"), false.into());
            assert_eq!(buff.get("side"), probe.get("side"));
            buffed.push(buff.get("side").as_i64());
        }
        buffed.sort_unstable();
        assert_eq!(buffed, [0, 1]);
        assert!(fight.get("after").as_array().is_empty());
        for seat in seats {
            let player = game.borrow().player(seat);
            let player = player.borrow();
            assert_eq!(player.gold_next_turn, 0);
            let unit = player.board_units().get(0).unwrap();
            let unit = unit.borrow();
            assert_eq!(unit.uid, seat * GhostRun::UID_STRIDE + uid);
            assert_eq!(
                unit.stats.as_ref().unwrap().borrow().perm_attack,
                saved_attack
            );
        }
        tested += 1;
    }
    assert_eq!(tested, 3);
}

#[test]
fn the_stand_in_uses_the_eliminated_run_seats_last_fought_board() {
    let _records = Records::new();
    let game = new_game(1007, RANDOM);
    run_rounds(&game, 3);
    GameSession::start_round(&game);
    let player = game.borrow().player(1);
    player.borrow_mut().health = 1;
    if game.borrow().opponent_of(1) == 0 {
        let card = game
            .borrow()
            .library
            .as_ref()
            .unwrap()
            .borrow()
            .get_card("hedge-knight")
            .unwrap();
        let unit = game.borrow_mut().new_unit(&card, false);
        {
            let mut unit = unit.borrow_mut();
            unit.slot = 0;
            let mut stats = unit.stats.as_ref().unwrap().borrow_mut();
            stats.perm_attack = 100;
            stats.perm_health = 100;
        }
        game.borrow().player(0).borrow().board.borrow_mut()[0] = Some(unit);
    }
    GameSession::finish_round(&game);
    assert!(!player.borrow().alive);
    assert_eq!(game.borrow().ghost_of, 1);
    assert_eq!(player.borrow().board_units().len(), 1);
    let last = FightSnapshot::units(&player.borrow().board);
    assert_eq!(FightSnapshot::units(&game.borrow().ghost_board), last);
    GameSession::start_round(&game);
    assert!(game.borrow().pairings.to_vec().iter().any(|pair| {
        pair.as_array()
            .borrow()
            .contains(&Matchmaking::GHOST.into())
    }));
    GameSession::finish_round(&game);
    let payloads = fight_boards(&game, 5).get("players").as_array().to_vec();
    let stand_in = payloads.last().unwrap().as_dict();
    assert_eq!(stand_in.get("id").as_i64(), Matchmaking::GHOST);
    assert_eq!(stand_in.get("of").as_i64(), 1);
    assert_eq!(RecordState::value(&stand_in.get("board")), last.to_state());
}
