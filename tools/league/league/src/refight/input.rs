//! The fight log supplies each round's ordered pairings and original results.
use crate::matchrun;
use bramble_engine::core::records::game_record::GameRecord;
use bramble_engine::core::session::matchmaking::Matchmaking;
use bramble_engine::util::godot_json;
use bramble_engine::{Array, Dictionary, Variant};
use serde_json::Value;
use std::collections::{BTreeMap, BTreeSet};
use std::fs::{self, File};
use std::io::{BufRead, BufReader};
use std::path::Path;
use std::sync::atomic::{AtomicBool, Ordering};

static NO_FIELD_WARNED: AtomicBool = AtomicBool::new(false);

pub(super) struct Match {
    pub content: String,
    pub games: Vec<Game>,
}

pub(super) struct Game {
    pub index: usize,
    pub seed: i64,
    pub rounds: Vec<Round>,
}

pub(super) struct Round {
    pub number: i64,
    pub fights: Vec<Fight>,
}

pub(super) struct Fight {
    pub players: [i64; 2],
    pub ghost_of: Option<i64>,
    pub winner: Option<i64>,
    pub damage: i64,
    pub result: Value,
}

pub(super) fn read_json(path: &Path) -> Result<Value, String> {
    fs::read(path)
        .map_err(|e| format!("{}: {e}", path.display()))
        .and_then(|bytes| {
            serde_json::from_slice(&bytes).map_err(|e| format!("{}: {e}", path.display()))
        })
}

fn lines(path: &Path) -> Result<impl Iterator<Item = Result<String, String>> + '_, String> {
    let file = File::open(path).map_err(|e| format!("{}: {e}", path.display()))?;
    Ok(BufReader::new(file)
        .lines()
        .enumerate()
        .map(move |(i, line)| line.map_err(|e| format!("{}:{}: {e}", path.display(), i + 1))))
}

pub(super) fn read_match(dir: &Path, verify: bool) -> Result<Match, String> {
    let manifest = read_json(&dir.join("summary.json"))?;
    if manifest["complete"] != true {
        return Err("summary.json: expected a completed league match".into());
    }
    let content = manifest["content"]
        .as_str()
        .ok_or("summary.json: missing content")?;
    let path = dir.join("games.jsonl");
    let mut games = Vec::new();
    for (i, line) in lines(&path)?.enumerate() {
        let line = line?;
        let game = serde_json::from_str(&line)
            .map_err(|e| format!("{}:{}: {e}", path.display(), i + 1))?;
        games.push(
            parse_game(game, i, verify)
                .map_err(|e| format!("{}:{}: {e}", path.display(), i + 1))?,
        );
    }
    if games.is_empty() || manifest["games"].as_u64() != Some(games.len() as u64) {
        return Err("games.jsonl: game count differs from summary.json or is zero".into());
    }
    Ok(Match {
        content: content.into(),
        games,
    })
}

fn parse_game(mut log: Value, index: usize, verify: bool) -> Result<Game, String> {
    if log["game"].as_u64() != Some(index as u64) {
        return Err(format!("expected game index {index}"));
    }
    let seed = log["seed"]
        .as_str()
        .and_then(|s| s.parse().ok())
        .ok_or("invalid game seed")?;
    let rounds = log["fights"].as_array_mut().ok_or("missing round fights")?;
    let rounds: Vec<_> = rounds
        .iter_mut()
        .enumerate()
        .map(|(i, round)| {
            let number = i as i64 + 1;
            if round["round"].as_i64() != Some(number) {
                return Err(format!("expected round {number}"));
            }
            let fights = round["fights"].as_array_mut().ok_or("missing fights")?;
            let mut seen = BTreeSet::new();
            let fights = fights
                .iter_mut()
                .map(|f| {
                    let fight = parse_fight(f, verify)?;
                    if !fight.players.into_iter().all(|id| seen.insert(id)) {
                        return Err("a player appears twice in one round".into());
                    }
                    Ok(fight)
                })
                .collect::<Result<Vec<_>, String>>()
                .map_err(|e| format!("round {number}: {e}"))?;
            Ok(Round { number, fights })
        })
        .collect::<Result<_, String>>()?;
    if rounds.is_empty()
        || log["rounds"].as_u64() != Some(rounds.len() as u64)
        || rounds.iter().all(|r| r.fights.is_empty())
    {
        return Err("missing logged rounds or fights".into());
    }
    Ok(Game {
        index,
        seed,
        rounds,
    })
}

fn parse_fight(log: &mut Value, verify: bool) -> Result<Fight, String> {
    let a = log["a"]
        .as_i64()
        .filter(|&a| a >= 0)
        .ok_or("invalid player a")?;
    let b = log["b"]
        .as_i64()
        .filter(|&b| b >= Matchmaking::GHOST)
        .ok_or("invalid player b")?;
    let players = [a, b];
    let winner = match log.get("winner") {
        Some(Value::Null) => None,
        Some(winner) => Some(
            winner
                .as_i64()
                .filter(|id| players.contains(id))
                .ok_or("invalid winner")?,
        ),
        None => return Err("missing winner".into()),
    };
    let damage = log["damage"].as_i64().ok_or("missing damage")?;
    let ghost_of = log["ghost_of"].as_i64();
    let result = if verify {
        if !log["result"].is_object() {
            return Err("missing original combat result".into());
        }
        log["result"].take()
    } else {
        Value::Null
    };
    Ok(Fight {
        players,
        ghost_of,
        winner,
        damage,
        result,
    })
}

pub(super) fn read_boards(
    dir: &Path,
    game: &Game,
) -> Result<BTreeMap<i64, Array<Variant>>, String> {
    let path = matchrun::out_path(&dir.join("records"), game.index);
    let mut lines = lines(&path)?;
    let header = godot_json::parse_string(
        &lines
            .next()
            .ok_or_else(|| format!("{}: empty record", path.display()))??,
    )
    .as_dict();
    if header.get("op").as_text() != "header"
        || header.get("format").as_i64() != GameRecord::FORMAT
        || header.get("seed").as_text().parse::<i64>() != Ok(game.seed)
    {
        return Err(format!(
            "{}: expected a format-{} header for seed {}",
            path.display(),
            GameRecord::FORMAT,
            game.seed
        ));
    }
    let runs: Vec<(i64, String)> = if header.get("mode").as_text() == "async" {
        let listed = header.get("runs").as_array();
        let listed = listed.borrow();
        listed
            .iter()
            .map(|run| {
                let run = run.as_dict();
                (run.get("seat").as_i64(), run.get("id").as_text())
            })
            .collect()
    } else {
        Vec::new()
    };
    let attached = super::restore::recorded_seats(&runs)
        .map_err(|e| format!("{}: recorded run: {e}", path.display()))?;
    if !attached && !NO_FIELD_WARNED.swap(true, Ordering::Relaxed) {
        eprintln!(
            "refight: this match was played against recorded runs. Pass --field <the match's field> so \
             those seats fight as recorded; without it a few fights do not reproduce and are left out."
        );
    }
    let mut snapshots = BTreeMap::new();
    let mut finished = Vec::new();
    for (i, line) in lines.enumerate() {
        let Variant::Dictionary(entry) = godot_json::parse_string(&line?) else {
            return Err(format!("{}:{}: invalid record line", path.display(), i + 2));
        };
        let round = entry.get("turn").as_i64();
        match entry.get("op").as_text().as_str() {
            "fight_boards" => {
                if snapshots
                    .insert(round, entry.get("players").as_array())
                    .is_some()
                {
                    return Err(format!(
                        "{}: repeated fight_boards for round {round}",
                        path.display()
                    ));
                }
            }
            "finish" => finished.push(round),
            _ => {}
        }
    }
    if !finished
        .into_iter()
        .eq(game.rounds.iter().map(|r| r.number))
        || snapshots
            .keys()
            .any(|&n| n < 1 || n > game.rounds.len() as i64)
    {
        return Err(format!(
            "{}: rounds differ from games.jsonl",
            path.display()
        ));
    }
    Ok(snapshots)
}

pub(super) fn payload(players: Option<&Array<Variant>>, id: i64) -> Result<Dictionary, String> {
    let Some(players) = players else {
        return Err("missing fight_boards snapshot".into());
    };
    let players = players.borrow();
    let mut matching = players.iter().filter_map(|entry| match entry {
        Variant::Dictionary(entry) if integer(&entry.get("id")) == Some(id) => Some(entry.clone()),
        _ => None,
    });
    let found = matching
        .next()
        .ok_or_else(|| format!("missing payload for player {id}"))?;
    if matching.next().is_some() {
        return Err(format!("multiple payloads for player {id}"));
    }
    Ok(found)
}

pub(super) fn check_pairings(
    round: &Round,
    players: Option<&Array<Variant>>,
) -> Result<(), String> {
    let paired: BTreeSet<_> = round.fights.iter().flat_map(|f| f.players).collect();
    let recorded: BTreeSet<_> = players
        .into_iter()
        .flat_map(Array::to_vec)
        .filter_map(|player| integer(&player.as_dict().get("id")))
        .collect();
    if paired.is_subset(&recorded)
        && let Some(id) = recorded.difference(&paired).next()
    {
        return Err(format!(
            "round {}: no logged fight for player {id}",
            round.number
        ));
    }
    Ok(())
}

pub(super) fn integer(value: &Variant) -> Option<i64> {
    match value {
        Variant::Int(n) => Some(*n),
        Variant::Float(n) if n.fract() == 0.0 && *n >= i64::MIN as f64 && *n < i64::MAX as f64 => {
            Some(*n as i64)
        }
        _ => None,
    }
}
