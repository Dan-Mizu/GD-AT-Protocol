extends Node

# URLs
const DEFAULT_SERVICE_ENDPOINT_URL: String = "https://bsky.social"
const PLC_DIRECTORY_URL: String = "https://plc.directory/"

# internal
var _client: ATProtoClient

func _ready() -> void:
	_client = ATProtoClient.new()
	add_child(_client)

func get_profile(actor: String) -> ATProtoProfileData.Response:
	var raw: Dictionary = await _client.xrpc_get(
		"/xrpc/app.bsky.actor.getProfile",
		{ "actor": actor },
		false
	)
	return ATProtoProfileData.Response.from_raw(raw)

func get_did_plc_doc(did: String) -> ATProtoDidPlcDocData.Response:
	var url := PLC_DIRECTORY_URL + did
	var raw: Dictionary = await _client.http_get_json(url)
	return ATProtoDidPlcDocData.Response.from_raw(raw)

func create_session(
	identifier: String,
	app_password: String,
	service_endpoint: String = DEFAULT_SERVICE_ENDPOINT_URL
) -> ATProtoSessionData.Response:
	var payload := {
		"identifier": identifier,
		"password": app_password,
	}

	var full_url := service_endpoint.rstrip("/") + "/xrpc/com.atproto.server.createSession"

	var raw: Dictionary = await _client.http_post_json(full_url, payload)

	var resp: ATProtoSessionData.Response = ATProtoSessionData.Response.from_raw(raw)
	if resp.error == "":
		var s: ATProtoSessionData = resp.data
		_client.set_session(s.did, s.access_jwt, s.refresh_jwt)
		_client.set_pds_url(service_endpoint)

	return resp

func describe_repo(repo: String) -> ATProtoDescribeRepoData.Response:
	var raw: Dictionary = await _client.xrpc_get(
		"/xrpc/com.atproto.repo.describeRepo",
		{ "repo": repo },
		true
	)
	return ATProtoDescribeRepoData.Response.from_raw(raw)

func list_records(
	repo: String,
	collection: String,
	cursor: String = "",
	limit: int = 100
) -> ATProtoListRecordsData.Response:
	var query: Dictionary = {
		"repo": repo,
		"collection": collection,
		"limit": limit,
	}
	if not cursor.is_empty():
		query["cursor"] = cursor

	var raw: Dictionary = await _client.xrpc_get(
		"/xrpc/com.atproto.repo.listRecords",
		query,
		true
	)
	return ATProtoListRecordsData.Response.from_raw(raw)

func get_record(repo: String, collection: String, rkey: String) -> ATProtoRecordData.Response:
	var raw: Dictionary = await _client.xrpc_get(
		"/xrpc/com.atproto.repo.getRecord",
		{ "repo": repo, "collection": collection, "rkey": rkey },
		true
	)
	return ATProtoRecordData.Response.from_raw(raw)

func put_record(repo: String, collection: String, rkey: String, record: Dictionary) -> ATProtoPutRecordData.Response:
	var payload := { "repo": repo, "collection": collection, "rkey": rkey, "record": record }
	var raw: Dictionary = await _client.xrpc_post(
		"/xrpc/com.atproto.repo.putRecord",
		payload,
		true
	)
	return ATProtoPutRecordData.Response.from_raw(raw)

func get_author_feed(actor_did: String, limit: int = 20, cursor: String = "") -> ATProtoAuthorFeedData.Response:
	var query: Dictionary = { "actor": actor_did, "limit": limit }
	if not cursor.is_empty():
		query["cursor"] = cursor

	var raw: Dictionary = await _client.xrpc_get(
		"/xrpc/app.bsky.feed.getAuthorFeed",
		query,
		true
	)
	return ATProtoAuthorFeedData.Response.from_raw(raw)

func resolve_handle(handle: String) -> ATProtoResolveHandleData.Response:
	var raw: Dictionary = await _client.xrpc_get(
		"/xrpc/com.atproto.identity.resolveHandle",
		{ "handle": handle },
		false
	)
	return ATProtoResolveHandleData.Response.from_raw(raw)

#region Helpers
func fetch_all_records_for_collection(
	repo: String,
	collection: String
) -> Array[ATProtoListRecordsData.Record]:
	var all_records: Array[ATProtoListRecordsData.Record] = []
	var cursor := ""

	while true:
		var page_res: ATProtoListRecordsData.Response = await list_records(
			repo,
			collection,
			cursor,
			100
		)

		if not page_res.is_ok():
			push_error("Failed to list records for %s\n%s" % [collection, page_res.error])
			break

		var page: ATProtoListRecordsData = page_res.data
		all_records.append_array(page.records)

		if page.cursor.is_empty():
			break

		cursor = page.cursor

	return all_records
#endregion
