# Mario Wiki deep dive → Pipe Hop gap plan

**Source of truth (evidence only):** [Super Mario Bros. (Mario Wiki)](https://www.mariowiki.com/Super_Mario_Bros.) plus category pages and 29 linked enemy/item/object articles (fetched 2026-10-10).

**Hard rule:** match **mechanics and structure**. Do **not** copy Nintendo names, sprites, music, maps, or trade dress. Every gap below maps to a **Pipe Hop** original name.

**scrapling:** not installed in this environment. Deep dive used Mario Wiki HTML fetches (main article + Category:SMB enemies/items/objects + entity pages).

---

## 1. Wiki inventory (what SMB1 actually has)

### Enemies (15 wiki pages)

| SMB wiki | Behavior summary | Pipe Hop today |
| --- | --- | --- |
| Little Goomba | Walk, walk off ledges, any attack KOs, 100 pts | **Browncap** (yes) |
| Koopa Troopa (green) | Shell → kick; walks off ledges | **Shellbug** (yes; ledge AI incomplete) |
| Koopa Troopa (red) | Turns at ledge edges | **Missing** (red ledge-turn) |
| Koopa Paratroopa (green) | Bounce / path fly; stomp → Troopa | **Winged Shellbug** (partial hop only) |
| Koopa Paratroopa (red) | Vertical fly path; stomp → green Troopa | **Missing** |
| Buzzy Beetle | Shell like Troopa; **fireproof**; Hard Mode Goomba swap | **Skipped** (features.csv) |
| Hammer Brother | Pairs, hop blocks, throw hammers; chase after 100 timer units | **Skipped** |
| Spiny | Stomp hurts; block-bump immune; fire OK | **Missing** |
| Spiny egg | Lakitu projectile; hatches on land | **Missing** |
| Lakitu | Follows x, throws eggs; respawns; stops at flag | **CloudDropper** (spike drop; not Spiny hatch / respawn) |
| Piranha Plant | Pipe cycle; no emerge if player on/near pipe; stomp hurts | **HazardPlant** (partial; proximity rule weak) |
| Cheep-cheep (red/gray) | Swim; no stomp in water; some leap on land bridges | **Missing** (water uses Browncap/Shellbug) |
| Bullet Bill | Straight shot; fireproof | **Missing** |
| Blooper / Bloober | Erratic underwater chase; fire only | **Missing** |
| Podoboo / Lava Bubble | Vertical lava jump | **Missing** (lava pit exists) |

### Obstacles

| SMB | Pipe Hop |
| --- | --- |
| Pit | Yes (shortened 20%) |
| Fire-Bar | **FireBar** yes |
| Koopa fire (boss flame) | **Missing** |
| Lava (aesthetic pit in SMB1) | **LavaHazard** (lethal; stricter than SMB1 lore) |
| Turtle Cannon / Bill Blaster | **Missing** |

### Bosses

| SMB | Pipe Hop |
| --- | --- |
| Fake Bowser W1-7 (flame early, hammers W6-7) | **Duke Spikes** impostor; **no flame/hammer patterns** |
| Real Bowser W8 (flame + hammers) | Final Duke; ember hits / axe only |
| 5 fireballs → 5000 + reveal | Ember hit count yes; **reveal minion VFX weak** |
| Retainer / princess end copy | Original text only (correct IP) |

### Items / power-ups

| SMB | Pipe Hop |
| --- | --- |
| Coin (200; 100 → 1-up) | Yes |
| Super Mushroom ground glide | **Big Berry** (glide pass 0.3.2) |
| Fire Flower | **Ember Bloom** |
| Starman bounce 10s | **Spark Star** |
| 1-Up mushroom | **OneUpBerry** |
| Multi-coin ? block | **Missing** |
| Only one world item at a time | Yes (`_active_world_item`) |
| Fire Flower if already Super when bumping mushroom block | **Partial** (block contents fixed at author time) |
| Shell kick combo / bulldozer scoring | **Partial** (kick exists; combo points weak) |

### Objects / traversal

| SMB | Pipe Hop |
| --- | --- |
| ? / brick / hidden / empty | Mostly yes |
| Multi-coin brick | **Missing** |
| Pipe + warp pipe | Yes |
| Flagpole height score + slide | Yes |
| Ax + bridge collapse | Yes |
| Beanstalk / vine → sky bonus | **Skipped** |
| Jumping board (timed high bounce) | **SpringBoard** (single boost; no hold-for-max) |
| Lift / balance lift / falling lift | **MovingPlatform** only |
| Mushroom platforms / islands | Visual/solid stairs only |
| Coral / underwater current | **Missing** |
| Fireworks on flag (timer digit 1/3/6) | **Missing** |
| Stairblocks | Yes (solid stacks) |

### Meta / systems

| SMB | Pipe Hop |
| --- | --- |
| 8×4 worlds, typed stages | Yes (procedural W3-8) |
| Night / snow palettes W3/5/6/7 | Partial sky tint |
| Hard Mode (beetles, faster, short lifts) | Faster foes only |
| Continue world after Game Over | Yes (C) |
| Mid-level invisible checkpoints | **Removed by request** (always stage start) |
| Time 400 @ ~2.5×; hurry <100 | Yes |
| Crouch (tall only) | **Missing** |
| Enter pipe with ↓ | Yes |
| 2P alternate Luigi | Out of scope |
| Official BGM/SFX catalog | Original chiptune only (correct) |

### Soundtrack roles (behavior, not Nintendo audio)

| Cue | Pipe Hop |
| --- | --- |
| Ground / under / water / castle loops | Theme stubs yes |
| Invincibility BGM | **Missing** (star uses same SFX) |
| Player Down / Course Clear jingles | Clear tone only |
| Pipe / power-down shared SFX | **Missing** distinct cues |

---

## 2. Priority plan (implementation order)

### Phase A: Combat parity (highest play impact)

1. **Red Shellbug**: turn at ledge edges (not walk off).
2. **Vertical winged Shellbug**: up/down path; stomp → ground Shellbug.
3. **Piranha proximity**: do not emerge if Cap is on/beside pipe.
4. **Shell combo scoring**: escalating points while one shell slides.
5. **Fireproof Beetle** (was skipped) ,  shell enemy immune to EmberShot; Hard Quest swaps Browncaps → Beetles.
6. **Hammer Pair** (was skipped) ,  two throwers on block rows; optional chase after long on-screen time.
7. **Spiny + egg + refined CloudDropper**: stomp-hurts crawler; CloudDropper throws eggs that hatch.
8. **Bill + Cannon**: straight projectile; fireproof; cannon silent if Cap adjacent.
9. **Water fauna**: Swimfin (Cheep) + Inkjet (Blooper); land bridge leapers optional.
10. **Lava Hopper (Podoboo)**: vertical jump from lava.

### Phase B: Power-ups / blocks

1. **Multi-coin block**: rapid bumps yield N coins then empty.
2. **Smart mushroom block**: if Cap already tall/fire, spawn Ember Bloom instead of Big Berry.
3. **Spring hold-for-max**: higher bounce if jump pressed at compression.
4. **Star invincibility theme**: swap Music to `star` loop for duration.
5. **Power-down / pipe SFX** distinct from hurt.

### Phase C: Traversal / castle feel

1. **Duke flame** (W1-5) and **Duke hammer** (W6-7); **both** on W8 final.
2. **Balance lifts** and **falling lifts**.
3. **Underwater current** in pits (pull down).
4. **Flag fireworks**: if timer ones digit is 1/3/6, N fireworks × 500 pts.
5. **Crouch** while tall (pass short gaps).
6. **Vine / beanstalk** optional sky bonus (replace skip if desired).

### Phase D: Content / presentation

1. Hand-author **W3-W8** landmark beats (less pure procedural).
2. Night / snow / castle-approach backgrounds per wiki world aesthetics.
3. Hard Quest: Beetle swap + shorter lifts + enemy speed (already partial).
4. Retainer / end screens with **original** copy (no Nintendo lines).
5. SFX pack: jump, stomp, bump, coin, power, pipe, down, clear, hurry (original waveforms).

### Phase E: Explicitly never from the wiki

- Nintendo character/product names in UI or store listing  
- Official sprites, logos, level art, soundtrack files  
- Byte-identical maps or ROM/binary  
- Minus World / over-flagpole glitches (optional fun later, not “parity”)  
- 2-player alternating mode (unless you reopen that slice)

---

## 3. Suggested Pipe Hop names (clean-room)

| Role | Name |
| --- | --- |
| Red ledge shell | **Cliffbug** |
| Vertical flyer | **Hoverbug** |
| Fireproof shell | **Ashbug** |
| Hammer pair | **Toss Twins** |
| Spiky crawler | **Needler** |
| Egg | **Needler Egg** |
| Cannon shot | **Pipe Shot** / cannon **Iron Snout** |
| Water fish | **Swimfin** |
| Squid | **Inkjet** |
| Lava jump | **Ember Blob** |
| Boss flame | **Duke Flame** |
| Boss hammer | **Duke Toss** |
| Vine | **Sky Stem** |
| Multi-coin | **Coin Crate** |

---

## 4. Tracking

| Artifact | Action |
| --- | --- |
| `features.csv` | Add Phase A-C rows; flip prior `skip` for beetle/hammer/vine when started |
| `smb-mechanics.md` | Sync checkpoint note (stage-start only per product choice) |
| `test-plan.md` | New cases per shipped enemy / block |
| `bugs.md` | Log regressions while implementing |
| `parity.md` | Re-run after each phase |

---

## 5. Status (0.4.0)

| Phase A item | Status |
| --- | --- |
| 1 Cliffbug (ledge turn) | **Shipped** |
| 2 Hoverbug (vertical) | **Shipped** |
| 3 Piranha proximity | **Shipped** |
| 4 Shell combo scoring | **Shipped** |
| 5 Ashbug + Hard Quest swap | **Shipped** |
| 6 Toss Twins | **Shipped** |
| 7 Needler + egg via CloudDropper | **Shipped** |
| 8 Iron Snout + Pipe Shot | **Shipped** |
| 9 Swimfin + Inkjet | **Shipped** |
| 10 Ember Blob | **Shipped** |

W3-W8 use paced original layouts (teach → mid → climax → stairs → flag/axe) with these foes. Phase B (multi-coin, smart mushroom, star theme, SFX pack) is next.
