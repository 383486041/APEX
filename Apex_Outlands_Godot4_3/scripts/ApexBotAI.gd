class_name ApexBotAI
extends CharacterBody3D
## Autonomous Smart AI Legend Bot / Firing Range Combat Dummy for Godot 4.3.
## Upgrades:
## 1. Eliminates Frantic Sideways Crab-Panning (`修复AI像平移且疯狂左右移动`):
##    - Replaces frame-by-frame random strafe flipping with committed Tactical Maneuver Windows (`1.8s–3.2s` duration),
##      diagonal sprint advances (`35°–55°`), natural weight-transfer acceleration/deceleration, and steady ADS footing while firing bursts!
##    - Computes `move_angle_local` (angle between facing and velocity vector) and passes it to `LegendRigBuilder.animate_rig()`
##      so the bot's hips and legs turn naturally toward its running direction while its upper torso aims at the player!
## 2. Autonomous AI Wall-Climbing (`AI自动爬墙登高`):
##    - When an AI bot encounters a climbable wall or crate while advancing/repositioning, it enters `bot_wall_climbing`
##      and scales the obstacle with the authentic 3rd-person climbing animation!
## 3. Player-Identical Weapon & Consumable Rules:
##    - Equips real weapons from `GameData.WEAPONS`, obeys magazine capacity & reload time, and holsters weapon onto back when healing.

var bot_name: String = "敌方传奇"
var legend_data: Dictionary = {}
var bot_weapon_id: String = "r301"
var hp: float = 100.0
var max_hp: float = 100.0
var shield: float = 75.0
var max_shield: float = 75.0
var evo_level: int = 2
var spawn_origin: Vector3 = Vector3.ZERO
var strafe_phase: float = 0.0
var strafe_dir: float = 1.0
var ai_mode: String = "strafe" # "static", "strafe", "combat"
var ai_state: String = "STRAFE_DUEL"
var active_heal_type: String = "shield_battery"
var scanned_timer: float = 0.0
var heal_timer: float = 0.0
var fire_cooldown: float = 1.2
var crouch_timer: float = 0.0
var combat_slide_timer: float = 0.0
var hit_flinch: float = 0.0
var storm_tick_timer: float = 0.0
var storm_slide_timer: float = 0.0
var is_sliding: bool = false
var aim_pitch: float = 0.0

# Committed Tactical Locomotion State (Prevents frantic sideways twitching!)
var maneuver_timer: float = 0.0
var maneuver_style: String = "DIAGONAL_ADVANCE" # "DIAGONAL_ADVANCE", "WIDE_FLANK", "ANCHOR_PACE", "ADS_HOLD"
var forward_bias: float = 0.45 # +1.0 = advancing diagonal, -0.5 = retreating diagonal, 0.0 = wide arc
var burst_aim_timer: float = 0.0
var bot_wall_climbing: bool = false
var bot_climb_timer: float = 0.0
var bot_climb_phase: float = 0.0
var was_on_floor_bot: bool = true
var bot_land_timer: float = 0.0

# Authentic Weapon Magazine & Reload State
var bot_ammo: int = 28
var bot_max_ammo: int = 28
var bot_reload_timer: float = 0.0
var bot_batteries_left: int = 2
var bot_syringes_left: int = 2

# Cumulative Damage Combo Tracking
var combo_damage: int = 0
var combo_hits: int = 0
var last_hit_ms: int = 0

var rig_node: Node3D
var status_lbl: Label3D
var scan_beacon: MeshInstance3D
var heal_fx_mesh: MeshInstance3D
var is_dying: bool = false
var death_collapse_timer: float = 0.0
var dying_weapon_name: String = ""
var squad_id: int = 1

var _cached_player: PlayerController = null
var _los_timer: float = 0.0
var _cached_has_los: bool = false
var _anim_lod_timer: float = 0.0

func _ready() -> void:
	collision_layer = 4
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

func setup(leg: Dictionary, pos: Vector3, title: String, evo_lv: int = 2, sq_id: int = 1) -> void:
	legend_data = leg
	bot_name = title
	evo_level = evo_lv
	squad_id = sq_id
	var tier: Dictionary = GameData.get_evo_tier(evo_lv)
	max_shield = float(tier["max_shield"])
	shield = max_shield
	spawn_origin = pos
	position = pos
	strafe_phase = randf() * TAU
	strafe_dir = 1.0 if randf() > 0.5 else -1.0
	maneuver_timer = randf_range(1.8, 3.0)
	if PlayerState.selected_mode_id != "firing_range":
		ai_mode = "combat"

	var bot_weps := ["r301", "flatline", "volt", "peacekeeper", "hemlok", "car", "prowler", "spitfire"]
	bot_weapon_id = bot_weps[absi(title.hash()) % bot_weps.size()]
	bot_max_ammo = GameData.get_weapon_mag_capacity(bot_weapon_id, 2)
	bot_ammo = bot_max_ammo

	rig_node = LegendRigBuilder.create_legend_rig(leg, bot_weapon_id)
	add_child(rig_node)

	status_lbl = Label3D.new()
	status_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status_lbl.no_depth_test = false
	status_lbl.font_size = 28
	status_lbl.pixel_size = 0.0042
	status_lbl.position = Vector3(0, 2.68, 0)
	add_child(status_lbl)

	scan_beacon = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.52
	cyl.bottom_radius = 0.52
	cyl.height = 2.1
	scan_beacon.mesh = cyl
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(1.0, 0.15, 0.15, 0.35)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.no_depth_test = true
	smat.emission_enabled = true
	smat.emission = Color("#ef4444")
	smat.emission_energy_multiplier = 2.8
	scan_beacon.material_override = smat
	scan_beacon.position = Vector3(0, 1.05, 0)
	scan_beacon.visible = false
	add_child(scan_beacon)

	heal_fx_mesh = MeshInstance3D.new()
	var h_torus := TorusMesh.new()
	h_torus.inner_radius = 0.62
	h_torus.outer_radius = 0.72
	heal_fx_mesh.mesh = h_torus
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.22, 0.74, 0.98, 0.75)
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.emission_enabled = true
	hmat.emission = Color("#38bdf8")
	hmat.emission_energy_multiplier = 3.2
	heal_fx_mesh.material_override = hmat
	heal_fx_mesh.position = Vector3(0, 1.1, 0)
	heal_fx_mesh.visible = false
	add_child(heal_fx_mesh)

	_update_overhead_label()

func set_scanned(duration: float) -> void:
	scanned_timer = maxf(scanned_timer, duration)
	if scan_beacon:
		scan_beacon.visible = true
	if status_lbl:
		status_lbl.no_depth_test = true

func _update_overhead_label() -> void:
	if status_lbl == null:
		return
	var tier: Dictionary = GameData.get_evo_tier(evo_level)
	var state_tag: String = ""
	if ai_state == "ESCAPE_STORM":
		state_tag = " [🏃跑毒进圈中...]"
	elif ai_state == "SEEK_COVER_HEAL":
		state_tag = " [⚡使用电池中...]" if active_heal_type == "shield_battery" else " [💉打药恢复中...]"
	elif bot_reload_timer > 0.0:
		state_tag = " [🔄换弹中...]"
	status_lbl.text = "%s%s\n[护盾 %d | 生命 %d]" % [bot_name, state_tag, int(shield), int(hp)]
	status_lbl.modulate = Color("#ef4444") if scanned_timer > 0.0 else tier["color"]

func _has_line_of_sight_to_player(player_node: Node3D) -> bool:
	if player_node == null or get_world_3d() == null or get_world_3d().direct_space_state == null:
		return true
	var from_pt: Vector3 = global_position + Vector3(0, 1.52, 0)
	var to_pt: Vector3 = player_node.global_position + Vector3(0, 1.35, 0)
	var q := PhysicsRayQueryParameters3D.create(from_pt, to_pt, 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty()

func _is_wall_in_direction(dir_world: Vector3, check_dist: float = 2.0) -> bool:
	if get_world_3d() == null or get_world_3d().direct_space_state == null:
		return false
	var from_pt: Vector3 = global_position + Vector3(0, 0.95, 0)
	var to_pt: Vector3 = from_pt + Vector3(dir_world.x, 0, dir_world.z).normalized() * check_dist
	var q := PhysicsRayQueryParameters3D.create(from_pt, to_pt, 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	return not hit.is_empty()

func _physics_process(delta: float) -> void:
	if is_dying:
		death_collapse_timer += delta
		_animate_rig_limbs(delta, false, false)
		if death_collapse_timer >= 0.38:
			is_dying = false
			visible = false
			PlayerState.deathbox_spawn_requested.emit(global_position, bot_name, evo_level, dying_weapon_name)
			if PlayerState.selected_mode_id == "firing_range" or PlayerState.selected_mode_id == "mixtape_tdm":
				await get_tree().create_timer(3.0).timeout
				hp = max_hp
				shield = max_shield
				bot_ammo = bot_max_ammo
				bot_batteries_left = 2
				bot_syringes_left = 2
				combo_damage = 0
				ai_state = "STRAFE_DUEL"
				global_position = spawn_origin
				velocity = Vector3.ZERO
				visible = true
				if status_lbl:
					status_lbl.visible = true
				_update_overhead_label()
			else:
				var parent_scene: Node = get_parent()
				var squad_wiped: bool = true
				if parent_scene and "enemies" in parent_scene:
					for other in parent_scene.enemies:
						if other != self and is_instance_valid(other) and other.visible and other.hp > 0.0:
							if "squad_id" in other and other.squad_id == squad_id:
								squad_wiped = false
								break

				PlayerState.players_alive = maxi(3, PlayerState.players_alive - 1)
				if squad_wiped:
					PlayerState.squads_alive = maxi(1, PlayerState.squads_alive - 1)
					if dying_weapon_name == "毒圈辐射":
						PlayerState.toast_pushed.emit("⭕ 一支敌方小队在毒圈辐射中全军覆没！", "warn")
						PlayerState.killfeed_pushed.emit("✦ 敌方小队已被毒圈淘汰！", Color("#94a3b8"))
					else:
						PlayerState.toast_pushed.emit("⚡ 敌方小队已被全灭！ SQUAD WIPED!", "evo")
						PlayerState.killfeed_pushed.emit("✦ 你消灭了整支小队！", Color("#fbbf24"))
					AudioSynthesizer.play_shield_crack()
				else:
					PlayerState.squads_alive = maxi(1, int(ceil(float(PlayerState.players_alive) / 3.0)))
				PlayerState.state_updated.emit()
		return

	if hp <= 0.0:
		return

	if scanned_timer > 0.0:
		scanned_timer -= delta
		if scanned_timer <= 0.0:
			if scan_beacon:
				scan_beacon.visible = false
			if status_lbl:
				status_lbl.no_depth_test = false
			_update_overhead_label()

	if hit_flinch > 0.0:
		hit_flinch = maxf(0.0, hit_flinch - delta * 5.0)
	if burst_aim_timer > 0.0:
		burst_aim_timer = maxf(0.0, burst_aim_timer - delta)
	if bot_land_timer > 0.0:
		bot_land_timer = maxf(0.0, bot_land_timer - delta)

	if is_on_floor() and not was_on_floor_bot and velocity.y < -3.0:
		bot_land_timer = 0.22
	was_on_floor_bot = is_on_floor()

	if not is_on_floor() and not bot_wall_climbing:
		velocity.y -= 24.5 * delta
	elif is_on_floor() and velocity.y < 0.0:
		velocity.y = -0.5

	var dist_from_center: float = Vector2(global_position.x, global_position.z).length()
	var cur_ring_r: float = PlayerState.ring_radius
	var is_outside_ring: bool = (dist_from_center > cur_ring_r)
	var is_near_storm_edge: bool = (dist_from_center > cur_ring_r - 20.0)

	if PlayerState.selected_mode_id != "firing_range":
		if is_outside_ring:
			storm_tick_timer -= delta
			if storm_tick_timer <= 0.0:
				storm_tick_timer = 1.0
				var r_stage: int = maxi(1, PlayerState.ring_stage)
				var ring_dmg: float = 3.5 + float(r_stage) * 2.5
				apply_storm_damage(ring_dmg)
				if hp <= 0.0 or is_dying:
					return
		else:
			storm_tick_timer = 0.5

		if (is_outside_ring or is_near_storm_edge) and ai_state != "SEEK_COVER_HEAL":
			if ai_state != "ESCAPE_STORM":
				ai_state = "ESCAPE_STORM"
				_update_overhead_label()
		elif ai_state == "ESCAPE_STORM" and dist_from_center < cur_ring_r - 35.0:
			ai_state = "STRAFE_DUEL"
			spawn_origin = global_position
			_update_overhead_label()

	if not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player") as PlayerController
		if _cached_player == null and get_parent():
			for c in get_parent().get_children():
				if c is PlayerController:
					_cached_player = c
					break
	var player_node: PlayerController = _cached_player

	var dist_to_player: float = 999.0
	var has_los: bool = false
	if player_node != null:
		dist_to_player = global_position.distance_to(player_node.global_position)
		_los_timer -= delta
		if _los_timer <= 0.0:
			_los_timer = randf_range(0.10, 0.18)
			_cached_has_los = _has_line_of_sight_to_player(player_node)
		has_los = _cached_has_los
		var dy: float = (player_node.global_position.y + 1.35) - (global_position.y + 1.45)
		aim_pitch = clampf(atan2(dy, maxf(1.0, dist_to_player)), -0.65, 0.65)

	var is_moving: bool = false
	var is_crouching: bool = false
	var desired_vel_xz := Vector3.ZERO

	if bot_reload_timer > 0.0:
		bot_reload_timer -= delta
		if bot_reload_timer <= 0.0:
			bot_reload_timer = 0.0
			bot_ammo = bot_max_ammo
			_update_overhead_label()

	if ai_mode != "static":
		var horiz_spd_now: float = Vector2(velocity.x, velocity.z).length()
		strafe_phase += delta * clampf(horiz_spd_now * 0.42, 1.8, 4.8)

		var wants_heal: bool = (shield <= 25.0 and hp < 85.0 and (bot_batteries_left > 0 or bot_syringes_left > 0))
		if wants_heal and ai_state != "SEEK_COVER_HEAL" and ai_state != "ESCAPE_STORM" and randf() < 0.035:
			ai_state = "SEEK_COVER_HEAL"
			if shield <= 0.0 and bot_batteries_left > 0:
				active_heal_type = "shield_battery"
				heal_timer = 5.0
				bot_batteries_left -= 1
			elif hp < 65.0 and bot_syringes_left > 0:
				active_heal_type = "syringe"
				heal_timer = 5.0
				bot_syringes_left -= 1
			else:
				active_heal_type = "shield_cell"
				heal_timer = 3.0
			heal_fx_mesh.visible = true
			_update_overhead_label()

		if ai_state == "SEEK_COVER_HEAL":
			is_crouching = true
			is_moving = true
			is_sliding = false
			bot_wall_climbing = false
			heal_timer -= delta
			heal_fx_mesh.position.y = 0.6 + sin(strafe_phase * 2.0) * 0.45

			var retreat_dir: Vector3 = (global_transform.basis.z * 0.55 + global_transform.basis.x * strafe_dir * 0.85).normalized()
			if _is_wall_in_direction(retreat_dir, 2.2) or is_on_wall():
				strafe_dir = -strafe_dir
				retreat_dir = (global_transform.basis.z * 0.55 + global_transform.basis.x * strafe_dir * 0.85).normalized()
			desired_vel_xz = retreat_dir * 4.8

			if heal_timer <= 0.0:
				if active_heal_type == "shield_battery":
					shield = max_shield
				elif active_heal_type == "syringe":
					hp = minf(max_hp, hp + 25.0)
				else:
					shield = minf(max_shield, shield + 25.0)
				ai_state = "STRAFE_DUEL"
				heal_fx_mesh.visible = false
				AudioSynthesizer.play_consumable_complete(active_heal_type)
				_update_overhead_label()
		elif ai_state == "ESCAPE_STORM":
			is_moving = true
			var to_center := Vector3(-global_position.x, 0.0, -global_position.z)
			var safe_dir := to_center.normalized() if to_center.length() > 0.1 else Vector3.FORWARD

			var squad_jitter: float = sin(strafe_phase * 0.35 + float(squad_id) * 1.5) * 0.18
			var run_dir: Vector3 = (safe_dir + global_transform.basis.x * squad_jitter).normalized()

			if _is_wall_in_direction(run_dir, 3.2) or is_on_wall():
				var left_steer := run_dir.rotated(Vector3.UP, 0.75)
				var right_steer := run_dir.rotated(Vector3.UP, -0.75)
				if not _is_wall_in_direction(left_steer, 2.8):
					run_dir = left_steer
				elif not _is_wall_in_direction(right_steer, 2.8):
					run_dir = right_steer
				else:
					run_dir = safe_dir.rotated(Vector3.UP, 1.4 * strafe_dir)

			var run_speed: float = 12.8
			storm_slide_timer += delta
			if storm_slide_timer > 3.6:
				if storm_slide_timer < 4.4:
					is_sliding = true
					is_crouching = true
					run_speed = 16.5
				else:
					is_sliding = false
					storm_slide_timer = 0.0
			else:
				is_sliding = false

			desired_vel_xz = run_dir * run_speed

			var forward_target := global_position + run_dir * 6.0
			if global_position.distance_to(forward_target) > 0.5:
				look_at(forward_target, Vector3.UP)
		else:
			# =================================================================
			# COMMITTED TACTICAL LOCOMOTION (Fixes frantic sideways crab-panning!)
			# =================================================================
			is_moving = true
			maneuver_timer -= delta
			if maneuver_timer <= 0.0:
				maneuver_timer = randf_range(1.9, 3.2)
				strafe_dir = -strafe_dir
				if ai_mode == "combat":
					var r_pick: float = randf()
					if r_pick < 0.42:
						maneuver_style = "DIAGONAL_ADVANCE"
						forward_bias = 0.58 if dist_to_player > 16.0 else -0.35
					elif r_pick < 0.78:
						maneuver_style = "WIDE_FLANK"
						forward_bias = 0.32
					else:
						maneuver_style = "ANCHOR_PACE"
						forward_bias = 0.18
				else:
					maneuver_style = "ANCHOR_PACE"
					forward_bias = 0.28 * sin(strafe_phase * 0.5)

			if combat_slide_timer > 0.0:
				combat_slide_timer -= delta
				is_sliding = true
				is_crouching = true
			else:
				is_sliding = false
				if is_on_floor() and ai_mode == "combat" and maneuver_style == "DIAGONAL_ADVANCE" and randf() < 0.003:
					combat_slide_timer = 0.68
					is_sliding = true
					is_crouching = true

			if not is_sliding:
				if crouch_timer > 0.0:
					crouch_timer -= delta
					is_crouching = true
				elif ai_mode == "combat" and burst_aim_timer <= 0.0 and randf() < 0.006:
					crouch_timer = 0.52

			# Face player smoothly, or angle 25% toward movement vector when sprinting in WIDE_FLANK
			var fwd_to_player: Vector3 = -global_transform.basis.z
			if player_node != null:
				var to_p := Vector3(player_node.global_position.x - global_position.x, 0.0, player_node.global_position.z - global_position.z)
				if to_p.length() > 0.6:
					fwd_to_player = to_p.normalized()
					var target_yaw: float = atan2(-fwd_to_player.x, -fwd_to_player.z)
					rotation.y = lerp_angle(rotation.y, target_yaw, delta * 8.5)

			var right_vec: Vector3 = global_transform.basis.x * strafe_dir
			var fwd_vec: Vector3 = -global_transform.basis.z * forward_bias

			# Keep bot near its patrol/spawn anchor in Firing Range so it doesn't wander off the platform
			var to_spawn: Vector3 = spawn_origin - global_position
			to_spawn.y = 0.0
			var max_roam: float = 7.5 if ai_mode == "strafe" else 16.0
			if to_spawn.length() > max_roam:
				fwd_vec = to_spawn.normalized() * 0.75

			var move_dir: Vector3 = (right_vec * 0.82 + fwd_vec * 0.58).normalized()

			# Check if wall is ahead: either Wall-Climb over it (if combat advancing) or smoothly reverse maneuver!
			if _is_wall_in_direction(move_dir, 1.65) or is_on_wall():
				if ai_mode == "combat" and bot_climb_timer < 0.95 and forward_bias > 0.0:
					bot_wall_climbing = true
					bot_climb_timer += delta
					bot_climb_phase += delta * 11.0
					velocity.y = 7.8
				else:
					bot_wall_climbing = false
					if maneuver_timer < 1.4:
						strafe_dir = -strafe_dir
						maneuver_timer = randf_range(1.8, 2.8)
					move_dir = -move_dir
			else:
				bot_wall_climbing = false
				if is_on_floor():
					bot_climb_timer = 0.0

			# Smooth speed profile: steady ADS pace (`5.2 m/s`) while firing bursts, athletic run (`8.4 m/s`) when flanking!
			var move_spd: float = 15.8 if is_sliding else (5.2 if burst_aim_timer > 0.0 else (6.0 if is_crouching else (6.8 if ai_mode == "strafe" else 8.6)))
			# Smooth turn-around ease when maneuver_timer is near switching
			var turn_ease: float = clampf(minf(maneuver_timer, 2.5 - maneuver_timer) * 3.5, 0.45, 1.0)
			desired_vel_xz = move_dir * (move_spd * turn_ease)

			if ai_mode == "combat" and player_node != null and dist_to_player < 68.0 and has_los and bot_reload_timer <= 0.0 and not player_node.in_dropship and not player_node.is_skydiving:
				fire_cooldown -= delta
				if fire_cooldown <= 0.0:
					if bot_ammo <= 0:
						var wep_d: Dictionary = GameData.get_weapon_by_id(bot_weapon_id)
						bot_reload_timer = float(wep_d.get("reload", 2.3))
						_update_overhead_label()
					else:
						fire_cooldown = randf_range(1.15, 1.95)
						burst_aim_timer = 0.55
						_fire_burst_at_player(player_node)

	velocity.x = lerpf(velocity.x, desired_vel_xz.x, delta * 8.5)
	velocity.z = lerpf(velocity.z, desired_vel_xz.z, delta * 8.5)
	move_and_slide()

	var should_animate: bool = true
	if dist_to_player > 55.0:
		_anim_lod_timer += delta
		if _anim_lod_timer < 0.08:
			should_animate = false
		else:
			_anim_lod_timer = 0.0
	elif dist_to_player > 28.0:
		_anim_lod_timer += delta
		if _anim_lod_timer < 0.04:
			should_animate = false
		else:
			_anim_lod_timer = 0.0

	if should_animate:
		_animate_rig_limbs(delta, is_moving and Vector2(velocity.x, velocity.z).length() > 0.5, is_crouching)

func _animate_rig_limbs(delta: float, is_moving: bool, is_crouching: bool) -> void:
	if rig_node == null:
		return
	# Compute local horizontal movement angle so legs/pelvis align with the bot's actual running direction!
	var local_vel: Vector3 = global_transform.basis.inverse() * Vector3(velocity.x, 0.0, velocity.z)
	var move_angle_local: float = 0.0
	if Vector2(local_vel.x, local_vel.z).length() > 0.45:
		if local_vel.z <= 0.25:
			move_angle_local = clampf(atan2(-local_vel.x, maxf(0.15, -local_vel.z)), -0.78, 0.78)
		else:
			move_angle_local = clampf(atan2(local_vel.x, maxf(0.15, local_vel.z)), -0.68, 0.68)

	var anim_dict := {
		"mode": "death" if is_dying else ("crouch" if is_crouching else ("combat" if is_moving else "idle")),
		"is_moving": is_moving,
		"is_crouching": is_crouching,
		"is_sliding": is_sliding,
		"is_in_air": not is_on_floor() and not is_dying and not bot_wall_climbing,
		"vel_y": velocity.y,
		"land_compress": bot_land_timer / 0.22,
		"is_wall_climbing": bot_wall_climbing,
		"climb_phase": bot_climb_phase,
		"is_healing": (ai_state == "SEEK_COVER_HEAL"),
		"heal_id": active_heal_type,
		"is_reloading": (bot_reload_timer > 0.0),
		"is_firing": (burst_aim_timer > 0.25 and bot_reload_timer <= 0.0),
		"is_ads": (burst_aim_timer > 0.0),
		"aim_pitch": aim_pitch,
		"move_angle_local": move_angle_local,
		"weapon_id": bot_weapon_id,
		"strafe_phase": strafe_phase,
		"strafe_dir": strafe_dir,
		"hit_flinch": hit_flinch,
		"death_time": death_collapse_timer if is_dying else -1.0,
		"speed": velocity.length(),
		"time": Time.get_ticks_msec() / 1000.0
	}
	LegendRigBuilder.animate_rig(rig_node, delta, anim_dict)

func _fire_burst_at_player(player_node: PlayerController) -> void:
	bot_ammo = maxi(0, bot_ammo - 3)
	if bot_ammo <= 0:
		var wep_d: Dictionary = GameData.get_weapon_by_id(bot_weapon_id)
		bot_reload_timer = float(wep_d.get("reload", 2.3))
		_update_overhead_label()

	if rig_node != null:
		var mflash: Node3D = rig_node.find_child("BotMuzzleFlash", true, false)
		if mflash:
			mflash.visible = true
			get_tree().create_timer(0.08).timeout.connect(func():
				if is_instance_valid(mflash):
					mflash.visible = false
			)

	var p_from: Vector3 = global_position + Vector3(0, 1.38, 0)
	var p_to: Vector3 = player_node.global_position + Vector3(randf_range(-0.55, 0.55), 1.2, randf_range(-0.55, 0.55))
	var blocked_by_wall: bool = false
	if get_world_3d() != null and get_world_3d().direct_space_state != null:
		var q := PhysicsRayQueryParameters3D.create(p_from, p_to, 1)
		var wall_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
		if not wall_hit.is_empty():
			p_to = wall_hit["position"]
			blocked_by_wall = true

	if get_parent() != null and p_from.distance_to(p_to) > 0.5:
		var tr := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.015
		cyl.bottom_radius = 0.015
		cyl.height = p_from.distance_to(p_to)
		tr.mesh = cyl
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = Color("#ef4444")
		tmat.emission_enabled = true
		tmat.emission = Color("#ef4444")
		tmat.emission_energy_multiplier = 3.2
		tr.material_override = tmat
		get_parent().add_child(tr)
		tr.global_position = (p_from + p_to) * 0.5
		var dir: Vector3 = (p_to - p_from).normalized()
		var up_v: Vector3 = Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		tr.look_at(p_to, up_v)
		tr.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		get_tree().create_timer(0.075).timeout.connect(func():
			if is_instance_valid(tr):
				tr.queue_free()
		)

	if not blocked_by_wall and PlayerState.void_timer <= 0.0 and randf() < 0.40:
		var dmg: float = 10.0
		if PlayerState.selected_legend_id == "gibraltar" and player_node.is_ads and PlayerState.gun_shield_hp > 0.0:
			PlayerState.gun_shield_hp = maxf(0.0, PlayerState.gun_shield_hp - dmg)
			return
		if PlayerState.shield > 0.0:
			PlayerState.shield = maxf(0.0, PlayerState.shield - dmg)
		else:
			PlayerState.hp = maxf(20.0, PlayerState.hp - dmg)
		PlayerState.state_updated.emit()

func apply_damage(dmg: int, is_headshot: bool, weapon_name: String) -> void:
	if hp <= 0.0:
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - last_hit_ms > 2200:
		combo_damage = 0
		combo_hits = 0
	last_hit_ms = now_ms
	combo_damage += dmg
	combo_hits += 1
	hit_flinch = 1.0

	if ai_state == "SEEK_COVER_HEAL" and dmg >= 25 and heal_fx_mesh:
		ai_state = "STRAFE_DUEL"
		heal_fx_mesh.visible = false

	var had_shield: bool = (shield > 0.0)
	var cracked_now: bool = false
	var rem: float = float(dmg)
	if shield > 0.0:
		var s_dmg: float = minf(shield, rem)
		shield -= s_dmg
		rem -= s_dmg
		if shield <= 0.0:
			cracked_now = true
			AudioSynthesizer.play_shield_crack()
			_spawn_shield_crack_vfx()
			PlayerState.killfeed_pushed.emit("⚡ 击碎了 %s 的 Lv.%d 进化护盾！" % [bot_name, evo_level], GameData.get_evo_tier(evo_level)["color"])
			if GameData.get_legend_by_id(PlayerState.selected_legend_id)["class_id"] == "ASSAULT":
				PlayerState.double_time_timer = 3.5
			if is_on_floor() and ai_mode != "static":
				combat_slide_timer = 0.65
				is_sliding = true
		else:
			AudioSynthesizer.play_armor_hit(evo_level, is_headshot, combo_hits)
	else:
		AudioSynthesizer.play_flesh_hit(is_headshot)

	if rem > 0.0:
		hp = maxf(0.0, hp - rem)

	PlayerState.add_damage_and_evo(dmg)
	var display_tier: int = evo_level if had_shield else 0
	PlayerState.hit_feedback_pushed.emit(bot_name, dmg, combo_damage, is_headshot, display_tier, cracked_now)
	var hit_wpos: Vector3 = global_position + Vector3(0, 1.48, 0)
	PlayerState.floating_damage_spawned.emit(hit_wpos, dmg, is_headshot, display_tier, cracked_now)
	_update_overhead_label()

	if hp <= 0.0:
		AudioSynthesizer.play_kill_confirmed()
		PlayerState.kills += 1
		PlayerState.add_damage_and_evo(100)
		if PlayerState.beast_timer > 0.0:
			PlayerState.beast_timer += 4.0
			PlayerState.hp = minf(PlayerState.max_hp, PlayerState.hp + 40.0)
		var inflicted: int = maxi(100, combo_damage)
		PlayerState.enemy_knocked_down.emit(bot_name, weapon_name, inflicted, 150)
		PlayerState.killfeed_pushed.emit("💀 你使用 [%s] 击倒并淘汰了 %s" % [weapon_name, bot_name], Color("#ff1e42"))
		PlayerState.enemy_eliminated.emit(bot_name, weapon_name, PlayerState.kills)
		is_dying = true
		death_collapse_timer = 0.0
		dying_weapon_name = weapon_name
		if status_lbl:
			status_lbl.visible = false
		if scan_beacon:
			scan_beacon.visible = false
		if heal_fx_mesh:
			heal_fx_mesh.visible = false

func _spawn_shield_crack_vfx() -> void:
	if get_parent() == null:
		return
	var tier: Dictionary = GameData.get_evo_tier(evo_level)
	var burst := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.65
	sp.height = 1.3
	burst.mesh = sp
	var bmat := StandardMaterial3D.new()
	var col: Color = tier["color"]
	bmat.albedo_color = Color(col.r, col.g, col.b, 0.65)
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.emission_enabled = true
	bmat.emission = col
	bmat.emission_energy_multiplier = 4.2
	burst.material_override = bmat
	get_parent().add_child(burst)
	burst.global_position = global_position + Vector3(0, 1.25, 0)
	var tw := create_tween()
	tw.tween_property(burst, "scale", Vector3(2.4, 2.4, 2.4), 0.28)
	tw.parallel().tween_property(bmat, "albedo_color:a", 0.0, 0.28)
	tw.tween_callback(burst.queue_free)

func apply_storm_damage(dmg: float) -> void:
	if hp <= 0.0 or is_dying:
		return
	hp = maxf(0.0, hp - dmg)
	hit_flinch = 0.5
	_update_overhead_label()

	if hp <= 0.0:
		is_dying = true
		death_collapse_timer = 0.0
		dying_weapon_name = "毒圈辐射"
		if status_lbl:
			status_lbl.visible = false
		if scan_beacon:
			scan_beacon.visible = false
		if heal_fx_mesh:
			heal_fx_mesh.visible = false
		PlayerState.killfeed_pushed.emit("💀 %s 倒在毒圈辐射中！" % bot_name, Color("#94a3b8"))
		AudioSynthesizer.play_shield_crack()
