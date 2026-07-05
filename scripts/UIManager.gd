class_name UIManager extends CanvasLayer

@export var string_manager: StringManager
@export var undo_button: Button
@export var reset_button: Button
@export var share_button: Button
@export var level_label: Label
@export var message_label: Label

@onready var goal_panel: PanelContainer = $Control/GoalPanel
@onready var goal_texture: TextureRect = $Control/GoalPanel/VBoxContainer/GoalTextureRect

# リセット用に現在のレベルの初期状態を保持
var _current_initial_state: Array[int] = [0, 4, 5, 9]

signal next_level_requested
signal guide_toggled(is_visible: bool)

var clear_particles: CPUParticles2D
var clear_sound: AudioStreamPlayer
var result_panel: PanelContainer
var next_button: Button

var ui_target_drawer: TargetDrawer
var guide_enabled: bool = false

func _ready() -> void:
	_setup_dynamic_nodes()
	_apply_premium_styles()
	if undo_button:
		undo_button.text = "↩ Undo"
		_setup_button_animations(undo_button)
		undo_button.pressed.connect(_on_undo_pressed)
	if reset_button:
		reset_button.text = "↺ Reset"
		_setup_button_animations(reset_button)
		reset_button.pressed.connect(_on_reset_pressed)
	if share_button:
		share_button.text = "🔗 Share"
		_setup_button_animations(share_button)
		share_button.pressed.connect(_on_share_pressed)
		
	if message_label:
		message_label.text = ""
		message_label.modulate.a = 0.0
		message_label.scale = Vector2(0.5, 0.5)
	
	share_button.hide() # 初期状態ではメインUIのシェアボタンを隠す

func _setup_dynamic_nodes() -> void:
	clear_particles = CPUParticles2D.new()
	clear_particles.emitting = false
	clear_particles.one_shot = true
	clear_particles.amount = 80
	clear_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	clear_particles.emission_rect_extents = Vector2(640, 10)
	clear_particles.direction = Vector2(0, -1)
	clear_particles.spread = 90
	clear_particles.gravity = Vector2(0, 980)
	clear_particles.initial_velocity_min = 400
	clear_particles.initial_velocity_max = 800
	clear_particles.scale_amount_min = 10
	clear_particles.scale_amount_max = 20
	clear_particles.position = Vector2(640, 720)
	clear_particles.color = Color(1.0, 0.8, 0.9)
	add_child(clear_particles)
	
	clear_sound = AudioStreamPlayer.new()
	add_child(clear_sound)
	
	result_panel = PanelContainer.new()
	result_panel.visible = false
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_panel.custom_minimum_size = Vector2(400, 300)
	$Control.add_child(result_panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	result_panel.add_child(vbox)
	
	next_button = Button.new()
	next_button.text = "つぎへ"
	next_button.add_theme_font_size_override("font_size", 32)
	next_button.pressed.connect(_on_next_pressed)
	vbox.add_child(next_button)
	
	var res_share_btn = Button.new()
	res_share_btn.text = "シェアする"
	res_share_btn.add_theme_font_size_override("font_size", 32)
	res_share_btn.pressed.connect(_on_share_pressed)
	vbox.add_child(res_share_btn)
	
	var guide_toggle_button = CheckButton.new()
	guide_toggle_button.text = "ガイドを表示"
	guide_toggle_button.button_pressed = false
	guide_toggle_button.toggled.connect(func(toggled_on):
		guide_enabled = toggled_on
		guide_toggled.emit(toggled_on)
	)
	$Control.add_child(guide_toggle_button)
	guide_toggle_button.position = Vector2(30, 90)
	guide_toggle_button.add_theme_font_size_override("font_size", 24)
	guide_toggle_button.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	guide_toggle_button.add_theme_color_override("font_pressed_color", Color(0.2, 0.2, 0.2))
	
	ui_target_drawer = TargetDrawer.new()
	var wrapper = Control.new()
	wrapper.custom_minimum_size = Vector2(200, 200)
	wrapper.clip_contents = true
	
	ui_target_drawer.scale = Vector2(0.3, 0.3)
	ui_target_drawer.position = Vector2(100 - (640 * 0.3), 100 - (360 * 0.3))
	
	wrapper.add_child(ui_target_drawer)
	if goal_panel:
		var vbox_target = goal_panel.get_node_or_null("VBoxContainer")
		if vbox_target:
			vbox_target.add_child(wrapper)
	
	if goal_texture:
		goal_texture.hide()

func _apply_premium_styles() -> void:
	# Create a shared StyleBox for buttons
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.98, 0.7, 0.8, 0.9) # Pastel pink
	btn_style.corner_radius_top_left = 24
	btn_style.corner_radius_top_right = 24
	btn_style.corner_radius_bottom_left = 24
	btn_style.corner_radius_bottom_right = 24
	btn_style.shadow_color = Color(0.9, 0.4, 0.6, 0.3)
	btn_style.shadow_size = 4
	btn_style.content_margin_left = 20
	btn_style.content_margin_right = 20
	btn_style.content_margin_top = 10
	btn_style.content_margin_bottom = 10
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(1.0, 0.8, 0.9, 1.0) # Lighter pink
	
	for btn in [undo_button, reset_button, share_button]:
		if btn:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_hover)
			btn.add_theme_stylebox_override("pressed", btn_style)
			btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_constant_override("outline_size", 4)
			btn.add_theme_color_override("font_outline_color", Color(0.9, 0.4, 0.6, 0.8))
			btn.add_theme_color_override("font_hover_color", Color.WHITE)
	
	if level_label:
		var lbl_style = StyleBoxFlat.new()
		lbl_style.bg_color = Color(0.6, 0.8, 0.95, 0.9) # Pastel blue
		lbl_style.corner_radius_top_left = 20
		lbl_style.corner_radius_top_right = 20
		lbl_style.corner_radius_bottom_left = 20
		lbl_style.corner_radius_bottom_right = 20
		lbl_style.shadow_color = Color(0.4, 0.6, 0.9, 0.4)
		lbl_style.shadow_size = 6
		lbl_style.content_margin_left = 24
		lbl_style.content_margin_right = 24
		lbl_style.content_margin_top = 8
		lbl_style.content_margin_bottom = 8
		level_label.add_theme_stylebox_override("normal", lbl_style)
		level_label.add_theme_color_override("font_color", Color.WHITE)
		# Add outline for text
		level_label.add_theme_constant_override("outline_size", 4)
		level_label.add_theme_color_override("font_outline_color", Color(0.3, 0.5, 0.8, 0.8))
		
	if goal_panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(1.0, 0.98, 0.9, 0.95) # Cream color
		panel_style.corner_radius_top_left = 24
		panel_style.corner_radius_top_right = 24
		panel_style.corner_radius_bottom_left = 24
		panel_style.corner_radius_bottom_right = 24
		panel_style.shadow_color = Color(0.8, 0.8, 0.8, 0.5)
		panel_style.shadow_size = 8
		panel_style.content_margin_left = 16
		panel_style.content_margin_right = 16
		panel_style.content_margin_top = 16
		panel_style.content_margin_bottom = 16
		goal_panel.add_theme_stylebox_override("panel", panel_style)
		
	if result_panel:
		var rp_style = StyleBoxFlat.new()
		rp_style.bg_color = Color(1.0, 0.95, 0.95, 0.95)
		rp_style.corner_radius_top_left = 32
		rp_style.corner_radius_top_right = 32
		rp_style.corner_radius_bottom_left = 32
		rp_style.corner_radius_bottom_right = 32
		rp_style.shadow_color = Color(0.8, 0.8, 0.8, 0.5)
		rp_style.shadow_size = 12
		result_panel.add_theme_stylebox_override("panel", rp_style)
		
		var res_vbox = result_panel.get_child(0)
		for btn in res_vbox.get_children():
			if btn is Button:
				btn.add_theme_stylebox_override("normal", btn_style)
				btn.add_theme_stylebox_override("hover", btn_hover)
				btn.add_theme_stylebox_override("pressed", btn_style)
				btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
				btn.add_theme_color_override("font_color", Color.WHITE)
				btn.add_theme_constant_override("outline_size", 4)
				btn.add_theme_color_override("font_outline_color", Color(0.9, 0.4, 0.6, 0.8))
				_setup_button_animations(btn)

func _setup_button_animations(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(func(): _animate_button(btn, Vector2(1.05, 1.05)))
	btn.mouse_exited.connect(func(): _animate_button(btn, Vector2(1.0, 1.0)))
	btn.button_down.connect(func(): _animate_button(btn, Vector2(0.95, 0.95)))
	btn.button_up.connect(func():
		if btn.is_hovered():
			_animate_button(btn, Vector2(1.05, 1.05))
		else:
			_animate_button(btn, Vector2(1.0, 1.0))
	)

func _animate_button(btn: Button, target_scale: Vector2) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, 0.3)

func update_level_text(level_num: int, level_name: String = "") -> void:
	if level_label:
		if level_name.is_empty():
			level_label.text = "Level " + str(level_num)
		else:
			level_label.text = "Lv." + str(level_num) + " " + level_name

func set_goal_texture(texture: Texture2D) -> void:
	if goal_texture:
		goal_texture.texture = texture
		if texture:
			goal_texture.show()
			# 画像がある場合は、線のTargetDrawerを隠す（オプション）
			if ui_target_drawer:
				ui_target_drawer.hide()
		else:
			goal_texture.hide()
			if ui_target_drawer:
				ui_target_drawer.show()

func set_goal_sequence(sequence: Array[int]) -> void:
	if ui_target_drawer:
		ui_target_drawer.set_target(sequence)

# MainControllerから現在のレベルの初期状態を受け取る
func set_initial_state(state: Array[int]) -> void:
	_current_initial_state = state.duplicate()

func on_game_clear_state() -> void:
	pass

func play_clear_animation() -> void:
	if clear_sound:
		clear_sound.play()
	if clear_particles:
		clear_particles.emitting = true
		
	if message_label:
		message_label.text = "クリア！よくできました！"
		message_label.scale = Vector2.ZERO
		message_label.modulate.a = 1.0
		
		var tween = create_tween()
		tween.tween_property(message_label, "scale", Vector2(1.2, 1.2), 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(message_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func show_result_panel() -> void:
	if result_panel:
		result_panel.show()
		result_panel.scale = Vector2.ZERO
		result_panel.pivot_offset = result_panel.size / 2.0
		var tween = create_tween()
		tween.tween_property(result_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_next_pressed() -> void:
	if result_panel:
		result_panel.hide()
	if message_label:
		message_label.modulate.a = 0.0
	next_level_requested.emit()

func show_message(msg: String) -> void:
	if message_label:
		message_label.text = msg
		# Reset state for animation
		message_label.scale = Vector2(0.5, 0.5)
		message_label.modulate.a = 0.0
		
		var tween = create_tween().set_parallel(true)
		# Pop in
		tween.tween_property(message_label, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(message_label, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# Fade out after delay
		tween.chain().tween_interval(1.5)
		var fade_out_tween = create_tween().set_parallel(true)
		fade_out_tween.tween_property(message_label, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		fade_out_tween.tween_property(message_label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _on_undo_pressed() -> void:
	if string_manager:
		string_manager.undo()

func _on_reset_pressed() -> void:
	if string_manager:
		# 現在のレベルの初期状態に戻す
		string_manager.reset_to_initial(_current_initial_state.duplicate())

func _on_share_pressed() -> void:
	# WebGLでのみ動作するJavaScript呼び出し
	if OS.has_feature("web"):
		var text = "「あやとりパズル -ゆびさきキャンバス-」で遊びました！"
		var url = "https://unityroom.com/games/ayatori_puzzle" # 仮のURL
		var x_intent = "https://twitter.com/intent/tweet?text=" + text.uri_encode() + "&url=" + url.uri_encode()
		
		# 新しいタブでXのシェア画面を開く
		JavaScriptBridge.eval("window.open('%s', '_blank');" % x_intent)
	else:
		print("X Share: ", "「あやとりパズル -ゆびさきキャンバス-」で遊びました！")
