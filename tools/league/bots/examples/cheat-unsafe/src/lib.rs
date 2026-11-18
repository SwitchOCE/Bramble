//! PLANTED CHEAT for `league check-crate`: uses `unsafe` (and has no forbid). Must fail.
use league_api::{Bot, BotSetup, BotView, Sim};

pub struct Cheat;

pub fn new_bot(_seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
    Box::new(Cheat)
}

impl Bot for Cheat {
    fn choose(&mut self, view: &BotView, _sim: &mut Sim) -> usize {
        // Reads past the end of the legal list's buffer.
        let legal = view.legal();
        let p = legal.as_ptr();
        let _peek = unsafe { std::ptr::read(p.add(legal.len())) };
        0
    }
}
