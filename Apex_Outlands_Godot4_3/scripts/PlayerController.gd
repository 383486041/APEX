class_name PlayerController
extends CharacterBody3D
## Authentic Apex Legends First-Person & Third-Person Movement, Slide Physics, Camera & Rig Controller for Godot 4.3.
## Features:
## - True Physics Capsule Collision (no wall-phasing during Zipline, Grapple, Skydive, or Slide)
## - Upgraded Momentum Slide (`滑铲`) with Initial Impulse Boost, Friction Taper, Slide-Jump Launch, Camera Drop (`y = 0.78`), Dutch Roll (`-11.5°`), and FOV Surge (`96°`)
## - Viewmodel Wall-Proximity Pullback Raycast (eliminates 1st-person gun clipping into walls)
## - 3rd-Person Camera Spring-Arm Collision Raycast + Dynamic Two-Handed Weapon Aiming (`pitch` tracking) & Back Weapon Holster when Healing!

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

var is_sliding: bool = false
var slide_timer: float = 0.0
var slide_dir: Vector3 = Vector3.ZERO
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

	# Build full-body articulated 3D character rig with active 3D weapon in hands + back holster!
	if is_instance_valid(player_body_rig):
		player_body_rig.queue_free()
	player_body_rig = LegendRigBuilder.create_legend_rig(leg, wid)
	player_body_rig.name = "PlayerBodyRig"
	add_child(player_body_rig)
	_update_body_perspective()

func _update_body_perspective() -> void:
	if player_body_rig == null:
		return
	var head_node: Node3D = player_body_rig.find_child("NeckPivot", true, false)
	var wep_mesh: Node3D = player_body_rig.find_child("HeldWeaponRoot", true, false)
	var back_wep: Node3D = player_body_rig.find_child("BackHolsterRoot", true, false)
	var is_holstered: bool = (PlayerState.active_slot == 2 or PlayerState.heal_cast_timer > 0.0)
	if is_third_person:
		player_body_rig.visible = true
		if head_node:
			head_node.visible = true
		if wep_mesh:
			wep_mesh.visible = not is_holstered
		if back_wep:
			back_wep.visible = is_holstered
		viewmodel_holder.visible = false
	else:
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
			is_ads = mb.pressed and PlayerState.heal_cast_timer <= 0.0
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT):
			if mb.position.x < 1320 or mb.position.y > 90:
				if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Smooth 360 Mouse Look
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var can_look: bool = (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if can_look:
			var sens: float = 0.0014 if is_ads else 0.0025
			yaw -= mm.relative.x * sens
			pitch = clampf(pitch - mm.relative.y * sens, -1.42, 1.42)

func _physics_process(delta: float) -> void:
	if PlayerState.heal_cast_timer > 0.0:
		is_ads = false
	_update_body_perspective()

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

	recoil_pitch = lerpf(recoil_pitch, 0.0, delta * 10.0)
	recoil_yaw = lerpf(recoil_yaw, 0.0, delta * 10.0)
	cam_shake = lerpf(cam_shake, 0.0, delta * 16.0)

	rotation.y = yaw + recoil_yaw
	var shake_offset := Vector2(randf_range(-cam_shake, cam_shake), randf_range(-cam_shake, cam_shake))
	camera.rotation.x = clampf(pitch + recoil_pitch + shake_offset.y, -1.45, 1.45)

	# Gibraltar Gun Shield visibility
	gun_shield_mesh.visible = (PlayerState.selected_legend_id == "gibraltar" and is_ads and PlayerState.active_slot != 2 and PlayerState.gun_shield_hp > 0.0)

	# Target FOV for ADS / Sprint / Stim / Momentum Slide
	var target_fov: float = 78.0
	if is_ads and PlayerState.active_slot != 2:
		var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
		var optic_info: Dictionary = GameData.get_optic_by_id(str(slot.get("optic", "2x_bruiser")))
		target_fov = float(optic_info["alt_fov"]) if PlayerState.scope_alt_zoom else float(optic_info["fov"])
	elif is_sliding:
		target_fov = 96.0
	elif PlayerState.stim_timer > 0.0 or PlayerState.beast_timer > 0.0:
		target_fov = 92.0
	camera.fov = lerpf(camera.fov, target_fov, delta * 13.0)

	# Viewmodel Wall-Proximity Pullback (Prevents 1st-Person Weapon Clipping Into Walls!)
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

	# Zipline Riding (Physics-safe velocity motion with wall-stop protection!)
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

	# Authentic Apex Legends Momentum Slide Trigger (Sprint/Move + Crouch)
	var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
	if crouching and (sprinting or horiz_speed > 8.2) and is_on_floor() and not is_sliding and input_dir.length() > 0.1:
		is_sliding = true
		slide_timer = 1.05
		slide_dir = move_vec if move_vec.length() > 0.1 else -global_transform.basis.z.normalized()
		velocity.x = slide_dir.x * slide_speed
		velocity.z = slide_dir.z * slide_speed
		AudioSynthesizer.play_melee_Whoosh(false)

	if slide_timer > 0.0:
		slide_timer -= delta
		if slide_timer <= 0.0 or not crouching:
			is_sliding = false
	elif not crouching:
		is_sliding = false

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

	# Authentic Consumable Healing Walk Penalty (except while sliding — allows Apex bunny-hop / slide healing!)
	if is_healing and not is_sliding:
		spd = minf(spd, base_speed * 0.56)
	elif is_ads and PlayerState.active_slot != 2 and not is_sliding:
		var slot_ads: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
		var wep_ads: Dictionary = GameData.get_weapon_by_id(slot_ads.get("weapon_id", "r301"))
		spd *= float(wep_ads.get("ads_move_scale", 0.72))

	if is_sliding and slide_dir.length() > 0.05:
		# Smooth momentum slide steering
		var steer_vec: Vector3 = (slide_dir * 0.78 + move_vec * 0.22).normalized()
		velocity.x = lerpf(velocity.x, steer_vec.x * spd, delta * 9.0)
		velocity.z = lerpf(velocity.z, steer_vec.z * spd, delta * 9.0)
	elif move_vec.length() > 0.01:
		var accel: float = 12.0 if is_on_floor() else (8.0 if PlayerState.selected_legend_id == "horizon" else 4.5)
		velocity.x = lerpf(velocity.x, move_vec.x * spd, delta * accel)
		velocity.z = lerpf(velocity.z, move_vec.z * spd, delta * accel)
		bob_time += delta * (13.5 if sprinting else 9.0)

		if is_on_floor() and not is_sliding:
			step_sound_accum += delta * (3.1 if sprinting else 2.1)
			if step_sound_accum >= 1.0:
				step_sound_accum = 0.0
				AudioSynthesizer.play_footstep(sprinting)
	else:
		velocity.x = move_toward(velocity.x, 0.0, spd * 6.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, spd * 6.0 * delta)
		step_sound_accum = 0.0

	# Gravity, Wall-Climb, Lifeline Glide & Valkyrie VTOL
	if not is_on_floor():
		var grav_mult: float = 1.0
		if PlayerState.selected_legend_id == "lifeline" and Input.is_key_pressed(KEY_SPACE) and velocity.y < 0.0:
			grav_mult = 0.25
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
			if is_sliding:
				# Authentic Apex Slide-Jump Momentum Launch!
				velocity.y = jump_velocity + 1.8
				var jump_boost_dir: Vector3 = Vector3(velocity.x, 0, velocity.z).normalized()
				velocity.x += jump_boost_dir.x * 3.2
				velocity.z += jump_boost_dir.z * 3.2
				is_sliding = false
				slide_timer = 0.0
			else:
				velocity.y = jump_velocity
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

	# Camera Positioning with Low-Profile Slide Drop (`0.78m`), Dutch Roll (`-11.5°`), and 3rd-Person Spring-Arm
	if is_third_person:
		var eye_h: float = 1.08 if is_sliding else (1.28 if crouching else 1.82)
		var desired_local := Vector3(0.58, eye_h, 2.28)
		target_cam_pos = _compute_spring_arm_cam_pos(Vector3(0, eye_h * 0.88, 0), desired_local)
	else:
		var fp_h: float = 0.78 if is_sliding else (1.08 if crouching else 1.68)
		target_cam_pos = Vector3(0, fp_h, 0)
	camera.position = camera.position.lerp(target_cam_pos, delta * 15.0)
	var target_roll: float = -0.20 if is_sliding else (-input_dir.x * 0.018)
	camera.rotation.z = lerpf(camera.rotation.z, target_roll, delta * 12.0)

	move_and_slide()

	# Record Player Behavior Trajectory for AI Imitation Learning
	var enemies_arr: Array = []
	if weapon_ctrl != null and "enemies" in weapon_ctrl:
		enemies_arr = weapon_ctrl.enemies
	BehaviorRecorder.record_step(delta, self, enemies_arr)

	# Drive procedural 3D character body rig animations in 3rd-person mode (with aim pitch & two-handed weapon hold!)
	if player_body_rig != null and is_third_person:
		_update_body_perspective()
		var firing: bool = false
		var reloading: bool = false
		if weapon_ctrl != null:
			firing = (Time.get_ticks_msec() - int(weapon_ctrl.get("last_fire_ms"))) < 160
			reloading = float(weapon_ctrl.get("reload_timer")) > 0.0
		var is_air: bool = not is_on_floor() and not is_sliding and not zipline_active and not grapple_active and not is_skydiving
		var cur_slot_d: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
		var cur_wid: String = str(cur_slot_d.get("weapon_id", "r301"))
		LegendRigBuilder.animate_rig(player_body_rig, delta, {
			"mode": "combat",
			"is_moving": input_dir.length() > 0.1 and is_on_floor() and not is_sliding,
			"is_sliding": is_sliding,
			"is_crouching": crouching and not is_sliding,
			"is_in_air": is_air,
			"is_ziplining": zipline_active,
			"is_grappling": grapple_active,
			"is_healing": is_healing,
			"heal_id": PlayerState.active_heal_id,
			"is_heirloom": (PlayerState.active_slot == 2 or cur_wid == "empty"),
			"is_reloading": reloading,
			"is_firing": firing,
			"is_ads": is_ads,
			"aim_pitch": pitch,
			"weapon_id": cur_wid,
			"strafe_phase": bob_time,
			"strafe_dir": input_dir.x,
			"speed": velocity.length(),
			"time": Time.get_ticks_msec() / 1000.0
		})


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
