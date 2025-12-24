class_name ATProtoDescribeRepoData
extends RefCounted

var did: String = ""
var handle: String = ""
var did_doc: ATProtoDidPlcDocData = null
var collections: Array[String] = []
var indexed_at: String = ""
var raw: Dictionary = {}

class Response:
	extends ATProtoResponse

	var data: ATProtoDescribeRepoData = null

	static func from_raw(raw: Dictionary) -> ATProtoDescribeRepoData.Response:
		var resp := ATProtoDescribeRepoData.Response.new()
		resp.status = int(raw.get("status", 0))
		resp.raw_body = String(raw.get("raw", ""))

		if not raw.get("ok", false):
			var code := String(raw.get("error", "UnknownError"))
			var msg  := String(raw.get("message", ""))
			resp.error = code if msg.is_empty() else "%s: %s" % [code, msg]
			return resp

		var d: Dictionary = raw["data"]
		var doc := ATProtoDescribeRepoData.new()

		doc.did = String(d.get("did", ""))
		doc.handle = String(d.get("handle", ""))

		# Strongly typed DID doc
		var dd = d.get("didDoc", {})
		if typeof(dd) == TYPE_DICTIONARY:
			doc.did_doc = ATProtoDidPlcDocData.from_dict(dd)
		else:
			doc.did_doc = null

		doc.indexed_at = String(d.get("indexedAt", ""))

		doc.collections = []
		var cols = d.get("collections", [])
		if typeof(cols) == TYPE_ARRAY:
			for v in cols:
				doc.collections.append(String(v))

		doc.raw = d
		resp.data = doc
		return resp
