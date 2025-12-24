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
	handle_line_edit.grab_focus()
#endregion

#region Signals
func _on_send_button_pressed() -> void: _get_profile()
func _on_handle_line_edit_text_submitted(_new_text: String) -> void: _get_profile()
#endregion

#region Get the AT Proto Profile of a user from their Handle
func _get_profile() -> void:
	# no input
	if handle_line_edit.text.is_empty(): return

	# show loading spinner
	profile_card_panel_container.visible = false
	spinner_container.visible = true

	# get profile data
	var profile: ATProtoProfileData.Response = await ATProto.get_profile(handle_line_edit.text)

	# failed
	if not profile.is_ok():
		Utility.on_error("Failed to get profile\n%s" % profile.error)
		handle_line_edit.clear()
		spinner_container.visible = false
		profile_card_panel_container.visible = false
		return

	# set profile text
	profile_name_label.text = profile.data.display_name
	profile_description_label.text = profile.data.description
	profile_follower_count_label.text = Utility.format_number_as_string(profile.data.followers_count)
	profile_following_count_label.text = Utility.format_number_as_string(profile.data.follows_count)

	# set profile images
	if profile.data.avatar_url: await Utility.set_texture_from_url(profile_avatar_texture_rect, profile.data.avatar_url)
	else: profile_avatar_texture_rect.texture = null
	if profile.data.banner_url: await Utility.set_texture_from_url(profile_banner_texture_rect, profile.data.banner_url)
	else: profile_banner_texture_rect.texture = null

	# show profile card
	spinner_container.visible = false
	profile_card_panel_container.visible = true
#endregion
