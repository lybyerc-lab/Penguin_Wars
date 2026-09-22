# Boss milestones and campaign ending

The current default is a boss phase **after the normal three waves** on milestone caves. It must be defeated before the cave-clear banner or exits unlock. The boss replaces the lesser milestone at 10/20; three bosses are not stacked in cave 20.

| Cave | Boss | Attacks | Solo HP | Base damage | Personal reward |
| --- | --- | --- | --- | --- | --- |
| 5 and 15 | Frostbreaker, mini-boss | Locked charge lane, rush, recovery | 500 | 16 | 15 flakes/XP |
| 10 | Glacier Warden | Alternating charges and eight-direction snowball volleys | 1,100 | 22 | 30 flakes/XP |
| 20 | Mondo, the War King | Charge, volley and radius slam; enrages below half HP | 2,400 | 28 | 60 flakes/XP |

Mondo's enrage shortens warnings from 1.1 to 0.8 seconds, increases rush speed from 340 to 430, fires 12 rather than 8 snowballs, and shortens recovery. Warning shapes lock the charge direction and show volley lanes or the slam radius before damage. Contact damage only occurs during rushes; dash immunity and player armor/dodge still apply. Bosses resist knockback and cannot be indefinitely interrupted by the cleaver. Boss HP scales by `1 + 0.65 * (party_size - 1)`; outgoing damage does not multiply merely because more players joined. These are first-pass tuning values requiring human balance testing.

Final-wave income is paid before the boss phase, once. Boss death grants the listed personal income to living players, scaled by Harvest, plus the existing ordinary enemy drop. Victory or a party wipe clears enemy projectiles. Boss fights keep the ordinary defeat rules; a wipe does not unlock travel or the campaign ending.

## Cave 20 decision

After defeating Mondo, choose:

- **End the war:** return to peaceful town, show the victory ending, and close the expedition. Builds and wallet remain visible there. Start a new expedition (or Restart) resets the run.
- **Endless caves:** retain the run and enter cave 21. Repeat the full milestone cycle: mini-bosses at 25/35, Warden at 30, Mondo at 40, and so on. The ending choice is offered at the first cave 20 completion only; later Mondo wins use normal cave exits.

The normal Next cave and Back to town routes cannot bypass the cave-20 choice. Endless enemy HP and contact/projectile damage increase by +35% of base per completed 20-cave block: 1.35x at caves 21–40, 1.70x at 41–60, etc. Boss HP also gets the party multiplier. Ordinary enemy counts retain their existing +20 cap to avoid unbounded crowd sizes on mobile. Current caves reuse the arena; no campaign save or permanent unlock is written.

## Extension points

`BossSchedule` determines milestone precedence and endless scaling. The three `BossDefinition` Resources hold names, health, damage, visual size, color, rank and rewards. `ArenaBoss` configures the shared enemy actor; `BossBehavior` implements attack state, and `BossHUD` presents its health independently. `EncounterDirector.State.BOSS` gates completion; `CaveJourney` validates the campaign decision and protects transitions from repeat requests. Replace the initial crown/seal visuals with dedicated boss art without changing fight authority. Online sessions will need host-owned damage, boss state and campaign choices.
