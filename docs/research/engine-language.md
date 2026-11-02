# Engine language: options, evidence and ramifications

Research for the owner's decision on which programming language Bramble's Godot code is written in. It lays out the options; it does not decide. Checked 2 November 2026.

**Markers.** **[V]** = checked in the cited source. **[I]** = inference, by me or the research agents. Sources were read by three research agents and by me; I re-read the claims that decide most (C# platform status, the .NET version, gdext's platform status, GodotSteam's C# status, the 4.8 beta notes, the LLM benchmark). Benchmarks carry their source, date, Godot version and hardware where the source gives them; many don't, and that is said.

**Links.** Links into `autobattler/` point at the Autobattler lessons in PR SwitchOCE/Bramble#3 (branch `research/autobattler-lessons`); they resolve once that PR merges.

**Versions.** The current stable Godot is **4.7.2** (18 August 2026), the version Autobattler used. **4.8** is in beta (beta 1 on 15 October, beta 2 on 29 October 2026) and in feature freeze, with no release date ([4.8 beta 1](https://godotengine.org/article/dev-snapshot-godot-4-8-beta-1/)) **[V]**. Where 4.8 changes something, it is noted.

---

## 1. The short version

**Is GDScript typed?** *Optionally.* Plain GDScript is not. Add types (`var hp: int`, `func attack(target: Unit) -> void`) and Godot checks them before the game runs. Project settings can turn "missing type" and "can't check this call" into hard errors, which makes typing compulsory. Autobattler ran exactly that way. So the choice is not "typed versus untyped". It is how complete each checker is, and what each language costs elsewhere.

**The four options:**
1. **GDScript**, Godot's own language, made strict.
2. **C#**, using Godot's separate .NET build.
3. **C++ or Rust compiled into Godot** ("GDExtension"), for the whole game or just a hot core.
4. **A hybrid**: the rules and fight simulation in one language, the screens and animation in another.

**What actually differs between them:**
- **Safety.** C#, Rust and C++ check more than strict GDScript: generics, interfaces and typed callbacks. GDScript has none of those, so some code stays loosely typed (section 3.1). Strict GDScript still catches the large majority of mistakes before anything runs.
- **Speed.** Pure number-crunching in C#, Rust or C++ is roughly 10–50× faster than GDScript **[I]**. That matters for *large balance batches*, not for playing the game: one fight should take a few milliseconds in GDScript, and the UI cost is the engine's, whatever the language (section 2.3).
- **Platforms.** This is C#'s big cost. In Godot 4, C# on Android and iOS is *experimental* and C# web export *does not exist* **[V]**. GDScript runs everywhere Godot runs. Rust and C++ run everywhere, but each platform needs its own compiled build, and Rust's Android, iOS and web support is labelled experimental by its own project **[V]**. Consoles go through paid third-party ports, where GDScript is supported on Switch, Xbox and PlayStation, and C# only in beta on two of them (section 3.3) **[V]**.
- **Tooling for cloud workers.** GDScript needs only the Godot editor (74 MB). C# adds the .NET SDK (about 217 MB) and NuGet. Rust or C++ adds a compiler, plus Android's NDK (over 1 GB) to build for phones, plus a Mac to build for iOS (section 3.4).
- **What Autobattler gives us.** Its whole quality gate, layer checker, lint config, test setup, RNG and cloud scripts are GDScript-specific. With GDScript they carry over almost as-is; with anything else, the lessons carry over but the scripts have to be rebuilt (section 4).
- **Changing your mind later.** In Autobattler the pure rules core was 3.2k lines against 41k lines of presentation **[V]**. If Bramble keeps its rules core pure (no engine types), integer-only and covered by golden replays, moving *just the core* to a faster language later is a contained job. Moving the presentation is the expensive part (section 6).

**Words used below, in plain terms:**
- **Generics:** one container or function written once and typed for any card type, e.g. a `Pool<Unit>` and a `Pool<Spell>` from the same code.
- **Interfaces / traits:** a promise that different things share an ability ("anything that can be targeted"), checked by the compiler.
- **Typed callbacks:** passing a function around ("run this when a unit dies") with its inputs checked.
- **Pure rules core / no engine types:** the rules code uses only its own plain data, never Godot's screen or node objects, so it can run without Godot.
- **Golden replays:** saved fights with known results; a test fails if a code change alters any of them.
- **Allowlist:** the list of websites a cloud worker's machine may download from.
- **NuGet / crates.io:** the package stores for C# and Rust libraries.
- **NDK:** Google's kit for compiling native code (C++ or Rust) for Android phones.

---

## 2. From the ground up

### 2.1 What the language choice is, and isn't

Godot is the engine: it draws the screen, plays sound, reads touches, and builds the Windows exe and the Android APK. The engine itself is written in C++. The language question is about the code *we* write on top of it: the rules, the fight simulation, the shop, the UI behaviour.

Godot lets a project write that code in several ways:
- **GDScript**, Godot's own language, built into the editor. Godot's FAQ calls it "the recommended language to learn and use since it is native to Godot" ([FAQ, 4.7](https://docs.godotengine.org/en/stable/about/faq.html)) **[V]**.
- **C#**, through a separate ".NET" download of the Godot editor.
- **C++ or Rust**, compiled into a library that Godot loads at start-up (a "GDExtension").

The FAQ lists GDScript, C# and C++ as the officially supported languages **[V]**. Rust is supported by the community project godot-rust. Languages can be mixed in one project, with costs at each boundary (section 3.5).

### 2.2 Typing, explained

A *type* says what kind of value something is: a whole number, a piece of text, a Unit, a Board.

- **Dynamically typed** code doesn't say. `var hp = 5` could later hold `"five"`. A typo like `unit.attak()` is found only when that line runs.
- **Statically typed** code says, and a checker reads it *before* it runs: `var hp: int = 5`. The typo is underlined in the editor, and the project fails its compile check.

When the check happens matters:

| Stage | What it means | Cost of a miss |
|---|---|---|
| **Editor / parse / compile** | The code is read, not run. Every line is checked, including rare branches. | Seconds |
| **Run time** | The line must actually run, in a test or in play. | Only as good as the tests. A deathrattle that fires only on an empty board can ship broken. |

A stricter checker moves more mistakes into the first row. That helps people, and it helps AI workers even more, because the error message tells them exactly what to fix (section 3.6).

### 2.3 How fast does Bramble need to be?

Bramble does three kinds of work with very different speed needs.

| Work | Size | Who waits |
|---|---|---|
| **One fight** in a real game | Two boards of up to 7 units; a few dozen to a few hundred events (attacks, deaths, triggers) | The player, but the fight is computed once and then *played back* as animation (architecture-notes §8). Anything under about 50 ms is invisible. |
| **Balance batches** | Tens of thousands to millions of fights | The designer, or a nightly job |
| **UI and animation** | Cards, tweens, a board, at 60 fps on a mid-range phone | The player, every frame |

**Measured numbers we already have:**
- Autobattler's GDScript sim ran **7.7 ms per battle** on a release build, **10.4 ms** on the debug editor (1,000 battles, mean 265 events and 340 ticks per battle, 4-core cloud container, Godot 4.7.2; Autobattler decision 7, 10 October 2026) **[V]**. Its fights were longer than a Battlegrounds fight, because they ran on a 20 Hz tick.
- Autobattler's GDScript balance tooling: a full ghost-pool rebuild took **about 1.5 hours on one core**; measuring one candidate took about 8 minutes per 600-run seed, run in parallel processes (`tools/balance/README.md`, 18 October 2026) **[V]**. Its nightly balance job took about 50 minutes ([toolchain.md](autobattler/toolchain.md) §2.12, on branch `research/autobattler-lessons`) **[V]**.
- Bramble's Python toy sim plays 6,000 paired fights per cell; the whole power-budget script takes about 35 seconds ([power-analysis.md](battlegrounds/power-analysis.md)) **[V]**. Its units are stat lumps with no card text, far simpler than the real rules.

**Estimates for Bramble [I]:**
- **One fight in GDScript: roughly 1–8 ms** on a desktop core. The arithmetic: 7.7 ms over 265 events is at most about 29 µs per event (less, since the 340 ticks also cost time). A Bramble fight of 30–250 events is then about 1–7 ms; trigger-heavy late-game boards sit at the top. A phone is perhaps 2–4× slower. Either way, far below what a player would notice.
- **A balance batch of 1 million fights in GDScript: roughly 15–130 CPU-minutes**, so about 4–35 minutes on a 4-core machine. For scale, 10,000 simulated 8-player games of about 15 rounds is around 600,000 fights.
- **The same batch in C#, Rust or C++** with the rules held in the language's own data structures: very roughly **10–50× faster**, so seconds to a few minutes. Microbenchmarks show bigger gaps (section 3.2), but real code narrows them.
- **How this squares with Autobattler's measured 8 minutes per 600 runs [I]:** an Autobattler "run" was a whole campaign (about 15 days of shop decisions by a bot, with battles along the way), not one fight, so about 0.8 s per run fits dozens of battles plus bot logic per run. Balance work that simulates whole games, with bots choosing what to buy, costs far more than fights alone.

So GDScript is fast enough to *play* Bramble with a large margin. Where it may pinch is balance work at scale: whole-game simulations with bots, or "change a number, re-run a million fights, look". In GDScript that is tens of minutes on a 4-core machine; in a compiled language, about a minute.

---

## 3. The evidence, question by question

### 3.1 Typing and safety

**GDScript (4.7)**
- **How it works.** Typing is optional and gradual: "you can use it only in some sensitive GDScript files, use it everywhere, or don't use it at all" ([Static typing, 4.7](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html)) **[V]**. Typed code is checked at parse time. The editor turns the line number green on lines it can prove safe; lines that touch untyped values are checked only at run time **[V]**.
- **How strict it can be made.** Each warning in `debug/gdscript/warnings/*` can be set to Error. The ones that enforce typing (`untyped_declaration`, `unsafe_property_access`, `unsafe_method_access`, `unsafe_cast`, `unsafe_call_argument`) are **off by default** ([ProjectSettings, 4.7](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html)) **[V]**. There is no single "warnings as errors" switch; each one is raised separately **[V]**. Autobattler raised 21 of them to Error, added a step that compiles every script, and ran gdlint **[V]**.
- **What it supports.** Typed arrays (`Array[Unit]`, since 4.0), typed dictionaries (`Dictionary[String, int]`, since [4.4](https://godotengine.org/releases/4.4/)) **[V]**, abstract classes and methods (since [4.5](https://godotengine.org/releases/4.5/)) **[V]**.
- **What it still can't type, as of 4.7.2 and the 4.8 beta:**
  - **No generics.** You can't write one typed `Pool<T>`. The proposal has been open since July 2020 ([#1207](https://github.com/godotengine/godot-proposals/issues/1207)) **[V]**.
  - **No interfaces or traits.** The main trait pull request was closed unmerged on 8 July 2026 by its own author, who wrote "I don't see a clear direction for how to move this PR forward" and invited others to take it over ([#107227](https://github.com/godotengine/godot/pull/107227)) **[V]**. Godot's [priorities page](https://godotengine.org/priorities/) still says "traits is the path we're going forward" **[V]**. So traits are wanted but have no current implementation or date. Abstract classes are the nearest substitute.
  - **No typed callbacks.** A `Callable` has no parameter types; a maintainer said in September 2024 that this "can't come any time soon" ([#10807](https://github.com/godotengine/godot-proposals/issues/10807)) **[V]**. The priorities page says the team is "thinking about enforcing the typing of signals and callables" **[V]**.
  - **No nested typed collections.** `Array[Array[int]]` is not supported ([Static typing, 4.7](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html)) **[V]**.
  - **Signal arguments aren't enforced** on `emit()` ([forum, 4.2](https://forum.godotengine.org/t/best-practices-for-static-typed-gdscript-signals-and-interfaces-abstract-classes/70295)) **[V for 4.2; unchanged through 4.7 is I]**.
- **What that cost in practice.** Autobattler's effect specs stayed untyped dictionaries: 51 `spec.get(` calls in core and 358 `: Variant` declarations in `src` (Autobattler [reuse.md](autobattler/reuse.md)) **[V]**. A card game's effect system (triggers, conditions, targets) is exactly where generics and interfaces help most **[I]**.

**C# (Godot 4.7: .NET 8; Godot 4.8: .NET 10)**
- **The compiler checks** everything a mainstream typed language does: generics, interfaces, null-safety (once `<Nullable>enable</Nullable>` is switched on; Godot's project template leaves it off) **[V]** ([project template, 4.7](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/modules/mono/editor/GodotTools/GodotTools.ProjectEditor/ProjectGenerator.cs)).
- **Godot adds its own analyzers** that fail the build on Godot-specific mistakes: a missing `partial`, bad `[Export]`s, misnamed signal delegates ([C# diagnostics, 4.7](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/diagnostics/index.html)) **[V]**.
- **Gaps at run time:** node paths in `GetNode<T>("path")` (a wrong cast throws at run time), and any call into GDScript code or addons, which goes through string-named `Call()`. A `Call` with missing arguments "will fail silently" ([cross-language scripting, 4.7](https://docs.godotengine.org/en/stable/tutorials/scripting/cross_language_scripting.html)) **[V]**.

**Rust (godot-rust, crate `godot` 0.5.5)**
- **The strictest compiler of the four.** Ownership rules prevent whole classes of bugs (use-after-free, data races) at compile time **[I]**.
- **Integer overflow** panics in debug builds **[I]**.
- **Run-time gaps:** the boundary with Godot. Calls into the engine can still fail at run time, and Rust panics in a web build abort the game ([gdext web export](https://godot-rust.github.io/book/toolchain/export-web.html)) **[V]**.
- **Stability:** pre-1.0, with "occasional breaking changes… usually minor and accompanied by migration guides" ([gdext ReadMe](https://github.com/godot-rust/gdext)) **[V]**.

**C++ (godot-cpp 10.0)**
- **Typed, but not memory-safe.** Mistakes that Rust or C# reject at compile time (dangling pointers, buffer overruns) become crashes at run time **[I]**.

**Ranking by how much is caught before running [I]:** Rust > C# > strict GDScript > C++. C++ outranks GDScript on type checking but loses on memory safety. Plain, non-strict GDScript would be last.

### 3.2 Performance

**Pure logic (what a fight simulation is).** No current, rigorous cross-language benchmark exists. The best available:

| Source | What was measured | GDScript | C# | Notes |
|---|---|---|---|---|
| [dicarne/godot-benchmark-gdscript-csharp](https://github.com/dicarne/godot-benchmark-gdscript-csharp) | 10M loop iterations, release exports | 117 ms | 2 ms | Godot version, hardware and date **not stated** **[V]** |
| same | 10M same-language function calls | 489 ms | 1.2 ms | **[V]** |
| same | 10M int-key dictionary ops | 1,834 ms | 1,921 ms (Godot `Dictionary`); 90 ms (.NET `Dictionary`) | C# loses its edge when it uses Godot's collections **[V]** |
| [Godot forum](https://forum.godotengine.org/t/why-is-there-such-a-massive-overhead-in-calling-a-function/82620) | cost of one function call | ~170 ns | ~3 ns (static) | GDScript: Godot 4.3, MacBook Air. The 170 ns is worked out from the post's timings; the C# figure is a separate test with no Godot version, so not like-for-like **[V/I]** |
| [RaidTheory inventory test](https://github.com/RaidTheory/csharp-gd-inventory-test) | inventory sort, 100 iterations | 6.8 ms | 0.34 ms | Godot 4 **[V]** |

- **Godot's own view:** GDScript's "performance is lackluster when it comes to pure data crunching" ([priorities](https://godotengine.org/priorities/)) **[V]**.
- **Rust and C++:** no published Godot 4 numbers were found. Godot 3-era tests put C++ about 40–45× faster than GDScript on a Mandelbrot loop ([forum](https://godotforums.randommomentania.com/d/28388-mandelbrot-benchmark-gdscript-c-gdnative-c-and-now-new-godot-rust-gdnative-rust)) **[V, old]**. Native Rust or C++ is normally at least as fast as C# on this kind of code **[I]**.
- **Faster GDScript coming?** No. GDScript is still a bytecode interpreter: a program inside Godot reads each instruction and carries it out, which is slower than code compiled straight to the processor's own instructions (C++, Rust, and C# once its runtime compiles it). "AOT" and "JIT" are two ways to compile it instead. Godot is "investigating whether to use AOT … or JIT" with no schedule ([priorities](https://godotengine.org/priorities/)) **[V]**. Community compilers exist but aren't production-ready **[I]**.

**Typed GDScript is faster than untyped.** When Godot knows the types, it can use faster, specialised instructions ([Static typing, 4.7](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html)) **[V]**. In one synthetic release-build test in [PR #70838](https://github.com/godotengine/godot/pull/70838) (merged for 4.0, January 2023), the untyped version scored 6.41 and the typed version 3.31, about 1.9× faster **[V]**. Commenters reported smaller and mixed gains on real projects **[V via reviewer]**. Strict typing is a speed bonus, not a guaranteed doubling.

**Engine-heavy work (UI, nodes, signals).** Here the language matters little, and C# can lose. The reason is "marshalling": every time C# hands data to the engine, it must be converted between .NET's format and Godot's, and that conversion costs time.
- Godot's FAQ: "C# can be slower than GDScript when making many Godot API calls, due to the cost of marshalling" ([FAQ, 4.7](https://docs.godotengine.org/en/stable/about/faq.html)) **[V]**.
- In the dicarne repo, creating 10k nodes took 13 ms in GDScript and 22 ms in C# **[V]**. C# calling GDScript functions was 13× slower than GDScript calling them (6,456 ms against 498 ms for 10M calls) **[V]**.
- A community "survivors" prototype in GDScript, C# and Rust on 4.4.1 hit the same frame-rate wall at about 250 enemies **[V, community, original post unreachable]**.

**Mobile UI and animation.** No measurements of language effects on 2D, tween-heavy mobile games were found. Tweens, layout and drawing run in the engine's C++ whatever the script language, so the renderer and draw calls dominate on a mid-range phone **[I]**. The FAQ warns that C#'s garbage collector (which periodically frees unused memory) can cause stutter "in complex projects" **[V]**; that this matters more on a phone is my inference **[I]**.

**Start-up time and size:**
- **GDScript** adds nothing beyond the engine. A stripped Android export template is about 7–12 MB ([godot-size-benchmarks](https://github.com/strogo/godot-size-benchmarks)) **[V]**.
- **C#, desktop:** a 4.6.1 Windows export carried about **76 MB of .NET DLLs** in a 175 MB folder; trimming didn't work ([forum, March 2026](https://forum.godotengine.org/t/c-net-dlls-too-large-after-export/134428)) **[V, one community report]**.
- **C#, Android:** no measured APK overhead was found. One report: a large C# game took **about 26 s to cold-start on a Pixel 4a** (Godot 4.3, Mono runtime). That report is why Android NativeAOT was added as an option in 4.5 ([#97775](https://github.com/godotengine/godot/issues/97775), [PR #97908](https://github.com/godotengine/godot/pull/97908)) **[V, single anecdote]**.
- **Rust and C++:** add one native library per platform, typically a few MB **[I]**.
- **Plugins dwarf all of these.** One project's APK went from 29 MB to 83 MB after adding a Gradle build and the AdMob plugin ([forum](https://forum.godotengine.org/t/29-mb-android-export-became-83mb-after-gradle-admob-plugin/104541)) **[V]**.

### 3.3 Platforms

| Platform | GDScript | C# (4.7) | Rust (gdext 0.5) | C++ (godot-cpp) |
|---|---|---|---|---|
| Windows, Linux | Stable | Stable | Stable | Stable |
| macOS | Stable | Stable | Stable; built on a Mac per the book | Stable; Mac or osxcross |
| **Android** | Stable (Autobattler exported it) | **Experimental** since 4.2; export needs .NET 9+ | **Experimental**; shipped games exist | Supported by godot-cpp's build scripts with the NDK **[V]**; Godot gives it no maturity label **[I]** |
| iOS | Stable (export needs a Mac) | **Experimental** (NativeAOT); "reflection use may fail at runtime"; Mac only | **Experimental**; needs a Mac and Xcode | Needs a Mac (or osxcross) |
| **Web** | Stable (standard templates) | **Not supported** | **Experimental**; nightly Rust; custom web templates | Custom "dlink" web templates; cross-origin isolation headers |

Sources: [C# basics, 4.7](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_basics.html) ("Projects written in C# using Godot 4 currently cannot be exported to the web platform"; "Android and iOS platform support is available as of Godot 4.2, but is experimental and some limitations apply") **[V]**; [gdext ReadMe](https://github.com/godot-rust/gdext) ("experimental support for Wasm, Android and iOS, but documentation and tooling is still lacking") **[V]**; [Exporting for the Web, 4.7](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) **[V]**; [Compiling for the Web, 4.7](https://docs.godotengine.org/en/stable/engine_details/development/compiling/compiling_for_web.html) ("The default export templates do not include GDExtension support") **[V]**.

**Details that matter:**
- **C# on mobile has been "experimental" for about three years** (since 4.2, November 2023) **[V]**. "Experimental" means Godot doesn't promise it works; it does not mean it never works. A short search found no named, shipped Godot 4 C# game on Google Play; that is not proof none exist **[V that none was found]**.
- **Rust has shipped on phones.** The godot-rust book lists two commercial games released on Google Play and the App Store (Graphwar II, Solitaire Klondike Classic) ([games list](https://godot-rust.github.io/book/ecosystem/games.html)) **[V]**.
- **Web builds in plain terms:** GDScript games export to the web with Godot's normal download. C# can't at all. Rust or C++ need a specially built web version of Godot, and the web server must send extra security settings ("cross-origin isolation") that some game portals don't allow **[V/I]**.
- **C# web export:** there is a prototype (GodotCon, May 2025, a 72 MiB pack before compression) and a draft pull request ([#106125](https://github.com/godotengine/godot/pull/106125)) still open after 18 months. Godot "cannot commit to a specific timeline" ([blog, May 2025](https://godotengine.org/article/live-from-godotcon-boston-web-dotnet-prototype/)) **[V]**. The 4.8 beta notes don't mention it **[V]**.
- **Rust web builds** need nightly Rust. The book pins Emscripten 3.1.74, while Godot 4.7's own web builds use 4.0.11 ([web_builds.yml](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/.github/workflows/web_builds.yml)) **[V]**. That mismatch needs testing before relying on it **[I]**.
- **Every compiled option (Rust, C++, and C# NativeAOT) must be built once per platform.** That makes the CI build a matrix of platforms, and iOS and macOS need a Mac runner **[I]**.

**Consoles (Switch, Xbox, PlayStation).** Godot has no official console exports; console makers' rules keep that code private. The main route is W4 Games' paid ports ("W4 Consoles"): Switch, Xbox Series X|S and PlayStation 5, Godot 4.4–4.6 listed, yearly fees from $800 per platform for small studios ([W4 Consoles](https://w4games.com/w4consoles), undated page) **[V]**.
- **GDScript:** supported on all three **[V]**.
- **C#:** "Beta support… for Nintendo Switch and Xbox Series X|S"; PlayStation 5 not listed **[V]**.
- **GDExtension (Rust, C++):** not mentioned on the page **[V]**. A separate free Switch port by RAWRLAB doesn't support C# or native extensions ([GamingOnLinux, January 2024](https://www.gamingonlinux.com/2024/01/godot-engine-gets-a-free-nintendo-switch-port-for-game-devs/)) **[V via search summary]**. Native code would have to be built with each console's own private toolchain **[I]**.
- So if consoles might matter one day, GDScript keeps every door open, C# keeps two of three in beta, and a native core is an open question to ask W4 **[I]**.

### 3.4 Toolchain in Claude Code cloud sessions

*Reference detail; the summary in section 1 is enough for the decision.*

The cloud setup script must finish in about 5 minutes to be cached, and every download domain must be on the allowlist ([toolchain.md](autobattler/toolchain.md) §1, §2.5) **[V]**.

| | GDScript | C# | Rust | C++ |
|---|---|---|---|---|
| **Godot editor (Linux)** | Standard, 74.3 MB | .NET build, 103 MB | Standard, 74.3 MB | Standard, 74.3 MB |
| **Language toolchain** | none | .NET SDK, ~217 MB. One `apt install dotnet-sdk-10.0` from Ubuntu 24.04's own feed covers Godot 4.7 (.NET 8+), Android export (.NET 9+) and 4.8 (.NET 10) | rustup + stable toolchain, a few hundred MB **[I]** | gcc/clang, SCons, godot-cpp source |
| **Lint and format** | gdtoolkit (pip) | `dotnet format`, analyzers (bundled) | rustfmt, clippy (bundled) | clang-format, clang-tidy |
| **Packages at build time** | none | NuGet restore | crates.io | git or vendored |
| **New allowlist domains** | none beyond Autobattler's | `builds.dotnet.microsoft.com`, `dot.net`, `api.nuget.org` | `static.rust-lang.org`, `sh.rustup.rs`, `index.crates.io`, `static.crates.io`, `crates.io` | `github.com`, PyPI for SCons |
| **To build for Android** | nothing extra (export templates + SDK, as Autobattler) | .NET 9+; NativeAOT also needs the NDK | **Android NDK, over 1 GB**, plus Rust Android targets | **Android NDK** |
| **To build for iOS** | Mac at export | Mac | Mac + Xcode | Mac + Xcode (or osxcross) |
| **Extra build step before Godot can check the code** | none (`--import` plus a compile step) | `dotnet build` | `cargo build` | `scons` |

Sources: [Godot 4.7.2 release assets](https://github.com/godotengine/godot/releases/tag/4.7.2-stable) (editors 74.3 MB and 103 MB; export templates 1.19 GB standard, 1.12 GB .NET) **[V]**; [.NET on Ubuntu](https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu-install) (updated April 2026) **[V]**; [dotnet-install script](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script) **[V]**; [rustup](https://rust-lang.github.io/rustup/environment-variables.html) and [crates.io index](https://index.crates.io/config.json) **[V]**; [gdext Android export](https://godot-rust.github.io/book/toolchain/export-android.html) **[V]**.

**How this meets Autobattler's history:**
- **GDScript** is the setup that already works. Godot editor, templates, Android SDK and gdtoolkit cached in about 24 s on the first run ([toolchain.md](autobattler/toolchain.md) §1) **[V]**. Every known failure has a recorded fix (§2.1–2.19).
- **C#** adds a moderate install (~217 MB SDK) that fits the 5-minute budget **[I]**. It brings new risks:
  - NuGet restore through the agent proxy, where Maven Central once returned HTTP 429 (§2.4) **[I]**;
  - a known "cannot be built using CI" issue in Godot .NET projects, worked around by running `dotnet build` first ([#92267](https://github.com/godotengine/godot/issues/92267)) **[V]**.
- **Rust or C++** for Android needs the NDK, which Autobattler deliberately never installed because it is over 1 GB and slows the snapshot (§2.4) **[V]**. Compile times for a cold build are unmeasured, and caching the build directory would matter **[I]**. A practical split: cloud workers build and test for Linux only, and GitHub Actions builds the Android, Windows and Mac libraries **[I]**.

### 3.5 Testing, linting and CI

| | Tests | Lint and format | Headless runs |
|---|---|---|---|
| **GDScript** | [GUT 9.7.1](https://github.com/bitwes/Gut/releases) (Godot 4.7 compatibility release, July 2026) **[V]**; [gdUnit4 6.2.3](https://github.com/MikeSchulze/gdUnit4/releases) (1 November 2026) **[V]** | [gdtoolkit 4.5.0](https://pypi.org/project/gdtoolkit/), October 2025 **[V]**. It lags new syntax: open issues on `@abstract` and on gdformat output that Godot rejects **[V]**. Godot's own warnings are the stronger check **[I]**. | Yes. Autobattler's traps are all documented (§2.7–2.9): silent passes, hangs, the class cache. |
| **C#** | `dotnet test` with xUnit/NUnit on pure C# code, **no Godot needed**; [gdUnit4Net](https://github.com/godot-gdunit-labs/gdUnit4Net) for engine tests (supports 4.7.x, .NET 8/10) **[V]** | `dotnet format`, Roslyn and Godot analyzers **[V]** | Yes, via `dotnet build` then Godot |
| **Rust** | `cargo test` on a Godot-free crate; engine tests need gdext's in-engine `#[itest]` ([dev tools](https://godot-rust.github.io/book/contribute/dev-tools.html)) **[V]** | rustfmt, clippy **[I]** | Yes |
| **C++** | doctest, Catch2 or GoogleTest on Godot-free code **[I]** | clang-format, clang-tidy **[I]** | Yes |

**The point to weigh [I]:** in C#, Rust or C++, a pure rules core is tested *without starting Godot*. That avoids most of Autobattler's GUT troubles: hangs, silent passes, the 10-minute gate that needed sharding. In GDScript, every test runs inside Godot. Autobattler's strict GUT hook (decision 13) and sharding (PR #424) solved those troubles.

### 3.6 AI agents writing it

- **GDScript works with current Claude models.** On [godot-llm-bench](https://github.com/flockbay/godot-llm-bench) (15 GDScript tasks run headless on Godot 4.7.2, 6 October 2026), Claude Opus 5.5 and Sonnet 5.5 in Claude Code passed 15/15 first try **[V]**. It is a single run by Flockbay, which sells an AI game maker built on Godot, and has had little outside review **[V]**.
- **Autobattler is stronger evidence.** Cloud workers wrote 583 `.gd` files and 451 test files in 8 days under a strict gate ([reuse.md](autobattler/reuse.md)) **[V]**. Its failures were in design and supervision, not the language **[V]**.
- **The usual GDScript failure is Godot 3 habits:** `yield`, `export var`, `KinematicBody2D`, old `connect()` syntax ([dev.to/Ziva](https://dev.to/ziva/7-godot-4-api-calls-your-ai-assistant-still-gets-wrong-3ep6), vendor) **[V]**. Godot hints at renamed Godot 3 names by default **[V]**, and a strict headless parse catches the rest **[I]**.
- **Large projects are harder in any language.** In one 2026 study of 300 Godot 4 projects, function-level completion fell from 80.4% on small projects to 5.7% on large ones. An agent loop that ran the game and fed errors back raised Claude's pass rate from 77.3% to 82.7% ([JamBench, arXiv 2606.19830](https://arxiv.org/html/2606.19830)) **[V via research agent]**. The study covers GDScript only.
- **No study compares GDScript, C# and Rust for Godot.** None was found **[V that none was found]**.
- **General evidence** says compiler feedback helps models:
  - type-constrained generation cut compile errors by more than half in TypeScript ([PLDI 2025](https://arxiv.org/abs/2504.09246)) **[V]**;
  - **Rust** is notably harder for models: in C-to-Rust translation 94.8% of failures were compile errors ([RustRepoTrans](https://arxiv.org/html/2411.13990v3)) **[V]**. The compiler then guides the fix **[I]**.
- **Godot-specific C# traps:** `partial` classes, `XEventHandler` signal naming, PascalCase API names, a `Basis` that starts at zero, signal lambdas that never disconnect ([C# differences](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_differences.html), [C# signals](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_signals.html)) **[V]**. Models may also mix in Unity habits **[I]**. Godot's analyzers catch some of these at build time **[V]**.
- **Plain C# and Rust logic** (no Godot) is mainstream code that models write well. The Godot-specific surface is the presentation layer **[I]**.

### 3.7 Determinism, async fights, server and web

- **Determinism is a design choice, not a language feature.** All four languages give identical results on every platform for integer maths with a seeded integer RNG **[I]**. Floats are where platforms differ:
  - Rust documents `sin`, `powf` and others as non-deterministic across platforms ([f64 docs](https://doc.rust-lang.org/std/primitive.f64.html)) **[V]**;
  - .NET changed float-to-int conversion on x86 in .NET 9 to match ARM ([MS Learn](https://learn.microsoft.com/en-us/dotnet/core/compatibility/jit/9.0/fp-to-integer)) **[V]**;
  - C++ compilers may combine arithmetic steps differently on phone (ARM) and PC (x86) processors, changing the last digits of results **[V, GCC list 2023]**.
- **Bramble's plan already avoids floats.** Architecture-notes §7–8 call for seeded named streams and a pure simulation; Autobattler had integers only, a seeded random-number generator (PCG32) checked against a Python copy, and golden replays **[V]**.
- **GDScript specifics:** `int` is 64-bit and wraps on overflow; `Vector2` and friends store 32-bit floats, so keep them out of sim state ([int](https://docs.godotengine.org/en/stable/classes/class_int.html), [GDScript basics](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)) **[V]**.
- **Async fights against stored snapshots** (rulebook 2.1.4, out of v0) need only the seed, the two board snapshots and the rules version, in any language **[I]**. Autobattler's rules lock and command journal are the template **[V]**.
- **Server-authoritative play:**

  | Core language | How the server runs it **[I]** |
  |---|---|
  | GDScript | Headless Godot on the server. It works, but it is heavier than a plain program. |
  | C# | A plain .NET server sharing the same class library. There is a precedent: [Klotho](https://godotengine.org/asset-library/asset/5234), a deterministic C# core for Godot that names auto-battlers as a target **[V; maturity unknown]**. |
  | Rust or C++ | A plain native server built from the same core. |
  | TypeScript | Only practical as a server-only core plus a second copy of the rules in the client, which doubles the rules and needs cross-checking. |

- **A web build:** GDScript exports to the web today. C# can't. Rust and C++ need custom web templates and cross-origin isolation headers, which some web portals don't send **[V/I]**.
- **TypeScript inside Godot** means [GodotJS](https://github.com/godotjs/GodotJS), a custom engine build that calls itself "essentially usable but still under testing". Its latest release is a beta on Godot 4.6.1, behind 4.7.2 **[V]**. Running Bramble on a custom engine build is a big commitment **[I]**.

### 3.8 Modding

- **GDScript mods** ship as resource packs loaded at run time, the simplest cross-platform route ([exporting packs, 4.7](https://docs.godotengine.org/en/stable/tutorials/export/exporting_pcks.html)) **[V]**.
- **C# mods** must ship a DLL that is loaded before the pack **[V]**.
- **Native (Rust or C++) mods** are arbitrary machine code, per platform, and unusable on iOS and the web in practice **[I]**.
- **Modding and security.** Godot's docs call pack-based mods "a security vulnerability" in some cases and suggest signing **[V]**.
- **Mods could also be data.** If modding ever matters, the safest route for every language is mods written as data against the card-language primitives (architecture-notes: "data for composition, code for primitives"), not code mods **[I]**.

### 3.9 Ecosystem and longevity

**Plugins that matter to Bramble:**

| Plugin | Status | From C# |
|---|---|---|
| Google Play Billing ([official](https://github.com/godot-sdk-integrations/godot-google-play-billing), Godot 4.2+, updated September 2026) | Documented for GDScript **[V]** | Untyped string calls unless wrapped **[I]** |
| Play Games Services ([official](https://github.com/godot-sdk-integrations/godot-play-game-services), Godot 4.3+) | GDScript **[V]** | Same |
| Apple in-app purchase / Game Center ([official iOS plugins](https://github.com/godot-sdk-integrations/godot-ios-plugins)) | Plugins **[V]** | The README itself shows `Engine.GetSingleton(...).Call(...)`, i.e. untyped **[V]** |
| GodotSteam | GDScript and GDExtension | "GodotSteam does not have a C# version currently" ([page, January 2026](https://godotsteam.com/tutorials/c-sharp)) **[V]**; community bindings or Steamworks.NET instead |
| Nakama (backend) | Official clients for both GDScript and .NET **[V]** | Yes |

- **Mixing languages:** GDScript calls C# members directly. C# reaches GDScript only through strings. Neither can inherit from the other, which the docs call "unlikely to change" ([cross-language scripting, 4.7](https://docs.godotengine.org/en/stable/tutorials/scripting/cross_language_scripting.html)) **[V]**. GDExtension classes (Rust or C++) appear to GDScript like built-in engine classes, with full types ([GDExtension C++ example, 4.7](https://docs.godotengine.org/en/stable/tutorials/scripting/cpp/gdextension_cpp_example.html)) **[V]**. C# gets no typed wrappers for them **[V]**.
- **Addon stores:** Godot's new Asset Store went live in May 2026, and the old Asset Library is becoming read-only ([blog](https://godotengine.org/article/introducing-the-godot-asset-store/)) **[V]**.

**Community and direction:**
- **Language share, 2025 community poll** (9,661 responses): GDScript 77.9%, C# 16.4% ([poll announcement](https://godotengine.org/article/godot-community-poll-2025/); figures via [Ziva](https://ziva.sh/blogs/godot-community-poll-2025)) **[V, secondary]**.
- **GDScript** is Godot's recommended language **[V]**. Its next steps (traits, typed callables, a faster VM) are stated goals without dates. The trait work was shelved in July 2026 **[V]**.
- **C#** is officially supported, with no deprecation, and 4.8 moves it to .NET 10 **[V]**. Godot's [priorities](https://godotengine.org/priorities/) aim at C# web export and at shipping C# as a plugin instead of a separate editor **[V]**. A GDExtension-based rewrite of the C# bindings ([godot-dotnet](https://github.com/godotengine/godot-dotnet)) is "still a work in progress" with no releases **[V]**. So C# in Godot is likely to change shape over the next few years; that is a migration risk and a likely improvement at once **[I]**.
- **Rust** depends on the godot-rust volunteers: pre-1.0, with support for each Godot version "for 1–2 years after their release" ([compatibility](https://godot-rust.github.io/book/toolchain/compatibility.html)) **[V]**.
- **C++** is official. Since godot-cpp 10, one extension build targets Godot 4.3 or later, and extensions keep working on later minor versions ([godot-cpp](https://github.com/godotengine/godot-cpp)) **[V]**.

**Shipped games:**
- **Most well-known commercial Godot games, mobile ones included, appear to use GDScript:** Brotato (with a mobile port), Dome Keeper, Cassette Beasts **[I, from mod tooling, job posts and a Godot showcase]**.
- **Slay the Spire 2** is the big C# exception: a desktop deckbuilder on Godot, early access 5 March 2026 ([Wikipedia](https://en.wikipedia.org/wiki/Slay_the_Spire_II)) **[V]**. Mega Crit said in a February 2026 AMA that its content was already C# classes before the engine switch, and that it uses a custom Godot fork, "MegaDot" ([fan summary of the AMA](https://slaythespire2.gg/news/mega-crit-ama-reddit-feb-2026)) **[V, secondary]**.
- **Backpack Battles,** the closest genre match, is a Godot 3 auto-battler that reached iOS and Android in February 2026 ([PocketGamer](https://www.pocketgamer.com/backpack-battles/official-launch-android-ios)) **[V]**. Its language is unconfirmed **[I: probably GDScript]**.

### 3.10 Day-to-day work

- **The edit-and-try loop.** GDScript changes take effect when the game is run again, with no build step **[I]**. C# needs a build (usually seconds) before Godot sees a change. Rust and C++ need a native rebuild, which can take longer, and their hot reload has known crash and file-locking issues on Windows ([gdext #582](https://github.com/godot-rust/gdext/issues/582)) **[V]**. For cloud workers, the extra build is one more step that can fail or time out **[I]**.
- **Can the owner read the code?** GDScript reads much like Python, which this repo's research tools already use **[I]**. C# is wordier but conventional. Rust is the hardest of the four to read without training **[I]**. If the owner wants to spot-check rules code, that favours GDScript or C# **[I]**.

---

## 4. Comparison table

| Question | GDScript (strict) | C# | Rust (GDExtension) | C++ (GDExtension) | Hybrid: GDScript UI + Rust/C++ core |
|---|---|---|---|---|---|
| **Is it typed?** | Optional; can be made compulsory | Fully | Fully, strictest | Fully, not memory-safe | Core fully; UI as GDScript |
| **Caught before running** | Most mistakes; no generics, interfaces or typed callbacks | Nearly all, except node paths and calls into GDScript | Nearly all, incl. memory errors | Types yes, memory errors no | Core: nearly all |
| **Fight-sim speed** | ~1–8 ms per fight **[I]**; fine for play | 10–50× faster **[I]** | Fastest tier **[I]** | Fastest tier **[I]** | Fastest tier for the sim |
| **1M-fight balance batch** | ~15–130 CPU-min **[I]** | ~1–10 CPU-min **[I]** | ~1–10 CPU-min **[I]** | ~1–10 CPU-min **[I]** | ~1–10 CPU-min **[I]** |
| **UI on a mid-range phone** | Engine-bound | Engine-bound; GC stutter risk; marshalling cost | Engine-bound | Engine-bound | Engine-bound |
| **Build size / start-up** | Smallest | +~76 MB of DLLs on desktop; slow Mono cold start reported on Android | + a few MB per platform **[I]** | + a few MB per platform **[I]** | + a few MB **[I]** |
| **Windows, Linux, macOS** | Stable | Stable | Stable | Stable | Stable |
| **Android** | Stable, proven by Autobattler | **Experimental** | **Experimental**; shipped games exist | Supported by godot-cpp; no maturity label | As the core's language |
| **iOS** | Stable (Mac) | **Experimental** (Mac) | **Experimental** (Mac) | Mac | As the core's language |
| **Web** | Stable | **None** | Experimental, nightly Rust | Custom templates | Custom templates |
| **Cloud setup added** | Nothing (proven) | ~217 MB SDK, NuGet; fits 5 min | rustup + crates; NDK for Android | compiler + SCons; NDK for Android | Both GDScript's and the core's |
| **Tests without Godot** | No | Yes | Yes | Yes | Core yes, UI no |
| **AI-agent track record here** | Strong (Autobattler, 8 days) | General C# strong; Godot-C# traps | Harder for models; strong compiler feedback | Riskier: crashes, not errors | Mixed |
| **Autobattler reuse** | Most scripts copy as-is | Lessons only; scripts rebuilt | Lessons only | Lessons only | UI-side scripts reusable |
| **Server / async ghosts** | Headless Godot server | Plain .NET server | Plain native server | Plain native server | Plain native server |
| **Consoles (W4 ports)** | All three | Switch, Xbox in beta | Not stated | Not stated | Not stated for the core |
| **Modding** | Easiest (packs) | DLL mods | Native code; data mods better | Native code; data mods better | Data mods |
| **Official plugins** | Native fit | String calls or wrappers; no GodotSteam C# | Called from GDScript side | Called from GDScript side | Native fit (UI side) |
| **Longevity** | Godot's own; 78% of users | Official; reshaping (.NET 10, plugin, GDExtension rewrite) | Volunteer, pre-1.0 | Official | Two stacks to keep current |

---

## 5. What each option would change in Bramble's plans

### GDScript (strict)
- **Toolchain plan:** unchanged. gdtoolkit, GUT, compile step, Autobattler's cloud setup and CI.
- **Copy from Autobattler as-is:** layers check (`layers.py`), the warnings-as-errors block, `compile_all.gd`, the GUT strict hook, the RNG, `check.sh`, screenshot tool, export smoke test ([reuse.md](autobattler/reuse.md)) **[V]**.
- **Design work needed:** typed effect classes instead of dictionaries, to avoid Autobattler's 358 `Variant`s. Without interfaces, the card language leans on abstract base classes **[I]**.
- **Balance:** batches run in parallel processes, as in Autobattler. Interactive "tweak and re-run" loops take minutes, not seconds **[I]**.
- **Later:** if the sim proves too slow, port the core only (see section 6).

### C#
- **Toolchain plan:** replace gdtoolkit/GUT with the .NET SDK, `dotnet format`, xUnit and gdUnit4Net. Add NuGet to the allowlist. Use the .NET Godot editor and templates. Install .NET 10, which covers 4.7, Android export and 4.8.
- **Architecture:** layers become separate projects, so the compiler enforces "core can't use presentation" with no custom checker **[I]**.
- **Platforms:** Android ships on an experimental path. Prove a release APK on a real mid-range phone early (start-up time, size, garbage-collector stutter), and accept that a web build is off the table until Godot ships C# web export.
- **Plugins:** write small typed wrappers around billing, Play Games and Steam.
- **Autobattler:** lessons carry over; scripts are rebuilt.

### Rust or C++ for the whole game
- **Toolchain plan:** compiler, crates or godot-cpp, the NDK for Android, a Mac runner for iOS and macOS, and a per-platform build matrix in CI.
- **Presentation in Rust or C++ is unusual** **[I]**. UI scenes, tweens and signals are verbose through bindings. One community comparison found gdext "very cumbersome" for game code **[V, community]**.
- **In practice** this option collapses into the hybrid below.

### Hybrid: GDScript presentation + a pure core in Rust (or C++)
- **The core:** a plain crate with no Godot types, tested with `cargo test` and run headless for balance at full speed. A thin GDExtension wrapper exposes it to GDScript as typed engine classes.
- **The presentation:** strict GDScript, reusing Autobattler's UI-side tooling.
- **Costs:** two languages and toolchains. Every worker change to the core needs a native rebuild before Godot can check the GDScript. Android, iOS and web builds of the core need the NDK, a Mac and (for web) custom templates. Rust on those platforms is "experimental", though shipped games exist.

### Hybrid: C# core + C# presentation (C# with discipline)
- Same as C#. The core is a Godot-free class library shared by tests, the balance runner and any future server. This is the Slay the Spire 2 pattern **[V/I]**.

### Hybrid: GDScript presentation + C# core
- Needs the .NET editor, so it inherits C#'s platform limits.
- GDScript can call C#, but those calls aren't statically typed, so Autobattler's strict `unsafe_*` errors would fire at every boundary call **[I]**.
- Weakest of the hybrids **[I]**.

### Hybrid: TypeScript core
- Inside Godot only via the GodotJS custom engine build (beta, behind stable). Otherwise server-only, with the rules written twice.
- Only worth it if a web or server stack in TypeScript is a goal in itself **[I]**.

---

## 6. Switching cost: choosing wrong, and keeping the door open

**What's expensive to switch [I]:**
- The **presentation** language: scenes, UI scripts, animations, plugin glue. In Autobattler that was 41k of about 59k lines **[V for the counts]**.
- **Tooling**: the gate, CI and cloud setup, built around one language.

**What's cheap to switch, if it is built for it [I]:**
- A **pure rules core**: no engine types, integers only, seeded named RNG streams, commands journaled, golden replays as JSON with a log hash. Autobattler's core was 3.2k lines **[V]**. The goldens become the oracle for a port: the new core is done when it reproduces every golden fight exactly.
- **Content as data** (JSON with a schema). It doesn't move at all.

**Translation tools** (GdScript2All, gd2cs.py) exist but need manual correction ([GdScript2All](https://github.com/Lcbx/GdScript2All)) **[V]**. AI workers with goldens to check against are likely the faster route **[I]**.

**Choices that keep the door open, whatever the language [I]:**
1. Keep the rules core free of engine types (architecture-notes §8 already says so).
2. Integer-only sim state, seeded integer RNG, no `Vector2` in sim state.
3. Golden replays on fixture content from day one (Autobattler's lesson: not on live content).
4. A narrow, data-shaped boundary between core and presentation: board snapshots in, a combat log out. Then the presentation never knows which language computed the fight.
5. Measure before porting: build a fight benchmark early, as Autobattler decision 7 did, and on a real phone.

**Choices that close doors [I]:**
- **C#** closes the web build until Godot ships it.
- **Rust or C++ for the whole game** makes UI work slower.
- **TypeScript** inside Godot ties Bramble to a custom engine build.

---

## 7. Questions for the owner, and which option fits which answer

1. **Does a web build matter?** (A browser demo, a web portal, a web-only test build.)
   - *Yes, soon:* GDScript, or the GDScript + Rust/C++ hybrid (more work). Not C#.
   - *No:* all options stay open.
2. **How important is Android at launch, and how much risk will you accept there?**
   - *First-class, low risk:* GDScript (proven by Autobattler).
   - *Willing to prove a less-trodden path early:* C# or the Rust hybrid (both labelled experimental), or the C++ hybrid (official tooling, but no maturity label and no Autobattler experience).
3. **How much balance simulation do you expect, and how interactive?**
   - *Nightly batches and occasional sweeps:* GDScript is enough, with parallel processes.
   - *Tight "tweak, re-run 100k fights, look" loops, or millions of fights per experiment:* a compiled core (C#, or the Rust/C++ hybrid). Or start in GDScript and port the core when a benchmark shows the need.
4. **How much do you value the compiler catching more (generics, interfaces, typed callbacks) against reusing Autobattler's working setup?**
   - *Reuse and proven tooling first:* GDScript.
   - *Stronger guarantees first:* C# or Rust.
5. **Is a server-authoritative mode or a separate server likely?**
   - *Likely:* a Godot-free core in C# or Rust runs on a server as a plain program. GDScript needs headless Godot there.
   - *Unlikely or far off:* no difference.
6. **Are code mods (not data mods) a goal?**
   - *Yes:* GDScript.
   - *Data mods are enough:* any option.
7. **How much toolchain complexity will you accept for cloud workers?**
   - *Least:* GDScript.
   - *Moderate:* C# (one SDK).
   - *Most:* Rust/C++ (compiler, NDK, a Mac in CI, a build matrix).
8. **Might consoles matter one day?**
   - *Yes:* GDScript is supported on all three through W4's ports; C# on two in beta; a native core is unconfirmed.
   - *No:* no difference.
9. **Steam, Play billing and Game Center from day one?**
   - All work best from GDScript.
   - C# needs wrappers, and has no official GodotSteam.

**Answer patterns [I]:**
- **Web or low-risk Android matters; balance needs are moderate** → GDScript, strict, with a pure core kept portable.
- **No web; strongest typing wanted; a .NET server likely; willing to prove Android early** → C#.
- **Web or low-risk Android matters *and* heavy balance simulation is central** → the GDScript + Rust/C++ hybrid. Possibly as a later step after starting in GDScript.

---

## 8. A recommendation (separate from the research above)

*This is my view. The sections above stand without it.*

**Start in strict GDScript, and build the rules core to be portable from day one** (section 6, items 1–5). Write the fight benchmark early, on a real phone and in a 100k-fight batch. Decide on a compiled core only if those numbers or the balance workflow call for it.

**Why:**
- It is the only option that is stable on every target, web included.
- It reuses a toolchain, quality gate and cloud setup that already survived 8 days of cloud workers.
- Its speed limit falls on balance batches, which can run in parallel or move to a compiled core later at a contained cost.
- The typing gaps are real, but strict settings plus typed effect classes close most of them.

**What would change it:**
- *You rule out web, and want the compiler's full guarantees or a .NET server* → C# becomes the stronger choice, provided an early Android release build proves start-up time, size and smoothness on a mid-range phone.
- *The early benchmark shows balance work is too slow to tune with* (for example, a typical balance experiment taking more than about 10 minutes on 4 cores, or whole-game bot simulations needing hours) → move the core to Rust or C++ behind the same boundary.
- *Godot ships C# web export and declares C# on mobile stable* → C#'s main costs go away.
- *Godot ships traits, typed callables or a faster GDScript VM* → GDScript's gaps shrink.
