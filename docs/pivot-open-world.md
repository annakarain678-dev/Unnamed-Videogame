# Pivot: open world, a stilled kingdom, no time loop

This note **replaces** the time loop and the chapter structure in the older notes. The species skills, the wisp, the darklings and the spirit view all stay. Nothing here is built yet.

## 1. The new shape

- **One open world, no chapters, no death loop.** Everything is reachable from the start. Some places need a form (species) you haven't unlocked, or knowledge you haven't found yet.
- **The world is stilled.** Almost every person in Lenhavu is a stone statue. They aren't dead. They're waiting.
- **Progress is learning,** not killing. Each place you understand gives you an ability, a tool, a route, or a piece of colour back in the world.
- **The end is a place you can reach with knowledge, not a boss.** There's a final confrontation, but it's a trial of what you've learned.
- **Size and feel:** a smaller, handcrafted game in the spirit of *Pathless*. The demo is one region of this one world.

## 2. The story, in one page (proposal)

**The Stilling.**
- A plague called the Wasting was killing Lenhavu. The king, a good man, was grieving and desperate.
- A voice offered him a bargain: *no one else will die*. In one hour, everyone was **stilled**: stone, preserved, no longer dying and no longer living.
- The voice was B'nuo Puxarorana. The king's gratitude let it in. It now possesses him, and he rules a silent world of statues, sure he saved them.
- **The counterfeit.** The stilling offers life without life. That is the Christian heart of the story: a good thing (saving people) bought by a lie, and mercy that turns into a prison.

**The wisp.**
- A star watched this happen. One of its sparks fell to Lenhavu with a charge: wake them.
- You don't remember who you were. The statues' memories are how you learn the world.
- You can't take over people. That is what darklings do (they possess statues). The wisp is different from them because it refuses to wear a person. You change form only at pedestals (see section 4).

**The key.**
- The bargain was written in a name, and names can be unwritten. Breaking it takes the **truth**: the true history, who said what, and the king's real choice.
- That is a *knowledge* solution. You get there by exploring, not by fighting.

## 3. Conflicting lore (the player decides what to believe)

Statues tell different versions of the same events:
- The royal guard says the king was betrayed by his council.
- The priest says the king sinned by bargaining with a spirit.
- A child saw only that the king's eyes changed.
- A scholar says the plague never ended, and the Stilling merely paused it.

The player's chosen version is tracked as **Belief**. It shapes who trusts you, which places open, and which ending you can reach. Some versions are true, some partly true, and none is flagged as such.

## 4. Mechanics changes

**Forms.**
- You no longer enter statues. They're people.
- **Likeness pedestals** (pedestals, save points) let you change form. You unlock a form by hearing a stilled person of that species remember who they were.
- This limits switching, which stops you from always using the best form for everything. The wisp can still float and leave any body anywhere.
- Existing body code (Human, Tar'ye, Sen-Kash, Qoi-Kash, Fayran) is reused as it is.

**Statues.**
- You can interact with them to hear memories: what they were doing, what they feared, what they saw.
- A few influential statues (a captain, a priest, a mapmaker) point to important places on the map. That gives the Outer Wilds clue web, but through people.
- **Restoration.** When you finish a place, its colour and life return to the area, and some of its people wake. This is the visible reward and the progress meter.

**Tools and abilities.**
- Each region gives something you can carry or use: a lantern's range, a grapnel, a bow, a ward against darkness.
- They open routes and help in optional fights. They never gate the final trial.

**Combat.**
- It exists but stays secondary: darklings, and some corrupted creatures.
- You can finish the game without killing. Violence changes your **reputation**, not your access.

**Soft-lock rules.**
1. The wisp can always float and always leave a body, so you can never be stuck.
2. Pedestals sit near the start and in every region.
3. Puzzle states reset when you leave the area.
4. No consumable key items.
5. Losing a body returns you to wisp form.

## 5. The egg (hidden secret)

- Somewhere hidden lies an **unhatched egg**. It wasn't stilled because it isn't born yet. It's alive, and it needs a partner.
- Pairing with it gives a companion (it hatches into something that helps you explore) and raises your **Bond** stat.
- It shapes one ending (see section 6, Substitution).
- The creature should be original, not a dragon. Ideas: a star-seed, a small beast of the forest, or a hatchling of one of the five species.

## 6. Stats and endings

Four tracked values:
- **Truth** (how much real lore you've found and understood)
- **Mercy** (what you chose when you could have harmed)
- **Reputation** (how the world remembers you)
- **Bond** (the egg and the people you've woken)

| Ending | What you do | Needs |
|---|---|---|
| **Unbinding** (best) | Break the bargain with the truth. The king is freed of B'nuo, and everyone wakes. | High Truth and Mercy |
| **Substitution** | The stilling must hold *someone*, so you take its place. Everyone wakes and you become a statue. | Willingness, Bond for the bittersweet epilogue |
| **The Throne** | Kill the king and take his place. Reputation decides: a **tyrant** who is overthrown one day, a **forgettable king** in a long line of histories, or a **hero-king** the kingdom keeps. | Violence, then Reputation |
| **Keeping the Stillness** | You leave the bargain alone. The world stays safe and silent. | Low Truth or a chosen Belief |
| **Wandering** | You walk away before the end. | Nothing |

**Why you can't just hop to another body in the Substitution ending:** the stilling takes whoever *holds the unbinding*, and the wisp's whole light is spent in it. A spark that is stilled can't leave the stone. That's what makes it a sacrifice. If you've bonded with the egg, it carries a spark of your light forward.

## 7. Open world structure

Regions (not chapters). Each has its own theme, one new rule, and links to the others:

| Region | Theme | Key form or tool | Notes |
|---|---|---|---|
| Coast and giant forest | Fire and shelter | Any, Tar'ye strength | The demo area |
| Drowned delta | Water and depth | Qoi-Kash, Sen-Kash | Breath and currents |
| The Aeries | Height and wind | Fayran | Flight puzzles |
| The Underways | Stone and darkness | Tar'ye, Sen-Kash | Burrows and ruins |
| The Capital and Throne | The king's court | Everything | The final trial |

- A direct route to the throne exists from the start, so you *can* finish early. You'll just reach it with low Truth.
- The puzzle web follows Outer Wilds: about 2 links per place, 4 at most, a third being dead-end story places. Each big place has a theme, one failed attempt, one contradiction and one missing piece (see section 6 of the Steam and puzzle notes).

## 8. How this affects what's built

| Existing | What happens |
|---|---|
| Species bodies and skills | Kept as they are |
| Wisp, spirit view, day and night | Kept |
| Darklings | Kept, now the thing that wears statues (a corruption of the dead) |
| Heart chase | Becomes an optional trial: freeing a person from a darkling's grip |
| Statues on the beach | Become likeness pedestals (changing form) and stilled people (memories) |
| Time loop and death-reset code | Not used |
| Journal idea | Becomes the Memory Journal (collected memories, linked by rumours) |

## 9. Open decisions

1. **Cause of the Stilling.** The recommended answer is the king's bargain (above). The alternative is a fungus or spore, which is more natural but has less moral weight.
2. **The king.** Is he fully good, or does he carry some guilt? That changes whether killing him is a tragedy.
3. **The egg's creature.** What is it, and what does it do for the player?
4. **How the Belief stat works.** Does the player pick versions in the journal, or does it follow what they do?
