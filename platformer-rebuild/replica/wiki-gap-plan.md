# Mario Wiki deep dive → Pipe Hop parity plan (0.5.0)

**Source:** [Super Mario Bros. (Mario Wiki)](https://www.mariowiki.com/Super_Mario_Bros.) plus Category:SMB enemies / items / objects (scrapling + HTML fetch, 2026-10-10).

**Hard rule:** match **mechanics and structure** exactly. Do **not** copy Nintendo names, sprites, music, maps, or trade dress. Every SMB entity maps to a **Pipe Hop** original.

---

## 0. Full rename (replace old Pipe Hop cast)

Old placeholders are **retired**. New generated names + art:

| Role (wiki) | Old Pipe Hop | New Pipe Hop |
| --- | --- | --- |
| Player | Cap | **Cap** (kept) |
| Little Goomba | Browncap | **Mudbit** |
| Green Troopa | Shellbug | **Coilbug** |
| Red Troopa | Cliffbug | **Cliffbug** |
| Green Paratroopa | Winged Shellbug | **Hopcoil** |
| Red Paratroopa | Hoverbug | **Hoverbug** |
| Buzzy Beetle | Ashbug | **Ashbug** |
| Hammer Bro pair | Toss Twins | **Toss Twins** |
| Spiny / egg | Needler / Needler Egg | **Needler** / **Needler Egg** |
| Lakitu | CloudDropper | **Sky Rider** |
| Piranha Plant | HazardPlant | **Pipe Chomp** |
| Cheep-Cheep | Swimfin | **Swimfin** |
| Blooper | Inkjet | **Inkjet** |
| Bullet Bill / Cannon | Pipe Shot / Iron Snout | **Pipe Shot** / **Iron Snout** |
| Podoboo | Ember Blob | **Ember Blob** |
| Fake/Real Bowser | Duke Spikes | **Duke Spikes** |
| Super Mushroom | Big Berry | **Rise Melon** |
| Fire Flower | Ember Bloom | **Blaze Bud** |
| Starman | Spark Star | **Zap Star** |
| 1-Up Mushroom | OneUpBerry | **Extra Melon** |
| Fireball | EmberShot | **Ember Shot** |
| ? / brick / hidden | (same roles) | regenerated art |
| Flag / Axe | GoalFlag / AxeGoal | regenerated art |
| Spring / Lift | SpringBoard / MovingPlatform | **Hop Pad** / **Lift Plate** |
| Vine | (skipped) | **Sky Stem** (Phase C) |
| Multi-coin block | missing | **Coin Crate** |

Class names in GDScript may keep legacy identifiers for stability; **sprites, HUD copy, and docs** use the new names.

---

## 1. Wiki inventory vs status

### Enemies

| Wiki | Exact rule (must match) | Status |
| --- | --- | --- |
| Little Goomba | Walk off ledges; any attack KO; 100 pts | Mudbit |
| Green Troopa | Shell→kick; walks off ledges; 100 stomp | Coilbug |
| Red Troopa | Turn at ledge | Cliffbug |
| Green Para | Hop/path; stomp→Troopa; 400 | Hopcoil |
| Red Para | Vertical path; stomp→green Troopa; 400 | Hoverbug |
| Buzzy | Shell; fireproof; Hard Mode Goomba swap | Ashbug |
| Hammer Bro | Pairs; hop tiers; hammers; chase after 100 timer units; 1000 | Toss Twins |
| Spiny | Stomp hurts; block-bump immune; fire OK; 200 | Needler |
| Spiny egg | Hatch on land | Needler Egg |
| Lakitu | Follow X; eggs; respawn; stop at flag | Sky Rider |
| Piranha | Cycle; hide if Cap on/near pipe; stomp hurts; fire 200 | Pipe Chomp |
| Cheep (red/gray) | Swim; no water stomp; fire only; optional bridge leaps | Swimfin |
| Bullet Bill | Straight; fireproof; stomp 200 | Pipe Shot |
| Turtle Cannon | Silent if Cap adjacent | Iron Snout |
| Blooper | Erratic chase; fire only | Inkjet |
| Podoboo | Vertical lava leap; indestructible | Ember Blob |

### Items / power-ups

| Wiki rule | Status |
| --- | --- |
| Coin = 200 pts; 100 coins = 1-up | Yes |
| Only one world item on screen | Yes |
| Mushroom glides on ground, reverses on solid, falls in pits | Rise Melon |
| If already tall/fire, mushroom block yields flower | **Smart bump** |
| Small + flower → tall (not fire) | Must enforce |
| Star ~10s; does not replace form; bounce spawn | Zap Star |
| Multi-coin ? block | **Coin Crate** |
| Power-up touch = 1000 pts | Enforce |
| Shell bulldozer combo 100→200→400→800→1000→2000→4000→8000→1-up | Combo scoring |

### Objects / systems

| Wiki rule | Status |
| --- | --- |
| Stage types per world (W3-2 ground, W8-3 ground, etc.) | Catalog match |
| Crouch while tall | Implement |
| Flag height score + fireworks if timer ones digit 1/3/6 | Implement |
| Spring hold-for-max | Implement |
| Star invuln BGM | Implement |
| Distinct power-down / pipe SFX | Implement |
| Duke flame W1–5; hammers W6–7; both W8 | Implement |
| Hard Mode: beetles, faster, shorter lifts | Partial→complete |
| Vine / balance lift / current | Phase C leftover |
| Mid-level checkpoints | Product: always stage start |
| Nintendo IP / ROM / map bytes | Never |

### Exact world stage kinds (wiki)

| | -1 | -2 | -3 | -4 |
| --- | --- | --- | --- | --- |
| W1 | ground | under | athletic | castle |
| W2 | ground | water | athletic | castle |
| W3 | ground | ground | athletic | castle |
| W4 | ground | under | athletic | castle |
| W5 | ground | ground | athletic | castle |
| W6 | ground | ground | athletic | castle |
| W7 | ground | water | athletic | castle |
| W8 | ground | ground | ground | castle |

---

## 2. Build order (this pass = 0.5.0)

1. Regenerate all art + apply new names in docs/UI.
2. Lock wiki stage kinds + **bigger, denser original maps**.
3. Ship missing rules: smart flower, multi-coin, crouch, fireworks, spring hold, star theme, Duke flame/hammers, shell wake, Sky Rider follow/respawn, power-down SFX, grow 1000 pts, small+flower→tall.
4. Phase C leftovers: Sky Stem, scale/falling lifts, underwater current, night/snow polish.

---

## 3. Explicitly never from the wiki

- Nintendo character/product names in UI or store listing
- Official sprites, logos, level art, soundtrack files
- Byte-identical maps or ROM/binary
- Minus World / over-flagpole glitches (optional later)
- 2-player alternating mode
