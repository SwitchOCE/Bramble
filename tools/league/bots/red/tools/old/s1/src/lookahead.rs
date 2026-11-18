use league_api::{BotView, PastFight, Sim, SnapUnit};

pub struct BuyEval {
    pub shop_index: usize,
    pub score: f64,
}

#[derive(Default)]
struct FightScores {
    sum: f64,
    count: usize,
}

impl FightScores {
    fn mean(&self) -> Option<f64> {
        (self.count > 0).then(|| self.sum / self.count as f64)
    }
}

fn opponents(view: &BotView, limit: usize) -> Vec<&PastFight> {
    let next = view.last_payload_of(view.opponent());
    let living = view.past().iter().rev().filter(|fight| {
        view.players()
            .iter()
            .any(|p| p.id == fight.opponent && p.id != view.me().id && p.alive)
    });
    let mut selected: Vec<&PastFight> = Vec::new();
    for fight in next.into_iter().chain(living) {
        if selected
            .iter()
            .all(|prior| prior.opponent != fight.opponent)
        {
            selected.push(fight);
            if selected.len() == limit {
                break;
            }
        }
    }
    selected
}

/// Compare the current board with buying and placing each candidate unit.
/// Each score averages the fights that finished successfully before the clock cutoff.
pub fn eval_buys(
    view: &BotView,
    sim: &mut Sim,
    candidates: &[usize],
    replace_uid: Option<i64>,
    max_opps: usize,
    seeds: usize,
    floor_ns: i64,
) -> (Option<f64>, Vec<BuyEval>) {
    // Reserve 2 ms initially, then raise the estimate if an observed fight costs more.
    let mut fight_ns = 2_000_000;
    if max_opps == 0 || seeds == 0 || sim.clock_left_ns().saturating_sub(fight_ns) < floor_ns {
        return (None, Vec::new());
    }
    let opponents = opponents(view, max_opps);
    if opponents.is_empty() {
        return (None, Vec::new());
    }

    let me = view.me();
    let base = me.payload();
    // Slot order is already front row, then back row.
    let slot = me.board.iter().position(Option::is_none).or_else(|| {
        let replace_uid = replace_uid?;
        me.board
            .iter()
            .position(|unit| unit.as_ref().is_some_and(|unit| unit.uid == replace_uid))
    });
    let uid = me.all_cards().map(|unit| unit.uid).max().unwrap_or(0);
    let mut buys = Vec::new();
    if let (Some(slot), Some(uid)) = (slot, uid.checked_add(1)) {
        for &shop_index in candidates {
            if sim.clock_left_ns().saturating_sub(fight_ns) < floor_ns {
                break;
            }
            let Some(def) = me.shop_units.get(shop_index).filter(|def| !def.is_empty()) else {
                continue;
            };
            let mut payload = base.clone();
            payload.set_board(slot, Some(SnapUnit::fresh(def, uid, false)));
            buys.push((shop_index, payload, FightScores::default()));
        }
    }

    let mut base_scores = FightScores::default();
    'samples: for _ in 0..seeds {
        let seed = sim.next_seed();
        for opponent in &opponents {
            let variants = buys
                .iter_mut()
                .map(|(_, payload, scores)| (&*payload, scores));
            for (payload, scores) in std::iter::once((base, &mut base_scores)).chain(variants) {
                let before = sim.clock_left_ns();
                if before.saturating_sub(fight_ns) < floor_ns {
                    break 'samples;
                }
                let result = sim.fight(payload, &opponent.payload, seed);
                fight_ns = fight_ns.max(before.saturating_sub(sim.clock_left_ns()));
                if let Ok(result) = result {
                    let sign = match result.winner {
                        0 => 1.0,
                        1 => -1.0,
                        _ => 0.0,
                    };
                    scores.sum += sign * (1.0 + 0.01 * result.damage as f64);
                    scores.count = scores.count.saturating_add(1);
                }
            }
        }
    }

    let buys = buys
        .into_iter()
        .filter_map(|(shop_index, _, scores)| {
            Some(BuyEval {
                shop_index,
                score: scores.mean()?,
            })
        })
        .collect();
    (base_scores.mean(), buys)
}
