extends Node

var _client: ATProtoClient

func _ready() -> void:
	_client = ATProtoClient.new()
	add_child(_client)

func get_profile(actor: String) -> ATProtoProfileData.ATProtoProfileResponse:
	var raw: Dictionary = await _client.xrpc_get(
		"/xrpc/app.bsky.actor.getProfile",
		{ "actor": actor },
		false
	)
	return ATProtoProfileData.ATProtoProfileResponse.from_raw(raw)

func create_session(identifier: String, app_password: String) -> ATProtoSessionData.ATProtoSessionResponse:
	var payload := { "identifier": identifier, "password": app_password }
	var raw: Dictionary = await _client.xrpc_post(
		"/xrpc/com.atproto.server.createSession",
		payload,
		false
	)
	var resp: ATProtoSessionData.ATProtoSessionResponse = ATProtoSessionData.ATProtoSessionResponse.from_raw(raw)
	if resp.error == "":
		var s: ATProtoSessionData = resp.data
		_client.set_session(s.did, s.access_jwt, s.refresh_jwt)
	return resp

func get_record(repo: String, collection: String, rkey: String) -> ATProtoRecordData.ATProtoRecordResponse:
	var raw: Dictionary = await _client.xrpc_get(
		"/xrpc/com.atproto.repo.getRecord",
		{ "repo": repo, "collection": collection, "rkey": rkey },
		true
	)
	return ATProtoRecordData.ATProtoRecordResponse.from_raw(raw)

func put_record(repo: String, collection: String, rkey: String, record: Dictionary) -> ATProtoPutRecordData.ATProtoPutRecordResponse:
	var payload := { "repo": repo, "collection": collection, "rkey": rkey, "record": record }
	var raw: Dictionary = await _client.xrpc_post(
		"/xrpc/com.atproto.repo.putRecord",
		payload,
		true
	)
	return ATProtoPutRecordData.ATProtoPutRecordResponse.from_raw(raw)

func get_author_feed(actor_did: String, limit: int = 20, cursor: String = "") -> ATProtoAuthorFeedData.ATProtoAuthorFeedResponse:
	var query: Dictionary = { "actor": actor_did, "limit": limit }
	if not cursor.is_empty():
		query["cursor"] = cursor

	var raw: Dictionary = await _client.xrpc_get(
		"/xrpc/app.bsky.feed.getAuthorFeed",
		query,
		true
	)
	return ATProtoAuthorFeedData.ATProtoAuthorFeedResponse.from_raw(raw)

func resolve_handle(handle: String) -> ATProtoResolveHandleData.ATProtoResolveHandleResponse:
	var raw: Dictionary = await _client.xrpc_get(
		"/xrpc/com.atproto.identity.resolveHandle",
		{ "handle": handle },
		false
	)
	return ATProtoResolveHandleData.ATProtoResolveHandleResponse.from_raw(raw)
