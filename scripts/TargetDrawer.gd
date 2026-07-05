class_name TargetDrawer extends Control

var target_sequence: Array[int] = []

# 固定された指の座標
var finger_positions: Array[Vector2] = [
	Vector2(640, 110),
	Vector2(786, 158),
	Vector2(877, 283),
	Vector2(877, 437),
	Vector2(786, 562),
	Vector2(640, 610),
	Vector2(494, 562),
	Vector2(403, 437),
	Vector2(403, 283),
	Vector2(494, 158)
]

func set_target(sequence: Array[int]) -> void:
	target_sequence = sequence
	queue_redraw()

func _draw() -> void:
	if target_sequence.size() < 2:
		return
	
	var points = PackedVector2Array()
	for idx in target_sequence:
		if idx >= 0 and idx < finger_positions.size():
			points.append(finger_positions[idx])
			
	if points.size() > 0:
		points.append(points[0]) # 閉じたループにする
		
	draw_polyline(points, Color(0.96, 0.45, 0.65, 1.0), 12.0, true)
