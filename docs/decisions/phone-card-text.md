---
id: phone-card-text
group: looks
size: big
headline: Does card text need to be readable on a phone yet?
source: proto/main:docs/prototype/OWNER-QUESTIONS.md#12
image: proto/main:docs/prototype/screens/recruit_select_1688x780.jpg | The playable game at phone size, with a tapped card open on the right
option: Tapping a card is enough for now
option: Make on-card text readable on phone
---
In the playable game, every card now shows its full rules text on a computer screen. On a phone it's a different story: the text is tiny. The smallest comes out around 7 pixels high, and even normal board-card text is about 9, when phone apps usually aim for 11 or 12 at the very least.

What you can do today is tap any card. It opens on the side of the screen with its text at full size, so nothing is hidden, it just isn't readable at a glance.

{image:1}

**What we need from you:** does readable text on the card itself matter on phone yet, or is tapping to read good enough while we're playtesting? Making it readable means one of two things: bigger cards on phone, or less text on each card (for example, keyword chips with the full rules on tap, which the design lab's Folk Print and Woodcraft mock-ups already try).

**Why it matters:** it decides how big cards are on a phone and how much each one can say, and that shapes every screen layout and how long card text can be from here on.

We'd suggest tapping is fine for now, and coming back to it with whichever look you pick, since the looks handle card text differently.

## Detail

- **Measured sizes (prototype, phone-size render):** smallest rules text about 7 px; unshrunk board-card text about 9 px; the usual phone minimum is 11–12 pt.
- **What exists:** full rules text on every card at desktop size; at phone size, tap a card to open the inspector with full-size text. Nobody has played it on a real phone yet.
- **Related picks already in the build:** keyword-only sentences move to a chip above the name (question 13), long text shrinks first and is cut with "…" only as a last step (question 9), and a card with very long text gets a shorter portrait (question 14).
- **Design lab:** round 2 of Folk Print drops rules text from phone shop cards entirely (keyword and trigger chips, full text on tap). Woodcraft and Storybook Ink show a tapped keyword chip opening a slip or bubble with the full rule.
- **The suggestion** is ours, not from the prototype's notes. The morning report lists this among the questions that most change what comes next.

**The original question (prototype question 12):**
> "Card text on phone. Rules text now shows in full on every card at desktop size. On a phone it is tiny: the smallest is about 7 px, and even unshrunk board-card text is about 9 px, against the usual 11–12 pt phone minimum. Tapping a card opens the inspector with full-size text. Does readable on-card text on phone matter yet, or is the inspector enough for now? Making it readable means bigger cards on phone, or less text on them."

Sources: `proto/main:docs/prototype/OWNER-QUESTIONS.md`, `docs/prototype/MORNING-REPORT.md`, `docs/prototype/PLAYTEST.md`; `design-lab/main:docs/design-lab/r2/*/note.md`.
