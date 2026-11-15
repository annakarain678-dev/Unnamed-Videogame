class_name Lore
extends RefCounted
## Everything the player can learn. One entry per fact: the line the journal keeps, and, for a rumour, where
## it came from and the place it points to (so the rumour chart can link them). Add new facts here.
## A rumour's `to` must match the name of a place the world announces (see RegionWorld).

const FACTS := {
	"lost_child": {
		"text": "A child has gone missing from the town. The Town Crier says small footprints led north along the road.",
		"from": "Town Crier", "to": "Road fork",
	},
	"scholar_ruins": {
		"text": "The Scholar says there are ruins to the south-west, older than the town, with something buried under them.",
		"from": "Scholar", "to": "Ancient Ruins",
	},
	"dragon_egg": {
		"text": "The ruins are said to hold a dragon's egg. Hatching it would bring great power, and the king's eye.",
		"from": "Scholar", "to": "",
	},
	"lucifer_name": {
		"text": "An old name from the library's oldest book: B'nuo Puxarorna, the Lord of the Dark.",
		"from": "Scholar", "to": "",
	},
	"king_evil": {
		"text": "The Sen-Kash visitor says the king has grown cruel in the last few years, and that the Qoi-Kash have vanished from the lake road.",
		"from": "Sen-Kash Visitor", "to": "Qoi-Kash Village",
	},
	"darklings_possess": {
		"text": "Darklings take hold of people from the inside. Only a Sen-Kash, or light itself, can see them.",
		"from": "Sen-Kash Visitor", "to": "",
	},
	"duel_ground": {
		"text": "The Tar'ye at the meat stand will test anyone's strength on the duel ground, east of the market. Nobody dies.",
		"from": "Tar'ye Meat Stand", "to": "",
	},
	"lake_statues": {
		"text": "The Cartographer says there are old statues beside a lake to the south, where a form pillar stands.",
		"from": "Fayran Cartographer", "to": "Lake Statues",
	},
}
