use crate::{
    Act, Ended, FolderStore, GhostStore, RUN_FORMAT, Run, RunSource, RunTurn, SourceKind, at,
    sha256,
};
use bramble_engine::Array;
use bramble_engine::core::{
    content::content_set::resolve,
    records::record_replay::RecordReplay,
    session::{game_session::GameSessionRef, matchmaking::Matchmaking},
    units::unit_library::UnitLibrary,
};
use bramble_engine::game::game_content::GameContent;
use bramble_engine::util::godot_json;
use serde::Deserialize;
use serde_json::Value;
use std::{collections::BTreeMap, fs, path::Path};

pub struct CutOptions<'a> {
    pub match_dir: &'a Path,
    pub repo_root: &'a Path,
    pub ghost_store: Option<&'a Path>,
    pub made: &'a str,
    pub include_unfinished: bool,
}

#[derive(Debug, Default)]
pub struct CutReport {
    pub records: usize,
    pub skipped_unfinished: usize,
    pub run_ids: Vec<String>,
}

#[derive(Deserialize)]
struct GameRow {
    game: usize,
    seed: String,
    seats: Vec<SeatRow>,
}

#[derive(Deserialize)]
struct SeatRow {
    seat: i64,
    bot: String,
    label: Option<String>,
}

#[derive(Deserialize)]
struct Header {
    format: i64,
    seed: String,
    build: Value,
    recipe: Recipe,
}

#[derive(Deserialize)]
struct Recipe {
    kind: String,
    paths: Vec<String>,
    tribes: Vec<String>,
}

#[derive(Default)]
struct SeatTurns {
    acts: Vec<Act>,
    turns: Vec<RunTurn>,
}

type ReplayedRecord = (GameSessionRef, BTreeMap<i64, SeatTurns>, bool);

pub fn cut_match(options: &CutOptions<'_>, store: &FolderStore) -> Result<CutReport, String> {
    let games_path = options.match_dir.join("games.jsonl");
    let mut games = BTreeMap::new();
    for (i, line) in at(&games_path, fs::read_to_string(&games_path))?
        .lines()
        .enumerate()
    {
        let row: GameRow =
            parse_line(line, i + 1).map_err(|e| format!("{}: {e}", games_path.display()))?;
        let id = row.game;
        if games.insert(id, row).is_some() {
            return Err(format!("{}: duplicate game {id}", games_path.display()));
        }
    }
    let records_dir = options.match_dir.join("records");
    let mut paths = Vec::new();
    for entry in at(&records_dir, fs::read_dir(&records_dir))? {
        let path = at(&records_dir, entry)?.path();
        if path.extension().is_some_and(|ext| ext == "jsonl") {
            paths.push(path);
        }
    }
    paths.sort_unstable();
    if paths.is_empty() {
        return Err(format!("{}: no JSONL records", records_dir.display()));
    }

    let mut report = CutReport::default();
    for path in paths {
        let game_id = path
            .file_stem()
            .and_then(|stem| stem.to_str())
            .and_then(|stem| stem.strip_prefix("game-"))
            .and_then(|id| id.parse::<usize>().ok())
            .ok_or_else(|| format!("{}: expected a game-NNNNN.jsonl filename", path.display()))?;
        let bytes = at(&path, fs::read(&path))?;
        let Some(runs) = at(&path, cut_record(options, &bytes, games.get(&game_id)))? else {
            report.skipped_unfinished += 1;
            continue;
        };
        // Validate the whole record's runs before publishing any of them.
        let runs: Vec<_> = at(
            &path,
            runs.iter().map(Run::to_bytes).collect::<Result<_, _>>(),
        )?;
        store.archive_record(&bytes)?;
        for run in runs {
            report.run_ids.push(store.add(&run)?);
        }
        report.records += 1;
    }
    Ok(report)
}

fn cut_record(
    options: &CutOptions<'_>,
    bytes: &[u8],
    row: Option<&GameRow>,
) -> Result<Option<Vec<Run>>, String> {
    let mut lines = std::str::from_utf8(bytes)
        .map_err(|e| e.to_string())?
        .lines();
    let first = lines.next().ok_or("empty record")?;
    let header: Header = parse_line(first, 1)?;
    let (game, seats, complete) = match header.format {
        3 | 4 => replay_record(options, first, lines)?,
        format => {
            return Err(format!(
                "unsupported record format {format}; expected format 3 or 4"
            ));
        }
    };
    if !complete && !options.include_unfinished {
        return Ok(None);
    }
    let row = row.ok_or("missing game in games.jsonl")?;
    if row.seed != header.seed {
        return Err(format!(
            "seed differs from game {} in games.jsonl",
            row.game
        ));
    }
    let mut meta = BTreeMap::new();
    for seat in &row.seats {
        if meta.insert(seat.seat, seat).is_some() {
            return Err(format!("duplicate seat {} in games.jsonl", seat.seat));
        }
    }
    let content = header
        .recipe
        .paths
        .iter()
        .map(|path| {
            Path::new(&RecordReplay::content_folder(options.repo_root, path))
                .file_name()
                .and_then(|name| name.to_str())
                .map(str::to_owned)
                .ok_or_else(|| format!("invalid content path {path:?}"))
        })
        .collect::<Result<Vec<_>, _>>()?;
    let fingerprints = card_fingerprints(options.repo_root, &header.recipe)?;
    let record_sha256 = sha256(bytes);
    let game = game.borrow();
    if meta
        .keys()
        .any(|&seat| !(0..game.players.len() as i64).contains(&seat))
    {
        return Err("invalid seat in games.jsonl".into());
    }
    if let Some(seat) = meta.keys().find(|seat| !seats.contains_key(seat)) {
        return Err(format!(
            "games.jsonl names seat {seat}, a run seat in the record"
        ));
    }
    let mode = if game.is_async() { "async" } else { "live" };
    let survivors = game.alive_players().len();
    let mut runs = Vec::new();
    for (seat, data) in seats {
        let label = meta
            .get(&seat)
            .ok_or_else(|| format!("missing seat {seat} in games.jsonl"))?;
        if label.bot == "tribe" || label.bot.starts_with("tribe-") {
            return Err(format!(
                "seat {seat} is TribeBot ({}), retired as a player on 20 Nov 2026 (owner): \
                 its runs can't become ghosts",
                label.bot
            ));
        }
        let player = game.player(seat);
        let player = player.borrow();
        let ended = if !player.alive {
            Ended::Eliminated
        } else if !complete {
            Ended::Unfinished
        } else if survivors > 1 {
            Ended::RoundLimit
        } else {
            Ended::Won
        };
        let mut cards = BTreeMap::new();
        for turn in &data.turns {
            for id in turn.card_ids()? {
                let hash = fingerprints
                    .get(id)
                    .ok_or_else(|| format!("missing card data for {id}"))?;
                cards.insert(id.to_owned(), hash.clone());
            }
        }
        let last_turn = data.turns.last().map_or(0, |turn| turn.turn);
        runs.push(Run {
            format: RUN_FORMAT,
            rules: header.build.clone(),
            patch: String::new(),
            content: content.clone(),
            tribes: header.recipe.tribes.clone(),
            source: RunSource {
                kind: SourceKind::Bot,
                label: label.label.clone().unwrap_or_else(|| label.bot.clone()),
                player: label.bot.clone(),
                rating: None,
                record_sha256: record_sha256.clone(),
                record_mode: mode.into(),
                game_seed: header.seed.clone(),
                seat,
            },
            made: options.made.into(),
            placement: player.placement,
            last_turn,
            ended,
            cards,
            turns: data.turns,
        });
    }
    Ok(Some(runs))
}

fn replay_record<'a>(
    options: &CutOptions<'_>,
    header: &str,
    lines: impl Iterator<Item = &'a str>,
) -> Result<ReplayedRecord, String> {
    // The header replay checks format, build, content and the initial state hash. Then use
    // the same replay step for every line so we can read the session right before each fight.
    let initial = RecordReplay::rebuild_to_with_store(
        options.repo_root,
        &Array::from(vec![godot_json::parse_string(header).as_dict()]),
        Some(0),
        options.ghost_store,
    );
    let game = initial.session.ok_or(initial.message)?;
    let state = game.borrow();
    let mut seats: BTreeMap<_, _> = (0..state.players.len() as i64)
        .filter(|&seat| !state.is_run_seat(seat))
        .map(|seat| (seat, SeatTurns::default()))
        .collect();
    drop(state);
    let mut phase = String::from("between");
    for (i, line) in lines.enumerate() {
        let raw: Value = parse_line(line, i + 2)?;
        let entry = godot_json::parse_string(line).as_dict();
        phase = RecordReplay::_step(&game, &entry, &phase).map_err(|e| e.message)?;
        match raw["op"].as_str() {
            Some("act") => {
                let act = serde_json::from_value(raw.clone())
                    .map_err(|e| format!("line {}: {e}", i + 2))?;
                let seat = raw["player"].as_i64().ok_or("invalid act seat")?;
                seats
                    .get_mut(&seat)
                    .ok_or("invalid act seat")?
                    .acts
                    .push(act);
            }
            Some("fight_boards") => {
                let game = game.borrow();
                let turn = game.round_number as usize;
                let players = raw["players"].as_array().ok_or("missing fight payloads")?;
                for payload in players {
                    let seat = payload["id"].as_i64().ok_or("fight payload has no seat")?;
                    if seat == Matchmaking::GHOST || game.is_run_seat(seat) {
                        continue;
                    }
                    let data = seats.get_mut(&seat).ok_or("invalid fight payload seat")?;
                    let player = game.player(seat);
                    let player = player.borrow();
                    data.turns.push(RunTurn {
                        turn,
                        tier: player.tier,
                        health: player.health,
                        armor: player.armor,
                        gold: player.gold,
                        acts: std::mem::take(&mut data.acts),
                        payload: payload.clone(),
                    });
                }
            }
            _ => {}
        }
        if matches!(raw["op"].as_str(), Some("finish")) {
            let state = game.borrow();
            state.events.clear();
            state.fights.clear();
        }
    }
    let complete = game.borrow().over && phase == "between";
    Ok((game, seats, complete))
}

fn parse_line<T: serde::de::DeserializeOwned>(line: &str, number: usize) -> Result<T, String> {
    serde_json::from_str(line).map_err(|e| format!("line {number}: {e}"))
}

fn card_fingerprints(root: &Path, recipe: &Recipe) -> Result<BTreeMap<String, String>, String> {
    // UnitLibrary embeds this raw data entry in with_system_cards and exposes only its
    // parsed definition. Hash the raw entry, like the entries in units.json.
    let triple_reward = serde_json::json!({
        "id": UnitLibrary::TRIPLE_REWARD_ID, "name": "Triple Reward", "kind": "spell",
        "tier": 1, "cost": 0, "offered": false, "effects": [{"mechanic": "triple_reward"}]
    });
    let mut cards = BTreeMap::from([(
        UnitLibrary::TRIPLE_REWARD_ID.into(),
        fingerprint(triple_reward)?,
    )]);
    let files = recipe.paths.iter().map(|folder| {
        resolve(root, &RecordReplay::content_folder(root, folder)).join("units.json")
    });
    for file in files.filter(|file| file.is_file()) {
        load_card_data(&file, &mut cards)?;
    }
    if recipe.kind == "game" {
        // Folder cards take precedence. GameContent may supply stand-in spells for a
        // lobby without tribe spells or the whole stand-in set for an empty lobby.
        load_card_data(&resolve(root, GameContent::STAND_IN_PATH), &mut cards)?;
    }
    Ok(cards)
}

fn load_card_data(file: &Path, cards: &mut BTreeMap<String, String>) -> Result<(), String> {
    let bytes = at(file, fs::read(file))?;
    let data: Value = at(file, serde_json::from_slice(&bytes))?;
    let entries = data["cards"]
        .as_array()
        .ok_or_else(|| format!("{}: missing cards", file.display()))?;
    for entry in entries {
        let id = entry["id"]
            .as_str()
            .ok_or_else(|| format!("{}: card is missing its id", file.display()))?;
        if !cards.contains_key(id) {
            cards.insert(id.into(), fingerprint(entry.clone())?);
        }
    }
    Ok(())
}

fn fingerprint(mut entry: Value) -> Result<String, String> {
    entry.sort_all_objects();
    let bytes = serde_json::to_vec(&entry).map_err(|e| e.to_string())?;
    Ok(sha256(&bytes)[..16].to_owned())
}
