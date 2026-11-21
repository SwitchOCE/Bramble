# Database trial: one database, one small sample of match data

You are one of three agents. Each tests a different database on the same sample. Another agent compiles the three reports into a debrief for the project owner, so your report is the product. Be honest about every dead end: the trial measures how hard it is for an agent to set up and use the database, not just whether it ends up working.

## The project, in one paragraph

Bramble is an auto-battler game (8 players buy units in a shop each round, then their boards fight). A Rust engine plays bot-vs-bot matches for balance testing. Until today every match wrote large uncompressed JSON-lines logs; an old league filled 57 GB. The owner wants "the ability to do standard developer analytics on balance choices and understanding the game state without storing far too much information", and wants to know whether a database, compression, or both, is the right way to keep match data.

Two kinds of data matter:
- **Archive:** each game's replay record (`records/game-NNNNN.jsonl`). It must be kept so a game can be replayed exactly and so player "ghosts" can be cut from it. It must come back byte-for-byte.
- **Analysis:** what the balance designer asks of the data (their own list, below).

## Your database

**{{DB}}**

## Where things are

- The sample: `/data/dbtest/sample/` — a 200-game match played with the project's final bots. Read only; copy what you need. Look at the files yourself to learn their format; the match writer's code is `tools/league/league/src/matchrun.rs` in the repo at `/home/alex/.t3/worktrees/Bramble/docs-league-data-storag-5aa7773d2cb236de` if you need it (read only).
- Ignore `sample/private/` (a match secret, not data).
- Your folder: `/data/dbtest/{{DIR}}/`. Everything you install, write or download goes here.

## The balance designer's questions (their words, lightly cut)

1. Per card, from shops: how often it's bought when it's offered, by round and by the buying player's tribe; how often it's sold; the value the bot puts on it, if the bot records one.
2. Per card, from final boards: how often it's on a final board; average place with it against without it; how often it's golden.
3. Per tribe: average place; the tribe's share of final boards; place by round reached.
4. Per round: median and spread of board stats (attack, health), and of each tribe's own resource counters if recorded.
5. Per fight, as counts only: kills by source, deaths per fight, uses of each mechanic — as far as the sample records these.
6. Boards to refight: fetch a sample of full board snapshots for a given round (e.g. 50 boards at round 8).

Answer whichever the sample's data supports; say plainly which it can't, and why.

## What to do

1. **Set up {{DB}}.** Install it without sudo, inside your folder (a venv, a downloaded release binary, whatever is normal for it). Find its official documentation, and any file meant for agents (an `llms.txt`, an agent skill, a docs MCP). Note what you used and whether it helped.
2. **MCP server.** Find the right MCP server for {{DB}} (prefer an official one; say what you found and why you picked it). Install it inside your folder. Register it only in a config file in your folder, never in `~/.claude.json`, `~/.claude/` or any global or project settings. Prove an agent can use it: one headless run like `claude -p "<a question that needs the database>" --mcp-config <your file> --strict-mcp-config --model claude-haiku-5-5`, and save its output. If no usable MCP server exists, say so and what an agent would do instead.
3. **Load the data.** Archive layer: all 200 replay records, retrievable byte-for-byte (prove it with a checksum comparison). Analysis layer: whatever tables/collections you'd design for the six questions.
4. **Compression.** Measure, for the 200 replay records: raw size; gzip -6; zstd -3 and -19 (if zstd is missing, get it inside your folder); xz -6; and the size inside {{DB}} with its default settings and with its best compression settings, if it has any. Also the total on-disk size of your analysis layer. Include time to compress and decompress where it matters.
5. **Query.** Answer the six questions with {{DB}} queries. Time each one (median of 3 runs). For at least two questions, check the answer against a plain Python count over the raw files. Fetch one game's record back.
6. **Scale guess.** From your numbers, estimate disk use and query time for 100,000 games. Say how you estimated.

Keep to 2 CPU threads: the other two agents run on the same 6-core machine at the same time.

## Rules

- Never write outside `/data/dbtest/{{DIR}}/`. Don't edit the repo or the sample. No sudo. Don't change global config, shell profiles or anything in `~/.claude*`.
- Never read token, credential or `auth.json` files.
- Never run `rm -rf` outside your folder.
- If a permission check refuses something, stop that step and report it; don't work around it.
- Don't read the other agents' folders (`/data/dbtest/*` other than yours and `sample`) until your report is written.

## Your log, as you go

Keep `/data/dbtest/{{DIR}}/LOG.md`: a timestamped line (`date +%H:%M:%S`) at the start and end of each step, and every error, dead end, retry and doc lookup, one line each. This is the main evidence for "effort required for agents to set up and use it", so don't tidy it afterwards.

## Your report: `/data/dbtest/{{DIR}}/REPORT.md`

Use these headings, short and plain:

1. **Result in three lines.**
2. **Setup:** steps that worked, wall time per step from the log, number of failed attempts, docs/agent files used.
3. **MCP server:** which, why, did the headless agent run work, its output in brief.
4. **Sizes:** one table (raw, gzip, zstd -3, zstd -19, xz, in-database default, in-database best, analysis layer), in KB per game and MB per 1,000 games.
5. **Queries:** one table (question, answered yes/partly/no, median ms, checked against Python yes/no). One line on how hard each was to write.
6. **Scale guess** for 100,000 games.
7. **Pros and cons** for this project, from what you did, not from general reputation.
8. **What an agent would struggle with** next time, and what would fix it (a doc, a skill, a helper script).
9. **Disk report:** what you wrote, sizes, what can be deleted.

Your final message: the report's section 1, plus the path to REPORT.md.
