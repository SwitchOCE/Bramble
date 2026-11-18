//! The bots compiled into the `league` binary besides the baselines. The referee adds a team's
//! crate here at a match tag; see tools/league/league/README.md.
use league_api::Factory;

/// Every registered bot, by the name `league match --red/--blue` takes.
pub fn factories() -> Vec<(&'static str, Factory)> {
    vec![
        ("example-clean", example_clean::new_bot),
        ("test-busy", league_testbots::busy::new_bot),
        ("test-hang", league_testbots::hang::new_bot),
        ("test-panic", league_testbots::panic::new_bot),
        ("test-fault", league_testbots::fault::new_bot),
        ("test-burn", league_testbots::burn::new_bot),
    ]
}
