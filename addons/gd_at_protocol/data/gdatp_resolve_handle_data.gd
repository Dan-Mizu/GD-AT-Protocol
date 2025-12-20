class_name ATProtoResolveHandleData
extends RefCounted

var did: String = ""
var raw: Dictionary = {}

class Response:
	extends ATProtoResponse

	var data: ATProtoResolveHandleData = null

	static func from_raw(raw: Dictionary) -> ATProtoResolveHandleData.Response:
		var resp := ATProtoResolveHandleData.Response.new()
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
