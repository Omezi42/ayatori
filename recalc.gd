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
		{"name": "クローバー", "target": [5, 4, 6, 5, 2, 8, 5, 0, 9], "layout_id": 0},
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
	
	for group in all_levels:
		print("--- " + group["mode"] + " ---")
		var is_adv = group["mode"] == "advanced"
		GameSaveMock.active_rules = {"multi_loop": is_adv}
		
		# set global GameSave if needed (StringManager checks it)
		if Engine.has_singleton("GameSave"):
			Engine.unregister_singleton("GameSave")
		Engine.register_singleton("GameSave", GameSaveMock)
		
		for conf in group["list"]:
			var target_seq: Array[int] = []
			target_seq.assign(conf["target"])
			
			var om = sm.calculate_optimal_moves_count(init_seq.duplicate(), target_seq.duplicate())
			conf["optimal_moves"] = om
			
			var inter = _calculate_intersections(target_seq)
			var overlaps = _calculate_overlaps(target_seq)
			var v = target_seq.size()
			var stretch = _calculate_stretch(target_seq)
			
			# NEW SCORE FORMULA
			# Lower OM weight, higher inter and overlaps weight
			var score = inter * 15.0 + overlaps * 20.0 + v * 3.0 + stretch * 2.0 + om * 1.0
			conf["score"] = score
			conf["metrics"] = "om:%d i:%d o:%d v:%d s:%.1f" % [om, inter, overlaps, v, stretch]
			
		group["list"].sort_custom(func(a, b): return a["score"] < b["score"])
		
		for conf in group["list"]:
			print('\t\t{"name": "%s", "target": %s, "optimal_moves": %d, "layout_id": %d}, # score: %.1f (%s)' % [conf["name"], str(conf["target"]), conf["optimal_moves"], conf["layout_id"], conf["score"], conf["metrics"]])
			
	quit()

func _calculate_intersections(target: Array[int]) -> int:
	var count = 0
	var n = target.size()
	if n < 4: return 0
	for i in range(n):
		for j in range(i + 1, n):
			var A = target[i]
			var B = target[(i + 1) % n]
			var C = target[j]
			var D = target[(j + 1) % n]
			if A == C or A == D or B == C or B == D:
				continue
			var diff_B = (B - A + 10) % 10
			var diff_C = (C - A + 10) % 10
			var diff_D = (D - A + 10) % 10
			var C_inside = diff_C > 0 and diff_C < diff_B
			var D_inside = diff_D > 0 and diff_D < diff_B
			if C_inside != D_inside:
				count += 1
	return count

func _calculate_overlaps(target: Array[int]) -> int:
	var count = 0
	var seen = {}
	for x in target:
		if seen.has(x):
			count += 1
		seen[x] = true
	return count

func _calculate_stretch(target: Array[int]) -> float:
	var stretch = 0.0
	var n = target.size()
	if n == 0: return 0.0
	for i in range(n):
		var a = target[i]
		var b = target[(i + 1) % n]
		var dist = abs(a - b)
		dist = min(dist, 10 - dist)
		stretch += dist
	return stretch / n
