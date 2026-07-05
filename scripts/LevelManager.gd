class_name LevelManager extends Node

# 各レベルのお題データ（指IDの配列）
# Level 1: 簡単な三角形
# Level 2: 星型っぽい形
# Level 3: 複雑な図形
var levels = [
	[1, 5, 8], # 三角形
	[0, 6, 2, 8, 4], # 星型
	[0, 2, 4, 6, 8, 9, 7, 5, 3, 1] # ギザギザ円
]

# 各レベルの初期状態データ
var initial_states = [
	[0, 4, 5, 9],
	[0, 4, 5, 9],
	[0, 4, 5, 9]
]

var current_level_index: int = 0
signal level_changed(level_idx, target_string, initial_string)
signal game_cleared()

func start_game() -> void:
	current_level_index = 0
	_load_current_level()

func next_level() -> void:
	current_level_index += 1
	if current_level_index < levels.size():
		_load_current_level()
	else:
		game_cleared.emit()

func _load_current_level() -> void:
	var current_target: Array[int] = []
	current_target.assign(levels[current_level_index])
	var current_initial: Array[int] = []
	current_initial.assign(initial_states[current_level_index])
	level_changed.emit(current_level_index, current_target, current_initial)

func get_current_level_target() -> Array[int]:
	if current_level_index < levels.size():
		return levels[current_level_index]
	return []
