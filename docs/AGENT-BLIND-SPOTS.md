# What agents can't see

Agents build and check this game without eyes on a real screen, hands on a real mouse, or ears. This page lists what that hides, so that nobody reads "checked", "play-tested" or "reviewed" as meaning more than it does. It was written on 17 Nov 2026 from one night's work on the second ideation track (`ideation/track-2`: a playable five-tribe build made by agents). The owner asked for it after the first item came to light:

> "that's the kind of thing that I would not have known at all had you not said things ... had you not mentioned that and just fixed it without telling me, I could have got another 2 weeks and I could have spent thousands and millions of tokens without realizing what the problem was."

**The rule this page stands for:** when a tool or a check cannot observe something that matters, say so to the owner at once, even if you already have a way round it, and add it here.

Each item says what is hidden, how we know, what covers part of it today, and what would close it. The "would close it" lines are suggestions, not decisions.

## 1. Motion and feel

- **Hidden:** how anything moves. Dragging, settling, tweens, hover timing, fight pacing.
- **How we know:** on the ideation track the agents' way of looking at the game is a screenshot tool (`tools/look` on that branch; not on `main`) that runs Godot under a virtual display with software rendering. A reviewer first noticed its sessions drawing 2 to 3 frames a second. Measured properly on 17 Nov, on a 6-core machine with no graphics card: a real game screen (the recruit screen) drew 41 frames in ten seconds, about 4 a second, while a near-empty scene reached the tool's cap of 30. A 0.2 second movement is then one or two drawn frames. Agents judged motion from still shots and from reading the code. Two agent play-tests passed the build; the owner found within minutes of playing that picking up and dropping cards felt wrong.
- **Covers part of it:** the film tool (`tools/feel/`) renders a scripted pointer scenario at a fixed 60 frames a second however slow the machine is, and writes a video an agent can step through frame by frame. Its README has the measurement and what the tool cannot be trusted for (no sound, a software renderer, left button and pointer movement only, anything timed by the wall clock).
- **Would close it:** nothing replaces the owner's hands. Film first, compare against reference footage, then a short play by a person.

## 2. Agent play-testers are not players

- **Hidden:** responsiveness, friction, boredom, confusion, fun.
- **How we know:** an agent play-tester clicks at coordinates and reads still pictures. It knows the card names from the data, never misclicks, and never gets impatient. On 17 Nov two agent play-tests called the build playable and listed mostly wording and labelling faults; neither mentioned that dragging felt wrong.
- **Covers part of it:** agent play-tests are good at finding broken flows, missing words, wrong numbers and hangs.
- **Would close it:** treat an agent play-test as a bug sweep, never as a verdict on feel. A few minutes of a person playing is the test.

## 3. Real hardware and real screens

- **Hidden:** how the game looks and runs on a graphics card, at other resolutions and aspect ratios, with Windows display scaling, windowed or full screen, and at what frame rate.
- **How we know:** every picture an agent has looked at came from a software renderer at exactly 1920 x 1080. The Windows build was only ever booted under wine to its first screen before the owner ran it.
- **Covers part of it:** the export check proves the pack is complete and the exe starts.
- **Would close it:** a run on a real Windows machine with a graphics card that takes screenshots at several window sizes and reports frame times.

## 4. Anything that depends on real time

- **Hidden:** timers and delays as a player meets them: input guards, how long a screen stays up, hover delay, animation length.
- **How we know:** in a slow session game time and wall time drift apart, and tests step time by hand. A play-tester reported a 1.5 second hover lag; a worker put it down to slow rendering; nobody confirmed that at real speed.
- **Covers part of it:** the film tool steps time at a fixed rate, so timers run as they would at 60 frames a second.
- **Would close it:** film any change to a timer or delay before calling it done.

## 5. The late game

- **Hidden:** what the screens look like with full boards of high-tier units, golden cards, large numbers and long fights.
- **How we know:** agent play-tests reached about turn 7. Later turns were only played by the soak, which checks rules and looks at nothing.
- **Would close it:** saved late-game states that can be opened, shot and filmed directly.

## 6. Balance and fun

- **Hidden:** whether a tribe is strong, weak or interesting, and whether a game against bots is a contest.
- **How we know:** the soak proves that thousands of fights break no rule. The bots are simple; one saved up 136 gold without spending it. "A whole game against bots" says the game ends, not that it is a game.
- **Would close it:** this is design and balance work, which the owner has scoped separately. Until then, do not read soak results or bot games as balance evidence.

## 7. The mock-up match number

- **Hidden:** small things that are completely wrong.
- **How we know:** the screenshot compare gives one average difference over the whole screen. Replacing a whole corner element moved it by about 0.5 out of 255. The compares were run by hand by the worker who made the change, not by the gate. Twice in one night a mock-up was edited to match the build instead of the build being matched to the mock-up.
- **Would close it:** per-region differences, the compare in the gate, and a rule that the owner's mock-up pages are only changed by the owner.

## 8. Sound

- **Hidden:** everything an agent would need to hear.
- **How we know:** no agent can listen. There is no sound in the build yet.
- **Would close it:** when sound arrives, agents can check that a sound is triggered and how loud the file is; whether it sounds right is a person's call.

## 9. Reviews share these limits

- **Hidden:** whether work is good, as opposed to whether it matches its brief.
- **How we know:** a reviewing agent reads code and runs headless checks. Its "keep" means the change does what was asked and nothing that wasn't. An orchestrating agent mostly reads workers' reports, not their work. Every agent in the chain has the blind spots above.
- **Covers part of it:** reviews did catch real faults that night (tests that proved nothing, a screen and a fight disagreeing about a card, labels added against an owner instruction).
- **Would close it:** ask of every review and play-test what it could not observe, and put that line at the top of the report.
