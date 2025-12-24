extends Node

func format_number_as_string(number: int) -> String:
	var num_str: String = str(abs(number))
	var result: String = ""
	var count: int = 0

	for i in range(num_str.length() - 1, -1, -1):
		result = num_str[i] + result
		count += 1
		if count % 3 == 0 and i != 0:
			result = "," + result

	if number < 0:
		result = "-" + result

	return result

func set_texture_from_url(target: TextureRect, url: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)

	var error := http.request(url)
	if error != OK:
		on_error("Error starting HTTP request for image: %s" % url)
		http.queue_free()
		return

	# Wait for the request to finish
	var result: Array = await http.request_completed
	http.queue_free()

	var req_result: int = result[0]
	var response_code: int = result[1]
	var _headers: PackedStringArray = result[2]
	var body: PackedByteArray = result[3]

	if req_result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		on_error("HTTP image request failed (result=%d, code=%d) for %s" % [req_result, response_code, url])
		return

	var image := Image.new()

	var err := image.load_jpg_from_buffer(body)
	if err != OK: err = image.load_png_from_buffer(body)
	if err != OK:
		on_error("Couldn't load image from buffer for %s" % url)
		return

	var texture := ImageTexture.create_from_image(image)
	target.texture = texture

func on_success(success: String) -> void:
	print(success)
	ToastParty.show({
		"text": "✅ %s" % success,           # Text (emojis can be used)
		"bgcolor": Color(0.223, 1.0, 0.223, 0.5),     # Background Color
		"color": Color(1, 1, 1, 1),         # Text Color
		"gravity": "top",                   # top or bottom
		"direction": "center",               # left or center or right
		"text_size": 14,                    # [optional] Text (font) size // experimental (warning!)
		"use_font": true                    # [optional] Use custom ToastParty font // experimental (warning!)
	})

func on_error(error: String) -> void:
	push_error(error)
	ToastParty.show({
		"text": "❌ %s" % error,           # Text (emojis can be used)
		"bgcolor": Color(1.0, 0.223, 0.223, 0.5),     # Background Color
		"color": Color(1, 1, 1, 1),         # Text Color
		"gravity": "top",                   # top or bottom
		"direction": "center",               # left or center or right
		"text_size": 14,                    # [optional] Text (font) size // experimental (warning!)
		"use_font": true                    # [optional] Use custom ToastParty font // experimental (warning!)
	})
