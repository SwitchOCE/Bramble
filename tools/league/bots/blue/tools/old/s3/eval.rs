//! Board strength by simulated fights against boards we have seen.
use league_api::{BotView, Payload, Sim, SnapUnit};

pub struct Evaluator {
    /// (payload, weight)
    pub opps: Vec<(Payload, f64)>,
    pub seeds: Vec<i64>,
    pub fights: i64,
}

impl Evaluator {
    /// Opponents: this round's opponent's latest board (if seen) and the latest board of up to
    /// `n_opp - 1` other players we have fought, most recent first.
    pub fn new(view: &BotView, sim: &mut Sim, n_opp: usize, n_seeds: usize) -> Option<Self> {
        let past = view.past();
        if past.is_empty() {
            return None;
        }
        let alive: Vec<i64> = view
            .players()
            .iter()
            .filter(|p| p.alive)
            .map(|p| p.id)
            .collect();
        let mut opps: Vec<(Payload, f64)> = Vec::new();
        let mut seen: Vec<i64> = Vec::new();
        let next = view.opponent();
        if let Some(f) = view.last_payload_of(next) {
            opps.push((f.payload.clone(), 2.0));
            seen.push(next);
        }
        for f in past.iter().rev() {
            if opps.len() >= n_opp {
                break;
            }
            if seen.contains(&f.opponent) {
                continue;
            }
            if f.opponent >= 0 && !alive.contains(&f.opponent) {
                continue;
            }
            seen.push(f.opponent);
            let age = (view.round() - f.round).max(0) as f64;
            opps.push((f.payload.clone(), 1.0 / (1.0 + 0.3 * age)));
        }
        if opps.is_empty() {
            // Only dead opponents seen: use the latest anyway.
            let f = past.last()?;
            opps.push((f.payload.clone(), 1.0));
        }
        let seeds = (0..n_seeds).map(|_| sim.next_seed()).collect();
        Some(Self {
            opps,
            seeds,
            fights: 0,
        })
    }

    /// Weighted mean score of `mine` (1 win, 0.5 tie, 0 loss, minus a little for damage).
    pub fn score(&mut self, sim: &mut Sim, mine: &Payload) -> f64 {
        let mut total = 0.0;
        let mut weight = 0.0;
        for (opp, w) in &self.opps {
            for &seed in &self.seeds {
                // Clock guard: never run a fight with under 100 ms left for the game.
                if sim.clock_left_ns() < 100_000_000 {
                    break;
                }
                self.fights += 1;
                let Ok(out) = sim.fight(mine, opp, seed) else {
                    continue;
                };
                let s = match out.winner {
                    0 => 1.0,
                    -1 => 0.5,
                    _ => -0.01 * out.damage as f64,
                };
                total += s * w;
                weight += w;
            }
        }
        if weight > 0.0 { total / weight } else { 0.0 }
    }
}

/// `base` with its board replaced by `board` (one entry per slot).
pub fn with_board(base: &Payload, board: &[Option<SnapUnit>]) -> Payload {
    let mut p = base.clone();
    for (i, u) in board.iter().enumerate() {
        p.set_board(i, u.clone());
    }
    p
}
