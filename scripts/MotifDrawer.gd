class_name MotifDrawer extends Node2D

var line: Line2D
var motif_scale: float = 0.0
var base_points: PackedVector2Array = []
var center_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	line = Line2D.new()
	line.width = 80.0
	line.default_color = Color(1.0, 0.9, 0.4, 0.5) # 光るような黄色/ゴールド
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.closed = true
	add_child(line)
	
func setup(finger_positions: Dictionary, target_sequence: Array[int]):
	base_points.clear()
	for f_id in target_sequence:
		if finger_positions.has(f_id):
			base_points.append(finger_positions[f_id])
			
	if base_points.is_empty():
		return
		
	# 中心を計算
	center_pos = Vector2.ZERO
	for p in base_points:
		center_pos += p
	center_pos /= base_points.size()
	
	motif_scale = 0.0
	modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "motif_scale", 1.0, 1.2)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# 少し待ってから消える
	var tween2 = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween2.tween_interval(2.0)
	tween2.tween_property(self, "modulate:a", 0.0, 0.5)

func _process(delta: float) -> void:
	if base_points.size() < 3:
		return
	
	line.clear_points()
	for p in base_points:
		line.add_point(center_pos + (p - center_pos) * motif_scale)
