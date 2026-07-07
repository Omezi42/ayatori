class_name FingerNode extends Area2D

@export var finger_id: int = 0
signal finger_clicked(id)
signal finger_dropped_on(id)

var base_scale: Vector2 = Vector2(1.0, 1.0)
var is_drag_highlighted: bool = false

var loop_count: int = 0

func set_loop_count(count: int) -> void:
	if loop_count != count:
		loop_count = count
		queue_redraw()

func set_base_scale(new_scale: Vector2) -> void:
	base_scale = new_scale
	scale = base_scale


func _ready() -> void:
	# Area2Dの入力イベントを拾う
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if GameSave:
		GameSave.customization_changed.connect(queue_redraw)

func apply_theme_colors() -> void:
	queue_redraw()

func _on_mouse_entered() -> void:
	_animate_scale(base_scale * 1.2)

func _on_mouse_exited() -> void:
	_animate_scale(base_scale)


func _animate_scale(target_scale: Vector2) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.3)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_animate_scale(base_scale * 0.9)
			finger_clicked.emit(finger_id)
		else:
			if is_hovered():
				_animate_scale(base_scale * 1.2)
			else:
				_animate_scale(base_scale)

			# ドラッグ完了時のドロップ判定用
			finger_dropped_on.emit(finger_id)

func is_hovered() -> bool:
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	var results = space.intersect_point(query)
	for res in results:
		if res.collider == self:
			return true
	return false

func set_highlight(highlighted: bool) -> void:
	if is_drag_highlighted == highlighted:
		return
	is_drag_highlighted = highlighted
	if is_drag_highlighted:
		_animate_scale(base_scale * 1.3)
	else:
		if is_hovered():
			_animate_scale(base_scale * 1.2)
		else:
			_animate_scale(base_scale)
		queue_redraw()

func _draw() -> void:
	var radius = 40.0
	var main_color = GameSave.get_current_pin_color()
	if is_drag_highlighted:
		main_color = main_color.lightened(0.2)
	
	var shadow_color = Color(0, 0, 0, 0.1)
	var shine_color = GameSave.get_current_pin_shine()
	
	# ドロップシャドウ
	draw_circle(Vector2(0, 8), radius, shadow_color)
	
	# メインの円
	draw_circle(Vector2.ZERO, radius, main_color)
	
	# ぷっくりしたハイライト（ツヤ）
	draw_circle(Vector2(-12, -12), radius * 0.3, shine_color)
	draw_circle(Vector2(-20, -4), radius * 0.1, shine_color)
	
	if GameSave.is_playing_advanced_level and loop_count >= 2:
		var font = ThemeDB.fallback_font
		if font:
			var text = "x" + str(loop_count)
			var font_size = 24
			var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var text_pos = Vector2(radius + 10, text_size.y * 0.3)
			draw_string_outline(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color.BLACK)
			draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
