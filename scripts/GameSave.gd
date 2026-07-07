extends Node

signal customization_changed

var total_stars: int = 0
var current_theme: int = 0 # 0: Normal, 1: Monochrome, 2: Dark
var liked_levels: Array = []
var daily_stamps: Array = []
var level_stars: Dictionary = {}

var unlocked_pins: Array = [0]
var current_pin: int = 0
var unlocked_bgs: Array = [0]
var current_bg: int = 0
var unlocked_strings: Array = [0]
var current_string: int = 0
var is_advanced_mode: bool = false
var active_rules: Dictionary = {}
var is_playing_advanced_level: bool = false
var playing_active_rules: Dictionary = {}


const PIN_ITEMS = [
	{"id": 0, "name": "パステルピンク", "price": 0, "color": Color("#FFB6C1"), "shine": Color(1, 1, 1, 0.6)},
	{"id": 1, "name": "スカイサファイア", "price": 15, "color": Color("#87CEEB"), "shine": Color(1, 1, 1, 0.7)},
	{"id": 2, "name": "ミントエメラルド", "price": 30, "color": Color("#98FB98"), "shine": Color(1, 1, 1, 0.7)},
	{"id": 3, "name": "サンシャインゴールド", "price": 50, "color": Color("#FFD700"), "shine": Color("#FFF8DC")},
	{"id": 4, "name": "ミスティックアメジスト", "price": 80, "color": Color("#E0B0FF"), "shine": Color(1, 1, 1, 0.8)},
	{"id": 5, "name": "スターライトホワイト", "price": 120, "color": Color("#FFFFFF"), "shine": Color("#E6E6FA")}
]

const BG_ITEMS = [
	{"id": 0, "name": "ウォームクリーム", "price": 0, "bg_color": Color("#FFF8E7"), "board_color": Color("#E6D8CE")},
	{"id": 1, "name": "サクラガーデン", "price": 15, "bg_color": Color("#FFF0F5"), "board_color": Color("#F5D6E0")},
	{"id": 2, "name": "クリアスカイ", "price": 30, "bg_color": Color("#F0F8FF"), "board_color": Color("#D6EAF8")},
	{"id": 3, "name": "フォレストテラス", "price": 50, "bg_color": Color("#F0F7F4"), "board_color": Color("#D4E6CE")},
	{"id": 4, "name": "トワイライトネオン", "price": 80, "bg_color": Color("#2B2D42"), "board_color": Color("#3D405B")}
]

const STRING_ITEMS = [
	{"id": 0, "name": "スタンダードピンク", "price": 0, "color": Color("#FF849E"), "tense_color": Color("#FFA6C9"), "target_color": Color("#FF849E")},
	{"id": 1, "name": "サンシャインイエロー", "price": 20, "color": Color("#FFD700"), "tense_color": Color("#FFE866"), "target_color": Color("#FFD700")},
	{"id": 2, "name": "オーシャンブルー", "price": 40, "color": Color("#00B4D8"), "tense_color": Color("#48CAE4"), "target_color": Color("#00B4D8")},
	{"id": 3, "name": "エメラルドグリーン", "price": 60, "color": Color("#2EC4B6"), "tense_color": Color("#68D8CD"), "target_color": Color("#2EC4B6")},
	{"id": 4, "name": "マジカルパープル", "price": 100, "color": Color("#9D4EDD"), "tense_color": Color("#C77DFF"), "target_color": Color("#9D4EDD")}
]

const SAVE_PATH = "user://ayatori_save.json"

func _ready() -> void:
	load_data()
	apply_theme()

func save_data() -> void:
	var data = {
		"total_stars": total_stars,
		"current_theme": current_theme,
		"liked_levels": liked_levels,
		"daily_stamps": daily_stamps,
		"level_stars": level_stars,
		"unlocked_pins": unlocked_pins,
		"current_pin": current_pin,
		"unlocked_bgs": unlocked_bgs,
		"current_bg": current_bg,
		"unlocked_strings": unlocked_strings,
		"current_string": current_string,
		"is_advanced_mode": is_advanced_mode,
		"active_rules": active_rules
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			var json = JSON.parse_string(text)
			if json and typeof(json) == TYPE_DICTIONARY:
				if json.has("total_stars"): total_stars = int(json["total_stars"])
				if json.has("current_theme"): current_theme = int(json["current_theme"])
				if json.has("liked_levels"): liked_levels = json["liked_levels"]
				if json.has("daily_stamps"): daily_stamps = json["daily_stamps"]
				if json.has("level_stars"): level_stars = json["level_stars"]
				if json.has("unlocked_pins"): unlocked_pins = json["unlocked_pins"]
				if json.has("current_pin"): current_pin = int(json["current_pin"])
				if json.has("unlocked_bgs"): unlocked_bgs = json["unlocked_bgs"]
				if json.has("current_bg"): current_bg = int(json["current_bg"])
				if json.has("unlocked_strings"): unlocked_strings = json["unlocked_strings"]
				if json.has("current_string"): current_string = int(json["current_string"])
				if json.has("is_advanced_mode"): is_advanced_mode = bool(json["is_advanced_mode"])
				if json.has("active_rules"): 
					active_rules = json["active_rules"]
				else:
					if is_advanced_mode:
						active_rules["multi_loop"] = true

func has_rule(rule_name: String) -> bool:
	if is_playing_advanced_level:
		return playing_active_rules.get(rule_name, false)
	return active_rules.get(rule_name, false)

func is_unlocked(category: String, id: int) -> bool:
	var arr = []
	if category == "pin": arr = unlocked_pins
	elif category == "bg": arr = unlocked_bgs
	elif category == "string": arr = unlocked_strings
	
	for val in arr:
		if int(val) == id:
			return true
	return false

func buy_item(category: String, id: int, price: int) -> bool:
	if total_stars < price:
		return false
	if is_unlocked(category, id):
		return true
	
	total_stars -= price
	if category == "pin": unlocked_pins.append(id)
	elif category == "bg": unlocked_bgs.append(id)
	elif category == "string": unlocked_strings.append(id)
	
	save_data()
	return true

func equip_item(category: String, id: int) -> void:
	if not is_unlocked(category, id):
		return
	
	if category == "pin": current_pin = id
	elif category == "bg": current_bg = id
	elif category == "string": current_string = id
	
	save_data()
	customization_changed.emit()

func get_current_pin_color() -> Color:
	if current_theme != 0:
		return ThemeConfig.finger_main
	for item in PIN_ITEMS:
		if item["id"] == current_pin:
			return item["color"]
	return PIN_ITEMS[0]["color"]

func get_current_pin_shine() -> Color:
	if current_theme != 0:
		return Color(1, 1, 1, 0.4)
	for item in PIN_ITEMS:
		if item["id"] == current_pin:
			return item["shine"]
	return PIN_ITEMS[0]["shine"]

func get_current_bg_color() -> Color:
	if current_theme != 0:
		return ThemeConfig.BG_WARM
	for item in BG_ITEMS:
		if item["id"] == current_bg:
			return item["bg_color"]
	return BG_ITEMS[0]["bg_color"]

func get_current_board_color() -> Color:
	if current_theme != 0:
		return ThemeConfig.board_bg
	for item in BG_ITEMS:
		if item["id"] == current_bg:
			return item["board_color"]
	return BG_ITEMS[0]["board_color"]

func get_current_string_color() -> Color:
	if current_theme != 0:
		return ThemeConfig.string_normal
	for item in STRING_ITEMS:
		if item["id"] == current_string:
			return item["color"]
	return STRING_ITEMS[0]["color"]

func get_current_string_tense_color() -> Color:
	if current_theme != 0:
		return ThemeConfig.string_tense
	for item in STRING_ITEMS:
		if item["id"] == current_string:
			if item.has("tense_color"):
				return item["tense_color"]
			return item["color"].lightened(0.2)
	return STRING_ITEMS[0]["color"].lightened(0.2)

func get_current_string_target_color() -> Color:
	if current_theme != 0:
		return ThemeConfig.string_target
	for item in STRING_ITEMS:
		if item["id"] == current_string:
			if item.has("target_color"):
				return item["target_color"]
			return item["color"]
	return STRING_ITEMS[0]["color"]

func has_liked(code: String) -> bool:
	return liked_levels.has(code)

func add_like_record(code: String) -> void:
	if not liked_levels.has(code):
		liked_levels.append(code)
		save_data()

func mark_daily_cleared(date_str: String) -> void:
	if not daily_stamps.has(date_str):
		daily_stamps.append(date_str)
		save_data()

func has_cleared_daily(date_str: String) -> bool:
	return daily_stamps.has(date_str)

func add_stars(amount: int) -> void:
	total_stars += amount
	save_data()

func save_level_stars(level_name: String, stars: int) -> void:
	if not level_stars.has(level_name) or int(level_stars[level_name]) < stars:
		level_stars[level_name] = stars
		save_data()

func get_level_stars(level_name: String) -> int:
	if level_stars.has(level_name):
		return int(level_stars[level_name])
	return 0

func apply_theme() -> void:
	ThemeConfig.set_theme_mode(current_theme)
	var tree = get_tree()
	if tree and tree.root:
		_notify_theme_change_recursive(tree.root)

func _notify_theme_change_recursive(node: Node) -> void:
	if node.has_method("queue_redraw"):
		node.queue_redraw()
	if node.has_method("apply_theme_colors"):
		node.apply_theme_colors()
	for child in node.get_children():
		_notify_theme_change_recursive(child)

func apply_theme_colors() -> void:
	var tree = get_tree()
	if tree and tree.root:
		_update_gamesave_settings_ui(tree.root)

func _update_gamesave_settings_ui(node: Node) -> void:
	if node is PanelContainer and node.name == "GameSaveSettingsPanel":
		ThemeConfig.update_settings_panel_colors(node, current_theme)
	elif node is Button and node.name == "GameSaveSettingsBtn":
		var btn_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4, ThemeConfig.RADIUS_XL)
		btn_normal.content_margin_left = 12
		btn_normal.content_margin_right = 12
		btn_normal.content_margin_top = 8
		btn_normal.content_margin_bottom = 8
		var btn_pressed = btn_normal.duplicate()
		btn_pressed.content_margin_top += 4
		btn_pressed.content_margin_bottom -= 4
		ThemeConfig.apply_icon_button_theme(node, btn_normal, btn_pressed)
	for child in node.get_children():
		_update_gamesave_settings_ui(child)

func add_settings_to(target: Node) -> void:
	var settings_panel = PanelContainer.new()
	settings_panel.name = "GameSaveSettingsPanel"
	settings_panel.visible = false
	settings_panel.custom_minimum_size = Vector2(300, 0)
	settings_panel.grow_horizontal = Control.GROW_DIRECTION_END
	settings_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	settings_panel.position = Vector2(920, 620)
	settings_panel.add_theme_stylebox_override("panel", ThemeConfig.create_settings_panel_style())
	
	var set_vbox = VBoxContainer.new()
	set_vbox.add_theme_constant_override("separation", ThemeConfig.SPACING_SM)
	settings_panel.add_child(set_vbox)
	
	var vol_label = ThemeConfig.create_icon_label("res://assets/ic_volume.svg", "おんりょう", ThemeConfig.FONT_BODY, 24, ThemeConfig.TEXT_DARK)
	set_vbox.add_child(vol_label)
	
	var vol_slider = HSlider.new()
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		vol_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus)) * 100.0
	else:
		vol_slider.value = 50
	vol_slider.value_changed.connect(_on_volume_changed)
	set_vbox.add_child(vol_slider)
	ThemeConfig.apply_slider_theme(vol_slider)
	
	var theme_label = ThemeConfig.create_icon_label("res://assets/ic_palette.svg", "テーマ", ThemeConfig.FONT_BODY, 24, ThemeConfig.TEXT_DARK)
	set_vbox.add_child(theme_label)
	
	var theme_btns = ThemeConfig.create_theme_select_buttons(current_theme, func(idx):
		current_theme = idx
		apply_theme()
		save_data()
	)
	set_vbox.add_child(theme_btns)
	
	var sep = HSeparator.new()
	set_vbox.add_child(sep)
	
	var shop_lbl = ThemeConfig.create_icon_label("res://assets/ic_shop.svg", "きせかえ", ThemeConfig.FONT_BODY, 24, ThemeConfig.TEXT_DARK)
	set_vbox.add_child(shop_lbl)
	
	var shop_btn = Button.new()
	shop_btn.text = " ショップを開く"
	shop_btn.icon = load("res://assets/ic_shop.svg")
	shop_btn.add_theme_constant_override("icon_max_width", 22)
	var shop_style_norm = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4, ThemeConfig.RADIUS_MD)
	shop_style_norm.content_margin_top = 8
	shop_style_norm.content_margin_bottom = 8
	var shop_style_press = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY, ThemeConfig.RADIUS_MD)
	shop_style_press.content_margin_top = 8
	shop_style_press.content_margin_bottom = 8
	ThemeConfig.apply_button_theme(shop_btn, shop_style_norm, shop_style_press)
	ThemeConfig.setup_button_animations(shop_btn)
	shop_btn.pressed.connect(func():
		settings_panel.visible = false
		var shop_scene = load("res://scenes/Shop.tscn")
		if shop_scene:
			var shop_instance = shop_scene.instantiate()
			target.add_child(shop_instance)
	)
	set_vbox.add_child(shop_btn)
	
	target.add_child(settings_panel)

	
	var settings_btn = Button.new()
	settings_btn.name = "GameSaveSettingsBtn"
	settings_btn.text = ""
	settings_btn.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
	var gear_tex = load("res://resources/gear_icon.svg")
	if gear_tex:
		settings_btn.icon = gear_tex
		settings_btn.add_theme_constant_override("icon_max_width", 28)
	
	var btn_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4, ThemeConfig.RADIUS_XL)
	btn_normal.content_margin_left = 12
	btn_normal.content_margin_right = 12
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_bottom = 8
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.content_margin_top += 4
	btn_pressed.content_margin_bottom -= 4
	
	ThemeConfig.apply_icon_button_theme(settings_btn, btn_normal, btn_pressed)
	ThemeConfig.setup_button_animations(settings_btn)
	
	settings_btn.position = Vector2(1180, 640)
	settings_btn.pressed.connect(func(): 
		settings_panel.visible = !settings_panel.visible
	)
	
	target.add_child(settings_btn)

func _on_volume_changed(val: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))
