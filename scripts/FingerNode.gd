class_name FingerNode extends Area2D

@export var finger_id: int = 0
signal finger_clicked(id)
signal finger_dropped_on(id)

func _ready() -> void:
	# Area2Dの入力イベントを拾う
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_animate_scale(Vector2(1.2, 1.2))

func _on_mouse_exited() -> void:
	_animate_scale(Vector2(1.0, 1.0))

func _animate_scale(target_scale: Vector2) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.3)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_animate_scale(Vector2(0.9, 0.9))
			finger_clicked.emit(finger_id)
		else:
			if is_hovered():
				_animate_scale(Vector2(1.2, 1.2))
			else:
				_animate_scale(Vector2(1.0, 1.0))
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
