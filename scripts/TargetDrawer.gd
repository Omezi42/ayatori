class_name TargetDrawer extends Control

var target_sequence: Array[int] = []

# 固定された指の座標
	pass

var layout_id: int = 0

func set_layout(new_layout_id: int) -> void:
	layout_id = new_layout_id
	queue_redraw()

func set_target(sequence: Array[int]) -> void:
	target_sequence = sequence
	queue_redraw()

func _draw() -> void:
	var finger_positions = PinLayout.get_positions(layout_id)
	# すべてのピンを薄く描画
	for pos in finger_positions:
		draw_circle(pos, 15.0, Color(0.8, 0.8, 0.8, 0.5))
	
	if target_sequence.size() < 2:
		return
	
	var points = PackedVector2Array()
	for idx in target_sequence:
		if idx >= 0 and idx < finger_positions.size():
			points.append(finger_positions[idx])
			# お題に使われるピンを強調して描画
			draw_circle(finger_positions[idx], 20.0, Color(1.0, 0.6, 0.7, 0.8))
			
	if points.size() > 0:
		points.append(points[0]) # 閉じたループにする
		
	draw_polyline(points, Color(0.96, 0.45, 0.65, 1.0), 12.0, true)
