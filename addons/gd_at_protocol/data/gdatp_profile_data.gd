class_name ATProtoProfileData
extends RefCounted

var did: String = ""
var handle: String = ""
var display_name: String = ""
var avatar_url: String = ""
var associated: ATProtoProfileData.AssociatedData = null
var labels: Array = []
var created_at: String = ""
var verification: ATProtoProfileData.VerificationData = null
var description: String = ""
var indexed_at: String = ""
var banner_url: String = ""
var followers_count: int = 0
var follows_count: int = 0
var posts_count: int = 0
var pinned_post: ATProtoProfileData.PinnedPostData = null
var raw: Dictionary = {}

class Response:
	extends ATProtoResponse

	var data: ATProtoProfileData = null

	static func from_raw(raw: Dictionary) -> ATProtoProfileData.Response:
		var resp := ATProtoProfileData.Response.new()
		resp.status = int(raw.get("status", 0))
		resp.raw_body = String(raw.get("raw", ""))

		if not raw.get("ok", false):
			var code := String(raw.get("error", "UnknownError"))
			var msg  := String(raw.get("message", ""))
			resp.error = code if msg.is_empty() else "%s: %s" % [code, msg]
			return resp

		var d: Dictionary = raw["data"]
		var p := ATProtoProfileData.new()

		# Basic fields
		p.did             = String(d.get("did", ""))
		p.handle          = String(d.get("handle", ""))
		p.display_name    = String(d.get("displayName", ""))
		p.description     = String(d.get("description", ""))
		p.avatar_url      = String(d.get("avatar", ""))
		p.banner_url      = String(d.get("banner", ""))
		p.followers_count = int(d.get("followersCount", 0))
		p.follows_count   = int(d.get("followsCount", 0))
		p.posts_count     = int(d.get("postsCount", 0))

		p.created_at      = String(d.get("createdAt", ""))
		p.indexed_at      = String(d.get("indexedAt", ""))
		p.labels          = d.get("labels", [])

		# associated
		if d.has("associated") and typeof(d["associated"]) == TYPE_DICTIONARY:
			var a_dict: Dictionary = d["associated"]
			var a := ATProtoProfileData.AssociatedData.new()

			a.lists         = float(a_dict.get("lists", 0.0))
			a.feedgens      = float(a_dict.get("feedgens", 0.0))
			a.starter_packs = float(a_dict.get("starterPacks", 0.0))
			a.labeler       = bool(a_dict.get("labeler", false))

			# chat: { allowIncoming: "all" }
			if a_dict.has("chat") and typeof(a_dict["chat"]) == TYPE_DICTIONARY:
				var chat_dict: Dictionary = a_dict["chat"]
				a.chat = {}
				# keep only strings here for now
				for k in chat_dict.keys():
					a.chat[String(k)] = String(chat_dict[k])

			# activitySubscription: { allowSubscriptions: "followers" }
			if a_dict.has("activitySubscription") and typeof(a_dict["activitySubscription"]) == TYPE_DICTIONARY:
				var act_dict: Dictionary = a_dict["activitySubscription"]
				a.activity_subscription = {}
				for k in act_dict.keys():
					a.activity_subscription[String(k)] = String(act_dict[k])

			p.associated = a

		# verification
		if d.has("verification") and typeof(d["verification"]) == TYPE_DICTIONARY:
			var v_dict: Dictionary = d["verification"]
			var v := ATProtoProfileData.VerificationData.new()

			v.verified_status         = String(v_dict.get("verifiedStatus", ""))
			v.trusted_verifier_status = String(v_dict.get("trustedVerifierStatus", ""))

			v.verifications = []

			var verifs: Array = v_dict.get("verifications", [])
			for item in verifs:
				if typeof(item) != TYPE_DICTIONARY:
					continue
				var item_dict: Dictionary = item
				var vv := ATProtoProfileData.VerificationVerificationsData.new()
				vv.issuer     = String(item_dict.get("issuer", ""))
				vv.uri        = String(item_dict.get("uri", ""))
				vv.is_valid   = bool(item_dict.get("isValid", false))
				vv.created_at = String(item_dict.get("createdAt", ""))
				v.verifications.append(vv)

			p.verification = v

		# pinnedPost
		if d.has("pinnedPost") and typeof(d["pinnedPost"]) == TYPE_DICTIONARY:
			var pp_dict: Dictionary = d["pinnedPost"]
			var pp := ATProtoProfileData.PinnedPostData.new()
			pp.cid = String(pp_dict.get("cid", ""))
			pp.uri = String(pp_dict.get("uri", ""))
			p.pinned_post = pp

		p.raw = d

		resp.data = p
		return resp

class AssociatedData:
	extends RefCounted

	var lists: float = 0.0
	var feedgens: float = 0.0
	var starter_packs: float = 0.0
	var labeler: bool = false
	var chat: Dictionary[String, String] = {}
	var activity_subscription: Dictionary[String, String] = {}

class VerificationData:
	extends RefCounted

	var verifications: Array[ATProtoProfileData.VerificationVerificationsData] = []
	var verified_status: String = ""
	var trusted_verifier_status: String = ""

class VerificationVerificationsData:
	extends RefCounted

	var issuer: String = ""
	var uri: String = ""
	var is_valid: bool = false
	var created_at: String = ""

class PinnedPostData:
	extends RefCounted

	var cid: String = ""
	var uri: String = ""
