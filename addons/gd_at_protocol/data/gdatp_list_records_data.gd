class_name ATProtoListRecordsData
extends RefCounted

var cursor: String = ""
var records: Array[Record] = []
var raw: Dictionary = {}

class Response:
	extends ATProtoResponse
	var data: ATProtoListRecordsData = null

	static func from_raw(raw: Dictionary) -> ATProtoListRecordsData.Response:
		var resp := ATProtoListRecordsData.Response.new()
		resp.status = int(raw.get("status", 0))
		resp.raw_body = String(raw.get("raw", ""))

		if not raw.get("ok", false):
			var code := String(raw.get("error", "UnknownError"))
			var msg  := String(raw.get("message", ""))
			resp.error = code if msg.is_empty() else "%s: %s" % [code, msg]
			return resp

		var d: Dictionary = raw["data"]
		var doc := ATProtoListRecordsData.new()

		doc.cursor = String(d.get("cursor", ""))

		doc.records = []
		var recs = d.get("records", [])
		if typeof(recs) == TYPE_ARRAY:
			for item in recs:
				if typeof(item) != TYPE_DICTIONARY:
					continue
				var r_dict: Dictionary = item
				var r := ATProtoListRecordsData.Record.new()
				r.uri = String(r_dict.get("uri", ""))
				r.cid = String(r_dict.get("cid", ""))
				r.indexed_at = String(r_dict.get("indexedAt", ""))
				r.value = r_dict.get("value", {})
				doc.records.append(r)

		doc.raw = d
		resp.data = doc
		return resp

class Record:
	extends RefCounted

	var uri: String = ""
	var cid: String = ""
	var value: Dictionary = {}
	var indexed_at: String = ""
