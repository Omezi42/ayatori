class_name TargetDrawer extends Control

var target_sequence: Array[int] = []

# 固定された指の座標

var layout_id: int = 0

func _ready() -> void:
	if GameSave and not GameSave.customization_changed.is_connected(queue_redraw):
		GameSave.customization_changed.connect(queue_redraw)

func set_layout(new_layout_id: int) -> void:
	layout_id = new_layout_id
	queue_redraw()

func set_target(sequence: Array[int]) -> void:
	target_sequence = sequence
	queue_redraw()

func apply_theme_colors() -> void:
	queue_redraw()

func _draw() -> void:
	var finger_positions = PinLayout.get_positions(layout_id)
	var base_pin_col = GameSave.get_current_pin_color() if GameSave else ThemeConfig.finger_main
	var inactive_pin_col = base_pin_col.darkened(0.2)
	inactive_pin_col.a = 0.5
	for pos in finger_positions:
		draw_circle(pos, 15.0, inactive_pin_col)
	
	if target_sequence.size() < 2:
		return
	
	var points = PackedVector2Array()
	var active_pin_col = base_pin_col.lightened(0.15)
	active_pin_col.a = 0.8
	for idx in target_sequence:
		if idx >= 0 and idx < finger_positions.size():
			points.append(finger_positions[idx])
			draw_circle(finger_positions[idx], 20.0, active_pin_col)
			
	if points.size() > 0:
		points.append(points[0]) # 閉じたループにする
		
	var target_col = GameSave.get_current_string_target_color() if GameSave else ThemeConfig.string_target
	draw_polyline(points, target_col, 12.0, true)
