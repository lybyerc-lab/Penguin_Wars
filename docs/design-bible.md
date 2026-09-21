# Penguin Wars — Design Bible

## High-level identity

**Think Brotato meets Zelda, but built around a ridiculous little penguin civilization fighting a very serious war.**

The game should be fast enough for repeated runs, handcrafted enough to feel like a place, and readable enough for 1–4 player local co-op.

## Core loop

Target run structure:

```
CHARACTER
→ STARTING WEAPON
→ REGION / CAVE
→ STORM LEVEL
→ 20-WAVE EXPEDITION
→ BOSS
→ WIN / ENDLESS
```

The 20-wave run should not mean twenty unrelated rooms. The intended hybrid is:

- waves happen in clusters inside handcrafted Zelda-like spaces,
- the party physically travels between rooms/chambers,
- branch choices and traversal provide exploration,
- Brotato-like upgrades/shop/economy carry continuously through the run.

Working chapter rhythm:

- Cave entrance: waves 1–3
- First branch: waves 4–6
- Deeper cave: waves 7–10
- Second branch: waves 11–14
- Dangerous depths: waves 15–19
- Final boss: wave 20

Exact chapter boundaries can change, but the principle is stable:

> Brotato’s run engine traveling through a Zelda dungeon.

## Run systems

### Wave count and pacing

Target standard run: **20 waves**.

Rough timing inspiration:

- Wave 1: ~20 s
- Wave 2: ~25 s
- Wave 3: ~30 s
- Wave 4: ~35 s
- Wave 5: ~40 s
- Wave 6: ~45 s
- Wave 7: ~50 s
- Wave 8: ~55 s
- Waves 9–19: ~60 s
- Wave 20 boss: ~90 s

This implies roughly 17–18 minutes of combat, comfortably sub-30 minutes including choices, travel and shopping.

### Personal build ownership

Each player owns:

- weapons
- stats
- XP/levels
- personal Snow
- shop choices
- build decisions

The party owns:

- current adventure
- room/cave progress
- world traversal
- boss state
- route decisions

### Weapons

Target ordinary character capacity: **6 weapon slots**.

Planned weapon-tier loop:

- Tier I
- Tier II
- Tier III
- Tier IV

Duplicate combining:

- I + I → II
- II + II → III
- III + III → IV

Do not implement weapon slots as one giant special-case array bolted onto Player. Use the existing CharacterDefinition starting-weapons seam and a dedicated inventory/rack runtime when this phase begins.

### Weapon classes

Planned overlapping tags/classes:

- Fish
- Blade
- Harpoon
- Snow
- Ice
- Heavy
- Precision
- Engineering
- Support
- Royal
- Swift
- Explosive

Examples:

- Frozen Mackerel = Fish / Ice
- Harpoon Gun = Harpoon / Ranged
- Royal Ice Lance = Royal / Precision
- Bomb Fish = Fish / Explosive
- Wrench = Engineering / Heavy

Owned classes should eventually influence shop weighting and/or set bonuses.

### Field Shop

Between-wave run shop, distinct from Township.

Target:

- 4 personal offers after a wave
- buy
- reroll
- lock
- combine
- recycle/sell later if useful
- prices and reroll cost escalate
- owned weapon classes influence weights
- players ready independently, party advances when all required players are ready

This is the primary paid run-power shop.

### Level-up choices

Target:

- 4 choices per level
- stat/upgrade rarity tiers
- personal choice
- no shared forced upgrade

### Snow economy

World resource name: **Snow**.

HUD may continue to use a snowflake symbol.

Preferred world presentation:

- small irregular snow blob = 1
- chunky clump = 5
- big snowball/lump = 10+
- ridiculous oversized lump = jackpot

Feel target:

- squash on landing
- bounce
- wobble/roll
- magnet pull
- satisfying splat/pop collection

World art should be blobs/chunks, not literal floating snowflake icons.

### Harvest

Planned long-term behavior should be closer to a Brotato-like compounding wave economy than the current multiplier prototype.

Concept:

- Harvest pays Snow and/or XP at wave end
- grows by a small percentage each wave (~5% was discussed)
- creates economy builds
- interacts with Hoarder/BurrowFoot-style characters

Final arithmetic is not yet locked.

### Luck

Eventually affects some combination of:

- rarity
- drops
- shop offers
- upgrade quality
- special event outcomes

### Trees / neutral nodes

Potential snowy equivalent of Brotato trees:

- breakable neutral resource/heal/crate nodes
- readable environmental targets
- not required every room

### Special waves / events

Possible encounter modifiers:

- seal stampede
- snowball ambush
- ice collapse
- elite walrus
- puffin raiders
- crab swarm
- blizzard
- protect the egg
- golden fish chase
- mini-boss

## Difficulty: Storm Levels

Storm is the intended danger ladder, roughly analogous to a structural difficulty mode rather than pure stat inflation.

Target: Storm 0–5+.

Examples:

- Storm 0: normal
- Storm 1: new enemy variants
- Storm 2: elite/horde events
- Storm 3: stronger pressure/combinations
- Storm 4: more special encounters/hazards
- Storm 5: boss mutation / dual-boss possibilities
- later: Whiteout / post-game tiers

Storm should change the *shape* of runs.

Endless numerical scaling belongs to RunModifiers, not BossSchedule.

## World structure

Potential region progression:

1. Penguin Village / Kelphollow
2. Frozen Coast
3. Ice Caverns / Wrecked Harbor
4. Ancient Temple / Glacier Pass
5. Enemy Fortress

Each substantial region should contain:

- combat
- miniboss
- secret
- traversal puzzle
- major item/tool
- boss
- shortcut or meaningful route unlock

Potential factions:

- Penguin Kingdom
- Seal Empire
- Walrus Clans
- Puffin Pirates
- Crab Legion
- Polar Cult
- Orca Navy

## Traversal tools

Adventure tools should serve both exploration and combat when possible.

Ideas:

- Ice Pick
- Flipper Dash
- Bomb Fish
- Snowball Cannon
- Hookfish
- Fire Pepper

They should unlock previously visible passages and create Zelda-like “I remember that blocked place” moments.

## Room/doorway language

Current intended visual grammar:

- Left/right openings: common progression and branch choices
- Top opening: deeper/important route often reads naturally
- Bottom opening: return/backtrack often reads naturally
- Special-looking blocked doors: tool gates, secrets, boss locks

Not an absolute law, but consistent enough that players learn the space.

Future room transitions:

- short directional camera slide/wipe
- old room gives way to new room
- no second simultaneous world authority required
- orientation comes from RoomExit.Side

## Township

Township is a **physical pre-run/meta hub**, not the between-wave shop.

Target layout, compact and one-screen-ish:

- North: Expedition Gate
- West: Armory
- East: Fish Market
- Center: Plaza / Quick Start / expedition bell
- Southwest: Training Yard
- Southeast: Town Hall
- South: Lodge / Docks

Target veteran loop:

> die → town → bell → new run in about 10 seconds

### Township services

#### Town Hall

- character/challenge archive
- unlock conditions
- run-history flavor
- challenge unlocks
- no permanent raw-stat inflation

#### Armory

- choose starting weapon
- inspect weapon tags/classes
- locked weapons behind glass
- teach merge/class language

#### Expedition Gate

- choose region
- choose Storm
- choose mode
- party readiness
- later endless toggle

#### Training Yard

- dummies
- moving targets
- damage counter
- optional enemy toggles
- no farming

#### Fish Market

- collection/codex
- item display
- inspect tags
- cosmetics later

#### Lodge / Docks

- join/leave
- controller assignment
- scarf cosmetics
- character shortcut

### Township vs current prototype

Current Fisher/Nurse/Blacksmith paid run-power services are transitional prototypes.

Do **not** expand them into permanent Township run shopping.

Long-term split:

- Township = setup/meta/codex/unlocks/training/cosmetics
- Field Shop = paid between-wave run power

Free level-up choices already earned during a run may remain spendable in town if needed so choices are not stranded.

## Characters

Design rule:

> Characters change rules, not just numbers.

Reserved/planned names should not become resources until they have real gameplay identity.

### Squish Squish

Tagline: **“Tiny, but fierce.”**

Identity:

- smallest penguin
- fast
- agile
- clumsy

Ideas:

- high move speed
- dodge
- attack speed
- lower HP
- more knockback taken
- smaller explicit hitbox
- “Oops!” high-speed tumble that can become a useful involuntary maneuver

Potential weapons:

- Tiny Ice Knife
- Frozen Mackerel
- Needle Spear
- Comically Large Hammer later

### BurrowFoot

Cozy survival/economy/homebody character.

Ideas:

- stronger food/healing
- excess healing → Full Belly effect
- stationary armor/regen
- snow castle nearby counts as “Home”
- extra consumable capacity
- Harvest/economy lean

Possible visual: cottage-loving practical penguin.

Potential weapons:

- walking stick
- frying pan
- turnip

### Big-un

Slightly overweight engineering/tech nerd.

Tagline: **“I can optimize that.”**

Ideas:

- Engineering
- structure attack speed
- pickup utility
- Luck
- slower movement
- weak melee
- Overclock ability/effect

Potential weapons:

- Wrench
- Ice Nail Gun
- Snowball Drone
- Arc Welder
- ridiculous Laptop buff weapon

Barks:
- “It’s within tolerance.”
- “It’s on fire.”
- “Briefly.”

### Caveman

Simple name intentionally.

Tagline: **“Bonk good.”**

Identity:

- slow-talking
- extremely tough
- heavy melee

Ideas:

- huge HP
- armor
- knockback resistance
- Heavy class
- low move/attack speed
- weak ranged/engineering
- “Too Tough to Notice”
- “Bonk” stagger bonus with boss-stunlock protection

Potential weapons:

- Big Stick
- Stone Fish
- Ice Club
- Mammoth Bone

Rare hidden-intelligence gag is welcome.

### Snowquatch

Penguin cryptid.

Tagline: **“Probably real.”**

Identity:

- huge shaggy silhouette
- long flippers
- snow-covered
- town unsure whether it exists

Ideas:

- high HP
- strong melee
- strong pickup
- Harvest from destructibles
- slower attacks
- low Dodge
- large explicit hitbox
- “Cryptid”: reduced targeting after not attacking
- footprints that slow enemies

Potential weapons:

- Pine Log
- Boulder
- Frozen Stump
- Bare Flippers

Town gag:
- sightings: many
- confirmed sightings: zero

### Other character archetypes

Possible wider roster:

- Emperor: ally buffs, lower personal damage
- Rockhopper: speed/dodge, weak armor
- Fisher: Fish/Harpoon weighting, economy
- Engineer: structures strong, normal weapons weaker
- One-Flipper: one weapon slot, enormous scaling
- Chick: weak start, unusual level scaling
- Hoarder: gains power from unspent Snow
- Knight: Heavy/Blade/armor with speed penalty
- Snowmage: elemental specialist, weak physical
- Pacifist: survival/CC
- Builder: castles/turrets
- Pirate: treasure upside, harder/more enemies

## Humor and tone

Target tone:

**dry confidence + petty penguin attitude + absurd civilization treated completely seriously.**

Rules:

1. Civilization is serious to the penguins.
2. Understatement beats yelling.
3. Physical comedy should emerge naturally.
4. Never explain the joke.
5. Keep sass brief.
6. Readability comes before comedy.
7. Rare/contextual barks reward repetition.
8. Death/downing is not grim.

Useful comedy domains:

- government
- military bureaucracy
- blacksmithing
- fish regulation
- town meetings
- rivalries
- legendary nonsense
- physical waddles/slides/splats

Example flavor:

- Blacksmith: “Fine weapon.” / “Terrible lunch.”
- Can’t afford: “That’s not enough Snow.” / “I counted twice because you looked hopeful.”
- Town Hall sign: “No sliding indoors. This means you, Rockhoppers.”
- Notice: “Fish theft remains theft even when the fish ‘looked lonely.’”
- Fisher: “That’s a perfectly good fish. Why did you put explosives in it?”
- Engineer: “It worked. That makes it engineering.”
- Knight: “FOR KELPHOLLOW!” … “and fish.”
- Snowmage: “I command the ancient forces of winter.” / “You made a snowball.”
- Chick: “I require violence.”
- Downed callout: “Dave has become horizontal.”
- Revive prompt: **ROUSE PENGUIN**
- Revive bark: “I was resting.”
- Boss reaction: “That’s a large seal.” / “Excellent observation.”

Item flavor ideas:

- Frozen Mackerel: “It was a weapon before anyone admitted it was a weapon.”
- Royal Helmet: “Officially protects the crown. Mostly protects whatever is under it.”
- Emergency Herring: “Break glass in case of seals.”
- Questionable Scarf: “Aerodynamic according to the penguin selling it.”
- Snowman’s Revenge: “They remember.”
- Luxury Fish: “Absolutely not worth it. Which is why you need one.”
- Tiny Crown: “Leadership sold separately.”

## Visual tone

Target:

- readable top-down/slightly angled 2.5D
- storybook/cartoon winter world
- chunky forms
- strong silhouettes
- clean combat readability
- whimsical details without visual noise

The game should increasingly look authored rather than procedural-debug.

Presentation target sentence:

> Brotato-tight mechanically, compact-Zelda structurally, storybook winter visually, and populated by organized judgmental little birds fighting a ridiculous war.
