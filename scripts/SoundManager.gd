extends Node

# === 音量設定（0〜100） ===
var master_volume: float = 80.0
var bgm_volume: float = 80.0
var se_volume: float = 80.0

# === SE プール ===
const SE_POOL_SIZE: int = 6
var _se_players: Array[AudioStreamPlayer] = []
var _se_pool_index: int = 0
var _se_cache: Dictionary = {}

# === ジングル ===
var _jingle_player: AudioStreamPlayer
var _jingle_cache: Dictionary = {}

# === BGM クロスフェード用プレイヤー ===
var _bgm_players: Array[AudioStreamPlayer] = []
var _bgm_active_index: int = 0
var _bgm_current_id: String = ""
var _bgm_current_path: String = ""
var _bgm_fade_tween: Tween

# === オーディオファイルパス ===
const SE_DIR: String = "res://assets/audio/se/"
const JINGLE_DIR: String = "res://assets/audio/jingle/"
const BGM_DIR: String = "res://assets/audio/bgm/"

# === 利用可能なサウンドID ===
const SE_IDS: Array[String] = [
	"button_tap",
	"string_hook",
	"string_unhook",
	"undo",
	"reset",
	"panel_open",
	"panel_close",
	"star_get",
	"transition",
]

const JINGLE_IDS: Array[String] = [
	"level_clear",
	"perfect_clear",
]

const BGM_IDS: Array[String] = [
	"bgm_title",
	"bgm_gameplay",
	"bgm_levelselect",
]

func _ready() -> void:
	# SEプレイヤープールを作成
	for i in SE_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "SE"
		add_child(player)
		_se_players.append(player)

	# ジングル専用プレイヤーを作成
	_jingle_player = AudioStreamPlayer.new()
	_jingle_player.bus = "SE"
	add_child(_jingle_player)

	# BGMクロスフェード用に2つのプレイヤーを作成
	for i in 2:
		var player = AudioStreamPlayer.new()
		player.bus = "BGM"
		add_child(player)
		_bgm_players.append(player)

	# SEファイルをプリロード
	for se_id in SE_IDS:
		var stream = _load_audio_safe(SE_DIR + se_id + ".wav")
		if not stream:
			# wavが見つからない場合はoggも試す
			stream = _load_audio_safe(SE_DIR + se_id + ".ogg")
		if stream:
			_se_cache[se_id] = stream

	# ジングルファイルをプリロード
	for jingle_id in JINGLE_IDS:
		var stream = _load_audio_safe(JINGLE_DIR + jingle_id + ".wav")
		if not stream:
			stream = _load_audio_safe(JINGLE_DIR + jingle_id + ".ogg")
		if stream:
			_jingle_cache[jingle_id] = stream

	# 保存された音量設定を適用
	apply_saved_volumes()


# === 安全なオーディオ読み込み ===
# ファイルが存在しない場合はnullを返す（クラッシュしない）
func _load_audio_safe(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	var res = load(path)
	if res is AudioStream:
		return res
	print("[SoundManager] 読み込み失敗（AudioStreamではない）: ", path)
	return null


# =============================================
#  SE 再生
# =============================================
func play_se(id: String) -> void:
	if not _se_cache.has(id):
		return
	var player = _se_players[_se_pool_index]
	player.stream = _se_cache[id]
	player.volume_db = linear_to_db(se_volume / 100.0)
	player.play()
	# プールを巡回して重複再生を可能にする
	_se_pool_index = (_se_pool_index + 1) % SE_POOL_SIZE


# =============================================
#  ジングル 再生
# =============================================
func play_jingle(id: String) -> void:
	if not _jingle_cache.has(id):
		return
	_jingle_player.stream = _jingle_cache[id]
	_jingle_player.volume_db = linear_to_db(se_volume / 100.0)
	_jingle_player.play()


# =============================================
#  BGM 解決＆フォールバック検索
# =============================================
func _get_available_bgm_files() -> Array[String]:
	var result: Array[String] = []
	var dir = DirAccess.open(BGM_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var clean_name = file_name.replace(".import", "").replace(".remap", "")
				if clean_name.ends_with(".ogg") or clean_name.ends_with(".wav") or clean_name.ends_with(".mp3"):
					var full_path = BGM_DIR + clean_name
					if not result.has(full_path) and ResourceLoader.exists(full_path):
						result.append(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	result.sort()
	return result

func _resolve_bgm_path(id: String) -> String:
	for ext in [".ogg", ".wav", ".mp3"]:
		var p = BGM_DIR + id + ext
		if ResourceLoader.exists(p):
			return p
	
	var available = _get_available_bgm_files()
	if available.size() > 0:
		var idx = 0
		if id == "bgm_gameplay" and available.size() > 1:
			idx = 1 % available.size()
		elif id == "bgm_levelselect" and available.size() > 2:
			idx = 2 % available.size()
		return available[idx]
		
	return ""

# =============================================
#  BGM 再生（クロスフェード対応）
# =============================================
func play_bgm(id: String, fade_time: float = 1.0) -> void:
	var target_path = _resolve_bgm_path(id)
	if target_path == "":
		print("[SoundManager] BGMファイルが見つかりません: id=", id)
		return
	
	# 同じファイルが既に再生中なら継続
	if target_path == _bgm_current_path and _bgm_players[_bgm_active_index].playing:
		_bgm_current_id = id
		return

	var stream = _load_audio_safe(target_path)
	if not stream:
		return

	if _bgm_fade_tween and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()

	var old_player = _bgm_players[_bgm_active_index]
	_bgm_active_index = 1 - _bgm_active_index
	var new_player = _bgm_players[_bgm_active_index]

	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		stream.loop = true

	new_player.stream = stream
	new_player.volume_db = -80.0
	new_player.play()

	var target_db = linear_to_db(bgm_volume / 100.0) - 2.5 # 今の7割〜8割程度の音量(約0.75倍 = -2.5dB)にする
	_bgm_fade_tween = create_tween().set_parallel(true)
	_bgm_fade_tween.tween_property(new_player, "volume_db", target_db, fade_time).set_trans(Tween.TRANS_SINE)
	if old_player.playing:
		_bgm_fade_tween.tween_property(old_player, "volume_db", -80.0, fade_time).set_trans(Tween.TRANS_SINE)
		_bgm_fade_tween.tween_callback(old_player.stop).set_delay(fade_time)

	_bgm_current_id = id
	_bgm_current_path = target_path
	print("[SoundManager] BGM再生開始: ", target_path, " (id: ", id, ")")


func stop_bgm(fade_time: float = 1.0) -> void:
	if _bgm_fade_tween and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()

	var player = _bgm_players[_bgm_active_index]
	if not player.playing:
		_bgm_current_id = ""
		_bgm_current_path = ""
		return

	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.tween_property(player, "volume_db", -80.0, fade_time).set_trans(Tween.TRANS_SINE)
	_bgm_fade_tween.tween_callback(player.stop)

	_bgm_current_id = ""
	_bgm_current_path = ""


# =============================================
#  音量制御
# =============================================
func set_master_volume(val: float) -> void:
	master_volume = clampf(val, 0.0, 100.0)
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(master_volume / 100.0))

func set_bgm_volume(val: float) -> void:
	bgm_volume = clampf(val, 0.0, 100.0)
	var bus_idx = AudioServer.get_bus_index("BGM")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(bgm_volume / 100.0))
	# 再生中のBGMプレイヤーの音量も更新（今の7〜8割程度の音量に調整）
	for player in _bgm_players:
		if player.playing:
			player.volume_db = linear_to_db(bgm_volume / 100.0) - 2.5

func set_se_volume(val: float) -> void:
	se_volume = clampf(val, 0.0, 100.0)
	var bus_idx = AudioServer.get_bus_index("SE")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(se_volume / 100.0))

func get_master_volume() -> float:
	return master_volume

func get_bgm_volume() -> float:
	return bgm_volume

func get_se_volume() -> float:
	return se_volume


# =============================================
#  セーブデータ連携
# =============================================
# GameSaveから保存された音量設定を読み込んで適用する
func apply_saved_volumes() -> void:
	if not GameSave:
		return
	# GameSaveにサウンド関連のデータがあれば適用
	# （GameSave側で master_volume / bgm_volume / se_volume を保存する想定）
	if "master_volume" in GameSave:
		set_master_volume(float(GameSave.master_volume))
	else:
		set_master_volume(master_volume)
	if "bgm_volume" in GameSave:
		set_bgm_volume(float(GameSave.bgm_volume))
	else:
		set_bgm_volume(bgm_volume)
	if "se_volume" in GameSave:
		set_se_volume(float(GameSave.se_volume))
	else:
		set_se_volume(se_volume)
