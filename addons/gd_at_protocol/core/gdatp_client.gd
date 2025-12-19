extends Node
class_name ATProtoClient

const DEFAULT_BASE_URL: String = "https://api.bsky.app"

var base_url: String = DEFAULT_BASE_URL
var _http: HTTPRequest

var _access_jwt: String = ""
var _refresh_jwt: String = ""
var _did: String = ""


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)


func set_base_url(url: String) -> void:
	base_url = url.rstrip("/")


func set_session(did: String, access_jwt: String, refresh_jwt: String) -> void:
	_did = did
	_access_jwt = access_jwt
	_refresh_jwt = refresh_jwt


func is_authenticated() -> bool:
	return not _access_jwt.is_empty()


func get_did() -> String:
	return _did


func xrpc_get(path: String, query: Dictionary = {}, require_auth: bool = false) -> Dictionary:
	var qs_parts: PackedStringArray = []
	for key in query.keys():
		var k: String = str(key).uri_encode()
		var v: String = str(query[key]).uri_encode()
		qs_parts.append("%s=%s" % [k, v])

	var url := "%s%s" % [base_url, path]
	if qs_parts.size() > 0:
		url += "?" + "&".join(qs_parts)

	var headers: PackedStringArray = []
	if require_auth:
		if _access_jwt.is_empty():
			return {
				"ok": false,
				"error": "AuthMissing",
				"message": "No access token. Call create_session() first.",
			}
		headers.append("Authorization: Bearer %s" % _access_jwt)

	var err: int = _http.request(url, headers)
	if err != OK:
		return {
			"ok": false,
			"error": "RequestStartFailed",
			"message": "Failed to start HTTP request",
			"godot_error": err,
		}

	var sig_result: Array = await _http.request_completed
	var result: int = sig_result[0]
	var response_code: int = sig_result[1]
	var _response_headers: PackedStringArray = sig_result[2]
	var body: PackedByteArray = sig_result[3]

	var text: String = body.get_string_from_utf8()

	if result != HTTPRequest.RESULT_SUCCESS:
		return {
			"ok": false,
			"error": "HTTPRequestFailed",
			"message": "HTTPRequest result: %d" % result,
			"status": response_code,
			"raw": text,
		}

	if response_code < 200 or response_code >= 300:
		var err_body: Variant = JSON.parse_string(text)
		var err_code := "HttpError"
		var err_msg := ""
		if typeof(err_body) == TYPE_DICTIONARY:
			err_code = String(err_body.get("error", err_code))
			err_msg  = String(err_body.get("message", ""))
		return {
			"ok": false,
			"error": err_code,
			"message": err_msg,
			"status": response_code,
			"body": err_body,
			"raw": text,
		}

	var data: Variant = JSON.parse_string(text)
	if data == null:
		return {
			"ok": false,
			"error": "JsonParseError",
			"status": response_code,
			"message": "Failed to parse JSON from response.",
			"raw": text,
		}

	return {
		"ok": true,
		"status": response_code,
		"data": data,
		"raw": text,
	}


func xrpc_post(path: String, body_dict: Dictionary, require_auth: bool = false) -> Dictionary:
	var url := "%s%s" % [base_url, path]
	var json_text := JSON.stringify(body_dict)

	var headers: PackedStringArray = [ "Content-Type: application/json" ]

	if require_auth:
		if _access_jwt.is_empty():
			return {
				"ok": false,
				"error": "AuthMissing",
				"message": "No access token. Call create_session() first.",
			}
		headers.append("Authorization: Bearer %s" % _access_jwt)

	var err: int = _http.request(url, headers, HTTPClient.METHOD_POST, json_text)
	if err != OK:
		return {
			"ok": false,
			"error": "RequestStartFailed",
			"message": "Failed to start HTTP POST",
			"godot_error": err,
		}

	var sig_result: Array = await _http.request_completed
	var result: int = sig_result[0]
	var response_code: int = sig_result[1]
	var _response_headers: PackedStringArray = sig_result[2]
	var body: PackedByteArray = sig_result[3]

	var text: String = body.get_string_from_utf8()

	if result != HTTPRequest.RESULT_SUCCESS:
		return {
			"ok": false,
			"error": "HTTPRequestFailed",
			"message": "HTTPRequest result: %d" % result,
			"status": response_code,
			"raw": text,
		}

	if response_code < 200 or response_code >= 300:
		var err_body: Variant = JSON.parse_string(text)
		var err_code := "HttpError"
		var err_msg := ""
		if typeof(err_body) == TYPE_DICTIONARY:
			err_code = String(err_body.get("error", err_code))
			err_msg  = String(err_body.get("message", ""))
		return {
			"ok": false,
			"error": "HttpError",
			"message": err_msg,
			"status": response_code,
			"body": err_body,
			"raw": text,
		}

	var data: Variant = JSON.parse_string(text)
	if data == null:
		return {
			"ok": false,
			"error": "JsonParseError",
			"message": "Failed to parse JSON from response.",
			"status": response_code,
			"raw": text,
		}

	return {
		"ok": true,
		"status": response_code,
		"data": data,
		"raw": text,
	}


func generate_rkey() -> String:
	var ms: int = Time.get_ticks_msec()
	return "%016x" % ms
