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
# 難易度順に並び替え済み（Phase 4）
func create_default_levels() -> void:
	# 難易度順: 要素数少・手数少 → 要素数多・手数多、新レイアウトは後半へ
	var level_configs = [
		# === 入門 (円形レイアウト / 3-4要素) ===
		{"name": "さんかく", "target": [1, 5, 8], "optimal_moves": 5, "layout_id": 0},
		{"name": "リボン", "target": [0, 4, 6, 2], "optimal_moves": 4, "layout_id": 0},
		{"name": "ダイヤ", "target": [0, 2, 5, 8], "optimal_moves": 4, "layout_id": 0},
		# === 初級 (円形レイアウト / 4-5要素) ===
		{"name": "いなずま", "target": [1, 7, 3, 5], "optimal_moves": 6, "layout_id": 0},
		{"name": "ロケット", "target": [0, 3, 6, 8], "optimal_moves": 6, "layout_id": 0},
		# === 中級 (円形レイアウト / 5要素) ===
		{"name": "ちょうちょ", "target": [1, 5, 9, 2, 8], "optimal_moves": 5, "layout_id": 0},
		{"name": "ほし", "target": [0, 6, 2, 8, 4], "optimal_moves": 5, "layout_id": 0},
		{"name": "おうち", "target": [0, 2, 3, 7, 8], "optimal_moves": 7, "layout_id": 0},
		# === 上級 (円形レイアウト / 多要素) ===
		{"name": "フラワー", "target": [1, 4, 6, 9, 2, 7, 5, 8, 3, 0], "optimal_moves": 8, "layout_id": 0},
		# === ピラミッドレイアウト ===
		{"name": "ピラミッド-1", "target": [3, 9, 0, 1], "optimal_moves": 4, "layout_id": 2},
		{"name": "ピラミッド-2", "target": [0, 3, 5, 6, 8], "optimal_moves": 5, "layout_id": 2},
		{"name": "ピラミッド-3", "target": [8, 4, 7, 5, 3, 0, 9, 2, 1], "optimal_moves": 7, "layout_id": 2}
	]
	
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
		level_data_list.append(level)
