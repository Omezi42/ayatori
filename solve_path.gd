extends SceneTree

func _init():
	var dummy_script = GDScript.new()
	dummy_script.source_code = "extends Node\nvar active_rules = {}\nfunc has_rule(r): return active_rules.has(r) and active_rules[r]"
	dummy_script.reload()
	var GameSaveMock = ClassDB.instantiate("Node")
	GameSaveMock.set_script(dummy_script)
	GameSaveMock.active_rules = {"multi_loop": true}
	
	if Engine.has_singleton("GameSave"):
		Engine.unregister_singleton("GameSave")
	Engine.register_singleton("GameSave", GameSaveMock)
	
	var sm = preload("res://scripts/StringManager.gd").new()
	sm.layout_id = 0
	
	var init_seq: Array[int] = [0, 4, 5, 9]
	var target_seq: Array[int] = [5, 4, 6, 5, 2, 8, 5, 0, 9]
	
	var queue = [{"state": init_seq, "path": []}]
	var visited = {}
	visited[sm._get_canonical_key(init_seq)] = true
	
	var found = false
	
	while queue.size() > 0:
		var curr = queue.pop_front()
		var state = curr["state"]
		var path = curr["path"]
		
		if sm.is_state_matching_target(state, target_seq):
			print("Found path in ", path.size(), " moves!")
			for i in range(path.size()):
				var m = path[i]["move"]
				print(i+1, ": ", m["type"], " pin ", m.get("finger", ""), " at segment ", m.get("segment_index", ""))
			found = true
			break
			
		var moves = sm._generate_next_moves(state)
		for move in moves:
			var nxt_state = move["next_state"]
			var nxt_key = sm._get_canonical_key(nxt_state)
			if not visited.has(nxt_key):
				visited[nxt_key] = true
				var new_path = path.duplicate()
				new_path.append(move)
				queue.push_back({"state": nxt_state, "path": new_path})
				
	if not found:
		print("Not found")
	
	quit()
