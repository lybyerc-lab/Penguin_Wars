# Penguin Wars — Field Shop + Larry V1 Design Lock

Status: **LOCKED FOR V1 / PLAYTEST-DRIVEN**
Date: 2026-09-23

This document preserves the approved V1 direction for the Field Shop, Larry, and the game's lightweight dialogue/narration style. Future changes should come from actual playtest evidence, not speculative expansion.

## North-star fit

Penguin Wars remains:

**BROTATO + ZELDA + PENGUINS**

Development priority:
- Township feels alive.
- Expeditions feel like journeys.
- Combat/builds are replayable enough that players want another run.
- Prefer frequent playable progress over speculative infrastructure.

The Field Shop exists to support the run loop without turning Township into a menu hub or creating a second progression game.

---

# 1. FIELD SHOP V1 — LOCKED

## Purpose

The Field Shop is the **between-wave, run-specific acquisition stop**.

It supports the run philosophy:

**Acquire -> Commit -> Survive -> Mature**

The Field Shop is for **Acquire + Commit**.

It is **NOT** where weapons are directly upgraded, merged, or matured.

## V1 behavior

For the first playable expedition slice:

- The Field Shop appears during the between-wave intermission.
- Combat is paused while the shop is active.
- The player spends collected **Snow**.
- The shop presents a small set of run-valid offers.
- Weapon purchases occupy real WeaponRack slots.
- A duplicate weapon occupies another real slot and both copies function independently.
- No Weapon I -> Weapon II purchase button.
- No direct merge UI.
- No maturation at the Field Shop.
- A scarce, separate maturation event remains responsible for resolving compatible duplicates later.
- The player explicitly leaves the shop / continues the expedition.

## Initial offer shape

Keep V1 deliberately small:

- **3 weapon offers** per visit.
- Offers are drawn from the currently unlocked run pool.
- Each offer clearly shows its weapon classes/tags.
- One refresh/reroll action is allowed by spending Snow.
- Refresh cost may increase during the same shop visit if needed for economy tuning.
- Exact prices are tuning values, not architecture.

For the first vertical slice, avoid building a large item ecosystem. If playtesting shows the shop needs a simple recovery/supply purchase, add one later as a narrow playtest-driven extension.

## Six-slot commitment rule

- The existing six-slot WeaponRack remains authoritative.
- Buying a weapon requires an available slot.
- Do not create backpack storage in V1.
- Do not create a complex sell/scrap inventory system in V1.
- Full-rack behavior should remain intentionally restrictive until maturation/discard behavior is proven through playtesting.

This preserves meaningful commitment instead of turning the rack into a temporary holding area.

## Pacing rule

V1 may show the Field Shop after each completed combat wave so the Brotato-like acquire/build cadence is immediately testable.

If this interrupts the Zelda-like journey too often, reduce shop frequency based on playtesting rather than designing a complex schedule in advance.

## Separation from Township

Township is the home/meta hub.

Field Shop is an expedition/run system.

Do not turn Township buildings into a duplicate between-wave weapon shop.

---

# 2. LARRY V1 — LOCKED

## Name

**Larry**

He introduces himself as:

**"Larry. With a y."**

The unnecessary clarification is part of the joke.

Do not rename him to Larrie, Larri, or any alternate spelling to make the joke literal. His name is simply Larry.

## Core role

Larry is the **nomadic Field Shop merchant** and a recurring, unreliable expedition narrator/guide.

He should feel as if he has somehow already been everywhere the players are going.

The recurring joke is not that he is secretly omnipotent. It is that he behaves like an impossibly seasoned survival legend despite having extremely unimpressive actual hardship.

Canonical seed story:

> Larry once got stuck in the caves for a whole three hours.

To Larry, this is a life-defining survival ordeal.

He may reference it with the gravity of a penguin who crossed an endless frozen wasteland.

## Visual identity

LOCKED core traits:

- Penguin
- Eyepatch
- Wooden peg leg
- The wooden leg is visibly **strapped/tied onto his completely normal orange foot**
- His real foot is still present and healthy
- Slightly over-equipped expedition/merchant appearance
- Portable improvised Field Shop setup
- Comically self-serious "veteran explorer" presentation

Important:
The wooden-leg joke only works if the normal foot is still visibly there. Do not replace or amputate the foot.

The eyepatch is theatrical. Do not build injury lore unless a later joke genuinely needs it.

## Portable shop flavor

V1 environmental ingredients can include a small subset of:

- little sled/cart
- fish/supply crates
- lantern
- patched canopy
- hand-painted sign
- expedition junk

Keep the setup compact. Larry is not permission to build a traveling-camp simulation.

## Personality

Larry should be:

- dramatic
- confident
- friendly
- slightly unreliable
- never cruel
- convinced that ordinary inconveniences are legendary expedition hardships
- useful despite the nonsense

He should occasionally possess genuinely helpful knowledge, which makes it harder to tell when he is exaggerating.

## Recurring gag structure

Larry's comedy should come from **commitment to his own legend**, not nonstop random jokes.

Examples of the energy:

> "Three hours in the caves changes a bird."

> "Larry. With a y."

> "You wouldn't believe what I've seen out there."

A character may occasionally point out the obvious contradiction. Do not explain every joke.

## Narrator role

APPROVED: Larry may serve as a recurring overall narrator/guide.

But he is **not an omnipresent voice-over**.

Use him selectively for:

- expedition introductions
- region introductions
- occasional tutorial/help beats
- Field Shop appearances
- return/result comments
- chapter/title-card flavor
- rare transitions where a short line improves personality

Do NOT use Larry to:

- narrate every room
- explain obvious actions
- interrupt combat
- deliver long lore dumps
- replace environmental storytelling
- speak over emotional or discovery moments that work better silently

The world should remain capable of speaking for itself.

Larry's narration can be unreliable in tone, but gameplay instructions must still be clear and truthful.

---

# 3. DIALOGUE STYLE V1 — LOCKED

## Direction

Use a **Nintendo-style console-adventure dialogue philosophy** without copying specific Nintendo characters, phrasing, UI, or scripts.

Desired qualities:

- short
- readable
- charming
- characterful
- visually paced
- easy to advance
- rarely more text than the joke/information needs

## Text-box rhythm

Default conversation beat:

- 1-2 short sentences per text box
- 2-4 boxes for an ordinary interaction
- longer sequences only when the moment truly earns them
- punchlines get their own beat when timing helps
- allow fast advance / skip
- never trap the player in slow text animation

Dialogue should read comfortably on mobile and during couch co-op.

## Presentation ideas

Allowed later, if cheap and useful:

- character name label
- subtle portrait/character reaction
- tiny text blip sounds
- selective emphasis on one or two words
- brief pause before a punchline
- simple choice prompts when there is an actual choice

Do not create a massive dialogue framework before the first useful conversations exist.

## Writing rule

Prefer:

**one memorable line**

over:

**a paragraph explaining the joke, lore, and mechanic.**

Characters should sound distinct without every sentence trying to be funny.

Larry gets the strongest narrator voice, but Township NPCs should have their own small personalities.

---

# 4. V1 IMPLEMENTATION GUARDRAILS

Do not overbuild any of this before the first expedition slice is playable.

For V1, we need only enough to prove:

1. Larry is memorable.
2. The Field Shop supports weapon acquisition/commitment.
3. The shop does not break expedition pacing.
4. Short dialogue adds personality without slowing play.
5. Players want to see Larry again.

Do not build yet:

- Larry questline
- Larry faction
- deep backstory system
- dozens of shop item types
- permanent shop leveling
- branching dialogue trees
- full voice acting system
- dynamic narrator AI
- complex merchant travel simulation

If players love Larry, earn the right to add more Larry later.
