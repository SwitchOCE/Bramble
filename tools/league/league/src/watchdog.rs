//! A bot call that never returns can't be stopped safely from inside its thread. The watchdog
//! thread reads each game thread's CPU clock; if one call runs past the seat clock plus 5 s of
//! thread CPU time, or 60 s of wall time, it aborts the whole match, naming the bot, seat and
//! game. The match must then be played again without that bot.
use league_api::harness;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

#[derive(Default)]
struct Slot {
    clock: Option<libc::clockid_t>,
    call: Option<(String, i64, Instant)>,
}

#[derive(Clone, Default)]
pub struct Watchdog {
    slots: Arc<Mutex<Vec<Slot>>>,
}

/// One game thread's handle.
pub struct Watch {
    dog: Option<Watchdog>,
    slot: usize,
}

impl Watch {
    /// A handle that watches nothing (for single games outside a match).
    pub fn none() -> Self {
        Self { dog: None, slot: 0 }
    }
    pub fn enter(&self, label: &str, cpu_now: i64) {
        if let Some(dog) = &self.dog {
            dog.slots.lock().expect("watchdog")[self.slot].call =
                Some((label.to_owned(), cpu_now, Instant::now()));
        }
    }
    pub fn leave(&self) {
        if let Some(dog) = &self.dog {
            dog.slots.lock().expect("watchdog")[self.slot].call = None;
        }
    }
}

impl Drop for Watch {
    fn drop(&mut self) {
        if let Some(dog) = &self.dog {
            let mut slots = dog.slots.lock().expect("watchdog");
            slots[self.slot] = Slot::default();
        }
    }
}

impl Watchdog {
    /// Registers the calling thread.
    pub fn register(&self) -> Watch {
        let mut slots = self.slots.lock().expect("watchdog");
        slots.push(Slot {
            clock: Some(harness::this_thread_clock()),
            call: None,
        });
        Watch {
            dog: Some(self.clone()),
            slot: slots.len() - 1,
        }
    }

    /// Starts the watching thread. `clock_ns` is the per-game seat clock.
    pub fn start(&self, clock_ns: i64, cpu_grace_ns: i64, wall_limit: Duration) {
        let slots = self.slots.clone();
        std::thread::spawn(move || {
            loop {
                std::thread::sleep(Duration::from_millis(100));
                let slots = slots.lock().expect("watchdog");
                for slot in slots.iter() {
                    let (Some(clock), Some((label, start, wall))) = (slot.clock, &slot.call) else {
                        continue;
                    };
                    let cpu = harness::clock_ns(clock).map(|now| now - start).unwrap_or(0);
                    if cpu > clock_ns + cpu_grace_ns || wall.elapsed() > wall_limit {
                        eprintln!(
                            "league: MATCH ABORTED: a bot call did not return: {label}: {:.1} s CPU, {:.1} s wall in one call (limit: clock + {:.0} s CPU, or {:.0} s wall)",
                            cpu as f64 / 1e9,
                            wall.elapsed().as_secs_f64(),
                            cpu_grace_ns as f64 / 1e9,
                            wall_limit.as_secs_f64()
                        );
                        std::process::exit(3);
                    }
                }
            }
        });
    }
}
