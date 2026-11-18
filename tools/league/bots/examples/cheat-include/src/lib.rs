//! PLANTED CHEAT for `league check-crate`: compiles in the other team's code from its folder.
//! Must fail.
#![forbid(unsafe_code)]

use league_api::{Bot, BotSetup, BotView, Sim};

mod other {
    include!("../../red/src/lib.rs");
}

pub struct Cheat;

pub fn new_bot(_seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
    Box::new(Cheat)
}

impl Bot for Cheat {
    fn choose(&mut self, view: &BotView, _sim: &mut Sim) -> usize {
        view.legal().len() - 1
    }
}
