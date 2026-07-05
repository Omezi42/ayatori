class_name HandBackground extends Node2D

func _draw() -> void:
	var skin_color = Color("ffeedd")
	var shadow_color = Color(0, 0, 0, 0.05)
	
	# 手のひらのベース部分
	var left_palm = Vector2(450, 360)
	var right_palm = Vector2(830, 360)
	var palm_radius = 160.0
	
	# 左手のひら
	draw_circle(left_palm + Vector2(0, 10), palm_radius, shadow_color)
	draw_circle(left_palm, palm_radius, skin_color)
	
	# 右手のひら
	draw_circle(right_palm + Vector2(0, 10), palm_radius, shadow_color)
	draw_circle(right_palm, palm_radius, skin_color)
	
	# 指の位置（FingerNodeの座標と一致）
	var l_fingers = [Vector2(494, 158), Vector2(403, 283), Vector2(403, 437), Vector2(494, 562), Vector2(640, 610)]
	var r_fingers = [Vector2(640, 110), Vector2(786, 158), Vector2(877, 283), Vector2(877, 437), Vector2(786, 562)]
	
	# 指の付け根から指先までを描画（太い線で繋ぐ代わりに、多角形で指のシルエットを作る）
	_draw_hand_fingers(left_palm, l_fingers, skin_color, shadow_color)
	_draw_hand_fingers(right_palm, r_fingers, skin_color, shadow_color)

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
