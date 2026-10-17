class_name ApexBotAI
extends CharacterBody3D
## Autonomous Smart AI Legend Bot / Firing Range Combat Dummy
## Features:
## - Articulated 3D Limb Animations (walking/running leg & arm swing, crouch/slide weave, jump-peeking, aiming, firing, hit flinch)
## - Tactical AI State Machine: STRAFE_DUEL, CROUCH_WEAVE, SEEK_COVER_HEAL (pops Shield Battery when cracked), AGGRESSIVE_PUSH
## - Cumulative Damage Tracking (emits to PlayerState.hit_feedback_pushed so numbers render on screen HUD without blocking enemy body!)
## - Distinct Armor Hit vs Flesh Hit vs Shield Crack audio & 3D Shield Crack Electric Burst VFX.

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
var ai_state: String = "STRAFE_DUEL" # "STRAFE_DUEL", "SEEK_COVER_HEAL", "AGGRESSIVE_PUSH"
var scanned_timer: float = 0.0
var heal_timer: float = 0.0
var fire_cooldown: float = 1.5
var crouch_timer: float = 0.0
var hit_flinch: float = 0.0

# Cumulative Damage Combo Tracking (resets after 1.65s without being hit)
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

func setup(leg: Dictionary, pos: Vector3, title: String, evo_lv: int = 2) -> void:
	legend_data = leg
	bot_name = title
	evo_level = evo_lv
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

	# 3D Overhead Compact Status Bar (positioned high at y=2.68 so it never blocks head/body shots)
	status_lbl = Label3D.new()
	status_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status_lbl.no_depth_test = false
	status_lbl.font_size = 28
	status_lbl.pixel_size = 0.0042
	status_lbl.position = Vector3(0, 2.68, 0)
	add_child(status_lbl)

	# 3D Scan Highlight Beacon
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

	# 3D Shield Battery Healing Ring (visible when AI is popping a battery)
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
	var state_tag: String = " [⚡打电回甲中...]" if ai_state == "SEEK_COVER_HEAL" else ""
	status_lbl.text = "%s%s\n[护盾 %d | 生命 %d]" % [bot_name, state_tag, int(shield), int(hp)]
	status_lbl.modulate = Color("#ef4444") if scanned_timer > 0.0 else tier["color"]

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
				combo_damage = 0
				ai_state = "STRAFE_DUEL"
				visible = true
				if status_lbl: status_lbl.visible = true
				_update_overhead_label()
			else:
				PlayerState.players_alive = maxi(1, PlayerState.players_alive - 1)
				PlayerState.squads_alive = maxi(1, int(ceil(float(PlayerState.players_alive) / 3.0)))
				PlayerState.state_updated.emit()
		return

	if hp <= 0.0:
		return
	if scanned_timer > 0.0:
		scanned_timer -= delta
		if scanned_timer <= 0.0:
			if scan_beacon: scan_beacon.visible = false
			if status_lbl: status_lbl.no_depth_test = false
			_update_overhead_label()

	if hit_flinch > 0.0:
		hit_flinch = maxf(0.0, hit_flinch - delta * 5.0)

	# Face player if player exists in scene
	var player_node: Node3D = get_parent().get_node_or_null("PlayerController") if get_parent() else null
	if player_node == null and get_parent():
		for c in get_parent().get_children():
			if c is PlayerController:
				player_node = c
				break

	var dist_to_player: float = 999.0
	if player_node != null:
		dist_to_player = global_position.distance_to(player_node.global_position)
		var look_pt := Vector3(player_node.global_position.x, global_position.y, player_node.global_position.z)
		if global_position.distance_to(look_pt) > 0.5:
			look_at(look_pt, Vector3.UP)

	var is_moving: bool = false
	var is_crouching: bool = false

	if ai_mode != "static":
		strafe_phase += delta * 3.8
		# Smart AI State Transitions
		if shield <= 0.0 and hp < 75.0 and ai_state != "SEEK_COVER_HEAL" and randf() < 0.025:
			ai_state = "SEEK_COVER_HEAL"
			heal_timer = 2.6
			heal_fx_mesh.visible = true
			_update_overhead_label()

		if ai_state == "SEEK_COVER_HEAL":
			is_crouching = true
			is_moving = true
			heal_timer -= delta
			heal_fx_mesh.position.y = 0.6 + sin(strafe_phase * 2.0) * 0.45
			global_position.x = lerpf(global_position.x, spawn_origin.x + strafe_dir * 7.5, delta * 3.5)
			if heal_timer <= 0.0:
				shield = max_shield
				ai_state = "STRAFE_DUEL"
				heal_fx_mesh.visible = false
				AudioSynthesizer.play_evo_level_up()
				_update_overhead_label()
		else:
			is_moving = true
			# Randomized A-D strafe reversals & crouch-weaving like real Apex players
			if randf() < 0.022:
				strafe_dir = -strafe_dir
			if randf() < 0.018 and crouch_timer <= 0.0:
				crouch_timer = 0.55
			if crouch_timer > 0.0:
				crouch_timer -= delta
				is_crouching = true

			var offset_x: float = sin(strafe_phase * 0.65) * 5.8 * strafe_dir
			var offset_z: float = cos(strafe_phase * 0.45) * 2.4
			global_position.x = lerpf(global_position.x, spawn_origin.x + offset_x, delta * 4.5)
			global_position.z = lerpf(global_position.z, spawn_origin.z + offset_z, delta * 3.5)

			# AI Combat Shooting at Player
			if ai_mode == "combat" and player_node != null and dist_to_player < 68.0 and not player_node.in_dropship and not player_node.is_skydiving:
				fire_cooldown -= delta
				if fire_cooldown <= 0.0:
					fire_cooldown = randf_range(1.15, 2.1)
					_fire_burst_at_player(player_node)

	_animate_rig_limbs(delta, is_moving, is_crouching)

func _animate_rig_limbs(delta: float, is_moving: bool, is_crouching: bool) -> void:
	if rig_node == null:
		return
	var anim_dict := {
		"mode": "death" if is_dying else ("crouch" if is_crouching else ("combat" if is_moving else "idle")),
		"is_moving": is_moving,
		"is_crouching": is_crouching,
		"is_in_air": not is_on_floor() and not is_dying,
		"is_healing": (ai_state == "SEEK_COVER_HEAL"),
		"is_firing": (fire_cooldown > 0.0 and fire_cooldown < 0.20),
		"strafe_phase": strafe_phase,
		"strafe_dir": strafe_dir,
		"hit_flinch": hit_flinch,
		"death_time": death_collapse_timer if is_dying else -1.0,
		"speed": velocity.length(),
		"time": Time.get_ticks_msec() / 1000.0
	}
	LegendRigBuilder.animate_rig(rig_node, delta, anim_dict)

func _fire_burst_at_player(player_node: PlayerController) -> void:
	if rig_node != null:
		var mflash: Node3D = rig_node.find_child("BotMuzzleFlash", true, false)
		if mflash:
			mflash.visible = true
			get_tree().create_timer(0.08).timeout.connect(func():
				if is_instance_valid(mflash): mflash.visible = false
			)
	# Spawn visible enemy tracer toward player
	if get_parent() != null:
		var p_from: Vector3 = global_position + Vector3(0, 1.35, 0)
		var p_to: Vector3 = player_node.global_position + Vector3(randf_range(-0.6, 0.6), 1.2, randf_range(-0.6, 0.6))
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
		tr.look_at(p_to, Vector3.UP)
		tr.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		get_tree().create_timer(0.075).timeout.connect(func():
			if is_instance_valid(tr): tr.queue_free()
		)

	# Apply slight damage to player if not in Void Phase and roll hits
	if PlayerState.void_timer <= 0.0 and randf() < 0.42:
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

	# Interrupt AI healing if hit
	if ai_state == "SEEK_COVER_HEAL" and heal_fx_mesh:
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
	# Push Cumulative Damage to Screen-Space HUD (NOT on enemy body!)
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
		if status_lbl: status_lbl.visible = false
		if scan_beacon: scan_beacon.visible = false
		if heal_fx_mesh: heal_fx_mesh.visible = false

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
