extends Node
## What the player is, knows and has done: the character system's memory.
##
## - Standing: Fame (towns), the king's Awareness of you, and the three Ways: Valor, Wisdom, Guile.
## - Knowledge: facts the player has learned (see Lore). The journal and the dialogue both read this, which
##   is how "pretending not to know something you know" can be told apart from plain ignorance.
## - People met, places found, and flags (tags) any part of the game can set and check.
## Nothing here is written to disk yet. When real saving is added, `to_dict` / `from_dict` are the hook.

## Anything changed (the journal redraws if it is open).
signal changed
## Something worth telling the player ("Rumour added", "Valor -1").
signal notice(text: String)

const STATS := ["fame", "awareness", "valor", "wisdom", "guile"]

var stats := {"fame": 0, "awareness": 0, "valor": 0, "wisdom": 0, "guile": 0}
## Fact ids in the order they were learned.
var facts: Array[String] = []
## Person id -> {name, species, note}.
var people := {}
## Place name -> true.
var places := {}
## Free-form tags: "mayor_purified", "child_found", ...
var flags := {}


func knows(fact: String) -> bool:
	return fact in facts


func learn(fact: String, quiet := false) -> void:
	if knows(fact):
		return
	facts.append(fact)
	var info: Dictionary = Lore.FACTS.get(fact, {})
	if not quiet:
		if info.get("to", "") != "":
			notice.emit("Rumour added: %s → %s" % [info.get("from", "?"), info["to"]])
		else:
			notice.emit("Journal updated")
	changed.emit()


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


func set_flag(flag: String, value := true) -> void:
	flags[flag] = value
	changed.emit()


func stat(stat_name: String) -> int:
	return stats.get(stat_name, 0)


func add_stat(stat_name: String, amount: int, why := "") -> void:
	if not stats.has(stat_name):
		return
	stats[stat_name] += amount
	var label: String = stat_name.capitalize()
	if stat_name == "awareness":
		label = "The king's awareness"
	notice.emit("%s %s%d%s" % [label, "+" if amount >= 0 else "−", absi(amount), ("  ·  " + why) if why != "" else ""])
	changed.emit()


func meet(person_id: String, person_name: String, species: String, note: String) -> void:
	if people.has(person_id):
		return
	people[person_id] = {"name": person_name, "species": species, "note": note}
	changed.emit()


func find_place(place_name: String) -> void:
	if places.has(place_name):
		return
	places[place_name] = true
	notice.emit("Place found: %s" % place_name)
	changed.emit()


## True when a rumour points at this place and the player has learned it.
func is_rumoured(place_name: String) -> bool:
	for fact in facts:
		if Lore.FACTS.get(fact, {}).get("to", "") == place_name:
			return true
	return false


## Checks one condition: "knows:x", "flag:x", "form:Human", "stat:valor>=2", each optionally with a leading "!".
## An empty condition is true.
func check(condition: String, player_species := "") -> bool:
	if condition == "":
		return true
	if condition.begins_with("!"):
		return not check(condition.substr(1), player_species)
	var kind := condition.get_slice(":", 0)
	var arg := condition.get_slice(":", 1)
	match kind:
		"knows":
			return knows(arg)
		"flag":
			return has_flag(arg)
		"form":
			return player_species == arg
		"stat":
			for op in [">=", "<=", ">", "<", "="]:
				if arg.contains(op):
					var value := stat(arg.get_slice(op, 0))
					var limit := int(arg.get_slice(op, 1))
					match op:
						">=": return value >= limit
						"<=": return value <= limit
						">": return value > limit
						"<": return value < limit
						_: return value == limit
	return false


## Applies one effect: "learn:x", "flag:x", "unflag:x", "stat:valor+1", "lie_if_knows:x" (a lie: costs Valor
## only if the player really knows the thing they are denying).
func apply(effect: String) -> void:
	var kind := effect.get_slice(":", 0)
	var arg := effect.get_slice(":", 1)
	match kind:
		"learn":
			learn(arg)
		"flag":
			set_flag(arg, true)
		"unflag":
			set_flag(arg, false)
		"lie_if_knows":
			if knows(arg):
				add_stat("valor", -1, "that was a lie")
		"stat":
			for op in ["+", "-"]:
				if arg.contains(op):
					var amount := int(arg.get_slice(op, 1))
					add_stat(arg.get_slice(op, 0), amount if op == "+" else -amount)
					return


func to_dict() -> Dictionary:
	return {"stats": stats, "facts": facts, "people": people, "places": places, "flags": flags}


func from_dict(data: Dictionary) -> void:
	stats = data.get("stats", stats)
	facts.assign(data.get("facts", []))
	people = data.get("people", {})
	places = data.get("places", {})
	flags = data.get("flags", {})
	changed.emit()
