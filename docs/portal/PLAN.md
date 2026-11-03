# Bramble portal: plan (v2, approved 4 Nov 2026)

<!-- status -->
- **Status:** waiting on you
- **Last step done:** Step 1: home page, builds page and the service, live on port 8780 (4 Nov 2026).
- **Next step:** Step 2: decision and feedback forms into the inbox.
- **Waiting on you:** The step 1 checkpoint: open the site on your phone, check the status words, and install the APK from it.
<!-- /status -->

## The owner's words

> "I want to have a web server that you host that has a website that I can use to interact with this project. I want the website to be nicely constructed, like highly polished, that I can interact with. I want it to cover the status of various work streams. So essentially act as like a documentation portal, but really follow the philosophy of kind of like good UI and UX design and dashboard design, where you can see the headline status for something and then drill down into the detail if you want to. So I kind of want to understand where various work streams are across different parts of the project. Have access to the content library, see what's been tried, what's been marked as not tried, you know, where iterations are currently at. Have some ability to submit user forms in the website or something, you know, so that I can talk to agents about content there or whatever and leave feedback, and with instructions and stuff to use the latest build so that I'm not always interacting via agent chat windows. And it should be hosted on this machine you're at, for my local network."

## Revision 3: decisions first (owner feedback, 4 Nov 2026, after step 1) — DRAFT for approval

### The owner's words, quoted

> "Okay, I think a lot of this stuff's overworded and doesn't really follow what I want, right? There needs to be more tiers to stuff and less focus on process and, you know, focus on me as a user. What do I want? Keep it simple. Like, this is the decision. Here's why it matters. State it plainly and concisely. Like, I come in here and it says design lab. Around on the direction or mix you pick. *[A round on the direction or mix you pick.]* What does that mean? … The gallery has the evidence. You know, which direction to mix or take further. None of this tells me about what I'm choosing. If it's about... For example, say... Make choices about how the design of the UI and UX is going to feel for the game. Also, the visual design of cards and the shop. Outstanding decisions. Accept the current designs. There are these designs. Pick your favorite. Or ask for additional iteration. That kind of thing. That would be, you know, I want, as a decision maker, to know, A, what the context of the decision is, what area does it affect? B, what are the exact decisions I need to make? And C, if I'm unclear about a decision, get additional detail and drill down. And that's what I want this site to serve. So have another pass on the site and maybe draft some wording rules for how this stuff needs to be summarized."

### What changes

- **Wording:** every word the portal shows follows `docs/portal/WORDING.md` (draft, for the owner's OK).
- **Home becomes decision-first, in three tiers:**
  - **Tier 1, Home:** "What needs you": the big decisions, grouped by area, one line each. Then one bundle per area of small picks ("11 small picks already made: accept all or review"). Then one plain line per area on where it's at. Then the latest build.
  - **Tier 2, Decision card:** the area, the question, 2–4 options (each saying what happens), why it matters, and the recommendation. Answer buttons and an optional note go here.
  - **Tier 3, Detail:** evidence, history, links (gallery, docs, plan), and the original question text.
- **Decision records:** each open decision becomes one short file, `docs/decisions/<id>.md`, on the branch of the workstream it belongs to. It holds the area, the question, the options, why it matters, the recommendation, big or small, and the detail. The portal reads `docs/decisions/` on every registered branch. The existing question lists stay as the detail and history.
- **Status blocks** gain one line, **In short:**, a plain sentence the home page shows. The other four lines move to the detail tier. *(This adds to the owner-approved status-block format, so it needs the owner's OK.)*
- **Answers:** the decision card's buttons save the answer, plus your note, to the portal inbox. That's step 2's forms, brought forward for decisions only. An agent picks it up at the start of a session (answer 2a), acts on it, and marks the question answered.
- **Rewriting the content:** an agent writes the decision records for every open question now: the prototype's 16, the review queue's open items, and one each for the design lab, the mechanics library, art and folio, and architecture. It follows the wording rules. A scope review checks each record against its source question.

### Revised steps (replacing steps 2–4 above)

1. **Wording and decisions pass:** the decision records, the "In short" lines, and the three-tier home and decision pages with answer buttons into the inbox.
   **Checkpoint:** you open the home page and can say, for each decision, what area it affects and what you're choosing, without opening the detail.
2. **Feedback form** (free-form, linked to any page) and the inbox pickup at session start.
3. **Content library and workstream pages,** worded the same way.
4. **Polish:** accessibility, and empty and error states.

## What it is

A website served from the Optiplex for the owner's own devices. It reads the project as it stands in git and in `/data/bramble-builds`, and it never edits the repo. The owner's input goes into its own store. Agents pick that input up from there.

## Pages

Each page opens on the headline: status, what changed last and what's waiting on the owner. The detail sits one tap below.

1. **Home.** One card per workstream: Prototype, Design lab, Rules and budget, Mechanics library, Art and folio, Architecture. Each card shows:
   - a status word (active, waiting on you, paused or done);
   - the last activity and its date;
   - the next step;
   - the count of open questions.

   Under the cards: a "Latest build" card with direct downloads, and a "Waiting on you" list.
2. **Workstream page.** Shows:
   - the plan;
   - progress through the plan's steps;
   - recent commits as a timeline;
   - the workstream's docs, rendered (plan, learnings, morning reports);
   - its open questions.
3. **Content library.** All 75 mechanics-library entries, plus the prototype's units and scenarios. It is searchable and filterable by category, tribe and status. Status is joined on each unit file's `source.entry`, not on script names:
   - **in the build:** a unit on `proto/main` uses the entry;
   - **has a scenario:** a sandbox scenario shows it;
   - **not tried:** neither.

   You can also mark an entry yourself, for example "played it" or "not for us", and your mark shows beside the automatic status. Each entry opens to its full text, its variations, where it is used, and a comment button.
4. **Design lab.** A headline card (the current round, the top directions and what's next), plus the existing gallery (`docs/design-lab/gallery.html`) served from its branch rather than rebuilt.
5. **Decisions.** The prototype's OWNER-QUESTIONS and the review queue. Each item shows its context and has an answer form. Answered items show the answer and what an agent did with it.
6. **Feedback.** A free-form form with an optional link to any page or item, plus a thread view of past messages and agents' replies.
7. **Builds.** Every build, its README, what's new, and how to install it. Downloads go straight to the phone, so the APK installs without the desktop.

## How it's built

- **Server:** Node 24, already on the machine, with as few packages as practical. It runs as a systemd user service, `bramble-portal`, which restarts on failure and starts at boot.
- **Address:** port 8780. It listens on all interfaces and refuses any client outside the LAN (192.168.0.0/16) and Tailscale (100.64.0.0/10). This survives DHCP address changes and a network that comes up late at boot. The machine has no public address.
- **Data:** an indexer reads every branch through `git show` and `git log` in the main repo, so it never depends on a worktree's state. It also reads `/data/bramble-builds`. It re-indexes when a branch head moves, checked with one cheap `git rev-parse` per request burst, and on demand. The index lives in memory only.
- **Owner input:** stored as dated JSON records in `/data/bramble-portal/inbox/`, outside the repo and backed up by copying.
- **Frontend:** server-rendered HTML with a small amount of script. It needs no build step, works on phone and desktop, and supports light and dark. Design-lab images are served from their branches. Markdown is rendered on the server.
- **Code:** `tools/portal/` on a new branch `portal/main`, in worktree `~/code/Bramble-portal`, branched from `main`. A PR to `main` when it's ready, as with other work.

## Where status comes from

The repo doesn't record "active / waiting on you / next step" anywhere. An indexer would have to guess, and `docs/STATUS.md` is two days stale. So each workstream keeps a short **status block** at the top of its plan file: a status word, the last step done, the next step, and what's waiting on you. The orchestrator updates it whenever a step merges. The portal reads those blocks. This is a new standing rule for agents, so its wording is yours to OK (question 1).

## Steps

Each step passes the two gates before it is merged: runtime (tests, plus Playwright journeys and screenshots at phone and desktop size) and a scope review. Each page gets a design pass as it lands. Each part of the index is built alongside the page that shows it.

1. **Status blocks, then the home page, the builds page and the service.** Add the status block to each workstream's plan. Build the home page and the builds page, and install the systemd service.
   **Checkpoint:** you open it on your phone, check the status words against what you believe, and install the APK from it.
2. **Decisions and feedback forms into the inbox,** with pickup as you choose (question 2).
   **Checkpoint:** you send one message and see an agent act on it.
3. **Content library and workstream pages.** The library carries the tried status and your marks. Workstream pages show rendered docs and a commit timeline.
   **Checkpoint:** you check that "tried" matches what you have played.
4. **Design-lab card and gallery link, then polish:**
   - an accessibility check (contrast, touch targets, keyboard);
   - empty, loading and error states;
   - a hand-over note on how to use it.

**Deferred:**
- Agent replies shown as threads, until a pickup writes back.
- A disk cache of the index, if startup gets slow.

## Load on the machine

One small Node process (well under 200 MB) and one `git rev-parse` per burst of page loads. Building it uses one or two agents at a time, plus Playwright renders.

## Owner's answers (4 Nov 2026)

1. **Status source:** the status-block rule, OK as worded. It is now in `CLAUDE.md`, with the format in `docs/workstreams/README.md`.
2. **How messages reach agents:** (a). An agent reads the inbox at the start of each session. Nothing acts on a message until a session starts.
3. **Who can reach it:** LAN plus Tailscale, with no passphrase.
4. **Your typed answers:** kept in the portal's inbox. Agents quote them in the docs they change. They are not saved as owner notes.

## Questions as asked

1. **Status source.** Do you OK this standing rule for agents? "Each workstream's plan file starts with a status block: status (active, waiting on you, paused or done), last step done, next step, and waiting on you. The orchestrator updates it whenever a step merges, so the portal shows the truth." Or do you accept a guessed status?
2. **How messages reach agents.**
   - (a) An agent reads the inbox at the start of each session.
   - (b) A scheduled agent run every few hours triages new messages, replies on the site, does small asks and flags bigger ones.
   - (c) A "send now" button wakes an agent for one message.
   - (b) and (c) act without you each time.
3. **Who can reach it.** LAN plus Tailscale, or LAN only? With a passphrase or without? If agents act on messages on their own, a passphrase stops anyone else on the network from instructing them.
4. **Your typed answers.** Should they be saved as dated owner notes, as your words (records that can't be edited later)? Or kept in the portal's inbox, with agents quoting them where they apply?
