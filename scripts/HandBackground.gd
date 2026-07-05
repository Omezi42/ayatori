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
	var skin_color = Color("ffeedd")
	var shadow_color = Color(0, 0, 0, 0.05)
	
	var left_palm = Vector2(450, 360)
	var right_palm = Vector2(830, 360)
	var palm_radius = 160.0
	
	draw_circle(left_palm + Vector2(0, 10), palm_radius, shadow_color)
	draw_circle(left_palm, palm_radius, skin_color)
	draw_circle(right_palm + Vector2(0, 10), palm_radius, shadow_color)
	draw_circle(right_palm, palm_radius, skin_color)
	
	var positions = PinLayout.get_positions(0)
	var r_fingers = []
	for i in range(5):
		r_fingers.append(positions[i])
	var l_fingers = []
	for i in range(5, 10):
		l_fingers.append(positions[i])
	l_fingers.reverse()
	
	_draw_hand_fingers(left_palm, l_fingers, skin_color, shadow_color)
	_draw_hand_fingers(right_palm, r_fingers, skin_color, shadow_color)

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
		var dir = (finger_pos - palm).normalized()
		var perp = Vector2(-dir.y, dir.x) * (thickness / 2.0)
		
		var p1 = palm + perp
		var p2 = palm - perp
		var p3 = finger_pos - perp
		var p4 = finger_pos + perp
		
		# ドロップシャドウ
		draw_polygon(PackedVector2Array([p1 + Vector2(0, 10), p2 + Vector2(0, 10), p3 + Vector2(0, 10), p4 + Vector2(0, 10)]), PackedColorArray([shadow, shadow, shadow, shadow]))
		draw_circle(finger_pos + Vector2(0, 10), thickness / 2.0, shadow)
		
		# メインカラー
		draw_polygon(PackedVector2Array([p1, p2, p3, p4]), PackedColorArray([color, color, color, color]))
		draw_circle(finger_pos, thickness / 2.0, color)
