extends Node

const PROJECT_ID = "ayatori-efbcd"
const BASE_URL = "https://firestore.googleapis.com/v1/projects/" + PROJECT_ID + "/databases/(default)/documents/levels"

signal save_completed(code)
signal save_failed(error)
signal load_completed(target_sequence, layout_id, title)
signal load_failed(error)
signal levels_fetched(levels_data)
signal fetch_failed(error)

signal network_request_started
signal network_request_completed(success: bool, error_message: String)

var http_request_save: HTTPRequest
var http_request_load: HTTPRequest
var http_request_fetch: HTTPRequest
var current_search_query: String = ""

func _ready():
	http_request_save = HTTPRequest.new()
	add_child(http_request_save)
	http_request_save.request_completed.connect(_on_save_request_completed)

	http_request_load = HTTPRequest.new()
	add_child(http_request_load)
	http_request_load.request_completed.connect(_on_load_request_completed)

	http_request_fetch = HTTPRequest.new()
	add_child(http_request_fetch)
	http_request_fetch.request_completed.connect(_on_fetch_request_completed)

# 共有コードを生成 (例: "A1B2C")
func _generate_short_code() -> String:
	const CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" # I, O, 1, 0を抜いて見間違い防止
	var code = ""
	for i in range(5):
		code += CHARS[randi() % CHARS.length()]
	return code

# ステージを保存
func save_level(title: String, target_sequence: Array[int], layout_id: int = 0):
	network_request_started.emit()
	var code = _generate_short_code()
	var url = BASE_URL + "?documentId=" + code
	
	# Firestore REST API 形式に変換
	var values = []
	for val in target_sequence:
		values.append({"integerValue": str(val)})
		
	var created_at = Time.get_datetime_string_from_system(true, false) + "Z"
	
	var body = {
		"fields": {
			"title": { "stringValue": title },
			"created_at": { "timestampValue": created_at },
			"play_count": { "integerValue": "0" },
			"likes": { "integerValue": "0" },
			"layout_id": { "integerValue": str(layout_id) },
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
		network_request_completed.emit(false, "リクエストの送信に失敗しました")

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
			network_request_completed.emit(true, "")
		else:
			emit_signal("save_failed", "レスポンスの解析に失敗しました")
			network_request_completed.emit(false, "レスポンスの解析に失敗しました")
	else:
		emit_signal("save_failed", "サーバーエラー: " + str(response_code))
		network_request_completed.emit(false, "サーバーエラー: " + str(response_code))

func _on_load_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("fields") and json["fields"].has("target_sequence"):
			var array_val = json["fields"]["target_sequence"]["arrayValue"]["values"]
			var seq: Array[int] = []
			for item in array_val:
				seq.append(int(item["integerValue"]))
			
			var layout_id = 0
			if json["fields"].has("layout_id"):
				layout_id = int(json["fields"]["layout_id"]["integerValue"])
			
			var title = "ユーザー作成ステージ"
			if json["fields"].has("title"):
				title = json["fields"]["title"]["stringValue"]
				
			emit_signal("load_completed", seq, layout_id, title)
		else:
			emit_signal("load_failed", "データが見つかりません")
	elif response_code == 404:
		emit_signal("load_failed", "指定されたコードのステージが見つかりません")
	else:
		emit_signal("load_failed", "サーバーエラー: " + str(response_code))

func fetch_levels(sort_type: String = "newest", search_query: String = ""):
	current_search_query = search_query
	var url = "https://firestore.googleapis.com/v1/projects/" + PROJECT_ID + "/databases/(default)/documents:runQuery"
	var order_by_field = "created_at"
	if sort_type == "popular":
		order_by_field = "play_count"
	elif sort_type == "likes":
		order_by_field = "likes"
		
	var query = {
		"structuredQuery": {
			"from": [{"collectionId": "levels"}],
			"orderBy": [
				{"field": {"fieldPath": order_by_field}, "direction": "DESCENDING"}
			],
			"limit": 50
		}
	}
	
	var json_str = JSON.stringify(query)
	var headers = ["Content-Type: application/json"]
	
	var error = http_request_fetch.request(url, headers, HTTPClient.METHOD_POST, json_str)
	if error != OK:
		emit_signal("fetch_failed", "リクエストの送信に失敗しました")

func _on_fetch_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var json_array = JSON.parse_string(body.get_string_from_utf8())
		if json_array is Array:
			var levels = []
			for doc in json_array:
				if doc is Dictionary and doc.has("document") and doc["document"].has("fields"):
					var fields = doc["document"]["fields"]
					var doc_name = doc["document"]["name"]
					var parts = doc_name.split("/")
					var code = parts[parts.size() - 1]
					
					var title = fields.get("title", {}).get("stringValue", "無題")
					var play_count = int(fields.get("play_count", {}).get("integerValue", "0"))
					var likes = int(fields.get("likes", {}).get("integerValue", "0"))
					
					# ローカルでの検索クエリ絞り込み
					if current_search_query != "":
						if current_search_query.to_upper() not in code and current_search_query not in title:
							continue
							
					var seq: Array[int] = []
					if fields.has("target_sequence"):
						var array_val = fields["target_sequence"]["arrayValue"]["values"]
						for item in array_val:
							seq.append(int(item["integerValue"]))
							
					var layout_id = 0
					if fields.has("layout_id"):
						layout_id = int(fields["layout_id"]["integerValue"])
							
					levels.append({
						"code": code,
						"title": title,
						"play_count": play_count,
						"likes": likes,
						"target_sequence": seq,
						"layout_id": layout_id
					})
			emit_signal("levels_fetched", levels)
		else:
			emit_signal("fetch_failed", "不正なデータ形式です")
	else:
		emit_signal("fetch_failed", "サーバーエラー: " + str(response_code))

func increment_like(code: String) -> void:
	var url = "https://firestore.googleapis.com/v1/projects/" + PROJECT_ID + "/databases/(default)/documents:commit"
	var body = {
		"writes": [
			{
				"transform": {
					"document": "projects/" + PROJECT_ID + "/databases/(default)/documents/levels/" + code,
					"fieldTransforms": [
						{
							"fieldPath": "likes",
							"increment": {
								"integerValue": "1"
							}
						}
					]
				}
			}
		]
	}
	
	var json_str = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	
	var req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_result, _response_code, _h, _b):
		req.queue_free()
	)
	req.request(url, headers, HTTPClient.METHOD_POST, json_str)
