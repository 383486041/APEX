class_name WeaponController
extends Node3D
## Drives First-Person Weapon Ballistics, Multi-Stage Procedural Reload Animations,
## Between-Shot Bolt/Lever Rechambering, Quick Melee (V), 3-Stage Heirloom Slash Combos,
## Weapon Inspect (N), 3D Bullet Tracers, Shell Ejection, and Sentinel/Rampage Charging.

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

# Reload State Machine
var reload_timer: float = 0.0
var reload_total: float = 0.0
var is_empty_reload: bool = false
var reload_step_mask: int = 0 # Bitmask for mag_out(1), mag_in(2), bolt_slap(4)

# Rechamber / Lever-Cock State (Kraber, Sentinel, Peacekeeper)
var rechamber_timer: float = 0.0
var rechamber_total: float = 0.0

# Melee & Inspect State Machine
var quick_melee_timer: float = 0.0
var melee_swing_timer: float = 0.0
var melee_combo_idx: int = 0
var inspect_timer: float = 0.0

# Procedural Viewmodel Transform Offsets
var kick_offset: Vector3 = Vector3.ZERO
var kick_rot: Vector3 = Vector3.ZERO
var bolt_back_offset: float = 0.0

func _process(delta: float) -> void:
	if player == null:
		return

	# Handle Charge Rifle "滋崩" Sequence
	if is_charging_beam:
		if reload_timer > 0.0 or quick_melee_timer > 0.0 or PlayerState.active_slot == 2:
			_cancel_charge_beam()
		else:
			_update_charge_rifle(delta)

	# Decay Charged Weapon timers (Sentinel / Rampage)
	for slot in PlayerState.loadout:
		if float(slot.get("charged", 0.0)) > 0.0:
			slot["charged"] = maxf(0.0, float(slot["charged"]) - delta)

	# Decay Recoil & Bolt Kick
	kick_offset = kick_offset.lerp(Vector3.ZERO, delta * 15.0)
	kick_rot = kick_rot.lerp(Vector3.ZERO, delta * 14.0)
	bolt_back_offset = lerpf(bolt_back_offset, 0.0, delta * 18.0)

	if rechamber_timer > 0.0:
		rechamber_timer = maxf(0.0, rechamber_timer - delta)

	if quick_melee_timer > 0.0:
		quick_melee_timer = maxf(0.0, quick_melee_timer - delta)

	if melee_swing_timer > 0.0:
		melee_swing_timer = maxf(0.0, melee_swing_timer - delta)

	if inspect_timer > 0.0:
		inspect_timer = maxf(0.0, inspect_timer - delta)

	# Process Multi-Stage Reload
	if reload_timer > 0.0:
		reload_timer -= delta
		var progress: float = 1.0 - clampf(reload_timer / maxf(0.01, reload_total), 0.0, 1.0)
		if progress >= 0.14 and (reload_step_mask & 1) == 0:
			reload_step_mask |= 1
			AudioSynthesizer.play_reload_step("mag_out")
			_spawn_dropped_mag()
		if progress >= 0.56 and (reload_step_mask & 2) == 0:
			reload_step_mask |= 2
			AudioSynthesizer.play_reload_step("mag_in")
			kick_offset.y += 0.035
			player.add_camera_recoil(0.012, 0.0, 0.01)
		if progress >= 0.82 and (reload_step_mask & 4) == 0:
			reload_step_mask |= 4
			AudioSynthesizer.play_reload_step("bolt_slap")
			player.add_camera_recoil(-0.015, 0.008, 0.015)

		if reload_timer <= 0.0:
			reload_timer = 0.0
			var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
			var wep: Dictionary = GameData.get_weapon_by_id(slot["weapon_id"])
			var needed: int = int(slot["max_ammo"]) - int(slot["ammo"])
			var ammo_key: String = str(wep["ammo"])
			var avail: int = int(PlayerState.ammo_reserve.get(ammo_key, 999))
			var loaded: int = mini(needed, avail) if PlayerState.selected_mode_id != "firing_range" else needed
			if PlayerState.selected_mode_id != "firing_range":
				PlayerState.ammo_reserve[ammo_key] = maxi(0, avail - loaded)
			slot["ammo"] = int(slot["ammo"]) + loaded
			PlayerState.state_updated.emit()

	_animate_viewmodel(delta)

func _animate_viewmodel(delta: float) -> void:
	if player.viewmodel_holder.get_child_count() == 0:
		return
	var vm: Node3D = player.viewmodel_holder.get_child(0)
	var gun_rig: Node3D = vm.get_node_or_null("GunRig")
	if gun_rig == null:
		return

	var is_heirloom: bool = (PlayerState.active_slot == 2)
	var sprinting: bool = Input.is_key_pressed(KEY_SHIFT) and not player.is_ads and reload_timer <= 0.0
	var base_pos := Vector3(0.24, -0.22, -0.46) if is_heirloom else Vector3(0.28, -0.24, -0.54)
	var optic_node: Node3D = gun_rig.get_node_or_null("OpticPivot")
	var cur_op: String = str(PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)].get("optic", "2x_bruiser"))

	if player.is_ads and not is_heirloom and reload_timer <= 0.0:
		if cur_op == "6x_kraber":
			# High-power sniper optic: drop viewmodel out of view for zero clipping & authentic full-aperture sniper sight picture!
			base_pos = Vector3(0.0, -1.8, -0.4)
			vm.visible = false
		else:
			vm.visible = true
			var slot_w: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
			var wid_cur: String = str(slot_w.get("weapon_id", ""))
			var is_pistol: bool = (wid_cur == "wingman" or wid_cur == "mozambique" or wid_cur == "re45" or wid_cur == "p2020")
			var ads_y: float = -0.098 if is_pistol else -0.111
			var ads_z: float = -0.22
			base_pos = Vector3(0.0, ads_y, ads_z)
		if optic_node:
			var sight_dot: Node3D = optic_node.get_node_or_null("SightDot")
			if sight_dot: sight_dot.visible = false
	else:
		vm.visible = true
		if optic_node:
			var sight_dot: Node3D = optic_node.get_node_or_null("SightDot")
			if sight_dot: sight_dot.visible = true

	# Ensure ammo counter screen housing and charm are hidden during ADS to guarantee zero sightline obstruction
	var ammo_housing: Node3D = gun_rig.get_node_or_null("AmmoScreenHousing")
	if ammo_housing:
		ammo_housing.visible = not player.is_ads
	var charm_node: Node3D = gun_rig.get_node_or_null("OmamoriCharm")
	if charm_node:
		charm_node.visible = not player.is_ads

	# Locomotion Figure-8 Bobbing & Slide Canting
	var bob_x: float = cos(player.bob_time * 0.5) * (0.014 if sprinting else 0.006)
	var bob_y: float = absf(sin(player.bob_time)) * (0.018 if sprinting else 0.007)
	if player.is_ads:
		bob_x *= 0.2
		bob_y *= 0.2

	vm.position = vm.position.lerp(base_pos + Vector3(bob_x, -bob_y, 0) + kick_offset, delta * 18.0)

	var target_rot := kick_rot
	if player.is_sliding:
		target_rot.z = -0.38
		target_rot.x = 0.12
	elif sprinting and not is_heirloom:
		target_rot = Vector3(0.28, 0.42, -0.22)

	# Void Phase Ghostly Visual
	var mag_pivot: Node3D = gun_rig.get_node_or_null("MagPivot")
	var bolt_pivot: Node3D = gun_rig.get_node_or_null("BoltPivot")
	var left_arm: Node3D = gun_rig.get_node_or_null("LeftArmPivot")
	var right_arm: Node3D = gun_rig.get_node_or_null("RightArmPivot")
	var heirloom_pivot: Node3D = gun_rig.get_node_or_null("HeirloomPivot")
	var ammo_lbl: Label3D = gun_rig.find_child("AmmoLabel3D", true, false)

	if ammo_lbl != null and not is_heirloom:
		var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
		ammo_lbl.text = "RLD" if reload_timer > 0.0 else "%02d" % int(slot["ammo"])

	# 1. Multi-Stage Reload Procedural Animation
	if reload_timer > 0.0 and not is_heirloom:
		var p: float = 1.0 - clampf(reload_timer / maxf(0.01, reload_total), 0.0, 1.0)
		if p < 0.32:
			# Stage 1: Tilt gun left, drop magazine out
			var t1: float = p / 0.32
			target_rot = Vector3(0.24 * t1, 0.18 * t1, 0.52 * t1)
			if mag_pivot:
				mag_pivot.position = Vector3(0, -0.14 - t1 * 0.28, -0.05)
				mag_pivot.rotation.x = t1 * 0.65
			if left_arm:
				left_arm.position = Vector3(-0.04, -0.14 - t1 * 0.18, -0.05)
		elif p < 0.68:
			# Stage 2: Bring fresh magazine up & snap into magwell
			var t2: float = (p - 0.32) / 0.36
			var snap_t: float = clampf(t2 * 1.25, 0.0, 1.0)
			target_rot = Vector3(0.24, 0.18, 0.52)
			if mag_pivot:
				mag_pivot.position = Vector3(0, lerpf(-0.42, -0.14, snap_t), -0.05)
				mag_pivot.rotation.x = lerpf(0.5, 0.0, snap_t)
			if left_arm:
				left_arm.position = Vector3(-0.02, lerpf(-0.34, -0.12, snap_t), -0.05)
		else:
			# Stage 3: Cant gun right & pull charging handle / bolt
			var t3: float = (p - 0.68) / 0.32
			var pull: float = sin(t3 * PI)
			target_rot = Vector3(0.10 * (1.0 - t3), -0.22 * pull, -0.38 * pull)
			if mag_pivot:
				mag_pivot.position = Vector3(0, -0.14, -0.05)
				mag_pivot.rotation = Vector3.ZERO
			if bolt_pivot:
				bolt_pivot.position.z = -0.04 + pull * 0.11
			if left_arm:
				left_arm.position = Vector3(-0.05, 0.02 * pull - 0.04, -0.08 + pull * 0.10)
	else:
		# Normal Bolt Reciprocation & Rechambering
		if mag_pivot:
			mag_pivot.position = mag_pivot.position.lerp(Vector3(0, -0.14, -0.05), delta * 16.0)
			mag_pivot.rotation = mag_pivot.rotation.lerp(Vector3.ZERO, delta * 16.0)
		if bolt_pivot:
			if rechamber_timer > 0.0:
				var rp: float = 1.0 - (rechamber_timer / maxf(0.01, rechamber_total))
				var r_wave: float = sin(rp * PI)
				bolt_pivot.position.z = -0.04 + r_wave * 0.12
				bolt_pivot.rotation.z = -r_wave * 0.85
				target_rot.z += r_wave * 0.22
			else:
				bolt_pivot.position.z = -0.04 + bolt_back_offset
				bolt_pivot.rotation = bolt_pivot.rotation.lerp(Vector3.ZERO, delta * 16.0)
		if left_arm and not is_heirloom:
			left_arm.position = left_arm.position.lerp(Vector3(-0.06, -0.05, -0.18), delta * 14.0)

	# 2. Quick Melee Strike Animation with Articulated Left Hand Punch/Palm Strike (V Key)
	if quick_melee_timer > 0.0:
		var mp: float = 1.0 - (quick_melee_timer / 0.42)
		var thrust: float = sin(mp * PI)
		vm.position += Vector3(0.08 * thrust, -0.06 * thrust, -0.18 * thrust)
		target_rot += Vector3(0.25 * thrust, -0.55 * thrust, 0.35 * thrust)
		if left_arm:
			left_arm.position = Vector3(-0.08 + 0.22 * thrust, 0.04 * thrust, -0.18 - 0.38 * thrust)
			left_arm.rotation = Vector3(0.55 * thrust, 0.45 * thrust, -0.35 * thrust)
	elif left_arm and not is_heirloom and reload_timer <= 0.0:
		left_arm.rotation = left_arm.rotation.lerp(Vector3.ZERO, delta * 14.0)

	# 3. Heirloom 3-Stage Slash Combo Animation with Coordinated Right & Left Hand Choreography
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
					left_arm.position = Vector3(-0.26 - arc * 0.10, -0.14 + arc * 0.12, -0.10 - arc * 0.18)
					left_arm.rotation = Vector3(arc * 0.40, -arc * 0.45, arc * 0.30)
			elif melee_combo_idx == 1:
				heirloom_pivot.rotation = Vector3(0.32 - arc * 1.15, -0.28 - arc * 1.6, 0.18 + arc * 1.3)
				heirloom_pivot.position = Vector3(0.04 + arc * 0.24, -0.02 + arc * 0.14, -0.06 - arc * 0.26)
				if right_arm:
					right_arm.position = Vector3(arc * 0.20, arc * 0.12, -arc * 0.20)
					right_arm.rotation = Vector3(-arc * 0.35, -arc * 0.85, arc * 0.65)
				if left_arm:
					left_arm.position = Vector3(-0.26 + arc * 0.28, -0.14 + arc * 0.22, -0.10 - arc * 0.36)
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
				left_arm.position = left_arm.position.lerp(Vector3(-0.26, -0.14, -0.10), delta * 12.0)
				left_arm.rotation = left_arm.rotation.lerp(Vector3(0, 0, sin(player.bob_time * 0.5) * 0.08), delta * 12.0)
			if inspect_timer > 0.0 or sprinting:
				# Continuous Kunai / Butterfly Knife Spin
				var spin_t: float = float(Time.get_ticks_msec()) * 0.012
				heirloom_pivot.rotation = Vector3(spin_t, -0.25, 0.35)
			else:
				heirloom_pivot.rotation = heirloom_pivot.rotation.lerp(Vector3(0.32, -0.28, 0.18), delta * 12.0)
				heirloom_pivot.position = heirloom_pivot.position.lerp(Vector3(0.04, -0.02, -0.06), delta * 12.0)
	elif inspect_timer > 0.0:
		# Firearm 360 Showcase Inspect
		var ip: float = 1.0 - (inspect_timer / 3.2)
		target_rot.y = sin(ip * TAU) * 0.68
		target_rot.z = sin(ip * PI) * 0.42
		target_rot.x = 0.18 * sin(ip * PI)

	gun_rig.rotation = gun_rig.rotation.lerp(target_rot, delta * 16.0)

func try_fire(enemies: Array) -> void:
	if player == null or reload_timer > 0.0 or rechamber_timer > 0.0 or quick_melee_timer > 0.0:
		return

	self.enemies = enemies

	if PlayerState.active_slot == 2:
		_perform_heirloom_slash(enemies)
		return

	var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
	var wep: Dictionary = GameData.get_weapon_by_id(slot["weapon_id"])
	var wid: String = str(wep["id"])

	# Iconic Apex Charge Rifle (充能步枪 / 滋崩): Two-stage continuous tracking laser channel ("滋") -> explosive burst ("崩")
	if wid == "chargerifle":
		if is_charging_beam:
			return
		var now_cr: int = Time.get_ticks_msec()
		if now_cr - last_fire_ms < 1150:
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

	var rpm: float = float(wep["rpm"])
	if str(wep["id"]) == "rampage" and float(slot.get("charged", 0.0)) > 0.0:
		rpm *= 1.38

	var now: int = Time.get_ticks_msec()
	if now - last_fire_ms < int(60000.0 / rpm):
		return

	if int(slot["ammo"]) <= 0:
		start_reload()
		return

	slot["ammo"] = int(slot["ammo"]) - 1
	last_fire_ms = now
	AudioSynthesizer.play_gunshot(str(wep["cat"]))

	# Trigger Muzzle Flash, Recoil & Bolt Blowback
	kick_offset = Vector3(0, 0.012, 0.055)
	kick_rot = Vector3(0.065, randf_range(-0.02, 0.02), 0.0)
	bolt_back_offset = 0.095
	var v_rec: float = 0.032 if str(wep["cat"]) == "SNIPER" else (0.024 if str(wep["cat"]) == "SHOTGUN" else 0.011)
	player.add_camera_recoil(v_rec, randf_range(-0.006, 0.006), 0.012)

	_trigger_muzzle_flash_and_casing()

	# Rechambering animation for bolt-action snipers & lever-action shotgun
	if wid == "kraber" or wid == "sentinel" or wid == "peacekeeper":
		rechamber_total = 0.55 if wid != "kraber" else 0.85
		rechamber_timer = rechamber_total
		AudioSynthesizer.play_reload_step("lever_cock")

	# Hitscan + 3D Tracer Beam
	var cam := player.camera
	var origin: Vector3 = cam.global_position
	var fwd: Vector3 = -cam.global_transform.basis.z
	var spread: float = float(wep["ads_spread"]) if player.is_ads else float(wep["spread"])
	var pellets: int = int(wep["pellets"])

	var total_hit_dmg: int = 0
	var hit_bot: ApexBotAI = null
	var was_head: bool = false
	var hit_pos: Vector3 = origin + fwd * 120.0

	for p in range(pellets):
		var ray_dir: Vector3 = (fwd + cam.global_transform.basis.x * randf_range(-spread, spread) + cam.global_transform.basis.y * randf_range(-spread, spread)).normalized()
		for bot in enemies:
			if not is_instance_valid(bot) or bot.hp <= 0.0:
				continue
			var to_bot: Vector3 = (bot.global_position + Vector3(0, 1.28, 0)) - origin
			var dist: float = to_bot.length()
			if dist > 340.0:
				continue
			if ray_dir.angle_to(to_bot.normalized()) < (0.095 if dist < 25.0 else 0.055):
				var is_h: bool = (ray_dir.y > to_bot.normalized().y + 0.015)
				var d: int = int(wep["dmg"])
				if wid == "sentinel" and float(slot.get("charged", 0.0)) > 0.0:
					d = int(round(float(d) * 1.25))
				if is_h:
					d = int(round(float(d) * float(wep["head"])))
					was_head = true
				total_hit_dmg += d
				hit_bot = bot
				hit_pos = bot.global_position + Vector3(0, 1.35, 0)
				break

	_spawn_bullet_tracer(origin + Vector3(0, -0.1, 0) + fwd * 0.8, hit_pos, wep.get("accent", Color("#f97316")))

	if hit_bot != null and total_hit_dmg > 0:
		hit_bot.apply_damage(total_hit_dmg, was_head, str(wep["name"]))

	PlayerState.state_updated.emit()

func _perform_heirloom_slash(enemies: Array) -> void:
	if melee_swing_timer > 0.0:
		return
	melee_swing_timer = 0.40
	var is_heavy_finisher: bool = (melee_combo_idx == 2)
	AudioSynthesizer.play_melee_Whoosh(is_heavy_finisher)
	player.add_camera_recoil(0.018 if is_heavy_finisher else 0.008, 0.015 * (1.0 if melee_combo_idx % 2 == 0 else -1.0), 0.02)

	# Lunge forward slightly
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	player.velocity += Vector3(fwd.x, 0, fwd.z).normalized() * 6.5

	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	var h_info: Dictionary = leg.get("heirloom", {"name": "传家宝近战", "color": Color("#8b5cf6")})
	_spawn_melee_slash_wave(h_info.get("color", Color("#8b5cf6")))

	var dmg: int = 65 if is_heavy_finisher else 45
	_check_melee_hit(enemies, dmg, str(h_info.get("name", "传家宝")))
	melee_combo_idx = (melee_combo_idx + 1) % 3
	PlayerState.state_updated.emit()

func start_quick_melee(enemies: Array) -> void:
	if quick_melee_timer > 0.0 or reload_timer > 0.0:
		return
	quick_melee_timer = 0.42
	AudioSynthesizer.play_melee_Whoosh(false)
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	player.velocity += Vector3(fwd.x, 0.15, fwd.z).normalized() * 8.0
	player.add_camera_recoil(0.015, -0.015, 0.02)
	_check_melee_hit(enemies, 35, "近战重击 [V]")

func _check_melee_hit(enemies: Array, dmg: int, source_label: String) -> void:
	var origin: Vector3 = player.camera.global_position
	var fwd: Vector3 = -player.camera.global_transform.basis.z
	for bot in enemies:
		if not is_instance_valid(bot) or bot.hp <= 0.0:
			continue
		var to_bot: Vector3 = (bot.global_position + Vector3(0, 1.1, 0)) - origin
		if to_bot.length() <= 4.6 and fwd.angle_to(to_bot.normalized()) < 0.65:
			bot.apply_damage(dmg, false, source_label)
			bot.global_position += Vector3(fwd.x, 0, fwd.z).normalized() * 2.2
			break

func start_reload() -> void:
	if PlayerState.active_slot == 2 or reload_timer > 0.0:
		return
	_cancel_charge_beam()
	var slot: Dictionary = PlayerState.loadout[PlayerState.active_slot]
	var wep: Dictionary = GameData.get_weapon_by_id(slot["weapon_id"])
	if int(slot["ammo"]) >= int(slot["max_ammo"]):
		return
	is_empty_reload = (int(slot["ammo"]) <= 0)
	reload_total = float(wep["reload"]) * (1.0 if is_empty_reload else 0.82)
	if PlayerState.stim_timer > 0.0 or PlayerState.double_time_timer > 0.0:
		reload_total *= 0.78
	reload_timer = reload_total
	reload_step_mask = 0
	player.is_ads = false
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
		PlayerState.toast_pushed.emit("🔧 已切换武器开火模式", "info")

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
	mag_drop.global_position = player.camera.global_position + (-player.camera.global_transform.basis.z * 0.45) + Vector3(0, -0.25, 0)
	world_root.add_child(mag_drop)
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
	cyl.top_radius = 0.015
	cyl.bottom_radius = 0.015
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

	# Find target hit along forward ray
	var target_pos := origin + fwd * 260.0
	var hit_bot: ApexBotAI = null
	var was_head: bool = false
	for bot in enemies:
		if not is_instance_valid(bot) or bot.hp <= 0.0:
			continue
		var to_bot: Vector3 = (bot.global_position + Vector3(0, 1.25, 0)) - origin
		var dist: float = to_bot.length()
		if dist > 340.0:
			continue
		var angle: float = fwd.angle_to(to_bot.normalized())
		if angle < (0.095 if dist < 25.0 else 0.055):
			hit_bot = bot
			was_head = (fwd.y > to_bot.normalized().y + 0.012)
			target_pos = bot.global_position + Vector3(0, 1.35 if was_head else 1.15, 0)
			break

	var muzzle_pos: Vector3 = origin + fwd * 0.72 + Vector3(0, -0.09, 0)

	# Phase 1: "滋" tracking laser beam (0.0s to 0.70s)
	if charge_timer < 0.70:
		# Synthesize rising frequency laser whine ("ziiiiii...")
		AudioSynthesizer.play_charge_rifle_charge(charge_timer / 0.70)

		# Subtle high-frequency energetic weapon jitter and camera hum
		kick_offset += Vector3(randf_range(-0.0016, 0.0016), randf_range(-0.0016, 0.0016), 0.0)
		player.add_camera_recoil(0.001, randf_range(-0.0015, 0.0015), 0.002)

		# Continuous tick damage: every 0.14s (approx 4-5 ticks of 4 damage = ~16-20 total damage)
		if charge_timer - charge_last_tick >= 0.14:
			charge_last_tick = charge_timer
			if hit_bot != null:
				var tick_dmg: int = 6 if was_head else 4
				hit_bot.apply_damage(tick_dmg, was_head, "充能步枪 滋")
				_spawn_charge_impact_sparks(target_pos, Color("#ff6600"))
				PlayerState.state_updated.emit()

		# Update 3D continuous tracking laser beam
		_update_charge_beam_mesh(muzzle_pos, target_pos, false)

	# Phase 2: "崩" colossal explosive plasma blast (at 0.70s)
	elif not charge_beng_fired:
		charge_beng_fired = true
		last_fire_ms = Time.get_ticks_msec()
		var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
		slot["ammo"] = maxi(0, int(slot["ammo"]) - 1)

		# Thunderous explosive plasma blast audio!
		AudioSynthesizer.play_charge_rifle_blast()

		# Massive recoil kick
		player.add_camera_recoil(0.056, randf_range(-0.008, 0.008), 0.038)
		kick_offset = Vector3(0, 0.045, 0.16)
		kick_rot = Vector3(0.095, randf_range(-0.02, 0.02), 0.0)
		bolt_back_offset = 0.14
		_trigger_muzzle_flash_and_casing()

		# Update thick plasma blast beam
		_update_charge_beam_mesh(muzzle_pos, target_pos, true)
		_spawn_charge_impact_burst(target_pos)

		if hit_bot != null:
			var blast_dmg: int = 115 if was_head else 68
			hit_bot.apply_damage(blast_dmg, was_head, "充能步枪 崩💥")

		PlayerState.state_updated.emit()

	# Phase 3: Post-blast venting & cooldown
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
