# Workstream status blocks

The owner approved this rule on 4 Nov 2026:

> Each workstream's plan file starts with a status block: status (active, waiting on you, paused or done), last step done, next step, and waiting on you. The orchestrator updates it whenever a step merges, so the portal shows the truth.

The block sits directly under the plan's title. The portal reads it, so keep the markers and the four labels exactly:

```
<!-- status -->
- **Status:** active
- **Last step done:** What was done, in a sentence (4 Nov 2026).
- **Next step:** What comes next.
- **Waiting on you:** What the owner needs to do, or "Nothing yet."
<!-- /status -->
```

Status is one of `active`, `waiting on you`, `paused` or `done`.

A workstream with no plan of its own gets a short plan file in this folder. The portal's list of workstreams, with each one's branch and plan path, is `tools/portal/workstreams.json` on `portal/main`.

## Answered questions

The owner approved this addition on 4 Nov 2026:

> When a question in a workstream's questions file is answered, the agent that acts on it adds `**Answered (date):**` and the answer under the item, so the portal's open-question count stays true.

For example:

```
3. **Lobby.** A live lobby is used instead of async snapshots. Fine for playtesting?
   **Answered (5 Nov 2026):** Yes, fine for now.
```
