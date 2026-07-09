extends SceneTree

func _init():
	var sm = preload("res://scripts/StringManager.gd").new()
	var dummy_script = GDScript.new()
	dummy_script.source_code = "extends Node\nvar active_rules = {}\nfunc has_rule(r): return active_rules.has(r) and active_rules[r]"
	dummy_script.reload()
	var GameSaveMock = ClassDB.instantiate("Node")
	GameSaveMock.set_script(dummy_script)
	
	var advanced_levels = [
		{"name": "ふたごやま", "target": [0, 4, 8, 0, 5, 9], "layout_id": 2},
		{"name": "ダブルトライアングル", "target": [5, 2, 8, 5, 4, 6], "layout_id": 0},
		{"name": "砂時計", "target": [0, 1, 2, 3, 0, 9, 8, 7], "layout_id": 0},
		{"name": "メガネ", "target": [2, 1, 0, 9, 2, 3, 5, 8], "layout_id": 0},
		{"name": "クリスタル", "target": [0, 2, 5, 8, 0, 3, 5, 7], "layout_id": 0},
		{"name": "クラウン", "target": [1, 0, 9, 1, 2, 5, 8, 9, 5], "layout_id": 0},
		{"name": "かざぐるま", "target": [5, 1, 2, 5, 3, 4, 5, 6, 7, 5, 8, 9], "layout_id": 0}
	]
	
	var normal_levels = [
		{"name": "さんかく", "target": [1, 5, 8], "layout_id": 0},
		{"name": "リボン", "target": [0, 4, 6, 2], "layout_id": 0},
		{"name": "ダイヤ", "target": [0, 2, 5, 8], "layout_id": 0},
		{"name": "いなずま", "target": [1, 7, 3, 5], "layout_id": 0},
		{"name": "ロケット", "target": [0, 3, 6, 8], "layout_id": 0},
		{"name": "ちょうちょ", "target": [1, 5, 9, 2, 8], "layout_id": 0},
		{"name": "ほし", "target": [0, 6, 2, 8, 4], "layout_id": 0},
		{"name": "おうち", "target": [0, 2, 3, 7, 8], "layout_id": 0},
		{"name": "フラワー", "target": [1, 4, 6, 9, 2, 7, 5, 8, 3, 0], "layout_id": 0},
		{"name": "ピラミッド-1", "target": [3, 9, 0, 1], "layout_id": 2},
		{"name": "ピラミッド-2", "target": [0, 3, 5, 6, 8], "layout_id": 2},
		{"name": "ピラミッド-3", "target": [8, 4, 7, 5, 3, 0, 9, 2, 1], "layout_id": 2}
	]
	
	var all_levels = [
		{"mode": "advanced", "list": advanced_levels},
		{"mode": "normal", "list": normal_levels}
	]
	
	var init_seq: Array[int] = [0, 4, 5, 9]
	var f = FileAccess.open("res://recalc_results.txt", FileAccess.WRITE)
	
	for group in all_levels:
		var is_adv = group["mode"] == "advanced"
		GameSaveMock.active_rules = {"multi_loop": is_adv}
		
		if Engine.has_singleton("GameSave"):
			Engine.unregister_singleton("GameSave")
		Engine.register_singleton("GameSave", GameSaveMock)
		
		for conf in group["list"]:
			var target_seq: Array[int] = []
			target_seq.assign(conf["target"])
			
			var om = sm.calculate_optimal_moves_count(init_seq.duplicate(), target_seq.duplicate())
			f.store_line(conf["name"] + ":" + str(om))
			f.flush()
			
	f.close()
	quit()
