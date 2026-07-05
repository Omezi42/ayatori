class_name HandBackground extends Node2D

var layout_id: int = 0

func _draw() -> void:
	if layout_id == 0:
		_draw_layout_hands()
	elif layout_id == 1:
		_draw_layout_board()
	elif layout_id == 2:
		_draw_layout_pyramid()

func _draw_layout_hands() -> void:
	pass

func _draw_layout_board() -> void:
	var board_color = Color("e6d8ce")
	var shadow_color = Color(0, 0, 0, 0.05)
	var rect = Rect2(240, 100, 800, 520)
	draw_rect(Rect2(rect.position + Vector2(0, 10), rect.size), shadow_color, true, 40.0)
	draw_rect(rect, board_color, true, 40.0)
	
	var positions = PinLayout.get_positions(1)
	for i in range(10):
		var p = positions[i]
		draw_circle(p + Vector2(0, 5), 45.0, shadow_color)
		draw_circle(p, 45.0, Color("ffffff").blend(Color(0,0,0,0.1)))

func _draw_layout_pyramid() -> void:
	var base_color = Color("d4e6ce")
	var shadow_color = Color(0, 0, 0, 0.05)
	
	var positions = PinLayout.get_positions(2)
	# Draw lines connecting perimeter
	var points = PackedVector2Array()
	for i in range(9):
		points.append(positions[i])
	points.append(positions[0])
	
	var line_color = Color("b5ccad")
	draw_polyline(points, shadow_color, 80.0, true)
	draw_polyline(points, base_color, 80.0, true)
	
	# Draw center area
	draw_circle(positions[9] + Vector2(0, 5), 60.0, shadow_color)
	draw_circle(positions[9], 60.0, base_color)


func _draw_hand_fingers(palm: Vector2, fingers: Array, color: Color, shadow: Color) -> void:
	var thickness = 80.0
	for finger_pos in fingers:
		# ドロップシャドウ
		draw_circle(finger_pos + Vector2(0, 10), thickness / 2.0, shadow)
		
		# メインカラー
		draw_circle(finger_pos, thickness / 2.0, color)
