# Penguin Wars Night Shift Queue

Purpose: define work that can safely continue without the creative director at the computer.

This file is intentionally conservative. Agents may make progress, but they do not get authority to redefine Penguin Wars.

## Labels

### NIGHT_SAFE
May be implemented, tested, committed and pushed on an isolated branch without waiting for director input.

Requirements:
- acceptance criteria are explicit
- no new art-direction decision
- no new architecture unless already authorized
- no merge to main
- regressions required
- stop on ambiguity

### PROTOTYPE_ONLY
May be explored and committed to an experiment branch.

Requirements:
- cannot replace approved production behavior
- cannot merge
- must produce evidence: tests, captures, report or measured results
- director decides whether it survives

### DIRECTOR_REVIEW
Do not implement while the director is absent.

Examples:
- final art approval
- enemy/weapon identity changes
- level-layout changes
- balance verdicts
- deciding whether a mechanic is fun
- replacing a locked system
- merges to main

## Global night-shift rules

1. One bounded task per branch/worktree.
2. Never merge `main`.
3. Never clean/delete protected dirty work, stashes or unknown generated files.
4. Reuse existing architecture before creating a new seam.
5. If requirements conflict, stop and report instead of inventing a compromise.
6. Shared Resources remain immutable at runtime.
7. Preserve 1-4 local co-op.
8. Preserve Expedition / RoomDefinition / EncounterDefinition / RunSession / PartyGate authority.
9. Do not expand scope because something nearby is easy.
10. Every completed task reports:
   - branch
   - HEAD
   - files changed
   - tests
   - review artifacts if visual
   - known limitations
   - exact stop point

## Current weekend queue

### NS-01 - GitHub Actions headless smoke bootstrap
Label: NIGHT_SAFE

Goal:
- prove that the repository can run at least one Godot headless test in GitHub Actions without the Windows workstation.

Minimum success:
- install Godot 4.7.2 in CI
- run import
- run `tests/foundation_test.gd`
- preserve repository contents
- no deployment
- no secrets

Do not attempt renderer/video tests in the first workflow.

If Godot 4.7.2 cannot be installed cleanly with the chosen action, stop and document the blocker rather than pinning a random engine version.

### NS-02 - Phase A code-seam audit
Label: NIGHT_SAFE

Goal:
Read existing code only and write a concise implementation map for:
- Frozen Coast room insertion point
- authored spawn markers
- current charger behavior reuse for Tuskbull
- current ranged/projectile reuse for Skua
- current weapon controller/visual seams for Spear/Slingshot/Snowbomb

Output:
`docs/production/phase-a-code-seam-audit.md`

No runtime code changes.

### NS-03 - Phase A test skeleton plan
Label: NIGHT_SAFE

Goal:
Define test files/assertions needed for:
- route transition and closed arch
- Rolly behavior
- Skua perch/locked landing point
- Tuskbull hard impact vs soft drift
- Spear line pierce
- Slingshot projectile
- Snowbomb arc/area
- 1-4P scaling

Output documentation only unless a test can be added without requiring unfinished runtime classes.

### NS-04 - Phase A runtime implementation
Label: DIRECTOR_REVIEW until Codex/interactive workstation is available

Reason:
This is playable combat content. It needs direct runtime testing and human feel review as it is assembled.

### NS-05 - Character material/world-fit production replacement
Label: PROTOTYPE_ONLY

Allowed:
- controlled material/render experiments
- comparison captures

Not allowed:
- re-render complete animation library
- replace production frames
- remodel penguin

### NS-06 - Frozen Coast Phase B/C
Label: DIRECTOR_REVIEW

Do not start before Phase A playtest.

## Phase A production order

When interactive implementation resumes:

1. Gate -> Pass -> Driftfield room
2. static collision and markers
3. Rolly
4. Fish Spear
5. Wave 1 playtest
6. Skua + Slingshot
7. Wave 2 playtest
8. Tuskbull
9. Snowbomb
10. mixed waves
11. 1-4P test
12. director playtest
13. only then Phase B

## Overnight agent stop words

If an agent encounters any of these questions, stop:

- "Should we redesign..."
- "Maybe a better architecture would be..."
- "We could also add..."
- "While here I cleaned..."
- "The concept seems incomplete so I invented..."
- "I merged..."
- "I replaced the approved..."

The night shift's job is to arrive in the morning with useful, reviewable work, not a surprise new game.
