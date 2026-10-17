class_name ApexBotAI
extends CharacterBody3D
## Autonomous Smart AI Legend Bot / Firing Range Combat Dummy for Godot 4.3.
## Fixes & Upgrades:
## 1. Zero Wall-Phasing (`自动穿墙修复`): Adds true CapsuleShape3D physics collision (`collision_layer = 4`, `collision_mask = 1`),
##    gravity (`24.5 m/s²`), `move_and_slide()`, and 3D raycast wall-avoidance steering so AI NEVER walks through walls, rocks, or crates!
## 2. Strictly Player-Identical Performance Limits (`不能出现超出人物性能以外的行为`):
##    - Movement speed strictly bounded by player speeds (`base_speed = 9.5`, `crouch = 6.2`, `heal_walk = 5.2`, `ads_strafe = 6.8`).
##    - Obeys authentic weapon magazine capacity (`24` rounds) and reload time (`2.4s`), and cannot fire while reloading or healing.
##    - Obeys authentic Consumable cast times (`5.0s` for Shield Battery, `3.0s` for Shield Cell, `5.0s` for Syringe) with 3D held battery/syringe animation.
##    - Requires unobstructed 3D Physics Raycast Line-of-Sight (`_has_line_of_sight_to_player`) before shooting!
## 3. Player Behavior Imitation Learning (`BehaviorRecorder` integration):
##    - Dynamically adapts strafe frequency, crouch-weave ratio, jump-peek timing, and cover/heal thresholds from recorded player trajectories!

var bot_name: String = "敌方传奇"
var legend_data: Dictionary = {}
var hp: float = 100.0
var max_hp: float = 100.0
var shield: float = 75.0
var max_shield: float = 75.0
var evo_level: int = 2
var spawn_origin: Vector3 = Vector3.ZERO
var strafe_phase: float = 0.0
var strafe_dir: float = 1.0
var ai_mode: String = "strafe" # "static", "strafe", "combat"
var ai_state: String = "STRAFE_DUEL" # "STRAFE_DUEL", "SEEK_COVER_HEAL", "RELOADING", "AGGRESSIVE_PUSH"
var active_heal_type: String = "shield_battery"
var scanned_timer: float = 0.0
var heal_timer: float = 0.0
var fire_cooldown: float = 1.2
var crouch_timer: float = 0.0
var hit_flinch: float = 0.0

# Authentic Weapon Magazine & Reload State (Matches Player Performance)
var bot_ammo: int = 24
var bot_max_ammo: int = 24
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

func _ready() -> void:
	# Add true CapsuleShape3D collision matching PlayerController so AI obeys physics & walls!
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
	if PlayerState.selected_mode_id != "firing_range":
		ai_mode = "combat"

	rig_node = LegendRigBuilder.create_legend_rig(leg)
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
	if ai_state == "SEEK_COVER_HEAL":
		state_tag = " [⚡使用电池中...]" if active_heal_type == "shield_battery" else " [💉打药恢复中...]"
	elif bot_reload_timer > 0.0:
		state_tag = " [🔄换弹中...]"
	status_lbl.text = "%s%s\n[护盾 %d | 生命 %d]" % [bot_name, state_tag, int(shield), int(hp)]
	status_lbl.modulate = Color("#ef4444") if scanned_timer > 0.0 else tier["color"]

func _has_line_of_sight_to_player(player_node: Node3D) -> bool:
	## Checks 3D physics world (collision_mask = 1) so AI NEVER sees or shoots through walls!
	if player_node == null or get_world_3d() == null or get_world_3d().direct_space_state == null:
		return true
	var from_pt: Vector3 = global_position + Vector3(0, 1.52, 0)
	var to_pt: Vector3 = player_node.global_position + Vector3(0, 1.35, 0)
	var q := PhysicsRayQueryParameters3D.create(from_pt, to_pt, 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty()

func _is_wall_in_direction(dir_world: Vector3, check_dist: float = 2.0) -> bool:
	## Checks if a wall or obstacle is blocking the desired movement direction.
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
				await get_tree().create_timer(3.2).timeout
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

	# Apply authentic gravity identical to PlayerController (24.5 m/s^2)
	if not is_on_floor():
		velocity.y -= 24.5 * delta
	elif velocity.y < 0.0:
		velocity.y = -0.5

	# Locate Player node
	var player_node: PlayerController = null
	if get_parent():
		for c in get_parent().get_children():
			if c is PlayerController:
				player_node = c
				break

	var dist_to_player: float = 999.0
	var has_los: bool = false
	if player_node != null:
		dist_to_player = global_position.distance_to(player_node.global_position)
		has_los = _has_line_of_sight_to_player(player_node)
		var look_pt := Vector3(player_node.global_position.x, global_position.y, player_node.global_position.z)
		if global_position.distance_to(look_pt) > 0.5:
			look_at(look_pt, Vector3.UP)

	var is_moving: bool = false
	var is_crouching: bool = false
	var desired_vel_xz := Vector3.ZERO

	# Tick AI Weapon Reload (strictly obeys player 2.4s reload time!)
	if bot_reload_timer > 0.0:
		bot_reload_timer -= delta
		if bot_reload_timer <= 0.0:
			bot_reload_timer = 0.0
			bot_ammo = bot_max_ammo
			_update_overhead_label()

	if ai_mode != "static":
		var policy: Dictionary = BehaviorRecorder.learned_policy
		var strafe_freq: float = float(policy.get("strafe_frequency", 2.2))
		var crouch_prob: float = float(policy.get("crouch_weave_prob", 0.28))
		var jump_prob: float = float(policy.get("jump_peek_prob", 0.08))
		var heal_thresh: float = float(policy.get("heal_shield_threshold", 25.0))

		strafe_phase += delta * (2.6 + strafe_freq * 0.55)

		# Query Player Behavior Imitation Policy if enabled
		var imit: Dictionary = BehaviorRecorder.query_imitation_action(dist_to_player, hp, shield, float(bot_ammo) / float(bot_max_ammo))
		var use_imit: bool = not imit.is_empty()

		# Smart AI State Transitions: Trigger Shield Battery (5.0s) or Syringe (5.0s) when low
		var wants_heal: bool = (shield <= heal_thresh and hp < 85.0 and (bot_batteries_left > 0 or bot_syringes_left > 0))
		if use_imit and bool(imit.get("heal", false)) and (shield < max_shield * 0.5 or hp < 75.0):
			wants_heal = true

		if wants_heal and ai_state != "SEEK_COVER_HEAL" and randf() < 0.035:
			ai_state = "SEEK_COVER_HEAL"
			if shield <= 0.0 and bot_batteries_left > 0:
				active_heal_type = "shield_battery"
				heal_timer = 5.0 # Authentic 5.0s Shield Battery cast time!
				bot_batteries_left -= 1
			elif hp < 65.0 and bot_syringes_left > 0:
				active_heal_type = "syringe"
				heal_timer = 5.0 # Authentic 5.0s Syringe cast time!
				bot_syringes_left -= 1
			else:
				active_heal_type = "shield_cell"
				heal_timer = 3.0 # Authentic 3.0s Shield Cell cast time!
			heal_fx_mesh.visible = true
			_update_overhead_label()

		if ai_state == "SEEK_COVER_HEAL":
			is_crouching = true
			is_moving = true
			heal_timer -= delta
			heal_fx_mesh.position.y = 0.6 + sin(strafe_phase * 2.0) * 0.45

			# Move laterally at player-identical healing walk speed (5.2 m/s max) while avoiding walls
			var right_dir: Vector3 = global_transform.basis.x * strafe_dir
			if _is_wall_in_direction(right_dir, 2.0) or is_on_wall():
				strafe_dir = -strafe_dir
				right_dir = -right_dir
			desired_vel_xz = right_dir * 4.8

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
		else:
			is_moving = true
			# Strafe reversal on timer, imitation policy, or wall detection
			if use_imit and absf(float(imit.get("move_x", 0.0))) > 0.2:
				strafe_dir = signf(float(imit["move_x"]))
			elif randf() < 0.025:
				strafe_dir = -strafe_dir

			# Crouch-weaving like real Apex players
			if use_imit:
				if bool(imit.get("crouch", false)) and crouch_timer <= 0.0:
					crouch_timer = 0.48
			elif randf() < (0.012 + crouch_prob * 0.03) and crouch_timer <= 0.0:
				crouch_timer = 0.55

			if crouch_timer > 0.0:
				crouch_timer -= delta
				is_crouching = true

			# Jump-peek on floor (bounded by player jump_velocity = 11.2)
			if is_on_floor() and ((use_imit and bool(imit.get("jump", false))) or randf() < jump_prob * 0.008):
				velocity.y = 11.2

			# Compute lateral + forward/back velocity strictly within player speed limits (6.8 m/s ADS strafe, 6.2 m/s crouch)
			var move_spd: float = 6.2 if is_crouching else 6.85
			var lat_vec: Vector3 = global_transform.basis.x * strafe_dir
			if _is_wall_in_direction(lat_vec, 2.2) or is_on_wall():
				strafe_dir = -strafe_dir
				lat_vec = -lat_vec

			# Keep near spawn_origin in firing range, or maintain optimal combat distance in BR
			var to_spawn: Vector3 = spawn_origin - global_position
			to_spawn.y = 0.0
			var anchor_pull: Vector3 = to_spawn.normalized() * clampf(to_spawn.length() * 0.35, 0.0, 2.5)
			desired_vel_xz = (lat_vec + anchor_pull * 0.35).normalized() * move_spd

			# AI Combat Shooting at Player (Only when Line-of-Sight is clear, not reloading, and not healing!)
			if ai_mode == "combat" and player_node != null and dist_to_player < 68.0 and has_los and bot_reload_timer <= 0.0 and not player_node.in_dropship and not player_node.is_skydiving:
				fire_cooldown -= delta
				if fire_cooldown <= 0.0:
					if bot_ammo <= 0:
						bot_reload_timer = 2.4
						_update_overhead_label()
					else:
						fire_cooldown = randf_range(1.10, 1.95)
						_fire_burst_at_player(player_node)

	# Smoothly accelerate horizontal velocity and call move_and_slide() so AI respects all walls & floors!
	velocity.x = lerpf(velocity.x, desired_vel_xz.x, delta * 10.0)
	velocity.z = lerpf(velocity.z, desired_vel_xz.z, delta * 10.0)
	move_and_slide()

	_animate_rig_limbs(delta, is_moving and velocity.length() > 0.5, is_crouching)

func _animate_rig_limbs(delta: float, is_moving: bool, is_crouching: bool) -> void:
	if rig_node == null:
		return
	var anim_dict := {
		"mode": "death" if is_dying else ("crouch" if is_crouching else ("combat" if is_moving else "idle")),
		"is_moving": is_moving,
		"is_crouching": is_crouching,
		"is_in_air": not is_on_floor() and not is_dying,
		"is_healing": (ai_state == "SEEK_COVER_HEAL"),
		"heal_id": active_heal_type,
		"is_reloading": (bot_reload_timer > 0.0),
		"is_firing": (fire_cooldown > 0.0 and fire_cooldown < 0.20 and bot_reload_timer <= 0.0),
		"strafe_phase": strafe_phase,
		"strafe_dir": strafe_dir,
		"hit_flinch": hit_flinch,
		"death_time": death_collapse_timer if is_dying else -1.0,
		"speed": velocity.length(),
		"time": Time.get_ticks_msec() / 1000.0
	}
	LegendRigBuilder.animate_rig(rig_node, delta, anim_dict)

func _fire_burst_at_player(player_node: PlayerController) -> void:
	# Consume 3 rounds per burst and trigger reload if empty
	bot_ammo = maxi(0, bot_ammo - 3)
	if bot_ammo <= 0:
		bot_reload_timer = 2.4
		_update_overhead_label()

	if rig_node != null:
		var mflash: Node3D = rig_node.find_child("BotMuzzleFlash", true, false)
		if mflash:
			mflash.visible = true
			get_tree().create_timer(0.08).timeout.connect(func():
				if is_instance_valid(mflash):
					mflash.visible = false
			)

	# Verify line-of-sight and stop tracer at walls if occluded
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

	# Apply damage ONLY if not blocked by a wall and player is not in Void Phase
	if not blocked_by_wall and PlayerState.void_timer <= 0.0 and randf() < 0.40:
		var dmg: float = 9.0
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
	if now_ms - last_hit_ms > 1650:
		combo_damage = 0
		combo_hits = 0
	last_hit_ms = now_ms
	combo_damage += dmg
	combo_hits += 1
	hit_flinch = 1.0

	# Interrupt AI healing if hit for heavy damage
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
		else:
			AudioSynthesizer.play_armor_hit(evo_level, is_headshot, combo_hits)
	else:
		AudioSynthesizer.play_flesh_hit(is_headshot)

	if rem > 0.0:
		hp = maxf(0.0, hp - rem)

	PlayerState.add_damage_and_evo(dmg)
	var display_tier: int = evo_level if had_shield else 0
	PlayerState.hit_feedback_pushed.emit(bot_name, dmg, combo_damage, is_headshot, display_tier, cracked_now)
	var hit_wpos: Vector3 = global_position + Vector3(0, 1.45, 0)
	PlayerState.floating_damage_spawned.emit(hit_wpos, dmg, is_headshot, display_tier, cracked_now)
	_update_overhead_label()

	if hp <= 0.0:
		AudioSynthesizer.play_kill_confirmed()
		PlayerState.kills += 1
		PlayerState.add_damage_and_evo(100)
		if PlayerState.beast_timer > 0.0:
			PlayerState.beast_timer += 4.0
			PlayerState.hp = minf(PlayerState.max_hp, PlayerState.hp + 40.0)
		PlayerState.killfeed_pushed.emit("💀 你使用 [%s] 淘汰了 %s" % [weapon_name, bot_name], Color("#ff1e42"))
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
