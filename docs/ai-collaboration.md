# Penguin Wars — AI Collaboration Guide

This repository has been developed with multiple AI agents. This document prevents future agents from solving the same problem in incompatible ways.

## Roles

### User / Creative Director

Owns:

- taste
- feel
- priorities
- playtest judgment
- final yes/no on direction

The user's feedback from a live build outweighs an agent claiming a feature is “complete.”

### ChatGPT

Primary role:

- integration referee
- architecture continuity
- design synthesis
- QA review
- handoff writing
- repository inspection
- keeping the project from fragmenting

ChatGPT should inspect pushed commits directly before accepting completion reports.

### Claude / Opus-style architecture lane

Best used for:

- architecture changes
- data ownership
- seams
- run/world structure
- refactors with long-term consequences
- complex integration contracts

Claude's architecture freeze at `e4c946b` remains an important reference.

### Antigravity / implementation lane

Best used for:

- concrete gameplay features
- content
- presentation
- tests
- render-smoke captures
- implementation from a precise handoff

### Gemini Flash High

Useful for:

- finishing well-specified implementation tasks
- careful mechanical porting
- visual/presentation work
- tests
- follow-through after architecture is already decided

Do not ask a fast implementation model to casually redesign core architecture while coding.

## The single-architecture rule

> Nobody creates another competing run, room, cave, party, world or combat manager.

If an existing authority can own the feature, extend its seam.

Current authorities:

- Expedition: travel / current place
- CaveDefinition: cave route graph
- RoomDefinition: room geography
- RoomExit: exit data
- PartyGate: co-op exit threshold
- EncounterDefinition: combat data
- EncounterDirector: combat lifecycle
- RunSession: shared wiring
- RunProgression: XP/run-choice policy
- RunWallet: personal balances
- RunModifiers: whole-run difficulty
- BossSchedule: milestone selection data
- CharacterDefinition / CharacterTrait: character content

## Required handoff format

Every implementation handoff should include:

1. **Authoritative base branch and SHA**
2. **Goal**
3. **Architecture rules that may not change**
4. **Specific files/systems safe to touch**
5. **Specific files/systems not to create**
6. **Behavioral acceptance criteria**
7. **Tests required**
8. **Render-smoke captures required when visual**
9. **Explicit deferrals**
10. **Final report requirements**
11. **Do not merge to main unless explicitly instructed**

## Required completion report

An agent finishing a task should report:

- branch
- pushed commit SHA
- what changed
- architecture compatibility changes
- what was deliberately not changed
- test commands and pass/fail
- render-smoke commands and captures
- warnings/TODOs
- whether main was touched

A report is not proof. Verify the GitHub branch/head.

## Branch discipline

When another agent is actively editing `antigravity`:

- do not write unrelated docs or features onto that same branch
- use a separate branch
- merge/cherry-pick later

This avoids accidental conflicts and makes review easier.

Recommended naming examples:

- `docs/project-memory`
- `feature/field-shop`
- `feature/snow-pickups`
- `integration/<topic>`

## Architecture review checklist

Before approving a gameplay commit, ask:

- Is Expedition still the only travel authority?
- Is RoomDefinition still the geography source of truth?
- Is EncounterDefinition still combat data?
- Did anything reintroduce a global current-room singleton?
- Did any boss content apply room/run scaling itself?
- Did visual scale accidentally change gameplay collision?
- Did BossSchedule gain lifecycle or difficulty authority?
- Did Township start becoming a second Field Shop?
- Did viewport size change gameplay geometry?
- Does 1–4 player support still hold?

## Boss scaling review checklist

Correct order:

```
BossDefinition base data
→ BossActor.configure(definition, party_size)
→ party-size HP scaling
→ configure returns
→ EncounterDirector applies room difficulty × RunModifiers once
```

Do not duplicate scaling.

## Character review checklist

- Player code must not switch on character names.
- Character-specific rule changes belong in CharacterTrait or another explicit content seam.
- `body_scale` is art.
- `collision_scale` is gameplay.
- Never infer hitbox from art size.

## Human playtest protocol

After meaningful playable work, ask the user to test the real scene.

Prioritize subjective questions:

- Is it fun?
- Is it readable?
- Does it feel responsive?
- Does the room feel too small/empty?
- Does the HUD get in the way?
- Is a branch understandable without reading?
- Does a boss feel like a boss?
- Does anything look like debug UI?

Do not hide behind green tests when the user says something looks or feels bad.

## Visual work protocol

For visual/presentation tasks:

- capture real renderer screenshots
- inspect them
- compare against previous baseline
- do not declare “polished” from code alone

Useful captures often include:

- normal 2-player combat
- 4-player layout
- town
- branch room
- boss state
- mobile
- locked/unlocked environmental state

## Current design decisions future agents should know

- Full-screen world presentation is preferred.
- Corner HUD cards are preferred to giant permanent panels.
- Physical Zelda-like doorways are preferred to teleport pads.
- Doorways should eventually support short directional screen slides.
- World Snow pickups should become chunky blobs, while HUD may keep ❄.
- Township is a pre-run/meta hub.
- Field Shop is the between-wave paid run-power shop.
- Most characters eventually have six weapon slots.
- Weapon tiers and duplicate merging are planned.
- Global run target is 20 waves.
- Boss milestones are based on global run wave.
- Meta progression should be horizontal rather than permanent raw-stat inflation.
- Humor is dry, concise and rooted in serious penguin civilization.

## When architecture and feel conflict

Do not solve presentation problems by breaking ownership rules.

Example:

Bad:
- create a second room manager just to animate a Zelda screen scroll

Good:
- keep Expedition authoritative
- feed a transition presentation layer directional data from RoomExit.Side
- swap rooms through the existing path

Likewise, do not preserve technically elegant UI if the live game looks bad. Keep the system, redo the presentation.

## Current documentation map

- `docs/architecture.md`: code ownership/seams
- `docs/project-memory.md`: durable history/current state
- `docs/design-bible.md`: game/design direction
- `docs/roadmap.md`: planned implementation order
- `docs/ai-collaboration.md`: agent workflow and guardrails
- `docs/verification.md`: test/render evidence
- `docs/hub-and-dungeons.md`: existing town/cave design notes
