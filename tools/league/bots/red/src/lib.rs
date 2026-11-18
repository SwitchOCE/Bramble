//! The red team's bot. It starts as a copy of `bots/examples/clean`; the team replaces it.
//! Rules: brief 5a and tools/league/league/README.md (`check-crate`). Tables built offline go
//! in `data/` and come in with `include_bytes!("../data/...")`; `tools/` is out of reach.
#![forbid(unsafe_code)]

use league_api::{Action, Bot, BotSetup, BotView, Report, Rng, Sim};

pub struct Clean {
    rng: Rng,
    looked: i64,
}

/// The league's constructor.
pub fn new_bot(seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
    Box::new(Clean {
        rng: Rng::new(seed as i64),
        looked: -1,
    })
}

fn value(view: &BotView, card: &str) -> f64 {
    view.library().get(card).map_or(0.0, |c| {
        c.tier as f64 * 10.0 + (c.attack + c.health) as f64 * 0.2
    })
}

impl Bot for Clean {
    fn choose(&mut self, view: &BotView, sim: &mut Sim) -> usize {
        let me = view.me();
        let legal = view.legal();
        let mut best = legal.len() - 1;
        let mut best_score = 0.0;
        for (i, action) in legal.iter().enumerate() {
            let score = match action {
                Action::Pick { index } => {
                    100.0 + value(view, &me.discover_options[*index as usize])
                }
                Action::Buy {
                    spell: false,
                    index,
                } if me.board_count() + (me.hand.len() as i64) < 7 => {
                    40.0 + value(view, &me.shop_units[*index as usize])
                }
                Action::Play { slot, .. } if *slot >= 0 => 80.0 - *slot as f64,
                Action::Upgrade if me.tier < 1 + (view.round() + 1) / 2 => 70.0,
                _ => -1.0,
            };
            if score > best_score {
                best_score = score;
                best = i;
            }
        }
        if best_score > 0.0 {
            return best;
        }
        // About to end the turn: one lookahead fight, once a round.
        if self.looked != view.round() {
            self.looked = view.round();
            if let Some(last) = view.last_payload_of(view.opponent()) {
                let seed = sim.next_seed() ^ self.rng.next_u32();
                if let Ok(outcome) = sim.fight(me.payload(), &last.payload, seed)
                    && outcome.winner == 1
                    && let Some(refresh) = legal.iter().position(|a| *a == Action::Refresh)
                {
                    return refresh;
                }
            }
        }
        legal
            .iter()
            .position(|a| *a == Action::EndTurn)
            .unwrap_or(0)
    }

    fn report(&mut self, view: &BotView, _sim: &mut Sim) -> Option<Report> {
        let me = view.me();
        let offered = me
            .shop_units
            .iter()
            .chain(me.discover_options.iter())
            .filter(|c| !c.is_empty());
        Some(Report {
            strategy: "greedy".into(),
            values: offered.map(|c| (c.clone(), value(view, c))).collect(),
        })
    }
}
