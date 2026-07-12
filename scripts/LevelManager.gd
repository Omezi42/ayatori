class_name LevelManager extends Node

# LevelData リソースの配列（インスペクタから設定可能）
@export var level_data_list: Array[LevelData] = []

var current_level_index: int = 0

# シグナル: LevelDataオブジェクトをそのまま渡す
signal level_changed(level_idx: int, level_data: LevelData)
signal game_cleared()

func start_game() -> void:
	# レベルデータが未設定の場合はデフォルトレベルを生成
	if level_data_list.is_empty():
		create_default_levels()
	current_level_index = 0
	_load_current_level()

func load_level(index: int) -> void:
	if level_data_list.is_empty():
		create_default_levels()
	if index >= 0 and index < level_data_list.size():
		current_level_index = index
	else:
		push_warning("LevelManager: load_level(%d) out of range (0-%d), falling back to 0" % [index, level_data_list.size() - 1])
		current_level_index = 0
	_load_current_level()

func next_level() -> void:
	current_level_index += 1
	if current_level_index < level_data_list.size():
		_load_current_level()
	else:
		game_cleared.emit()

func _load_current_level() -> void:
	if current_level_index >= level_data_list.size():
		push_warning("LevelManager: _load_current_level() index %d out of range" % current_level_index)
		return
	
	var data = level_data_list[current_level_index]
	level_changed.emit(current_level_index, data)

func get_current_level_target() -> Array[int]:
	if current_level_index < level_data_list.size():
		return level_data_list[current_level_index].target_sequence.duplicate()
	return []

func get_level_count() -> int:
	if level_data_list.is_empty():
		create_default_levels()
	return level_data_list.size()

# デフォルトのレベルデータを生成
# 最新の難易度ロジックに基づいて動的にソート・最短手数を再計算する
func create_default_levels() -> void:
	var level_configs = []
	
	if _is_advanced_mode():
		level_configs = [
			{"name": "ふたごやま", "target": [0, 4, 8, 0, 5, 9], "layout_id": 2, "optimal_moves": 2},
			{"name": "ダブルトライアングル", "target": [5, 2, 8, 5, 4, 6], "layout_id": 0, "optimal_moves": 5},
			{"name": "砂時計", "target": [0, 1, 2, 3, 0, 9, 8, 7], "layout_id": 0, "optimal_moves": 7},
			{"name": "メガネ", "target": [2, 1, 0, 9, 2, 3, 5, 8], "layout_id": 0, "optimal_moves": 6},
			{"name": "クリスタル", "target": [0, 2, 5, 8, 0, 3, 5, 7], "layout_id": 0, "optimal_moves": 6},
			{"name": "クローバー", "target": [5, 4, 6, 5, 2, 8, 5, 0, 9], "layout_id": 0, "optimal_moves": 4},
			{"name": "クラウン", "target": [1, 0, 9, 1, 2, 5, 8, 9, 5], "layout_id": 0, "optimal_moves": 5},
			{"name": "かざぐるま", "target": [5, 1, 2, 5, 3, 4, 5, 6, 7, 5, 8, 9], "layout_id": 0, "optimal_moves": 8},
			{"name": "メビウス", "target": [0, 1, 5, 8, 9, 0, 2, 5, 7, 9], "layout_id": 0, "optimal_moves": 6},
			{"name": "タリスマン", "target": [5, 0, 2, 4, 5, 6, 8, 9, 1, 5, 3, 7], "layout_id": 0, "optimal_moves": 7},
			{"name": "ギャラクシー", "target": [0, 4, 8, 2, 6, 0, 5, 9, 3, 7, 1, 5], "layout_id": 0, "optimal_moves": 8},
			{"name": "スパイダー", "target": [0, 5, 1, 6, 2, 7, 3, 8, 4, 9, 0, 3, 6, 9], "layout_id": 0, "optimal_moves": 10}
		]
	else:
		level_configs = [
			{"name": "さんかく", "target": [1, 5, 8], "layout_id": 0, "optimal_moves": 5},
			{"name": "リボン", "target": [0, 4, 6, 2], "layout_id": 0, "optimal_moves": 4},
			{"name": "ダイヤ", "target": [0, 2, 5, 8], "layout_id": 0, "optimal_moves": 4},
			{"name": "いなずま", "target": [1, 7, 3, 5], "layout_id": 0, "optimal_moves": 6},
			{"name": "ロケット", "target": [0, 3, 6, 8], "layout_id": 0, "optimal_moves": 6},
			{"name": "ちょうちょ", "target": [1, 5, 9, 2, 8], "layout_id": 0, "optimal_moves": 5},
			{"name": "ほし", "target": [0, 6, 2, 8, 4], "layout_id": 0, "optimal_moves": 5},
			{"name": "おうち", "target": [0, 2, 3, 7, 8], "layout_id": 0, "optimal_moves": 7},
			{"name": "フラワー", "target": [1, 4, 6, 9, 2, 7, 5, 8, 3, 0], "layout_id": 0, "optimal_moves": 8},
			{"name": "ラビリンス", "target": [0, 4, 8, 2, 6, 1, 5, 9, 3, 7], "layout_id": 0, "optimal_moves": 6},
			{"name": "トルネード", "target": [0, 9, 1, 8, 2, 7, 3, 6, 4, 5], "layout_id": 0, "optimal_moves": 8},
			{"name": "ピラミッド-1", "target": [3, 9, 0, 1], "layout_id": 2, "optimal_moves": 3},
			{"name": "ピラミッド-2", "target": [0, 3, 5, 6, 8], "layout_id": 2, "optimal_moves": 3},
			{"name": "ピラミッド-3", "target": [8, 4, 7, 5, 3, 0, 9, 2, 1], "layout_id": 2, "optimal_moves": 7},
			{"name": "ピラミッド-4", "target": [8, 2, 1, 0, 4, 3, 9, 5, 6], "layout_id": 2, "optimal_moves": 6},
			{"name": "ピラミッド-5", "target": [0, 3, 4, 6, 9, 2, 1, 7, 5], "layout_id": 2, "optimal_moves": 6}
		]

	# 難易度スコアリング

	for config in level_configs:
		var target_seq: Array[int] = []
		target_seq.assign(config["target"])
		
		# 2. 難易度計算のための指標を取得
		var inter = _calculate_intersections(target_seq)
		var overlaps = _calculate_overlaps(target_seq)
		var v = target_seq.size()
		var stretch = _calculate_stretch(target_seq)
		
		# 3. 新しい重み付け（最短手数の重要度を下げ、交点と重ね掛けの重要度を上げる）
		config["score"] = inter * 15.0 + overlaps * 20.0 + v * 3.0 + stretch * 2.0 + float(config["optimal_moves"]) * 0.5

	# 難易度順に並び替え（丸型レイアウトを先に、丸型はスコア順、ピラミッドは名前順）
	level_configs.sort_custom(func(a, b): 
		var layout_a = a.get("layout_id", 0)
		var layout_b = b.get("layout_id", 0)
		if layout_a != layout_b:
			return layout_a < layout_b
		if layout_a == 2:
			return a["name"] < b["name"]
		return a["score"] < b["score"]
	)
	
	
	level_data_list.clear()
	for config in level_configs:
		var level = LevelData.new()
		level.level_name = config["name"]
		var ts: Array[int] = []
		ts.assign(config["target"])
		level.target_sequence = ts
		var is_seq: Array[int] = [0, 4, 5, 9]
		level.initial_sequence = is_seq
		if config.has("layout_id"):
			level.layout_id = config["layout_id"]
		if config.has("optimal_moves"):
			level.optimal_moves = config["optimal_moves"]
		
		level.active_rules = _get_active_rules()
		level_data_list.append(level)

func _is_advanced_mode() -> bool:
	if Engine.has_singleton("GameSave"):
		var gs = Engine.get_singleton("GameSave")
		if gs and gs.has_method("has_rule"):
			return gs.has_rule("multi_loop")
	if Engine.get_main_loop() and Engine.get_main_loop() is SceneTree and Engine.get_main_loop().root and Engine.get_main_loop().root.is_inside_tree() and Engine.get_main_loop().root.has_node("/root/GameSave"):
		var gs = Engine.get_main_loop().root.get_node("/root/GameSave")
		if gs and gs.has_method("has_rule"):
			return gs.has_rule("multi_loop")
	return false

func _get_active_rules() -> Dictionary:
	if Engine.has_singleton("GameSave"):
		var gs = Engine.get_singleton("GameSave")
		if gs and "active_rules" in gs and gs.active_rules is Dictionary:
			return gs.active_rules.duplicate()
	if Engine.get_main_loop() and Engine.get_main_loop() is SceneTree and Engine.get_main_loop().root and Engine.get_main_loop().root.is_inside_tree() and Engine.get_main_loop().root.has_node("/root/GameSave"):
		var gs = Engine.get_main_loop().root.get_node("/root/GameSave")
		if gs and "active_rules" in gs and gs.active_rules is Dictionary:
			return gs.active_rules.duplicate()
	return {}

# 交点の数を計算（円形モデルベース）
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

# 重ね掛け（同じ指への複数回のフック）の数を計算
func _calculate_overlaps(target: Array[int]) -> int:
	var count = 0
	var seen = {}
	for x in target:
		if seen.has(x):
			count += 1
		seen[x] = true
	return count

# 線の伸縮度合いを計算
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
	return stretch / float(n)
