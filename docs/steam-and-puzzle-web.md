# Steam plan, puzzle web and the wisp's charge

Working notes from the planning session. Nothing here is built yet.

## 1. Releasing on Steam (demo first)

Sources are third-party guides, so check the official Steamworks docs (partner.steamgames.com) before committing to dates or money.

**What it takes**
- A Steamworks account and a **one-time $100 fee per game**, which Steam refunds to you once the game earns $1,000. A demo is its own separate listing, so check whether it needs its own fee.
- Valve takes about 30% of sales. Taxes and identity paperwork come first, and approval takes days to weeks.
- A **Coming Soon page** must be public for at least two weeks before release. Most guides say start 3 to 6 months early.
- Valve reviews the store page and the build before they go live.
- Add Steam support to Godot with GodotSteam (achievements, cloud saves) once the game is further along.
- Exports are needed for Windows (most Steam players) and Mac. **We must test on a Windows machine.**
- Steam asks developers to disclose AI-generated content. Check what that means for this project.

**Marketing that matters**
- **Wishlists are the main metric.** Steam shows the game to more people when many have wishlisted it. Guides say a few thousand wishlists before launch is a good target, but the numbers vary a lot.
- Make a **short trailer** (about 60 seconds, with the best moment in the first 10), capsule art and 5 to 8 good screenshots. The wisp, the star and the species are the visual hook.
- **A demo can be the main marketing.** Steam Next Fest (a few times a year) needs a demo. Guides suggest 15 to 30 minutes at first, but a deeper demo works for an exploration game.
- Keep a devlog and a Discord server going. Send streamer and press keys (Keymailer-style sites), and post clips on social media.
- Pick tags honestly: exploration, puzzle, time loop, open world, atmospheric.

**Suggested path**
1. Pick the final name and register it.
2. Build Chapter 1 as a polished vertical slice.
3. Put the Coming Soon page up as early as the trailer and art exist.
4. Release the demo during a Next Fest.
5. Use the demo's feedback and wishlists to decide the full launch date.

## 2. How Outer Wilds links its places

The web search didn't find a clean clue map, so the patterns below start from memory. Section 2b checks them against the real ship log graph on outerwilds.ventures.

**Patterns**
- **Every place is entered by a clue from somewhere else** (a ship log rumor, a Nomai message, a signal or a visible oddity). Almost nothing is gated by items.
- **Gates are knowledge.** Examples are coordinates, a route, a hazard's timing, or how to open a door.
- **Average of about 2 outgoing clues per place** (range 1 to 3), and many places have 2 incoming. A few hubs send you to 3 or more places.
- **A hub is usually reached partway through**, after one or two simple places. Early places point inward to the hub.
- **Some places are visible long before they're reachable** (the Quantum Moon, Dark Bramble, the Interloper). Seeing them first makes you want to figure out how to get there.
- **Dead ends give a story payoff**, not a progression gate. Not every branch has to open something.
- **Death loops let the game make places hard to leave.** Dying is the exit from the centre or from a trap, so the designers don't need an elevator back out.
- **The ship log shows connections between clues.** It marks which ones are unfinished and the player decides what to chase next.

**Your Giant's Deep example, as a graph**

```
Giant's Deep astronaut ──► satellite-parts island ──► orbiting space station
                                       └────────────► sunken piece at the planet's centre (jellyfish puzzle)
```

## 2b. What the real ship log graph shows

Source: the interactive ship log at outerwilds.ventures. I counted its nodes and links by script, and matched each link to its nearest card, so the figures are approximate.

- **About 90 cards and 73 links.** Each card is a place or a discovery, and each link is a "rumour" that the log shows between two places.
- **Average of 2.06 links per card.** The spread: 26 cards have 1 link (37%), 23 have 2, 14 have 3, and 8 have 4. **No card has more than 4.**
- **The busiest cards are places like the Ash Twin Project, the Hanging City, the Sunless City, the Orbital Probe Cannon's neighbours and Escape Pod 2.** None is a giant central hub. The web is wide, not a star.
- **Six colour-coded story threads** group the cards: the Orbital Cannon and the Eye, the Quantum Moon, the Vessel and Nomai arrival, the Ash Twin Project, the Stranger, and a miscellaneous thread (the Interloper and the fate of the Nomai). Most links stay inside one thread, and a few cross between them.
- **Each card holds 1 to 6 log entries.** The number is shown on the card, so you know how much is left to find there.
- **A link can be found from either end.** The guide says links "may be found at either side", so a clue can come from either place.
- **The big places have sub-places.** The Orbital Probe Cannon branches into the Construction Yard, Gabbro's Island and the Southern Observatory. The Ash Twin Project branches into the Nomai Mines, High Energy Lab, Statue Workshop and Black Hole Forge. Each big place is a small cluster, not one room.
- **Some clusters sit apart.** The Stranger forms its own large cluster, and the Quantum Moon is a separate cluster from the rest.

**What this means for our journal and puzzles**
- Aim for about 2 links per place, with a maximum of 4.
- A third of the places should be one-link endings.
- Build 5 or 6 threads (one per species, or one per theme) and let a few links cross between them.
- Show the player the unfinished links, and a count of how many entries remain at each place.
- Let a clue be found at either end of a link.

## 3. Rules for our puzzle web

1. **Each puzzle has a hook** (why you notice it), a **want** (why you care) and **2 pointers out**. A hub can have 3.
2. The **want** should be one of: curiosity (something unexplained is visible), need (a path is blocked), care (someone needs help), dread (the fire clock), or gift (a new body or ability).
3. **No item gates.** The things you carry between loops are knowledge, bodies you find again, and how well you know the world.
4. **Each species is a key.** Every Chapter 1 puzzle should be solvable best with one species. The beach statues are where you swap bodies.
5. **Some places are seen from far away first** (the smoke column, the lighthouse, the canopy), so the player makes their own goals.
6. **Trap one area on purpose** so dying is how you leave. Our version is the Forest Heart, ringed by fire.

## 4. Chapter 1 web (first draft)

```
Beach statues (tutorial) ──► Smoke column in the forest ──► Wildfire origin
        │
        ├──► Tar'ye weight hut ──► Johnny's cache ──► Canopy observatory
        │                      └──► Fayran feather carving ──► Canopy observatory
        │
        └──► Haunted human / darkling heart ──► Darkling nest
                                            └──► Sunken lighthouse (Qoi-Kash dive)
                                                   ├──► Lighthouse signal (tells the fire's time)
                                                   └──► Canopy observatory (the fire map)

Canopy observatory ──► Forest Heart (walled by fire; die to leave)
                  └──► Cliff pass (the way out of Chapter 1)

Cliff pass needs three pieces of knowledge: the fire's time, the darkling oath, and the lighthouse signal.
```

| Place | Why you go | Species key | Points to |
|---|---|---|---|
| Beach statues | You arrive here; the smoke is on the horizon | all five, to learn them | smoke column, weight hut, haunted human |
| Weight hut | Boulders block the only inland path | Tar'ye | Johnny's cache, the feather carving |
| Haunted human | It's a body you want back, and a person trapped inside | wisp light, then any | darkling nest, lighthouse |
| Sunken lighthouse | A light is blinking underwater | Qoi-Kash (gills) | fire time, canopy |
| Canopy observatory | You can see it from everywhere | Fayran | fire map, cliff pass, Forest Heart |
| Forest Heart | The fire pushes you here | any | nothing, except dying shows where it ends |
| Cliff pass | The way out | needs all three clues | Chapter 2 |

The Sen-Kash hasn't been given a puzzle yet. A narrow burrow under the fire's start would fit.

## 5. The wisp's charge (a destiny that isn't a prophecy)

**The scene.** The game opens in a void where the wisp sees what happened: the world burning, kingdoms falling, the people lost. A voice (the star) tells you it is your purpose to get to the end, one way or another.

**Why it isn't a prophecy:**
- The star gives a **destination and a duty**, not a script. "Reach the end and stop the ruin," never "you will do X."
- It says *what must be reached* and leaves *how* and *what you do there* up to you.
- The star is wrong or limited in places. It doesn't know about the possessed king until you find out.
- The ending you get depends on who you've been along the way (kills, mercy, fame, which bodies you kept). That keeps the free will.

**Five endings (proposed):**
1. **Exorcism** (best): drive B'nuo Puxarorana out of the king.
2. **Sacrifice**: the king dies and the possession ends with him.
3. **Flight**: you leave with the people you saved and the world falls.
4. **Throne**: the wisp takes the crown (the fame path goes wrong).
5. **Dark star**: you give up and the star goes out.

**Open questions**
- Does the star know the whole truth or only part of it?
- Is the "end" a place, a person, or a moment?
- How much of the void scene do we show in the demo?
