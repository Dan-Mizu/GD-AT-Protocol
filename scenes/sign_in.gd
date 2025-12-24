extends Control

# internal
var _profile: ATProtoProfileData
var _did_doc: ATProtoDidPlcDocData

#region Linking Scene Nodes to Variables
# inputs
@export var handle_line_edit: LineEdit
@export var password_line_edit: LineEdit

# views
@export var profile_container: PanelContainer
@export var handle_input_container: HBoxContainer
@export var password_input_container: HBoxContainer
@export var spinner_container: MarginContainer

# profile
@export var profile_avatar_texture_rect: TextureRect
@export var profile_name_label: Label
@export var profile_handle_label: Label
@export var profile_back_button: Panel
@export var profile_sign_out_button: Panel
#endregion

#region Scene Initialization
func _ready() -> void: _reset()
#endregion

#region Signals
func _on_handle_send_button_pressed() -> void: _get_profile()
func _on_handle_line_edit_text_submitted(_new_text: String) -> void: _get_profile()
func _on_password_line_edit_text_submitted(_new_text: String) -> void: _log_in()
func _on_password_send_button_pressed() -> void: _log_in()
func _on_back_button_pressed() -> void: _reset()
func _on_sign_out_button_pressed() -> void: _reset()
#endregion

func _get_profile():
	# no input
	if handle_line_edit.text.is_empty(): return

	# loading
	handle_input_container.visible = false
	spinner_container.visible = true

	## get handle
	#var handle: ATProtoResolveHandleData.Response = await ATProto.resolve_handle(handle_line_edit.text)
	#if not handle.is_ok():
		#_on_error("Failed to get handle: %s" % handle.error)
		#_reset()
		#return

	# get profile
	var profile: ATProtoProfileData.Response = await ATProto.get_profile(handle_line_edit.text)
	if not profile.is_ok():
		Utility.on_error("Failed to get profile\n%s" % profile.error)
		_reset()
		return
	_profile = profile.data

	# get DID doc
	var did_doc: ATProtoDidPlcDocData.Response = await ATProto.get_did_plc_doc(profile.data.did)
	if not did_doc.is_ok():
		Utility.on_error("Failed to fetch DID doc\n%s" % did_doc.error)
		_reset()
		return
	_did_doc = did_doc.data

	# get PDS URL
	if _did_doc.pds_endpoint.is_empty():
		Utility.on_error("No PDS endpoint found in DID doc.")
		_reset()
		return

	# show profile
	profile_handle_label.text = "@" + _profile.handle
	profile_name_label.text = profile.data.display_name
	if profile.data.avatar_url: await Utility.set_texture_from_url(profile_avatar_texture_rect, profile.data.avatar_url)
	else: profile_avatar_texture_rect.texture = null
	profile_container.visible = true

	# done loading
	spinner_container.visible = false

	# show and focus password input
	password_input_container.visible = true
	password_line_edit.grab_focus()

func _log_in() -> void:
	# no input
	if password_line_edit.text.is_empty(): return

	# loading
	spinner_container.visible = true
	password_input_container.visible = false

	# log in
	var session_res: ATProtoSessionData.Response = await ATProto.create_session(_profile.handle, password_line_edit.text, _did_doc.pds_endpoint)

	# login failed
	if not session_res.is_ok():
		Utility.on_error("Login failed\n%s" % session_res.error)

		# reset password field
		password_line_edit.clear()
		password_input_container.visible = true
		password_line_edit.grab_focus()

		# hide loading spinner
		spinner_container.visible = false

		# skip the rest
		return

	# done loading
	spinner_container.visible = false

	# switch to sign out button
	profile_back_button.visible = false
	profile_sign_out_button.visible = true

	# successfully signed in
	var session: ATProtoSessionData = session_res.data
	Utility.on_success("Signed In As @%s\nDID: %s" % [session.handle, session.did])

	# get collections
	var repo_res: ATProtoDescribeRepoData.Response = await ATProto.describe_repo(session.did)
	if not repo_res.is_ok():
		Utility.on_error("Failed to describe repo\n%s" % repo_res.error)
		return
	var repo: ATProtoDescribeRepoData = repo_res.data
	if repo.collections.is_empty():
		print("No collections.")
		return
	else:
		prints("Collections for repo:", repo.collections)

	## list records
	#for col in repo.collections:
		#print("\n=== Collection %s ===" % col)
		#var records: Array[ATProtoListRecordsData.Record] = await ATProto.fetch_all_records_for_collection(
			#repo.did,
			#col
		#)
		#print("Found %d records" % records.size())
#
		#for rec in records:
			#var rkey := ""
			#var parts := rec.uri.split("/")
			#if parts.size() >= 4: rkey = parts[3]
#
			#prints(
				#"rkey:", rkey,
				#"uri:", rec.uri,
				#"cid:", rec.cid,
				#"indexedAt:", rec.indexed_at,
				#"value:", rec.value
			#)

func _reset() -> void:
	# clear inputs
	handle_line_edit.clear()
	password_line_edit.clear()

	# hide subsequent containers
	profile_container.visible = false
	password_input_container.visible = false
	spinner_container.visible = false
	profile_back_button.visible = true
	profile_sign_out_button.visible = false

	# clear state
	_profile = null
	_did_doc = null

	# show initial state
	handle_input_container.visible = true
	handle_line_edit.grab_focus()
