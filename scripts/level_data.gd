class_name LevelData
extends Resource

@export var level_name: String = "新しいお題"
@export var target_image: Texture2D
@export var target_sequence: Array[int] = []
@export var initial_sequence: Array[int] = [0, 4, 5, 9]
@export var optimal_moves: int = -1 # -1の場合は自動計算
@export var layout_id: int = 0 # 0: 円形, 1: 2行5列, 2: 星型
