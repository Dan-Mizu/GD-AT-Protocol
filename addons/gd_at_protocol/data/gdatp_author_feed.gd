extends RefCounted
class_name ATProtoAuthorFeedData

var feed: Array = []            # array of feed items (Dictionary for now)
var cursor: String = ""         # pagination cursor (if present)
var raw: Dictionary = {}        # full JSON

class ATProtoAuthorFeedResponse:
	extends ATProtoResponse

	var data: ATProtoAuthorFeedData = null

	static func from_raw(raw: Dictionary) -> ATProtoAuthorFeedResponse:
		var resp := ATProtoAuthorFeedResponse.new()
		resp.status = int(raw.get("status", 0))
		resp.raw_body = String(raw.get("raw", ""))

		if not raw.get("ok", false):
			var code := String(raw.get("error", "UnknownError"))
			var msg  := String(raw.get("message", ""))
			resp.error = code if msg.is_empty() else "%s: %s" % [code, msg]
			return resp

		var d: Dictionary = raw["data"]
		var af := ATProtoAuthorFeedData.new()

		af.feed   = d.get("feed", [])
		af.cursor = String(d.get("cursor", ""))
		af.raw    = d

		resp.data = af
		return resp
