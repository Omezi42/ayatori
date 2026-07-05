extends Node2D

func _draw() -> void:
	var color = Color(1.0, 1.0, 1.0, 0.9)
	var shadow = Color(0, 0, 0, 0.2)
	
	# ドロップシャドウ
	draw_circle(Vector2(0, 4), 16, shadow)
	draw_circle(Vector2(0, 24), 22, shadow)
	
	# 本体
	draw_circle(Vector2(0, 0), 15, color)  # 人差し指
	draw_circle(Vector2(0, 20), 20, color) # 手のひら
	draw_circle(Vector2(-15, 25), 10, color) # 親指
