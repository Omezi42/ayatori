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
	var level1 = LevelData.new()
	level1.level_name = "さんかく"
	var ts1: Array[int] = [1, 5, 8]
	level1.target_sequence = ts1
	var is1: Array[int] = [0, 4, 5, 9]
	level1.initial_sequence = is1
	
	var level2 = LevelData.new()
	level2.level_name = "ほし"
	var ts2: Array[int] = [0, 6, 2, 8, 4]
	level2.target_sequence = ts2
	var is2: Array[int] = [0, 4, 5, 9]
	level2.initial_sequence = is2
	
	var level3 = LevelData.new()
	level3.level_name = "ギザギザ"
	var ts3: Array[int] = [0, 2, 4, 6, 8, 9, 7, 5, 3, 1]
	level3.target_sequence = ts3
	var is3: Array[int] = [0, 4, 5, 9]
	level3.initial_sequence = is3
	
	level_data_list = [level1, level2, level3]
