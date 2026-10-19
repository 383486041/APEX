class_name PlayerController
extends CharacterBody3D
## Authentic Apex Legends First-Person & Third-Person Movement, Wall-Climb & Ledge Mantle (`爬墙与扒墙翻越`),
## Wall-Bounce (`蹬墙跳`), Momentum Slide (`滑铲`), Camera & Rig Controller for Godot 4.3.
## Features:
## - Full Apex Legends Wall-Climb State Machine (`is_wall_climbing`, `climb_timer`, `climb_fatigue` up to 1.55s / ~6.5m height)
##   with progressive vertical speed taper (`8.8 m/s` -> `3.2 m/s`), lateral wall-strafe, and rhythmic hand-over-hand audio/animation
## - Automatic Ledge Detection & Vault Mantle (`is_mantling`, `0.34s` smooth upward-and-forward ledge pull-up when clearing wall top)
## - Authentic Wall-Bounce (`蹬墙跳`) off climbable surfaces with `Space`
## - Landing Knee-Compression Spring (`land_compress_timer`) + Horizon Spacewalk soft-landing passive
## - Lower-Body / Upper-Body Direction Split (`move_angle_local`) for natural 3rd-person diagonal/strafe gait

@export var base_speed: float = 9.6
@export var sprint_speed: float = 14.4
@export var slide_speed: float = 20.8
@export var jump_velocity: float = 11.4
@export var gravity: float = 24.5

var camera: Camera3D
var viewmodel_holder: Node3D
var gun_shield_mesh: MeshInstance3D
var grapple_beam: MeshInstance3D

var weapon_ctrl: Node = null
var player_body_rig: Node3D = null
var is_third_person: bool = false
var target_cam_pos: Vector3 = Vector3(0, 1.68, 0)
var vm_wall_pullback: float = 0.0
var step_sound_accum: float = 0.0

var yaw: float = 0.0
var pitch: float = 0.0
var recoil_pitch: float = 0.0
var recoil_yaw: float = 0.0
var cam_shake: float = 0.0
var last_mouse_vel: Vector2 = Vector2.ZERO

var is_sliding: bool = false
var was_crouch_pressed: bool = false
var slide_timer: float = 0.0
var slide_cooldown: float = 0.0
var slide_dir: Vector3 = Vector3.ZERO
var is_skydiving: bool = false
var in_dropship: bool = false
var double_jump_ready: bool = false
var is_ads: bool = false
var bob_time: float = 0.0

# Wall-Climb & Ledge Mantle State Machine (`爬墙` & `扒墙翻越`)
var is_wall_climbing: bool = false
var climb_timer: float = 0.0
var climb_fatigue: float = 0.0
var climb_phase: float = 0.0
var climb_sound_accum: float = 0.0
var climb_wall_normal: Vector3 = Vector3.ZERO

var is_mantling: bool = false
var mantle_timer: float = 0.0
var mantle_duration: float = 0.34
var mantle_start_pos: Vector3 = Vector3.ZERO
var mantle_target_pos: Vector3 = Vector3.ZERO

var was_on_floor_prev: bool = true
var prev_fall_vel_y: float = 0.0
var land_compress_timer: float = 0.0

# Apex Melee Lock-On Step-In ("吸附进") & Spacing/Rebound Step-Back ("防穿模/反震退") State Machine
var melee_lunge_active: bool = false
var melee_lunge_timer: float = 0.0
var melee_lunge_duration: float = 0.15
var melee_lunge_target: Node3D = null
var melee_rebound_timer: float = 0.0
var melee_rebound_dir: Vector3 = Vector3.ZERO
var melee_fov_offset: float = 0.0

# Pathfinder Grapple & Zipline States
var grapple_active: bool = false
var grapple_point: Vector3 = Vector3.ZERO
var grapple_timer: float = 0.0

var zipline_active: bool = false
var zipline_start: Vector3 = Vector3.ZERO
var zipline_end: Vector3 = Vector3.ZERO
var zipline_t: float = 0.0

func _ready() -> void:
	add_to_group("player")
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
	var gs_shader: Shader = load("res://shaders/evo_shield_hex.gdshader")
	if gs_shader != null:
		var gs_smat := ShaderMaterial.new()
		gs_smat.shader = gs_shader
		gs_smat.set_shader_parameter("shield_color", Color(1.0, 0.48, 0.10, 0.52))
		gs_smat.set_shader_parameter("pulse_speed", 4.0)
		gun_shield_mesh.material_override = gs_smat
	else:
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
	var slot_idx: int = clampi(PlayerState.active_slot, 0, 1)
	PlayerState.recalculate_weapon_slot(slot_idx, false)
	var slot: Dictionary = PlayerState.loadout[slot_idx]
	var wid: String = str(slot.get("weapon_id", "empty"))
	var is_heirloom: bool = (PlayerState.active_slot == 2 or wid == "empty" or wid == "")
	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	var wep: Dictionary = GameData.get_weapon_by_id(wid)
	var optic_id: String = str(slot.get("optic", "2x_bruiser"))
	var mesh_node := WeaponMeshBuilder.create_viewmodel(wep, is_heirloom, leg, optic_id)
	viewmodel_holder.add_child(mesh_node)

	if is_instance_valid(player_body_rig):
		player_body_rig.queue_free()
	player_body_rig = LegendRigBuilder.create_legend_rig(leg, wid)
	player_body_rig.name = "PlayerBodyRig"
	add_child(player_body_rig)
	_update_body_perspective()

func _update_body_perspective() -> void:
	if is_third_person:
		if is_instance_valid(player_body_rig):
			player_body_rig.visible = true
			var head_node: Node3D = player_body_rig.find_child("NeckPivot", true, false)
			var chest_node: Node3D = player_body_rig.find_child("ChestBoneAttachment", true, false)
			var wep_mesh: Node3D = player_body_rig.find_child("HeldWeaponRoot", true, false)
			var heirloom_mesh: Node3D = player_body_rig.find_child("HeldHeirloomRoot", true, false)
			var back_wep: Node3D = player_body_rig.find_child("BackHolsterRoot", true, false)
			var is_holstered: bool = (PlayerState.active_slot == 2 or PlayerState.heal_cast_timer > 0.0 or is_wall_climbing or is_mantling)
			var show_tp_heirloom: bool = (PlayerState.active_slot == 2 and PlayerState.heal_cast_timer <= 0.0 and not is_wall_climbing and not is_mantling)
			if head_node: head_node.visible = true
			if chest_node: chest_node.visible = true
			if wep_mesh: wep_mesh.visible = not is_holstered
			if heirloom_mesh: heirloom_mesh.visible = show_tp_heirloom
			if back_wep: back_wep.visible = is_holstered
		if is_instance_valid(viewmodel_holder):
			viewmodel_holder.visible = false
	else:
		if is_instance_valid(player_body_rig):
			player_body_rig.visible = false
		if is_instance_valid(viewmodel_holder):
			viewmodel_holder.visible = true

func add_camera_recoil(v_kick: float, h_kick: float, shake: float = 0.015) -> void:
	recoil_pitch += v_kick
	recoil_yaw += h_kick
	cam_shake = minf(0.06, cam_shake + shake)

func start_melee_lock_on_lunge(target_bot: Node3D, duration: float = 0.15) -> void:
	melee_lunge_target = target_bot
	melee_lunge_duration = duration
	melee_lunge_timer = duration
	melee_lunge_active = (target_bot != null)
	melee_rebound_timer = 0.0
	melee_fov_offset = 5.5 if target_bot != null else 2.8

func trigger_melee_impact_rebound(away_dir: Vector3, rebound_strength: float = 4.6) -> void:
	melee_lunge_active = false
	melee_lunge_timer = 0.0
	melee_rebound_timer = 0.16
	melee_rebound_dir = Vector3(away_dir.x, 0.0, away_dir.z).normalized() * rebound_strength
	melee_fov_offset = -3.5

func start_grapple(target_pt: Vector3) -> void:
	grapple_active = true
	grapple_point = target_pt
	grapple_timer = 1.45
	is_wall_climbing = false
	is_mantling = false
	grapple_beam.visible = true
	AudioSynthesizer.play_ability("grapple")

func start_zipline(p_start: Vector3, p_end: Vector3) -> void:
	zipline_active = true
	zipline_start = p_start
	zipline_end = p_end
	zipline_t = 0.0
	is_wall_climbing = false
	is_mantling = false
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
			is_ads = mb.pressed and PlayerState.heal_cast_timer <= 0.0 and not is_wall_climbing and not is_mantling
		elif mb.button_index == MOUSE_BUTTON_MIDDLE and mb.pressed:
			AudioSynthesizer.play_ping()
			PlayerState.toast_pushed.emit("📍 轮盘标点：敌军方位已标记！", Color("#38bdf8"))
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT):
			if mb.position.x < 1320 or mb.position.y > 90:
				if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Smooth 360 Mouse Look + Track Mouse Velocity for Apex Recoil Smoothing
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var can_look: bool = (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if can_look:
			var sens: float = 0.0014 if is_ads else 0.0025
			yaw -= mm.relative.x * sens
			pitch = clampf(pitch - mm.relative.y * sens, -1.42, 1.42)
			last_mouse_vel = mm.relative

func _physics_process(delta: float) -> void:
	if PlayerState.heal_cast_timer > 0.0 or is_wall_climbing or is_mantling:
		is_ads = false
	_update_body_perspective()
	last_mouse_vel = last_mouse_vel.lerp(Vector2.ZERO, delta * 18.0)

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

	recoil_pitch = lerpf(recoil_pitch, 0.0, delta * 10.5)
	recoil_yaw = lerpf(recoil_yaw, 0.0, delta * 10.5)
	cam_shake = lerpf(cam_shake, 0.0, delta * 16.0)

	rotation.y = yaw + recoil_yaw
	var shake_offset := Vector2(randf_range(-cam_shake, cam_shake), randf_range(-cam_shake, cam_shake))
	var climb_cam_pitch: float = sin(climb_phase * 2.0) * 0.025 if is_wall_climbing else (sin((1.0 - mantle_timer / maxf(0.01, mantle_duration)) * PI) * 0.14 if is_mantling else 0.0)
	camera.rotation.x = clampf(pitch + recoil_pitch + shake_offset.y + climb_cam_pitch, -1.45, 1.45)

	# Gibraltar Gun Shield visibility
	gun_shield_mesh.visible = (PlayerState.selected_legend_id == "gibraltar" and is_ads and PlayerState.active_slot != 2 and PlayerState.gun_shield_hp > 0.0)

	# Target FOV for ADS / Sprint / Stim / Momentum Slide / Wall-Climb
	var target_fov: float = 78.0
	if is_ads and PlayerState.active_slot != 2:
		var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
		var optic_info: Dictionary = GameData.get_optic_by_id(str(slot.get("optic", "2x_bruiser")))
		target_fov = float(optic_info["alt_fov"]) if PlayerState.scope_alt_zoom else float(optic_info["fov"])
	elif is_sliding:
		target_fov = 96.0
	elif is_wall_climbing or is_mantling:
		target_fov = 84.0
	elif PlayerState.stim_timer > 0.0 or PlayerState.beast_timer > 0.0:
		target_fov = 92.0
	melee_fov_offset = lerpf(melee_fov_offset, 0.0, delta * 14.0)
	camera.fov = lerpf(camera.fov, target_fov + melee_fov_offset, delta * 15.0)

	# Viewmodel Wall-Proximity Pullback
	_update_viewmodel_wall_avoidance(delta)

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
		zipline_t += (28.0 / total_len) * delta
		var desired_pos: Vector3 = zipline_start.lerp(zipline_end, clampf(zipline_t, 0.0, 1.0)) + Vector3(0, -1.2, 0)
		velocity = (desired_pos - global_position) / maxf(delta, 0.001)
		move_and_slide()
		if zipline_t >= 1.0 or Input.is_key_pressed(KEY_SPACE) or is_on_wall():
			zipline_active = false
			velocity = (zipline_end - zipline_start).normalized() * 14.0 + Vector3(0, 9.5, 0)
		return

	# Pathfinder Grappling Hook Pendulum Pull
	if grapple_active:
		grapple_timer -= delta
		var hand_pos: Vector3 = global_position + Vector3(0, 1.35, 0)
		var to_target: Vector3 = grapple_point - hand_pos
		var dist: float = to_target.length()
		if dist < 2.2 or grapple_timer <= 0.0 or Input.is_key_pressed(KEY_C) or (is_on_wall() and grapple_timer < 1.15):
			grapple_active = false
			grapple_beam.visible = false
		else:
			var pull_dir: Vector3 = to_target.normalized()
			var look_fwd: Vector3 = -camera.global_transform.basis.z
			velocity = (pull_dir * 25.0 + look_fwd * 9.0 + Vector3(0, 5.5, 0))
			var mid: Vector3 = (hand_pos + grapple_point) * 0.5
			grapple_beam.global_position = mid
			grapple_beam.scale = Vector3(1.0, dist, 1.0)
			var up_dir: Vector3 = Vector3.UP if absf(pull_dir.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
			grapple_beam.look_at(grapple_point, up_dir)
			grapple_beam.rotate_object_local(Vector3.RIGHT, PI * 0.5)
			move_and_slide()
			return

	# =========================================================================
	# LEDGE MANTLE EXECUTION (`扒墙翻越` — 0.34s Smooth Two-Handed Ledge Vault!)
	# =========================================================================
	if is_mantling:
		mantle_timer -= delta
		var mp: float = 1.0 - clampf(mantle_timer / maxf(0.01, mantle_duration), 0.0, 1.0)
		# First 55% lifts vertically up to ledge height; last 45% vaults smoothly forward onto roof deck
		var y_ease: float = 1.0 - pow(1.0 - clampf(mp * 1.35, 0.0, 1.0), 2.2)
		var xz_ease: float = clampf((mp - 0.18) / 0.82, 0.0, 1.0)
		var cur_target := Vector3(
			lerpf(mantle_start_pos.x, mantle_target_pos.x, xz_ease),
			lerpf(mantle_start_pos.y, mantle_target_pos.y, y_ease),
			lerpf(mantle_start_pos.z, mantle_target_pos.z, xz_ease)
		)
		velocity = (cur_target - global_position) / maxf(delta, 0.001)
		move_and_slide()
		if mantle_timer <= 0.0:
			is_mantling = false
			is_wall_climbing = false
			climb_timer = 0.0
			climb_fatigue = 0.0
			var fwd_m: Vector3 = -global_transform.basis.z.normalized()
			velocity = Vector3(fwd_m.x * 5.8, 0.0, fwd_m.z * 5.8)
		_update_camera_and_rig(delta, Vector2(0, -1), false, false)
		return

	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	input_dir = input_dir.normalized()

	var is_healing: bool = (PlayerState.heal_cast_timer > 0.0)
	var sprinting: bool = Input.is_key_pressed(KEY_SHIFT) and not is_ads and not is_healing
	var crouching: bool = Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_CTRL)

	var move_vec: Vector3 = (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Reset climb fatigue & trigger landing compression when touching floor
	if is_on_floor():
		if not was_on_floor_prev and prev_fall_vel_y < -4.5:
			land_compress_timer = 0.24
			AudioSynthesizer.play_footstep(true)
			if PlayerState.selected_legend_id == "horizon":
				# Horizon Passive: Spacewalk soft landing + air-to-ground momentum preservation!
				land_compress_timer = 0.10
				velocity.x *= 1.14
				velocity.z *= 1.14
		climb_fatigue = 0.0
		climb_timer = 0.0
		is_wall_climbing = false

	was_on_floor_prev = is_on_floor()
	prev_fall_vel_y = velocity.y
	if land_compress_timer > 0.0:
		land_compress_timer = maxf(0.0, land_compress_timer - delta)

	# =========================================================================
	# AUTHENTIC APEX LEGENDS WALL-CLIMB (`爬墙`) & LEDGE MANTLE DETECTION
	# Only initiates when airborne (`not is_on_floor()`) or pressing Jump (`KEY_SPACE`)
	# so walking into a wall on flat ground never gets stuck in a climbing loop!
	# =========================================================================
	var wall_check: Dictionary = _probe_climbable_wall()
	var airborne_or_jump: bool = (not is_on_floor()) or Input.is_key_pressed(KEY_SPACE) or is_wall_climbing
	var wants_climb: bool = airborne_or_jump and (input_dir.y < -0.15) and (not crouching) and (not is_healing) and (not is_sliding)

	if wants_climb and bool(wall_check.get("can_mantle", false)):
		_start_ledge_mantle(wall_check["mantle_pos"])
		return
	elif wants_climb and bool(wall_check.get("has_wall", false)) and climb_fatigue < 1.35 and velocity.y > -14.0:
		if not is_wall_climbing:
			is_wall_climbing = true
			climb_timer = 0.0
			is_sliding = false
			AudioSynthesizer.play_footstep(true)
		climb_wall_normal = wall_check["wall_normal"]
		climb_timer += delta
		climb_fatigue += delta
		var fatigue_ratio: float = clampf(climb_fatigue / 1.35, 0.0, 1.0)
		var climb_spd: float = lerpf(8.8, 3.2, pow(fatigue_ratio, 1.25))
		velocity.y = climb_spd
		var wall_right: Vector3 = climb_wall_normal.cross(Vector3.UP).normalized()
		var shimmy: Vector3 = wall_right * (-input_dir.x * 3.4) - climb_wall_normal * 2.6
		velocity.x = shimmy.x
		velocity.z = shimmy.z
		climb_phase += delta * (12.0 - fatigue_ratio * 4.5)
		climb_sound_accum += delta * (4.2 - fatigue_ratio * 1.4)
		if climb_sound_accum >= 1.0:
			climb_sound_accum = 0.0
			AudioSynthesizer.play_footstep(true)

		if Input.is_key_pressed(KEY_SPACE) and climb_timer > 0.14:
			is_wall_climbing = false
			velocity = climb_wall_normal * 14.8 + Vector3(0, 11.8, 0)
			AudioSynthesizer.play_footstep(true)
	else:
		if is_wall_climbing:
			is_wall_climbing = false
			if climb_fatigue >= 1.35:
				velocity.y = minf(velocity.y, -2.5)

	# =========================================================================
	# GROUND & AIRBORNE LOCOMOTION (WHEN NOT WALL-CLIMBING)
	# =========================================================================
	if slide_cooldown > 0.0:
		slide_cooldown = maxf(0.0, slide_cooldown - delta)

	var crouch_just_pressed: bool = crouching and (not was_crouch_pressed)
	was_crouch_pressed = crouching

	if not is_wall_climbing:
		var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
		if crouch_just_pressed and (sprinting or horiz_speed > 8.2) and is_on_floor() and not is_sliding and slide_cooldown <= 0.0 and input_dir.length() > 0.1:
			is_sliding = true
			slide_timer = 0.76
			slide_dir = move_vec if move_vec.length() > 0.1 else -global_transform.basis.z.normalized()
			velocity.x = slide_dir.x * slide_speed
			velocity.z = slide_dir.z * slide_speed
			AudioSynthesizer.play_melee_Whoosh(false)

		if is_sliding:
			slide_timer -= delta
			if slide_timer <= 0.0 or not crouching or horiz_speed < 4.5 or not is_on_floor():
				is_sliding = false
				slide_timer = 0.0
				slide_cooldown = 0.52
				crouching = false
		else:
			slide_timer = 0.0
			if sprinting and input_dir.y < -0.1:
				crouching = false

		var spd: float = base_speed
		if sprinting and input_dir.y < 0.0:
			spd = sprint_speed
		if is_sliding and slide_timer > 0.0:
			var slide_taper: float = clampf(slide_timer / 1.05, 0.38, 1.0)
			spd = slide_speed * slide_taper
		elif crouching:
			spd = 6.2

		if PlayerState.stim_timer > 0.0 or PlayerState.void_timer > 0.0 or PlayerState.beast_timer > 0.0 or PlayerState.double_time_timer > 0.0:
			spd *= 1.32

		if is_healing and not is_sliding:
			spd = minf(spd, base_speed * 0.56)
		elif is_ads and PlayerState.active_slot != 2 and not is_sliding:
			var slot_ads: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
			var wep_ads: Dictionary = GameData.get_weapon_by_id(slot_ads.get("weapon_id", "r301"))
			spd *= float(wep_ads.get("ads_move_scale", 0.72))

		if is_sliding and slide_dir.length() > 0.05:
			var steer_vec: Vector3 = (slide_dir * 0.78 + move_vec * 0.22).normalized()
			velocity.x = lerpf(velocity.x, steer_vec.x * spd, delta * 9.0)
			velocity.z = lerpf(velocity.z, steer_vec.z * spd, delta * 9.0)
		elif move_vec.length() > 0.01:
			var accel: float = 12.5 if is_on_floor() else (8.8 if PlayerState.selected_legend_id == "horizon" else 4.8)
			velocity.x = lerpf(velocity.x, move_vec.x * spd, delta * accel)
			velocity.z = lerpf(velocity.z, move_vec.z * spd, delta * accel)
			bob_time += delta * (13.5 if sprinting else 9.0)

			if is_on_floor() and not is_sliding:
				step_sound_accum += delta * (3.1 if sprinting else 2.1)
				if step_sound_accum >= 1.0:
					step_sound_accum = 0.0
					AudioSynthesizer.play_footstep(sprinting)
		else:
			velocity.x = move_toward(velocity.x, 0.0, spd * 6.5 * delta)
			velocity.z = move_toward(velocity.z, 0.0, spd * 6.5 * delta)
			step_sound_accum = 0.0

		# Gravity, Lifeline Glide & Valkyrie VTOL
		if not is_on_floor():
			var grav_mult: float = 1.0
			if PlayerState.selected_legend_id == "lifeline" and Input.is_key_pressed(KEY_SPACE) and velocity.y < 0.0:
				grav_mult = 0.25
			velocity.y -= gravity * grav_mult * delta
			if PlayerState.selected_legend_id == "valkyrie" and PlayerState.vtol_fuel < 100.0 and not Input.is_key_pressed(KEY_SPACE):
				PlayerState.vtol_fuel = minf(100.0, PlayerState.vtol_fuel + 18.0 * delta)
		else:
			double_jump_ready = false
			if velocity.y <= 0.0:
				velocity.y = -0.5
			if PlayerState.vtol_fuel < 100.0:
				PlayerState.vtol_fuel = minf(100.0, PlayerState.vtol_fuel + 35.0 * delta)

		if Input.is_key_pressed(KEY_SPACE):
			if is_on_floor():
				if is_sliding:
					velocity.y = jump_velocity + 1.8
					var jump_boost_dir: Vector3 = Vector3(velocity.x, 0, velocity.z).normalized()
					velocity.x += jump_boost_dir.x * 3.2
					velocity.z += jump_boost_dir.z * 3.2
					is_sliding = false
					slide_timer = 0.0
				else:
					velocity.y = jump_velocity
			elif is_on_wall() or bool(wall_check.get("has_wall", false)):
				var wn: Vector3 = get_wall_normal() if is_on_wall() else Vector3(wall_check.get("wall_normal", Vector3.BACK))
				velocity = wn * 14.8 + Vector3(0, 11.8, 0)
				AudioSynthesizer.play_footstep(true)
			elif double_jump_ready:
				velocity.y = 14.2
				double_jump_ready = false
				AudioSynthesizer.play_ability("jumppad")
			elif PlayerState.selected_legend_id == "valkyrie" and PlayerState.vtol_fuel > 2.0:
				velocity.y = lerpf(velocity.y, 8.8, delta * 8.0)
				PlayerState.vtol_fuel = maxf(0.0, PlayerState.vtol_fuel - 28.0 * delta)

	# =========================================================================
	# APEX MELEE MAGNETIC LOCK-ON STEP-IN ("吸附进") & REBOUND STEP-BACK ("反震退")
	# =========================================================================
	if melee_lunge_active and melee_lunge_timer > 0.0:
		melee_lunge_timer -= delta
		if is_instance_valid(melee_lunge_target) and ("hp" not in melee_lunge_target or melee_lunge_target.hp > 0.0):
			var enemy_pos: Vector3 = melee_lunge_target.global_position
			var to_enemy: Vector3 = enemy_pos - global_position
			var to_enemy_xz := Vector3(to_enemy.x, 0.0, to_enemy.z)
			var dist_xz: float = to_enemy_xz.length()
			if dist_xz > 0.05:
				var dir_xz: Vector3 = to_enemy_xz / dist_xz
				# Soft Camera Aim-Assist Lock onto enemy chest
				var desired_yaw: float = atan2(-dir_xz.x, -dir_xz.z)
				yaw = lerp_angle(yaw, desired_yaw, delta * 18.0)
				var chest_dy: float = (enemy_pos.y + 1.25) - camera.global_position.y
				var desired_pitch: float = clampf(atan2(chest_dy, maxf(0.8, dist_xz)), -0.85, 0.85)
				pitch = lerpf(pitch, desired_pitch, delta * 14.0)
				# Adaptive Step-In (>1.30m) OR Too-Close Spacing Step-Back (<1.18m) to optimal 1.30m strike distance!
				var optimal_dist: float = 1.30
				var delta_dist: float = dist_xz - optimal_dist
				if absf(delta_dist) > 0.06:
					var step_spd: float = clampf(delta_dist / maxf(0.035, melee_lunge_timer), -9.5, 22.5)
					velocity.x = dir_xz.x * step_spd
					velocity.z = dir_xz.z * step_spd
				else:
					velocity.x = lerpf(velocity.x, 0.0, delta * 25.0)
					velocity.z = lerpf(velocity.z, 0.0, delta * 25.0)
				if enemy_pos.y > global_position.y + 0.35 and is_on_floor():
					velocity.y = maxf(velocity.y, 6.2)
		if melee_lunge_timer <= 0.0:
			melee_lunge_active = false
	elif melee_rebound_timer > 0.0:
		melee_rebound_timer = maxf(0.0, melee_rebound_timer - delta)
		var reb_t: float = melee_rebound_timer / 0.16
		velocity.x = lerpf(velocity.x, melee_rebound_dir.x * reb_t, delta * 20.0)
		velocity.z = lerpf(velocity.z, melee_rebound_dir.z * reb_t, delta * 20.0)

	move_and_slide()
	_update_camera_and_rig(delta, input_dir, sprinting, crouching)


func _probe_climbable_wall() -> Dictionary:
	## Casts waist-level and head-level forward rays to detect climbable walls and top ledges for mantling!
	if get_world_3d() == null or get_world_3d().direct_space_state == null:
		return {"has_wall": false, "can_mantle": false}
	var space := get_world_3d().direct_space_state
	var fwd_xz: Vector3 = -global_transform.basis.z
	fwd_xz.y = 0.0
	if fwd_xz.length_squared() < 0.001:
		return {"has_wall": false, "can_mantle": false}
	fwd_xz = fwd_xz.normalized()

	var waist_origin: Vector3 = global_position + Vector3(0, 0.82, 0)
	var head_origin: Vector3 = global_position + Vector3(0, 1.88, 0)

	var q_waist := PhysicsRayQueryParameters3D.create(waist_origin, waist_origin + fwd_xz * 0.88, 1, [get_rid()])
	var hit_waist: Dictionary = space.intersect_ray(q_waist)
	if hit_waist.is_empty():
		return {"has_wall": false, "can_mantle": false}

	var wn: Vector3 = hit_waist["normal"]
	if absf(wn.y) > 0.35 or fwd_xz.dot(-wn) < 0.45:
		return {"has_wall": false, "can_mantle": false}

	var q_head := PhysicsRayQueryParameters3D.create(head_origin, head_origin + fwd_xz * 1.05, 1, [get_rid()])
	var hit_head: Dictionary = space.intersect_ray(q_head)

	# If waist hits a wall AND head ray clears the top of the wall, probe downward for the ledge surface!
	if hit_head.is_empty():
		var down_from: Vector3 = global_position + fwd_xz * 0.72 + Vector3(0, 2.15, 0)
		var down_to: Vector3 = global_position + fwd_xz * 0.72 + Vector3(0, 0.35, 0)
		var q_down := PhysicsRayQueryParameters3D.create(down_from, down_to, 1, [get_rid()])
		var hit_ledge: Dictionary = space.intersect_ray(q_down)
		if not hit_ledge.is_empty() and hit_ledge["normal"].y > 0.65:
			var ledge_pt: Vector3 = hit_ledge["position"]
			if ledge_pt.y > global_position.y + 0.38 and ledge_pt.y <= global_position.y + 2.05:
				return {
					"has_wall": false,
					"wall_normal": wn,
					"can_mantle": true,
					"mantle_pos": ledge_pt + Vector3(0, 0.05, 0)
				}
		return {"has_wall": false, "can_mantle": false}

	return {
		"has_wall": true,
		"wall_normal": wn,
		"can_mantle": false
	}


func _start_ledge_mantle(target_ledge_pos: Vector3) -> void:
	is_mantling = true
	is_wall_climbing = false
	is_sliding = false
	mantle_duration = 0.34
	mantle_timer = mantle_duration
	mantle_start_pos = global_position
	mantle_target_pos = target_ledge_pos
	AudioSynthesizer.play_footstep(true)
	add_camera_recoil(-0.045, 0.0, 0.015)


func _update_camera_and_rig(delta: float, input_dir: Vector2, sprinting: bool, crouching: bool) -> void:
	# Record Player Behavior Trajectory for AI Imitation Learning
	var enemies_arr: Array = []
	if weapon_ctrl != null and "enemies" in weapon_ctrl:
		enemies_arr = weapon_ctrl.enemies
	BehaviorRecorder.record_step(delta, self, enemies_arr)

	# Compute local horizontal movement angle for 3rd-person hip/leg directional alignment
	var horiz_vel := Vector2(velocity.x, velocity.z)
	var local_vel: Vector3 = global_transform.basis.inverse() * Vector3(velocity.x, 0.0, velocity.z)
	var move_angle_local: float = 0.0
	if Vector2(local_vel.x, local_vel.z).length() > 0.5:
		if local_vel.z <= 0.15:
			move_angle_local = clampf(atan2(-local_vel.x, maxf(0.1, -local_vel.z)), -0.78, 0.78)
		else:
			move_angle_local = clampf(atan2(local_vel.x, maxf(0.1, local_vel.z)), -0.68, 0.68)

	var firing: bool = false
	var reloading: bool = false
	var reload_dur: float = 1.80
	var reload_prog: float = 0.0
	var quick_melee: bool = false
	if weapon_ctrl != null:
		firing = (Time.get_ticks_msec() - int(weapon_ctrl.get("last_fire_ms"))) < 160
		var r_timer: float = float(weapon_ctrl.get("reload_timer"))
		reload_dur = maxf(0.45, float(weapon_ctrl.get("reload_total")))
		reloading = r_timer > 0.0
		reload_prog = clampf(1.0 - (r_timer / reload_dur), 0.0, 1.0) if reloading else 0.0
		quick_melee = float(weapon_ctrl.get("quick_melee_timer")) > 0.0 or float(weapon_ctrl.get("melee_swing_timer")) > 0.0

	var is_air: bool = not is_on_floor() and not is_sliding and not zipline_active and not grapple_active and not is_skydiving and not is_wall_climbing and not is_mantling
	var cur_slot_d: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
	var cur_wid: String = str(cur_slot_d.get("weapon_id", "r301"))
	var is_moving_ground: bool = (input_dir.length() > 0.1 or horiz_vel.length() > 0.55) and is_on_floor() and not is_sliding

	# 1. Animate character body rig in 3rd-person mode
	_update_body_perspective()
	if is_third_person and player_body_rig != null:
		LegendRigBuilder.animate_rig(player_body_rig, delta, {
			"mode": "combat",
			"is_first_person": false,
			"is_moving": is_moving_ground,
			"is_sprinting": sprinting and is_moving_ground and not crouching and not is_ads and not firing,
			"is_sliding": is_sliding,
			"is_crouching": crouching and not is_sliding,
			"is_in_air": is_air,
			"vel_y": velocity.y,
			"land_compress": land_compress_timer / 0.24,
			"is_wall_climbing": is_wall_climbing,
			"climb_phase": climb_phase,
			"is_mantling": is_mantling,
			"mantle_progress": 1.0 - (mantle_timer / maxf(0.01, mantle_duration)),
			"is_ziplining": zipline_active,
			"is_grappling": grapple_active,
			"is_healing": (PlayerState.heal_cast_timer > 0.0),
			"heal_id": PlayerState.active_heal_id,
			"is_heirloom": (PlayerState.active_slot == 2 or cur_wid == "empty"),
			"is_reloading": reloading,
			"reload_duration": reload_dur,
			"reload_progress": reload_prog,
			"is_firing": firing,
			"is_melee": quick_melee,
			"melee_prog": float(weapon_ctrl.get("active_melee_progress")) if weapon_ctrl != null else 0.0,
			"melee_combo_idx": int(weapon_ctrl.get("melee_combo_idx")) if weapon_ctrl != null else 0,
			"melee_variant": int(weapon_ctrl.get("quick_melee_variant")) if weapon_ctrl != null else 0,
			"is_ads": is_ads,
			"aim_pitch": pitch,
			"move_angle_local": move_angle_local,
			"weapon_id": cur_wid,
			"strafe_phase": bob_time,
			"strafe_dir": input_dir.x,
			"speed": horiz_vel.length(),
			"time": Time.get_ticks_msec() / 1000.0
		})

	# 2. Compute 1st-Person or 3rd-Person Spring-Arm Camera Position
	var land_dip: float = sin((land_compress_timer / 0.24) * PI) * 0.14 if land_compress_timer > 0.0 else 0.0
	if is_third_person:
		var eye_h: float = 1.08 if is_sliding else (1.28 if crouching else 1.82)
		eye_h -= land_dip
		var desired_local := Vector3(0.58, eye_h, 2.28)
		target_cam_pos = _compute_spring_arm_cam_pos(Vector3(0, eye_h * 0.88, 0), desired_local)
		camera.position = camera.position.lerp(target_cam_pos, delta * 15.0)
	else:
		var eye_h: float = 0.95 if is_sliding else (1.18 if crouching else 1.68)
		target_cam_pos = Vector3(0.0, eye_h - land_dip, 0.0)
		camera.position = camera.position.lerp(target_cam_pos, delta * 22.0)

	var target_roll: float = -0.20 if is_sliding else (sin(climb_phase) * 0.035 if is_wall_climbing else (-input_dir.x * 0.018))
	camera.rotation.z = lerpf(camera.rotation.z, target_roll, delta * 12.0)


func _update_viewmodel_wall_avoidance(delta: float) -> void:
	var target_pull: float = 0.0
	if not is_third_person and get_world_3d() != null and get_world_3d().direct_space_state != null:
		var origin: Vector3 = camera.global_position
		var fwd: Vector3 = -camera.global_transform.basis.z
		var q := PhysicsRayQueryParameters3D.create(origin, origin + fwd * 1.05, 1)
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			var d: float = origin.distance_to(hit["position"])
			if d < 1.05:
				target_pull = (1.05 - d) * 0.42
	vm_wall_pullback = lerpf(vm_wall_pullback, target_pull, delta * 18.0)
	viewmodel_holder.position.z = vm_wall_pullback


func _compute_spring_arm_cam_pos(pivot_local: Vector3, desired_local: Vector3) -> Vector3:
	if get_world_3d() == null or get_world_3d().direct_space_state == null:
		return desired_local
	var from_w: Vector3 = to_global(pivot_local)
	var to_w: Vector3 = to_global(desired_local)
	var q := PhysicsRayQueryParameters3D.create(from_w, to_w, 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		var hit_w: Vector3 = hit["position"]
		var safe_w: Vector3 = from_w.lerp(hit_w, 0.82)
		return to_local(safe_w)
	return desired_local
