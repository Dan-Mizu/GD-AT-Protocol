@abstract
class_name ATProtoResponse
extends RefCounted

var status: int = 0
var error: String = ""      # empty string = OK
var raw_body: String = ""   # raw JSON string (for debugging, logs)

func is_ok() -> bool: return error.is_empty()
