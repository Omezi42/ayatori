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
		_create_default_levels()
	current_level_index = 0
	_load_current_level()

func load_level(index: int) -> void:
	if level_data_list.is_empty():
		_create_default_levels()
	if index >= 0 and index < level_data_list.size():
		current_level_index = index
	else:
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
		return
	
	var data = level_data_list[current_level_index]
	level_changed.emit(current_level_index, data)

func get_current_level_target() -> Array[int]:
	if current_level_index < level_data_list.size():
		return level_data_list[current_level_index].target_sequence.duplicate()
	return []

# デフォルトのレベルデータを生成（.tres未設定時のフォールバック）
func _create_default_levels() -> void:
	var level_configs = [
		{"name": "さんかく", "target": [1, 5, 8], "optimal_moves": 5}, # score: 20.7 (om:5, i:0, v:3, str:3.3)
		{"name": "ひしがた", "target": [0, 3, 5, 7], "optimal_moves": 4}, # score: 21.0 (om:4, i:0, v:4, str:2.5)
		{"name": "ダイヤ", "target": [0, 2, 5, 8], "optimal_moves": 4}, # score: 21.0 (om:4, i:0, v:4, str:2.5)
		{"name": "しかく", "target": [1, 3, 7, 9], "optimal_moves": 6}, # score: 23.0 (om:6, i:0, v:4, str:2.5)
		{"name": "ロケット", "target": [0, 3, 6, 8], "optimal_moves": 6}, # score: 23.0 (om:6, i:0, v:4, str:2.5)
		{"name": "クリスタル", "target": [0, 2, 4, 5, 6, 8], "optimal_moves": 4}, # score: 25.3 (om:4, i:0, v:6, str:1.7)
		{"name": "おうち", "target": [0, 2, 3, 7, 8], "optimal_moves": 7}, # score: 26.0 (om:7, i:0, v:5, str:2.0)
		{"name": "リボン", "target": [0, 4, 6, 2], "optimal_moves": 4}, # score: 32.0 (om:4, i:1, v:4, str:3.0)
		{"name": "テント", "target": [0, 4, 5, 6, 2], "optimal_moves": 3}, # score: 32.8 (om:3, i:1, v:5, str:2.4)
		{"name": "クロス", "target": [1, 7, 9, 3], "optimal_moves": 6}, # score: 34.0 (om:6, i:1, v:4, str:3.0)
		{"name": "かざぐるま", "target": [1, 6, 9, 4], "optimal_moves": 4}, # score: 34.0 (om:4, i:1, v:4, str:4.0)
		{"name": "いなずま", "target": [1, 7, 3, 5], "optimal_moves": 6}, # score: 35.0 (om:6, i:1, v:4, str:3.5)
		{"name": "クラウン", "target": [0, 4, 2, 6, 8], "optimal_moves": 5}, # score: 35.6 (om:5, i:1, v:5, str:2.8)
		{"name": "さかな", "target": [2, 7, 5, 3, 8], "optimal_moves": 7}, # score: 39.2 (om:7, i:1, v:5, str:3.6)
		{"name": "めがね", "target": [8, 9, 7, 6, 5, 4, 3, 2], "optimal_moves": 6}, # score: 43.0 (om:6, i:1, v:8, str:1.5)
		{"name": "キャンディ", "target": [1, 3, 2, 8, 7, 9], "optimal_moves": 8}, # score: 50.0 (om:8, i:2, v:6, str:2.0)
		{"name": "インフィニティ", "target": [2, 6, 9, 7, 3, 0], "optimal_moves": 6}, # score: 60.0 (om:6, i:3, v:6, str:3.0)
		{"name": "ちょうちょ", "target": [1, 5, 9, 2, 8], "optimal_moves": 5}, # score: 77.2 (om:5, i:5, v:5, str:3.6)
		{"name": "ほし", "target": [0, 6, 2, 8, 4], "optimal_moves": 5}, # score: 78.0 (om:5, i:5, v:5, str:4.0)
		{"name": "スパイダー", "target": [0, 4, 7, 2, 6, 9], "optimal_moves": 4}, # score: 78.7 (om:4, i:5, v:6, str:3.3)
		{"name": "ふたごぼし", "target": [0, 3, 8, 1, 6, 2], "optimal_moves": 8}, # score: 103.3 (om:8, i:7, v:6, str:3.7)
		{"name": "ギザギザ", "target": [0, 2, 4, 6, 8, 9, 7, 5, 3, 1], "optimal_moves": 8}, # score: 111.6 (om:8, i:7, v:10, str:1.8)
		{"name": "マジックサークル", "target": [0, 3, 5, 7, 9, 2, 4, 6, 8, 1], "optimal_moves": 8}, # score: 142.4 (om:8, i:10, v:10, str:2.2)
		{"name": "フラワー", "target": [1, 4, 6, 9, 2, 7, 5, 8, 3, 0], "optimal_moves": 8}, # score: 184.0 (om:8, i:14, v:10, str:3.0)
		{"name": "ブラックホール", "target": [9, 3, 6, 1, 8, 4, 7, 2, 5, 0], "optimal_moves": 8}, # score: 245.2 (om:8, i:20, v:10, str:3.6)
		{"name": "スーパーノヴァ", "target": [0, 5, 2, 7, 4, 9, 1, 6, 3, 8], "optimal_moves": 8}, # score: 265.6 (om:8, i:22, v:10, str:3.8)
		{"name": "ギャラクシー", "target": [0, 6, 3, 9, 5, 1, 8, 4, 7, 2], "optimal_moves": 6}, # score: 273.2 (om:6, i:23, v:10, str:3.6)
		{"name": "マスター", "target": [0, 4, 8, 1, 5, 9, 2, 6, 3, 7], "optimal_moves": 6}, # score: 293.2 (om:6, i:25, v:10, str:3.6)
		{"name": "コスモス", "target": [2, 7, 4, 9, 5, 0, 6, 1, 8, 3], "optimal_moves": 8}, # score: 296.0 (om:8, i:25, v:10, str:4.0)
		{"name": "メイズ", "target": [0, 4, 8, 3, 7, 1, 5, 9, 2, 6], "optimal_moves": 6} # score: 334.0 (om:6, i:29, v:10, str:4.0)
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
		if config.has("optimal_moves"):
			level.optimal_moves = config["optimal_moves"]
		level_data_list.append(level)
