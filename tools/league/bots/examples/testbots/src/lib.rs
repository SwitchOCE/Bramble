//! Bots for the harness's own gates. None of them is a real player.
#![forbid(unsafe_code)]

use league_api::{Action, Bot, BotSetup, BotView, Sim};

/// A plain choice: pick, buy, play, else end the turn.
fn plain(view: &BotView) -> usize {
    let legal = view.legal();
    for kind in ["pick", "play", "buy"] {
        if let Some(i) = legal.iter().position(|a| a.kind() == kind) {
            return i;
        }
    }
    legal.iter().position(|a| *a == Action::EndTurn).unwrap_or(0)
}

/// Busy-loops past its clock from round 3 on, then returns: it must get a clock-out.
pub mod busy {
    use super::*;
    pub struct Busy;
    pub fn new_bot(_seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
        Box::new(Busy)
    }
    impl Bot for Busy {
        fn choose(&mut self, view: &BotView, sim: &mut Sim) -> usize {
            if view.round() >= 3 {
                let mut x: u64 = 1;
                while sim.clock_left_ns() > -20_000_000 {
                    for i in 0..10_000u64 {
                        x = x.wrapping_mul(6364136223846793005).wrapping_add(i);
                    }
                }
                if x == 0 {
                    return 0;
                }
            }
            plain(view)
        }
    }
}

/// Never returns from its round 2 call: the watchdog must abort the match.
pub mod hang {
    use super::*;
    pub struct Hang;
    pub fn new_bot(_seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
        Box::new(Hang)
    }
    impl Bot for Hang {
        fn choose(&mut self, view: &BotView, _sim: &mut Sim) -> usize {
            let mut x: u64 = 1;
            while view.round() >= 2 {
                x = x.wrapping_mul(3).wrapping_add(1);
                if x == 7 {
                    break;
                }
            }
            plain(view)
        }
    }
}

/// Panics in round 3.
pub mod panic {
    use super::*;
    pub struct Panic;
    pub fn new_bot(_seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
        Box::new(Panic)
    }
    impl Bot for Panic {
        fn choose(&mut self, view: &BotView, _sim: &mut Sim) -> usize {
            assert!(view.round() < 3, "test-panic: planted panic in round {}", view.round());
            plain(view)
        }
    }
}

/// Returns an index outside the legal list in round 2.
pub mod fault {
    use super::*;
    pub struct Fault;
    pub fn new_bot(_seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
        Box::new(Fault)
    }
    impl Bot for Fault {
        fn choose(&mut self, view: &BotView, _sim: &mut Sim) -> usize {
            if view.round() == 2 { view.legal().len() } else { plain(view) }
        }
    }
}

/// Spends nearly its whole clock on lookahead fights: at each call it fights its board against
/// past payloads until it has used its share (an even split of what is left over 40 calls),
/// and it tries one sandbox refresh a turn. For the clock figures.
pub mod burn {
    use super::*;
    pub struct Burn {
        clock: i64,
        fights: u64,
        boxed_round: i64,
    }
    pub fn new_bot(_seed: u64, setup: &BotSetup) -> Box<dyn Bot> {
        Box::new(Burn { clock: setup.clock_ns(), fights: 0, boxed_round: -1 })
    }
    impl Bot for Burn {
        fn choose(&mut self, view: &BotView, sim: &mut Sim) -> usize {
            let left = sim.clock_left_ns();
            let stop = left - left / 40;
            if self.boxed_round != view.round() {
                self.boxed_round = view.round();
                if let Ok(mut sandbox) = sim.sandbox() {
                    sandbox.act(&Action::Refresh);
                }
            }
            let floor = self.clock / 50;
            while sim.clock_left_ns() > stop.max(floor) {
                let Some(last) = view.past().last() else { break };
                let seed = sim.next_seed();
                if sim.fight(view.me().payload(), &last.payload, seed).is_err() {
                    break;
                }
                self.fights += 1;
            }
            plain(view)
        }
    }
}
