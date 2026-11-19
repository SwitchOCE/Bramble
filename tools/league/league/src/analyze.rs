//! `league analyze <dir>`: the score (each colour's average placement and the red-minus-blue
//! gap, with 95% intervals over the seed pairs), placement by seat and by colour, and the
//! health counts. Writes `analysis.json` beside the logs and returns a short text report.
use serde_json::{Value, json};
use std::collections::BTreeMap;
use std::path::Path;

/// Mean and 95% half-width (normal approximation) of `xs`.
pub fn mean_ci(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    if xs.is_empty() {
        return (0.0, 0.0);
    }
    let mean = xs.iter().sum::<f64>() / n;
    if xs.len() < 2 {
        return (mean, 0.0);
    }
    let var = xs.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / (n - 1.0);
    (mean, 1.96 * (var / n).sqrt())
}

fn read_lines(path: &Path) -> Result<Vec<Value>, String> {
    let text = std::fs::read_to_string(path).map_err(|e| format!("{}: {e}", path.display()))?;
    text.lines()
        .filter(|l| !l.trim().is_empty())
        .map(|l| serde_json::from_str(l).map_err(|e| format!("{}: {e}", path.display())))
        .collect()
}

pub fn analyze(dir: &Path) -> Result<String, String> {
    let games = read_lines(&dir.join("games.jsonl"))?;
    if games.is_empty() {
        return Err("no games".into());
    }
    let cpu = read_lines(&dir.join("cpu.jsonl")).unwrap_or_default();
    let timing: Option<Value> = std::fs::read_to_string(dir.join("timing.json"))
        .ok()
        .and_then(|t| serde_json::from_str(&t).ok());

    // Per game: each colour's mean place. Per seed pair: their average.
    let mut by_pair: BTreeMap<u64, Vec<(f64, f64)>> = BTreeMap::new();
    let mut seat_places: BTreeMap<i64, Vec<f64>> = BTreeMap::new();
    let mut colour_places: BTreeMap<String, Vec<f64>> = BTreeMap::new();
    let mut seat_colour: BTreeMap<(i64, String), Vec<f64>> = BTreeMap::new();
    let mut health: BTreeMap<String, BTreeMap<&str, i64>> = BTreeMap::new();
    let (mut limit_games, mut draws, mut rounds) = (0, 0, 0i64);
    let mut bots: BTreeMap<String, String> = BTreeMap::new();
    for g in &games {
        let seats = g["seats"].as_array().ok_or("games.jsonl: no seats")?;
        let mut sums: BTreeMap<String, (f64, f64)> = BTreeMap::new();
        let mut seen_places = Vec::new();
        for s in seats {
            let colour = s["colour"].as_str().unwrap_or("none").to_owned();
            let place = s["place"].as_f64().unwrap_or(0.0);
            let seat = s["seat"].as_i64().unwrap_or(-1);
            bots.insert(colour.clone(), s["bot"].as_str().unwrap_or("").to_owned());
            seen_places.push(place as i64);
            let e = sums.entry(colour.clone()).or_insert((0.0, 0.0));
            e.0 += place;
            e.1 += 1.0;
            seat_places.entry(seat).or_default().push(place);
            colour_places.entry(colour.clone()).or_default().push(place);
            seat_colour
                .entry((seat, colour.clone()))
                .or_default()
                .push(place);
            let h = health.entry(colour).or_default();
            *h.entry("seats").or_insert(0) += 1;
            *h.entry("clock_outs").or_insert(0) += i64::from(!s["clock_out"].is_null());
            *h.entry("panics").or_insert(0) += i64::from(!s["panic"].is_null());
            *h.entry("faults").or_insert(0) += i64::from(!s["fault"].is_null());
            *h.entry("refused").or_insert(0) += s["refused"].as_i64().unwrap_or(0);
        }
        seen_places.sort();
        if seen_places.windows(2).any(|w| w[0] == w[1]) {
            draws += 1;
        }
        if g["round_limit_hit"].as_bool().unwrap_or(false) {
            limit_games += 1;
        }
        rounds += g["rounds"].as_i64().unwrap_or(0);
        let mean = |c: &str| sums.get(c).map_or(f64::NAN, |(s, n)| s / n);
        by_pair
            .entry(g["game"].as_u64().ok_or("games.jsonl: no game index")? / 2)
            .or_default()
            .push((mean("red"), mean("blue")));
    }
    let pair_red: Vec<f64> = by_pair
        .values()
        .map(|v| v.iter().map(|x| x.0).sum::<f64>() / v.len() as f64)
        .collect();
    let pair_blue: Vec<f64> = by_pair
        .values()
        .map(|v| v.iter().map(|x| x.1).sum::<f64>() / v.len() as f64)
        .collect();
    let pair_gap: Vec<f64> = by_pair
        .values()
        .map(|v| v.iter().map(|x| x.0 - x.1).sum::<f64>() / v.len() as f64)
        .collect();
    let (red, red_ci) = mean_ci(&pair_red);
    let (blue, blue_ci) = mean_ci(&pair_blue);
    let (gap, gap_ci) = mean_ci(&pair_gap);
    let winner = if gap.is_nan() || (gap.abs() <= gap_ci) {
        "none outside the noise"
    } else if gap < 0.0 {
        "red"
    } else {
        "blue"
    };
    let seats: Vec<Value> = seat_places
        .iter()
        .map(|(s, v)| {
            let (m, c) = mean_ci(v);
            json!({"seat": s, "games": v.len(), "avg_place": m, "ci95": c})
        })
        .collect();
    let colours: Vec<Value> = colour_places
        .iter()
        .map(|(k, v)| {
            let (m, c) = mean_ci(v);
            json!({"colour": k, "seats": v.len(), "avg_place": m, "ci95_seats": c})
        })
        .collect();
    let seat_by_colour: Vec<Value> = seat_colour
        .iter()
        .map(|((s, k), v)| {
            let (m, c) = mean_ci(v);
            json!({"seat": s, "colour": k, "games": v.len(), "avg_place": m, "ci95": c})
        })
        .collect();
    let mut cpu_by_colour: BTreeMap<String, Vec<f64>> = BTreeMap::new();
    for (g, c) in games.iter().zip(cpu.iter()) {
        for (s, cs) in g["seats"]
            .as_array()
            .into_iter()
            .flatten()
            .zip(c["seats"].as_array().into_iter().flatten())
        {
            cpu_by_colour
                .entry(s["colour"].as_str().unwrap_or("none").to_owned())
                .or_default()
                .push(cs["cpu_ms"].as_f64().unwrap_or(0.0));
        }
    }
    let cpu_summary: BTreeMap<String, Value> = cpu_by_colour
        .iter()
        .map(|(k, v)| {
            let mut sorted = v.clone();
            sorted.sort_by(|a, b| a.partial_cmp(b).expect("finite"));
            (k.clone(), json!({"mean_ms": v.iter().sum::<f64>() / v.len() as f64, "max_ms": sorted.last(), "median_ms": sorted[sorted.len() / 2]}))
        })
        .collect();
    let seconds_per_game = timing.as_ref().and_then(|t| t["seconds_per_game"].as_f64());
    let report = json!({
        "games": games.len(), "seed_pairs": by_pair.len(), "bots": bots,
        "score": {
            "red_avg_place": red, "red_ci95": red_ci,
            "blue_avg_place": blue, "blue_ci95": blue_ci,
            "gap_red_minus_blue": gap, "gap_ci95": gap_ci, "winner": winner,
        },
        "placement_by_seat": seats, "placement_by_colour": colours, "placement_by_seat_and_colour": seat_by_colour,
        "health": {
            "by_colour": health, "games_at_round_limit": limit_games, "draws": draws,
            "rounds_mean": rounds as f64 / games.len() as f64,
            "wall_seconds_per_game": seconds_per_game, "seat_cpu": cpu_summary,
        },
    });
    std::fs::write(dir.join("analysis.json"), format!("{report:#}\n"))
        .map_err(|e| e.to_string())?;
    let mut text = format!(
        "{} games, {} seed pairs: red ({}) {:.3} ± {:.3}, blue ({}) {:.3} ± {:.3}; red minus blue {:+.3} ± {:.3}: winner {}\n",
        games.len(),
        by_pair.len(),
        bots.get("red").map_or("", String::as_str),
        red,
        red_ci,
        bots.get("blue").map_or("", String::as_str),
        blue,
        blue_ci,
        gap,
        gap_ci,
        winner
    );
    text += "placement by seat: ";
    text += &seat_places
        .iter()
        .map(|(s, v)| format!("{s}:{:.2}", mean_ci(v).0))
        .collect::<Vec<_>>()
        .join(" ");
    text += "\n";
    for (colour, h) in &health {
        text += &format!("{colour}: {h:?}\n");
    }
    text += &format!(
        "games at the round limit: {limit_games}; draws: {draws}; wall s/game: {}\n",
        seconds_per_game.map_or("?".into(), |s| format!("{s:.3}"))
    );
    text += "(full figures in analysis.json)";
    Ok(text)
}
