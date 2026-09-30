# Actor Grounding V1 runtime contract

Actor Grounding V1 is a presentation-only candidate for the next production
phone review. It does not change actor roots, velocity, collision, hit/contact
radii, AI, weapon behavior, damage, spawning, or Phase A combat pressure.

## Runtime presentation

- Player contact shadow: 36 x 13 px, alpha 0.60.
- Player cast shadow: 26 px wide, alpha 0.26, approximately 70 px in Frozen
  Coast and 52 px in Township.
- Region sun angles: -51.6 degrees Frozen Coast and -38.5 degrees Township.
- Team ring: 42 x 15 px, 1.5 px wide, alpha 0.40.
- Actor body and held-weapon tint: `(0.88, 0.91, 0.96)`.
- Scarf tint multiplier: `(0.95, 0.96, 0.99)` over the player identity colour.
- Placeholder enemy body anchor: local y `-21`, with existing bob added on top.
- Waddle cycle distance: 108 px. Movement speed remains 220 px/s.

Move, dash, and hit frames use the locked sway/lift response tables. Dash,
downed, revive, enemy bob, Tuskbull charge, and Tuskbull crash scale or fade the
same shared contact/cast textures. Player acceleration lean, travel lean, start
squash, stop settle, and turn squeeze apply only to `CharacterVisual._pivot` and
compose with Township slide/elevation presentation.

Phase A weapons use the front-flipper anchor `(11 * facing, -11)`, occupied-slot
fan spacing of 7 px, per-weapon hold distances of 8-9 px, and supplied grip
offsets. Rack slots, firing-phase stagger, controller timing, thrust, damage,
and HUD order remain unchanged. No weapon z-index override is used.

## Snow effects and mobile budget

One `GroundingEffectPool` under the active actor layer preallocates eight
`Sprite2D` nodes. Footfall/turn/stop/landing kicks, dash puffs, and Tuskbull
effects reuse those nodes. A ninth concurrent request is dropped. No particles,
shaders, dynamic lights, or per-frame node allocation are used.

The source textures use linear filtering at runtime, lossless texture import,
and no mipmaps. Their locked SHA-256 hashes are:

- `ag_shadow_contact.png`: `A1A8D851DC9CE6B3984E567C4FCF02050C7BEF875D94474051A5D9185165C7BE`
- `ag_shadow_cast.png`: `74834D3517C06A401A906DFC746AE3EF8F5695D165E81C3B561B3A2926955A34`
- `ag_snow_kick_6f.png`: `80DE195DC08C6A6B8FC48D089FFEF083DB7D63CD7B20831321D9F9049E0FAEEF`
- `ag_snow_puff_dash_8f.png`: `B9C54CAA41591FBF1E083A029217128D791DE650F88B3F490902C4FAB747FC87`

## Phone tuning authority

The production Android build remains authoritative for cast strength/length,
ambient-tint strength, movement weight, and snow density. Tune these values only
after that phone review; the current values deliberately match the supplied V1
runtime parameter package.
