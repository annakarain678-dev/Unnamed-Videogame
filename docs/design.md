# Lenhavu — Game Design Document

> Working title: *Unnamed Videogame*. This is the game's rulebook. It records what is **decided**, what is a **suggestion** waiting for a yes, and what is still **open**. Update it whenever a decision is made.

Status legend: ✅ Decided · 💡 Suggested (not yet confirmed) · ❓ Open question

---

## 1. The pitch

A 3D open-world exploration and puzzle game set in **Lenhavu**, a world God created with four sentient species. You play a **wisp**, a speck of light whose home is a star. You can slip into statues and bring them to life as members of Lenhavu's species. You journey across the world chapter by chapter, through disasters, toward the stronghold of the darkling king.

Puzzles are solved mostly by **knowledge**: what you've seen, who you've talked to, and what you've learned. A player who already knows the answers can get through a chapter on the first try.

### Inspirations (for feel only, not to copy)
- **Outer Wilds:** time loops, knowledge as progress, the ship's log, art feel
- **Pathless:** open-world regions that unlock as you progress
- **Detroit: Become Human:** branching choices with a flowchart of outcomes, but done more fairly
- **Horizon Zero Dawn:** combat is available, never mandatory
- **Minecraft:** the health and hunger model

---

## 2. Design pillars

1. **Knowledge is progress.** ✅ Every gate inside a chapter can be passed on the first loop if you know how.
2. **Choices have consequences.** ✅ Rescues, theft, reputation and allies carry forward and shape the ending.
3. **Every form matters.** ✅ Each species opens paths and closes others. No form is simply "best".
4. **A righteous path is always possible.** ✅ The game can be completed following the Ten Commandments, including **without killing anyone** and **without stealing**. It's hard, but always possible.
5. **Light against darkness.** ✅ The Christian worldview runs through the theme. Darkness is real, possession is real, and light drives it out.
6. **Never soft-lock the player.** ✅ Loops and chapter restarts mean the player can always recover.

---

## 3. World and story

### Lenhavu ✅
A world created by God, home to four sentient species: **Humans, Kash (Qoi-Kash and Sen-Kash), Tar'ye, and Fayrans.**

### The player: the wisp ✅
- A small light living in the spiritual realm, rare in the wild.
- Its home is a **star**.
- Can **see other wisps and darklings**.
- Can **drive darklings away**, including those possessing a host.
- Cannot carry items or touch the physical world.

### Motivation
- 💡 **Sent by God on a mission it doesn't fully understand.** You're sent to stop the darkling king. Along the way the wisp tries to understand *what it is*. The reveal of its nature is part of the ending.
- 💡 "Become king of the world" is a **temptation** the darklings offer, not the goal. It leads to the dictator ending.

### The enemy ✅
- **Darklings:** dark spirits visible only to the wisp. They can possess people and use them to bring about destruction. (Full details still to come.)
- **B'nuo Puxarorana** ✅ is **Satan**, the darkling king. The name is a Caesar cipher meaning **"self-glorifier"**: shift each letter forward 17 to decode, and back 17 to encode.
  - Note: decoded exactly, "Puxarorana" reads "glorifirer". A perfect "glorifier" would be "Puxarorna". Either can stand; it's a stylistic choice.
- ✅ **He possesses the king** who rules from the Dead Mudflats. The **king is a good king** underneath, whom the world sees as evil.
- ✅ A player who realizes this can leave their body as a wisp and drive B'nuo Puxarorana out. This is the **best ending**: the king is freed and **learns to be good again**.

### Why does time loop?
- ❓ Needs an in-world reason. 💡 One idea: when you die, your light returns to the star, which sends you out again at the start of the chapter. The loop may tie into the mystery of what the wisp is.

---

## 4. The species (playable forms)

| Form | Strengths | Limits | Notes |
|---|---|---|---|
| **Wisp** | Sees darklings and wisps, drives darklings off, floats freely | Can't touch the physical world, can't carry items | Your true form |
| **Human** | Best crafters and tool users; explosives and inventions; **understands and translates every species**; full market access | Physically average | The most neutral species; least resistance from others |
| **Sen-Kash** (half-snake) | Survives extreme heat; mathematical minds; metalworking; **soul-sight**; sees math and shape puzzles | Rare outside hot regions | Logical, not emotional; music matters only if mathematical. City builders in the desert; work with Humans; dislike the Tar'ye |
| **Qoi-Kash** (half-eel) | Deep caves, tight spaces, long swims, gills, longer survival in toxic air; **soul-sight**; sees math puzzles | **Cannot leave the caves or underwater areas**; dislikes light | Rare; found only deep underground or at sea cliffs |
| **Tar'ye** (cat people) | Strongest; claws and teeth; push heavy objects; climb trees and cliffs fast and far; high ground in fights; deals and takes more damage | **Some puzzles don't appear to them** (ones Humans and Kash can see); **eats only meat** | Walk on two legs or four; fight each other, rarely to the death |
| **Fayran** (winged) | **Flight** (costs hunger); fast; reaches high places | Weak fighters; **drowns in deep water**; flight ceiling (thin air); **very vulnerable to toxic air and smoke**; dislikes caves and underground | Angelic wings sprouting from the upper shoulders |

### Soul-sight (Kash) ✅
Kash can see how good or evil a person's soul is, and spot people likely to harm you.
- 💡 Shown as a **visible aura of light or shadow**, not a number. It echoes the wisp's ability to see darklings.
- ✅ Used in puzzles. Example: as a Kash you see that *Johnny the tax collector* is deeply evil. On another loop you follow him as a wisp and see darklings possessing him, steering him to cause the disaster. As a wisp you can drive them out and save the area.

### Species skills: the build list
Each skill gets built and tested **on its own**, in its own small spot on the test island, before they're combined into real puzzles. ✅ = prototyped.

**Any body**
- ✅ Walk, run (double-tap W), jump, swim
- ✅ **Stone weight:** a body you leave turns to heavy stone and stays put, so it can hold down a pressure plate (the hut puzzle)
- ✅ **Shattering:** an empty statue that falls more than ~10 m shatters when it lands (e.g. leaving a flying Fayran in mid-air). For now it simply reappears on its plinth; a breaking animation comes later.
- ✅ **Breath:** with your head underwater, a breath bar runs down (Human ~15 s, Sen-Kash ~15 s, Tar'ye ~12 s, Fayran ~8 s). Floating at the surface counts as breathing. Only the **Qoi-Kash** (gills) never run out.
- ✅ **Drowning:** run out of breath and you drown: you're thrown out as the wisp and the body returns to its plinth. (Later, dying in a body restarts the chapter's loop.)

**Wisp**
- ✅ Float, dash, comet tail; spirit view; sees darklings
- ✅ Shine (Left Mouse) to drive darklings off; draw light lines (Right Mouse) in a heart chase
- ✅ Weighs nothing (can't press plates); can't move things
- ⬜ Pass through some things that block bodies (which ones is still open)

**Human**
- ✅ Can't move boulders (struggles and gives up)
- ⬜ **Operate machines:** levers, cranks, winches, doors that only hands can work
- ⬜ **Read and translate:** signs and writing that look like scribbles to other species
- ⬜ **Tools and explosives:** blow open cracked walls, use rope, etc. (ties into the 3 inventory slots)
- ⬜ Full market access (later, with people)

**Tar'ye**
- ✅ **Shove boulders** (Right Mouse)
- ⬜ **Climb** trees and cliffs, fast and far
- ⬜ **Run on four legs:** faster, lower to the ground
- ⬜ Stronger in fights (later, with combat)
- ⬜ Weakness: **some puzzle markings are invisible** to them (ones Humans and Kash can see)
- ⬜ Weakness: eats only meat (later, with hunger)

**Fayran** (look: ✅ a Human with a pair of white feathered wings from the upper shoulders. ✅ **Two-jointed wings**, like a bird's (or a chicken's) wing bones: from the shoulder, the upper wing rises to a bend just above the head; from there, the long lower wing folds back down, **tapering, almost to the feet** (stopping just short of the ground). In flight both parts unfold out to the sides. ✅ **No tail feathers, on purpose.** Instead, a squarish panel of feathers on the **outer side** of each lower leg (clear of the ground): flat along the leg on the ground; in flight it spreads out to the side like an airplane's tail fin (or a kite), sweeping a little up the leg, to catch the wind and hold the legs up.)
- ✅ **Flight (Elytra-style):** **Space jumps; jump again in mid-air to take off.** After that, **steer entirely with the mouse**: you fly the way the camera points, up and down as well as left and right. Look down to dive and pick up speed; look up to climb, trading speed for height (climb too steeply and you slow, **stall** and sink).
  - **W beats the wings**: a push forward along wherever the camera points, whichever way that is (uses energy). Flap while looking up to climb; flap in a dive and you go down even faster (a near-certain crash).
  - **Space is not for flying**: it's only for jumping and taking off, plus a little lift right near the ground (about a meter) for hopping a gap or a step.
  - S brakes, **Shift tucks the wings** for a faster, steeper dive, A/D drift a little to the side. Every few seconds while gliding the wings give a quick double flap. You land when you touch the ground. (Walking stays as it is.)
- ✅ **Crashing** (any body, into anything: the ground, trees, walls) depends on **how hard you hit and which way the body is pointing**: **head first** breaks at a fairly low speed; **feet first** in between (about a 9 m drop: you'd break your legs, but landing feet first slows you); **side-on or flat**, like skidding along the ground, takes a really hard slam, and skimming the ground at a shallow angle barely loses speed, so you usually just skid and survive. A crash shatters the body: you're thrown out as the wisp and it returns to its plinth.
- ✅ **Flight pose:** nearly level, but not quite, more so the faster you fly; legs trailing straight behind, arms swept back; more upright when hovering. ✅ The **wings stay level with the ground** however far the body leans.
- ✅ **Turning like a bird:** in flight the body turns around **the point between the wings** (not the feet), swings round in wide curves, and **banks into the turn**: it rolls slightly, the inner wing dips and the outer one lifts, and the legs steer a little.
- ✅ **Flight energy is the main limit:** climbing tires you fast; it comes back fully on the ground. Shown as a bar. One full bar climbs ~75 m, enough to land on the giant trees. (Later this becomes hunger.)
- ✅ **Gliding low** (below ~40 m), energy slowly comes back (up to 80%, never full while airborne), so you can glide a long way. **Up in the thin air** it doesn't come back.
- ✅ The **world's height limit** is far up (~120 m above the sea), where the air is too thin to climb
- ✅ Weakness: **can't swim**: in deep water the wings soak through and you sink (and can drown), and you can't fly again until they dry (~4 s)
- ⬜ Weakness: **smoke and toxic air** hurt badly
- ⬜ Weakness: dislikes caves (can't, or won't, go into tight places)
- 💡 Maybe later: Kash steered by the mouse while swimming too (for now, only the Fayran in flight).
- 💡 Idea: in the **rainforest**, steady (and growing) rain keeps a Fayran's wings soaked, so it can't always fly there.

**Sen-Kash** (look: ✅ a human upper body on a long snake tail in jewel tones: emerald and gold bands with ruby accents, tan skin, a gold vest and collar, gold slit eyes. No gills.)
- ✅ **Slithers** instead of walking: the body draws a line and the tail follows it, pulled a little taut like a string (corners and loops tighten slightly), with an S-shaped wave running down it. It **always keeps its full length**, and goes around rocks the body went around rather than hopping over them. Jumps only a little, and **only the torso lifts**: the tail stays on the ground (and jumping on the spot never pulls it in).
- ✅ **Turns in arcs:** the head swings round at a limited rate, so turning around is a **U-turn** (the front curves back past the tail) rather than spinning on the spot. (Both Kash.)
- ✅ **Slithers up steep slopes and steps** that walkers have to jump (up to ~70°); the tail lies along the ground over steps and ledges, and drops quickly going downhill
- ✅ Swims (moderately). **At the surface, swims upright**, driven by the tail like slithering, with only the shoulders and head out of the water; stretches out flat only when diving. Swims the way the head points, curving round to turn (never sliding sideways). **In water, the tail behaves like a supple rope**: it keeps its full length whichever way you move (trailing below you as you rise, above you as you dive), bends in smooth curves rather than hinges, and at rest settles into a natural shape: **down from the hips first, continuing the line of the body, then curving back** to lie level behind (like a mermaid's tail), with a soft ripple, resting on the bottom only where it actually touches. An empty statue left in the water **sinks in one piece**, tail and all. (Both Kash.)
- ⬜ **Survives heat** that hurts everyone else
- ⬜ **Soul-sight:** sees an aura of light or shadow on people (and possessed things)
- ⬜ **Sees math and shape puzzles** others can't
- ⬜ Metalworking (later)

**Qoi-Kash** (look: ✅ eel-like: dark slate shark-like skin rather than scales, a dorsal fin from the back of the head down the back to the tip of the tail, gills on the sides of the torso, a sleeker head, pale eyes. A bit scary-looking, but not evil.)
- ✅ Slithers on land **exactly like the Sen-Kash** (same speed and movement); its tail is a little shorter
- ✅ **Gills: at home underwater**: fast swimmer, dives and rises quickly, stays at whatever depth you choose
- ⬜ **Fits tight crawlspaces**
- ⬜ **Survives toxic air** longer
- ⬜ Soul-sight and math puzzles (shared with Sen-Kash)
- ⬜ Weakness: **can't leave caves or water**; dislikes light. (For testing, it can still slither around on land.)

**Shared hazards** (needed for several weaknesses above, so they're built once)
- ⬜ **Health** (Minecraft-style, with hunger)
- ✅ **Breath** underwater (Qoi-Kash don't need it), and drowning
- ⬜ **Heat** zones (Sen-Kash are fine)
- ⬜ **Smoke and toxic air** (Fayran are hurt most; Qoi-Kash least)

💡 Suggested order from here: shared hazards (health, breath, heat, smoke) → Tar'ye climbing → Human machines and reading → Kash soul-sight and math puzzles → Qoi-Kash crawlspaces and cave-bound rule. Every species now has a statue on the test island's beach.

---

## 5. Statues and form-swapping ✅

- Statues are **found anywhere**, not only in groves. Reaching a statue can be a puzzle itself. For example, one form gets you into a cave, and a statue deep inside lets you take the form you need for the underwater section.
- Some places have **groves with every species available in that chapter**.
- You can **leave a body at any time** and return to wisp form.
- 💡 A body you leave **turns back to stone where it stands** (as built in the prototype). You can come back and enter it again. An empty statue doesn't swim; it sinks.
- ✅ Once a statue has come to rest, it **stays exactly where it is**: nothing (like a rolling boulder) can shove it, so you can always find it again.
- Qoi-Kash statues are rare: only deep underground or at water's edge.

### Wisp passing through things 💡
- The wisp is blocked by solid things for now, but **some things should let the wisp through** (for example spiritual barriers, gaps a body can't fit, or things only a spirit can pass). ❓ Which ones, and why?

### Items and inventory ✅
- Not an item-heavy game.
- Each body has **about 3 inventory slots**, switched with the **1/2/3 keys or the scroll wheel**.
- ✅ **Armor isn't carried in the inventory.** You get dressed and change armor at **inns** (and similar places), so what you wear into a fight is a real choice.
- Items **stay with the statue's body** when you leave it.
- You can **interact with a statue to pull its items**, so you don't have to refind the same items.

### Death ✅
- **If you're inside a body when it's destroyed, you die and the chapter restarts.**
- **If you've already left the body** and the statue is destroyed, you carry on as a wisp and find another statue.
- ❓ What can kill the wisp itself? 💡 Darklings catching you in wisp form.

---

## 6. Chapters, loops and consequences

### Chapter loops ✅
- Each chapter is its own region with **its own loop that ends in a disaster**.
- **Dying or the disaster restarts the chapter** from its starting state, which may be altered by earlier chapters.
- Some puzzles can only be solved at **certain moments in the loop**.
- 💡 Loop length: **about 20 minutes as the standard**, adjusted per chapter (roughly 12–25 minutes depending on size and number of NPCs).
- ✅ Each chapter is sealed so you can't escape the disaster easily. Example: in the wildfire chapter, **heavy smoke makes flying above the fire deadly** for Fayrans.

### Two levels of consequence ✅
- **Inside a loop:** reputation, rescues, robberies and relationships all count, but reset when the loop restarts.
- **When you leave a chapter:** whatever was true at that moment becomes **permanent for that save**. That includes who you saved, who joined you, your reputation, and whether you fled or saved the area.

### What carries forward ✅
To keep the branching manageable, each chapter's outcome is **mostly stats, not situations**. Later chapters read these values instead of needing unique content for every path:
- **Reputation:** how people *feel* about you (by species, by town, and overall), including flavors like "clumsy oaf"
- **Fame:** how *widely known* you are, separate from reputation. It rises when your deeds spread, e.g. by talking to a town crier, a messenger, or someone about to leave the area. Fame doesn't decide whether people like you, only how many have heard of you.
- **Areas saved vs. fled**
- **Lives taken** (for the no-kill path)
- **The king's attention:** driven mainly by **fame**. The more widely known you are, the sooner B'nuo Puxarorana notices you.
- **Thank-you notes:** when you save an area, you can hear people's gratitude as a spirit. These are collected in your journal.

**Plus a few specific situations** that carry forward as themselves, not as stats:
- **Companions and allies:** people rescued or befriended who join you or reappear later (e.g. a strong warrior who joins the final fight)
- Occasional key story moments, kept few on purpose

### Branching saves (the flowchart) ✅
- Each chapter ending becomes a **point on a flowchart**, viewable from the main menu.
- You can **jump back to any outcome you've already reached** and continue from there **without losing your other paths**. *Example:* you played as a thief (low reputation) and as a generous hero (99% reputation). Both remain on the flowchart, and you can continue either.
- A **new save** starts fresh.
- ✅ Better than Detroit: no replaying everything to explore one alternative.

### The journal ✅
- The wisp has no items, only **knowledge**. The journal is its memory, like the ship's log in Outer Wilds.
- **Organized by chapter.**
- Records places, people, clues and rumors.
- Shows hints like **"there's more to discover here"**.
- ✅ The journal belongs to the **player, not the save branch**. Knowledge carries across retries and branches, which is what makes "replay and beat it on the first try" possible.

### Revisiting chapters ❓
Can you physically return to a past disaster area in the world to help? Worry: too much freedom could bog the player down. 💡 Lean toward chapters locking once you leave, with replays done through the flowchart instead.

---

## 7. The chapters

| # | Region | Disaster | Species present | Notes |
|---|---|---|---|---|
| 1 | **Coastline and Forest of Giant Trees** | ✅ **Wildfire** | All four; Sen-Kash rare; Qoi-Kash rare (sea cliffs) | Starting area. The coast teaches swimming: Fayrans can't, Humans and Tar'ye can a little, Qoi-Kash can but dislike light. Smoke grounds Fayrans. Escape or rescue options: lead people to a **deep natural cave** or to the **ocean**. Introduces darklings and possession (Johnny). |
| 2 | **Deep Underground** | ✅ **Earthquake or cave-in** | Kash, Qoi-Kash, Human — **no Fayrans** | Reached through the deep cave. Leads by water into the cenote. |
| 3 | **Jungle and Cenote** | 💡 Storm or tsunami | All four, **mostly Tar'ye** | You swim up from the underground through a cenote into the jungle. Tougher enemies (evil wolves or dogs). |
| 4 | **Desert** | ✅ **Spreading fungal blight** | All four, **mostly Sen-Kash** | Reached through a cave tunnel or narrow valley pass. The blight starts on one side of the map and spreads; being inside it makes you weaker. The loop ends when it covers everything. Sen-Kash cities are sophisticated; they work with Humans and dislike Tar'ye. |
| 5 | **Volcanic Plains** | ✅ **Eruption** | Very few people | Hostile land with sparse settlements: fighting off dangers and evacuating. Future home of the dragon egg. |
| 6 | **Dead Mudflats** | ✅ **Siege timer** (no loop) | — | The darkling king's capital: endless dead mud, lava plains behind you, ❓ some boundary on the other sides (mountains? endlessness?). Little to explore; small puzzles give extra tools or weapons. The king sends stronger and stronger waves. Fighting lowers your standing with him. Surrendering early opens other outcomes. Fighting until you fall means capture, and possibly death. |

### The king's attention ✅
The king watches you. The greater your **fame**, the sooner his soldiers come for you. Become famous enough and you may be **pulled into the final confrontation early**, even a chapter or more ahead.
- ✅ The final chapter must handle skipped chapters: skipping means fewer allies and a harder fight.

---

## 8. Endings

✅ About **five endings**, with many paths to each. Good endings come from **understanding the world**, not luck or a perfect run.

| Ending | How (draft) |
|---|---|
| **Peace (best)** ✅ | Realize the king is possessed by B'nuo Puxarorana. Abandon your body in his presence (risking it), and as a wisp drive Satan out. The good king is freed and learns to be good again, and Lenhavu enters a time of peace. You don't take part in the world afterward. |
| **Dictator** | Accept the temptation of power and rule the world. |
| **Destruction** | The world is destroyed. |
| **Abandonment** | Leave the mission, start a family, and live a quiet life while everything falls because the evil was never defeated. |
| ❓ Fifth | To be decided. Possibly a bittersweet partial victory: defeating the king by force, killing a good man while Satan escapes. |

✅ The peace ending is set up in Chapter 1: following Johnny teaches, without saying so, that the wisp can free a possessed person.

---

## 9. Puzzle toolkit

Like Outer Wilds, many puzzles should come from a small set of tools used in different ways. In Lenhavu, most tools are **abilities**, not items.

| Puzzle type | What it means | Examples |
|---|---|---|
| **Spirit sight** (wisp only) | Some things exist only in the spirit realm | Darklings, hidden spirit trails, remains of past events |
| **Form-gated paths** | Only certain bodies can get there | Climbing (Tar'ye), flight (Fayran), deep caves, toxic air and long swims (Qoi-Kash), heat (Sen-Kash) |
| **Form-gated seeing** | Only certain bodies can see or understand it | Math and shape puzzles and soul auras (Kash); reading any language (Human); puzzles hidden from Tar'ye |
| **Statue logistics** | Getting the right body to the right place | Reaching a statue deep in a cave; 💡 a body left behind is **heavy stone** where it stands, so it can hold down a pressure plate or block something, then you go on as the wisp |
| **Time** | Things happen at set moments in the loop | Fire spreading, tides, Johnny's daily route, a door that only opens at dusk |
| **People** | Knowledge comes from following and talking to people | Following Johnny; driving darklings out of someone possessed |
| **Hazards** | The world can hurt you | Smoke, deep water, fire, toxic air, darkness |

### Spirit view ✅ (prototyped)
- Whenever you're the wisp, you see the **spirit realm**: it's always night there. Darker, navy-toned, flattened contrast, faded color, drifting dust. The wisp is the brightest thing around.
- ✅ The drifting dust is what sets spirit night apart from ordinary night.
- **Darklings are visible only in spirit view.** In a body, they're invisible.

### Day-night cycle ✅ (prototyped)
- Like Minecraft: the **sun crosses the sky by day and the moon by night**, with sunrise and sunset colors in between.
- Prototype timing: a **10-minute full day** (5 minutes of daylight from 6 am to 6 pm, 5 minutes of night). The real game's length is still open. ❓
- Time keeps running in spirit view; spirit view just looks the same at any hour.
- A clock shows the day and time (for testing, at least).
- ✅ At night: a **starry sky and a visible moon**, and the everyday world's colors get a little less vivid (but stay clearly different from spirit view's grey-navy).

### Spirit shrines ✅ (prototyped)
- Small glowing orbs only the wisp can take. Each one **grows the home star** a little. One sits inside the stone-weight puzzle's hut as a reward.

### The home star ✅ (prototyped)
- The spirit sky has **one star**: the wisp's home. In wisp form, **all the other stars disappear** and only this one remains.
- On ordinary nights it also shines among the other stars, so you can find it from a body too.
- It **grows a little with each chapter**, as the wisp learns and grows.
- ❓ Where it sits in the sky, and whether it moves when you go in and out of wisp form. (Aesthetic, not functional; decide later.)

### Possession ✅ (prototyped on a statue; meant for people)
- A darkling possessing someone **hides inside them**. In spirit view, the possessed one burns with **black fire**.
- To everyone else, they just look **darker and gloomier**: a clue even for bodies that can't see darklings. ❓ Undecided: this may be removed, so possession is invisible to bodies.
- In the full game this applies mainly to **people (NPCs)**, not statues.
- A possessed statue **can't be entered** until the darkling is driven out.

### Ending a possession: the heart chase ✅ (prototyped)
✅ Shine is fine for chasing darklings out of an area. **Some possessions take more.**

- When you shine a darkling out of a host, there's a chance it's **stubborn** and fights back. (✅ 100% for testing; ~30% planned, varying with the level's difficulty.)
- A stubborn darkling draws the wisp **into the host's heart**: a dark, foggy chamber of rough black stone with **a few gold grooves and gashes** (like gilded blackstone) that **pulse red** outward from the **heart at the center, burning with black fire**. A glowing **border ring** circles it.
- The darkling keeps trying to get back to the heart, and **swings around the wisp** if you're in its way. ✅ Its speed feels right: difficult, but not impossible. The chamber size feels right too.
- **Left Mouse (shine)** pushes it away, hardest up close (F also works). Inside a heart, shining doesn't slow the wisp. (Mouse buttons, so you can steer with WASD at the same time.)
- **Hold Right Mouse to draw a line of light** behind you, as if your comet tail were a brush. The darkling **can't cross** a line, **keeps its distance** from it (about 1.5 m), and slides along it looking for a way around. Let go to end a line; old lines stay until they fade.
- **Line length is limited** (12 m for now): draw past it and the oldest part fades away first, and each part fades on its own after ~10 seconds, so it's never overpowered.
- ✅ **No accidental soft-locks:** if your lines ever wall the darkling in completely, it **hops up and over** them after a moment, then settles back to its normal hover.
- 💡 **The line grows as the wisp grows**, e.g. with each darkling chased out, like a scarf that lengthens over a long journey.
- Drive it **past the border** and the heart is cleansed: the veins pulse **soft bluish-white**, the heart turns a **healthy beating red**, and you get about 4 seconds to watch the change. Then you come back out, **already inside the host**.
- **Tab gives up**: you're back outside, and the darkling keeps its hold.
- The chamber must be neutral enough to work for a statue or a person, but still interesting. Inside a heart, spirit view keeps its darkness but drops its grey-navy wash, so the reds and blues show true.
- 💡 Difficulty depends on the level: harder darklings are faster, dodge harder, or dash back toward the heart now and then. Keep the AI simple, so it's never too hard.

### More possession puzzle ideas ❓
💡 A shared rule that fits Outer Wilds-style knowledge puzzles: **every possession has a foothold**, the thing the darkling clings to. Shine can't drive it out until the foothold is found and dealt with. Discovering the foothold is the knowledge; dealing with it may need the right body. Foothold ideas:
- **An object:** a cursed trinket, stolen goods, a dark idol. Find it and remove, return or destroy it (e.g. a Tar'ye shoves a boulder off a buried idol; a Human uses explosives on a shrine).
- **A sin or a lie:** what the person is consumed by: greed, fear, pride, bitterness. Kash soul-sight reveals *what* it is; you find what would answer it. *Example:* Johnny the tax collector is held by greed; you find his hidden ledger (a Human can read it) and the people he cheated, and when he's faced with it and makes things right, the darkling loses its grip. (Echoes Zacchaeus.)
- **A place or darkness:** the darkling is strong in shadow. Bring the possessed into the light: sunrise in the loop, a lighthouse or bonfire, or pushing a possessed statue into the sun.
- **A time:** possession weakens at a certain moment in the loop (dawn, a bell, a festival), and that's the only window when shine works.
- **People who care:** someone who loves the possessed person (a rescued child, a mother) is brought to them; their presence and prayer weakens the hold. Ties into rescues and companions.
- **A source:** many darklings in an area draw strength from a dark shrine or totem in their territory. Cleanse the source first, then free the people.

### Territory and re-possession ✅
- Each darkling has a **territory** around its home.
- ✅ **Fear wears off:** when you shine on a darkling, it's afraid for a few seconds and keeps away from you, but it **stays (mostly) inside its territory**, sliding along the edge rather than leaving. Then it forgets its fear and carries on. It only runs again if you shine on it again. (prototyped)
- **Statues:** a darkling takes over any empty statue inside its territory, and comes back for it after being driven off, so you just chase it off again. A statue **outside** its territory is left alone; the darkling stays in its own area rather than chasing it. (✅ prototyped)
- **People:** a darkling can come back into a person **unless that person has been convinced to keep it out**. They don't really know what a darkling is (it's like a demon to them), but if you change the person (help them, persuade them, change their heart), the darkling can't return. If you don't, it will. (Not built yet; needs people and dialogue.)

### Shine ✅ (prototyped)
- As the wisp, **hold F to shine**: the wisp flares brighter and wider and moves slower.
- Darklings caught in the light recoil, then flee for a while (see Territory above).
- ✅ They **don't die**.
- Darklings ignore you unless you shine on them (for now).
- ❓ Does shining have a cost or a limit? Can it attract attention (e.g. from the king, or bigger darklings)?
- 💡 Idea pile: **drawing lines of light in the outside world** too, not just inside hearts. (Maybe, maybe not.)

### Heavy things ✅ (prototyped)
- Pushing is a deliberate action: stand next to a boulder and press **Right Mouse**. Walking into it does nothing.
- **Tar'ye are strong**: they brace, lean in and **shove**, rolling the boulder a couple of meters.
- **Humans can't**: they try to heave it, **struggle for a moment, then give up and step back**.
- Prototype Tar'ye look: Human-shaped pill person, a little bigger, with fur, **cat ears**, green cat eyes, and a tail that hangs **mostly level, drooping slightly**, swishing side to side with the odd flick, and **trailing behind on turns** before springing back, like the wisp's tail. Walking on four legs comes later.

### Prototype build order
1. ✅ Spirit view and darklings
2. ✅ Shine to drive darklings away (possessed-statue mini-puzzle)
3. ✅ Day-night cycle
4. ✅ Tar'ye, with boulder pushing (form-gated path)
5. ✅ The heart chase (ending a stubborn possession)
6. ✅ Stone-weight puzzle: the hut, gate and pressure plate (a body left as stone, or a Tar'ye's boulder, opens it; a spirit shrine inside grows the home star)
7. Each species' skills, one at a time (see **Species skills: the build list** in section 4)
8. The loop, with a timed event to puzzle around (e.g. a rising tide covering a path)
9. The journal

---

## 10. Systems

### Health and hunger ✅
- **Minecraft-style:** a health bar and a hunger bar; eating restores both.
- ✅ No separate stamina bar. **Fayran flight and Tar'ye sprinting burn hunger faster.**
- Tar'ye eat only meat.

### Combat ✅
- **Balanced and optional:** seek out as much as you want, but the story never depends on it.
- **Every fight can be won or avoided another way**, using each form's strengths. A Fayran caught by bandits flies away; a Kash outthinks them.
- ✅ The **no-kill path must be possible** throughout, including the final siege, and is built in from the start. Enemies need knock-out, flee and surrender states.

### Markets and reputation ✅
- Marketplaces with stalls owned by particular species.
- **As a Human or the stall-owner's species**, you see the full stock. As another species, you see about **2 items** because of the language barrier.
- Markets are mainly for **information, relationships and conversation**, and for resources (e.g. hunting an animal and selling it to the butcher).
- Reputation spreads by word of mouth: rescue a child and their mother tells the town; rob someone and everyone hears; get rescued yourself and you're known as a clumsy oaf.
- 💡 A no-theft playthrough must always be possible, so markets must stay fair without stealing.

### Companions ✅
- People can **come with you** if willing, such as a rescued child going home or an ally joining your cause.
- Allies can reappear later and change the ending (e.g. a warrior joins the final fight).

### Dialogue ✅
- **All NPC dialogue is written by hand.** No AI-generated conversation for now.
- **Clues must always be true.** No NPC ever gives a false clue by accident. (A character may *lie* on purpose as part of the story, but that's written deliberately.)
- Dialogue reacts to reputation, fame, species and form (e.g. limited conversation when you don't share a language and aren't Human).
- Each NPC still gets a **character sheet** (identity, species, personality, how they speak, what they know, their relationships). It keeps the writing consistent.

#### AI conversation (maybe someday)
Set aside for now. If it's ever revisited, the rules are: written dialogue stays the core, story facts are fixed data the AI can never contradict or invent, NPCs stay in-world, and off-topic or manipulative players get brushed off ("Go talk to a baker") until the NPC avoids them.

### Multiplayer ✅
- Single-player game.
- Passing the controller works naturally with loops.
- ✅ **No split-screen for now.** 💡 Keep camera and controls flexible so it's not ruled out later.

### Dragon companion (later update) ✅
- Hatched from an egg (possibly in one specific storyline, maybe the Volcanic Plains).
- Only one per player; grants an elemental power: light, fire, ice, water, earth, plants, void, sound, and others.
- Not in the first version.

---

## 11. Look and feel

- ✅ Semi-low-poly, **hand-painted** style: cared-for and detailed, but not realistic. "Real enough."
- Each chapter must feel distinct.
- 💡 Much of the hand-painted feel comes from lighting, color palette and shaders, which can be built in code.

---

## 12. Tools and workflow

Development machine: **M1 MacBook Air, 8 GB memory.** Keep installs small and leave it running smoothly for other things.

| Tool | Purpose | Size | Status |
|---|---|---|---|
| **Godot 4** | Game engine | ~200 MB | 💡 Recommended; not installed yet |
| **Blender** | 3D models, rigging, animation | ~1.5 GB | Later, for art |
| Git + GitHub | Version control and backup | — | ✅ Set up |
| ChatGPT images | Concept art | — | Anytime |
| Meshy / Tripo (web) | Image-to-3D starting models | — | Later, for art |

- **Not using:** Unreal (too big and heavy for this Mac), Unity (larger, needs an account; Godot fits better).
- Godot's files are plain text, which makes it easy for Claude to build and edit the game directly.
- If the game runs well on an M1 Air, it'll run on almost anything.

### Art pipeline 💡
1. Concept art from ChatGPT images; refine each species, with front and side views.
2. Image-to-3D tool for a rough starting model.
3. Cleanup and rigging in Blender, with Claude writing scripts and guiding step by step. Humans and Fayrans are fairly standard (wings need extra bones). **Kash tails and Tar'ye that move on two or four legs are the hardest**, and may eventually justify a hired 3D artist.
4. Environments (trees, rocks, cliffs, terrain) built procedurally with scripts and shaders.
5. **Gameplay first with simple shapes; real art only after Chapter 1 is fun.**

### Playtesting
- **Does it work?** Claude tests loops, saves and soft-locks with automated tests, screenshots and test runs.
- **Is it fun?** Only people can say: you, family and friends.

---

## 13. Build order

1. **Design** — this document. Settle the open questions in sections 3, 5 and 6.
2. **Core prototype (simple shapes):** wisp movement and camera; statue possession; one form; loop timer and reset; journal.
3. **Chapter 1 slice:** the coast and forest with several forms, the wildfire, one puzzle chain solvable by knowledge alone, and Johnny's possession storyline. Playtest it.
4. **Art direction test:** one small corner made beautiful, plus one test character. Settle the art pipeline.
5. **Remaining chapters**, one at a time.
6. **Darklings, story, the king's attention, the final siege and endings**, plus polish.
7. **Later updates:** the dragon; maybe split-screen or AI conversation someday.

---

## 14. Open questions (summary)

- [ ] Why does time loop, in-world?
- [ ] The good king's name, and his story before the possession
- [ ] What can kill the wisp itself?
- [ ] More detail on darklings
- [ ] The fifth ending
- [ ] Can you physically return to past chapters?
- [ ] Jungle disaster: storm or tsunami?
- [ ] What bounds the Dead Mudflats?
- [ ] Underground disaster: earthquake or cave-in?
- [ ] "Puxarorana" or "Puxarorna" (exact cipher spelling)
- [ ] Final game title
