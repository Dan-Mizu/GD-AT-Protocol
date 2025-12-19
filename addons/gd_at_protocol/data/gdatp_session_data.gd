extends RefCounted
class_name ATProtoSessionData

var did: String = ""
var access_jwt: String = ""
var refresh_jwt: String = ""
var handle: String = ""
var email: String = ""
var raw: Dictionary = {}

class ATProtoSessionResponse:
	extends ATProtoResponse

	var data: ATProtoSessionData = null

	static func from_raw(raw: Dictionary) -> ATProtoSessionResponse:
		var resp := ATProtoSessionResponse.new()
		resp.status = int(raw.get("status", 0))
		resp.raw_body = String(raw.get("raw", ""))

		if not raw.get("ok", false):
			var code := String(raw.get("error", "UnknownError"))
			var msg  := String(raw.get("message", ""))
			resp.error = code if msg.is_empty() else "%s: %s" % [code, msg]
			return resp

		var d: Dictionary = raw["data"]
		var s := ATProtoSessionData.new()

		s.did         = String(d.get("did", ""))
		s.access_jwt  = String(d.get("accessJwt", ""))
		s.refresh_jwt = String(d.get("refreshJwt", ""))
		s.handle      = String(d.get("handle", ""))
		s.email       = String(d.get("email", ""))
		s.raw         = d

		resp.data = s
		return resp
