extends Control

#region Linking Scene Nodes to Variables
# inputs
@export var handle_line_edit: LineEdit

# views
@export var profile_card_panel_container: PanelContainer
@export var spinner_container: MarginContainer

# profile
@export var profile_avatar_texture_rect: TextureRect
@export var profile_banner_texture_rect: TextureRect
@export var profile_name_label: Label
@export var profile_description_label: Label
@export var profile_follower_count_label: Label
@export var profile_following_count_label: Label
#endregion

#region Scene Initialization
func _ready() -> void: 
	spinner_container.visible = false
	profile_card_panel_container.visible = false
#endregion

#region Signals
func _on_send_button_pressed() -> void: _get_profile()
func _on_handle_line_edit_text_submitted(_new_text: String) -> void: _get_profile()
#endregion

#region Get the AT Proto Profile of a user from their Handle
func _get_profile() -> void:
	# user typed in a handle
	if not handle_line_edit.text.is_empty():
		# show loading spinner
		profile_card_panel_container.visible = false
		spinner_container.visible = true

		# get profile data
		var res: ATProtoProfileData.ATProtoProfileResponse = await ATProto.get_profile(handle_line_edit.text)

		# failed
		if not res.is_ok():
			push_error("Failed to get profile: %s" % res.error)
			handle_line_edit.clear()
			spinner_container.visible = false
			profile_card_panel_container.visible = false
			return

		# success
		var profile_data: ATProtoProfileData = res.data
		print("Profile data: ", profile_data.raw)

		# set profile text
		profile_name_label.text = profile_data.display_name
		profile_description_label.text = profile_data.description
		profile_follower_count_label.text = format_number_as_string(profile_data.followers_count)
		profile_following_count_label.text = format_number_as_string(profile_data.follows_count)

		# set profile images
		var avatar_url: String = profile_data.avatar_url
		if avatar_url.is_empty(): profile_avatar_texture_rect.texture = null
		else: await _set_texture_from_url(profile_avatar_texture_rect, avatar_url)

		var banner_url: String = profile_data.banner_url
		if banner_url.is_empty(): profile_banner_texture_rect.texture = null
		else: await _set_texture_from_url(profile_banner_texture_rect, banner_url)

		# show profile card
		spinner_container.visible = false
		profile_card_panel_container.visible = true
#endregion

#region Helper Functions
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
#endregion
