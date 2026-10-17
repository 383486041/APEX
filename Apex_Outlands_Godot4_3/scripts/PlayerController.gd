class_name PlayerController
extends CharacterBody3D
## Authentic Apex Legends First-Person Movement, Camera Look & Physics Controller for Godot 4.3.
## Fixes mouse control via _input() handling, click-to-capture, right-click drag fallback, and arrow-key backup.
## Supports Sprint, Momentum Slide, Wall Mantle/Climb, Wall-Bounce, Jump Pad Double-Jump,
## Pathfinder 3D Grappling Hook, Zipline Riding, Valkyrie VTOL Jets, and Gibraltar 3D Gun Shield.

@export var base_speed: float = 9.5
@export var sprint_speed: float = 14.2
@export var slide_speed: float = 19.5
@export var jump_velocity: float = 11.2
@export var gravity: float = 24.5

var camera: Camera3D
var viewmodel_holder: Node3D
var gun_shield_mesh: MeshInstance3D
var grapple_beam: MeshInstance3D

var weapon_ctrl: Node = null
var player_body_rig: Node3D = null
var is_third_person: bool = false
var target_cam_pos: Vector3 = Vector3(0, 1.68, 0)

var yaw: float = 0.0
var pitch: float = 0.0
var recoil_pitch: float = 0.0
var recoil_yaw: float = 0.0
var cam_shake: float = 0.0

var is_sliding: bool = false
var slide_timer: float = 0.0
var is_skydiving: bool = false
var in_dropship: bool = false
var double_jump_ready: bool = false
var is_ads: bool = false
var bob_time: float = 0.0

# Pathfinder Grapple & Zipline States
var grapple_active: bool = false
var grapple_point: Vector3 = Vector3.ZERO
var grapple_timer: float = 0.0

var zipline_active: bool = false
var zipline_start: Vector3 = Vector3.ZERO
var zipline_end: Vector3 = Vector3.ZERO
var zipline_t: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.35
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(50.0)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.85
	col.shape = cap
	col.position = Vector3(0, 0.925, 0)
	add_child(col)

	camera = Camera3D.new()
	camera.name = "PlayerCamera3D"
	camera.position = Vector3(0, 1.68, 0)
	camera.fov = 78.0
	camera.near = 0.02
	camera.current = true
	add_child(camera)

	viewmodel_holder = Node3D.new()
	viewmodel_holder.name = "ViewmodelHolder"
	camera.add_child(viewmodel_holder)

	# Gibraltar 3D Arm Gun Shield (visible when Gibraltar aims down sights)
	gun_shield_mesh = MeshInstance3D.new()
	var gs_box := BoxMesh.new()
	gs_box.size = Vector3(0.68, 0.48, 0.02)
	gun_shield_mesh.mesh = gs_box
	var gs_mat := StandardMaterial3D.new()
	gs_mat.albedo_color = Color(1.0, 0.48, 0.1, 0.32)
	gs_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gs_mat.emission_enabled = true
	gs_mat.emission = Color("#f97316")
	gs_mat.emission_energy_multiplier = 2.0
	gun_shield_mesh.material_override = gs_mat
	gun_shield_mesh.position = Vector3(-0.18, -0.06, -0.52)
	gun_shield_mesh.visible = false
	camera.add_child(gun_shield_mesh)

	# Pathfinder 3D Grapple Rope Mesh
	grapple_beam = MeshInstance3D.new()
	var rope_cyl := CylinderMesh.new()
	rope_cyl.top_radius = 0.022
	rope_cyl.bottom_radius = 0.022
	rope_cyl.height = 1.0
	grapple_beam.mesh = rope_cyl
	var rope_mat := StandardMaterial3D.new()
	rope_mat.albedo_color = Color("#facc15")
	rope_mat.metallic = 0.85
	rope_mat.roughness = 0.25
	grapple_beam.material_override = rope_mat
	grapple_beam.visible = false
	add_child(grapple_beam)

	rebuild_viewmodel()

func rebuild_viewmodel() -> void:
	for c in viewmodel_holder.get_children():
		c.queue_free()
	var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
	var wid: String = str(slot.get("weapon_id", "empty"))
	var is_heirloom: bool = (PlayerState.active_slot == 2 or wid == "empty" or wid == "")
	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	var wep: Dictionary = GameData.get_weapon_by_id(wid)
	var optic_id: String = str(slot.get("optic", "2x_bruiser"))
	var mesh_node := WeaponMeshBuilder.create_viewmodel(wep, is_heirloom, leg, optic_id)
	viewmodel_holder.add_child(mesh_node)

	# Build full-body articulated 3D character rig for shadow casting & 3rd-person camera
	if is_instance_valid(player_body_rig):
		player_body_rig.queue_free()
	player_body_rig = LegendRigBuilder.create_legend_rig(leg)
	player_body_rig.name = "PlayerBodyRig"
	add_child(player_body_rig)
	_update_body_perspective()

func _update_body_perspective() -> void:
	if player_body_rig == null:
		return
	var head_node: Node3D = player_body_rig.find_child("NeckPivot", true, false)
	var wep_mesh: Node3D = player_body_rig.find_child("HeldWeaponRoot", true, false)
	if is_third_person:
		player_body_rig.visible = true
		if head_node: head_node.visible = true
		if wep_mesh: wep_mesh.visible = (PlayerState.active_slot != 2)
		viewmodel_holder.visible = false
	else:
		# In first person, completely hide the 3rd person body rig so it never obstructs the camera!
		player_body_rig.visible = false
		viewmodel_holder.visible = true

func add_camera_recoil(v_kick: float, h_kick: float, shake: float = 0.015) -> void:
	recoil_pitch += v_kick
	recoil_yaw += h_kick
	cam_shake = minf(0.06, cam_shake + shake)

func start_grapple(target_pt: Vector3) -> void:
	grapple_active = true
	grapple_point = target_pt
	grapple_timer = 1.45
	grapple_beam.visible = true
	AudioSynthesizer.play_ability("grapple")

func start_zipline(p_start: Vector3, p_end: Vector3) -> void:
	zipline_active = true
	zipline_start = p_start
	zipline_end = p_end
	zipline_t = 0.0
	AudioSynthesizer.play_ability("grapple")

func _input(event: InputEvent) -> void:
	if PlayerState.ui_modal_open or PlayerState.inventory_open:
		is_ads = false
		return

	# F5 key toggles Third-Person / First-Person Camera Perspective
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			is_third_person = not is_third_person
			_update_body_perspective()
			var tip: String = "已切换为【第三人称视角】(按 F5 切换)" if is_third_person else "已切换为【第一人称视角】(按 F5 切换)"
			PlayerState.toast_pushed.emit(tip, Color("#38bdf8"))

	# Auto-capture mouse on click in 3D view & handle Right-Click ADS
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			is_ads = mb.pressed
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT):
			if mb.position.x < 1320 or mb.position.y > 90: # Avoid top-right menu button area
				if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Smooth 360 Mouse Look (works in MOUSE_MODE_CAPTURED or while holding Left/Right mouse button)
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var can_look: bool = (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if can_look:
			var sens: float = 0.0014 if is_ads else 0.0025
			yaw -= mm.relative.x * sens
			pitch = clampf(pitch - mm.relative.y * sens, -1.42, 1.42)

func _physics_process(delta: float) -> void:
	# Backup keyboard arrow look so camera is always controllable even without mouse lock
	if not PlayerState.ui_modal_open:
		var key_turn: float = 2.1 * delta
		if Input.is_key_pressed(KEY_LEFT):
			yaw += key_turn
		if Input.is_key_pressed(KEY_RIGHT):
			yaw -= key_turn
		if Input.is_key_pressed(KEY_UP):
			pitch = clampf(pitch + key_turn * 0.8, -1.42, 1.42)
		if Input.is_key_pressed(KEY_DOWN):
			pitch = clampf(pitch - key_turn * 0.8, -1.42, 1.42)

	# Smoothly decay recoil kick
	recoil_pitch = lerpf(recoil_pitch, 0.0, delta * 10.0)
	recoil_yaw = lerpf(recoil_yaw, 0.0, delta * 10.0)
	cam_shake = lerpf(cam_shake, 0.0, delta * 16.0)

	rotation.y = yaw + recoil_yaw
	var shake_offset := Vector2(randf_range(-cam_shake, cam_shake), randf_range(-cam_shake, cam_shake))
	camera.rotation.x = clampf(pitch + recoil_pitch + shake_offset.y, -1.45, 1.45)

	# Gibraltar Gun Shield visibility
	gun_shield_mesh.visible = (PlayerState.selected_legend_id == "gibraltar" and is_ads and PlayerState.active_slot != 2 and PlayerState.gun_shield_hp > 0.0)

	# Target FOV for ADS / Sprint / Stim
	var target_fov: float = 78.0
	if is_ads and PlayerState.active_slot != 2:
		var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
		var optic_info: Dictionary = GameData.get_optic_by_id(str(slot.get("optic", "2x_bruiser")))
		target_fov = float(optic_info["alt_fov"]) if PlayerState.scope_alt_zoom else float(optic_info["fov"])
	elif PlayerState.stim_timer > 0.0 or PlayerState.beast_timer > 0.0 or is_sliding:
		target_fov = 92.0
	camera.fov = lerpf(camera.fov, target_fov, delta * 12.0)

	if in_dropship:
		global_position += Vector3(22.0, 0.0, 18.0) * delta
		global_position.y = 115.0
		return

	if is_skydiving:
		var fwd: Vector3 = -camera.global_transform.basis.z
		velocity = Vector3(fwd.x * 52.0, minf(-16.0, fwd.y * 42.0), fwd.z * 52.0)
		move_and_slide()
		if is_on_floor() or global_position.y <= 1.8:
			is_skydiving = false
			global_position.y = maxf(0.5, global_position.y)
			AudioSynthesizer.play_ability("jumppad")
		return

	# Zipline Riding
	if zipline_active:
		var total_len: float = maxf(1.0, zipline_start.distance_to(zipline_end))
		zipline_t += (30.0 / total_len) * delta
		global_position = zipline_start.lerp(zipline_end, clampf(zipline_t, 0.0, 1.0)) + Vector3(0, -1.2, 0)
		if zipline_t >= 1.0 or Input.is_key_pressed(KEY_SPACE):
			zipline_active = false
			velocity = (zipline_end - zipline_start).normalized() * 16.0 + Vector3(0, 10.5, 0)
		return

	# Pathfinder Grappling Hook Pendulum Pull
	if grapple_active:
		grapple_timer -= delta
		var hand_pos: Vector3 = global_position + Vector3(0, 1.35, 0)
		var to_target: Vector3 = grapple_point - hand_pos
		var dist: float = to_target.length()
		if dist < 2.2 or grapple_timer <= 0.0 or Input.is_key_pressed(KEY_C):
			grapple_active = false
			grapple_beam.visible = false
		else:
			var pull_dir: Vector3 = to_target.normalized()
			var look_fwd: Vector3 = -camera.global_transform.basis.z
			velocity = (pull_dir * 26.0 + look_fwd * 10.0 + Vector3(0, 6.5, 0))
			# Update 3D Grapple Rope transform
			var mid: Vector3 = (hand_pos + grapple_point) * 0.5
			grapple_beam.global_position = mid
			grapple_beam.scale = Vector3(1.0, dist, 1.0)
			var up_dir: Vector3 = Vector3.UP if absf(pull_dir.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
			grapple_beam.look_at(grapple_point, up_dir)
			grapple_beam.rotate_object_local(Vector3.RIGHT, PI * 0.5)
			move_and_slide()
			return

	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	input_dir = input_dir.normalized()

	var sprinting: bool = Input.is_key_pressed(KEY_SHIFT) and not is_ads
	var crouching: bool = Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_CTRL)

	if crouching and sprinting and is_on_floor() and not is_sliding and input_dir.length() > 0.1:
		is_sliding = true
		slide_timer = 0.88
		AudioSynthesizer.play_melee_Whoosh(false)

	if slide_timer > 0.0:
		slide_timer -= delta
		if slide_timer <= 0.0 and not crouching:
			is_sliding = false
	elif not crouching:
		is_sliding = false

	var spd: float = base_speed
	if sprinting and input_dir.y < 0.0:
		spd = sprint_speed
	if is_sliding and slide_timer > 0.0:
		spd = slide_speed
	elif crouching:
		spd = 6.2

	if PlayerState.stim_timer > 0.0 or PlayerState.void_timer > 0.0 or PlayerState.beast_timer > 0.0 or PlayerState.double_time_timer > 0.0:
		spd *= 1.35
	if is_ads:
		spd *= 0.72

	var move_vec: Vector3 = (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if move_vec.length() > 0.01:
		var accel: float = 12.0 if is_on_floor() else (8.0 if PlayerState.selected_legend_id == "horizon" else 4.5)
		velocity.x = lerpf(velocity.x, move_vec.x * spd, delta * accel)
		velocity.z = lerpf(velocity.z, move_vec.z * spd, delta * accel)
		bob_time += delta * (13.5 if sprinting else 9.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, spd * 6.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, spd * 6.0 * delta)

	# Gravity, Wall-Climb, Lifeline Glide & Valkyrie VTOL
	if not is_on_floor():
		var grav_mult: float = 1.0
		if PlayerState.selected_legend_id == "lifeline" and Input.is_key_pressed(KEY_SPACE) and velocity.y < 0.0:
			grav_mult = 0.25 # D.O.C. Drone Slow Glide
		velocity.y -= gravity * grav_mult * delta
		if is_on_wall() and Input.is_key_pressed(KEY_W) and velocity.y < 4.5:
			velocity.y = 7.8
		if PlayerState.selected_legend_id == "valkyrie" and PlayerState.vtol_fuel < 100.0 and not Input.is_key_pressed(KEY_SPACE):
			PlayerState.vtol_fuel = minf(100.0, PlayerState.vtol_fuel + 18.0 * delta)
	else:
		double_jump_ready = false
		if PlayerState.vtol_fuel < 100.0:
			PlayerState.vtol_fuel = minf(100.0, PlayerState.vtol_fuel + 35.0 * delta)

	if Input.is_key_pressed(KEY_SPACE):
		if is_on_floor():
			velocity.y = jump_velocity + (2.2 if is_sliding else 0.0)
		elif is_on_wall():
			var wn: Vector3 = get_wall_normal()
			velocity = wn * 14.5 + Vector3(0, 11.8, 0)
		elif double_jump_ready:
			velocity.y = 14.2
			double_jump_ready = false
			AudioSynthesizer.play_ability("jumppad")
		elif PlayerState.selected_legend_id == "valkyrie" and PlayerState.vtol_fuel > 2.0:
			velocity.y = lerpf(velocity.y, 8.8, delta * 8.0)
			PlayerState.vtol_fuel = maxf(0.0, PlayerState.vtol_fuel - 28.0 * delta)

	if is_third_person:
		target_cam_pos = Vector3(0.55, 1.25 if (is_sliding or crouching) else 1.85, 2.2)
	else:
		target_cam_pos = Vector3(0, 1.02 if (is_sliding or crouching) else 1.68, 0)
	camera.position = camera.position.lerp(target_cam_pos, delta * 14.0)
	camera.rotation.z = lerpf(camera.rotation.z, -0.12 if is_sliding else 0.0, delta * 10.0)

	move_and_slide()

	# Drive procedural 3D character body rig animations only when in 3rd-person mode
	if player_body_rig != null and is_third_person:
		var firing: bool = false
		var reloading: bool = false
		if weapon_ctrl != null:
			firing = (Time.get_ticks_msec() - int(weapon_ctrl.get("last_fire_ms"))) < 160
			reloading = float(weapon_ctrl.get("reload_timer")) > 0.0
		var is_air: bool = not is_on_floor() and not is_sliding and not zipline_active and not grapple_active and not is_skydiving
		LegendRigBuilder.animate_rig(player_body_rig, delta, {
			"mode": "combat",
			"is_moving": input_dir.length() > 0.1 and is_on_floor() and not is_sliding,
			"is_sliding": is_sliding,
			"is_crouching": crouching and not is_sliding,
			"is_in_air": is_air,
			"is_ziplining": zipline_active,
			"is_grappling": grapple_active,
			"is_healing": PlayerState.heal_cast_timer > 0.0,
			"is_heirloom": (PlayerState.active_slot == 2),
			"is_reloading": reloading,
			"is_firing": firing,
			"strafe_phase": bob_time,
			"strafe_dir": input_dir.x,
			"speed": velocity.length(),
			"time": Time.get_ticks_msec() / 1000.0
		})
