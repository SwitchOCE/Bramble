# Owner rule: players face ghosts, not bots; GDScript bots are archived

Said in chat on 19 November 2026. The question was whether the frozen old TribeBot needed a GDScript copy, proved game for game against the Rust one like the other bots.

> No, we don't need any bots in GDScript, right? Because we're going to be using ghosts. We do not need bots in GDScript. They should all be archived. We are moving to ghosts, are we not? Isn't that the entire point of this system? We don't ever need a bot to play. Ghosts can be playing always.

*[Editor's note: the ghost orchestrator then proposed: (1) prove Rust against Godot by having Rust play the reference games and Godot replay and check every one, in place of Godot bots playing them; (2) the playable build's opponents become ghosts (ghost plan, step 4); (3) archive the GDScript bots after that. The Rust league bots stay: they play the runs that become ghosts, and they refill the field in development (ghost plan, decision 4). They never face a player.]*

The owner's answer to that proposal:

> Yes, unless there are significant reasons as to why we would need a bot in GDScript, maybe just for testing purposes. I'm not sure if there are some tests that rely on a bot or something. In the interim, before we move to the ghost architecture, but you're in charge of moving the architecture to ghost. So we need to run that.

*[Editor's note: today GDScript bots are used by the playable build's opponents (src/game/game_flow.gd, flow_bot.gd), by game tests (tests/game/test_flow_bot.gd, test_game_flow.gd, test_records.gd, test_tribe_games.gd, tests/core/test_session.gd), by the bot soak and records checks (tools/checks/soak.gd, records.gd) and by the league's reference data (tools/league/gd/). Each is replaced before its bot is archived; until then they stay. The ghost orchestrator owns the move.]*
