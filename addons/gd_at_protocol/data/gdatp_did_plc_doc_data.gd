class_name ATProtoDidPlcDocData
extends RefCounted

var context: Array[String] = []
var id: String = ""
var also_known_as: Array[String] = []
var verification_methods: Array[VerificationMethod] = []
var services: Array[Service] = []
var pds_endpoint: String = ""
var raw: Dictionary = {}

static func from_dict(d: Dictionary) -> ATProtoDidPlcDocData:
	var doc := ATProtoDidPlcDocData.new()

	# @context
	doc.context = []
	var ctx = d.get("@context", [])
	if typeof(ctx) == TYPE_ARRAY:
		for v in ctx:
			doc.context.append(String(v))

	# id
	doc.id = String(d.get("id", ""))

	# alsoKnownAs
	doc.also_known_as = []
	var aka = d.get("alsoKnownAs", [])
	if typeof(aka) == TYPE_ARRAY:
		for v in aka:
			doc.also_known_as.append(String(v))

	# verificationMethod[]
	doc.verification_methods = []
	var vms = d.get("verificationMethod", [])
	if typeof(vms) == TYPE_ARRAY:
		for item in vms:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var vm_dict: Dictionary = item
			var vm := ATProtoDidPlcDocData.VerificationMethod.new()
			vm.id        = String(vm_dict.get("id", ""))
			vm.type      = String(vm_dict.get("type", ""))
			vm.controller = String(vm_dict.get("controller", ""))
			vm.public_key_multibase = String(vm_dict.get("publicKeyMultibase", ""))
			doc.verification_methods.append(vm)

	# service[]
	doc.services = []
	doc.pds_endpoint = ""
	var svc = d.get("service", [])
	if typeof(svc) == TYPE_ARRAY:
		for item in svc:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var s_dict: Dictionary = item
			var s := ATProtoDidPlcDocData.Service.new()
			s.id = String(s_dict.get("id", ""))
			s.type = String(s_dict.get("type", ""))
			s.service_endpoint = String(s_dict.get("serviceEndpoint", ""))

			doc.services.append(s)

			if s.type == "AtprotoPersonalDataServer" and doc.pds_endpoint.is_empty():
				doc.pds_endpoint = s.service_endpoint

	doc.raw = d
	return doc

class Response:
	extends ATProtoResponse

	var data: ATProtoDidPlcDocData = null

	static func from_raw(raw: Dictionary) -> ATProtoDidPlcDocData.Response:
		var resp := ATProtoDidPlcDocData.Response.new()
		resp.status = int(raw.get("status", 0))
		resp.raw_body = String(raw.get("raw", ""))

		if not raw.get("ok", false):
			var code := String(raw.get("error", "UnknownError"))
			var msg  := String(raw.get("message", ""))
			resp.error = code if msg.is_empty() else "%s: %s" % [code, msg]
			return resp

		var d: Dictionary = raw["data"]
		var doc := ATProtoDidPlcDocData.new()

		# @context
		doc.context = []
		var ctx = d.get("@context", [])
		if typeof(ctx) == TYPE_ARRAY:
			for v in ctx:
				doc.context.append(String(v))

		# id
		doc.id = String(d.get("id", ""))

		# alsoKnownAs
		doc.also_known_as = []
		var aka = d.get("alsoKnownAs", [])
		if typeof(aka) == TYPE_ARRAY:
			for v in aka:
				doc.also_known_as.append(String(v))

		# verificationMethod[]
		doc.verification_methods = []
		var vms = d.get("verificationMethod", [])
		if typeof(vms) == TYPE_ARRAY:
			for item in vms:
				if typeof(item) != TYPE_DICTIONARY:
					continue
				var vm_dict: Dictionary = item
				var vm := ATProtoDidPlcDocData.VerificationMethod.new()
				vm.id        = String(vm_dict.get("id", ""))
				vm.type      = String(vm_dict.get("type", ""))
				vm.controller = String(vm_dict.get("controller", ""))
				vm.public_key_multibase = String(vm_dict.get("publicKeyMultibase", ""))
				doc.verification_methods.append(vm)

		# service[]
		doc.services = []
		doc.pds_endpoint = ""
		var svc = d.get("service", [])
		if typeof(svc) == TYPE_ARRAY:
			for item in svc:
				if typeof(item) != TYPE_DICTIONARY:
					continue
				var s_dict: Dictionary = item
				var s := ATProtoDidPlcDocData.Service.new()
				s.id = String(s_dict.get("id", ""))
				s.type = String(s_dict.get("type", ""))
				s.service_endpoint = String(s_dict.get("serviceEndpoint", ""))

				doc.services.append(s)

				# convenience: capture PDS endpoint
				if s.type == "AtprotoPersonalDataServer" and doc.pds_endpoint.is_empty():
					doc.pds_endpoint = s.service_endpoint

		doc.raw = d
		resp.data = doc
		return resp

class VerificationMethod:
	extends RefCounted

	var id: String = ""
	var type: String = ""
	var controller: String = ""
	var public_key_multibase: String = ""

class Service:
	extends RefCounted

	var id: String = ""
	var type: String = ""
	var service_endpoint: String = ""
