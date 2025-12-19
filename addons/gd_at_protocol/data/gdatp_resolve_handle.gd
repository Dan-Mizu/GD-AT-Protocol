extends RefCounted
class_name ATProtoResolveHandleData

var did: String = ""
var raw: Dictionary = {}

class ATProtoResolveHandleResponse:
	extends ATProtoResponse

	var data: ATProtoResolveHandleData = null

	static func from_raw(raw: Dictionary) -> ATProtoResolveHandleResponse:
		var resp := ATProtoResolveHandleResponse.new()
		resp.status = int(raw.get("status", 0))
		resp.raw_body = String(raw.get("raw", ""))

		if not raw.get("ok", false):
			var code := String(raw.get("error", "UnknownError"))
			var msg  := String(raw.get("message", ""))
			resp.error = code if msg.is_empty() else "%s: %s" % [code, msg]
			return resp

		var d: Dictionary = raw["data"]
		var r := ATProtoResolveHandleData.new()

		r.did = String(d.get("did", ""))
		r.raw = d

		resp.data = r
		return resp
