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
	
	var levels = [
		{"name": "ふたごやま", "target": [0, 4, 8, 0, 5, 9], "layout_id": 2, "is_adv": true},
		{"name": "ダブルトライアングル", "target": [5, 2, 8, 5, 4, 6], "layout_id": 0, "is_adv": true},
		{"name": "砂時計", "target": [0, 1, 2, 3, 0, 9, 8, 7], "layout_id": 0, "is_adv": true},
		{"name": "メガネ", "target": [2, 1, 0, 9, 2, 3, 5, 8], "layout_id": 0, "is_adv": true},
		{"name": "クリスタル", "target": [0, 2, 5, 8, 0, 3, 5, 7], "layout_id": 0, "is_adv": true},
		{"name": "クローバー", "target": [5, 4, 6, 5, 2, 8, 5, 0, 9], "layout_id": 0, "is_adv": true},
		{"name": "クラウン", "target": [1, 0, 9, 1, 2, 5, 8, 9, 5], "layout_id": 0, "is_adv": true},
		{"name": "かざぐるま", "target": [5, 1, 2, 5, 3, 4, 5, 6, 7, 5, 8, 9], "layout_id": 0, "is_adv": true},
		{"name": "さんかく", "target": [1, 5, 8], "layout_id": 0, "is_adv": false},
		{"name": "リボン", "target": [0, 4, 6, 2], "layout_id": 0, "is_adv": false},
		{"name": "ダイヤ", "target": [0, 2, 5, 8], "layout_id": 0, "is_adv": false},
		{"name": "いなずま", "target": [1, 7, 3, 5], "layout_id": 0, "is_adv": false},
		{"name": "ロケット", "target": [0, 3, 6, 8], "layout_id": 0, "is_adv": false},
		{"name": "ちょうちょ", "target": [1, 5, 9, 2, 8], "layout_id": 0, "is_adv": false},
		{"name": "ほし", "target": [0, 6, 2, 8, 4], "layout_id": 0, "is_adv": false},
		{"name": "おうち", "target": [0, 2, 3, 7, 8], "layout_id": 0, "is_adv": false},
		{"name": "フラワー", "target": [1, 4, 6, 9, 2, 7, 5, 8, 3, 0], "layout_id": 0, "is_adv": false},
		{"name": "ピラミッド-1", "target": [3, 9, 0, 1], "layout_id": 1, "is_adv": false},
		{"name": "ピラミッド-2", "target": [0, 3, 5, 6, 8], "layout_id": 1, "is_adv": false},
		{"name": "ピラミッド-3", "target": [8, 4, 7, 5, 3, 0, 9, 2, 1], "layout_id": 1, "is_adv": false}
	]
	
	for lvl in levels:
		GameSaveMock.active_rules = {"multi_loop": lvl["is_adv"]}
		sm.layout_id = lvl["layout_id"]
		var target_seq = lvl["target"]
		var init_seq: Array[int] = [0, 4, 5, 9]
		if lvl["layout_id"] == 1:
			init_seq = [0, 5, 9]
		elif lvl["layout_id"] == 2:
			init_seq = [0, 4, 8]
			
		sm.is_state_matching_target(init_seq, target_seq)
		
		var q = [{"state": init_seq, "path_len": 0}]
		var visited = {}
		
		var found_depth = -1
		for depth in range(1, 11):
			var next_q = []
			while q.size() > 0:
				var curr = q.pop_front()
				var state = curr["state"]
				
				var moves = sm._generate_next_moves(state)
				for move in moves:
					var nxt_state = move["next_state"]
					var nxt_key = sm._get_canonical_key(nxt_state)
					if visited.has(nxt_key): continue
					visited[nxt_key] = true
					
					if sm.is_state_matching_target(nxt_state, target_seq):
						found_depth = depth
						break
					
					next_q.push_back({"state": nxt_state, "path_len": depth})
					
				if found_depth != -1: break
			if found_depth != -1: break
			q = next_q
			
		if found_depth == -1:
			print(lvl["name"], ": NOT FOUND")
		else:
			print(lvl["name"], ": ", found_depth)
			
	quit()
