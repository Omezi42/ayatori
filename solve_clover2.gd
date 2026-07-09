extends SceneTree

func _init():
	var sm = preload("res://scripts/StringManager.gd").new()
	var GameSaveMock = ClassDB.instantiate("Node")
	GameSaveMock.set_script(preload("res://scripts/GameSave.gd"))
	GameSaveMock.active_rules = {"multi_loop": true}
	if Engine.has_singleton("GameSave"):
		Engine.unregister_singleton("GameSave")
	Engine.register_singleton("GameSave", GameSaveMock)

	var current: Array[int] = [0, 4, 5, 9]
	var target: Array[int] = [5, 4, 6, 5, 2, 8, 5, 0, 9]

	print("Initial state: ", current)

	for step in range(10):
		if sm.is_state_matching_target(current, target):
			print("Finished!")
			break
			
		var hint = sm.get_heuristic_hint(current, target)
		
		if hint.is_empty():
			print("No hint available.")
			break
		if hint.has("_need_deep_search"):
			# If need deep search, let's call the BFS manually
			var target_key = sm._get_canonical_key(target)
			var bfs_hint = sm._search_bidirectional_bfs(current, target, target_key)
			if bfs_hint.is_empty():
				print("BFS failed to find hint")
				break
			hint = bfs_hint
			
		if hint.type == "hook":
			print("手目", step + 1, ": ", current[hint.segment_index], "と", current[(hint.segment_index + 1) % current.size()], "の間の糸を引いて", hint.finger, "のピンにかける")
			current.insert(hint.segment_index + 1, hint.finger)
		elif hint.type == "unhook":
			print("手目", step + 1, ": ", hint.finger, "のピンから糸をはずす")
			current.remove_at(hint.index)
			
		print("Current state: ", current)

	quit()
