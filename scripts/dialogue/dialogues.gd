class_name Dialogues
extends RefCounted
## The conversations. Each person has a species, a list of openers, and a set of nodes.
##
## - "start": [[condition, node], ...]. The first whose condition is true is where talking begins.
## - A node has "text", optional "effects" (applied when it is shown), and "choices". A choice has "text",
##   optional "if" (only shown when true), optional "effects", and "goto" (a node id; left out = ends).
## - Conditions and effects are the strings GameState.check and GameState.apply understand.
## A choice that denies something the player knows should carry "lie_if_knows:<fact>": that is what makes
## pretending not to know cost Valor, while real ignorance costs nothing.

const TREES := {
	"crier": {
		"name": "Town Crier", "species": "Human",
		"note": "Calls the news in the square. Worried about a missing child.",
		"start": [["flag:crier_talked", "again"], ["", "hello"]],
		"nodes": {
			"hello": {
				"text": "Hear ye! The market is open, the road north is clear, and the Tar'ye are betting on the duel ground again! ... Oh. You look like someone who listens. Have you seen a child? A little one, brown coat. She went missing three days ago.",
				"choices": [
					{"text": "No. Tell me more.", "goto": "child", "effects": ["flag:crier_talked"]},
					{"text": "Sorry, I can't help.", "effects": ["flag:crier_talked"]},
				],
			},
			"child": {
				"text": "Small footprints led out of town, up the north road past the forest. They stop where the road forks. I can't leave the square, and the guards say it is not their business.",
				"effects": ["learn:lost_child"],
				"choices": [
					{"text": "I'll keep an eye out.", "goto": "thanks", "effects": ["stat:fame+1"]},
					{"text": "Why would anyone take a child?", "goto": "why"},
				],
			},
			"why": {
				"text": "Bandits, I think. There have been more of them since the king raised the tolls. Or worse. People say things about the dead trees to the north-west.",
				"choices": [{"text": "I'll keep an eye out.", "goto": "thanks"}],
			},
			"thanks": {"text": "Bless you. Hear ye, hear ye!"},
			"again": {
				"text": "Any word of the little one?",
				"choices": [
					{"text": "Not yet.", "goto": "thanks"},
					{"text": "Where were the footprints again?", "goto": "child"},
				],
			},
		},
	},

	"scholar": {
		"name": "Scholar", "species": "Human",
		"note": "Keeps the library. Knows old names and older ruins.",
		"start": [["flag:scholar_tested", "tested"], ["flag:scholar_talked", "again"], ["", "hello"]],
		"nodes": {
			"hello": {
				"text": "Quiet, please. ... Though I am rarely troubled. What brings you into the stacks?",
				"choices": [
					{"text": "Anything old and strange.", "goto": "ruins", "effects": ["flag:scholar_talked"]},
					{"text": "Do you know about the darklings?", "goto": "darklings", "effects": ["flag:scholar_talked"]},
					{"text": "Just looking.", "effects": ["flag:scholar_talked"]},
				],
			},
			"ruins": {
				"text": "Then you want the ruins to the south-west. They are older than the town and older than the king's line. The stones tell of a hatchery beneath them, and of a thing in it that has waited a very long time.",
				"effects": ["learn:scholar_ruins"],
				"choices": [
					{"text": "A hatchery? For what?", "goto": "egg"},
					{"text": "Thank you.", "goto": "name"},
				],
			},
			"egg": {
				"text": "A dragon's egg. Hatching one is not free. It would make you a legend, for good or ill, and it would not go unnoticed by the king.",
				"effects": ["learn:dragon_egg"],
				"choices": [{"text": "Thank you.", "goto": "name"}],
			},
			"darklings": {
				"text": "Spirits of the dark that hide inside people. Ordinary eyes cannot see them. The Sen-Kash can, or a very bright light. The oldest book in this room gives the name of the one they answer to, though I would sooner not say it twice.",
				"choices": [{"text": "Tell me the name.", "goto": "name"}],
			},
			"name": {
				"text": "B'nuo Puxarorna. Remember it, and tell no one I said it.",
				"effects": ["learn:lucifer_name"],
				"choices": [{"text": "I will remember.", "goto": "bye"}],
			},
			"bye": {"text": "Good. Mind the shelves on your way out."},
			"again": {
				"text": "Back so soon? I was about to test my own memory. Do you remember the name from the old book?",
				"effects": ["flag:scholar_tested"],
				"choices": [
					{"text": "Yes: B'nuo Puxarorna.", "goto": "honest"},
					{"text": "No, I don't know it.", "goto": "denied", "effects": ["lie_if_knows:lucifer_name"]},
				],
			},
			"honest": {
				"text": "Good. Honest and attentive. That will serve you.",
				"effects": ["stat:wisdom+1"],
			},
			"denied": {
				"text": "...Is that so? Well. I must have told someone else.",
			},
			"tested": {
				"text": "Take care out there. Honest ink lasts longer than a clever tongue.",
			},
		},
	},

	"visitor": {
		"name": "Sen-Kash Visitor", "species": "Sen-Kash",
		"note": "Came up from the south to see the market, and to listen.",
		"start": [["flag:visitor_talked", "again"], ["", "hello"]],
		"nodes": {
			"hello": {
				"text": "Sss. A traveller. Sit, if you like; I never do. I came north for a reason, and the market is a good place to listen. Do you hear what is being said about the king?",
				"choices": [
					{"text": "Tell me.", "goto": "king", "effects": ["flag:visitor_talked"]},
					{"text": "I've heard nothing.", "goto": "nothing", "effects": ["flag:visitor_talked"]},
				],
			},
			"king": {
				"text": "He is not what he was. Colder every season. The Qoi-Kash of the lake road have stopped coming to market, and no one will say why. I have gone looking, and I will tell you what I saw: a good many people in this town have something extra behind their eyes.",
				"effects": ["learn:king_evil", "learn:darklings_possess"],
				"choices": [{"text": "I'll keep my eyes open.", "goto": "bye"}],
			},
			"nothing": {
				"text": "Then listen well. It will be worth more to you than coin.",
				"choices": [{"text": "Go on.", "goto": "king"}],
			},
			"bye": {"text": "Sss. Stay bright."},
			"again": {
				"text": "Still here, still listening.",
				"choices": [{"text": "Say the part about the king again.", "goto": "king"}],
			},
		},
	},

	"meat_stand": {
		"name": "Tar'ye Meat Stand", "species": "Tar'ye",
		"note": "Sells roast meat. Loves a fair fight.",
		"start": [["flag:meat_talked", "again"], ["", "hello"]],
		"nodes": {
			"hello": {
				"text": "Roast kasu, hot! Good for your strength and better for your mood. You've the look of someone who's never lost a fair fight. Want to prove it? The duel ground's just east of the market. Nobody dies, nobody holds a grudge.",
				"effects": ["learn:duel_ground", "flag:meat_talked"],
				"choices": [
					{"text": "I'll think about it.", "goto": "bye"},
					{"text": "Not today.", "goto": "bye"},
				],
			},
			"bye": {"text": "Come back hungry!"},
			"again": {
				"text": "Meat, or a fight?",
				"choices": [{"text": "Neither, thanks.", "goto": "bye"}],
			},
		},
	},

	"cartographer": {
		"name": "Fayran Cartographer", "species": "Fayran",
		"note": "Draws the land from above. Loves a good landmark.",
		"start": [["flag:carto_talked", "again"], ["", "hello"]],
		"nodes": {
			"hello": {
				"text": "Careful, you'll blow my paper! ... I draw the land as it looks from the sky. The best landmarks I have found are the old statues beside the lake to the south. Anyone can see them from far off, and there is a pillar standing among them.",
				"effects": ["learn:lake_statues", "flag:carto_talked"],
				"choices": [{"text": "Thank you.", "goto": "bye"}],
			},
			"bye": {"text": "Fly well!"},
			"again": {
				"text": "Still want that map? It will fill in as you find places yourself.",
				"choices": [{"text": "I'll find them.", "goto": "bye"}],
			},
		},
	},
}


## True when two species can speak: everyone understands Human, and a species understands itself.
static func can_understand(a: String, b: String) -> bool:
	return a == "Human" or b == "Human" or a == b
