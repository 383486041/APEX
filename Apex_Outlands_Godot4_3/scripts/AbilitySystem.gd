class_name AbilitySystem
extends Node3D
## Complete 3D Legend Skills, Deployables, Healing & Ordnance System for Godot 4.3.
## Implements Passive, Tactical (Q), and Ultimate (Z) abilities for all 12 Legends:
## - Wraith: Voices from the Void Passive + Into the Void Phase (Q) + Linked Dimensional Rift Portals (Z)
## - Octane: Swift Mend Passive + Stim Injection (Q) + 3D Launch Pad Jump Pad (Z)
## - Bloodhound: Tracker Clues + Eye of the Allfather 3D Sonar Dome (Q) + Beast of the Hunt (Z)
## - Pathfinder: Insider Knowledge + 45m 3D Grappling Hook (Q) + 120m 3D Zipline Gun (Z)
## - Lifeline: Glide Passive + 3D Hovering D.O.C. Heal Drone (Q) + D.O.C. Halo & Care Package Drop (Z)
## - Gibraltar: Gun Shield + 6.5m 3D Dome of Protection (Q) + Defensive Bombardment Artillery (Z)
## - Bangalore: Double Time + 3-Canister Smoke Wall (Q) + Rolling Thunder Barrage (Z)
## - Horizon: Spacewalk + 18m Vertical Gravity Lift Vortex (Q) + N.E.W.T. Black Hole Singularity (Z)
## - Ash: Death Mark + Spinning Arc Snare Tether (Q) + 45m Phase Breach Sword Blink (Z)
## - Valkyrie: VTOL Jetpack + 12-Rocket Missile Swarm (Q) + Skyward Dive Redeploy (Z)
## - Caustic: Nox Vision + 3D Nox Gas Traps (Q) + Nox Gas Grenade Cloud (Z)
## - Mirage: Encore + 3D Holographic Decoy (Q) + Life of the Party 6-Decoy Ring (Z)

var player: PlayerController
var world_root: Node3D
var enemies: Array = []

# Active 3D Deployables
var jump_pads: Array = []       # [{pos: Vector3, node: Node3D}]
var void_portals: Array = []    # [{pos_a: Vector3, pos_b: Vector3, cooldown: float}]
var ziplines: Array = []        # [{start: Vector3, end: Vector3}]
var gravity_lifts: Array = []   # [{pos: Vector3, expire: float, node: Node3D}]
var black_holes: Array = []     # [{pos: Vector3, expire: float, node: Node3D}]
var doc_drones: Array = []      # [{pos: Vector3, expire: float, node: Node3D}]
var gas_clouds: Array = []      # [{pos: Vector3, radius: float, expire: float, node: Node3D}]

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
	if PlayerState.beast_timer > 0.0:
		PlayerState.beast_timer = maxf(0.0, PlayerState.beast_timer - delta)
	if PlayerState.scan_timer > 0.0:
		PlayerState.scan_timer = maxf(0.0, PlayerState.scan_timer - delta)
	if PlayerState.double_time_timer > 0.0:
		PlayerState.double_time_timer = maxf(0.0, PlayerState.double_time_timer - delta)

	# 2. Tick Healing Cast Timer (Key 4)
	if PlayerState.heal_cast_timer > 0.0:
		PlayerState.heal_cast_timer -= delta
		if PlayerState.heal_cast_timer <= 0.0:
			PlayerState.heal_cast_timer = 0.0
			_complete_heal_item()

	# 3. Legend Passive Skills Tick
	_process_passives(delta)

	# 4. Tick 3D Deployables (Jump Pads, Portals, Gravity Lifts, Black Holes, D.O.C. Drones, Gas Clouds)
	_process_deployables(delta)

func _process_passives(delta: float) -> void:
	var lid: String = PlayerState.selected_legend_id
	# Octane Swift Mend Passive
	if lid == "octane" and PlayerState.stim_timer <= 0.0 and PlayerState.hp < PlayerState.max_hp:
		PlayerState.hp = minf(PlayerState.max_hp, PlayerState.hp + 3.5 * delta)

	# Wraith Voices from the Void & Bloodhound Tracker Passive
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
	else:
		PlayerState.passive_warning_text = ""

func _process_deployables(delta: float) -> void:
	var p_pos: Vector3 = player.global_position
	var now: float = float(Time.get_ticks_msec()) * 0.001

	# Jump Pads
	for jp in jump_pads:
		if p_pos.distance_to(jp["pos"]) < 2.2 and player.velocity.y <= 2.0:
			player.velocity.y = 20.5
			var fwd: Vector3 = -player.camera.global_transform.basis.z
			player.velocity.x = fwd.x * 18.0
			player.velocity.z = fwd.z * 18.0
			player.double_jump_ready = true
			AudioSynthesizer.play_ability("jumppad")

	# Void Portals (Bidirectional Teleport)
	for vp in void_portals:
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

	# Horizon Gravity Lifts
	for i in range(gravity_lifts.size() - 1, -1, -1):
		var gl: Dictionary = gravity_lifts[i]
		if now >= float(gl["expire"]):
			if is_instance_valid(gl["node"]): gl["node"].queue_free()
			gravity_lifts.remove_at(i)
			continue
		if Vector2(p_pos.x, p_pos.z).distance_to(Vector2(gl["pos"].x, gl["pos"].z)) < 2.6 and p_pos.y < gl["pos"].y + 18.0:
			player.velocity.y = 14.5

	# Horizon N.E.W.T. Black Holes (Pulls Enemies In)
	for i in range(black_holes.size() - 1, -1, -1):
		var bh: Dictionary = black_holes[i]
		if now >= float(bh["expire"]):
			if is_instance_valid(bh["node"]): bh["node"].queue_free()
			black_holes.remove_at(i)
			continue
		for bot in enemies:
			if is_instance_valid(bot) and bot.hp > 0.0:
				var d: float = bot.global_position.distance_to(bh["pos"])
				if d < 18.0 and d > 1.2:
					bot.global_position = bot.global_position.lerp(bh["pos"], delta * 3.8)
					bot.scanned_timer = 1.0

	# Lifeline D.O.C. Healing Drones
	for i in range(doc_drones.size() - 1, -1, -1):
		var dd: Dictionary = doc_drones[i]
		if now >= float(dd["expire"]):
			if is_instance_valid(dd["node"]): dd["node"].queue_free()
			doc_drones.remove_at(i)
			continue
		if is_instance_valid(dd["node"]):
			dd["node"].rotation.y += delta * 2.5
		if p_pos.distance_to(dd["pos"]) < 8.5:
			PlayerState.hp = minf(PlayerState.max_hp, PlayerState.hp + 15.0 * delta)
			PlayerState.shield = minf(PlayerState.max_shield, PlayerState.shield + 8.0 * delta)

	# Caustic Nox Gas / Thermite Clouds
	for i in range(gas_clouds.size() - 1, -1, -1):
		var gc: Dictionary = gas_clouds[i]
		if now >= float(gc["expire"]):
			if is_instance_valid(gc["node"]): gc["node"].queue_free()
			gas_clouds.remove_at(i)
			continue
		for bot in enemies:
			if is_instance_valid(bot) and bot.hp > 0.0:
				if bot.global_position.distance_to(gc["pos"]) < float(gc["radius"]):
					bot.scanned_timer = 1.5
					if randf() < delta * 2.5:
						bot.apply_damage(8, false, "夜神毒气 / 铝热剂")

func use_tactical() -> void:
	if PlayerState.tac_cooldown > 0.0:
		PlayerState.toast_pushed.emit("⏳ 战术技能冷却中 (%.1fs)" % PlayerState.tac_cooldown, "warn")
		return

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
	var target_ground: Vector3 = player.global_position + Vector3(fwd.x, 0, fwd.z).normalized() * 12.0
	target_ground.y = 0.0

	match lid:
		"wraith":
			AudioSynthesizer.play_ability("void")
			PlayerState.void_timer = 4.0
			PlayerState.toast_pushed.emit("🌀 【踏入虚空】：进入跨维度虚空通道 4 秒，免疫伤害且移速 +35%！", "evo")
		"octane":
			AudioSynthesizer.play_ability("stim")
			PlayerState.hp = maxf(1.0, PlayerState.hp - 12.0)
			PlayerState.stim_timer = 6.0
			PlayerState.toast_pushed.emit("💉 【兴奋剂】：肾上腺素注入！冲刺速度 +35%，换弹加速！", "evo")
		"bloodhound":
			AudioSynthesizer.play_ability("scan")
			PlayerState.scan_timer = 5.0
			_spawn_sonar_pulse_dome(player.global_position)
			var count: int = 0
			for bot in enemies:
				if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(player.global_position) <= 95.0:
					bot.set_scanned(5.0)
					count += 1
			PlayerState.toast_pushed.emit("👁️ 【上帝之眼】：声呐脉冲已透视锁定 %d 名敌方目标！" % count, "evo")
		"pathfinder":
			var hook_pt: Vector3 = origin + fwd * 32.0
			hook_pt.y = maxf(4.5, hook_pt.y + 6.0)
			player.start_grapple(hook_pt)
			PlayerState.toast_pushed.emit("🪝 【机械钩爪】：抓钩已锚定！摆锤高速弹射飞跃！", "evo")
		"lifeline":
			AudioSynthesizer.play_evo_level_up()
			_spawn_doc_drone(player.global_position + Vector3(fwd.x * 2.0, 1.2, fwd.z * 2.0))
			PlayerState.toast_pushed.emit("➕ 【D.O.C. 治疗无人机】：已部署医疗力场，持续恢复生命与护盾！", "evo")
		"gibraltar":
			AudioSynthesizer.play_ability("void")
			_spawn_dome_shield(player.global_position)
			PlayerState.toast_pushed.emit("🛡️ 【保护圆顶】：6.5m 能量护罩已展开，阻挡一切火力 12 秒！", "evo")
		"bangalore":
			AudioSynthesizer.play_gunshot("SHOTGUN")
			for s in [-1, 0, 1]:
				var sp_pos: Vector3 = target_ground + player.global_transform.basis.x * float(s) * 4.2
				_spawn_smoke_sphere(sp_pos, Color(0.65, 0.72, 0.82, 0.55), 5.5, 11.0)
			PlayerState.double_time_timer = 4.0
			PlayerState.toast_pushed.emit("💨 【烟雾发射器】：三联装高爆战术烟墙已封锁战区！", "info")
		"horizon":
			AudioSynthesizer.play_ability("void")
			_spawn_gravity_lift(player.global_position + Vector3(fwd.x * 3.5, 0, fwd.z * 3.5))
			PlayerState.toast_pushed.emit("🌌 【重力电梯】：反重力上升气流已激活！步入即可升空！", "evo")
		"ash":
			AudioSynthesizer.play_ability("scan")
			_spawn_arc_snare(target_ground)
			PlayerState.toast_pushed.emit("⚡ 【电弧陷阱】：电磁飞盘已束缚并感电目标区域敌人！", "evo")
		"valkyrie":
			AudioSynthesizer.play_gunshot("SHOTGUN")
			_spawn_missile_swarm(target_ground)
			PlayerState.toast_pushed.emit("🚀 【导弹群】：12 枚制导微型火箭弹已覆盖目标区！", "evo")
		"caustic":
			AudioSynthesizer.play_ability("void")
			_spawn_gas_cloud(target_ground, 8.5, 12.0)
			PlayerState.toast_pushed.emit("☣️ 【夜神毒气陷阱】：剧毒绿雾已释放，持续腐蚀敌方生命并高亮视野！", "evo")
		"mirage":
			AudioSynthesizer.play_ability("scan")
			_spawn_mirage_decoy(player.global_position, fwd)
			PlayerState.toast_pushed.emit("🎭 【疯猫全息诱饵】：全息诱饵分身已派出吸引火力！", "evo")

	PlayerState.state_updated.emit()

func use_ultimate() -> void:
	if PlayerState.ult_charge < 100.0:
		PlayerState.toast_pushed.emit("⏳ 终极技能充能中 (%d%%)" % int(PlayerState.ult_charge), "warn")
		return
	PlayerState.ult_charge = 0.0

	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	var lid: String = str(leg["id"])
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	var flat_fwd: Vector3 = Vector3(fwd.x, 0, fwd.z).normalized()
	var target_ground: Vector3 = player.global_position + flat_fwd * 22.0
	target_ground.y = 0.0

	AudioSynthesizer.play_evo_level_up()

	match lid:
		"wraith":
			var pos_a: Vector3 = player.global_position
			var pos_b: Vector3 = player.global_position + flat_fwd * 32.0
			pos_b.y = 0.0
			_spawn_void_portal_pair(pos_a, pos_b)
			player.global_position = pos_b + Vector3(0, 0.5, 0)
			PlayerState.toast_pushed.emit("🌀 【维度裂隙】：双向虚空传送门已连通！步入任意门即可瞬移！", "evo")
		"octane":
			var pad_pos: Vector3 = player.global_position + flat_fwd * 4.5
			pad_pos.y = 0.0
			_spawn_jump_pad(pad_pos)
			PlayerState.toast_pushed.emit("🚀 【弹射跳垫】：跳垫已部署！踩上跳垫可高空飞跃并二段跳！", "evo")
		"bloodhound":
			PlayerState.beast_timer = 18.0
			for bot in enemies:
				if is_instance_valid(bot) and bot.hp > 0.0:
					bot.set_scanned(18.0)
			PlayerState.toast_pushed.emit("🐺 【狩猎野兽】：众神之父赐予感官！18秒全屏红影透视 + 35%移速！", "evo")
		"pathfinder":
			var zip_start: Vector3 = player.global_position + Vector3(0, 2.2, 0)
			var zip_end: Vector3 = player.global_position + flat_fwd * 65.0 + Vector3(0, 12.0, 0)
			_spawn_zipline(zip_start, zip_end)
			player.start_zipline(zip_start, zip_end)
			PlayerState.toast_pushed.emit("🚡 【滑索枪】：高空钢缆滑索已架设并自动挂载滑行！", "evo")
		"lifeline":
			var drop_pos: Vector3 = player.global_position + flat_fwd * 6.0
			drop_pos.y = 0.0
			_spawn_dome_shield(drop_pos)
			_spawn_doc_drone(drop_pos + Vector3(0, 1.2, 0))
			PlayerState.shield = PlayerState.max_shield
			PlayerState.hp = PlayerState.max_hp
			PlayerState.toast_pushed.emit("📦 【D.O.C. 光环护盾 & 空投】：全队状态已回满并展开医疗屏障！", "evo")
		"horizon":
			_spawn_black_hole(target_ground)
			PlayerState.toast_pushed.emit("🕳️ 【黑洞奇点】：纽特已展开微型黑洞，强力吸附周围所有敌军！", "evo")
		"ash":
			var dest: Vector3 = player.global_position + flat_fwd * 38.0
			dest.y = maxf(1.0, player.global_position.y)
			_spawn_void_portal_pair(player.global_position, dest)
			player.global_position = dest
			PlayerState.toast_pushed.emit("⚔️ 【相位裂隙】：一剑斩开空间，瞬间闪烁突进 38 米！", "evo")
		"valkyrie":
			player.global_position.y = 95.0
			player.is_skydiving = true
			PlayerState.toast_pushed.emit("🦅 【天际俯冲】：喷气全开冲入高空，进入滑翔空降模式！", "evo")
		"caustic":
			_spawn_gas_cloud(target_ground, 15.0, 15.0)
			PlayerState.toast_pushed.emit("☣️ 【夜神毒气手雷】：大范围剧毒风暴已笼罩战场！", "evo")
		"mirage":
			for i in range(6):
				var ang: float = (float(i) / 6.0) * TAU
				var dir := Vector3(cos(ang), 0, sin(ang))
				_spawn_mirage_decoy(player.global_position + dir * 2.2, dir)
			PlayerState.toast_pushed.emit("🎪 【派对焦点】：6 个全息幻象分身已围绕四周展开！", "evo")
		_:
			# Gibraltar / Bangalore Artillery Bombardment
			_spawn_artillery_barrage(target_ground)
			PlayerState.toast_pushed.emit("💥 【轨道火炮轰炸】：密集重炮已轰炸目标区域！", "evo")

	PlayerState.state_updated.emit()

func start_heal_item(heal_id: String = "") -> void:
	if heal_id != "":
		PlayerState.selected_heal_id = heal_id
	var hid: String = PlayerState.selected_heal_id
	var count: int = int(PlayerState.consumables.get(hid, 0))
	if count <= 0:
		PlayerState.toast_pushed.emit("⚠️ 恢复品数量不足！", "warn")
		return
	var cast_t: float = 3.0 if (hid == "shield_cell" or hid == "syringe") else 4.5
	if PlayerState.evo_level == 4:
		cast_t *= 0.65
	PlayerState.heal_cast_total = cast_t
	PlayerState.heal_cast_timer = cast_t
	AudioSynthesizer.play_ability("stim")
	var hname: String = GameData.get_consumable_name(hid)
	PlayerState.toast_pushed.emit("🔋 正在使用【%s】(%.1fs)..." % [hname, cast_t], "info")

func _complete_heal_item() -> void:
	var hid: String = PlayerState.selected_heal_id
	if int(PlayerState.consumables.get(hid, 0)) <= 0:
		return
	PlayerState.consumables[hid] = int(PlayerState.consumables[hid]) - 1
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
	AudioSynthesizer.play_evo_level_up()
	var hname: String = GameData.get_consumable_name(hid)
	PlayerState.toast_pushed.emit("✨ 【%s】使用完成！状态已补充！" % hname, "evo")
	PlayerState.state_updated.emit()

func throw_ordnance() -> void:
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	var target_pos: Vector3 = player.global_position + Vector3(fwd.x, 0, fwd.z).normalized() * 20.0
	target_pos.y = 0.5
	AudioSynthesizer.play_melee_Whoosh(true)
	PlayerState.toast_pushed.emit("✦ 已投掷【电弧星 / 破片手雷】！", "info")

	# Spawn projectile visual
	var proj := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.22
	proj.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#38bdf8")
	mat.emission_enabled = true
	mat.emission = Color("#38bdf8")
	mat.emission_energy_multiplier = 3.0
	proj.material_override = mat
	proj.global_position = player.camera.global_position + fwd * 1.0
	world_root.add_child(proj)

	var tw := create_tween()
	tw.tween_property(proj, "global_position", target_pos, 0.55)
	tw.tween_interval(0.6)
	tw.tween_callback(func():
		if is_instance_valid(proj):
			proj.queue_free()
		AudioSynthesizer.play_gunshot("SNIPER")
		_spawn_smoke_sphere(target_pos, Color(0.22, 0.74, 0.98, 0.55), 6.0, 1.2)
		for bot in enemies:
			if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(target_pos) <= 12.0:
				bot.apply_damage(75, false, "电弧星爆炸")
	)

# ==================== 3D DEPLOYABLE SPAWNERS ====================
func _spawn_sonar_pulse_dome(center: Vector3) -> void:
	var dome := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 1.0
	sp.height = 2.0
	dome.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.32, 0.1, 0.22)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color("#ef4444")
	mat.emission_energy_multiplier = 2.2
	dome.material_override = mat
	dome.global_position = center
	world_root.add_child(dome)
	var tw := create_tween()
	tw.tween_property(dome, "scale", Vector3(85, 85, 85), 0.85)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.85)
	tw.tween_callback(dome.queue_free)

func _spawn_jump_pad(pos: Vector3) -> void:
	var pad := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.45
	cyl.bottom_radius = 1.65
	cyl.height = 0.28
	pad.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#22c55e")
	mat.emission_enabled = true
	mat.emission = Color("#22c55e")
	mat.emission_energy_multiplier = 1.8
	pad.material_override = mat
	pad.global_position = pos + Vector3(0, 0.14, 0)
	world_root.add_child(pad)
	jump_pads.append({"pos": pos, "node": pad})

func _spawn_void_portal_pair(pos_a: Vector3, pos_b: Vector3) -> void:
	for p in [pos_a, pos_b]:
		var portal := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.85
		torus.outer_radius = 1.18
		portal.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#8b5cf6")
		mat.emission_enabled = true
		mat.emission = Color("#a855f7")
		mat.emission_energy_multiplier = 3.2
		portal.material_override = mat
		portal.global_position = p + Vector3(0, 1.3, 0)
		portal.rotation.x = PI * 0.5
		world_root.add_child(portal)
	void_portals.append({"pos_a": pos_a, "pos_b": pos_b, "cooldown": 1.5})

func _spawn_zipline(p_start: Vector3, p_end: Vector3) -> void:
	var dist: float = p_start.distance_to(p_end)
	var cable := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.04
	cyl.height = dist
	cable.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#facc15")
	mat.emission_enabled = true
	mat.emission = Color("#f59e0b")
	cable.material_override = mat
	world_root.add_child(cable)
	cable.global_position = (p_start + p_end) * 0.5
	var dir: Vector3 = (p_end - p_start).normalized()
	var up_v: Vector3 = Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	cable.look_at(p_end, up_v)
	cable.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	ziplines.append({"start": p_start, "end": p_end})

func _spawn_dome_shield(pos: Vector3) -> void:
	var dome := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 6.5
	sp.height = 6.5
	sp.is_hemisphere = true
	dome.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.72, 0.98, 0.28)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color("#38bdf8")
	dome.material_override = mat
	dome.global_position = Vector3(pos.x, 0.0, pos.z)
	world_root.add_child(dome)
	get_tree().create_timer(12.0).timeout.connect(func():
		if is_instance_valid(dome):
			dome.queue_free()
	)

func _spawn_doc_drone(pos: Vector3) -> void:
	var drone := Node3D.new()
	drone.global_position = pos
	var body := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.35
	sp.height = 0.55
	body.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#2dd4bf")
	mat.emission_enabled = true
	mat.emission = Color("#14b8a6")
	mat.emission_energy_multiplier = 2.2
	body.material_override = mat
	drone.add_child(body)
	world_root.add_child(drone)
	doc_drones.append({"pos": pos, "expire": float(Time.get_ticks_msec()) * 0.001 + 12.0, "node": drone})

func _spawn_gravity_lift(pos: Vector3) -> void:
	var col := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.2
	cyl.bottom_radius = 1.6
	cyl.height = 18.0
	col.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.65, 1.0, 0.30)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color("#38bdf8")
	mat.emission_energy_multiplier = 2.4
	col.material_override = mat
	col.global_position = Vector3(pos.x, 9.0, pos.z)
	world_root.add_child(col)
	gravity_lifts.append({"pos": Vector3(pos.x, 0, pos.z), "expire": float(Time.get_ticks_msec()) * 0.001 + 10.0, "node": col})

func _spawn_black_hole(pos: Vector3) -> void:
	var hole := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 2.6
	sp.height = 5.2
	hole.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.04, 0.25, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color("#a855f7")
	mat.emission_energy_multiplier = 3.2
	hole.material_override = mat
	hole.global_position = pos + Vector3(0, 2.2, 0)
	world_root.add_child(hole)
	black_holes.append({"pos": pos, "expire": float(Time.get_ticks_msec()) * 0.001 + 10.0, "node": hole})

func _spawn_gas_cloud(pos: Vector3, radius: float, duration: float) -> void:
	var cloud := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = radius
	sp.height = 4.5
	cloud.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.85, 0.15, 0.36)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color("#84cc16")
	cloud.material_override = mat
	cloud.global_position = pos + Vector3(0, 1.8, 0)
	world_root.add_child(cloud)
	gas_clouds.append({"pos": pos, "radius": radius, "expire": float(Time.get_ticks_msec()) * 0.001 + duration, "node": cloud})

func _spawn_smoke_sphere(pos: Vector3, col: Color, radius: float, duration: float) -> void:
	var sm := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = radius
	sp.height = radius * 1.4
	sm.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sm.material_override = mat
	sm.global_position = pos + Vector3(0, 2.0, 0)
	world_root.add_child(sm)
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(sm):
			sm.queue_free()
	)

func _spawn_arc_snare(pos: Vector3) -> void:
	_spawn_smoke_sphere(pos, Color(0.1, 0.8, 0.98, 0.45), 6.5, 4.5)
	for bot in enemies:
		if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(pos) <= 11.0:
			bot.apply_damage(25, false, "艾许电弧陷阱")
			bot.set_scanned(4.5)

func _spawn_missile_swarm(pos: Vector3) -> void:
	for i in range(6):
		var offset := Vector3(randf_range(-6.0, 6.0), 0, randf_range(-6.0, 6.0))
		_spawn_smoke_sphere(pos + offset, Color(1.0, 0.45, 0.1, 0.55), 3.5, 1.5)
	for bot in enemies:
		if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(pos) <= 13.0:
			bot.apply_damage(40, false, "瓦尔基里导弹群")

func _spawn_artillery_barrage(pos: Vector3) -> void:
	for i in range(8):
		var offset := Vector3(randf_range(-12.0, 12.0), 0, randf_range(-12.0, 12.0))
		_spawn_smoke_sphere(pos + offset, Color(1.0, 0.25, 0.1, 0.55), 5.0, 2.2)
	for bot in enemies:
		if is_instance_valid(bot) and bot.hp > 0.0 and bot.global_position.distance_to(pos) <= 18.0:
			bot.apply_damage(65, false, "重型火炮轰炸")

func _spawn_mirage_decoy(pos: Vector3, dir: Vector3) -> void:
	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	var decoy := LegendRigBuilder.create_legend_rig(leg)
	decoy.global_position = pos
	world_root.add_child(decoy)
	var tw := create_tween()
	tw.tween_property(decoy, "global_position", pos + Vector3(dir.x, 0, dir.z).normalized() * 18.0, 3.5)
	tw.tween_interval(4.0)
	tw.tween_callback(decoy.queue_free)
