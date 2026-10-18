class_name WeaponController
extends Node3D
## Drives First-Person Weapon Ballistics, Stepped Parabolic Projectile Drop & Travel-Time Lead,
## Apex Legends Recoil Smoothing (while tracking targets), Caliber-Specific Tracers, Brass Casing Ejection & Impact Sparks,
## Authentic Unit-Normalized Shotgun Pellet Patterns (Star-11, Line-8, Fig8-8, Triangle-3) & Precision Choke,
## Shotgun Bolt Fire-Rate & Rechamber Acceleration, 30-30 Repeater ADS Charge, L-STAR Overheat Cooling,
##HAVOC Windup, Bocek Compound Bow Hold-to-Draw & Release Mechanics,
## 28 Individually Choreographed Weapon Reload Animations (Unique per weapon ID!),
## First-Person Wall-Climb & Ledge-Mantle Hand Choreography,
## Holstered-Weapon Two-Handed First-Person Consumable Animations (Shield Battery Twist & Syringe Injection),
## Magnetic Melee Lunge (`3.6m`), Hitstop (`45ms`), Flying Jump-Kick / Uppercut, and 3-Stage Heirloom Slash Combos.

var player: PlayerController
var world_root: Node3D
var last_fire_ms: int = 0
var enemies: Array = []

# Charge Rifle (滋崩) Two-Stage Firing State Machine: Phase 1 "滋" (Tracking Laser) -> Phase 2 "崩" (Explosive Blast)
var is_charging_beam: bool = false
var charge_timer: float = 0.0
var charge_last_tick: float = 0.0
var charge_beng_fired: bool = false
var charge_beam_mesh: MeshInstance3D = null

# Bocek Compound Bow Hold-to-Draw State Machine
var is_drawing_bow: bool = false
var bow_draw_progress: float = 0.0
var bow_hold_time: float = 0.0

# Peacekeeper / Triple Take ADS Precision Choke, 30-30 Repeater ADS Charge, L-STAR Heat & HAVOC Windup
var choke_progress: float = 0.0
var repeater_charge: float = 0.0
var lstar_heat: float = 0.0
var havoc_windup: float = 0.0

# Burst-Fire State Machine (Hemlok 3-burst, Nemesis 4-burst, Prowler 5-burst)
var burst_shots_remaining: int = 0
var burst_next_shot_timer: float = 0.0
var nemesis_energy_charge: float = 0.0
var devotion_spinup: float = 0.0

# Reload State Machine (28 Individually Choreographed Weapon Reloads)
var reload_timer: float = 0.0
var reload_total: float = 0.0
var is_empty_reload: bool = false
var is_segmented_reload: bool = false
var reload_step_mask: int = 0

# Rechamber / Lever-Cock / Pump State
var rechamber_timer: float = 0.0
var rechamber_total: float = 0.0

# Melee, Magnetic Lock-On Step-In/Step-Back, Hitstop & MoCap Keyframe State Machine
var quick_melee_timer: float = 0.0
var quick_melee_total: float = 0.46
var quick_melee_variant: int = 0 # 0: Left Hook, 1: Rifle-Butt Smash, 2: Airborne Flying Jump-Kick, 3: Sliding Uppercut
var melee_swing_timer: float = 0.0
var melee_swing_total: float = 0.46
var melee_combo_idx: int = 0
var melee_hitstop_timer: float = 0.0
var active_melee_progress: float = 0.0
var melee_impact_pending: bool = false
var melee_pending_dmg: int = 35
var melee_pending_label: String = "近战重击"
var melee_pending_col: Color = Color("#38bdf8")
var inspect_timer: float = 0.0

# Procedural Viewmodel Transform Offsets & Dynamic Sway
var kick_offset: Vector3 = Vector3.ZERO
var kick_rot: Vector3 = Vector3.ZERO
var bolt_back_offset: float = 0.0
var sway_offset: Vector2 = Vector2.ZERO
var prev_cam_yaw: float = 0.0
var prev_cam_pitch: float = 0.0
var consecutive_shots: int = 0

func _process(delta: float) -> void:
	if player == null:
		return

	# Melee Hitstop Micro-Freeze (45ms tactile freeze on melee impact, just like Apex Legends!)
	if melee_hitstop_timer > 0.0:
		melee_hitstop_timer = maxf(0.0, melee_hitstop_timer - delta)
		delta *= 0.12

	# Track smooth rotational weapon sway from mouse look
	var dyaw: float = wrapf(player.yaw - prev_cam_yaw, -PI, PI)
	var dpitch: float = player.pitch - prev_cam_pitch
	prev_cam_yaw = player.yaw
	prev_cam_pitch = player.pitch
	sway_offset = sway_offset.lerp(Vector2(-dyaw * 0.45, dpitch * 0.45).limit_length(0.06), delta * 14.0)

	# Decay consecutive shot counter, Devotion spinup, HAVOC windup & L-STAR heat when not firing
	var now_ms: int = Time.get_ticks_msec()
	var holding_lmb: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if now_ms - last_fire_ms > 240:
		consecutive_shots = maxi(0, consecutive_shots - 1)
		devotion_spinup = maxf(0.0, devotion_spinup - delta * 1.4)
		lstar_heat = maxf(0.0, lstar_heat - delta * 0.55)
	if not holding_lmb:
		havoc_windup = maxf(0.0, havoc_windup - delta * 2.5)

	nemesis_energy_charge = maxf(0.0, nemesis_energy_charge - delta * 0.08)

	# Cancel active weapon states if player starts healing or wall-climbing/mantling
	if PlayerState.heal_cast_timer > 0.0 or player.is_wall_climbing or player.is_mantling:
		if is_charging_beam:
			_cancel_charge_beam()
		is_drawing_bow = false
		bow_draw_progress = 0.0
		burst_shots_remaining = 0
		repeater_charge = 0.0

	# Handle Charge Rifle "滋崩" Sequence
	if is_charging_beam:
		if reload_timer > 0.0 or quick_melee_timer > 0.0 or PlayerState.active_slot == 2:
			_cancel_charge_beam()
		else:
			_update_charge_rifle(delta)

	# Handle Burst-Fire Follow-up Shots
	if burst_shots_remaining > 0:
		if reload_timer > 0.0 or PlayerState.active_slot == 2 or PlayerState.heal_cast_timer > 0.0:
			burst_shots_remaining = 0
		else:
			burst_next_shot_timer -= delta
			if burst_next_shot_timer <= 0.0:
				burst_shots_remaining -= 1
				burst_next_shot_timer = 0.048
				_execute_single_shot(enemies, true)

	# Handle Bocek Compound Bow Draw & Release
	_update_bocek_bow(delta)

	# Handle ADS Precision Choke (Peacekeeper & Triple Take) & 30-30 Repeater ADS Charge
	_update_precision_choke(delta)

	# Decay Charged Weapon timers (Sentinel / Rampage)
	for slot in PlayerState.loadout:
		if float(slot.get("charged", 0.0)) > 0.0:
			slot["charged"] = maxf(0.0, float(slot["charged"]) - delta)

	# Decay Recoil & Bolt Kick
	kick_offset = kick_offset.lerp(Vector3.ZERO, delta * 16.5)
	kick_rot = kick_rot.lerp(Vector3.ZERO, delta * 15.5)
	bolt_back_offset = lerpf(bolt_back_offset, 0.0, delta * 18.0)

	if rechamber_timer > 0.0:
		rechamber_timer = maxf(0.0, rechamber_timer - delta)

	active_melee_progress = 0.0
	if quick_melee_timer > 0.0:
		quick_melee_timer = maxf(0.0, quick_melee_timer - delta)
		active_melee_progress = 1.0 - (quick_melee_timer / maxf(0.01, quick_melee_total))

	if melee_swing_timer > 0.0:
		melee_swing_timer = maxf(0.0, melee_swing_timer - delta)
		active_melee_progress = 1.0 - (melee_swing_timer / maxf(0.01, melee_swing_total))

	# Trigger Melee Impact at the Exact MoCap Apex Extension Frame (p >= 0.34, after Step-In Lunge completes!)
	if melee_impact_pending and active_melee_progress >= 0.34:
		melee_impact_pending = false
		_check_melee_hit(enemies, melee_pending_dmg, melee_pending_label, melee_pending_col)

	if inspect_timer > 0.0:
		inspect_timer = maxf(0.0, inspect_timer - delta)

	# Process Multi-Stage or Segmented Shell-by-Shell Reload
	if reload_timer > 0.0:
		reload_timer -= delta
		var progress: float = 1.0 - clampf(reload_timer / maxf(0.01, reload_total), 0.0, 1.0)
		if is_segmented_reload:
			if progress >= 0.45 and (reload_step_mask & 2) == 0:
				reload_step_mask |= 2
				AudioSynthesizer.play_reload_step("shell_insert")
				kick_offset.y += 0.024
				kick_rot.z += 0.06
				player.add_camera_recoil(0.008, 0.004, 0.008)
			if reload_timer <= 0.0:
				_complete_segmented_shell_insert()
		else:
			if progress >= 0.14 and (reload_step_mask & 1) == 0:
				reload_step_mask |= 1
				AudioSynthesizer.play_reload_step("mag_out")
				_spawn_dropped_mag()
			if progress >= 0.56 and (reload_step_mask & 2) == 0:
				reload_step_mask |= 2
				AudioSynthesizer.play_reload_step("mag_in")
				kick_offset.y += 0.038
				player.add_camera_recoil(0.012, 0.0, 0.01)
			if progress >= 0.82 and (reload_step_mask & 4) == 0:
				reload_step_mask |= 4
				var slot_s: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
				var wid_s: String = str(slot_s.get("weapon_id", "r301"))
				AudioSynthesizer.play_reload_step("lever_cock" if wid_s == "peacekeeper" else "bolt_slap")
				player.add_camera_recoil(-0.015, 0.008, 0.015)

			if reload_timer <= 0.0:
				reload_timer = 0.0
				var slot_idx: int = clampi(PlayerState.active_slot, 0, 1)
				PlayerState.recalculate_weapon_slot(slot_idx, false)
				var slot: Dictionary = PlayerState.loadout[slot_idx]
				var wep: Dictionary = GameData.get_weapon_by_id(slot["weapon_id"])
				var needed: int = int(slot["max_ammo"]) - int(slot["ammo"])
				var ammo_key: String = str(wep["ammo"])
				var loaded: int = PlayerState.deduct_ammo(ammo_key, needed)
				slot["ammo"] = int(slot["ammo"]) + loaded
				PlayerState.sync_ammo_reserve_from_inventory()

	_animate_viewmodel(delta)


func _complete_segmented_shell_insert() -> void:
	var slot_idx: int = clampi(PlayerState.active_slot, 0, 1)
	PlayerState.recalculate_weapon_slot(slot_idx, false)
	var slot: Dictionary = PlayerState.loadout[slot_idx]
	var wep: Dictionary = GameData.get_weapon_by_id(slot["weapon_id"])
	var wid: String = str(wep["id"])
	var ammo_key: String = str(wep["ammo"])
	if int(slot["ammo"]) < int(slot["max_ammo"]):
		var loaded: int = PlayerState.deduct_ammo(ammo_key, 1)
		if loaded > 0:
			slot["ammo"] = int(slot["ammo"]) + 1
			PlayerState.sync_ammo_reserve_from_inventory()

	var new_avail: int = PlayerState.get_reserve_ammo(ammo_key)
	if int(slot["ammo"]) < int(slot["max_ammo"]) and (new_avail > 0 or PlayerState.selected_mode_id == "firing_range"):
		var stock_t: int = maxi(int(slot.get("stock", 0)), int(slot.get("stock_tier", 0)))
		var stock_mult: float = 1.0 - float(stock_t) * 0.07
		reload_total = (0.42 if wid == "mastiff" else 0.38) * stock_mult
		reload_timer = reload_total
		reload_step_mask = 0
	else:
		reload_timer = 0.0
		is_segmented_reload = false
		AudioSynthesizer.play_reload_step("pump_action" if wid == "mastiff" else "lever_cock")


func _update_bocek_bow(delta: float) -> void:
	if PlayerState.active_slot == 2 or reload_timer > 0.0 or PlayerState.heal_cast_timer > 0.0 or player.is_wall_climbing or player.is_mantling:
		is_drawing_bow = false
		bow_draw_progress = 0.0
		return
	var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
	var wid: String = str(slot.get("weapon_id", ""))
	if wid != "bocek":
		is_drawing_bow = false
		bow_draw_progress = 0.0
		return

	var holding_fire: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var avail_arrows: int = PlayerState.get_reserve_ammo("arrows")
	if holding_fire and (int(slot["ammo"]) > 0 or avail_arrows > 0 or PlayerState.selected_mode_id == "firing_range"):
		if not is_drawing_bow:
			var now_b: int = Time.get_ticks_msec()
			if now_b - last_fire_ms < 260:
				return
			is_drawing_bow = true
			bow_draw_progress = 0.0
			bow_hold_time = 0.0
			AudioSynthesizer.play_bow_draw()
		bow_hold_time += delta
		bow_draw_progress = clampf(bow_hold_time / 0.52, 0.0, 1.0)
	elif is_drawing_bow:
		_fire_bocek_arrow(bow_draw_progress)
		is_drawing_bow = false
		bow_draw_progress = 0.0
		bow_hold_time = 0.0


func _fire_bocek_arrow(draw_ratio: float) -> void:
	var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
	var wep: Dictionary = GameData.get_weapon_by_id("bocek")
	if PlayerState.selected_mode_id != "firing_range":
		var cur_arrows: int = PlayerState.get_reserve_ammo("arrows")
		if cur_arrows > 0:
			PlayerState.deduct_ammo("arrows", 1)
		elif int(slot["ammo"]) > 0:
			slot["ammo"] = int(slot["ammo"]) - 1
		else:
			return

	last_fire_ms = Time.get_ticks_msec()
	AudioSynthesizer.play_bow_release(draw_ratio)

	kick_offset = Vector3(0, 0.010, 0.045)
	kick_rot = Vector3(0.035, randf_range(-0.008, 0.008), -0.24)
	player.add_camera_recoil(0.014, randf_range(-0.004, 0.004), 0.01)

	var cam: Camera3D = player.camera
	var origin: Vector3 = cam.global_position
	var fwd: Vector3 = -cam.global_transform.basis.z
	var spread: float = lerpf(0.016, 0.0008, draw_ratio) * (0.35 if player.is_ads else 1.0)
	var ray_dir: Vector3 = (fwd + cam.global_transform.basis.x * randf_range(-spread, spread) + cam.global_transform.basis.y * randf_range(-spread, spread)).normalized()

	var hit_info: Dictionary = _cast_ballistic_ray(origin, ray_dir, 320.0, false, lerpf(190.0, 290.0, draw_ratio), lerpf(1.25, 0.75, draw_ratio))
	var hit_pos: Vector3 = hit_info["hit_pos"]
	var hit_bot: ApexBotAI = hit_info["hit_bot"]
	var was_head: bool = hit_info["was_head"]
	var was_legs: bool = hit_info.get("was_legs", false)

	var base_dmg: int = int(round(lerpf(28.0, float(wep["dmg"]), draw_ratio)))
	if was_head:
		base_dmg = int(round(float(base_dmg) * float(wep["head"])))
	elif was_legs:
		base_dmg = int(round(float(base_dmg) * float(wep.get("legs", 0.90))))

	_spawn_bullet_tracer(origin + Vector3(0, -0.06, 0) + fwd * 0.65, hit_pos, Color("#f59e0b"), 0.014)
	_spawn_embedded_arrow(hit_pos, ray_dir)
	_spawn_impact_vfx(hit_pos, hit_bot != null, was_head, Color("#f59e0b"))

	if hit_bot != null and base_dmg > 0:
		hit_bot.apply_damage(base_dmg, was_head, "博塞克复合弓")

	BehaviorRecorder.record_event("fire_bocek", {"draw": draw_ratio, "hit": hit_bot != null})
	PlayerState.state_updated.emit()


func _spawn_embedded_arrow(hit_pos: Vector3, dir: Vector3) -> void:
	if world_root == null:
		return
	var arr := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.006
	cyl.bottom_radius = 0.006
	cyl.height = 0.58
	arr.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#f59e0b")
	mat.emission_enabled = true
	mat.emission = Color("#f59e0b")
	mat.emission_energy_multiplier = 2.4
	arr.material_override = mat
	world_root.add_child(arr)
	arr.global_position = hit_pos - dir * 0.25
	var up_v: Vector3 = Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	arr.look_at(hit_pos + dir, up_v)
	arr.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	get_tree().create_timer(8.0).timeout.connect(func():
		if is_instance_valid(arr):
			arr.queue_free()
	)


func _update_precision_choke(delta: float) -> void:
	if PlayerState.active_slot == 2 or reload_timer > 0.0 or PlayerState.heal_cast_timer > 0.0:
		choke_progress = 0.0
		repeater_charge = 0.0
		return
	var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
	var wep: Dictionary = GameData.get_weapon_by_id(slot["weapon_id"])
	var wid: String = str(wep["id"])

	if bool(wep.get("has_choke", false)) and player.is_ads and rechamber_timer <= 0.0:
		var prev_c: float = choke_progress
		choke_progress = clampf(choke_progress + delta / 1.05, 0.0, 1.0)
		if (prev_c < 0.33 and choke_progress >= 0.33) or (prev_c < 0.66 and choke_progress >= 0.66) or (prev_c < 0.98 and choke_progress >= 0.98):
			AudioSynthesizer.play_shotgun_choke_step(choke_progress)
	else:
		choke_progress = maxf(0.0, choke_progress - delta * 2.5)

	if wid == "repeater3030" and player.is_ads and rechamber_timer <= 0.0:
		repeater_charge = clampf(repeater_charge + delta / 0.55, 0.0, 1.0)
	else:
		repeater_charge = maxf(0.0, repeater_charge - delta * 3.5)


func _cast_ballistic_ray(origin: Vector3, ray_dir: Vector3, max_dist: float = 340.0, is_shotgun_pellet: bool = false, proj_speed: float = 285.0, grav_scale: float = 1.0) -> Dictionary:
	## Upgraded Ballistic Solver:
	## 1. Evaluates Physics World Wall Occlusion
	## 2. Applies realistic Projectile Gravity Drop (`0.5 * g * grav_scale * t_flight^2`) at long range (> 42m) while preserving snappy hit-reg at close/mid range
	## 3. Distinguishes Headshot (`rel_y >= 1.42`), Torso (`0.68 <= rel_y < 1.42`), and Leg (`rel_y < 0.68`) hit zones!
	var wall_dist: float = max_dist
	var final_pos: Vector3 = origin + ray_dir * max_dist

	if world_root != null and world_root.get_world_3d() != null:
		var space_state := world_root.get_world_3d().direct_space_state
		if space_state != null:
			var q := PhysicsRayQueryParameters3D.create(origin, final_pos, 1)
			q.collide_with_bodies = true
			var wall_hit: Dictionary = space_state.intersect_ray(q)
			if not wall_hit.is_empty():
				final_pos = wall_hit["position"]
				wall_dist = origin.distance_to(final_pos)

	var best_bot: ApexBotAI = null
	var best_dist: float = wall_dist
	var best_head: bool = false
	var best_legs: bool = false
	var best_hit_pt: Vector3 = final_pos

	for bot in enemies:
		if not is_instance_valid(bot) or bot.hp <= 0.0:
			continue
		var bot_feet: Vector3 = bot.global_position
		var to_mid: Vector3 = (bot_feet + Vector3(0, 1.0, 0)) - origin
		var approx_proj: float = to_mid.dot(ray_dir)
		if approx_proj < 0.4 or approx_proj > best_dist + 1.0:
			continue

		var horiz_ray_len_sq: float = ray_dir.x * ray_dir.x + ray_dir.z * ray_dir.z
		var t_closest: float = approx_proj
		if horiz_ray_len_sq > 0.0001:
			var dx: float = bot_feet.x - origin.x
			var dz: float = bot_feet.z - origin.z
			t_closest = clampf((dx * ray_dir.x + dz * ray_dir.z) / horiz_ray_len_sq, 0.4, best_dist)

		# Ballistic gravity drop over distance (starts gently beyond 40m so close/mid range feels ultra-crisp, while snipers/marksman have authentic long-range drop!)
		var eff_dist: float = maxf(0.0, t_closest - 40.0)
		var flight_t: float = eff_dist / maxf(120.0, proj_speed)
		var bullet_drop_y: float = 0.5 * 9.8 * grav_scale * flight_t * flight_t

		var ray_pt: Vector3 = origin + ray_dir * t_closest - Vector3(0.0, bullet_drop_y, 0.0)
		var rel_y: float = ray_pt.y - bot_feet.y
		if rel_y < -0.12 or rel_y > 2.10:
			continue

		var horiz_dist: float = Vector2(ray_pt.x - bot_feet.x, ray_pt.z - bot_feet.z).length()
		var is_head_zone: bool = (rel_y >= 1.42)
		var is_leg_zone: bool = (rel_y < 0.66)
		var base_body_r: float = 0.55 if is_shotgun_pellet else 0.49
		var base_head_r: float = 0.34 if is_shotgun_pellet else 0.31
		var hit_radius: float = base_head_r if is_head_zone else base_body_r

		if horiz_dist <= hit_radius:
			best_dist = t_closest
			best_bot = bot
			best_head = is_head_zone
			best_legs = is_leg_zone
			best_hit_pt = ray_pt

	return {
		"hit_pos": best_hit_pt,
		"hit_bot": best_bot,
		"was_head": best_head,
		"was_legs": best_legs,
		"hit_wall": (best_bot == null and wall_dist < max_dist - 0.1)
	}


func _animate_viewmodel(delta: float) -> void:
	if player.viewmodel_holder.get_child_count() == 0:
		return
	var vm: Node3D = player.viewmodel_holder.get_child(0)
	var gun_rig: Node3D = vm.get_node_or_null("GunRig")
	if gun_rig == null:
		return

	var is_heirloom: bool = (PlayerState.active_slot == 2)
	var slot_cur: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
	var wid_cur: String = str(slot_cur.get("weapon_id", "r301"))
	var wep_cur: Dictionary = GameData.get_weapon_by_id(wid_cur)
	var is_bow: bool = (wid_cur == "bocek" and not is_heirloom)
	var is_healing: bool = (PlayerState.heal_cast_timer > 0.0)
	var is_climbing: bool = player.is_wall_climbing
	var is_mantling: bool = player.is_mantling

	var grip_prof: Dictionary = WeaponMeshBuilder.get_weapon_grip_profile(wid_cur)
	var wep_vm_pos: Vector3 = grip_prof.get("vm_pos", Vector3(0.26, -0.22, -0.52))
	var wep_vm_rot: Vector3 = grip_prof.get("vm_rot", Vector3.ZERO)
	var sprinting: bool = Input.is_key_pressed(KEY_SHIFT) and not player.is_ads and reload_timer <= 0.0 and not is_drawing_bow and not is_healing and not player.is_sliding and not is_climbing and not is_mantling
	var base_pos := Vector3(0.0, -0.15, -0.38) if (is_healing or is_climbing or is_mantling) else (Vector3(0.24, -0.22, -0.46) if is_heirloom else (Vector3(0.22, -0.20, -0.48) if is_bow else wep_vm_pos))
	var optic_node: Node3D = gun_rig.get_node_or_null("OpticPivot")
	var cur_op: String = str(slot_cur.get("optic", "2x_bruiser"))

	if player.is_ads and not is_heirloom and reload_timer <= 0.0 and not is_healing and not is_climbing and not is_mantling:
		if cur_op == "6x_kraber" and not is_bow:
			base_pos = Vector3(0.0, -1.8, -0.4)
			vm.visible = false
		else:
			vm.visible = true
			var is_pistol: bool = (wid_cur == "wingman" or wid_cur == "mozambique" or wid_cur == "re45" or wid_cur == "p2020")
			var ads_y: float = -0.082 if is_bow else (-0.094 if is_pistol else -0.102)
			var ads_z: float = -0.25 if is_bow else -0.24
			base_pos = Vector3(0.0, ads_y, ads_z)
		if optic_node:
			var sight_dot: Node3D = optic_node.get_node_or_null("SightDot")
			if sight_dot:
				sight_dot.visible = false
	else:
		vm.visible = true
		if optic_node:
			var sight_dot: Node3D = optic_node.get_node_or_null("SightDot")
			if sight_dot:
				sight_dot.visible = true

	var ammo_housing: Node3D = gun_rig.get_node_or_null("AmmoScreenHousing")
	if ammo_housing:
		ammo_housing.visible = (not is_healing) and (not is_heirloom) and (not is_climbing) and (not is_mantling)
	var charm_node: Node3D = gun_rig.get_node_or_null("OmamoriCharm")
	if charm_node:
		charm_node.visible = not player.is_ads and not is_healing and not is_climbing and not is_mantling

	# Locomotion Figure-8 Bobbing & Dynamic Rotational Sway
	var bob_x: float = cos(player.bob_time * 0.5) * (0.014 if sprinting else 0.006)
	var bob_y: float = absf(sin(player.bob_time)) * (0.018 if sprinting else 0.007)
	if player.is_ads or player.is_sliding:
		bob_x *= 0.16
		bob_y *= 0.16

	var sway_pos := Vector3(sway_offset.x, sway_offset.y, 0.0)
	if player.is_sliding and not is_healing and not player.is_ads:
		base_pos += Vector3(-0.05, -0.03, 0.04)
	if player.land_compress_timer > 0.0:
		base_pos.y -= sin((player.land_compress_timer / 0.24) * PI) * 0.045
	vm.position = vm.position.lerp(base_pos + Vector3(bob_x, -bob_y, 0) + kick_offset + sway_pos, delta * 18.0)

	var base_cant_rot: Vector3 = Vector3(0, 0, -0.24 if not player.is_ads else -0.08) if is_bow else (Vector3.ZERO if (player.is_ads or is_heirloom) else wep_vm_rot)
	var target_rot := kick_rot + base_cant_rot + Vector3(sway_offset.y * 1.4, sway_offset.x * 1.8, 0.0)
	if player.is_sliding and not is_healing:
		target_rot += Vector3(0.16, 0.24, -0.46)
	elif sprinting and not is_heirloom:
		target_rot = grip_prof.get("sprint_rot", Vector3(0.24, 0.40, -0.24))

	var mag_pivot: Node3D = gun_rig.get_node_or_null("MagPivot")
	var bolt_pivot: Node3D = gun_rig.get_node_or_null("BoltPivot")
	var left_arm: Node3D = gun_rig.get_node_or_null("LeftArmPivot")
	var right_arm: Node3D = gun_rig.get_node_or_null("RightArmPivot")
	var heirloom_pivot: Node3D = gun_rig.get_node_or_null("HeirloomPivot")
	var cons_pivot: Node3D = gun_rig.get_node_or_null("ConsumablePivot")
	var ammo_lbl: Label3D = gun_rig.find_child("AmmoLabel3D", true, false)

	if ammo_lbl != null and not is_heirloom:
		if is_bow:
			ammo_lbl.text = "%02d" % PlayerState.get_reserve_ammo("arrows")
		elif wid_cur == "lstar":
			var heat_pct: int = int(round(lstar_heat * 99.0))
			ammo_lbl.text = "H%02d" % heat_pct if heat_pct > 0 else "%02d" % mini(99, PlayerState.get_reserve_ammo("energy"))
		else:
			ammo_lbl.text = "RLD" if reload_timer > 0.0 else "%02d" % int(slot_cur["ammo"])

	# =========================================================================
	# 0A. FIRST-PERSON WALL-CLIMB (`爬墙`) & LEDGE MANTLE (`扒墙翻越`) HAND CHOREOGRAPHY!
	# =========================================================================
	if is_climbing or is_mantling:
		if cons_pivot != null:
			cons_pivot.visible = false
		# Hide firearm receiver while climbing/mantling so both hands clamber up the wall cleanly!
		for child in gun_rig.get_children():
			if child.name != "LeftArmPivot" and child.name != "RightArmPivot":
				if child.visible:
					child.visible = false

		if is_mantling:
			var mp: float = 1.0 - clampf(player.mantle_timer / maxf(0.01, player.mantle_duration), 0.0, 1.0)
			var push_down: float = sin(mp * PI)
			if left_arm:
				left_arm.position = left_arm.position.lerp(Vector3(-0.14, 0.06 - push_down * 0.22, -0.08), delta * 22.0)
				left_arm.rotation = left_arm.rotation.lerp(Vector3(0.85 - push_down * 1.1, 0.25, -0.35), delta * 22.0)
			if right_arm:
				right_arm.position = right_arm.position.lerp(Vector3(0.14, 0.06 - push_down * 0.22, -0.08), delta * 22.0)
				right_arm.rotation = right_arm.rotation.lerp(Vector3(0.85 - push_down * 1.1, -0.25, 0.35), delta * 22.0)
		else:
			# Alternating hand-over-hand wall clamber motion!
			var cp: float = player.climb_phase
			var l_reach: float = sin(cp)
			var r_reach: float = sin(cp + PI)
			if left_arm:
				left_arm.position = left_arm.position.lerp(Vector3(-0.14, 0.02 + l_reach * 0.14, -0.08 - maxf(0.0, l_reach) * 0.06), delta * 20.0)
				left_arm.rotation = left_arm.rotation.lerp(Vector3(0.95 + l_reach * 0.35, 0.20, -0.22), delta * 20.0)
			if right_arm:
				right_arm.position = right_arm.position.lerp(Vector3(0.14, 0.02 + r_reach * 0.14, -0.08 - maxf(0.0, r_reach) * 0.06), delta * 20.0)
				right_arm.rotation = right_arm.rotation.lerp(Vector3(0.95 + r_reach * 0.35, -0.20, 0.22), delta * 20.0)
		gun_rig.rotation = gun_rig.rotation.lerp(Vector3.ZERO, delta * 18.0)
		return

	# =========================================================================
	# 0B. FIRST-PERSON CONSUMABLE ANIMATION (打药动作 & 使用电池动作 — 完全收起枪械!)
	# =========================================================================
	if is_healing:
		if cons_pivot != null:
			cons_pivot.visible = true
		for child in gun_rig.get_children():
			if child.name != "ConsumablePivot" and child.name != "LeftArmPivot" and child.name != "RightArmPivot":
				if child.visible:
					child.visible = false

		var heal_id: String = PlayerState.active_heal_id
		var is_bat: bool = (heal_id == "shield_battery" or heal_id == "shield_cell" or heal_id == "phoenix_kit")
		var bat_prop: Node3D = cons_pivot.get_node_or_null("BatteryProp") if cons_pivot != null else null
		var med_prop: Node3D = cons_pivot.get_node_or_null("MedProp") if cons_pivot != null else null
		if bat_prop:
			bat_prop.visible = is_bat
		if med_prop:
			med_prop.visible = not is_bat

		var hp_prog: float = 1.0 - clampf(PlayerState.heal_cast_timer / maxf(0.1, PlayerState.heal_cast_total), 0.0, 1.0)
		var pulse_w: float = sin(hp_prog * PI * 8.0)

		if is_bat and bat_prop != null and cons_pivot != null:
			var bcol: Color = Color("#a855f7") if heal_id == "phoenix_kit" else (Color("#06b6d4") if heal_id == "shield_battery" else Color("#3b82f6"))
			var core_mesh: MeshInstance3D = bat_prop.get_node_or_null("BatteryCoreMesh")
			if core_mesh and core_mesh.material_override is StandardMaterial3D:
				var cmat: StandardMaterial3D = core_mesh.material_override
				cmat.albedo_color = bcol
				cmat.emission = bcol
				cmat.emission_energy_multiplier = 3.2 + hp_prog * 5.8
			var blight: OmniLight3D = bat_prop.get_node_or_null("BatteryOmniLight")
			if blight:
				blight.light_color = bcol
				blight.light_energy = 1.4 + hp_prog * 2.4

			cons_pivot.position = cons_pivot.position.lerp(Vector3(0.0, 0.02 + sin(hp_prog * TAU * 3.0) * 0.008, -0.06), delta * 15.0)
			cons_pivot.rotation = Vector3(0.24, -0.10, 0.06 + pulse_w * 0.035)
			var twist_top: Node3D = bat_prop.get_node_or_null("BatteryTwistTop")
			if twist_top:
				twist_top.position.y = 0.095 + clampf(hp_prog * 1.35, 0.0, 1.0) * 0.042
				twist_top.rotation.y = hp_prog * TAU * 3.0

			if left_arm:
				left_arm.position = left_arm.position.lerp(Vector3(-0.055, -0.055, -0.06), delta * 15.0)
				left_arm.rotation = left_arm.rotation.lerp(Vector3(0.38, 0.42, -0.24), delta * 15.0)
			if right_arm:
				right_arm.position = right_arm.position.lerp(Vector3(0.052, 0.115 + clampf(hp_prog * 1.35, 0.0, 1.0) * 0.032, -0.055), delta * 15.0)
				right_arm.rotation = right_arm.rotation.lerp(Vector3(0.62, -0.45, 0.32 + pulse_w * 0.14), delta * 15.0)
			target_rot = Vector3.ZERO
		elif med_prop != null and cons_pivot != null:
			var jab_offset: float = sin(clampf((hp_prog - 0.15) * 3.5, 0.0, 1.0) * PI) * 0.038
			cons_pivot.position = cons_pivot.position.lerp(Vector3(-0.01, 0.02 - jab_offset, -0.07), delta * 15.0)
			cons_pivot.rotation = Vector3(0.42, -0.20, -0.26)
			var plunger: Node3D = med_prop.get_node_or_null("SyringePlunger")
			if plunger:
				plunger.position.y = lerpf(0.102, 0.060, clampf((hp_prog - 0.22) / 0.65, 0.0, 1.0))

			if left_arm:
				left_arm.position = left_arm.position.lerp(Vector3(-0.050, 0.00 - jab_offset, -0.07), delta * 15.0)
				left_arm.rotation = left_arm.rotation.lerp(Vector3(0.46, 0.38, -0.24), delta * 15.0)
			if right_arm:
				right_arm.position = right_arm.position.lerp(Vector3(0.035, 0.095 - jab_offset, -0.065), delta * 15.0)
				right_arm.rotation = right_arm.rotation.lerp(Vector3(0.58, -0.32, 0.25), delta * 15.0)
			target_rot = Vector3.ZERO

		gun_rig.rotation = gun_rig.rotation.lerp(target_rot, delta * 15.0)
		return
	else:
		if cons_pivot != null and cons_pivot.visible:
			cons_pivot.visible = false
		for child in gun_rig.get_children():
			if child.name != "ConsumablePivot" and child.name != "MuzzleFlashNode" and child.name != "KickLegPivot":
				if not child.visible:
					child.visible = true

	# =========================================================================
	# 1. BOCEK COMPOUND BOW DRAW ANIMATION
	# =========================================================================
	if is_bow:
		var str_piv: Node3D = gun_rig.get_node_or_null("BowStringPivot")
		var arr_piv: Node3D = gun_rig.get_node_or_null("NockedArrowPivot")
		var top_cam: Node3D = gun_rig.get_node_or_null("TopCam")
		var bot_cam: Node3D = gun_rig.get_node_or_null("BottomCam")
		var draw_z: float = bow_draw_progress * 0.26
		if str_piv:
			str_piv.position.z = lerpf(str_piv.position.z, 0.04 + draw_z, delta * 22.0)
		if arr_piv:
			arr_piv.position.z = lerpf(arr_piv.position.z, 0.04 + draw_z, delta * 22.0)
		if top_cam:
			top_cam.rotation.x = -bow_draw_progress * 1.4
		if bot_cam:
			bot_cam.rotation.x = bow_draw_progress * 1.4
		if right_arm:
			right_arm.position = right_arm.position.lerp(Vector3(0.03, -0.01, 0.08 + draw_z), delta * 20.0)
		if left_arm and quick_melee_timer <= 0.0:
			left_arm.position = left_arm.position.lerp(Vector3(-0.02, -0.04, -0.14), delta * 16.0)

	# =========================================================================
	# 2. 28 INDIVIDUALLY CHOREOGRAPHED WEAPON RELOAD ANIMATIONS (`每个武器单独优化换弹`)
	# =========================================================================
	var is_bullpup: bool = (str(wep_cur.get("stock_type", "")) == "bullpup")
	var base_mag_pos := Vector3(0, -0.14, 0.22 if is_bullpup else -0.05)
	if wid_cur == "wingman":
		base_mag_pos = Vector3(0, 0.018, -0.02)
	elif wid_cur == "peacekeeper":
		base_mag_pos = Vector3(-0.02, -0.02, -0.08)
	elif wid_cur == "mastiff" or wid_cur == "repeater3030":
		base_mag_pos = Vector3(0, -0.04, -0.06)
	elif wid_cur == "chargerifle":
		base_mag_pos = Vector3(0, -0.11, 0.02)
	elif wid_cur == "kraber":
		base_mag_pos = Vector3(-0.055, 0.02, -0.02)
	elif wid_cur == "prowler":
		base_mag_pos = Vector3(0, 0.052, 0.12)

	if reload_timer > 0.0 and not is_heirloom:
		var p: float = 1.0 - clampf(reload_timer / maxf(0.01, reload_total), 0.0, 1.0)
		target_rot = _animate_individual_weapon_reload(wid_cur, p, base_mag_pos, mag_pivot, bolt_pivot, left_arm, right_arm, float(wep_cur.get("rec_len", 0.48)))
	elif not is_bow:
		if mag_pivot:
			mag_pivot.position = mag_pivot.position.lerp(base_mag_pos, delta * 16.0)
			mag_pivot.rotation = mag_pivot.rotation.lerp(Vector3.ZERO, delta * 16.0)
		if bolt_pivot:
			if rechamber_timer > 0.0:
				var rp: float = 1.0 - (rechamber_timer / maxf(0.01, rechamber_total))
				var r_wave: float = sin(rp * PI)
				if wid_cur == "peacekeeper" or wid_cur == "repeater3030":
					bolt_pivot.rotation.x = r_wave * 1.25
					target_rot.x += r_wave * 0.28
					target_rot.z -= r_wave * 0.20
				elif wid_cur == "mastiff":
					bolt_pivot.position.z = -0.22 + r_wave * 0.11
					if left_arm:
						left_arm.position.z = -0.18 + r_wave * 0.11
				else:
					bolt_pivot.position.z = -0.04 + r_wave * 0.14
					bolt_pivot.rotation.z = -r_wave * 0.92
					target_rot.z += r_wave * 0.26
			else:
				var base_bolt_z: float = -0.22 if wid_cur == "mastiff" else (0.06 if (wid_cur == "peacekeeper" or wid_cur == "repeater3030") else (-0.06 if wid_cur == "chargerifle" else -0.04))
				bolt_pivot.position.z = base_bolt_z + bolt_back_offset
				bolt_pivot.rotation = bolt_pivot.rotation.lerp(Vector3.ZERO, delta * 16.0)
		if left_arm and not is_heirloom:
			var target_la_pos: Vector3 = grip_prof.get("left_pos", Vector3(-0.055, -0.045, -0.18))
			var target_la_rot: Vector3 = grip_prof.get("left_rot", Vector3.ZERO)
			if player.is_sliding:
				target_la_pos += Vector3(-0.035, -0.04, 0.03)
				target_la_rot += Vector3(0.20, 0.16, -0.30)
			left_arm.position = left_arm.position.lerp(target_la_pos, delta * 14.0)
			left_arm.rotation = left_arm.rotation.lerp(target_la_rot, delta * 14.0)
		if right_arm and not is_heirloom:
			var target_ra_pos: Vector3 = grip_prof.get("right_pos", Vector3(0.02, -0.10, 0.105))
			var target_ra_rot: Vector3 = grip_prof.get("right_rot", Vector3.ZERO)
			right_arm.position = right_arm.position.lerp(target_ra_pos, delta * 14.0)
			right_arm.rotation = right_arm.rotation.lerp(target_ra_rot, delta * 14.0)

	# =========================================================================
	# 3. MOCAP KEYFRAME QUICK MELEE STRIKE ANIMATION (V Key: Hook / Rifle-Butt / Flying Jump-Kick / Sliding Uppercut)
	# =========================================================================
	var kick_leg_node: Node3D = gun_rig.get_node_or_null("KickLegPivot")
	if kick_leg_node:
		kick_leg_node.visible = (quick_melee_timer > 0.0 and quick_melee_variant == 2)

	if quick_melee_timer > 0.0 and not is_heirloom:
		var mp: float = clampf(1.0 - (quick_melee_timer / maxf(0.01, quick_melee_total)), 0.0, 1.0)
		if quick_melee_variant == 2:
			# MoCap Clip: Airborne Taekwondo Flying Jump-Kick (With 1st-Person 3D Boot Thrust!)
			vm.position += _sample_vec3_keyframes([
				[0.0, Vector3.ZERO],
				[0.14, Vector3(-0.14, -0.06, 0.06)],
				[0.36, Vector3(-0.22, -0.12, -0.10)],
				[0.50, Vector3(-0.20, -0.10, -0.08)],
				[1.0, Vector3.ZERO]
			], mp)
			target_rot += _sample_vec3_keyframes([
				[0.0, Vector3.ZERO],
				[0.14, Vector3(0.28, 0.45, -0.38)],
				[0.36, Vector3(0.52, 0.72, -0.62)],
				[0.52, Vector3(0.45, 0.60, -0.50)],
				[1.0, Vector3.ZERO]
			], mp)
			if kick_leg_node:
				kick_leg_node.position = _sample_vec3_keyframes([
					[0.0, Vector3(0.08, -0.45, 0.22)],
					[0.14, Vector3(0.05, -0.25, -0.05)],
					[0.36, Vector3(-0.04, 0.02, -0.58)],
					[0.48, Vector3(-0.04, 0.00, -0.55)],
					[0.76, Vector3(0.04, -0.22, -0.12)],
					[1.0, Vector3(0.08, -0.45, 0.22)]
				], mp)
				kick_leg_node.rotation = _sample_vec3_keyframes([
					[0.0, Vector3(-0.35, 0.0, 0.0)],
					[0.14, Vector3(-0.10, 0.12, -0.18)],
					[0.36, Vector3(0.18, 0.22, -0.42)],
					[0.50, Vector3(0.15, 0.18, -0.38)],
					[1.0, Vector3(-0.35, 0.0, 0.0)]
				], mp)
		elif quick_melee_variant == 3:
			# MoCap Clip: Sliding Rising Dragon Uppercut (Low Coil -> Skyward Fist Launch)
			vm.position += _sample_vec3_keyframes([
				[0.0, Vector3.ZERO],
				[0.16, Vector3(0.16, -0.18, 0.08)],
				[0.36, Vector3(0.12, 0.08, -0.18)],
				[0.50, Vector3(0.10, 0.10, -0.14)],
				[1.0, Vector3.ZERO]
			], mp)
			target_rot += _sample_vec3_keyframes([
				[0.0, Vector3.ZERO],
				[0.16, Vector3(-0.35, -0.55, 0.45)],
				[0.36, Vector3(0.55, -0.68, 0.48)],
				[0.52, Vector3(0.42, -0.52, 0.35)],
				[1.0, Vector3.ZERO]
			], mp)
			if left_arm:
				left_arm.position = _sample_vec3_keyframes([
					[0.0, Vector3(-0.055, -0.045, -0.18)],
					[0.16, Vector3(-0.18, -0.26, 0.04)],
					[0.36, Vector3(0.14, 0.22, -0.56)],
					[0.48, Vector3(0.12, 0.24, -0.52)],
					[0.75, Vector3(-0.04, 0.02, -0.28)],
					[1.0, Vector3(-0.055, -0.045, -0.18)]
				], mp)
				left_arm.rotation = _sample_vec3_keyframes([
					[0.0, Vector3.ZERO],
					[0.16, Vector3(-0.45, -0.35, 0.25)],
					[0.36, Vector3(1.18, 0.48, -0.52)],
					[0.50, Vector3(1.10, 0.42, -0.45)],
					[1.0, Vector3.ZERO]
				], mp)
		elif quick_melee_variant == 0:
			# MoCap Clip: Brawler Lead Left Hook (Chamber Left -> Snap Across Jaw -> Guard Return)
			vm.position += _sample_vec3_keyframes([
				[0.0, Vector3.ZERO],
				[0.15, Vector3(0.15, -0.10, 0.06)],
				[0.36, Vector3(0.18, -0.08, -0.14)],
				[0.48, Vector3(0.16, -0.07, -0.12)],
				[1.0, Vector3.ZERO]
			], mp)
			target_rot += _sample_vec3_keyframes([
				[0.0, Vector3.ZERO],
				[0.15, Vector3(0.18, -0.42, 0.32)],
				[0.36, Vector3(0.35, -0.78, 0.48)],
				[0.50, Vector3(0.28, -0.65, 0.38)],
				[1.0, Vector3.ZERO]
			], mp)
			if left_arm:
				left_arm.position = _sample_vec3_keyframes([
					[0.0, Vector3(-0.055, -0.045, -0.18)],
					[0.15, Vector3(-0.24, -0.06, 0.05)],
					[0.35, Vector3(0.16, 0.05, -0.58)],
					[0.46, Vector3(0.22, 0.04, -0.54)],
					[0.74, Vector3(-0.02, -0.02, -0.28)],
					[1.0, Vector3(-0.055, -0.045, -0.18)]
				], mp)
				left_arm.rotation = _sample_vec3_keyframes([
					[0.0, Vector3.ZERO],
					[0.15, Vector3(0.12, -0.48, 0.35)],
					[0.35, Vector3(0.68, 0.78, -0.58)],
					[0.48, Vector3(0.62, 0.85, -0.62)],
					[1.0, Vector3.ZERO]
				], mp)
		else:
			# MoCap Clip: Two-Handed Rifle-Butt Crosscheck Smash
			vm.position += _sample_vec3_keyframes([
				[0.0, Vector3.ZERO],
				[0.16, Vector3(0.12, 0.08, 0.14)],
				[0.36, Vector3(-0.12, 0.04, -0.32)],
				[0.48, Vector3(-0.14, 0.02, -0.28)],
				[0.75, Vector3(-0.04, -0.04, -0.08)],
				[1.0, Vector3.ZERO]
			], mp)
			target_rot += _sample_vec3_keyframes([
				[0.0, Vector3.ZERO],
				[0.16, Vector3(0.32, -0.48, 0.35)],
				[0.36, Vector3(-0.48, 0.68, -0.56)],
				[0.50, Vector3(-0.42, 0.62, -0.48)],
				[1.0, Vector3.ZERO]
			], mp)

	# =========================================================================
	# 4. 12 LEGEND-SPECIFIC HEIRLOOM GRIPS & MOCAP 3-STAGE ATTACK CHOREOGRAPHY
	# =========================================================================
	if is_heirloom and heirloom_pivot:
		var is_hl_atk: bool = (melee_swing_timer > 0.0 or quick_melee_timer > 0.0)
		var sp_hl: float = 0.0
		if melee_swing_timer > 0.0:
			sp_hl = clampf(1.0 - (melee_swing_timer / maxf(0.01, melee_swing_total)), 0.0, 1.0)
		elif quick_melee_timer > 0.0:
			sp_hl = clampf(1.0 - (quick_melee_timer / maxf(0.01, quick_melee_total)), 0.0, 1.0)
		var hl_cam: Dictionary = WeaponMeshBuilder.animate_custom_heirloom_1p(
			PlayerState.selected_legend_id,
			melee_combo_idx,
			sp_hl,
			is_hl_atk,
			sprinting,
			inspect_timer > 0.0,
			player.bob_time,
			delta,
			heirloom_pivot,
			left_arm,
			right_arm,
			kick_leg_node,
			not player.is_on_floor(),
			player.is_sliding
		)
		target_rot.z += float(hl_cam.get("cam_roll", 0.0))
		target_rot.x += float(hl_cam.get("cam_pitch", 0.0))
	elif inspect_timer > 0.0:
		var ip: float = 1.0 - (inspect_timer / 3.2)
		target_rot.y += sin(ip * TAU) * 0.68
		target_rot.z += sin(ip * PI) * 0.42
		target_rot.x += 0.18 * sin(ip * PI)

	gun_rig.rotation = gun_rig.rotation.lerp(target_rot, delta * 16.0)


func _animate_individual_weapon_reload(wid: String, p: float, base_mag_pos: Vector3, mag_pivot: Node3D, bolt_pivot: Node3D, left_arm: Node3D, right_arm: Node3D, rec_len: float) -> Vector3:
	## Bespoke weapon-by-weapon reload choreography for all 28 weapons in GameData.WEAPONS!
	var rot := Vector3.ZERO
	if right_arm:
		right_arm.position = Vector3(0.02, -0.10, rec_len * 0.22)
		right_arm.rotation = Vector3.ZERO

	# 1. Segmented Shell-by-Shell Loaders: Mastiff Shotgun & 30-30 Repeater
	if is_segmented_reload or wid == "mastiff" or wid == "repeater3030":
		var sh_wave: float = sin(p * PI)
		if wid == "mastiff":
			# Mastiff: Inverted bottom-gate thumb shell push with heavy forward cant
			rot = Vector3(0.32, 0.24, 0.58)
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(0, -0.05 * (1.0 - sh_wave), -0.03 * sh_wave)
			if left_arm:
				left_arm.position = Vector3(-0.02, -0.16 + sh_wave * 0.12, -0.08 - sh_wave * 0.04)
				left_arm.rotation = Vector3(0.48 * sh_wave, 0.32, -0.22)
		else:
			# 30-30 Repeater: Right-side brass loading gate thumb insertion + lever-loop stabilizing
			rot = Vector3(0.18, -0.32, -0.52)
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(0.04 * (1.0 - sh_wave), -0.02, 0.04 * sh_wave)
			if left_arm:
				left_arm.position = Vector3(0.03, -0.12 + sh_wave * 0.10, -0.03)
				left_arm.rotation = Vector3(0.36 * sh_wave, -0.28, 0.24)
		return rot

	# 2. Wingman Revolver: Swing-out cylinder -> upward brass dump -> speedloader twist -> wrist flick close
	if wid == "wingman":
		if p < 0.28:
			var t1: float = p / 0.28
			rot = Vector3(0.42 * t1, -0.18 * t1, -0.38 * t1)
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(-0.046 * t1, -0.01 * t1, 0)
				mag_pivot.rotation.z = 0.92 * t1
			if left_arm:
				left_arm.position = Vector3(-0.06, -0.04 - 0.12 * t1, -0.04)
		elif p < 0.72:
			var t2: float = (p - 0.28) / 0.44
			var ins: float = sin(t2 * PI)
			rot = Vector3(0.28, 0.15, 0.44)
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(-0.046, 0, 0)
				mag_pivot.rotation.z = 0.92
				mag_pivot.rotation.y = t2 * PI
			if left_arm:
				left_arm.position = Vector3(-0.06, -0.16 + ins * 0.16, -0.02 - ins * 0.04)
				left_arm.rotation = Vector3(0.35 * ins, 0.30, 0.0)
		else:
			var t3: float = (p - 0.72) / 0.28
			var flick: float = sin(t3 * PI)
			rot = Vector3(-0.18 * flick, 0.24 * flick, -0.72 * flick)
			if mag_pivot:
				mag_pivot.position = base_mag_pos.lerp(base_mag_pos + Vector3(-0.046, 0, 0), 1.0 - t3)
				mag_pivot.rotation.z = lerpf(0.92, 0.0, t3)
				mag_pivot.rotation.y = 0.0
			if left_arm:
				left_arm.position = Vector3(-0.055, -0.045, -0.14)
		return rot

	# 3. Peacekeeper: Side star-cell cartridge swap + 360-degree lever-action flip cock
	if wid == "peacekeeper":
		if p < 0.62:
			var tc: float = p / 0.62
			var cell_arc: float = sin(tc * PI)
			rot = Vector3(0.22, 0.26, 0.58)
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(-0.15 * cell_arc, -0.12 * cell_arc, 0)
			if left_arm:
				left_arm.position = Vector3(-0.05 - 0.11 * cell_arc, -0.06 - 0.12 * cell_arc, -0.08)
				left_arm.rotation = Vector3(0.35 * cell_arc, 0.40, -0.25)
		else:
			var tl: float = (p - 0.62) / 0.38
			var flip_wave: float = sin(tl * PI)
			rot = Vector3(0.48 * flip_wave, -0.15 * flip_wave, -0.32 * flip_wave)
			if mag_pivot:
				mag_pivot.position = base_mag_pos
			if bolt_pivot:
				bolt_pivot.rotation.x = tl * TAU
			if left_arm:
				left_arm.position = Vector3(-0.055, -0.045, -0.18)
		return rot

	# 4. Prowler Burst PDW: Iconic P90-style TOP-REAR Horizontal Magazine Lift-Out & Overhead Slam!
	if wid == "prowler":
		if p < 0.34:
			var t1: float = p / 0.34
			rot = Vector3(-0.18 * t1, 0.22 * t1, -0.38 * t1)
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(-0.04 * t1, 0.18 * t1, 0.05 * t1)
				mag_pivot.rotation.z = 0.35 * t1
			if left_arm:
				left_arm.position = Vector3(-0.03, 0.06 + 0.16 * t1, 0.10)
				left_arm.rotation = Vector3(-0.45 * t1, 0.25, -0.30)
		elif p < 0.70:
			var t2: float = (p - 0.34) / 0.36
			var slam: float = clampf(t2 * 1.25, 0.0, 1.0)
			rot = Vector3(-0.18 + 0.12 * slam, 0.22, -0.38)
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(0, lerpf(0.20, 0.0, slam), 0)
				mag_pivot.rotation = Vector3.ZERO
			if left_arm:
				left_arm.position = Vector3(-0.02, lerpf(0.24, 0.06, slam), 0.10)
				left_arm.rotation = Vector3(-0.35 * (1.0 - slam), 0.20, -0.15)
		else:
			var t3: float = (p - 0.70) / 0.30
			var rack: float = sin(t3 * PI)
			rot = Vector3(0.10 * rack, -0.14 * rack, 0.22 * rack)
			if mag_pivot:
				mag_pivot.position = base_mag_pos
			if bolt_pivot:
				bolt_pivot.position.z = -0.04 + rack * 0.10
			if left_arm:
				left_arm.position = Vector3(-0.05, -0.02, -0.10 + rack * 0.09)
		return rot

	# 5. Kraber .50-Cal Mythic Sniper: Left-Side Horizontal Magazine Pull + Heavy 2-Step Bolt Lift & Pull!
	if wid == "kraber":
		if p < 0.32:
			var t1: float = p / 0.32
			rot = Vector3(0.16 * t1, 0.32 * t1, 0.48 * t1)
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(-0.22 * t1, -0.05 * t1, 0)
				mag_pivot.rotation.z = 0.28 * t1
			if left_arm:
				left_arm.position = Vector3(-0.08 - 0.18 * t1, 0.00 - 0.05 * t1, -0.02)
		elif p < 0.64:
			var t2: float = (p - 0.32) / 0.32
			var snap_k: float = clampf(t2 * 1.25, 0.0, 1.0)
			rot = Vector3(0.16, 0.32, 0.48)
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(lerpf(-0.22, 0.0, snap_k), 0, 0)
				mag_pivot.rotation.z = lerpf(0.28, 0.0, snap_k)
			if left_arm:
				left_arm.position = Vector3(lerpf(-0.26, -0.07, snap_k), 0.01, -0.02)
		else:
			var t3: float = (p - 0.64) / 0.36
			var pull_k: float = sin(t3 * PI)
			rot = Vector3(0.22 * pull_k, -0.28 * pull_k, 0.56 * pull_k)
			if mag_pivot:
				mag_pivot.position = base_mag_pos
			if bolt_pivot:
				bolt_pivot.rotation.z = -pull_k * 0.95
				bolt_pivot.position.z = -0.04 + pull_k * 0.16
			if left_arm:
				left_arm.position = Vector3(0.04, 0.02, 0.04 + pull_k * 0.14)
		return rot

	# 6. Charge Rifle ("滋崩"): Bottom Cylindrical Capacitor Canister Twist-and-Pull + Top Cooling Louver Vent!
	if wid == "chargerifle":
		if p < 0.36:
			var t1: float = p / 0.36
			rot = Vector3(0.26 * t1, 0.18 * t1, 0.42 * t1)
			if bolt_pivot:
				bolt_pivot.position.y = 0.045 + 0.028 * t1
			if mag_pivot:
				mag_pivot.rotation.y = t1 * PI
				mag_pivot.position = base_mag_pos + Vector3(0, -0.22 * t1, 0)
			if left_arm:
				left_arm.position = Vector3(-0.03, -0.12 - 0.18 * t1, 0.02)
				left_arm.rotation.y = t1 * 0.8
		elif p < 0.74:
			var t2: float = (p - 0.36) / 0.38
			var twist_in: float = clampf(t2 * 1.2, 0.0, 1.0)
			rot = Vector3(0.26, 0.18, 0.42)
			if bolt_pivot:
				bolt_pivot.position.y = 0.073
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(0, lerpf(-0.22, 0.0, twist_in), 0)
				mag_pivot.rotation.y = (1.0 - twist_in) * PI
			if left_arm:
				left_arm.position = Vector3(-0.02, lerpf(-0.30, -0.11, twist_in), 0.02)
		else:
			var t3: float = (p - 0.74) / 0.26
			rot = Vector3(0.26 * (1.0 - t3), 0.18 * (1.0 - t3), 0.42 * (1.0 - t3))
			if bolt_pivot:
				bolt_pivot.position.y = lerpf(0.073, 0.045, t3)
			if mag_pivot:
				mag_pivot.position = base_mag_pos
				mag_pivot.rotation = Vector3.ZERO
			if left_arm:
				left_arm.position = Vector3(-0.055, -0.045, -0.16)
		return rot

	# 7. L-STAR EMG: Overheated Top/Side Plasma Lens Core Swap & Heat Purge!
	if wid == "lstar":
		var vent_arc: float = sin(p * PI)
		rot = Vector3(0.24 * vent_arc, -0.32 * vent_arc, -0.48 * vent_arc)
		if bolt_pivot:
			bolt_pivot.position.y = 0.032 + vent_arc * 0.045
			bolt_pivot.rotation.z = -vent_arc * 0.65
		if mag_pivot:
			mag_pivot.position = base_mag_pos + Vector3(-0.12 * vent_arc, 0.08 * vent_arc, -0.08 * vent_arc)
		if left_arm:
			left_arm.position = Vector3(-0.06 - 0.08 * vent_arc, 0.02 + 0.06 * vent_arc, -0.12)
			left_arm.rotation = Vector3(0.45 * vent_arc, 0.35, -0.30 * vent_arc)
		return rot

	# 8. Mozambique Shotgun Pistol: Break-Action Wrist Flick + Triangular 3-Shell Pod Insert!
	if wid == "mozambique":
		if p < 0.30:
			var t1: float = p / 0.30
			rot = Vector3(0.55 * t1, 0.12 * t1, 0.28 * t1)
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(0, -0.16 * t1, 0.08 * t1)
		elif p < 0.72:
			var t2: float = (p - 0.30) / 0.42
			var pod_in: float = sin(t2 * PI)
			rot = Vector3(0.55, 0.18, 0.35)
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(0, -0.14 * (1.0 - t2), 0.04 * (1.0 - t2))
			if left_arm:
				left_arm.position = Vector3(-0.02, -0.12 + pod_in * 0.12, -0.02)
		else:
			var t3: float = (p - 0.72) / 0.28
			var snap_shut: float = sin(t3 * PI)
			rot = Vector3(-0.28 * snap_shut, 0.0, -0.35 * snap_shut)
			if mag_pivot:
				mag_pivot.position = base_mag_pos
		return rot

	# 9. Weapon-Specific Tuning Parameters for Standard / Bullpup / SMG / LMG / DMR / Pistol Archetypes
	var cant_z: float = 0.54
	var cant_y: float = 0.18
	var pitch_x: float = 0.28
	var mag_drop_vec := Vector3(0.0, -0.28, 0.0)
	var bolt_side_x: float = -0.05

	match wid:
		"r301":
			cant_z = 0.52; cant_y = 0.20; pitch_x = 0.26; mag_drop_vec = Vector3(0.0, -0.28, -0.05)
		"flatline":
			cant_z = -0.58; cant_y = -0.28; pitch_x = 0.34; mag_drop_vec = Vector3(0.0, -0.26, 0.08); bolt_side_x = 0.04
		"hemlok":
			cant_z = 0.46; cant_y = 0.15; pitch_x = 0.32; mag_drop_vec = Vector3(0.0, -0.30, -0.04)
		"nemesis":
			cant_z = 0.42; cant_y = 0.24; pitch_x = 0.24; mag_drop_vec = Vector3(0.0, -0.26, -0.08)
		"havoc":
			cant_z = -0.44; cant_y = -0.20; pitch_x = 0.30; mag_drop_vec = Vector3(0.0, -0.25, 0.0)
		"r99":
			cant_z = 0.64; cant_y = 0.26; pitch_x = 0.22; mag_drop_vec = Vector3(-0.04, -0.30, -0.04)
		"volt":
			cant_z = 0.48; cant_y = 0.22; pitch_x = 0.20; mag_drop_vec = Vector3(-0.08, -0.24, 0.0)
		"car":
			cant_z = 0.58; cant_y = 0.24; pitch_x = 0.26; mag_drop_vec = Vector3(0.0, -0.28, -0.06)
		"alternator":
			cant_z = -0.48; cant_y = 0.16; pitch_x = 0.24; mag_drop_vec = Vector3(0.0, -0.26, 0.02); bolt_side_x = 0.0
		"spitfire":
			cant_z = 0.38; cant_y = 0.28; pitch_x = 0.34; mag_drop_vec = Vector3(-0.06, -0.32, 0.0); bolt_side_x = 0.05
		"rampage":
			cant_z = -0.52; cant_y = -0.24; pitch_x = 0.32; mag_drop_vec = Vector3(-0.14, -0.26, 0.0); bolt_side_x = 0.04
		"devotion":
			cant_z = 0.44; cant_y = 0.26; pitch_x = 0.30; mag_drop_vec = Vector3(-0.08, -0.30, 0.0)
		"g7":
			cant_z = -0.42; cant_y = -0.18; pitch_x = 0.26; mag_drop_vec = Vector3(0.0, -0.26, 0.0); bolt_side_x = 0.04
		"tripletake":
			cant_z = 0.40; cant_y = 0.16; pitch_x = 0.28; mag_drop_vec = Vector3(0.0, -0.24, -0.04); bolt_side_x = 0.0
		"sentinel":
			cant_z = 0.46; cant_y = 0.22; pitch_x = 0.24; mag_drop_vec = Vector3(0.0, -0.26, 0.0); bolt_side_x = 0.05
		"longbow":
			cant_z = 0.50; cant_y = 0.20; pitch_x = 0.28; mag_drop_vec = Vector3(0.0, -0.28, -0.02)
		"eva8":
			cant_z = 0.62; cant_y = 0.28; pitch_x = 0.32; mag_drop_vec = Vector3(-0.06, -0.28, -0.06); bolt_side_x = 0.04
		"re45":
			cant_z = -0.58; cant_y = 0.24; pitch_x = 0.22; mag_drop_vec = Vector3(0.0, -0.24, 0.08)
		"p2020":
			cant_z = -0.52; cant_y = 0.20; pitch_x = 0.18; mag_drop_vec = Vector3(0.0, -0.22, 0.06)

	var mag_end_p: float = 0.72 if is_empty_reload else 0.86
	if p < 0.34:
		var t1: float = p / 0.34
		rot = Vector3(pitch_x * t1, cant_y * t1, cant_z * t1)
		if mag_pivot:
			mag_pivot.position = base_mag_pos + mag_drop_vec * t1
			mag_pivot.rotation.x = t1 * 0.55
		if left_arm:
			left_arm.position = Vector3(-0.04 + mag_drop_vec.x * t1, -0.14 + mag_drop_vec.y * 0.65 * t1, base_mag_pos.z)
			left_arm.rotation = Vector3(0.28 * t1, 0.22, -0.25 * t1)
	elif p < mag_end_p:
		var t2: float = (p - 0.34) / (mag_end_p - 0.34)
		var snap_t: float = clampf(t2 * 1.25, 0.0, 1.0)
		var palm_bump: float = sin(clampf((t2 - 0.65) / 0.35, 0.0, 1.0) * PI) * 0.08
		rot = Vector3(pitch_x - palm_bump, cant_y, cant_z)
		if mag_pivot:
			mag_pivot.position = base_mag_pos.lerp(base_mag_pos + mag_drop_vec, 1.0 - snap_t)
			mag_pivot.rotation.x = lerpf(0.50, 0.0, snap_t)
		if left_arm:
			left_arm.position = Vector3(-0.02, lerpf(-0.34, -0.12 + palm_bump * 0.4, snap_t), base_mag_pos.z)
			left_arm.rotation = Vector3(0.28 * (1.0 - snap_t), 0.25, -0.15)
	else:
		var t3: float = (p - mag_end_p) / maxf(0.05, 1.0 - mag_end_p)
		var pull: float = sin(t3 * PI)
		rot = Vector3(0.14 * (1.0 - t3), -0.24 * pull, -0.44 * pull)
		if mag_pivot:
			mag_pivot.position = base_mag_pos
			mag_pivot.rotation = Vector3.ZERO
		if bolt_pivot:
			bolt_pivot.position.z = -0.04 + pull * 0.13
			if wid == "sentinel":
				bolt_pivot.rotation.z = -pull * 0.88
		if left_arm:
			left_arm.position = Vector3(bolt_side_x, 0.02 * pull - 0.04, -0.08 + pull * 0.12)
			left_arm.rotation = Vector3(0.35 * pull, 0.24 * pull, 0.0)
	return rot


func try_fire(enemies_list: Array) -> void:
	if player == null or rechamber_timer > 0.0 or quick_melee_timer > 0.0 or PlayerState.heal_cast_timer > 0.0 or player.is_wall_climbing or player.is_mantling:
		return

	self.enemies = enemies_list

	if PlayerState.active_slot == 2:
		_perform_heirloom_slash(enemies_list)
		return

	var slot_idx: int = clampi(PlayerState.active_slot, 0, 1)
	var slot: Dictionary = PlayerState.loadout[slot_idx]
	var wep: Dictionary = GameData.get_weapon_by_id(slot["weapon_id"])
	var wid: String = str(wep["id"])
	var cat: String = str(wep.get("cat", "AR"))

	if wid == "bocek":
		return

	# Allow interrupting segmented shell-by-shell reload (Mastiff / 30-30) if at least 1 round is chambered!
	if reload_timer > 0.0:
		if is_segmented_reload and int(slot["ammo"]) > 0:
			reload_timer = 0.0
			is_segmented_reload = false
		else:
			return

	# Iconic Apex Charge Rifle (充能步枪 / 滋崩)
	if wid == "chargerifle":
		if is_charging_beam:
			return
		var now_cr: int = Time.get_ticks_msec()
		if now_cr - last_fire_ms < 1100:
			return
		if int(slot["ammo"]) <= 0:
			start_reload()
			return
		is_charging_beam = true
		charge_timer = 0.0
		charge_last_tick = 0.0
		charge_beng_fired = false
		AudioSynthesizer.play_charge_rifle_charge(0.0)
		PlayerState.toast_pushed.emit("⚡ 充能步枪：锁定充能中【先滋后崩】...", "info")
		return

	# HAVOC Rifle 0.28s Turbo Windup before firing burst
	if wid == "havoc" and consecutive_shots == 0 and havoc_windup < 0.24:
		havoc_windup += get_process_delta_time()
		kick_offset += Vector3(randf_range(-0.0015, 0.0015), randf_range(-0.0015, 0.0015), 0.0)
		AudioSynthesizer.play_charge_rifle_charge(havoc_windup / 0.24)
		return

	if burst_shots_remaining > 0:
		return

	var rpm: float = float(wep["rpm"])
	if cat == "SHOTGUN":
		var bolt_t: int = maxi(int(slot.get("bolt", 0)), int(slot.get("mag", 0)))
		rpm *= GameData.get_shotgun_bolt_fire_mult(bolt_t)
	elif wid == "rampage" and float(slot.get("charged", 0.0)) > 0.0:
		rpm *= 1.38
	elif wid == "nemesis":
		rpm *= (1.0 + nemesis_energy_charge * 0.32)
	elif wid == "devotion":
		rpm *= lerpf(0.55, 1.0, devotion_spinup)

	var now: int = Time.get_ticks_msec()
	if now - last_fire_ms < int(60000.0 / rpm):
		return

	if wid == "lstar":
		if lstar_heat >= 0.98:
			start_reload()
			return
		if int(slot["ammo"]) <= 0 and PlayerState.get_reserve_ammo("energy") <= 0 and PlayerState.selected_mode_id != "firing_range":
			PlayerState.toast_pushed.emit("⚠️ 能量备弹耗尽！", "warn")
			return
	elif int(slot["ammo"]) <= 0:
		start_reload()
		return

	var b_cnt: int = int(wep.get("burst_count", 1))
	if b_cnt > 1:
		burst_shots_remaining = maxi(0, mini(b_cnt, int(slot["ammo"])) - 1)
		burst_next_shot_timer = 0.048

	_execute_single_shot(enemies_list, false)


func _execute_single_shot(_enemies_list: Array, is_burst_followup: bool = false) -> void:
	var slot_idx: int = clampi(PlayerState.active_slot, 0, 1)
	var slot: Dictionary = PlayerState.loadout[slot_idx]
	var wep: Dictionary = GameData.get_weapon_by_id(slot["weapon_id"])
	var wid: String = str(wep["id"])
	var cat: String = str(wep["cat"])

	if wid == "lstar":
		if PlayerState.selected_mode_id != "firing_range":
			if PlayerState.get_reserve_ammo("energy") > 0:
				PlayerState.deduct_ammo("energy", 1)
			elif int(slot["ammo"]) > 0:
				slot["ammo"] = int(slot["ammo"]) - 1
			else:
				return
		lstar_heat = clampf(lstar_heat + 0.042, 0.0, 1.0)
		if lstar_heat >= 0.99:
			PlayerState.toast_pushed.emit("🔥 L-STAR 等离子核心过热！正在更换散热透镜...", "warn")
			start_reload()
	else:
		if int(slot["ammo"]) <= 0:
			burst_shots_remaining = 0
			return
		var ammo_cost: int = int(wep.get("ammo_per_shot", 1))
		slot["ammo"] = maxi(0, int(slot["ammo"]) - ammo_cost)

	last_fire_ms = Time.get_ticks_msec()
	consecutive_shots += 1
	if wid == "devotion":
		devotion_spinup = clampf(devotion_spinup + 0.14, 0.0, 1.0)
	elif wid == "nemesis":
		nemesis_energy_charge = clampf(nemesis_energy_charge + 0.09, 0.0, 1.0)

	AudioSynthesizer.play_gunshot(cat, wid)

	# Barrel stabilizer attachment + Authentic Apex Legends Recoil Smoothing (when tracking with mouse!)
	var barrel_tier: int = int(slot.get("barrel", 0))
	var rec_mult: float = 1.0 - float(barrel_tier) * 0.08
	var tracking_speed: float = player.last_mouse_vel.length()
	var recoil_smoothing: float = clampf(1.0 - tracking_speed * 0.042, 0.42, 1.0)

	kick_offset = Vector3(0, 0.011, 0.048 if cat != "SHOTGUN" else 0.076) * rec_mult
	kick_rot = Vector3(0.056 if cat != "SHOTGUN" else 0.098, randf_range(-0.014, 0.014), 0.0) * rec_mult
	bolt_back_offset = 0.095

	var base_v_rec: float = float(wep.get("recoil_v", 0.012))
	var base_h_rec: float = float(wep.get("recoil_h", 0.004))
	var h_dir: float = sin(float(consecutive_shots) * 0.68)
	if wid == "alternator":
		h_dir = 1.0 if (consecutive_shots % 2 == 0) else -1.0
	elif wid == "flatline":
		h_dir = -cos(float(consecutive_shots) * 0.85)
	player.add_camera_recoil(base_v_rec * rec_mult * recoil_smoothing, base_h_rec * h_dir * rec_mult * recoil_smoothing, 0.011 * rec_mult)

	_trigger_muzzle_flash_and_casing(str(wep.get("ammo", "light")) != "energy")

	# Rechamber / Lever-Action / Pump-Action Timing
	var bolt_mult: float = 1.0
	if cat == "SHOTGUN":
		var bolt_t: int = maxi(int(slot.get("bolt", 0)), int(slot.get("mag", 0)))
		bolt_mult = GameData.get_shotgun_bolt_fire_mult(bolt_t)

	if wid == "kraber":
		rechamber_total = 0.82
		rechamber_timer = rechamber_total
		AudioSynthesizer.play_reload_step("bolt_slap")
	elif wid == "sentinel":
		rechamber_total = 0.58
		rechamber_timer = rechamber_total
		AudioSynthesizer.play_reload_step("bolt_slap")
	elif wid == "peacekeeper":
		rechamber_total = 0.56 / bolt_mult
		rechamber_timer = rechamber_total
		AudioSynthesizer.play_reload_step("lever_cock")
	elif wid == "mastiff":
		rechamber_total = 0.40 / bolt_mult
		rechamber_timer = rechamber_total
		AudioSynthesizer.play_reload_step("pump_action")

	# Ballistic Calculation + Authentic Unit-Normalized Shotgun / Multi-Pellet Pattern
	var cam: Camera3D = player.camera
	var origin: Vector3 = cam.global_position
	var fwd: Vector3 = -cam.global_transform.basis.z
	var cam_right: Vector3 = cam.global_transform.basis.x
	var cam_up: Vector3 = cam.global_transform.basis.y

	var spread: float = float(wep["ads_spread"]) if player.is_ads else float(wep["spread"])
	if bool(wep.get("has_choke", false)) and player.is_ads:
		spread *= lerpf(1.0, 0.25, choke_progress)

	var pellets: int = int(wep.get("pellets", 1))
	var pattern_name: String = str(wep.get("pellet_pattern", "single"))
	var pattern_offsets: Array = GameData.get_pellet_pattern_offsets(pattern_name, 1.0)
	var proj_spd: float = float(wep.get("proj_speed", 280.0))
	var grav_sc: float = float(wep.get("grav_scale", 1.0))
	var accent_col: Color = wep.get("accent", Color("#f97316"))

	var total_hit_dmg: int = 0
	var hit_bot: ApexBotAI = null
	var was_head: bool = false
	var pellet_hit_flags: Array = []

	for p in range(pellets):
		var ray_dir: Vector3 = fwd
		if pellets > 1 and p < pattern_offsets.size():
			var po: Vector2 = pattern_offsets[p]
			var sx: float = spread * (0.58 if (wid == "mastiff" and player.is_ads) else 1.0)
			var sy: float = spread * (0.45 if (wid == "mastiff" and player.is_ads) else 1.0)
			ray_dir = (fwd + cam_right * (po.x * sx) + cam_up * (po.y * sy)).normalized()
		else:
			ray_dir = (fwd + cam_right * randf_range(-spread, spread) + cam_up * randf_range(-spread, spread)).normalized()

		var hit_res: Dictionary = _cast_ballistic_ray(origin, ray_dir, 340.0, pellets > 1, proj_spd, grav_sc)
		var p_pos: Vector3 = hit_res["hit_pos"]
		var p_bot: ApexBotAI = hit_res["hit_bot"]
		var p_head: bool = hit_res["was_head"]
		var p_legs: bool = hit_res.get("was_legs", false)

		if p_bot != null:
			pellet_hit_flags.append(true)
			var d: int = int(wep["dmg"])
			if wid == "repeater3030" and repeater_charge > 0.05:
				d = int(round(lerpf(float(d), float(wep.get("max_charge_dmg", 60)), repeater_charge)))
			elif wid == "sentinel" and float(slot.get("charged", 0.0)) > 0.0:
				d = int(wep.get("amped_dmg", 92))
			elif wid == "r301" and player.is_ads and str(slot.get("hopup", "")) == "anvil":
				d = int(round(float(d) * 1.15))
			if (wid == "mozambique" or wid == "p2020" or wid == "re45") and p_bot.shield <= 0.0:
				d = int(round(float(d) * 1.35))
			if p_head:
				d = int(round(float(d) * float(wep["head"])))
				was_head = true
			elif p_legs:
				d = int(round(float(d) * float(wep.get("legs", 0.85))))
			total_hit_dmg += d
			hit_bot = p_bot
		else:
			pellet_hit_flags.append(false)

		if pellets <= 3 or p % 2 == 0 or p_bot != null:
			var tr_rad: float = 0.022 if wid == "lstar" else (0.018 if cat == "SNIPER" else 0.012)
			_spawn_bullet_tracer(origin + Vector3(0, -0.08, 0) + fwd * 0.72, p_pos, accent_col, tr_rad)
			if p == 0 or p_bot != null:
				_spawn_impact_vfx(p_pos, p_bot != null, p_head, accent_col)

	if wid == "repeater3030":
		repeater_charge = 0.0

	if pellets > 1:
		PlayerState.shotgun_pellet_feedback_pushed.emit(pattern_name, pellet_hit_flags, was_head)

	if hit_bot != null and total_hit_dmg > 0:
		hit_bot.apply_damage(total_hit_dmg, was_head, str(wep["name"]))

	if not is_burst_followup:
		BehaviorRecorder.record_event("fire_weapon", {"weapon_id": wid, "cat": cat, "ads": player.is_ads, "hit": hit_bot != null, "dmg": total_hit_dmg})

	PlayerState.state_updated.emit()


func _sample_vec3_keyframes(kfs: Array, t: float) -> Vector3:
	## Evaluates a multi-keyframe MoCap curve [[t0, v0], [t1, v1], ...] using cubic Hermite smoothstep interpolation!
	if kfs.is_empty():
		return Vector3.ZERO
	if t <= float(kfs[0][0]):
		return kfs[0][1]
	for i in range(kfs.size() - 1):
		var t0: float = float(kfs[i][0])
		var t1: float = float(kfs[i + 1][0])
		if t <= t1:
			var local_t: float = clampf((t - t0) / maxf(0.0001, t1 - t0), 0.0, 1.0)
			var smooth_t: float = local_t * local_t * (3.0 - 2.0 * local_t)
			return (kfs[i][1] as Vector3).lerp(kfs[i + 1][1] as Vector3, smooth_t)
	return kfs[kfs.size() - 1][1]


func _animate_mocap_heirloom_combo(lid: String, combo_idx: int, sp: float, heirloom_pivot: Node3D, left_arm: Node3D, right_arm: Node3D) -> void:
	## Multi-keyframe MoCap Heirloom animations across 4 weapon archetypes (Blade, Heavy Axe/Hammer, Spear, Dual/Boxing)
	var is_heavy_wep: bool = (lid == "bloodhound" or lid == "gibraltar" or lid == "caustic" or lid == "horizon" or lid == "mirage")
	var is_spear: bool = (lid == "valkyrie")
	var is_dual_or_box: bool = (lid == "pathfinder" or lid == "lifeline" or lid == "ash")

	if is_spear:
		# Valkyrie Suzaku Spear: Wide Sweep -> Viper Thrust -> Overhead Helicopter Twirl
		if combo_idx % 3 == 0:
			heirloom_pivot.position = _sample_vec3_keyframes([[0.0, Vector3(0.04, -0.02, -0.06)], [0.16, Vector3(0.26, 0.08, 0.08)], [0.36, Vector3(-0.34, 0.02, -0.34)], [0.52, Vector3(-0.28, 0.0, -0.28)], [1.0, Vector3(0.04, -0.02, -0.06)]], sp)
			heirloom_pivot.rotation = _sample_vec3_keyframes([[0.0, Vector3(0.32, -0.28, 0.18)], [0.16, Vector3(0.15, -0.95, 0.85)], [0.36, Vector3(0.85, 1.35, -1.15)], [0.52, Vector3(0.75, 1.15, -0.95)], [1.0, Vector3(0.32, -0.28, 0.18)]], sp)
		elif combo_idx % 3 == 1:
			heirloom_pivot.position = _sample_vec3_keyframes([[0.0, Vector3(0.04, -0.02, -0.06)], [0.15, Vector3(0.14, -0.10, 0.18)], [0.35, Vector3(-0.04, 0.04, -0.58)], [0.48, Vector3(-0.04, 0.04, -0.54)], [1.0, Vector3(0.04, -0.02, -0.06)]], sp)
			heirloom_pivot.rotation = _sample_vec3_keyframes([[0.0, Vector3(0.32, -0.28, 0.18)], [0.15, Vector3(1.15, -0.10, 0.05)], [0.35, Vector3(1.48, 0.08, -0.12)], [0.50, Vector3(1.42, 0.05, 0.65)], [1.0, Vector3(0.32, -0.28, 0.18)]], sp)
		else:
			heirloom_pivot.position = _sample_vec3_keyframes([[0.0, Vector3(0.04, -0.02, -0.06)], [0.18, Vector3(0.0, 0.18, -0.12)], [0.38, Vector3(0.0, -0.14, -0.42)], [1.0, Vector3(0.04, -0.02, -0.06)]], sp)
			heirloom_pivot.rotation = Vector3(0.32 + sin(sp * PI) * 1.35, -0.28, 0.18 + sp * TAU)
	elif is_heavy_wep:
		# Heavy Cleaver / Maul (Raven's Bite, Death Hammer, War Club, Gravity Maw): High-Inertia Windup -> Brutal Cleave -> Impact Tremor
		if combo_idx % 3 == 0:
			heirloom_pivot.position = _sample_vec3_keyframes([[0.0, Vector3(0.04, -0.02, -0.06)], [0.20, Vector3(0.22, 0.22, 0.10)], [0.38, Vector3(-0.28, -0.16, -0.36)], [0.54, Vector3(-0.26, -0.18, -0.32)], [1.0, Vector3(0.04, -0.02, -0.06)]], sp)
			heirloom_pivot.rotation = _sample_vec3_keyframes([[0.0, Vector3(0.32, -0.28, 0.18)], [0.20, Vector3(-0.55, -0.68, -0.45)], [0.38, Vector3(1.55, 1.15, -1.05)], [0.54, Vector3(1.48, 1.05, -0.95)], [1.0, Vector3(0.32, -0.28, 0.18)]], sp)
		elif combo_idx % 3 == 1:
			heirloom_pivot.position = _sample_vec3_keyframes([[0.0, Vector3(0.04, -0.02, -0.06)], [0.18, Vector3(-0.26, 0.04, 0.06)], [0.38, Vector3(0.28, 0.08, -0.34)], [0.52, Vector3(0.24, 0.06, -0.30)], [1.0, Vector3(0.04, -0.02, -0.06)]], sp)
			heirloom_pivot.rotation = _sample_vec3_keyframes([[0.0, Vector3(0.32, -0.28, 0.18)], [0.18, Vector3(0.18, 0.95, 0.85)], [0.38, Vector3(0.65, -1.45, 1.15)], [0.52, Vector3(0.58, -1.30, 0.98)], [1.0, Vector3(0.32, -0.28, 0.18)]], sp)
		else:
			heirloom_pivot.position = _sample_vec3_keyframes([[0.0, Vector3(0.04, -0.02, -0.06)], [0.22, Vector3(0.02, 0.28, 0.08)], [0.40, Vector3(0.0, -0.22, -0.42)], [0.58, Vector3(0.0, -0.24, -0.38)], [1.0, Vector3(0.04, -0.02, -0.06)]], sp)
			heirloom_pivot.rotation = _sample_vec3_keyframes([[0.0, Vector3(0.32, -0.28, 0.18)], [0.22, Vector3(-0.78, 0.0, 0.0)], [0.40, Vector3(1.75, 0.12, -0.15)], [0.58, Vector3(1.68, 0.08, -0.12)], [1.0, Vector3(0.32, -0.28, 0.18)]], sp)
	elif is_dual_or_box:
		# Boxing Gloves / Shock Sticks / Nunchaku Blade: Rapid 1-2 Left-Right Combination Flurry!
		if combo_idx % 3 == 0:
			heirloom_pivot.position = _sample_vec3_keyframes([[0.0, Vector3(0.04, -0.02, -0.06)], [0.14, Vector3(0.18, -0.08, 0.08)], [0.35, Vector3(-0.12, 0.08, -0.48)], [0.48, Vector3(-0.10, 0.06, -0.42)], [1.0, Vector3(0.04, -0.02, -0.06)]], sp)
			heirloom_pivot.rotation = _sample_vec3_keyframes([[0.0, Vector3(0.32, -0.28, 0.18)], [0.14, Vector3(-0.15, -0.55, 0.42)], [0.35, Vector3(1.15, 0.65, -0.78)], [0.48, Vector3(1.05, 0.55, -0.68)], [1.0, Vector3(0.32, -0.28, 0.18)]], sp)
		elif combo_idx % 3 == 1:
			heirloom_pivot.position = _sample_vec3_keyframes([[0.0, Vector3(0.04, -0.02, -0.06)], [0.15, Vector3(0.12, -0.14, -0.02)], [0.36, Vector3(0.08, 0.14, -0.24)], [1.0, Vector3(0.04, -0.02, -0.06)]], sp)
			heirloom_pivot.rotation = _sample_vec3_keyframes([[0.0, Vector3(0.32, -0.28, 0.18)], [0.36, Vector3(0.65, -0.85, 0.95)], [1.0, Vector3(0.32, -0.28, 0.18)]], sp)
		else:
			heirloom_pivot.position = _sample_vec3_keyframes([[0.0, Vector3(0.04, -0.02, -0.06)], [0.16, Vector3(0.06, -0.22, 0.06)], [0.38, Vector3(-0.04, 0.24, -0.46)], [0.52, Vector3(-0.04, 0.22, -0.42)], [1.0, Vector3(0.04, -0.02, -0.06)]], sp)
			heirloom_pivot.rotation = _sample_vec3_keyframes([[0.0, Vector3(0.32, -0.28, 0.18)], [0.16, Vector3(-0.55, -0.25, 0.35)], [0.38, Vector3(1.45, 0.35, -0.45 + sp * TAU)], [1.0, Vector3(0.32, -0.28, 0.18 + TAU)]], sp)
	else:
		# Finesse Blade (Wraith Kunai, Octane Butterfly Knife, Bangalore Kukri): Whip Slash -> Reverse-Grip Spin Cut -> Finger-Ring Twirl Stab!
		if combo_idx % 3 == 0:
			heirloom_pivot.position = _sample_vec3_keyframes([[0.0, Vector3(0.04, -0.02, -0.06)], [0.14, Vector3(0.22, 0.14, 0.06)], [0.35, Vector3(-0.28, -0.08, -0.34)], [0.48, Vector3(-0.26, -0.10, -0.30)], [0.76, Vector3(0.08, 0.06, -0.12)], [1.0, Vector3(0.04, -0.02, -0.06)]], sp)
			heirloom_pivot.rotation = _sample_vec3_keyframes([[0.0, Vector3(0.32, -0.28, 0.18)], [0.14, Vector3(-0.42, -0.85, -0.55)], [0.35, Vector3(1.42, 1.38, -1.25)], [0.48, Vector3(1.35, 1.28, -1.15)], [0.78, Vector3(0.55, -0.45, 0.65)], [1.0, Vector3(0.32, -0.28, 0.18)]], sp)
		elif combo_idx % 3 == 1:
			heirloom_pivot.position = _sample_vec3_keyframes([[0.0, Vector3(0.04, -0.02, -0.06)], [0.15, Vector3(-0.22, -0.12, 0.04)], [0.36, Vector3(0.26, 0.14, -0.32)], [0.48, Vector3(0.24, 0.12, -0.28)], [0.76, Vector3(0.06, 0.08, -0.14)], [1.0, Vector3(0.04, -0.02, -0.06)]], sp)
			heirloom_pivot.rotation = _sample_vec3_keyframes([[0.0, Vector3(0.32, -0.28, 0.18)], [0.15, Vector3(0.55, 0.92, 0.95)], [0.36, Vector3(-0.85, -1.55, 1.38)], [0.50, Vector3(-0.75, -1.35, 1.85)], [0.80, Vector3(0.15, -0.45, 3.85)], [1.0, Vector3(0.32, -0.28, 0.18 + TAU)]], sp)
		else:
			heirloom_pivot.position = _sample_vec3_keyframes([[0.0, Vector3(0.04, -0.02, -0.06)], [0.16, Vector3(0.02, 0.16, 0.10)], [0.36, Vector3(-0.02, 0.04, -0.44)], [0.48, Vector3(-0.02, 0.04, -0.40)], [0.76, Vector3(0.04, 0.12, -0.14)], [1.0, Vector3(0.04, -0.02, -0.06)]], sp)
			heirloom_pivot.rotation = Vector3(0.32 + sin(sp * PI) * 1.48, -0.28 + sin(sp * TAU) * 0.35, 0.18 + sp * TAU)

	if right_arm:
		right_arm.position = (heirloom_pivot.position - Vector3(0.04, -0.02, -0.06)) * 0.78
		right_arm.rotation = Vector3(heirloom_pivot.rotation.x * 0.45, heirloom_pivot.rotation.y * 0.55, clampf(heirloom_pivot.rotation.z, -0.8, 0.8) * 0.45)
	if left_arm:
		if is_dual_or_box and combo_idx % 3 == 1:
			left_arm.position = _sample_vec3_keyframes([[0.0, Vector3(-0.24, -0.13, -0.10)], [0.15, Vector3(-0.32, -0.16, 0.06)], [0.35, Vector3(0.12, 0.06, -0.54)], [0.48, Vector3(0.14, 0.05, -0.50)], [1.0, Vector3(-0.24, -0.13, -0.10)]], sp)
			left_arm.rotation = _sample_vec3_keyframes([[0.0, Vector3.ZERO], [0.15, Vector3(-0.25, -0.45, 0.35)], [0.35, Vector3(0.85, 0.72, -0.58)], [0.48, Vector3(0.78, 0.65, -0.52)], [1.0, Vector3.ZERO]], sp)
		else:
			var l_arc: float = sin(sp * PI)
			left_arm.position = Vector3(-0.24 + l_arc * 0.14, -0.13 + l_arc * 0.16, -0.10 - l_arc * 0.24)
			left_arm.rotation = Vector3(l_arc * 0.52, l_arc * 0.38 * (1.0 if combo_idx % 2 == 0 else -1.0), -l_arc * 0.28)


func _find_melee_lunge_target(enemies_list: Array, max_lunge_dist: float = 4.85) -> ApexBotAI:
	## Authentic Apex Legends Melee Lock-On Target Finder (up to 4.85m when sliding/airborne, 4.45m standing, within 42° cone)
	var origin: Vector3 = player.camera.global_position
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	var best_bot: ApexBotAI = null
	var best_score: float = 999.0
	for bot in enemies_list:
		if not is_instance_valid(bot) or bot.hp <= 0.0:
			continue
		var to_bot: Vector3 = (bot.global_position + Vector3(0, 1.15, 0)) - origin
		var d: float = to_bot.length()
		if d <= max_lunge_dist:
			var ang: float = fwd.angle_to(to_bot.normalized())
			if ang < 0.74:
				var score: float = d + ang * 2.2
				if score < best_score:
					best_score = score
					best_bot = bot
	return best_bot


func _perform_heirloom_slash(enemies_list: Array) -> void:
	if melee_swing_timer > 0.0:
		return
	melee_swing_total = 0.46
	melee_swing_timer = melee_swing_total
	var is_heavy_finisher: bool = (melee_combo_idx % 3 == 2)
	AudioSynthesizer.play_melee_Whoosh(is_heavy_finisher)
	player.add_camera_recoil(0.018 if is_heavy_finisher else 0.010, 0.016 * (1.0 if melee_combo_idx % 2 == 0 else -1.0), 0.018)

	# Phase 1: Start Magnetic Lock-On Step-In / Spacing Lunge (0.0s -> 0.15s)
	var max_range: float = 5.15 if (player.is_sliding or not player.is_on_floor()) else 4.55
	var lunge_bot := _find_melee_lunge_target(enemies_list, max_range)
	if lunge_bot != null:
		player.start_melee_lock_on_lunge(lunge_bot, 0.15)
	else:
		player.start_melee_lock_on_lunge(null, 0.12)
		var fwd: Vector3 = -player.camera.global_transform.basis.z
		player.velocity += Vector3(fwd.x, 0, fwd.z).normalized() * 6.4

	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	var h_info: Dictionary = leg.get("heirloom", {"name": "传家宝近战", "color": Color("#8b5cf6")})

	# Schedule Impact Frame Hit & Rebound Step-Back at MoCap Apex (p = 0.34 / ~0.15s)
	melee_impact_pending = true
	melee_pending_dmg = 75 if is_heavy_finisher else 50
	melee_pending_label = str(h_info.get("name", "传家宝"))
	melee_pending_col = h_info.get("color", Color("#8b5cf6"))
	melee_combo_idx = (melee_combo_idx + 1) % 3
	PlayerState.state_updated.emit()


func start_quick_melee(enemies_list: Array) -> void:
	if quick_melee_timer > 0.0 or melee_swing_timer > 0.0 or reload_timer > 0.0 or PlayerState.heal_cast_timer > 0.0 or player.is_wall_climbing or player.is_mantling:
		return
	if PlayerState.active_slot == 2:
		_perform_heirloom_slash(enemies_list)
		return
	quick_melee_total = 0.46
	quick_melee_timer = quick_melee_total
	if not player.is_on_floor():
		quick_melee_variant = 2 # Airborne Taekwondo Flying Jump-Kick!
	elif player.is_sliding:
		quick_melee_variant = 3 # Sliding Rising Dragon Uppercut!
	else:
		quick_melee_variant = (quick_melee_variant + 1) % 2 # Alternate Brawler Left Hook & Two-Handed Rifle-Butt Smash!

	AudioSynthesizer.play_melee_Whoosh(quick_melee_variant >= 2)
	var max_range: float = 5.15 if (player.is_sliding or not player.is_on_floor()) else 4.50
	var lunge_bot := _find_melee_lunge_target(enemies_list, max_range)
	if lunge_bot != null:
		player.start_melee_lock_on_lunge(lunge_bot, 0.15)
	else:
		player.start_melee_lock_on_lunge(null, 0.12)
		var fwd: Vector3 = -player.camera.global_transform.basis.z
		player.velocity += Vector3(fwd.x, 0.14, fwd.z).normalized() * 7.2

	player.add_camera_recoil(0.022 if quick_melee_variant != 1 else -0.018, -0.018, 0.022)
	var label: String = "腾空飞踢 [V]" if quick_melee_variant == 2 else ("滑铲升龙拳 [V]" if quick_melee_variant == 3 else ("左摆拳重击 [V]" if quick_melee_variant == 0 else "枪托猛砸 [V]"))
	melee_impact_pending = true
	melee_pending_dmg = 40 if quick_melee_variant >= 2 else 35
	melee_pending_label = label
	melee_pending_col = Color("#38bdf8")


func _check_melee_hit(enemies_list: Array, dmg: int, source_label: String, vfx_col: Color = Color("#38bdf8")) -> void:
	var origin: Vector3 = player.camera.global_position
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	var hit_target: ApexBotAI = _find_melee_lunge_target(enemies_list, 4.65)
	if hit_target != null:
		var to_bot: Vector3 = (hit_target.global_position + Vector3(0, 1.15, 0)) - origin
		var ray_res: Dictionary = _cast_ballistic_ray(origin, to_bot.normalized(), to_bot.length() + 0.6, false)
		if ray_res["hit_bot"] == hit_target or not ray_res["hit_wall"]:
			# Phase 2 & 3: 52ms Impact Hitstop + Heavy Enemy Knockback + Attacker Elastic Rebound Step-Back!
			melee_hitstop_timer = 0.052
			player.add_camera_recoil(-0.032, 0.018, 0.036)
			var impact_pt: Vector3 = hit_target.global_position + Vector3(0, 1.25, 0)
			_spawn_charge_impact_burst(impact_pt)
			_spawn_impact_vfx(impact_pt, true, false, vfx_col)
			hit_target.apply_damage(dmg, false, source_label)
			var knock_up: float = 0.48 if (quick_melee_variant >= 2 or melee_combo_idx == 0) else 0.30
			hit_target.velocity += Vector3(fwd.x, knock_up, fwd.z).normalized() * 11.6
			# Trigger Attacker Rebound Step-Back ("命中反震回撤步") so spacing resets cleanly!
			var away_vec: Vector3 = player.global_position - hit_target.global_position
			if Vector2(away_vec.x, away_vec.z).length() < 0.05:
				away_vec = -fwd
			player.trigger_melee_impact_rebound(away_vec, 4.8)


func start_reload() -> void:
	if PlayerState.active_slot == 2 or reload_timer > 0.0 or PlayerState.heal_cast_timer > 0.0 or player.is_wall_climbing or player.is_mantling:
		return
	_cancel_charge_beam()
	burst_shots_remaining = 0
	var slot_idx: int = clampi(PlayerState.active_slot, 0, 1)
	PlayerState.recalculate_weapon_slot(slot_idx, false)
	var slot: Dictionary = PlayerState.loadout[slot_idx]
	var wep: Dictionary = GameData.get_weapon_by_id(slot["weapon_id"])
	var wid: String = str(wep["id"])
	if wid == "bocek":
		return
	if wid == "lstar":
		if lstar_heat <= 0.1:
			return
		lstar_heat = 0.0
		reload_total = 1.85
		reload_timer = reload_total
		reload_step_mask = 0
		return

	if int(slot["ammo"]) >= int(slot["max_ammo"]):
		return
	var ammo_key: String = str(wep["ammo"])
	PlayerState.sync_ammo_reserve_from_inventory()
	if PlayerState.selected_mode_id != "firing_range" and PlayerState.get_reserve_ammo(ammo_key) <= 0:
		PlayerState.toast_pushed.emit("⚠️ 备弹耗尽！背包内无【%s】弹药" % _get_ammo_name(ammo_key), "warn")
		return

	is_empty_reload = (int(slot["ammo"]) <= 0)
	is_segmented_reload = bool(wep.get("segmented_reload", false))
	var stock_tier: int = maxi(int(slot.get("stock", 0)), int(slot.get("stock_tier", 0)))
	var stock_mult: float = 1.0 - float(stock_tier) * 0.07

	if is_segmented_reload:
		reload_total = (0.44 if wid == "mastiff" else 0.38) * stock_mult
	else:
		var base_rel: float = float(wep.get("reload_empty", wep["reload"])) if is_empty_reload else float(wep["reload"])
		reload_total = base_rel * stock_mult
	if PlayerState.stim_timer > 0.0 or PlayerState.double_time_timer > 0.0:
		reload_total *= 0.78
	reload_timer = reload_total
	reload_step_mask = 0
	player.is_ads = false
	BehaviorRecorder.record_event("reload", {"weapon_id": wid})
	PlayerState.state_updated.emit()


func start_inspect() -> void:
	inspect_timer = 3.2
	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	if PlayerState.active_slot == 2:
		PlayerState.toast_pushed.emit("🗡️ 检视传家宝：【%s】" % str(leg["heirloom"]["name"]), "evo")
	else:
		var slot: Dictionary = PlayerState.loadout[PlayerState.active_slot]
		var wep: Dictionary = GameData.get_weapon_by_id(slot["weapon_id"])
		PlayerState.toast_pushed.emit("🔍 360° 检视武器：【%s】" % str(wep["name"]), "info")


func charge_active_weapon() -> void:
	if PlayerState.active_slot == 2:
		return
	var slot: Dictionary = PlayerState.loadout[PlayerState.active_slot]
	var wid: String = str(slot["weapon_id"])
	if wid == "sentinel" or wid == "rampage":
		slot["charged"] = 45.0
		AudioSynthesizer.play_evo_level_up()
		PlayerState.toast_pushed.emit("⚡ 武器已过载充能 45 秒！伤害/射速大幅提升！", "evo")
		PlayerState.state_updated.emit()
	else:
		PlayerState.toast_pushed.emit("🔧 已检查武器配件与射击模式", "info")


func _trigger_muzzle_flash_and_casing(eject_brass: bool = true) -> void:
	if player.viewmodel_holder.get_child_count() == 0:
		return
	var vm: Node3D = player.viewmodel_holder.get_child(0)
	var flash: Node3D = vm.get_node_or_null("GunRig/MuzzleFlashNode")
	if flash:
		flash.visible = true
		flash.rotation.z = randf() * TAU
		get_tree().create_timer(0.055).timeout.connect(func():
			if is_instance_valid(flash):
				flash.visible = false
		)
	if eject_brass and world_root != null and not player.is_third_person:
		_spawn_brass_casing()


func _spawn_brass_casing() -> void:
	var casing := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.005
	cyl.bottom_radius = 0.005
	cyl.height = 0.026
	casing.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#fbbf24")
	mat.metallic = 0.92
	mat.roughness = 0.18
	casing.material_override = mat
	world_root.add_child(casing)
	var cam: Camera3D = player.camera
	var start_p: Vector3 = cam.global_position + (-cam.global_transform.basis.z * 0.42) + (cam.global_transform.basis.x * 0.24) + Vector3(0, -0.14, 0)
	casing.global_position = start_p
	var end_p: Vector3 = start_p + (cam.global_transform.basis.x * randf_range(0.45, 0.75)) + Vector3(0, -0.55, randf_range(-0.2, 0.2))
	var tw := create_tween()
	tw.tween_property(casing, "global_position", end_p, 0.28)
	tw.parallel().tween_property(casing, "rotation", Vector3(randf() * 8.0, randf() * 8.0, randf() * 8.0), 0.28)
	tw.tween_callback(casing.queue_free)


func _spawn_impact_vfx(pt: Vector3, hit_enemy: bool, is_head: bool, col: Color) -> void:
	if world_root == null:
		return
	var spark := CPUParticles3D.new()
	spark.emitting = false
	spark.one_shot = true
	spark.amount = 10 if is_head else 6
	spark.lifetime = 0.22
	spark.explosiveness = 0.95
	var sm := BoxMesh.new()
	sm.size = Vector3(0.028, 0.028, 0.085)
	var mat := StandardMaterial3D.new()
	var scol: Color = Color("#fbbf24") if is_head else (col if hit_enemy else Color("#fcd34d"))
	mat.albedo_color = scol
	mat.emission_enabled = true
	mat.emission = scol
	mat.emission_energy_multiplier = 4.2
	sm.material = mat
	spark.mesh = sm
	spark.direction = Vector3(0, 1, 0)
	spark.spread = 115.0
	spark.initial_velocity_min = 3.5
	spark.initial_velocity_max = 7.8
	spark.gravity = Vector3(0, -16.0, 0)
	world_root.add_child(spark)
	spark.global_position = pt
	spark.emitting = true
	get_tree().create_timer(0.28).timeout.connect(func():
		if is_instance_valid(spark):
			spark.queue_free()
	)


func _spawn_dropped_mag() -> void:
	if world_root == null or player == null:
		return
	var mag_drop := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.055, 0.18, 0.085)
	mag_drop.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#1e293b")
	mag_drop.material_override = mat
	world_root.add_child(mag_drop)
	mag_drop.global_position = player.camera.global_position + (-player.camera.global_transform.basis.z * 0.45) + Vector3(0, -0.25, 0)
	var tw := create_tween()
	tw.tween_property(mag_drop, "global_position:y", player.global_position.y + 0.08, 0.45)
	tw.parallel().tween_property(mag_drop, "rotation", Vector3(1.5, 0.8, 1.2), 0.45)
	tw.tween_interval(3.0)
	tw.tween_callback(mag_drop.queue_free)


func _spawn_bullet_tracer(p_from: Vector3, p_to: Vector3, col: Color, radius: float = 0.013) -> void:
	if world_root == null:
		return
	var dist: float = p_from.distance_to(p_to)
	if dist < 0.5:
		return
	var tracer := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = dist
	tracer.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.8
	tracer.material_override = mat
	world_root.add_child(tracer)
	tracer.global_position = (p_from + p_to) * 0.5
	var dir: Vector3 = (p_to - p_from).normalized()
	var up_v: Vector3 = Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	tracer.look_at(p_to, up_v)
	tracer.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	get_tree().create_timer(0.065).timeout.connect(func():
		if is_instance_valid(tracer):
			tracer.queue_free()
	)


func _spawn_melee_slash_wave(_col: Color) -> void:
	pass


func _update_charge_rifle(delta: float) -> void:
	if player == null or world_root == null:
		return
	charge_timer += delta

	var cam: Camera3D = player.camera
	var origin: Vector3 = cam.global_position
	var fwd: Vector3 = -cam.global_transform.basis.z

	var hit_info: Dictionary = _cast_ballistic_ray(origin, fwd, 280.0, false, 340.0, 0.0)
	var target_pos: Vector3 = hit_info["hit_pos"]
	var hit_bot: ApexBotAI = hit_info["hit_bot"]
	var was_head: bool = hit_info["was_head"]

	var muzzle_pos: Vector3 = origin + fwd * 0.72 + Vector3(0, -0.09, 0)

	if charge_timer < 0.70:
		AudioSynthesizer.play_charge_rifle_charge(charge_timer / 0.70)
		kick_offset += Vector3(randf_range(-0.0016, 0.0016), randf_range(-0.0016, 0.0016), 0.0)
		player.add_camera_recoil(0.001, randf_range(-0.0015, 0.0015), 0.002)

		if charge_timer - charge_last_tick >= 0.14:
			charge_last_tick = charge_timer
			if hit_bot != null:
				var tick_dmg: int = 8 if was_head else 5
				hit_bot.apply_damage(tick_dmg, was_head, "充能步枪 滋")
				_spawn_charge_impact_sparks(target_pos, Color("#ff6600"))
				PlayerState.state_updated.emit()

		_update_charge_beam_mesh(muzzle_pos, target_pos, false)

	elif not charge_beng_fired:
		charge_beng_fired = true
		last_fire_ms = Time.get_ticks_msec()
		var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
		slot["ammo"] = maxi(0, int(slot["ammo"]) - 2)

		AudioSynthesizer.play_charge_rifle_blast()

		player.add_camera_recoil(0.056, randf_range(-0.008, 0.008), 0.038)
		kick_offset = Vector3(0, 0.045, 0.16)
		kick_rot = Vector3(0.095, randf_range(-0.02, 0.02), 0.0)
		bolt_back_offset = 0.14
		_trigger_muzzle_flash_and_casing(false)

		_update_charge_beam_mesh(muzzle_pos, target_pos, true)
		_spawn_charge_impact_burst(target_pos)

		if hit_bot != null:
			var blast_dmg: int = 128 if was_head else 82
			hit_bot.apply_damage(blast_dmg, was_head, "充能步枪 崩💥")

		PlayerState.state_updated.emit()

	if charge_timer >= 0.88:
		_cancel_charge_beam()
		var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
		if int(slot["ammo"]) <= 0:
			start_reload()


func _update_charge_beam_mesh(p_from: Vector3, p_to: Vector3, is_blast: bool) -> void:
	if world_root == null:
		return
	if charge_beam_mesh == null:
		charge_beam_mesh = MeshInstance3D.new()
		charge_beam_mesh.name = "ChargeLaserBeam"
		var init_cyl := CylinderMesh.new()
		init_cyl.radial_segments = 12
		charge_beam_mesh.mesh = init_cyl
		var init_mat := StandardMaterial3D.new()
		init_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		init_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		init_mat.emission_enabled = true
		charge_beam_mesh.material_override = init_mat
		world_root.add_child(charge_beam_mesh)

	var dist: float = p_from.distance_to(p_to)
	var cyl: CylinderMesh = charge_beam_mesh.mesh as CylinderMesh
	var mat: StandardMaterial3D = charge_beam_mesh.material_override as StandardMaterial3D

	if is_blast:
		cyl.top_radius = 0.055
		cyl.bottom_radius = 0.055
		mat.albedo_color = Color(1.0, 0.92, 0.65, 0.95)
		mat.emission = Color("#ff6600")
		mat.emission_energy_multiplier = 6.5
	else:
		cyl.top_radius = 0.016
		cyl.bottom_radius = 0.016
		mat.albedo_color = Color(1.0, 0.55, 0.1, 0.85)
		mat.emission = Color("#ff5500")
		mat.emission_energy_multiplier = 4.0

	cyl.height = dist
	charge_beam_mesh.global_position = (p_from + p_to) * 0.5
	var dir: Vector3 = (p_to - p_from).normalized()
	var up_v: Vector3 = Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	charge_beam_mesh.look_at(p_to, up_v)
	charge_beam_mesh.rotate_object_local(Vector3.RIGHT, PI * 0.5)


func _cancel_charge_beam() -> void:
	is_charging_beam = false
	charge_timer = 0.0
	charge_beng_fired = false
	if is_instance_valid(charge_beam_mesh):
		charge_beam_mesh.queue_free()
		charge_beam_mesh = null


func _spawn_charge_impact_burst(pt: Vector3) -> void:
	if world_root == null:
		return
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.45
	torus.outer_radius = 0.65
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.1, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color("#ff6600")
	mat.emission_energy_multiplier = 5.0
	ring.material_override = mat
	ring.global_position = pt
	world_root.add_child(ring)

	var tw := create_tween()
	tw.tween_property(ring, "scale", Vector3(2.4, 2.4, 2.4), 0.22)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.22)
	tw.tween_callback(ring.queue_free)


func _spawn_charge_impact_sparks(pt: Vector3, col: Color) -> void:
	if world_root == null:
		return
	var spk := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.045
	sp.height = 0.09
	spk.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 4.0
	spk.material_override = mat
	spk.global_position = pt
	world_root.add_child(spk)
	var tw := create_tween()
	tw.tween_property(spk, "scale", Vector3.ZERO, 0.10)
	tw.tween_callback(spk.queue_free)


func _get_ammo_name(ammo_key: String) -> String:
	match ammo_key:
		"light": return "轻型子弹"
		"heavy": return "重型子弹"
		"energy": return "能量子弹"
		"shotgun": return "霰弹枪弹药"
		"sniper": return "狙击枪子弹"
		"arrows": return "箭矢"
		"mythic": return "神话专属弹药"
		_: return ammo_key
