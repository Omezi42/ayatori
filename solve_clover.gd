extends SceneTree

func _init():
	var sm = preload("res://scripts/StringManager.gd").new()
	var GameSaveMock = ClassDB.instantiate("Node")
	GameSaveMock.set_script(preload("res://scripts/GameSave.gd"))
	GameSaveMock.active_rules = {"multi_loop": true}
	if Engine.has_singleton("GameSave"):
		Engine.unregister_singleton("GameSave")
	Engine.register_singleton("GameSave", GameSaveMock)

	var start_state: Array[int] = [0, 4, 5, 9]
	var target_state: Array[int] = [5, 4, 6, 5, 2, 8, 5, 0, 9]
	
	var queue = [{"state": start_state, "path": []}]
	var visited = {}
	visited[sm._get_canonical_key(start_state)] = true
	
	print("Solving...")
	
	var found = false
	while queue.size() > 0:
		var curr = queue.pop_front()
		
		if sm.is_state_matching_target(curr["state"], target_state):
			print("Solution found in ", curr["path"].size(), " moves:")
			for i in range(curr["path"].size()):
				var move = curr["path"][i]
				if move.has("unhook_index"):
					print(i + 1, ": Unhook index ", move["unhook_index"])
				else:
					print(i + 1, ": Hook finger ", move["finger_id"], " on segment ", move["segment_index"])
			found = true
			break
			
		var next_moves = sm._generate_next_moves(curr["state"])
		for move in next_moves:
			var next_state = move["next_state"]
			var key = sm._get_canonical_key(next_state)
			if not visited.has(key):
				visited[key] = true
				var next_path = curr["path"].duplicate()
				next_path.push_back(move)
				queue.push_back({"state": next_state, "path": next_path})
				
	if not found:
		print("No solution found")
		
	quit()
