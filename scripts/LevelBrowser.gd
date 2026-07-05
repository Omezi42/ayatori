extends Control

@onready var list_vbox = $VBoxContainer/ScrollContainer/ListVBox
@onready var search_input = $VBoxContainer/SearchHBox/SearchInput
@onready var sort_option = $VBoxContainer/SearchHBox/SortOption
@onready var loading_label = $LoadingLabel

func _ready() -> void:
	# UIセットアップ
	sort_option.add_item("新着順")
	sort_option.add_item("人気順")
	
	$VBoxContainer/HeaderHBox/BackButton.pressed.connect(_on_back_pressed)
	$VBoxContainer/HeaderHBox/CreateButton.pressed.connect(_on_create_pressed)
	$VBoxContainer/SearchHBox/SearchButton.pressed.connect(_on_search_pressed)
	
	FirebaseManager.levels_fetched.connect(_on_levels_fetched)
	FirebaseManager.fetch_failed.connect(_on_fetch_failed)
	
	FirebaseManager.load_completed.connect(_on_level_loaded)
	FirebaseManager.load_failed.connect(_on_load_failed)
	
	_fetch_data()

func _fetch_data() -> void:
	loading_label.text = "読込中..."
	loading_label.show()
	for child in list_vbox.get_children():
		child.queue_free()
		
	var sort_type = "newest"
	if sort_option.selected == 1:
		sort_type = "popular"
		
	FirebaseManager.fetch_levels(sort_type, search_input.text.strip_edges())

func _on_search_pressed() -> void:
	_fetch_data()

func _on_levels_fetched(levels: Array) -> void:
	loading_label.hide()
	for level in levels:
		var panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color.WHITE
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.content_margin_left = 20
		style.content_margin_right = 20
		style.content_margin_top = 15
		style.content_margin_bottom = 15
		style.shadow_color = Color(0,0,0,0.1)
		style.shadow_size = 4
		panel.add_theme_stylebox_override("panel", style)
		
		var hbox = HBoxContainer.new()
		panel.add_child(hbox)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var title_label = Label.new()
		title_label.text = level["title"]
		title_label.add_theme_font_size_override("font_size", 28)
		title_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
		info_vbox.add_child(title_label)
		
		var meta_label = Label.new()
		meta_label.text = "コード: " + level["code"] + "  |  プレイ数: " + str(level["play_count"])
		meta_label.add_theme_font_size_override("font_size", 18)
		meta_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		info_vbox.add_child(meta_label)
		
		var play_btn = Button.new()
		play_btn.text = " 遊ぶ "
		play_btn.custom_minimum_size = Vector2(120, 0)
		play_btn.add_theme_font_size_override("font_size", 24)
		play_btn.pressed.connect(func(): _play_level(level["code"], play_btn))
		hbox.add_child(play_btn)
		
		list_vbox.add_child(panel)
		
	if levels.size() == 0:
		loading_label.text = "お題が見つかりませんでした"
		loading_label.show()

func _on_fetch_failed(err: String) -> void:
	loading_label.text = "エラー: " + err
	loading_label.show()

func _play_level(code: String, btn: Button) -> void:
	btn.text = "読込中"
	btn.disabled = true
	FirebaseManager.load_level(code)

func _on_level_loaded(target_sequence: Array, layout_id: int) -> void:
	FirebaseManager.set_meta("ugc_target", target_sequence)
	FirebaseManager.set_meta("ugc_layout_id", layout_id)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_load_failed(err: String) -> void:
	print("Load Failed: ", err)
	loading_label.text = "エラー: " + err
	loading_label.show()
	await get_tree().create_timer(1.5).timeout
	_fetch_data()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Title.tscn")

func _on_create_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelEditor.tscn")
