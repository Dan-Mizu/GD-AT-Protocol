extends Node
class_name GDATProtocol

# Base URL for public Bluesky API
const DEFAULT_BASE_URL: String = "https://api.bsky.app"

var base_url: String = DEFAULT_BASE_URL

# Internal HTTPRequest node
var _http: HTTPRequest

# Auth/session state
var _access_jwt: String = ""
var _refresh_jwt: String = ""
var _did: String = ""


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)


# ---------------------------------------------------
# Low-level XRPC helper
# ---------------------------------------------------

func _xrpc_get(path: String, query: Dictionary = {}, require_auth: bool = false) -> Dictionary:
	# Build URL with query string
	var qs_parts: PackedStringArray = []
	for key in query.keys():
		var k: String = str(key).uri_encode()
		var v: String = str(query[key]).uri_encode()
		qs_parts.append("%s=%s" % [k, v])

	var url: String = "%s%s" % [base_url, path]
	if qs_parts.size() > 0:
		url += "?" + "&".join(qs_parts)

	var headers: PackedStringArray = []
	if require_auth:
		if _access_jwt.is_empty():
			return {
				"ok": false,
				"error": "AuthMissing",
				"message": "No access token. Call create_session() first."
			}
		headers.append("Authorization: Bearer %s" % _access_jwt)

	var err: int = _http.request(url, headers)
	if err != OK:
		return {
			"ok": false,
			"error": "RequestStartFailed",
			"message": "Failed to start HTTP request",
			"godot_error": err
		}

	# Wait for HTTPRequest to complete; result is an Array:
	# [result, response_code, headers, body]
	var sig_result: Array = await _http.request_completed

	var result: int = sig_result[0]
	var response_code: int = sig_result[1]
	var response_headers: PackedStringArray = sig_result[2]
	var body: PackedByteArray = sig_result[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		return {
			"ok": false,
			"error": "HTTPRequestFailed",
			"message": "HTTPRequest result: %d" % result,
			"http_result": result,
			"status": response_code
		}

	var text: String = body.get_string_from_utf8()

	if response_code < 200 or response_code >= 300:
		var err_body: Variant = JSON.parse_string(text)
		return {
			"ok": false,
			"error": "HttpError",
			"status": response_code,
			"body": err_body,
			"raw": text
		}

	var data: Variant = JSON.parse_string(text)
	if data == null:
		return {
			"ok": false,
			"error": "JsonParseError",
			"raw": text
		}

	return {
		"ok": true,
		"status": response_code,
		"data": data
	}


func _xrpc_post(path: String, body_dict: Dictionary, require_auth: bool = false) -> Dictionary:
	var url: String = "%s%s" % [base_url, path]

	var json_text: String = JSON.stringify(body_dict)
	var headers: PackedStringArray = [
		"Content-Type: application/json"
	]

	if require_auth:
		if _access_jwt.is_empty():
			return {
				"ok": false,
				"error": "AuthMissing",
				"message": "No access token. Call create_session() first."
			}
		headers.append("Authorization: Bearer %s" % _access_jwt)

	var err: int = _http.request(url, headers, HTTPClient.METHOD_POST, json_text)
	if err != OK:
		return {
			"ok": false,
			"error": "RequestStartFailed",
			"message": "Failed to start HTTP POST",
			"godot_error": err
		}

	var sig_result: Array = await _http.request_completed

	var result: int = sig_result[0]
	var response_code: int = sig_result[1]
	var response_headers: PackedStringArray = sig_result[2]
	var body: PackedByteArray = sig_result[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		return {
			"ok": false,
			"error": "HTTPRequestFailed",
			"message": "HTTPRequest result: %d" % result,
			"http_result": result,
			"status": response_code
		}

	var text: String = body.get_string_from_utf8()

	if response_code < 200 or response_code >= 300:
		var err_body: Variant = JSON.parse_string(text)
		return {
			"ok": false,
			"error": "HttpError",
			"status": response_code,
			"body": err_body,
			"raw": text
		}

	var data: Variant = JSON.parse_string(text)
	if data == null:
		return {
			"ok": false,
			"error": "JsonParseError",
			"raw": text
		}

	return {
		"ok": true,
		"status": response_code,
		"data": data
	}


# ---------------------------------------------------
# Public API: identity / profiles
# ---------------------------------------------------

## Resolve a handle (e.g. "danbagh.com") to a DID
## Returns: { ok: true, data: { did: String } } on success
func resolve_handle(handle: String) -> Dictionary:
	var res: Dictionary = await _xrpc_get("/xrpc/com.atproto.identity.resolveHandle", {
		"handle": handle,
	})
	return res


## Get profile by handle or DID.
## Example: get_profile("danbagh.com") or get_profile("did:plc:...")
func get_profile(actor: String) -> Dictionary:
	var res: Dictionary = await _xrpc_get("/xrpc/app.bsky.actor.getProfile", {
		"actor": actor,
	})
	return res


# ---------------------------------------------------
# Public API: auth / sessions
# ---------------------------------------------------

## Log in with handle + app password
## Stores access_jwt / refresh_jwt / did in this singleton.
## Returns { ok: true, data: { did, accessJwt, refreshJwt } } on success.
func create_session(identifier: String, app_password: String) -> Dictionary:
	var payload := {
		"identifier": identifier,
		"password": app_password
	}

	var res: Dictionary = await _xrpc_post("/xrpc/com.atproto.server.createSession", payload)
	if res.get("ok", false):
		var data: Dictionary = res["data"]
		_access_jwt = String(data.get("accessJwt", ""))
		_refresh_jwt = String(data.get("refreshJwt", ""))
		_did = String(data.get("did", ""))
	return res


func is_authenticated() -> bool:
	return not _access_jwt.is_empty()


func get_did() -> String:
	return _did


# ---------------------------------------------------
# Public API: simple feed call
# ---------------------------------------------------

## Get author's feed (timeline) for a DID.
## Requires authentication (access token).
## limit: 1–100 usually.
func get_author_feed(actor_did: String, limit: int = 20, cursor: String = "") -> Dictionary:
	var query: Dictionary = {
		"actor": actor_did,
		"limit": limit
	}
	if not cursor.is_empty():
		query["cursor"] = cursor

	var res: Dictionary = await _xrpc_get("/xrpc/app.bsky.feed.getAuthorFeed", query, true)
	return res
