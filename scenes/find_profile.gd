extends Control

# inputs
@export var handle_line_edit: LineEdit

# profile
@export var profile_card_panel_container: PanelContainer
@export var profile_avatar_texture_rect: TextureRect
@export var profile_banner_texture_rect: TextureRect
@export var profile_name_label: Label
@export var profile_description_label: Label
@export var profile_follower_count_label: Label
@export var profile_following_count_label: Label

func _ready() -> void: profile_card_panel_container.visible = false

func _on_send_button_pressed() -> void: _get_profile()

func _on_handle_line_edit_text_submitted(_new_text: String) -> void: _get_profile()

func _get_profile() -> void:
	if not handle_line_edit.text.is_empty():
		profile_card_panel_container.visible = false

		# get profile data
		var res: Dictionary = await ATProto.get_profile(handle_line_edit.text)

		# failed
		if not res.get("ok", false):
			push_error("Failed to get profile: %s" % res)
			handle_line_edit.clear()
			profile_card_panel_container.visible = false
			return

		# success
		var profile_data: Dictionary = res["data"]
		print("Profile data: ", profile_data)

		profile_name_label.text = profile_data.get("displayName", "")
		profile_description_label.text = profile_data.get("description", "")
		profile_follower_count_label.text = str(profile_data.get("followersCount", ""))
		profile_following_count_label.text = str(profile_data.get("followsCount", ""))

		var avatar_url: String = profile_data.get("avatar", "")
		if avatar_url.is_empty(): profile_avatar_texture_rect.texture = null
		else: await _set_texture_from_url(profile_avatar_texture_rect, avatar_url)

		var banner_url: String = profile_data.get("banner", "")
		if banner_url.is_empty(): profile_banner_texture_rect.texture = null
		else: await _set_texture_from_url(profile_banner_texture_rect, banner_url)

		profile_card_panel_container.visible = true

func _set_texture_from_url(target: TextureRect, url: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)

	var error := http.request(url)
	if error != OK:
		push_error("Error starting HTTP request for image: %s" % url)
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
		push_error("HTTP image request failed (result=%d, code=%d) for %s" % [req_result, response_code, url])
		return

	var image := Image.new()

	var err := image.load_jpg_from_buffer(body)
	if err != OK: err = image.load_png_from_buffer(body)
	if err != OK:
		push_error("Couldn't load image from buffer for %s" % url)
		return

	var texture := ImageTexture.create_from_image(image)
	target.texture = texture
