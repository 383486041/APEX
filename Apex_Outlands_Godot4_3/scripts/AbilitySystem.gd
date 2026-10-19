class_name AbilitySystem
extends Node3D
## Complete 3D Legend Skills, Deployables, Healing & Ordnance System for Godot 4.3.
## Overhauled Edition:
## - Replaces demo-style static spheres with Multi-Layered 3D Deployable Models, `CPUParticles3D` Volumetric Smoke/Gas/Sparks,
##   and `evo_shield_hex.gdshader` Hexagonal Forcefields!
## - Authentic Mechanics & Visuals for ALL 12 Legends:
##   1. Wraith: Void Phase trail particles + Upright Elliptical 3D Void Rift Portals (`evo_shield_hex.gdshader`)
##   2. Octane: Stim trail particles + Multi-part 3D Octagonal Launch Pad with pneumatic jets
##   3. Bloodhound: 95m Hexagonal Sonar Wave + Beast of the Hunt thermal lock & kill extension
##   4. Pathfinder: 3D Pendulum Grapple + Dual-Pylon 3D Zipline with interactive re-mounting
##   5. Lifeline: Articulated 3D D.O.C. Drone with live Healing Tether Beam + Orbital Care Package Drop & Halo Shield
##   6. Gibraltar: Shader-driven 6.5m Hexagonal Dome Shield with projector disc + 10 Falling 3D Mortar Shells
##   7. Bangalore: Volumetric `CPUParticles3D` 3-Canister Smoke Wall + Creeping Rolling Thunder Rocket Carpet Barrage
##   8. Ash: Spinning 3D Bladed Arc Snare with live Electric Tether Beam + Vertical Phase Breach Slash
##   9. Horizon: Animated Multi-Ring Gravity Lift with upward particle stream + N.E.W.T. Accretion-Disc Black Hole
##   10. Valkyrie: 12 Arched 3D Micro-Missiles with ground target reticles + Skyward Dive VTOL launch plume
##   11. Caustic: 3D Inflatable Nox Gas Barrel Trap + Billowing Green `CPUParticles3D` Nox Gas Cloud
##   12. Mirage: Fully Animated Running 3D Hologram Decoys (`LegendRigBuilder.animate_rig`) that follow terrain and ping enemies!

var player: PlayerController
var world_root: Node3D
var enemies: Array = []

# Active 3D Deployables
var jump_pads: Array = []       # [{pos: Vector3, node: Node3D}]
var void_portals: Array = []    # [{pos_a: Vector3, pos_b: Vector3, cooldown: float, node_a: Node3D, node_b: Node3D}]
var ziplines: Array = []        # [{start: Vector3, end: Vector3, cooldown: float}]
var gravity_lifts: Array = []   # [{pos: Vector3, expire: float, node: Node3D, rings: Array}]
var black_holes: Array = []     # [{pos: Vector3, expire: float, node: Node3D}]
var doc_drones: Array = []      # [{pos: Vector3, expire: float, node: Node3D, beam: MeshInstance3D}]
var gas_clouds: Array = []      # [{pos: Vector3, radius: float, expire: float, node: Node3D}]
var active_snares: Array = []   # [{pos: Vector3, expire: float, node: Node3D, beam: MeshInstance3D}]
var mirage_decoys: Array = []   # [{node: Node3D, dir: Vector3, speed: float, phase: float, expire: float}]

var heal_audio_tick: float = 0.0
var void_trail_tick: float = 0.0

static var _hex_shader: Shader = null

static func _get_hex_shader() -> Shader:
	if _hex_shader == null:
		_hex_shader = load("res://shaders/evo_shield_hex.gdshader")
	return _hex_shader

static func _make_hex_shader_mat(col: Color, pulse_spd: float = 3.6) -> Material:
	var sh := _get_hex_shader()
	if sh != null:
		var sm := ShaderMaterial.new()
		sm.shader = sh
		sm.set_shader_parameter("shield_color", col)
		sm.set_shader_parameter("pulse_speed", pulse_spd)
		return sm
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = col
	fallback.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
	fallback.emission_enabled = true
	fallback.emission = Color(col.r, col.g, col.b, 1.0)
	fallback.emission_energy_multiplier = 2.4
	return fallback

func _raycast_clamp_position(from_pt: Vector3, to_pt: Vector3, clearance: float = 1.1) -> Vector3:
	if world_root == null or world_root.get_world_3d() == null:
		return to_pt
	var space_state := world_root.get_world_3d().direct_space_state
	if space_state == null:
		return to_pt
	var q := PhysicsRayQueryParameters3D.create(from_pt, to_pt, 1)
	var hit: Dictionary = space_state.intersect_ray(q)
	if not hit.is_empty():
		var hit_pos: Vector3 = hit["position"]
		var hit_norm: Vector3 = hit.get("normal", (from_pt - to_pt).normalized())
		return hit_pos + hit_norm * clearance
	return to_pt

func _raycast_ground_height(xz_pos: Vector3) -> float:
	if world_root == null or world_root.get_world_3d() == null:
		return 0.0
	var space_state := world_root.get_world_3d().direct_space_state
	if space_state == null:
		return 0.0
	var q := PhysicsRayQueryParameters3D.create(Vector3(xz_pos.x, 45.0, xz_pos.z), Vector3(xz_pos.x, -5.0, xz_pos.z), 1)
	var hit: Dictionary = space_state.intersect_ray(q)
	if not hit.is_empty():
		return maxf(0.0, float(hit["position"].y))
	return 0.0

func _process(delta: float) -> void:
	if player == null or world_root == null:
		return

	# 1. Tick Cooldowns & Buff Timers
	if PlayerState.tac_cooldown > 0.0:
		PlayerState.tac_cooldown = maxf(0.0, PlayerState.tac_cooldown - delta)
	if PlayerState.ult_charge < 100.0:
		PlayerState.ult_charge = minf(100.0, PlayerState.ult_charge + delta * 1.5)

	if PlayerState.stim_timer > 0.0:
		PlayerState.stim_timer = maxf(0.0, PlayerState.stim_timer - delta)
	if PlayerState.void_timer > 0.0:
		PlayerState.void_timer = maxf(0.0, PlayerState.void_timer - delta)
		void_trail_tick += delta
		if void_trail_tick >= 0.09:
			void_trail_tick = 0.0
			_spawn_phase_step_wisp(player.global_position + Vector3(0, 1.0, 0), Color("#8b5cf6"))
	if PlayerState.beast_timer > 0.0:
		PlayerState.beast_timer = maxf(0.0, PlayerState.beast_timer - delta)
	if PlayerState.scan_timer > 0.0:
		PlayerState.scan_timer = maxf(0.0, PlayerState.scan_timer - delta)
	if PlayerState.double_time_timer > 0.0:
		PlayerState.double_time_timer = maxf(0.0, PlayerState.double_time_timer - delta)

	# 2. Tick Healing Cast Timer (Key 4) + Progressive Acoustic Feedback
	if PlayerState.heal_cast_timer > 0.0:
		PlayerState.heal_cast_timer -= delta
		heal_audio_tick += delta
		if heal_audio_tick >= 0.42:
			heal_audio_tick = 0.0
			var prog: float = 1.0 - clampf(PlayerState.heal_cast_timer / maxf(0.1, PlayerState.heal_cast_total), 0.0, 1.0)
			AudioSynthesizer.play_consumable_progress(PlayerState.active_heal_id, prog)
		if PlayerState.heal_cast_timer <= 0.0:
			PlayerState.heal_cast_timer = 0.0
			_complete_heal_item()

	# 3. Legend Passive Skills Tick
	_process_passives(delta)

	# 4. Tick 3D Deployables & Animated Decoys
	_process_deployables(delta)

func _process_passives(delta: float) -> void:
	var lid: String = PlayerState.selected_legend_id
	if lid == "octane" and PlayerState.stim_timer <= 0.0 and PlayerState.hp < PlayerState.max_hp:
		var regen_rate: float = 5.5 if PlayerState.chosen_upgrades.get("lv2", "") == "o_2b" else 3.5
		PlayerState.hp = minf(PlayerState.max_hp, PlayerState.hp + regen_rate * delta)
	elif lid == "conduit" and PlayerState.shield < PlayerState.max_shield:
		PlayerState.shield = minf(PlayerState.max_shield, PlayerState.shield + 1.5 * delta)

	var nearest_dist: float = 999.0
	var aiming_at_player: int = 0
	for bot in enemies:
		if not is_instance_valid(bot) or bot.hp <= 0.0:
			continue
		var d: float = bot.global_position.distance_to(player.global_position)
		if d < nearest_dist:
			nearest_dist = d
		if d < 38.0:
			aiming_at_player += 1

	if lid == "wraith" and aiming_at_player > 0:
		PlayerState.passive_warning_text = "⚠️ 虚空低语：附近 38m 内有 %d 名敌方目标正锁定你！" % aiming_at_player
	elif lid == "bloodhound" and nearest_dist < 200.0:
		PlayerState.passive_warning_text = "🦅 渡鸦追踪：最近敌方目标距离 %.0f 米" % nearest_dist
	elif lid == "valkyrie":
		PlayerState.passive_warning_text = "🚀 VTOL 喷气燃料：%d%% [空中按住 Space 飞行]" % int(PlayerState.vtol_fuel)
	elif lid == "ash" and nearest_dist < 200.0:
		PlayerState.passive_warning_text = "🗡️ 死神烙印：最近幸存敌队距离 %.0f 米" % nearest_dist
	else:
		PlayerState.passive_warning_text = ""

func _process_deployables(delta: float) -> void:
	var p_pos: Vector3 = player.global_position
	var now: float = float(Time.get_ticks_msec()) * 0.001

	# 1. Octane Jump Pads (Launches Player & AI Bots!)
	for jp in jump_pads:
		if p_pos.distance_to(jp["pos"]) < 2.25 and player.velocity.y <= 2.0:
			player.velocity.y = 20.5
			var fwd: Vector3 = -player.camera.global_transform.basis.z
			player.velocity.x = fwd.x * 18.0
			player.velocity.z = fwd.z * 18.0
			player.double_jump_ready = true
			AudioSynthesizer.play_ability("jumppad")
		for bot in enemies:
			if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(jp["pos"]) < 2.1 and bot.velocity.y <= 1.0:
				bot.velocity.y = 18.5

	# 2. Wraith / Ash Void Portals (Bidirectional Teleport + Vortex Rotation)
	for vp in void_portals:
		if is_instance_valid(vp.get("node_a")):
			vp["node_a"].rotation.z += delta * 2.2
		if is_instance_valid(vp.get("node_b")):
			vp["node_b"].rotation.z -= delta * 2.2
		if vp["cooldown"] > 0.0:
			vp["cooldown"] -= delta
			continue
		if p_pos.distance_to(vp["pos_a"]) < 2.0:
			player.global_position = vp["pos_b"] + Vector3(0, 0.5, 0)
			vp["cooldown"] = 2.0
			AudioSynthesizer.play_ability("void")
			PlayerState.toast_pushed.emit("🌀 已通过维度裂隙传送门转移！", "evo")
		elif p_pos.distance_to(vp["pos_b"]) < 2.0:
			player.global_position = vp["pos_a"] + Vector3(0, 0.5, 0)
			vp["cooldown"] = 2.0
			AudioSynthesizer.play_ability("void")
			PlayerState.toast_pushed.emit("🌀 已通过维度裂隙传送门返回！", "evo")

	# 3. Deployed Pathfinder Ziplines (Re-mountable by approaching start pole)
	for zl in ziplines:
		if float(zl.get("cooldown", 0.0)) > 0.0:
			zl["cooldown"] = maxf(0.0, float(zl["cooldown"]) - delta)
			continue
		if not player.zipline_active and p_pos.distance_to(zl["start"]) < 2.6 and Input.is_key_pressed(KEY_E):
			zl["cooldown"] = 2.0
			player.start_zipline(zl["start"], zl["end"])

	# 4. Horizon Gravity Lifts (Rising Animated Rings + Top Hover)
	for i in range(gravity_lifts.size() - 1, -1, -1):
		var gl: Dictionary = gravity_lifts[i]
		if now >= float(gl["expire"]):
			if is_instance_valid(gl["node"]):
				gl["node"].queue_free()
			gravity_lifts.remove_at(i)
			continue
		if is_instance_valid(gl["node"]):
			var rings_arr: Array = gl.get("rings", [])
			for r_idx in range(rings_arr.size()):
				var rn: Node3D = rings_arr[r_idx]
				if is_instance_valid(rn):
					rn.position.y = fmod(rn.position.y + delta * 14.0, 17.5)
					var h_ratio: float = rn.position.y / 17.5
					var s_val: float = lerpf(1.0, 1.55, h_ratio)
					rn.scale = Vector3(s_val, 1.0, s_val)
		if Vector2(p_pos.x, p_pos.z).distance_to(Vector2(gl["pos"].x, gl["pos"].z)) < 2.6 and p_pos.y < gl["pos"].y + 18.5:
			player.velocity.y = 14.5 if p_pos.y < gl["pos"].y + 16.0 else lerpf(player.velocity.y, 1.2, delta * 8.0)

	# 5. Horizon N.E.W.T. Black Holes (Spinning Accretion Discs + Gravitational Pull)
	for i in range(black_holes.size() - 1, -1, -1):
		var bh: Dictionary = black_holes[i]
		if now >= float(bh["expire"]):
			if is_instance_valid(bh["node"]):
				bh["node"].queue_free()
			black_holes.remove_at(i)
			continue
		if is_instance_valid(bh["node"]):
			var d1: Node3D = bh["node"].get_node_or_null("AccretionDisc1")
			var d2: Node3D = bh["node"].get_node_or_null("AccretionDisc2")
			if d1:
				d1.rotation.y += delta * 6.5
			if d2:
				d2.rotation.x += delta * 5.2
		var pull_rad: float = 22.0 if PlayerState.chosen_upgrades.get("lv2", "") == "h_2b" else 18.0
		for bot in enemies:
			if is_instance_valid(bot) and bot.hp > 0.0:
				var d: float = bot.global_position.distance_to(bh["pos"])
				if d < pull_rad and d > 1.4:
					var pull_dir: Vector3 = (bh["pos"] - bot.global_position).normalized()
					bot.velocity += Vector3(pull_dir.x, 0, pull_dir.z) * 19.5 * delta
					bot.set_scanned(1.2)

	# 6. Lifeline D.O.C. Healing Drones (Bobbing Hover + Live Tether Beam to Player)
	for i in range(doc_drones.size() - 1, -1, -1):
		var dd: Dictionary = doc_drones[i]
		if now >= float(dd["expire"]):
			if is_instance_valid(dd["node"]):
				dd["node"].queue_free()
			doc_drones.remove_at(i)
			continue
		var d_node: Node3D = dd["node"]
		var beam: MeshInstance3D = dd.get("beam")
		if is_instance_valid(d_node):
			d_node.rotation.y += delta * 2.2
			d_node.position.y = dd["pos"].y + sin(now * 3.8) * 0.14
		var dist_p: float = p_pos.distance_to(dd["pos"])
		if dist_p < 8.5:
			var heal_mult: float = 1.35 if PlayerState.chosen_upgrades.get("lv2", "") == "l_2a" else 1.0
			PlayerState.hp = minf(PlayerState.max_hp, PlayerState.hp + 16.0 * heal_mult * delta)
			PlayerState.shield = minf(PlayerState.max_shield, PlayerState.shield + 11.0 * heal_mult * delta)
			if is_instance_valid(beam) and is_instance_valid(d_node):
				beam.visible = true
				var p_chest: Vector3 = p_pos + Vector3(0, 1.15, 0)
				var d_origin: Vector3 = d_node.global_position
				var b_len: float = d_origin.distance_to(p_chest)
				if b_len > 0.2:
					var cyl_b: CylinderMesh = beam.mesh as CylinderMesh
					cyl_b.height = b_len
					beam.global_position = (d_origin + p_chest) * 0.5
					var dir_b: Vector3 = (p_chest - d_origin).normalized()
					var up_b: Vector3 = Vector3.UP if absf(dir_b.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
					beam.look_at(p_chest, up_b)
					beam.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		elif is_instance_valid(beam):
			beam.visible = false

	# 7. Ash Spinning Arc Snares (Tethers Enemy + Draws Live Electric Beam!)
	for i in range(active_snares.size() - 1, -1, -1):
		var sn: Dictionary = active_snares[i]
		if now >= float(sn["expire"]):
			if is_instance_valid(sn["node"]):
				sn["node"].queue_free()
			active_snares.remove_at(i)
			continue
		var sn_node: Node3D = sn["node"]
		var sn_beam: MeshInstance3D = sn.get("beam")
		if is_instance_valid(sn_node):
			sn_node.rotation.y += delta * 14.0
		var tethered_bot: ApexBotAI = null
		for bot in enemies:
			if is_instance_valid(bot) and bot.hp > 0.0:
				var d_s: float = bot.global_position.distance_to(sn["pos"])
				if d_s <= 9.5:
					tethered_bot = bot
					if d_s > 2.2:
						var pull_s: Vector3 = (sn["pos"] - bot.global_position).normalized()
						bot.velocity.x = lerpf(bot.velocity.x, pull_s.x * 9.5, delta * 12.0)
						bot.velocity.z = lerpf(bot.velocity.z, pull_s.z * 9.5, delta * 12.0)
					break
		if tethered_bot != null and is_instance_valid(sn_beam):
			sn_beam.visible = true
			var b_start: Vector3 = sn["pos"] + Vector3(0, 0.9, 0)
			var b_end: Vector3 = tethered_bot.global_position + Vector3(0, 1.1, 0)
			var b_dist: float = b_start.distance_to(b_end)
			if b_dist > 0.2:
				(sn_beam.mesh as CylinderMesh).height = b_dist
				sn_beam.global_position = (b_start + b_end) * 0.5
				var b_dir: Vector3 = (b_end - b_start).normalized()
				sn_beam.look_at(b_end, Vector3.UP if absf(b_dir.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT)
				sn_beam.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		elif is_instance_valid(sn_beam):
			sn_beam.visible = false

	# 8. Caustic Nox Gas Trap Barrels & Toxic Gas Clouds
	for i in range(gas_clouds.size() - 1, -1, -1):
		var gc: Dictionary = gas_clouds[i]
		if now >= float(gc["expire"]):
			if is_instance_valid(gc["node"]):
				gc["node"].queue_free()
			gas_clouds.remove_at(i)
			continue
		if PlayerState.selected_legend_id == "caustic" and PlayerState.chosen_upgrades.get("lv3", "") == "c_3b":
			if p_pos.distance_to(gc["pos"]) < float(gc["radius"]):
				PlayerState.hp = minf(PlayerState.max_hp, PlayerState.hp + 10.0 * delta)
				PlayerState.shield = minf(PlayerState.max_shield, PlayerState.shield + 10.0 * delta)
		for bot in enemies:
			if is_instance_valid(bot) and bot.hp > 0.0:
				if bot.global_position.distance_to(gc["pos"]) < float(gc["radius"]):
					bot.set_scanned(1.8)
					if randf() < delta * 2.5:
						bot.apply_damage(9, false, "夜神剧毒绿雾")

	# 9. Mirage Animated Running 3D Hologram Decoys (`LegendRigBuilder.animate_rig`)
	for i in range(mirage_decoys.size() - 1, -1, -1):
		var md: Dictionary = mirage_decoys[i]
		var d_rig: Node3D = md["node"]
		if now >= float(md["expire"]) or not is_instance_valid(d_rig):
			if is_instance_valid(d_rig):
				_spawn_phase_step_wisp(d_rig.global_position + Vector3(0, 1.0, 0), Color("#facc15"))
				d_rig.queue_free()
			mirage_decoys.remove_at(i)
			continue
		var d_dir: Vector3 = md["dir"]
		var d_spd: float = float(md["speed"])
		if d_spd > 0.5:
			var next_pos: Vector3 = d_rig.global_position + d_dir * d_spd * delta
			var clamped_next: Vector3 = _raycast_clamp_position(d_rig.global_position + Vector3(0, 1.0, 0), next_pos + Vector3(0, 1.0, 0), 0.8)
			if Vector2(clamped_next.x - d_rig.global_position.x, clamped_next.z - d_rig.global_position.z).length() < d_spd * delta * 0.35:
				md["speed"] = 0.0
				d_spd = 0.0
			else:
				d_rig.global_position = Vector3(clamped_next.x, _raycast_ground_height(clamped_next), clamped_next.z)
		md["phase"] = float(md["phase"]) + delta * 9.5
		LegendRigBuilder.animate_rig(d_rig, delta, {
			"mode": "combat",
			"is_moving": (d_spd > 0.5),
			"is_crouching": false,
			"is_sliding": false,
			"is_in_air": false,
			"aim_pitch": 0.0,
			"move_angle_local": 0.0,
			"strafe_phase": float(md["phase"]),
			"strafe_dir": 1.0,
			"speed": d_spd,
			"time": now
		})
		# If an enemy gets baited by the decoy within 14m, scan that enemy ("Bamboozled!")
		for bot in enemies:
			if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(d_rig.global_position) < 12.0:
				if bot.scanned_timer <= 0.1:
					bot.set_scanned(4.0)


func use_tactical() -> void:
	if PlayerState.tac_cooldown > 0.0:
		PlayerState.toast_pushed.emit("⏳ 战术技能冷却中 (%.1fs)" % PlayerState.tac_cooldown, "warn")
		return

	PlayerState.heal_cast_timer = 0.0

	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	var lid: String = str(leg["id"])
	var cd: float = float(leg["tac_cd"])
	if PlayerState.beast_timer > 0.0 and lid == "bloodhound":
		cd = 5.0
	if PlayerState.chosen_upgrades["lv2"] != "":
		cd *= 0.80
	PlayerState.tac_cooldown = cd

	var origin: Vector3 = player.camera.global_position
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	var raw_target: Vector3 = player.global_position + Vector3(fwd.x, 0, fwd.z).normalized() * 14.0
	var target_ground: Vector3 = _raycast_clamp_position(origin, raw_target + Vector3(0, 1.0, 0), 1.0)
	target_ground.y = _raycast_ground_height(target_ground)

	BehaviorRecorder.record_event("use_tactical", {"legend": lid})

	match lid:
		"wraith":
			AudioSynthesizer.play_ability("void")
			AudioSynthesizer.play_legend_voice("wraith")
			PlayerState.void_timer = 4.0
			_spawn_phase_step_wisp(player.global_position + Vector3(0, 1.0, 0), Color("#8b5cf6"))
			PlayerState.toast_pushed.emit("🌀 【踏入虚空】：进入跨维度虚空通道 4 秒，免疫伤害且移速 +32%！", "evo")
		"octane":
			AudioSynthesizer.play_ability("stim")
			AudioSynthesizer.play_legend_voice("octane")
			var hp_cost: float = 8.0 if PlayerState.chosen_upgrades.get("lv2", "") == "o_2a" else 12.0
			PlayerState.hp = maxf(1.0, PlayerState.hp - hp_cost)
			PlayerState.stim_timer = 6.0
			_spawn_phase_step_wisp(player.global_position + Vector3(0, 1.0, 0), Color("#22c55e"))
			PlayerState.toast_pushed.emit("💉 【兴奋剂】：肾上腺素注入！冲刺速度 +32%，换弹加速！", "evo")
		"bloodhound":
			AudioSynthesizer.play_ability("scan")
			var scan_dur: float = 6.5 if PlayerState.chosen_upgrades.get("lv2", "") == "b_2a" else 5.0
			PlayerState.scan_timer = scan_dur
			_spawn_sonar_pulse_dome(player.global_position)
			var count: int = 0
			for bot in enemies:
				if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(player.global_position) <= 95.0:
					bot.set_scanned(scan_dur)
					count += 1
			if count > 0 and PlayerState.chosen_upgrades.get("lv2", "") == "b_2b":
				PlayerState.ult_charge = minf(100.0, PlayerState.ult_charge + 20.0)
			PlayerState.toast_pushed.emit("👁️ 【上帝之眼】：声呐脉冲已透视锁定 %d 名敌方目标！" % count, "evo")
		"pathfinder":
			AudioSynthesizer.play_legend_voice("pathfinder")
			var desired_hook: Vector3 = origin + fwd * 32.0
			var hook_pt: Vector3 = _raycast_clamp_position(origin, desired_hook, 0.5)
			hook_pt.y = maxf(3.5, hook_pt.y)
			_spawn_phase_step_wisp(hook_pt, Color("#facc15"))
			player.start_grapple(hook_pt)
			PlayerState.toast_pushed.emit("🪝 【机械钩爪】：抓钩已锚定！摆锤高速弹射飞跃！", "evo")
		"lifeline":
			AudioSynthesizer.play_evo_level_up()
			AudioSynthesizer.play_legend_voice("lifeline")
			_spawn_doc_drone(player.global_position + Vector3(fwd.x * 2.0, 1.25, fwd.z * 2.0))
			PlayerState.toast_pushed.emit("➕ 【D.O.C. 治疗无人机】：已展开医疗力场与治疗光束，持续恢复生命与护盾！", "evo")
		"gibraltar":
			AudioSynthesizer.play_ability("void")
			AudioSynthesizer.play_legend_voice("gibraltar")
			_spawn_dome_shield(player.global_position)
			PlayerState.toast_pushed.emit("🛡️ 【保护圆顶】：6.5m 蜂巢能量力场已展开，阻挡一切火力 12 秒！", "evo")
		"bangalore":
			AudioSynthesizer.play_gunshot("SHOTGUN", "eva8")
			for s in [-1, 0, 1]:
				var sp_pos: Vector3 = target_ground + player.global_transform.basis.x * float(s) * 4.2
				_spawn_volumetric_smoke_canister(sp_pos, Color(0.70, 0.76, 0.84, 0.58), 5.6, 11.5)
			PlayerState.double_time_timer = 4.0
			PlayerState.toast_pushed.emit("💨 【烟雾发射器】：三联装体积粒子战术烟墙已封锁战区！", "info")
		"horizon":
			AudioSynthesizer.play_ability("void")
			var gl_pos: Vector3 = _raycast_clamp_position(origin, player.global_position + Vector3(fwd.x * 3.5, 1.0, fwd.z * 3.5), 0.8)
			gl_pos.y = _raycast_ground_height(gl_pos)
			_spawn_gravity_lift(gl_pos)
			PlayerState.toast_pushed.emit("🌌 【重力电梯】：反重力螺旋上升气流已激活！步入即可升空！", "evo")
		"ash":
			AudioSynthesizer.play_ability("scan")
			_spawn_arc_snare(target_ground)
			PlayerState.toast_pushed.emit("⚡ 【电弧陷阱】：旋转电弧飞盘已束缚并感电目标区域敌人！", "evo")
		"valkyrie":
			AudioSynthesizer.play_gunshot("SHOTGUN", "peacekeeper")
			_spawn_missile_swarm(target_ground)
			PlayerState.toast_pushed.emit("🚀 【导弹群】：12 枚制导微型火箭弹已从肩部发射覆盖目标网格！", "evo")
		"caustic":
			AudioSynthesizer.play_ability("void")
			AudioSynthesizer.play_legend_voice("caustic")
			_spawn_nox_gas_trap(target_ground, 8.5, 12.5)
			PlayerState.toast_pushed.emit("☣️ 【夜神毒气陷阱】：充气毒气罐已部署并释放腐蚀性夜神绿雾！", "evo")
		"mirage":
			AudioSynthesizer.play_ability("scan")
			AudioSynthesizer.play_legend_voice("mirage")
			_spawn_mirage_decoy(player.global_position, fwd)
			PlayerState.toast_pushed.emit("🎭 【疯猫全息诱饵】：动态全息奔跑诱饵已派出吸引火力！", "evo")

	PlayerState.state_updated.emit()

func use_ultimate() -> void:
	if PlayerState.ult_charge < 100.0:
		PlayerState.toast_pushed.emit("⏳ 终极技能充能中 (%d%%)" % int(PlayerState.ult_charge), "warn")
		return
	PlayerState.ult_charge = 0.0
	PlayerState.heal_cast_timer = 0.0

	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	var lid: String = str(leg["id"])
	var origin: Vector3 = player.camera.global_position
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	var flat_fwd: Vector3 = Vector3(fwd.x, 0, fwd.z).normalized()
	var target_ground: Vector3 = _raycast_clamp_position(origin, player.global_position + flat_fwd * 22.0 + Vector3(0, 1.0, 0), 1.2)
	target_ground.y = _raycast_ground_height(target_ground)

	BehaviorRecorder.record_event("use_ultimate", {"legend": lid})
	AudioSynthesizer.play_evo_level_up()

	match lid:
		"wraith":
			var pos_a: Vector3 = player.global_position
			var dist_mult: float = 40.0 if PlayerState.chosen_upgrades.get("lv2", "") == "w_2b" else 32.0
			var raw_b: Vector3 = player.global_position + flat_fwd * dist_mult + Vector3(0, 1.0, 0)
			var pos_b: Vector3 = _raycast_clamp_position(origin, raw_b, 1.2)
			pos_b.y = _raycast_ground_height(pos_b)
			_spawn_void_portal_pair(pos_a, pos_b)
			player.global_position = pos_b + Vector3(0, 0.5, 0)
			PlayerState.toast_pushed.emit("🌀 【维度裂隙】：双向直立虚空传送门已连通！步入任意门即可瞬移！", "evo")
		"octane":
			var pad_pos: Vector3 = _raycast_clamp_position(origin, player.global_position + flat_fwd * 4.5 + Vector3(0, 1.0, 0), 1.0)
			pad_pos.y = _raycast_ground_height(pad_pos)
			_spawn_jump_pad(pad_pos)
			PlayerState.toast_pushed.emit("🚀 【弹射跳垫】：高压弹射跳垫已部署！踩上跳垫可高空飞跃并二段跳！", "evo")
		"bloodhound":
			PlayerState.beast_timer = 18.0
			_spawn_sonar_pulse_dome(player.global_position)
			for bot in enemies:
				if is_instance_valid(bot) and bot.hp > 0.0:
					bot.set_scanned(18.0)
			PlayerState.toast_pushed.emit("🐺 【狩猎野兽】：众神之父赐予感官！18秒全屏红影透视 + 32%移速！", "evo")
		"pathfinder":
			var zip_start: Vector3 = player.global_position + Vector3(0, 2.2, 0)
			var raw_zip_end: Vector3 = player.global_position + flat_fwd * 58.0 + Vector3(0, 10.0, 0)
			var zip_end: Vector3 = _raycast_clamp_position(zip_start, raw_zip_end, 1.5)
			_spawn_zipline(zip_start, zip_end)
			player.start_zipline(zip_start, zip_end)
			PlayerState.toast_pushed.emit("🚡 【滑索枪】：双端立柱高空钢缆滑索已架设并自动挂载滑行！", "evo")
		"lifeline":
			var drop_pos: Vector3 = _raycast_clamp_position(origin, player.global_position + flat_fwd * 6.5 + Vector3(0, 1.0, 0), 1.2)
			drop_pos.y = _raycast_ground_height(drop_pos)
			_spawn_lifeline_care_package_and_halo(drop_pos)
			PlayerState.shield = PlayerState.max_shield
			PlayerState.hp = PlayerState.max_hp
			for k in PlayerState.ammo_reserve.keys():
				PlayerState.ammo_reserve[k] = int(PlayerState.ammo_reserve[k]) + 60
			PlayerState.consumables["shield_battery"] = int(PlayerState.consumables.get("shield_battery", 0)) + 2
			PlayerState.toast_pushed.emit("📦 【D.O.C. 光环护盾与医疗空投仓】：轨道空投已降落，状态回满并补充大电与弹药！", "evo")
		"gibraltar":
			_spawn_gibraltar_defensive_bombardment(target_ground)
			PlayerState.toast_pushed.emit("💥 【防御性轰炸】：信号弹已投出，密集高爆迫击炮群正在轰炸目标区！", "evo")
		"bangalore":
			_spawn_bangalore_rolling_thunder(target_ground, flat_fwd)
			PlayerState.toast_pushed.emit("🧨 【雷鸣滚滚】：地毯式推进火箭弹阵列已插地并即将依次引爆！", "evo")
		"horizon":
			_spawn_black_hole(target_ground)
			PlayerState.toast_pushed.emit("🕳️ 【黑洞奇点】：纽特已展开吸积盘微型黑洞，强力吸附周围所有敌军！", "evo")
		"ash":
			var dist_a: float = 46.0 if PlayerState.chosen_upgrades.get("lv3", "") == "a_3b" else 36.0
			var raw_dest: Vector3 = player.global_position + flat_fwd * dist_a + Vector3(0, 1.0, 0)
			var dest: Vector3 = _raycast_clamp_position(origin, raw_dest, 1.2)
			dest.y = maxf(_raycast_ground_height(dest) + 0.2, player.global_position.y)
			_spawn_void_portal_pair(player.global_position, dest)
			player.global_position = dest
			PlayerState.toast_pushed.emit("⚔️ 【相位裂隙】：一剑斩开单向空间裂隙，瞬间突进至目标点！", "evo")
		"valkyrie":
			_spawn_phase_step_wisp(player.global_position + Vector3(0, 1.0, 0), Color("#f59e0b"))
			player.global_position.y = 115.0 if PlayerState.chosen_upgrades.get("lv3", "") == "v_3b" else 95.0
			player.is_skydiving = true
			for bot in enemies:
				if is_instance_valid(bot) and bot.hp > 0.0:
					bot.set_scanned(8.0)
			PlayerState.toast_pushed.emit("🦅 【天际俯冲】：喷气全开冲入高空，已自动扫描全图敌方目标！", "evo")
		"caustic":
			var gas_r: float = 16.5 if PlayerState.chosen_upgrades.get("lv3", "") == "c_3a" else 13.0
			_spawn_nox_gas_trap(target_ground, gas_r, 15.0)
			PlayerState.toast_pushed.emit("☣️ 【夜神毒气手雷】：大范围高浓缩夜神毒雾已瞬间覆盖目标战区！", "evo")
		"mirage":
			PlayerState.void_timer = 1.2
			for i in range(6):
				var ang: float = (float(i) / 6.0) * TAU
				var dir := Vector3(cos(ang), 0, sin(ang))
				_spawn_mirage_decoy(player.global_position + dir * 1.8, dir)
			PlayerState.toast_pushed.emit("🎪 【派对焦点】：短暂隐身并召唤 6 个同步奔跑的全息幻象分身！", "evo")
		_:
			_spawn_gibraltar_defensive_bombardment(target_ground)

	PlayerState.state_updated.emit()

func start_heal_item(heal_id: String = "") -> void:
	if heal_id != "":
		PlayerState.selected_heal_id = heal_id
	var hid: String = PlayerState.selected_heal_id
	var count: int = int(PlayerState.consumables.get(hid, 0))
	if count <= 0:
		PlayerState.toast_pushed.emit("⚠️ 【%s】数量不足！请从物资箱或死亡之箱拾取补充" % GameData.get_consumable_name(hid), "warn")
		return

	if (hid == "shield_cell" or hid == "shield_battery") and PlayerState.shield >= PlayerState.max_shield:
		PlayerState.toast_pushed.emit("🛡️ 护盾已满，无需使用电池！", "info")
		return
	if (hid == "syringe" or hid == "med_kit") and PlayerState.hp >= PlayerState.max_hp:
		PlayerState.toast_pushed.emit("❤️ 生命值已满，无需使用医疗品！", "info")
		return

	var cast_t: float = GameData.get_consumable_cast_time(hid)
	if PlayerState.evo_level == 4:
		cast_t *= 0.75
	PlayerState.active_heal_id = hid
	PlayerState.heal_cast_total = cast_t
	PlayerState.heal_cast_timer = cast_t
	heal_audio_tick = 0.0

	AudioSynthesizer.play_consumable_start(hid)
	BehaviorRecorder.record_event("start_heal", {"heal_id": hid, "cast_time": cast_t})
	var hname: String = GameData.get_consumable_name(hid)
	PlayerState.toast_pushed.emit("🔋 正在使用【%s】(%.1f秒)... [第一/三人称动作同步中]" % [hname, cast_t], "info")
	PlayerState.state_updated.emit()

func _complete_heal_item() -> void:
	var hid: String = PlayerState.active_heal_id if PlayerState.active_heal_id != "" else PlayerState.selected_heal_id
	if int(PlayerState.consumables.get(hid, 0)) <= 0:
		return
	PlayerState.deduct_consumable(hid, 1)
	match hid:
		"shield_cell":
			PlayerState.shield = minf(PlayerState.max_shield, PlayerState.shield + 25.0)
		"shield_battery":
			PlayerState.shield = PlayerState.max_shield
		"syringe":
			PlayerState.hp = minf(PlayerState.max_hp, PlayerState.hp + 25.0)
		"med_kit":
			PlayerState.hp = PlayerState.max_hp
		"phoenix_kit":
			PlayerState.hp = PlayerState.max_hp
			PlayerState.shield = PlayerState.max_shield
	AudioSynthesizer.play_consumable_complete(hid)
	var hname: String = GameData.get_consumable_name(hid)
	PlayerState.toast_pushed.emit("✨ 【%s】使用完成！状态已恢复！" % hname, "evo")
	PlayerState.state_updated.emit()

func throw_ordnance() -> void:
	var oid: String = PlayerState.selected_ordnance_id
	if int(PlayerState.ordnance.get(oid, 0)) <= 0:
		PlayerState.toast_pushed.emit("⚠️ 投掷物【%s】数量不足！" % oid, "warn")
		return
	PlayerState.deduct_ordnance(oid, 1)
	var origin: Vector3 = player.camera.global_position
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	var raw_target: Vector3 = player.global_position + Vector3(fwd.x, 0, fwd.z).normalized() * 20.0 + Vector3(0, 0.5, 0)
	var target_pos: Vector3 = _raycast_clamp_position(origin, raw_target, 0.6)
	target_pos.y = maxf(0.4, _raycast_ground_height(target_pos) + 0.4)
	AudioSynthesizer.play_grenade("arc_star", "throw")
	PlayerState.toast_pushed.emit("✦ 已投掷【%s】！" % oid, "info")

	# 3D Shuriken / Ordnance Projectile
	var proj := Node3D.new()
	var star_a := MeshInstance3D.new()
	var bm_a := BoxMesh.new()
	bm_a.size = Vector3(0.36, 0.04, 0.08)
	star_a.mesh = bm_a
	var star_b := MeshInstance3D.new()
	var bm_b := BoxMesh.new()
	bm_b.size = Vector3(0.08, 0.04, 0.36)
	star_b.mesh = bm_b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#38bdf8")
	mat.emission_enabled = true
	mat.emission = Color("#38bdf8")
	mat.emission_energy_multiplier = 3.6
	star_a.material_override = mat
	star_b.material_override = mat
	proj.add_child(star_a)
	proj.add_child(star_b)
	proj.global_position = origin + fwd * 1.0
	world_root.add_child(proj)

	var tw := create_tween()
	tw.tween_property(proj, "global_position", target_pos, 0.52)
	tw.parallel().tween_property(proj, "rotation:y", TAU * 3.0, 0.52)
	tw.tween_interval(0.55)
	tw.tween_callback(func():
		if is_instance_valid(proj):
			proj.queue_free()
		AudioSynthesizer.play_grenade("arc_star", "detonation")
		_spawn_explosion_vfx(target_pos, Color("#38bdf8"), 5.5)
		for bot in enemies:
			if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(target_pos) <= 12.0:
				bot.apply_damage(75, false, "电弧星爆炸")
				bot.set_scanned(3.0)
	)


# ============================================================================
# HIGH-DETAIL MULTI-LAYERED 3D & PARTICLE DEPLOYABLE SPAWNERS
# ============================================================================

func _spawn_phase_step_wisp(pos: Vector3, col: Color) -> void:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = 12
	p.lifetime = 0.45
	p.explosiveness = 0.85
	var sm := SphereMesh.new()
	sm.radius = 0.09
	sm.height = 0.18
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.5
	sm.material = mat
	p.mesh = sm
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.42
	p.gravity = Vector3(0, 2.5, 0)
	world_root.add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(0.55).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free()
	)

func _spawn_explosion_vfx(pos: Vector3, col: Color, blast_radius: float = 5.0) -> void:
	## Spawns a multi-layered Shockwave Torus Ring + Flash Core + `CPUParticles3D` Fire/Smoke Debris Burst!
	var root := Node3D.new()
	root.global_position = pos
	world_root.add_child(root)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.85
	ring.mesh = torus
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(col.r, col.g, col.b, 0.88)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.emission_enabled = true
	rmat.emission = col
	rmat.emission_energy_multiplier = 4.5
	ring.material_override = rmat
	ring.position = Vector3(0, 0.25, 0)
	root.add_child(ring)

	var sparks := CPUParticles3D.new()
	sparks.emitting = false
	sparks.one_shot = true
	sparks.amount = 22
	sparks.lifetime = 0.65
	sparks.explosiveness = 0.92
	var s_mesh := SphereMesh.new()
	s_mesh.radius = 0.16
	s_mesh.height = 0.32
	s_mesh.material = rmat
	sparks.mesh = s_mesh
	sparks.direction = Vector3(0, 1, 0)
	sparks.spread = 85.0
	sparks.initial_velocity_min = 6.0
	sparks.initial_velocity_max = 14.5
	sparks.gravity = Vector3(0, -18.0, 0)
	root.add_child(sparks)
	sparks.emitting = true

	var tw := create_tween()
	tw.tween_property(ring, "scale", Vector3(blast_radius, 1.4, blast_radius), 0.36)
	tw.parallel().tween_property(rmat, "albedo_color:a", 0.0, 0.38)
	tw.tween_interval(0.35)
	tw.tween_callback(root.queue_free)

func _spawn_sonar_pulse_dome(center: Vector3) -> void:
	## Bloodhound Eye of the Allfather: Shader-driven Hexagonal Sonar Dome + Ground Pulse Ring
	var dome := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 1.0
	sp.height = 2.0
	dome.mesh = sp
	dome.material_override = _make_hex_shader_mat(Color(1.0, 0.28, 0.08, 0.55), 5.0)
	dome.global_position = center
	world_root.add_child(dome)
	var tw := create_tween()
	tw.tween_property(dome, "scale", Vector3(88, 88, 88), 0.88)
	tw.tween_callback(dome.queue_free)

func _spawn_jump_pad(pos: Vector3) -> void:
	## Octane Launch Pad: Detailed 3D Octagonal Frame + Corner Stabilizers + Glowing Green Cushion + Upward Air Jets!
	var root := Node3D.new()
	root.global_position = pos
	world_root.add_child(root)

	var mat_frame := CanyonWorldBuilder._make_mat(Color("#1e293b"), 0.82, 0.28)
	var mat_hazard := CanyonWorldBuilder._make_mat(Color("#f59e0b"), 0.55, 0.35)
	var mat_pad := CanyonWorldBuilder._make_mat(Color("#22c55e"), 0.25, 0.20, true, 2.8)

	CanyonWorldBuilder._add_cyl(root, 1.65, 1.82, 0.18, Vector3(0, 0.09, 0), mat_frame, Vector3.ZERO, 8)
	CanyonWorldBuilder._add_cyl(root, 1.38, 1.48, 0.26, Vector3(0, 0.16, 0), mat_pad, Vector3.ZERO, 12)
	for i in range(4):
		var ang: float = float(i) * (PI * 0.5) + PI * 0.25
		CanyonWorldBuilder._add_box(root, Vector3(0.45, 0.22, 0.32), Vector3(cos(ang) * 1.62, 0.11, sin(ang) * 1.62), mat_hazard, Vector3(0, -ang, 0))

	var jets := CPUParticles3D.new()
	jets.amount = 14
	jets.lifetime = 0.65
	var jm := SphereMesh.new()
	jm.radius = 0.08
	jm.height = 0.16
	jm.material = mat_pad
	jets.mesh = jm
	jets.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	jets.emission_sphere_radius = 1.1
	jets.direction = Vector3(0, 1, 0)
	jets.spread = 12.0
	jets.initial_velocity_min = 3.5
	jets.initial_velocity_max = 6.0
	jets.gravity = Vector3.ZERO
	jets.position = Vector3(0, 0.25, 0)
	root.add_child(jets)

	jump_pads.append({"pos": pos, "node": root})

func _spawn_void_portal_pair(pos_a: Vector3, pos_b: Vector3) -> void:
	## Wraith Dimensional Rift / Ash Phase Breach: Upright Elliptical 3D Void Rift Portals with Shader Membrane & Particles!
	var nodes: Array = []
	for p in [pos_a, pos_b]:
		var p_root := Node3D.new()
		p_root.global_position = p + Vector3(0, 1.25, 0)
		p_root.scale = Vector3(0.82, 1.35, 0.82)
		world_root.add_child(p_root)

		var outer := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.82
		torus.outer_radius = 1.08
		outer.mesh = torus
		outer.rotation.x = PI * 0.5
		outer.material_override = CanyonWorldBuilder._make_mat(Color("#a855f7"), 0.2, 0.1, true, 4.2)
		p_root.add_child(outer)

		var core := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.84
		cyl.bottom_radius = 0.84
		cyl.height = 0.06
		core.mesh = cyl
		core.rotation.x = PI * 0.5
		core.material_override = _make_hex_shader_mat(Color(0.55, 0.22, 0.98, 0.72), 6.0)
		p_root.add_child(core)

		var sparks := CPUParticles3D.new()
		sparks.amount = 16
		sparks.lifetime = 0.75
		var sm := SphereMesh.new()
		sm.radius = 0.06
		sm.height = 0.12
		sm.material = outer.material_override
		sparks.mesh = sm
		sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
		sparks.emission_ring_radius = 0.92
		sparks.emission_ring_inner_radius = 0.75
		sparks.emission_ring_height = 0.1
		sparks.emission_ring_axis = Vector3(0, 0, 1)
		sparks.gravity = Vector3.ZERO
		p_root.add_child(sparks)

		nodes.append(p_root)

	void_portals.append({"pos_a": pos_a, "pos_b": pos_b, "cooldown": 1.5, "node_a": nodes[0], "node_b": nodes[1]})

func _spawn_zipline(p_start: Vector3, p_end: Vector3) -> void:
	## Pathfinder Zipline Gun: Spawns Dual 3D Armored Zipline Pylons at Both Ends + High-Visibility Cable!
	var mat_pole := CanyonWorldBuilder._make_mat(Color("#334155"), 0.85, 0.25)
	var mat_yellow := CanyonWorldBuilder._make_mat(Color("#facc15"), 0.75, 0.20, true, 2.4)

	for end_pt in [p_start, p_end]:
		var ground_y: float = _raycast_ground_height(end_pt)
		var pole_h: float = maxf(2.4, end_pt.y - ground_y + 0.4)
		var pylon := Node3D.new()
		pylon.global_position = Vector3(end_pt.x, ground_y, end_pt.z)
		world_root.add_child(pylon)
		CanyonWorldBuilder._add_cyl(pylon, 0.12, 0.16, pole_h, Vector3(0, pole_h * 0.5, 0), mat_pole, Vector3.ZERO, 8)
		CanyonWorldBuilder._add_cyl(pylon, 0.35, 0.45, 0.25, Vector3(0, 0.125, 0), mat_pole, Vector3.ZERO, 8)
		CanyonWorldBuilder._add_box(pylon, Vector3(0.32, 0.28, 0.32), Vector3(0, pole_h, 0), mat_yellow)

	var dist: float = p_start.distance_to(p_end)
	var cable := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.038
	cyl.bottom_radius = 0.038
	cyl.height = dist
	cable.mesh = cyl
	cable.material_override = mat_yellow
	world_root.add_child(cable)
	cable.global_position = (p_start + p_end) * 0.5
	var dir: Vector3 = (p_end - p_start).normalized()
	var up_v: Vector3 = Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	cable.look_at(p_end, up_v)
	cable.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	ziplines.append({"start": p_start, "end": p_end, "cooldown": 1.2})

func _spawn_dome_shield(pos: Vector3) -> void:
	## Gibraltar Dome of Protection: 3D Ground Projector Disc + 6.5m Hexagonal Shader Forcefield (`evo_shield_hex.gdshader`) + Base Ring!
	var root := Node3D.new()
	root.global_position = pos
	world_root.add_child(root)

	var mat_proj := CanyonWorldBuilder._make_mat(Color("#ea580c"), 0.78, 0.25, true, 2.2)
	var mat_cyan := CanyonWorldBuilder._make_mat(Color("#38bdf8"), 0.2, 0.1, true, 3.8)
	CanyonWorldBuilder._add_cyl(root, 0.42, 0.52, 0.18, Vector3(0, 0.09, 0), mat_proj, Vector3.ZERO, 12)
	CanyonWorldBuilder._add_cyl(root, 0.22, 0.22, 0.24, Vector3(0, 0.12, 0), mat_cyan, Vector3.ZERO, 12)

	var dome := MeshInstance3D.new()
	var sp := SphereMesh.new()
	var r_val: float = 7.5 if PlayerState.chosen_upgrades.get("lv3", "") == "g_3a" else 6.5
	sp.radius = r_val
	sp.height = r_val
	sp.is_hemisphere = true
	dome.mesh = sp
	dome.material_override = _make_hex_shader_mat(Color(0.14, 0.74, 0.98, 0.56), 3.4)
	root.add_child(dome)

	var base_ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = r_val - 0.12
	torus.outer_radius = r_val + 0.08
	base_ring.mesh = torus
	base_ring.material_override = mat_cyan
	base_ring.position = Vector3(0, 0.08, 0)
	root.add_child(base_ring)

	get_tree().create_timer(12.0).timeout.connect(func():
		if is_instance_valid(root):
			root.queue_free()
	)

func _spawn_doc_drone(pos: Vector3) -> void:
	## Lifeline D.O.C. Heal Drone: Articulated 3D Turtle Drone Shell + Twin Hover Rotors + Ground Ring + Live Healing Tether Beam!
	var drone := Node3D.new()
	drone.global_position = pos
	world_root.add_child(drone)

	var mat_shell := CanyonWorldBuilder._make_mat(Color("#f8fafc"), 0.65, 0.25)
	var mat_pink := CanyonWorldBuilder._make_mat(Color("#db2777"), 0.70, 0.28)
	var mat_teal := CanyonWorldBuilder._make_mat(Color("#2dd4bf"), 0.2, 0.1, true, 3.8)
	var mat_dark := CanyonWorldBuilder._make_mat(Color("#0f172a"), 0.8, 0.3)

	CanyonWorldBuilder._add_cyl(drone, 0.36, 0.42, 0.24, Vector3.ZERO, mat_shell, Vector3.ZERO, 12)
	CanyonWorldBuilder._add_box(drone, Vector3(0.28, 0.08, 0.08), Vector3(0, 0.13, 0), mat_pink)
	CanyonWorldBuilder._add_box(drone, Vector3(0.08, 0.08, 0.28), Vector3(0, 0.13, 0), mat_pink)
	CanyonWorldBuilder._add_cyl(drone, 0.12, 0.12, 0.10, Vector3(0, 0, -0.38), mat_teal, Vector3(PI * 0.5, 0, 0), 12)
	for s in [-1.0, 1.0]:
		CanyonWorldBuilder._add_cyl(drone, 0.22, 0.22, 0.05, Vector3(s * 0.48, 0.04, 0), mat_dark, Vector3.ZERO, 12)
		CanyonWorldBuilder._add_cyl(drone, 0.16, 0.16, 0.06, Vector3(s * 0.48, 0.04, 0), mat_teal, Vector3.ZERO, 10)

	var beam := MeshInstance3D.new()
	var b_cyl := CylinderMesh.new()
	b_cyl.top_radius = 0.035
	b_cyl.bottom_radius = 0.035
	b_cyl.height = 1.0
	beam.mesh = b_cyl
	beam.material_override = mat_teal
	beam.visible = false
	world_root.add_child(beam)

	drone.tree_exiting.connect(func():
		if is_instance_valid(beam):
			beam.queue_free()
	)

	doc_drones.append({"pos": pos, "expire": float(Time.get_ticks_msec()) * 0.001 + 14.0, "node": drone, "beam": beam})

func _spawn_lifeline_care_package_and_halo(pos: Vector3) -> void:
	## Lifeline Ultimate: Drops a 3D Triangular Orbital Care Package Pod from the sky + D.O.C. Halo Barrier!
	_spawn_dome_shield(pos)
	_spawn_doc_drone(pos + Vector3(0, 1.35, 0))

	var pod := Node3D.new()
	pod.global_position = pos + Vector3(0, 36.0, 0)
	world_root.add_child(pod)

	var mat_body := CanyonWorldBuilder._make_mat(Color("#f8fafc"), 0.72, 0.26)
	var mat_trim := CanyonWorldBuilder._make_mat(Color("#db2777"), 0.65, 0.28)
	var mat_glow := CanyonWorldBuilder._make_mat(Color("#38bdf8"), 0.2, 0.1, true, 4.0)

	CanyonWorldBuilder._add_cyl(pod, 0.95, 1.25, 2.8, Vector3(0, 1.4, 0), mat_body, Vector3.ZERO, 3)
	CanyonWorldBuilder._add_cyl(pod, 1.02, 1.30, 0.35, Vector3(0, 2.6, 0), mat_trim, Vector3.ZERO, 3)
	CanyonWorldBuilder._add_cyl(pod, 1.32, 1.36, 0.24, Vector3(0, 0.12, 0), mat_glow, Vector3.ZERO, 6)

	var tw := create_tween()
	tw.tween_property(pod, "global_position:y", pos.y, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		AudioSynthesizer.play_gunshot("SHOTGUN", "mastiff")
		_spawn_explosion_vfx(pos, Color("#38bdf8"), 4.5)
	)
	tw.tween_interval(18.0)
	tw.tween_callback(func():
		if is_instance_valid(pod):
			pod.queue_free()
	)

func _spawn_gravity_lift(pos: Vector3) -> void:
	## Horizon Gravity Lift: Base Emitter Disc + 4 Animated Rising Spiral Torus Rings + Upward Anti-Gravity Particle Stream!
	var root := Node3D.new()
	root.global_position = pos
	world_root.add_child(root)

	var mat_cyan := CanyonWorldBuilder._make_mat(Color("#38bdf8"), 0.2, 0.1, true, 4.0)
	CanyonWorldBuilder._add_cyl(root, 0.55, 0.68, 0.16, Vector3(0, 0.08, 0), mat_cyan, Vector3.ZERO, 12)

	var rings: Array = []
	for i in range(4):
		var r_mesh := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 1.25
		torus.outer_radius = 1.42
		r_mesh.mesh = torus
		r_mesh.material_override = mat_cyan
		r_mesh.position = Vector3(0, float(i) * 4.2, 0)
		root.add_child(r_mesh)
		rings.append(r_mesh)

	var stream := CPUParticles3D.new()
	stream.amount = 28
	stream.lifetime = 1.1
	var sm := SphereMesh.new()
	sm.radius = 0.10
	sm.height = 0.20
	sm.material = mat_cyan
	stream.mesh = sm
	stream.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	stream.emission_sphere_radius = 1.35
	stream.direction = Vector3(0, 1, 0)
	stream.spread = 8.0
	stream.initial_velocity_min = 12.0
	stream.initial_velocity_max = 16.0
	stream.gravity = Vector3.ZERO
	root.add_child(stream)

	gravity_lifts.append({"pos": pos, "expire": float(Time.get_ticks_msec()) * 0.001 + 10.0, "node": root, "rings": rings})

func _spawn_black_hole(pos: Vector3) -> void:
	## Horizon N.E.W.T. Black Hole: Dark Event-Horizon Core + Dual Counter-Rotating Accretion Discs + Inward Particle Pull!
	var root := Node3D.new()
	root.global_position = pos + Vector3(0, 2.2, 0)
	world_root.add_child(root)

	var core := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 1.15
	sp.height = 2.30
	core.mesh = sp
	var mat_core := StandardMaterial3D.new()
	mat_core.albedo_color = Color("#090414")
	mat_core.roughness = 0.05
	mat_core.rim_enabled = true
	mat_core.rim = 1.0
	mat_core.rim_tint = 0.0
	core.material_override = mat_core
	root.add_child(core)

	var mat_violet := CanyonWorldBuilder._make_mat(Color("#a855f7"), 0.2, 0.1, true, 4.5)
	var mat_orange := CanyonWorldBuilder._make_mat(Color("#f97316"), 0.2, 0.1, true, 4.2)

	var disc1 := MeshInstance3D.new()
	disc1.name = "AccretionDisc1"
	var t1 := TorusMesh.new()
	t1.inner_radius = 1.65
	t1.outer_radius = 2.55
	disc1.mesh = t1
	disc1.material_override = mat_violet
	disc1.rotation = Vector3(0.35, 0, 0.25)
	root.add_child(disc1)

	var disc2 := MeshInstance3D.new()
	disc2.name = "AccretionDisc2"
	var t2 := TorusMesh.new()
	t2.inner_radius = 1.35
	t2.outer_radius = 1.95
	disc2.mesh = t2
	disc2.material_override = mat_orange
	disc2.rotation = Vector3(-0.65, 0, -0.35)
	root.add_child(disc2)

	var pull_p := CPUParticles3D.new()
	pull_p.amount = 24
	pull_p.lifetime = 0.75
	var pm := SphereMesh.new()
	pm.radius = 0.11
	pm.height = 0.22
	pm.material = mat_violet
	pull_p.mesh = pm
	pull_p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	pull_p.emission_sphere_radius = 4.2
	pull_p.radial_accel_min = -18.0
	pull_p.radial_accel_max = -12.0
	pull_p.gravity = Vector3.ZERO
	root.add_child(pull_p)

	black_holes.append({"pos": pos, "expire": float(Time.get_ticks_msec()) * 0.001 + 10.0, "node": root})

func _spawn_nox_gas_trap(pos: Vector3, radius: float, duration: float) -> void:
	## Caustic Nox Gas Trap & Cloud: 3D Inflatable Black/Yellow Gas Barrel + Billowing Volumetric Green `CPUParticles3D`!
	var root := Node3D.new()
	root.global_position = pos
	world_root.add_child(root)

	var mat_base := CanyonWorldBuilder._make_mat(Color("#1e293b"), 0.82, 0.28)
	var mat_bag := CanyonWorldBuilder._make_mat(Color("#0f172a"), 0.25, 0.68)
	var mat_yellow := CanyonWorldBuilder._make_mat(Color("#eab308"), 0.45, 0.35, true, 1.8)
	var mat_gas := StandardMaterial3D.new()
	mat_gas.albedo_color = Color(0.48, 0.88, 0.14, 0.46)
	mat_gas.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_gas.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_gas.emission_enabled = true
	mat_gas.emission = Color("#84cc16")
	mat_gas.emission_energy_multiplier = 2.0

	# 3D Inflatable Nox Gas Barrel
	CanyonWorldBuilder._add_cyl(root, 0.45, 0.55, 0.24, Vector3(0, 0.12, 0), mat_base, Vector3.ZERO, 8)
	CanyonWorldBuilder._add_cyl(root, 0.42, 0.42, 1.05, Vector3(0, 0.72, 0), mat_bag, Vector3.ZERO, 12)
	CanyonWorldBuilder._add_cyl(root, 0.44, 0.44, 0.14, Vector3(0, 0.52, 0), mat_yellow, Vector3.ZERO, 12)
	CanyonWorldBuilder._add_cyl(root, 0.44, 0.44, 0.14, Vector3(0, 0.92, 0), mat_yellow, Vector3.ZERO, 12)

	# Billowing Nox Gas Particle Cloud
	var gas_p := CPUParticles3D.new()
	gas_p.amount = 32
	gas_p.lifetime = 1.6
	var gm := SphereMesh.new()
	gm.radius = 1.35
	gm.height = 2.2
	gm.material = mat_gas
	gas_p.mesh = gm
	gas_p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	gas_p.emission_sphere_radius = radius * 0.58
	gas_p.direction = Vector3(0, 1, 0)
	gas_p.spread = 95.0
	gas_p.initial_velocity_min = 1.2
	gas_p.initial_velocity_max = 3.2
	gas_p.gravity = Vector3(0, 0.4, 0)
	gas_p.position = Vector3(0, 1.2, 0)
	root.add_child(gas_p)

	gas_clouds.append({"pos": pos, "radius": radius, "expire": float(Time.get_ticks_msec()) * 0.001 + duration, "node": root})

func _spawn_volumetric_smoke_canister(pos: Vector3, col: Color, radius: float, duration: float) -> void:
	## Bangalore Smoke Launcher: 3D Smoke Canister + Multi-Puff Volumetric `CPUParticles3D` Smoke Screen!
	var root := Node3D.new()
	root.global_position = pos
	world_root.add_child(root)

	var mat_can := CanyonWorldBuilder._make_mat(Color("#334155"), 0.8, 0.3)
	CanyonWorldBuilder._add_cyl(root, 0.08, 0.08, 0.36, Vector3(0, 0.10, 0), mat_can, Vector3(PI * 0.5, 0.4, 0), 8)

	var mat_smoke := StandardMaterial3D.new()
	mat_smoke.albedo_color = col
	mat_smoke.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_smoke.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_smoke.roughness = 0.95

	var smoke_p := CPUParticles3D.new()
	smoke_p.amount = 28
	smoke_p.lifetime = 1.8
	var sm := SphereMesh.new()
	sm.radius = 1.55
	sm.height = 2.6
	sm.material = mat_smoke
	smoke_p.mesh = sm
	smoke_p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke_p.emission_sphere_radius = radius * 0.52
	smoke_p.direction = Vector3(0, 1, 0)
	smoke_p.spread = 80.0
	smoke_p.initial_velocity_min = 1.0
	smoke_p.initial_velocity_max = 2.6
	smoke_p.gravity = Vector3(0, 0.35, 0)
	smoke_p.position = Vector3(0, 1.5, 0)
	root.add_child(smoke_p)

	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(root):
			root.queue_free()
	)

func _spawn_arc_snare(pos: Vector3) -> void:
	## Ash Arc Snare: Spinning 3D Bladed Electromagnetic Disc + Electric Field Ring + Live Enemy Tether Beam!
	var root := Node3D.new()
	root.global_position = pos + Vector3(0, 0.95, 0)
	world_root.add_child(root)

	var mat_cyan := CanyonWorldBuilder._make_mat(Color("#06b6d4"), 0.2, 0.1, true, 4.2)
	var mat_steel := CanyonWorldBuilder._make_mat(Color("#cbd5e1"), 0.92, 0.18)

	CanyonWorldBuilder._add_cyl(root, 0.28, 0.28, 0.06, Vector3.ZERO, mat_steel, Vector3.ZERO, 12)
	CanyonWorldBuilder._add_cyl(root, 0.18, 0.18, 0.08, Vector3.ZERO, mat_cyan, Vector3.ZERO, 10)
	for b in range(3):
		var ang: float = float(b) * (TAU / 3.0)
		CanyonWorldBuilder._add_box(root, Vector3(0.42, 0.02, 0.10), Vector3(cos(ang) * 0.28, 0, sin(ang) * 0.28), mat_steel, Vector3(0, -ang + 0.4, 0))

	var field_ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 5.2
	torus.outer_radius = 5.4
	field_ring.mesh = torus
	field_ring.material_override = mat_cyan
	field_ring.position = Vector3(0, -0.85, 0)
	root.add_child(field_ring)

	var beam := MeshInstance3D.new()
	var b_cyl := CylinderMesh.new()
	b_cyl.top_radius = 0.04
	b_cyl.bottom_radius = 0.04
	b_cyl.height = 1.0
	beam.mesh = b_cyl
	beam.material_override = mat_cyan
	beam.visible = false
	world_root.add_child(beam)

	root.tree_exiting.connect(func():
		if is_instance_valid(beam):
			beam.queue_free()
	)

	for bot in enemies:
		if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(pos) <= 11.0:
			bot.apply_damage(25, false, "电弧陷阱")
			bot.set_scanned(4.8)

	var dur: float = 12.0 if PlayerState.chosen_upgrades.get("lv2", "") == "a_2a" else 5.0
	active_snares.append({"pos": pos, "expire": float(Time.get_ticks_msec()) * 0.001 + dur, "node": root, "beam": beam})

func _spawn_missile_swarm(pos: Vector3) -> void:
	## Valkyrie Missile Swarm: 12 Arched 3D Micro-Missiles Launching onto a 4x3 Ground Target Grid!
	var mat_reticle := CanyonWorldBuilder._make_mat(Color("#ef4444"), 0.2, 0.1, true, 3.8)
	var mat_missile := CanyonWorldBuilder._make_mat(Color("#f97316"), 0.3, 0.1, true, 4.2)
	var start_origin: Vector3 = player.global_position + Vector3(0, 2.1, 0)

	for i in range(12):
		var gx: float = (float(i % 4) - 1.5) * 3.2
		var gz: float = (float(i / 4) - 1.0) * 3.2
		var hit_pt: Vector3 = pos + Vector3(gx, 0.08, gz)
		hit_pt.y = _raycast_ground_height(hit_pt) + 0.08

		var marker := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.65
		torus.outer_radius = 0.82
		marker.mesh = torus
		marker.material_override = mat_reticle
		marker.global_position = hit_pt
		world_root.add_child(marker)

		var missile := MeshInstance3D.new()
		var mcyl := CylinderMesh.new()
		mcyl.top_radius = 0.03
		mcyl.bottom_radius = 0.08
		mcyl.height = 0.55
		missile.mesh = mcyl
		missile.material_override = mat_missile
		missile.global_position = start_origin + Vector3(gx * 0.15, 0.4, gz * 0.15)
		world_root.add_child(missile)

		var delay_t: float = float(i) * 0.045
		var apex_pt: Vector3 = (start_origin + hit_pt) * 0.5 + Vector3(0, 9.5, 0)
		var tw := create_tween()
		tw.tween_interval(delay_t)
		tw.tween_property(missile, "global_position", apex_pt, 0.22)
		tw.tween_property(missile, "global_position", hit_pt, 0.24)
		tw.tween_callback(func():
			if is_instance_valid(missile):
				missile.queue_free()
			if is_instance_valid(marker):
				marker.queue_free()
			_spawn_explosion_vfx(hit_pt, Color("#f97316"), 3.2)
			if i == 0 or i == 6:
				AudioSynthesizer.play_gunshot("SHOTGUN", "mastiff")
			if i == 5:
				for bot in enemies:
					if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(pos) <= 13.0:
						bot.apply_damage(40, false, "瓦尔基里导弹群")
						bot.set_scanned(3.0)
		)

func _spawn_gibraltar_defensive_bombardment(pos: Vector3) -> void:
	## Gibraltar Defensive Bombardment: 10 Falling 3D Mortar Shells from Orbit with Red Target Zones & Fireball Plumes!
	var mat_reticle := CanyonWorldBuilder._make_mat(Color("#ef4444"), 0.2, 0.1, true, 4.0)
	var mat_shell := CanyonWorldBuilder._make_mat(Color("#f97316"), 0.4, 0.1, true, 4.5)

	for i in range(10):
		var ang: float = float(i) * (TAU / 10.0) + randf_range(-0.2, 0.2)
		var rad: float = randf_range(2.0, 11.5)
		var hit_pt: Vector3 = pos + Vector3(cos(ang) * rad, 0.08, sin(ang) * rad)
		hit_pt.y = _raycast_ground_height(hit_pt) + 0.08

		var marker := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 1.4
		torus.outer_radius = 1.7
		marker.mesh = torus
		marker.material_override = mat_reticle
		marker.global_position = hit_pt
		world_root.add_child(marker)

		var shell := MeshInstance3D.new()
		var scyl := CylinderMesh.new()
		scyl.top_radius = 0.12
		scyl.bottom_radius = 0.20
		scyl.height = 1.1
		shell.mesh = scyl
		shell.material_override = mat_shell
		shell.global_position = hit_pt + Vector3(0, 38.0, 0)
		world_root.add_child(shell)

		var delay_t: float = 0.25 + float(i) * 0.14
		var tw := create_tween()
		tw.tween_interval(delay_t)
		tw.tween_property(shell, "global_position:y", hit_pt.y, 0.35)
		tw.tween_callback(func():
			if is_instance_valid(shell):
				shell.queue_free()
			if is_instance_valid(marker):
				marker.queue_free()
			if i % 2 == 0:
				AudioSynthesizer.play_gunshot("SNIPER", "kraber")
			_spawn_explosion_vfx(hit_pt, Color("#ef4444"), 5.5)
			for bot in enemies:
				if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(hit_pt) <= 8.5:
					bot.apply_damage(45, false, "防御性迫击炮轰炸")
		)

func _spawn_bangalore_rolling_thunder(pos: Vector3, fwd_dir: Vector3) -> void:
	## Bangalore Rolling Thunder: Creeping 3x4 Grid of 3D Artillery Rockets that Plant in the Ground then Detonate Sequentially!
	var right_dir: Vector3 = fwd_dir.cross(Vector3.UP).normalized()
	var mat_body := CanyonWorldBuilder._make_mat(Color("#334155"), 0.85, 0.25)
	var mat_beacon := CanyonWorldBuilder._make_mat(Color("#ef4444"), 0.2, 0.1, true, 4.2)

	for row in range(3):
		for col_i in range(4):
			var offset: Vector3 = fwd_dir * (float(row - 1) * 5.5) + right_dir * ((float(col_i) - 1.5) * 4.5)
			var hit_pt: Vector3 = pos + offset
			hit_pt.y = _raycast_ground_height(hit_pt)

			var rocket := Node3D.new()
			rocket.global_position = hit_pt + Vector3(0, 32.0, 0)
			world_root.add_child(rocket)
			CanyonWorldBuilder._add_cyl(rocket, 0.12, 0.16, 1.35, Vector3(0, 0.65, 0), mat_body, Vector3(0.18, 0, 0), 8)
			CanyonWorldBuilder._add_cyl(rocket, 0.17, 0.17, 0.22, Vector3(0, 1.15, 0), mat_beacon, Vector3(0.18, 0, 0), 8)

			var drop_delay: float = float(row) * 0.22 + float(col_i) * 0.05
			var tw := create_tween()
			tw.tween_interval(drop_delay)
			tw.tween_property(rocket, "global_position:y", hit_pt.y, 0.32)
			tw.tween_interval(0.55)
			tw.tween_callback(func():
				if is_instance_valid(rocket):
					rocket.queue_free()
				if col_i == 0:
					AudioSynthesizer.play_gunshot("SNIPER", "kraber")
				_spawn_explosion_vfx(hit_pt, Color("#f97316"), 5.2)
				for bot in enemies:
					if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(hit_pt) <= 8.5:
						bot.apply_damage(42, false, "雷鸣滚滚火炮")
						bot.set_scanned(4.0)
			)

func _spawn_mirage_decoy(pos: Vector3, dir: Vector3) -> void:
	## Mirage Psyche Out / Life of the Party: Spawns an Animated 3D Running Decoy oriented along `dir`!
	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	var cur_slot_d: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
	var cur_wid: String = str(cur_slot_d.get("weapon_id", "r301"))
	var decoy := LegendRigBuilder.create_legend_rig(leg, cur_wid)
	world_root.add_child(decoy)
	var flat_dir: Vector3 = Vector3(dir.x, 0.0, dir.z).normalized()
	if flat_dir.length_squared() < 0.01:
		flat_dir = Vector3.FORWARD
	decoy.global_position = Vector3(pos.x, _raycast_ground_height(pos), pos.z)
	decoy.look_at(decoy.global_position + flat_dir * 5.0, Vector3.UP)

	_spawn_phase_step_wisp(decoy.global_position + Vector3(0, 1.0, 0), Color("#38bdf8"))

	mirage_decoys.append({
		"node": decoy,
		"dir": flat_dir,
		"speed": 9.8,
		"phase": randf() * TAU,
		"expire": float(Time.get_ticks_msec()) * 0.001 + 10.0
	})
