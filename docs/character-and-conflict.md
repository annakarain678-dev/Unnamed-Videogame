# Character, reputation and the conflict with the king

This note builds on [pivot-open-world.md](pivot-open-world.md). Where the two disagree, **this one wins**. Nothing here is built yet.

## 1. The story (revised)

- **Not a spore and not stone.** The spore stays in your own world's lore, as Noah's Ark. In the game, the conflict is the fall: after Lucifer fell, he took the keys of the world, and the wisp (a spark from the stars) has come to take them back.
- **Lanhavu is one region.** He holds sway over it through a king he possesses (B'nuo Puxarorana) and through **darklings** who possess ordinary people.
- **Possession is partial.** Many people are afflicted, but not all. Some bandits, mayors and guards are possessed. Others are just wicked, and some are good.
- **The Sen-Kash can sense possession.** Other species have to read clues: odd behaviour, cold hands, a flinch from light.
- **The ending never wins outright.** Whatever you do, the text of every ending says Lucifer still holds sway over Lanhavu, and someone greater will come one day.
  - The good endings send your spark to the stars.
  - The villain endings send it down to the **Black** (hell), among his angels.
- **Forms.** The "likeness pedestals" from the pivot note stay as the save points where you change form. The stone statues are dropped.
- **The dragon.** A small companion who flies around you, with an element. See section 8.

## 2. The minimum stats

Six numbers and a list of facts. That is enough for everything you described.

| Stat | Range | What it measures | Goes up when you... |
|---|---|---|---|
| **Virtue** | -100 to +100 | How good you are (one axis) | Show mercy, keep promises, help for free, sacrifice. Goes down: murder, theft, cruelty, taking pay after helping, bribes (slightly) |
| **Valor** | 0 to 100 | The knight in you | Charge into fights, protect others, face danger |
| **Wisdom** | 0 to 100 | The scholar in you | Read, investigate, avoid needless fights, solve things by knowing |
| **Guile** | 0 to 100 | The rogue in you | Bribe, lie, steal, sneak, bargain, snipe unseen |
| **Fame** | 0 to 100 | How widely you're known | Be seen doing notable things (good or bad) |
| **Gold** | 0 and up | Money | Quests, loot, selling |

On top of those:
- **Lore facts.** A list of things you know, each tagged (see section 6). This is the Outer Wilds journal.
- **King Lean.** A flag set from which sources you choose to believe about the king (good or evil, see section 7).
- **Suspicion** (hidden, 0 to 100). Crimes nobody saw. See section 4.
- **Bribe price** (hidden). Starts low, and goes up each time you pay.

**Your "Way"** is whichever of Valor, Wisdom and Guile is highest. It sets your voice in dialogue.

**Everything works from tags.** Every action sends a small packet to one `Character` script, for example `{virtue:+2, valor:+1, fame:+1, witnessed:true}`. That one script applies it. You never write special-case code for a quest. You tag its outcomes.

## 3. Same action, different reactions

Virtue is changed by **what you did and why**. Fame and local goodwill are changed by **how people reacted**.

Example: you drive a darkling out of a mayor.
- A **contrite** mayor is thankful, because the dark urges are gone. Fame +, local goodwill +.
- A **hardened** mayor wants to stay evil and hates the conviction. He blames you, calls the guards and sends a bounty. Fame + (a different kind: wanted).
- Your Virtue goes up either way, because you did a good thing.

Each afflicted NPC has a hidden *disposition* (contrite or hardened) that you can read from clues. This is how the game shows how people react to a Christ-like figure.

**Compensation after the deed.**
- "Ten gold for helping you" is asking for pay after agreeing to help free: Virtue -1, Guile +1, Gold +.
- Helping, then keeping their things: Virtue -5, Guile +3, and the victim's family remembers.
- The line between them is deliberate. The first is mildly selfish, the second is evil.

## 4. Fame, hunts and being caught

**Fame decides how far the king's reach extends.**
- Hunt radius from the castle = base + Fame x something. Low Fame means only the area close to the castle is dangerous.
- Hunting party strength and frequency also scale with Fame.
- **Quiet play** (low Fame, or doing what the king would want) is left alone.
- **Famous defiance** draws bigger parties more often. This is the pressure that pushes you toward the final confrontation.

**Witnesses.** Crimes and heroic acts count only if someone saw them.
- A sniped guard nobody saw: no Fame change, no Virtue loss from the act being known, but **Suspicion** rises, which raises hunt activity without giving you a reputation.
- Murder in front of a town: Fame and a bounty right away, and you're a wanted person. Nobody helps you, and some people attack on sight.
- Full investigations are **out of scope** for now. Suspicion is the simple version.

**Being caught.** When a hunting party catches you, you choose:
1. **Fight** (if you can).
2. **Bribe them.** You pay the bribe price, and are released in a random town (or the last pedestal). The price goes up next time. The king hears that you take bribes: Virtue -1, Guile +2, and some dialogue options change.
3. **Surrender.** You're taken to the king early. This is an audience you aren't ready for: you lose, are recruited, or are let go, depending on your stats. Either way you wake at a pedestal. It's never a game over.

## 4b. Soft-lock rules

1. The wisp can always float and leave any body.
2. Pedestals are near the start and in each town.
3. Puzzle states reset when you leave.
4. No consumable key items.
5. Being caught or killed returns you to a pedestal with a cost (gold, Fame, a scar), never a dead end.

## 5. Dialogue: how it works

**Format:** a hand-written choice list (we already decided hand-written only). Each beat offers up to **3 options, one per Way** (Valor, Wisdom, Guile), and some are also tagged with a Virtue direction.

- **Gating.** An option is available if your stats allow it. A locked option is shown greyed with a reason ("You aren't the sort to lie").
- **Voice.** The same intent is worded differently for a knight, a scholar and a rogue. That keeps the writing manageable, with about 3 lines per beat.
- **Consistency rule.** The more you've played one Way, the fewer options of the others you get. A villain through and through can't suddenly be a saint at the end. There is wiggle room, but not much.
- **Closest games:** Disco Elysium (skills as voices), Fable (good, evil and renown), Kingdom Come: Deliverance (witnesses, bribes, guilt), Dishonored (consequence by how you play), Life is Strange and Detroit (choices that change the ending).

**What NPCs ask you for** (every request is tagged):
1. Help for free (Virtue +)
2. Help for pay (mild Virtue -, Gold +)
3. Hide something (Guile +, Virtue -)
4. Spy or steal (Guile +, Virtue -)
5. Hurt someone (Valor or Guile +, Virtue -)
6. Carry a message or item (neutral, builds goodwill)

## 6. Knowledge that matters in the end

Lore facts aren't trivia. Each is tagged with a **use**, so each one does something when you bring it to the right place:

| Tag | What it does |
|---|---|
| **Weakness** | Reveals how to beat an enemy faster, e.g. a darkling tied to an object, or an ability a creature fears |
| **Name** | A true name breaks a darkling's hold when spoken at the right moment |
| **Route** | A secret path, guard shift or map for the castle or a fortress. Practical advantage |
| **Secret** | Leverage over a person. Lets you avoid a fight or turn an enemy into an ally |
| **Rite** | A real prayer, ward or ritual. It only works if you learned the *correct* form |
| **Contradiction** | Proof that a claim is false. Used against the devil's promises |

So a knowledge-heavy player has an easier fight (weak points), more allies (secrets), safer entry (routes), and better odds in the final deal (contradictions).

**The final scene: the deal.**
- It's not a quiz. It's a negotiation with a silver tongue.
- He offers promises: "I will leave the kingdom." "No harm will come to the people." You have to catch **the double-sided wording**, such as *leave* the kingdom but keep the king's body, or *no harm from me* while his servants do harm.
- Each trick you catch needs a **Contradiction** fact you actually have. A wrong accusation costs you (he gains ground).
- Each caught lie removes a **hold** on the kingdom. Beat all of them and he is driven out, and the cost is paid.
- He still isn't gone forever (see section 1).

Knowledge and weapons count equally. You can reach the confrontation through a knight's route (win fights, gain allies), a scholar's route (win the negotiation), or a rogue's route (cut a deal with him).

## 7. The king, and the final choice

- **The king is the same man for everyone.** The same events happen and the same people say the same things.
- **Affinity bias.** You decide whether you believe he was good or evil, and the final scene highlights the version you chose, tempered by what else you learned.
- **The options at the end depend on who you've been:**

| Your build | Final options |
|---|---|
| Hero (Virtue high) | Drive him out (with knowledge), sacrifice yourself, or spare the king and take the crown as a hero |
| Scholar (Wisdom high) | Outwit the deal and drive him out |
| Knight (Valor high) | Fight and drive him out, at a cost |
| Rogue or villain (Guile high, Virtue low) | Join the enemy as his right hand, or kill the king and rule as a tyrant |
| Mixed | A narrower set, with whichever fits best |

The kill-and-take-the-throne result depends on your Fame and Virtue: an overthrown tyrant, a forgettable king in a long line, or a hero-king. A player who has been a villain the whole game can't suddenly walk the saint's route. The reverse is also true.

## 8. Items, interactables and the dragon

**A small inventory.** Gold, 4 to 6 materials (iron, hide, herb, oil, cloth, wood), 1 to 2 weapons, 1 tool and the dragon's element. The lore lives in the journal, not the bag.

**Interactables:**
1. Pedestals (change form, save)
2. People (dialogue, requests)
3. Lore objects (letters, murals, graves, inscriptions)
4. Notice and bounty boards (your own poster shows when you're wanted)
5. Merchants and the blacksmith (crafting takes game days)
6. Chests and loot
7. Campfires and beds (rest, pass time)
8. Shrines and bells (rites)
9. Doors, levers, pressure plates and boulders (we already have these)
10. Ledges, ropes and climbing
11. Lanterns (light)

**The dragon.** A companion that flies near you. You choose its element at the start, or it learns more as you explore. A choice is better than random, because it says who you are. It's one of the "powerful finds" that attract exploring.

**Weapons as rewards.** A few unique weapons are hidden in places that need a form and some lore to reach.

## 9. Combat that isn't button-mashing

Inspired by *Horizon Zero Dawn* (find the right way in) and *Pathless* (puzzles feeding power).

- Three verbs: **Strike** (heavy, committed), **Guard or dodge** (timed, optional), **Light** (the wisp's shine, which exposes and exorcises).
- **Each enemy has a way in.** Possessed enemies are weak to light and have a visible tell. Beasts have weak points. Bandits have patrols.
- **Choose your approach:** face it, snipe from a cliff, sneak, use a lore Weakness, or avoid it.
- **Non-lethal is an option.** Knocking out or exorcising gives Virtue. Killing a possessed person is worse than exorcising them.
- **Species help.** Tar'ye are strong, the Fayran can attack from above, the Sen-Kash sense possession, and the Qoi-Kash fight in water.

## 10. Side quests

Every side quest must give at least one of:
- **Lore** (a tagged fact)
- **Materials** (for crafting)
- **Character change** (Virtue, a Way, Fame)

And it must tie into the main story. Example: "bring me iron for a sword" also teaches you where the iron comes from, which has a darkling-infested mine.

**Demo quests (draft):**
1. **The mayor** has a darkling. Drive it out, expose him, or blackmail him. A contrite or hardened mayor reacts differently.
2. **The smith** wants iron. A craft quest whose mine has a lore fact about the king's guards.
3. **The payment:** you help a farmer, and he offers pay (or you ask for it).
4. **The bandit camp** might be possessed, or just bandits. You can sniff out which, with the Sen-Kash.
5. **The hunting party** arrives once your Fame is high enough. A test of all the systems.

## 11. Time

- **Day and night** stays (10-minute days).
- **Game days** pass for crafting, hunts and some schedules.
- **No hard deadline.** The king's pressure grows with your Fame instead.

## 12. What this is like, and the scope warning

**A mix of:** *The Pathless* (exploration, puzzles, power-ups), *Outer Wilds* (lore web), *Fable* and *Kingdom Come* (reputation, witnesses, bribes), *Disco Elysium* (voices), and *Horizon* (tactical fights).

**Scope is the main risk.** It's a big combination for a small team. The way to manage it:
- Build the **systems once** (the Character script, the dialogue gate, the tag packets) and fill them with content.
- Make a **vertical slice** first: one town, one mayor quest with three outcomes, one fight with three approaches, one hunting party, the bribe loop, a journal with about 8 facts, and a mini version of the deal.
- Use that as the Steam demo.

## 13. Build order

1. `Character` script (stats, tags, Way) with a debug overlay.
2. Dialogue runner with gated options.
3. One town with 3 NPCs and one quest.
4. Fame, witness and hunting party loop, plus bribe or surrender.
5. Combat with three approaches on one encounter.
6. Journal and lore tags.
7. The deal scene.
8. Dragon, loot and crafting.

## 14. Open questions

1. Is the **Black** shown at all in the game, or only in the ending text?
2. Does the **dragon** hatch from the hidden egg (as before) or come from somewhere else?
3. How many **settlements** in the demo region (suggested: one town and two small places)?
4. Do we want **bounty posters** and a **jail** screen, or only the three-choice capture?
