class_name WeaponController
extends Node3D
## Drives First-Person Weapon Ballistics (True 3D Ray-to-Capsule Intersection + Wall Occlusion),
## Authentic Unit-Normalized Shotgun Pellet Patterns (Star-11, Line-8, Fig8-8, Triangle-3) & Precision Choke,
## Shotgun Bolt Fire-Rate & Rechamber Acceleration, 30-30 Repeater ADS Charge, L-STAR Overheat Cooling,
## Bocek Compound Bow Hold-to-Draw & Release Mechanics, Burst-Fire & Energy Windup State Machines,
## Archetype-Specific Choreographed Reloads (AR Tactical, Bullpup Rear Mag, Peacekeeper Lever Flip,
## Segmented Shell-by-Shell Mastiff/30-30, Wingman Swing-Out Cylinder, Sniper Bolt Action),
## Holstered-Weapon Two-Handed First-Person Consumable Animations (Shield Battery Twist & Syringe Injection),
## Quick Melee (V), 3-Stage Heirloom Slash Combos, and Weapon Inspect (N).

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
var bow_draw_progress: float = 0.0 # 0.0 to 1.0 (full draw at 0.52s)
var bow_hold_time: float = 0.0

# Peacekeeper / Triple Take ADS Precision Choke & 30-30 Repeater ADS Charge State
var choke_progress: float = 0.0 # 0.0 to 1.0
var repeater_charge: float = 0.0 # 0.0 to 1.0 (+36% damage at full ADS charge)
var lstar_heat: float = 0.0 # 0.0 to 1.0

# Burst-Fire State Machine (Hemlok 3-burst, Nemesis 4-burst, Prowler 5-burst)
var burst_shots_remaining: int = 0
var burst_next_shot_timer: float = 0.0
var nemesis_energy_charge: float = 0.0 # 0.0 to 1.0 (+32% RPM at full charge)
var devotion_spinup: float = 0.0 # 0.0 to 1.0

# Reload State Machine (Supports Standard Mag, Bullpup, Lever, Revolver, Sniper & Segmented Shell-by-Shell)
var reload_timer: float = 0.0
var reload_total: float = 0.0
var is_empty_reload: bool = false
var is_segmented_reload: bool = false
var reload_step_mask: int = 0 # Bitmask for mag_out(1), mag_in(2), bolt_slap(4)

# Rechamber / Lever-Cock / Pump State (Kraber, Sentinel, Peacekeeper, Mastiff, Longbow)
var rechamber_timer: float = 0.0
var rechamber_total: float = 0.0

# Melee & Inspect State Machine
var quick_melee_timer: float = 0.0
var melee_swing_timer: float = 0.0
var melee_combo_idx: int = 0
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

	# Track smooth rotational weapon sway from mouse look
	var dyaw: float = wrapf(player.yaw - prev_cam_yaw, -PI, PI)
	var dpitch: float = player.pitch - prev_cam_pitch
	prev_cam_yaw = player.yaw
	prev_cam_pitch = player.pitch
	sway_offset = sway_offset.lerp(Vector2(-dyaw * 0.45, dpitch * 0.45).limit_length(0.06), delta * 14.0)

	# Decay consecutive shot counter & L-STAR heat when not firing
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - last_fire_ms > 240:
		consecutive_shots = maxi(0, consecutive_shots - 1)
		devotion_spinup = maxf(0.0, devotion_spinup - delta * 1.4)
		lstar_heat = maxf(0.0, lstar_heat - delta * 0.55)

	nemesis_energy_charge = maxf(0.0, nemesis_energy_charge - delta * 0.08)

	# Cancel active weapon states if player starts healing
	if PlayerState.heal_cast_timer > 0.0:
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
	kick_offset = kick_offset.lerp(Vector3.ZERO, delta * 16.0)
	kick_rot = kick_rot.lerp(Vector3.ZERO, delta * 15.0)
	bolt_back_offset = lerpf(bolt_back_offset, 0.0, delta * 18.0)

	if rechamber_timer > 0.0:
		rechamber_timer = maxf(0.0, rechamber_timer - delta)

	if quick_melee_timer > 0.0:
		quick_melee_timer = maxf(0.0, quick_melee_timer - delta)

	if melee_swing_timer > 0.0:
		melee_swing_timer = maxf(0.0, melee_swing_timer - delta)

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

	# Continue inserting next shell if still below max_ammo and reserves remain
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
	if PlayerState.active_slot == 2 or reload_timer > 0.0 or PlayerState.heal_cast_timer > 0.0:
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

	var cam := player.camera
	var origin: Vector3 = cam.global_position
	var fwd: Vector3 = -cam.global_transform.basis.z
	var spread: float = lerpf(0.016, 0.0008, draw_ratio) * (0.35 if player.is_ads else 1.0)
	var ray_dir: Vector3 = (fwd + cam.global_transform.basis.x * randf_range(-spread, spread) + cam.global_transform.basis.y * randf_range(-spread, spread)).normalized()

	var hit_info: Dictionary = _cast_ballistic_ray(origin, ray_dir, 320.0, false)
	var hit_pos: Vector3 = hit_info["hit_pos"]
	var hit_bot: ApexBotAI = hit_info["hit_bot"]
	var was_head: bool = hit_info["was_head"]

	var base_dmg: int = int(round(lerpf(28.0, float(wep["dmg"]), draw_ratio)))
	if was_head:
		base_dmg = int(round(float(base_dmg) * float(wep["head"])))

	_spawn_bullet_tracer(origin + Vector3(0, -0.06, 0) + fwd * 0.65, hit_pos, Color("#f59e0b"))
	_spawn_embedded_arrow(hit_pos, ray_dir)

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


func _cast_ballistic_ray(origin: Vector3, ray_dir: Vector3, max_dist: float = 340.0, is_shotgun_pellet: bool = false) -> Dictionary:
	## True 3D Physics Raycast + Exact Ray-to-Spine Segment Intersection against Enemy Capsules.
	## Eliminates missed angled shots on head/torso and provides responsive shotgun pellet hit registration!
	var wall_dist: float = max_dist
	var final_pos: Vector3 = origin + ray_dir * max_dist

	# 1. Check Physics World Wall / Obstacle Occlusion First (collision_mask = 1)
	if world_root != null and world_root.get_world_3d() != null:
		var space_state := world_root.get_world_3d().direct_space_state
		if space_state != null:
			var q := PhysicsRayQueryParameters3D.create(origin, final_pos, 1)
			q.collide_with_bodies = true
			var wall_hit: Dictionary = space_state.intersect_ray(q)
			if not wall_hit.is_empty():
				final_pos = wall_hit["position"]
				wall_dist = origin.distance_to(final_pos)

	# 2. Check Ray-to-Enemy Vertical Spine Capsule Intersection before wall_dist
	var best_bot: ApexBotAI = null
	var best_dist: float = wall_dist
	var best_head: bool = false
	var best_hit_pt: Vector3 = final_pos

	for bot in enemies:
		if not is_instance_valid(bot) or bot.hp <= 0.0:
			continue
		var bot_feet: Vector3 = bot.global_position
		var to_mid: Vector3 = (bot_feet + Vector3(0, 1.0, 0)) - origin
		var approx_proj: float = to_mid.dot(ray_dir)
		if approx_proj < 0.4 or approx_proj > best_dist + 1.0:
			continue

		# Compute closest point between the ray (origin + t * ray_dir) and the vertical spine segment (bot_feet.y + [0.15, 1.85])
		# Evaluate ray at several heights or solve closest horizontal approach
		var horiz_ray_len_sq: float = ray_dir.x * ray_dir.x + ray_dir.z * ray_dir.z
		var t_closest: float = approx_proj
		if horiz_ray_len_sq > 0.0001:
			var dx: float = bot_feet.x - origin.x
			var dz: float = bot_feet.z - origin.z
			t_closest = clampf((dx * ray_dir.x + dz * ray_dir.z) / horiz_ray_len_sq, 0.4, best_dist)

		var ray_pt: Vector3 = origin + ray_dir * t_closest
		var rel_y: float = ray_pt.y - bot_feet.y
		if rel_y < -0.10 or rel_y > 2.08:
			continue

		var horiz_dist: float = Vector2(ray_pt.x - bot_feet.x, ray_pt.z - bot_feet.z).length()
		var is_head_zone: bool = (rel_y >= 1.42)
		var base_body_r: float = 0.54 if is_shotgun_pellet else 0.48
		var base_head_r: float = 0.33 if is_shotgun_pellet else 0.30
		var hit_radius: float = base_head_r if is_head_zone else base_body_r

		if horiz_dist <= hit_radius:
			best_dist = t_closest
			best_bot = bot
			best_head = is_head_zone
			best_hit_pt = ray_pt

	return {
		"hit_pos": best_hit_pt,
		"hit_bot": best_bot,
		"was_head": best_head,
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
	var reload_style: String = str(wep_cur.get("reload_style", "ar_tactical"))
	var is_bow: bool = (wid_cur == "bocek" and not is_heirloom)
	var is_healing: bool = (PlayerState.heal_cast_timer > 0.0)

	var sprinting: bool = Input.is_key_pressed(KEY_SHIFT) and not player.is_ads and reload_timer <= 0.0 and not is_drawing_bow and not is_healing and not player.is_sliding
	var base_pos := Vector3(0.0, -0.15, -0.38) if is_healing else (Vector3(0.24, -0.22, -0.46) if is_heirloom else (Vector3(0.22, -0.20, -0.48) if is_bow else Vector3(0.26, -0.22, -0.52)))
	var optic_node: Node3D = gun_rig.get_node_or_null("OpticPivot")
	var cur_op: String = str(slot_cur.get("optic", "2x_bruiser"))

	if player.is_ads and not is_heirloom and reload_timer <= 0.0 and not is_healing:
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
		ammo_housing.visible = (not is_healing) and (not is_heirloom)
	var charm_node: Node3D = gun_rig.get_node_or_null("OmamoriCharm")
	if charm_node:
		charm_node.visible = not player.is_ads and not is_healing

	# Locomotion Figure-8 Bobbing & Dynamic Rotational Sway
	var bob_x: float = cos(player.bob_time * 0.5) * (0.014 if sprinting else 0.006)
	var bob_y: float = absf(sin(player.bob_time)) * (0.018 if sprinting else 0.007)
	if player.is_ads or player.is_sliding:
		bob_x *= 0.16
		bob_y *= 0.16

	var sway_pos := Vector3(sway_offset.x, sway_offset.y, 0.0)
	if player.is_sliding and not is_healing and not player.is_ads:
		base_pos += Vector3(-0.05, -0.03, 0.04)
	vm.position = vm.position.lerp(base_pos + Vector3(bob_x, -bob_y, 0) + kick_offset + sway_pos, delta * 18.0)

	var target_rot := kick_rot + Vector3(sway_offset.y * 1.4, sway_offset.x * 1.8, (-0.24 if is_bow and not player.is_ads else (-0.08 if is_bow else 0.0)))
	if player.is_sliding and not is_healing:
		# Authentic Apex Legends Tactical Canted Slide Posture!
		target_rot += Vector3(0.16, 0.24, -0.46)
	elif sprinting and not is_heirloom:
		target_rot = Vector3(0.24, 0.40, -0.24)

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
	# 0. FIRST-PERSON CONSUMABLE ANIMATION (打药动作 & 使用电池动作 — 完全收起枪械!)
	# =========================================================================
	if is_healing:
		if cons_pivot != null:
			cons_pivot.visible = true
		# Hide ALL weapon receiver/barrel/mag/optic meshes so ONLY hands + battery/syringe are visible!
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
			# Update capacitor core & OmniLight color (Blue for Cell, Cyan for Battery, Violet-Gold for Phoenix)
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

			# Two-handed center-screen Shield Battery posture:
			cons_pivot.position = cons_pivot.position.lerp(Vector3(0.0, 0.02 + sin(hp_prog * TAU * 3.0) * 0.008, -0.06), delta * 15.0)
			cons_pivot.rotation = Vector3(0.24, -0.10, 0.06 + pulse_w * 0.035)
			var twist_top: Node3D = bat_prop.get_node_or_null("BatteryTwistTop")
			if twist_top:
				twist_top.position.y = 0.095 + clampf(hp_prog * 1.35, 0.0, 1.0) * 0.042
				twist_top.rotation.y = hp_prog * TAU * 3.0

			# Left hand wraps tightly around the lower battery housing; Right hand grips & twists top handle bar!
			if left_arm:
				left_arm.position = left_arm.position.lerp(Vector3(-0.055, -0.055, -0.06), delta * 15.0)
				left_arm.rotation = left_arm.rotation.lerp(Vector3(0.38, 0.42, -0.24), delta * 15.0)
			if right_arm:
				right_arm.position = right_arm.position.lerp(Vector3(0.052, 0.115 + clampf(hp_prog * 1.35, 0.0, 1.0) * 0.032, -0.055), delta * 15.0)
				right_arm.rotation = right_arm.rotation.lerp(Vector3(0.62, -0.45, 0.32 + pulse_w * 0.14), delta * 15.0)
			target_rot = Vector3.ZERO
		elif med_prop != null and cons_pivot != null:
			# Two-handed Syringe / MedKit Pneumatic Auto-Injector Animation!
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
			if child.name != "ConsumablePivot" and child.name != "MuzzleFlashNode":
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
	# 2. ARCHETYPE-SPECIFIC CHOREOGRAPHED RELOAD ANIMATIONS
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

	if reload_timer > 0.0 and not is_heirloom:
		var p: float = 1.0 - clampf(reload_timer / maxf(0.01, reload_total), 0.0, 1.0)
		if is_segmented_reload:
			# Mastiff & 30-30 Repeater: Shell-by-shell thumb insertion into loading gate
			var sh_wave: float = sin(p * PI)
			target_rot = Vector3(0.24, 0.28, 0.54)
			if mag_pivot:
				mag_pivot.position = base_mag_pos + Vector3(0, -0.04 * (1.0 - sh_wave), 0.03 * sh_wave)
			if left_arm:
				left_arm.position = Vector3(-0.02, -0.15 + sh_wave * 0.11, -0.05)
				left_arm.rotation = Vector3(0.42 * sh_wave, 0.28, -0.18)
		elif reload_style == "revolver_swing" or wid_cur == "wingman":
			# Wingman Revolver: Swing cylinder out to left -> dump brass -> insert speedloader -> wrist flick close!
			if p < 0.28:
				var t1: float = p / 0.28
				target_rot = Vector3(0.38 * t1, -0.18 * t1, -0.35 * t1)
				if mag_pivot:
					mag_pivot.position = base_mag_pos + Vector3(-0.046 * t1, -0.01 * t1, 0)
					mag_pivot.rotation.z = 0.92 * t1
				if left_arm:
					left_arm.position = Vector3(-0.06, -0.04 - 0.12 * t1, -0.04)
			elif p < 0.72:
				var t2: float = (p - 0.28) / 0.44
				var ins: float = sin(t2 * PI)
				target_rot = Vector3(0.28, 0.15, 0.42)
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
				target_rot = Vector3(-0.15 * flick, 0.22 * flick, -0.68 * flick)
				if mag_pivot:
					mag_pivot.position = base_mag_pos.lerp(base_mag_pos + Vector3(-0.046, 0, 0), 1.0 - t3)
					mag_pivot.rotation.z = lerpf(0.92, 0.0, t3)
					mag_pivot.rotation.y = 0.0
				if left_arm:
					left_arm.position = Vector3(-0.055, -0.045, -0.14)
		elif reload_style == "lever_shotgun" and wid_cur == "peacekeeper":
			# Peacekeeper: Side-chamber energy cell swap + 360-degree lever-action flip cock!
			if p < 0.64:
				var tc: float = p / 0.64
				var cell_arc: float = sin(tc * PI)
				target_rot = Vector3(0.22, 0.24, 0.56)
				if mag_pivot:
					mag_pivot.position = base_mag_pos + Vector3(-0.14 * cell_arc, -0.12 * cell_arc, 0)
				if left_arm:
					left_arm.position = Vector3(-0.05 - 0.10 * cell_arc, -0.06 - 0.12 * cell_arc, -0.08)
					left_arm.rotation = Vector3(0.35 * cell_arc, 0.40, -0.25)
			else:
				var tl: float = (p - 0.64) / 0.36
				var flip_wave: float = sin(tl * PI)
				target_rot = Vector3(0.45 * flip_wave, -0.15 * flip_wave, -0.28 * flip_wave)
				if mag_pivot:
					mag_pivot.position = base_mag_pos
				if bolt_pivot:
					bolt_pivot.rotation.x = tl * TAU
				if left_arm:
					left_arm.position = Vector3(-0.055, -0.045, -0.18)
		else:
			# Standard AR / SMG / LMG / Bullpup / Sniper 3-Stage Choreographed Reload
			if p < 0.32:
				var t1: float = p / 0.32
				target_rot = Vector3(0.28 * t1, (-0.24 if is_bullpup else 0.18) * t1, 0.54 * t1)
				if mag_pivot:
					mag_pivot.position = base_mag_pos + Vector3(0, -t1 * 0.28, 0)
					mag_pivot.rotation.x = t1 * 0.62
				if left_arm:
					left_arm.position = Vector3(-0.04, -0.14 - t1 * 0.18, base_mag_pos.z)
					left_arm.rotation = Vector3(0.25 * t1, 0.20, -0.25 * t1)
			elif p < 0.68:
				var t2: float = (p - 0.32) / 0.36
				var snap_t: float = clampf(t2 * 1.25, 0.0, 1.0)
				target_rot = Vector3(0.28, -0.24 if is_bullpup else 0.18, 0.54)
				if mag_pivot:
					mag_pivot.position = Vector3(base_mag_pos.x, lerpf(base_mag_pos.y - 0.28, base_mag_pos.y, snap_t), base_mag_pos.z)
					mag_pivot.rotation.x = lerpf(0.52, 0.0, snap_t)
				if left_arm:
					left_arm.position = Vector3(-0.02, lerpf(-0.34, -0.12, snap_t), base_mag_pos.z)
					left_arm.rotation = Vector3(0.28 * (1.0 - snap_t), 0.25, -0.15)
			else:
				var t3: float = (p - 0.68) / 0.32
				var pull: float = sin(t3 * PI)
				target_rot = Vector3(0.12 * (1.0 - t3), -0.24 * pull, -0.42 * pull)
				if mag_pivot:
					mag_pivot.position = base_mag_pos
					mag_pivot.rotation = Vector3.ZERO
				if bolt_pivot:
					bolt_pivot.position.z = -0.04 + pull * 0.12
					if reload_style == "bolt_sniper":
						bolt_pivot.rotation.z = -pull * 0.85
				if left_arm:
					left_arm.position = Vector3(-0.05, 0.02 * pull - 0.04, -0.08 + pull * 0.11)
					left_arm.rotation = Vector3(0.32 * pull, 0.22 * pull, 0.0)
	elif not is_bow:
		if mag_pivot:
			mag_pivot.position = mag_pivot.position.lerp(base_mag_pos, delta * 16.0)
			mag_pivot.rotation = mag_pivot.rotation.lerp(Vector3.ZERO, delta * 16.0)
		if bolt_pivot:
			if rechamber_timer > 0.0:
				var rp: float = 1.0 - (rechamber_timer / maxf(0.01, rechamber_total))
				var r_wave: float = sin(rp * PI)
				if wid_cur == "peacekeeper" or wid_cur == "repeater3030":
					bolt_pivot.rotation.x = r_wave * 1.15
					target_rot.x += r_wave * 0.28
					target_rot.z -= r_wave * 0.18
				elif wid_cur == "mastiff":
					bolt_pivot.position.z = -0.22 + r_wave * 0.11
					if left_arm:
						left_arm.position.z = -0.18 + r_wave * 0.11
				else:
					bolt_pivot.position.z = -0.04 + r_wave * 0.13
					bolt_pivot.rotation.z = -r_wave * 0.90
					target_rot.z += r_wave * 0.24
			else:
				var base_bolt_z: float = -0.22 if wid_cur == "mastiff" else (0.06 if (wid_cur == "peacekeeper" or wid_cur == "repeater3030") else -0.04)
				bolt_pivot.position.z = base_bolt_z + bolt_back_offset
				bolt_pivot.rotation = bolt_pivot.rotation.lerp(Vector3.ZERO, delta * 16.0)
		if left_arm and not is_heirloom:
			var target_la_pos := Vector3(-0.055, -0.045, -0.18)
			var target_la_rot := Vector3.ZERO
			if player.is_sliding:
				target_la_pos = Vector3(-0.095, -0.09, -0.14)
				target_la_rot = Vector3(0.22, 0.18, -0.35)
			left_arm.position = left_arm.position.lerp(target_la_pos, delta * 14.0)
			left_arm.rotation = left_arm.rotation.lerp(target_la_rot, delta * 14.0)
		if right_arm and not is_heirloom:
			var rec_len_cur: float = float(wep_cur.get("rec_len", 0.48))
			right_arm.position = right_arm.position.lerp(Vector3(0.02, -0.10, rec_len_cur * 0.22), delta * 14.0)
			right_arm.rotation = right_arm.rotation.lerp(Vector3.ZERO, delta * 14.0)

	# =========================================================================
	# 3. QUICK MELEE STRIKE ANIMATION (V Key)
	# =========================================================================
	if quick_melee_timer > 0.0:
		var mp: float = 1.0 - (quick_melee_timer / 0.42)
		var thrust: float = sin(mp * PI)
		vm.position += Vector3(0.08 * thrust, -0.06 * thrust, -0.18 * thrust)
		target_rot += Vector3(0.25 * thrust, -0.55 * thrust, 0.35 * thrust)
		if left_arm:
			left_arm.position = Vector3(-0.08 + 0.22 * thrust, 0.04 * thrust, -0.18 - 0.38 * thrust)
			left_arm.rotation = Vector3(0.55 * thrust, 0.45 * thrust, -0.35 * thrust)

	# =========================================================================
	# 4. HEIRLOOM 3-STAGE SLASH COMBO & WEAPON INSPECT
	# =========================================================================
	if is_heirloom and heirloom_pivot:
		if melee_swing_timer > 0.0:
			var sp: float = 1.0 - (melee_swing_timer / 0.40)
			var arc: float = sin(sp * PI)
			if melee_combo_idx == 0:
				heirloom_pivot.rotation = Vector3(0.32 + arc * 1.25, -0.28 + arc * 1.55, 0.18 - arc * 1.2)
				heirloom_pivot.position = Vector3(0.04 - arc * 0.28, -0.02 + arc * 0.08, -0.06 - arc * 0.28)
				if right_arm:
					right_arm.position = Vector3(-arc * 0.22, arc * 0.08, -arc * 0.22)
					right_arm.rotation = Vector3(arc * 0.45, arc * 0.85, -arc * 0.55)
				if left_arm:
					left_arm.position = Vector3(-0.24 - arc * 0.10, -0.13 + arc * 0.12, -0.10 - arc * 0.18)
					left_arm.rotation = Vector3(arc * 0.40, -arc * 0.45, arc * 0.30)
			elif melee_combo_idx == 1:
				heirloom_pivot.rotation = Vector3(0.32 - arc * 1.15, -0.28 - arc * 1.6, 0.18 + arc * 1.3)
				heirloom_pivot.position = Vector3(0.04 + arc * 0.24, -0.02 + arc * 0.14, -0.06 - arc * 0.26)
				if right_arm:
					right_arm.position = Vector3(arc * 0.20, arc * 0.12, -arc * 0.20)
					right_arm.rotation = Vector3(-arc * 0.35, -arc * 0.85, arc * 0.65)
				if left_arm:
					left_arm.position = Vector3(-0.24 + arc * 0.28, -0.13 + arc * 0.22, -0.10 - arc * 0.36)
					left_arm.rotation = Vector3(arc * 0.65, arc * 0.55, -arc * 0.40)
			else:
				heirloom_pivot.rotation = Vector3(0.32 + arc * 1.5, -0.28, 0.18 + sp * TAU)
				heirloom_pivot.position = Vector3(0.0, 0.06 * arc, -0.06 - arc * 0.36)
				if right_arm:
					right_arm.position = Vector3(-0.04 * arc, 0.08 * arc, -0.28 * arc)
					right_arm.rotation = Vector3(arc * 0.55, 0, sp * TAU * 0.25)
				if left_arm:
					left_arm.position = Vector3(-0.22 + arc * 0.16, -0.08 + arc * 0.18, -0.10 - arc * 0.28)
					left_arm.rotation = Vector3(arc * 0.50, arc * 0.35, 0)
		else:
			if right_arm:
				right_arm.position = right_arm.position.lerp(Vector3.ZERO, delta * 12.0)
				right_arm.rotation = right_arm.rotation.lerp(Vector3.ZERO, delta * 12.0)
			if left_arm:
				left_arm.position = left_arm.position.lerp(Vector3(-0.24, -0.13, -0.10), delta * 12.0)
				left_arm.rotation = left_arm.rotation.lerp(Vector3(0, 0, sin(player.bob_time * 0.5) * 0.08), delta * 12.0)
			if inspect_timer > 0.0 or sprinting:
				var spin_t: float = float(Time.get_ticks_msec()) * 0.012
				heirloom_pivot.rotation = Vector3(spin_t, -0.25, 0.35)
			else:
				heirloom_pivot.rotation = heirloom_pivot.rotation.lerp(Vector3(0.32, -0.28, 0.18), delta * 12.0)
				heirloom_pivot.position = heirloom_pivot.position.lerp(Vector3(0.04, -0.02, -0.06), delta * 12.0)
	elif inspect_timer > 0.0:
		var ip: float = 1.0 - (inspect_timer / 3.2)
		target_rot.y += sin(ip * TAU) * 0.68
		target_rot.z += sin(ip * PI) * 0.42
		target_rot.x += 0.18 * sin(ip * PI)

	gun_rig.rotation = gun_rig.rotation.lerp(target_rot, delta * 16.0)


func try_fire(enemies_list: Array) -> void:
	if player == null or rechamber_timer > 0.0 or quick_melee_timer > 0.0 or PlayerState.heal_cast_timer > 0.0:
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

	# L-STAR EMG draws directly from energy reserve or mag with overheat protection
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


func _execute_single_shot(enemies_list: Array, is_burst_followup: bool = false) -> void:
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
		var ammo_cost: int = 1
		slot["ammo"] = maxi(0, int(slot["ammo"]) - ammo_cost)

	last_fire_ms = Time.get_ticks_msec()
	consecutive_shots += 1
	if wid == "devotion":
		devotion_spinup = clampf(devotion_spinup + 0.14, 0.0, 1.0)
	elif wid == "nemesis":
		nemesis_energy_charge = clampf(nemesis_energy_charge + 0.09, 0.0, 1.0)

	AudioSynthesizer.play_gunshot(cat, wid)

	# Barrel stabilizer attachment reduces recoil kick
	var barrel_tier: int = int(slot.get("barrel", 0))
	var rec_mult: float = 1.0 - float(barrel_tier) * 0.08

	kick_offset = Vector3(0, 0.012, 0.052 if cat != "SHOTGUN" else 0.080) * rec_mult
	kick_rot = Vector3(0.062 if cat != "SHOTGUN" else 0.105, randf_range(-0.016, 0.016), 0.0) * rec_mult
	bolt_back_offset = 0.095
	var v_rec: float = (0.030 if cat == "SNIPER" else (0.024 if cat == "SHOTGUN" else 0.009)) * rec_mult
	var h_pat: float = sin(float(consecutive_shots) * 0.65) * 0.004 * rec_mult
	player.add_camera_recoil(v_rec, h_pat, 0.012)

	_trigger_muzzle_flash_and_casing()

	# Rechamber / Lever-Action / Pump-Action Timing (Accelerated by Shotgun Bolt on Peacekeeper & Mastiff!)
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
	var cam := player.camera
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

		var hit_res: Dictionary = _cast_ballistic_ray(origin, ray_dir, 340.0, pellets > 1)
		var p_pos: Vector3 = hit_res["hit_pos"]
		var p_bot: ApexBotAI = hit_res["hit_bot"]
		var p_head: bool = hit_res["was_head"]

		if p_bot != null:
			pellet_hit_flags.append(true)
			var d: int = int(wep["dmg"])
			if wid == "repeater3030" and repeater_charge > 0.05:
				d = int(round(lerpf(float(d), float(wep.get("max_charge_dmg", 60)), repeater_charge)))
			elif wid == "sentinel" and float(slot.get("charged", 0.0)) > 0.0:
				d = int(wep.get("amped_dmg", 92))
			elif wid == "r301" and player.is_ads and str(slot.get("hopup", "")) == "anvil":
				d = int(round(float(d) * 1.15))
			# Hammerpoint Rounds bonus against unshielded flesh (Mozambique, P2020, RE-45, EVA-8)
			if (wid == "mozambique" or wid == "p2020" or wid == "re45") and p_bot.shield <= 0.0:
				d = int(round(float(d) * 1.35))
			if p_head:
				d = int(round(float(d) * float(wep["head"])))
				was_head = true
			total_hit_dmg += d
			hit_bot = p_bot
		else:
			pellet_hit_flags.append(false)

		if pellets <= 3 or p % 2 == 0 or p_bot != null:
			_spawn_bullet_tracer(origin + Vector3(0, -0.08, 0) + fwd * 0.72, p_pos, wep.get("accent", Color("#f97316")))

	if wid == "repeater3030":
		repeater_charge = 0.0

	if pellets > 1:
		PlayerState.shotgun_pellet_feedback_pushed.emit(pattern_name, pellet_hit_flags, was_head)

	if hit_bot != null and total_hit_dmg > 0:
		hit_bot.apply_damage(total_hit_dmg, was_head, str(wep["name"]))

	if not is_burst_followup:
		BehaviorRecorder.record_event("fire_weapon", {"weapon_id": wid, "cat": cat, "ads": player.is_ads, "hit": hit_bot != null, "dmg": total_hit_dmg})

	PlayerState.state_updated.emit()


func _perform_heirloom_slash(enemies_list: Array) -> void:
	if melee_swing_timer > 0.0:
		return
	melee_swing_timer = 0.40
	var is_heavy_finisher: bool = (melee_combo_idx == 2)
	AudioSynthesizer.play_melee_Whoosh(is_heavy_finisher)
	player.add_camera_recoil(0.018 if is_heavy_finisher else 0.008, 0.015 * (1.0 if melee_combo_idx % 2 == 0 else -1.0), 0.02)

	var fwd: Vector3 = -player.camera.global_transform.basis.z
	player.velocity += Vector3(fwd.x, 0, fwd.z).normalized() * 5.2

	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	var h_info: Dictionary = leg.get("heirloom", {"name": "传家宝近战", "color": Color("#8b5cf6")})
	_spawn_melee_slash_wave(h_info.get("color", Color("#8b5cf6")))

	var dmg: int = 75 if is_heavy_finisher else 50
	_check_melee_hit(enemies_list, dmg, str(h_info.get("name", "传家宝")))
	melee_combo_idx = (melee_combo_idx + 1) % 3
	PlayerState.state_updated.emit()


func start_quick_melee(enemies_list: Array) -> void:
	if quick_melee_timer > 0.0 or reload_timer > 0.0 or PlayerState.heal_cast_timer > 0.0:
		return
	quick_melee_timer = 0.42
	AudioSynthesizer.play_melee_Whoosh(false)
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	player.velocity += Vector3(fwd.x, 0.12, fwd.z).normalized() * 6.2
	player.add_camera_recoil(0.015, -0.015, 0.02)
	_check_melee_hit(enemies_list, 35, "近战重击 [V]")


func _check_melee_hit(enemies_list: Array, dmg: int, source_label: String) -> void:
	var origin: Vector3 = player.camera.global_position
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	for bot in enemies_list:
		if not is_instance_valid(bot) or bot.hp <= 0.0:
			continue
		var to_bot: Vector3 = (bot.global_position + Vector3(0, 1.1, 0)) - origin
		if to_bot.length() <= 4.2 and fwd.angle_to(to_bot.normalized()) < 0.65:
			var ray_res: Dictionary = _cast_ballistic_ray(origin, to_bot.normalized(), to_bot.length() + 0.5, false)
			if ray_res["hit_bot"] == bot or not ray_res["hit_wall"]:
				bot.apply_damage(dmg, false, source_label)
				bot.velocity += Vector3(fwd.x, 0.25, fwd.z).normalized() * 8.5
				break


func start_reload() -> void:
	if PlayerState.active_slot == 2 or reload_timer > 0.0 or PlayerState.heal_cast_timer > 0.0:
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
		reload_total = float(wep["reload"]) * (1.0 if is_empty_reload else 0.82) * stock_mult
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


func _trigger_muzzle_flash_and_casing() -> void:
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


func _spawn_bullet_tracer(p_from: Vector3, p_to: Vector3, col: Color) -> void:
	if world_root == null:
		return
	var dist: float = p_from.distance_to(p_to)
	if dist < 0.5:
		return
	var tracer := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.013
	cyl.bottom_radius = 0.013
	cyl.height = dist
	tracer.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.5
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


func _spawn_melee_slash_wave(col: Color) -> void:
	if world_root == null or player == null:
		return
	var wave := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.68
	wave.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.2
	wave.material_override = mat
	world_root.add_child(wave)
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	wave.global_position = player.camera.global_position + fwd * 1.35
	wave.rotation = player.camera.global_rotation + Vector3(0, 0, randf_range(-0.5, 0.5))
	var tw := create_tween()
	tw.tween_property(wave, "global_position", wave.global_position + fwd * 2.4, 0.22)
	tw.parallel().tween_property(wave, "scale", Vector3(1.6, 1.6, 1.6), 0.22)
	tw.tween_callback(wave.queue_free)


func _update_charge_rifle(delta: float) -> void:
	if player == null or world_root == null:
		return
	charge_timer += delta

	var cam := player.camera
	var origin: Vector3 = cam.global_position
	var fwd: Vector3 = -cam.global_transform.basis.z

	var hit_info: Dictionary = _cast_ballistic_ray(origin, fwd, 280.0, false)
	var target_pos: Vector3 = hit_info["hit_pos"]
	var hit_bot: ApexBotAI = hit_info["hit_bot"]
	var was_head: bool = hit_info["was_head"]

	var muzzle_pos: Vector3 = origin + fwd * 0.72 + Vector3(0, -0.09, 0)

	# Phase 1: "滋" tracking laser beam (0.0s to 0.70s)
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

	# Phase 2: "崩" colossal explosive plasma blast (at 0.70s)
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
		_trigger_muzzle_flash_and_casing()

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
		var cyl := CylinderMesh.new()
		cyl.radial_segments = 12
		charge_beam_mesh.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		charge_beam_mesh.material_override = mat
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
