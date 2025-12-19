extends RefCounted
class_name ATProtoPutRecordData

var uri: String = ""
var cid: String = ""
var value: Dictionary = {}
var raw: Dictionary = {}

class ATProtoPutRecordResponse:
	extends ATProtoResponse

	var data: ATProtoPutRecordData = null

	static func from_raw(raw: Dictionary) -> ATProtoPutRecordResponse:
		var resp := ATProtoPutRecordResponse.new()
		resp.status = int(raw.get("status", 0))
		resp.raw_body = String(raw.get("raw", ""))

		if not raw.get("ok", false):
			var code := String(raw.get("error", "UnknownError"))
			var msg  := String(raw.get("message", ""))
			resp.error = code if msg.is_empty() else "%s: %s" % [code, msg]
			return resp

		var d: Dictionary = raw["data"]
		var r := ATProtoPutRecordData.new()

		r.uri   = String(d.get("uri", ""))
		r.cid   = String(d.get("cid", ""))
		r.value = d.get("value", {})
		r.raw   = d

		resp.data = r
		return resp
