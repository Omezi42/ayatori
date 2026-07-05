class_name UIManager extends CanvasLayer

@export var string_manager: StringManager
@export var undo_button: Button
@export var reset_button: Button
@export var share_button: Button
@export var level_label: Label
@export var message_label: Label

@export var moves_label: Label

@onready var goal_panel: PanelContainer = get_node_or_null("Control/HeaderHBox/GoalPanel")
@onready var goal_texture: TextureRect = get_node_or_null("Control/HeaderHBox/GoalPanel/VBoxContainer/GoalTextureRect")
@onready var clear_dim_rect: ColorRect = get_node_or_null("Control/ClearDimRect")
@onready var transition_rect: ColorRect = get_node_or_null("Control/TransitionRect")

# リセット用に現在のレベルの初期状態を保持
var _current_initial_state: Array[int] = [0, 4, 5, 9]

signal next_level_requested
signal guide_toggled(is_visible: bool)
signal hint_requested

var clear_particles: CPUParticles2D
var clear_sound: AudioStreamPlayer
var result_panel: PanelContainer
var next_button: Button
var result_stars_label: Label

var ui_target_drawer: TargetDrawer
var guide_enabled: bool = false

var settings_panel: PanelContainer
var share_panel: PanelContainer
var ingame_share_btn: Button
var settings_btn: Button
var hint_button: Button

func _ready() -> void:
	# 画面遷移アニメーション
	if transition_rect:
		transition_rect.show()
		transition_rect.modulate.a = 1.0
		var trans_tween = create_tween()
		trans_tween.tween_property(transition_rect, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		trans_tween.tween_callback(transition_rect.hide)

	if goal_panel:
		goal_panel.rotation = 0.05 # ポラロイド風に少し傾ける
	
	_setup_dynamic_nodes()
	_setup_floating_menus()
	
	if undo_button:
		undo_button.text = "一つ戻る"
		var undo_tex = load("res://assets/ic_system_rotate-counterclockwise_01_trimmed.svg")
		if undo_tex:
			undo_button.icon = undo_tex
			undo_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			undo_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			undo_button.add_theme_constant_override("icon_max_width", 32)
		_setup_button_animations(undo_button)
		undo_button.pressed.connect(_on_undo_pressed)
	if reset_button:
		reset_button.text = "リセット"
		var reset_tex = load("res://assets/ic_system_refresh_01_trimmed.svg")
		if reset_tex:
			reset_button.icon = reset_tex
			reset_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			reset_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			reset_button.add_theme_constant_override("icon_max_width", 32)
		_setup_button_animations(reset_button)
		reset_button.pressed.connect(_on_reset_pressed)
	if share_button:
		_setup_button_animations(share_button)
		share_button.pressed.connect(_on_share_pressed)
		share_button.hide() # 初期状態ではメインUIのシェアボタンを隠す
		
	if message_label:
		message_label.text = ""
		message_label.modulate.a = 0.0
		message_label.scale = Vector2(0.5, 0.5)
	
	hint_button = Button.new()
	hint_button.text = "ヒント"
	var hint_tex = load("res://assets/ic_social_lightbulb_01_trimmed.svg")
	if hint_tex:
		hint_button.icon = hint_tex
		hint_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		hint_button.add_theme_constant_override("icon_max_width", 32)
	hint_button.add_theme_font_size_override("font_size", 24)
	var footer = get_node_or_null("Control/FooterHBox")
	if footer:
		footer.add_child(hint_button)
		footer.move_child(hint_button, 0)
	hint_button.pressed.connect(func(): hint_requested.emit())
	
	_apply_premium_styles()

func _setup_floating_menus() -> void:
	var menu_hbox = HBoxContainer.new()
	# 右下にフローティング配置
	menu_hbox.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	menu_hbox.position = Vector2(1150, 620)
	menu_hbox.add_theme_constant_override("separation", 15)
	$Control.add_child(menu_hbox)

	settings_btn = Button.new()
	settings_btn.text = ""
	var gear_tex = load("res://resources/gear_icon.svg")
	if gear_tex:
		settings_btn.icon = gear_tex
		settings_btn.add_theme_constant_override("icon_max_width", 32)
	settings_btn.add_theme_color_override("icon_normal_color", Color.WHITE)
	settings_btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	settings_btn.add_theme_color_override("icon_pressed_color", Color.WHITE)
	settings_btn.pressed.connect(func(): 
		settings_panel.visible = !settings_panel.visible
		share_panel.visible = false
	)
	menu_hbox.add_child(settings_btn)

	ingame_share_btn = Button.new()
	ingame_share_btn.text = ""
	var share_tex = load("res://resources/share_icon.svg")
	if share_tex:
		ingame_share_btn.icon = share_tex
		ingame_share_btn.add_theme_constant_override("icon_max_width", 32)
	ingame_share_btn.add_theme_color_override("icon_normal_color", Color.WHITE)
	ingame_share_btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	ingame_share_btn.add_theme_color_override("icon_pressed_color", Color.WHITE)
	ingame_share_btn.pressed.connect(func(): 
		share_panel.visible = !share_panel.visible
		settings_panel.visible = false
	)
	menu_hbox.add_child(ingame_share_btn)
	
	share_panel = PanelContainer.new()
	share_panel.visible = false
	share_panel.position = Vector2(850, 520)
	var share_vbox = VBoxContainer.new()
	share_panel.add_child(share_vbox)
	
	var save_btn = Button.new()
	save_btn.text = "画像として保存/コピー"
	save_btn.pressed.connect(_on_save_image_pressed)
	share_vbox.add_child(save_btn)
	
	var x_btn = Button.new()
	x_btn.text = "Xに投稿する"
	x_btn.pressed.connect(_on_share_pressed)
	share_vbox.add_child(x_btn)
	
	$Control.add_child(share_panel)
	
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.custom_minimum_size = Vector2(300, 200)
	settings_panel.position = Vector2(850, 400)
	var set_vbox = VBoxContainer.new()
	settings_panel.add_child(set_vbox)
	
	var guide_label = Label.new()
	guide_label.text = "【ルール】\n指にかかっている糸をドラッグして\n別の指にかけたり、\nタップして外したりして\n右上の目標の形を作りましょう！\n\n少ない手数で完成させると\n星をたくさんもらえます。"
	guide_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	set_vbox.add_child(guide_label)
	
	var vol_label = Label.new()
	vol_label.text = "音量"
	vol_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	set_vbox.add_child(vol_label)
	
	var vol_slider = HSlider.new()
	vol_slider.value = 50
	vol_slider.value_changed.connect(_on_volume_changed)
	set_vbox.add_child(vol_slider)
	
	var theme_label = Label.new()
	theme_label.text = "画面テーマ"
	theme_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	set_vbox.add_child(theme_label)
	
	var theme_btn = OptionButton.new()
	theme_btn.add_item("通常")
	theme_btn.add_item("モノクロ")
	theme_btn.add_item("ダーク")
	if GameSave: theme_btn.selected = GameSave.current_theme
	theme_btn.item_selected.connect(func(idx):
		if GameSave:
			GameSave.current_theme = idx
			GameSave.apply_theme()
			GameSave.save_data()
	)
	set_vbox.add_child(theme_btn)
	
	$Control.add_child(settings_panel)

func _setup_dynamic_nodes() -> void:
	var p_left = CPUParticles2D.new()
	p_left.emitting = false
	p_left.one_shot = true
	p_left.amount = 60
	p_left.direction = Vector2(1, -1.5).normalized()
	p_left.spread = 25
	p_left.gravity = Vector2(0, 980)
	p_left.initial_velocity_min = 600
	p_left.initial_velocity_max = 1000
	p_left.scale_amount_min = 12
	p_left.scale_amount_max = 24
	p_left.position = Vector2(0, 720)
	var grad = Gradient.new()
	grad.colors = [Color(1, 0.5, 0.5), Color(0.5, 1, 0.5), Color(0.5, 0.5, 1), Color(1, 1, 0.5), Color(1, 0.5, 1)]
	grad.offsets = [0.0, 0.25, 0.5, 0.75, 1.0]
	p_left.color_initial_ramp = grad
	add_child(p_left)
	
	var p_right = p_left.duplicate()
	p_right.position = Vector2(1280, 720)
	p_right.direction = Vector2(-1, -1.5).normalized()
	add_child(p_right)
	
	clear_particles = p_left
	clear_particles.set_meta("partner", p_right)
	
	clear_sound = AudioStreamPlayer.new()
	add_child(clear_sound)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Control.add_child(center_container)
	
	result_panel = PanelContainer.new()
	result_panel.visible = false
	result_panel.custom_minimum_size = Vector2(400, 300)
	center_container.add_child(result_panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	result_panel.add_child(vbox)
	
	result_stars_label = Label.new()
	result_stars_label.add_theme_font_size_override("font_size", 72)
	result_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	result_stars_label.add_theme_color_override("font_outline_color", Color(0.8, 0.4, 0.1, 0.9))
	result_stars_label.add_theme_constant_override("outline_size", 12)
	result_stars_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.2))
	result_stars_label.add_theme_constant_override("shadow_offset_x", 0)
	result_stars_label.add_theme_constant_override("shadow_offset_y", 6)
	vbox.add_child(result_stars_label)
	
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
	guide_toggle_button.position = Vector2(30, 20) # Headerの下あたりに配置
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
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.92, 0.62, 0.75, 0.95)
	btn_style.corner_radius_top_left = 32
	btn_style.corner_radius_top_right = 32
	btn_style.corner_radius_bottom_left = 32
	btn_style.corner_radius_bottom_right = 32
	btn_style.shadow_color = Color(0.8, 0.35, 0.5, 0.3)
	btn_style.shadow_size = 4
	btn_style.content_margin_left = 20
	btn_style.content_margin_right = 20
	btn_style.content_margin_top = 10
	btn_style.content_margin_bottom = 10
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.96, 0.72, 0.82, 1.0)
	
	for btn in [hint_button, undo_button, reset_button, share_button, settings_btn, ingame_share_btn]:
		if btn:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_hover)
			btn.add_theme_stylebox_override("pressed", btn_style)
			btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_constant_override("outline_size", 4)
			btn.add_theme_color_override("font_outline_color", Color(0.7, 0.4, 0.5, 0.8))
			btn.add_theme_color_override("font_hover_color", Color.WHITE)
			btn.add_theme_color_override("icon_normal_color", Color.WHITE)
			btn.add_theme_color_override("icon_pressed_color", Color.WHITE)
			btn.add_theme_color_override("icon_hover_color", Color.WHITE)
			if btn == settings_btn or btn == ingame_share_btn:
				_setup_button_animations(btn)
	
	# InfoPanel (Top Left) Style
	if has_node("Control/HeaderHBox/InfoPanel"):
		var info_panel = $Control/HeaderHBox/InfoPanel
		var info_style = StyleBoxFlat.new()
		info_style.bg_color = Color(1.0, 1.0, 1.0, 0.8)
		info_style.corner_radius_top_left = 16
		info_style.corner_radius_top_right = 16
		info_style.corner_radius_bottom_left = 16
		info_style.corner_radius_bottom_right = 16
		info_style.shadow_color = Color(0, 0, 0, 0.1)
		info_style.shadow_size = 4
		info_style.content_margin_left = 20
		info_style.content_margin_right = 20
		info_style.content_margin_top = 10
		info_style.content_margin_bottom = 10
		info_panel.add_theme_stylebox_override("panel", info_style)

		# Make Level/Moves Labels dark for contrast against white panel
		if level_label:
			level_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
		if moves_label:
			moves_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		
	# Polaroid Style for GoalPanel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 1.0, 1.0, 1.0) # Pure white for polaroid frame
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.15)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(2, 6)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 32 # extra bottom margin for polaroid

	if goal_panel:
		goal_panel.add_theme_stylebox_override("panel", panel_style)
		
	if settings_panel:
		settings_panel.add_theme_stylebox_override("panel", panel_style)
	if share_panel:
		share_panel.add_theme_stylebox_override("panel", panel_style)
		var share_vbox = share_panel.get_child(0)
		for btn in share_vbox.get_children():
			if btn is Button:
				btn.add_theme_stylebox_override("normal", btn_style)
				btn.add_theme_stylebox_override("hover", btn_hover)
				btn.add_theme_stylebox_override("pressed", btn_style)
				btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
				btn.add_theme_color_override("font_color", Color.WHITE)
				btn.add_theme_constant_override("outline_size", 4)
				btn.add_theme_color_override("font_outline_color", Color(0.7, 0.4, 0.5, 0.8))
				_setup_button_animations(btn)
		
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
				btn.add_theme_color_override("font_outline_color", Color(0.7, 0.4, 0.5, 0.8))
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
			level_label.text = "LEVEL " + str(level_num)
		else:
			level_label.text = "LV." + str(level_num) + " " + level_name

func update_moves_display(moves: int, optimal: int) -> void:
	if not moves_label:
		return
	var stars = 3
	if moves > optimal:
		if moves <= optimal + 2:
			stars = 2
		else:
			stars = 1
			
	var stars_text = ""
	for i in range(stars):
		stars_text += "★"
	for i in range(3 - stars):
		stars_text += "☆"
		
	moves_label.text = "手数: %d / 最短: %d\n%s" % [moves, optimal, stars_text]

func set_result_stars(stars: int) -> void:
	if result_stars_label:
		var stars_text = ""
		for i in range(stars):
			stars_text += "★"
		for i in range(3 - stars):
			stars_text += "☆"
		var total = 0
		if GameSave: total = GameSave.total_stars
		result_stars_label.text = stars_text + "\n累計: " + str(total) + " ★"
		result_stars_label.add_theme_font_size_override("font_size", 48)

func _animate_goal_bounce() -> void:
	if goal_panel:
		goal_panel.scale = Vector2.ZERO
		goal_panel.pivot_offset = goal_panel.size / 2.0
		var tw = create_tween()
		tw.tween_property(goal_panel, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func set_goal_texture(texture: Texture2D) -> void:
	if goal_texture:
		goal_texture.texture = texture
		if texture:
			goal_texture.show()
			if ui_target_drawer:
				ui_target_drawer.hide()
			_animate_goal_bounce()
		else:
			goal_texture.hide()
			if ui_target_drawer:
				ui_target_drawer.show()

func set_goal_sequence(sequence: Array[int]) -> void:
	if ui_target_drawer:
		ui_target_drawer.set_target(sequence)
		if goal_texture and not goal_texture.visible:
			_animate_goal_bounce()

func set_initial_state(state: Array[int]) -> void:
	_current_initial_state = state.duplicate()

func on_game_clear_state() -> void:
	pass

func play_clear_animation() -> void:
	if clear_sound:
		clear_sound.play()
	if clear_particles:
		clear_particles.emitting = true
		if clear_particles.has_meta("partner"):
			clear_particles.get_meta("partner").emitting = true
	
	if clear_dim_rect:
		var dim_tw = create_tween()
		dim_tw.tween_property(clear_dim_rect, "color:a", 0.6, 0.5).set_trans(Tween.TRANS_SINE)
		
	if message_label:
		message_label.text = "クリア！"
		message_label.pivot_offset = message_label.size / 2.0
		message_label.scale = Vector2.ZERO
		message_label.rotation = -0.2
		message_label.modulate.a = 1.0
		message_label.self_modulate = Color(1, 1, 1, 1)
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(message_label, "scale", Vector2(1.3, 1.3), 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(message_label, "rotation", 0.05, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(message_label, "self_modulate", Color(1.0, 0.9, 0.4), 0.5)
		
		var seq = create_tween()
		seq.tween_interval(0.4)
		seq.tween_property(message_label, "rotation", -0.02, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		seq.tween_property(message_label, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		seq.tween_property(message_label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func show_result_panel() -> void:
	if result_panel:
		result_panel.show()
		result_panel.scale = Vector2.ZERO
		result_panel.pivot_offset = Vector2(200, 150)
		var tween = create_tween()
		tween.tween_property(result_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_next_pressed() -> void:
	if result_panel:
		result_panel.hide()
	if message_label:
		message_label.modulate.a = 0.0
	if clear_dim_rect:
		var tw = create_tween()
		tw.tween_property(clear_dim_rect, "color:a", 0.0, 0.3)
	
	# Transition before next level
	if transition_rect:
		transition_rect.show()
		var tw = create_tween()
		tw.tween_property(transition_rect, "modulate:a", 1.0, 0.3)
		tw.tween_callback(func():
			next_level_requested.emit()
			# will fade out again when new level loads if we reset scene or we can just fade out here
			var tw2 = create_tween()
			tw2.tween_property(transition_rect, "modulate:a", 0.0, 0.5)
			tw2.tween_callback(transition_rect.hide)
		)
	else:
		next_level_requested.emit()

func show_message(msg: String) -> void:
	if message_label:
		message_label.text = msg
		message_label.scale = Vector2(0.5, 0.5)
		message_label.modulate.a = 0.0
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(message_label, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(message_label, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		tween.chain().tween_interval(1.5)
		var fade_out_tween = create_tween().set_parallel(true)
		fade_out_tween.tween_property(message_label, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		fade_out_tween.tween_property(message_label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _on_undo_pressed() -> void:
	if string_manager:
		string_manager.undo()

func _on_reset_pressed() -> void:
	if string_manager:
		string_manager.reset_to_initial(_current_initial_state.duplicate())

func _on_save_image_pressed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("alert('画像の保存機能はWebブラウザの制限により準備中です。スクショ等をご利用ください。');")
	else:
		print("Save Image")

func _on_volume_changed(val: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))

func _on_share_pressed() -> void:
	if OS.has_feature("web"):
		var text = "「あやとりパズル -ゆびさきキャンバス-」で遊びました！"
		var url = "https://unityroom.com/games/ayatori_puzzle"
		var x_intent = "https://twitter.com/intent/tweet?text=" + text.uri_encode() + "&url=" + url.uri_encode()
		JavaScriptBridge.eval("window.open('%s', '_blank');" % x_intent)
	else:
		print("X Share: ", "「あやとりパズル -ゆびさきキャンバス-」で遊びました！")
