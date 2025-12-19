extends RefCounted
class_name ATProtoProfileData

var did: String = ""
var handle: String = ""
var display_name: String = ""
var description: String = ""
var avatar_url: String = ""
var banner_url: String = ""
var followers_count: int = 0
var follows_count: int = 0
var posts_count: int = 0
var raw: Dictionary = {}

class ATProtoProfileResponse:
	extends ATProtoResponse

	var data: ATProtoProfileData = null

	static func from_raw(raw: Dictionary) -> ATProtoProfileResponse:
		var resp := ATProtoProfileResponse.new()
		resp.status = int(raw.get("status", 0))
		resp.raw_body = String(raw.get("raw", ""))

		if not raw.get("ok", false):
			var code := String(raw.get("error", "UnknownError"))
			var msg  := String(raw.get("message", ""))
			resp.error = code if msg.is_empty() else "%s: %s" % [code, msg]
			return resp

		var d: Dictionary = raw["data"]
		var p := ATProtoProfileData.new()

		p.did             = String(d.get("did", ""))
		p.handle          = String(d.get("handle", ""))
		p.display_name    = String(d.get("displayName", ""))
		p.description     = String(d.get("description", ""))
		p.avatar_url      = String(d.get("avatar", ""))
		p.banner_url      = String(d.get("banner", ""))
		p.followers_count = int(d.get("followersCount", 0))
		p.follows_count   = int(d.get("followsCount", 0))
		p.posts_count     = int(d.get("postsCount", 0))
		p.raw             = d

		resp.data = p
		return resp
