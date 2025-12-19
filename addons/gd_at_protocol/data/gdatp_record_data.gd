extends RefCounted
class_name ATProtoRecordData

var uri: String = ""
var cid: String = ""
var value: Dictionary = {}
var repo: String = ""
var collection: String = ""
var rkey: String = ""
var raw: Dictionary = {}

class ATProtoRecordResponse:
	extends ATProtoResponse

	var data: ATProtoRecordData = null

	static func from_raw(raw: Dictionary) -> ATProtoRecordResponse:
		var resp := ATProtoRecordResponse.new()
		resp.status = int(raw.get("status", 0))
		resp.raw_body = String(raw.get("raw", ""))

		if not raw.get("ok", false):
			var code := String(raw.get("error", "UnknownError"))
			var msg  := String(raw.get("message", ""))
			resp.error = code if msg.is_empty() else "%s: %s" % [code, msg]
			return resp

		var d: Dictionary = raw["data"]
		var r := ATProtoRecordData.new()

		r.uri        = String(d.get("uri", ""))
		r.cid        = String(d.get("cid", ""))
		r.value      = d.get("value", {})
		r.repo       = String(d.get("repo", ""))
		r.collection = String(d.get("collection", ""))
		r.rkey       = String(d.get("rkey", ""))
		r.raw        = d

		resp.data = r
		return resp
