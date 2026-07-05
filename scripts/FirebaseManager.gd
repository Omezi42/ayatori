extends Node

const PROJECT_ID = "ayatori-efbcd"
const BASE_URL = "https://firestore.googleapis.com/v1/projects/" + PROJECT_ID + "/databases/(default)/documents/levels"

signal save_completed(code)
signal save_failed(error)
signal load_completed(target_sequence)
signal load_failed(error)

var http_request_save: HTTPRequest
var http_request_load: HTTPRequest

func _ready():
	http_request_save = HTTPRequest.new()
	add_child(http_request_save)
	http_request_save.request_completed.connect(_on_save_request_completed)

	http_request_load = HTTPRequest.new()
	add_child(http_request_load)
	http_request_load.request_completed.connect(_on_load_request_completed)

# 共有コードを生成 (例: "A1B2C")
func _generate_short_code() -> String:
	const CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" # I, O, 1, 0を抜いて見間違い防止
	var code = ""
	for i in range(5):
		code += CHARS[randi() % CHARS.length()]
	return code

# ステージを保存
func save_level(target_sequence: Array[int]):
	var code = _generate_short_code()
	var url = BASE_URL + "?documentId=" + code
	
	# Firestore REST API 形式に変換
	var values = []
	for val in target_sequence:
		values.append({"integerValue": str(val)})
		
	var body = {
		"fields": {
			"target_sequence": {
				"arrayValue": {
					"values": values
				}
			}
		}
	}
	
	var json_str = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	
	var error = http_request_save.request(url, headers, HTTPClient.METHOD_POST, json_str)
	if error != OK:
		emit_signal("save_failed", "リクエストの送信に失敗しました")

# ステージを読み込み
func load_level(code: String):
	code = code.to_upper()
	var url = BASE_URL + "/" + code
	var headers = ["Content-Type: application/json"]
	
	var error = http_request_load.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		emit_signal("load_failed", "リクエストの送信に失敗しました")

func _on_save_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("name"):
			var parts = json["name"].split("/")
			var code = parts[parts.size() - 1]
			emit_signal("save_completed", code)
		else:
			emit_signal("save_failed", "レスポンスの解析に失敗しました")
	else:
		emit_signal("save_failed", "サーバーエラー: " + str(response_code))

func _on_load_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("fields") and json["fields"].has("target_sequence"):
			var array_val = json["fields"]["target_sequence"]["arrayValue"]["values"]
			var seq: Array[int] = []
			for item in array_val:
				seq.append(int(item["integerValue"]))
			emit_signal("load_completed", seq)
		else:
			emit_signal("load_failed", "データが見つかりません")
	elif response_code == 404:
		emit_signal("load_failed", "指定されたコードのステージが見つかりません")
	else:
		emit_signal("load_failed", "サーバーエラー: " + str(response_code))
