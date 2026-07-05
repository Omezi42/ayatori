extends Node

var total_stars: int = 0
var current_theme: int = 0 # 0: Normal, 1: Monochrome, 2: Dark

const SAVE_PATH = "user://ayatori_save.json"

var effect_rect: ColorRect

func _ready() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	effect_rect = ColorRect.new()
	effect_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(effect_rect)
	
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform int theme_mode = 0;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	void fragment() {
		vec4 c = texture(screen_texture, SCREEN_UV);
		if (theme_mode == 1) { // Monochrome
			float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
			COLOR = vec4(gray, gray, gray, c.a);
		} else if (theme_mode == 2) { // Dark
			// 少し青みがかったダークモード（単純な反転ではない）
			vec3 dark = vec3(c.r * 0.3 + 0.1, c.g * 0.3 + 0.1, c.b * 0.4 + 0.2);
			COLOR = vec4(dark, c.a);
		} else {
			COLOR = c;
		}
	}
	"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	effect_rect.material = mat
	
	load_data()
	apply_theme()

func save_data() -> void:
	var data = {
		"total_stars": total_stars,
		"current_theme": current_theme
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
			if json:
				if json.has("total_stars"): total_stars = json["total_stars"]
				if json.has("current_theme"): current_theme = json["current_theme"]

func add_stars(amount: int) -> void:
	total_stars += amount
	save_data()

func apply_theme() -> void:
	if effect_rect and effect_rect.material:
		effect_rect.material.set_shader_parameter("theme_mode", current_theme)
