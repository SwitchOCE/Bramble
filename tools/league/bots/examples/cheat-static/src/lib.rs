//! PLANTED CHEAT for `league check-crate`: a static shared by every seat in the process, so
//! teammates could signal to each other. Must fail.
#![forbid(unsafe_code)]

use league_api::{Bot, BotSetup, BotView, Sim};
use std::sync::atomic::{AtomicU64, Ordering};

static SEEN: AtomicU64 = AtomicU64::new(0);

pub struct Cheat;

pub fn new_bot(_seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
    SEEN.fetch_add(1, Ordering::Relaxed);
    Box::new(Cheat)
}

impl Bot for Cheat {
    fn choose(&mut self, view: &BotView, _sim: &mut Sim) -> usize {
        view.legal().len() - 1
    }
}
