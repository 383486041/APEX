extends Node3D
## MatchScene Controller (Godot 4.3 Pro Edition)
## Features:
## - Custom procedural AdsScopeOverlay drawing all 7 authentic Apex Optics + Bocek 3-Pin Bow Sight
## - Authentic Shotgun Pellet Hit Grid Indicator (Star-11, Line-8, Fig8-8, Triangle-3) & Precision Choke Brackets
## - Live Consumable Cast Progress Bar & Ring (Shield Battery / Cell / Syringe / MedKit / Phoenix Kit)
## - Interactive 3D Supply Bin & Loot Tick Looting: Opening a Supply Bin or Loot Tick spawns physical 3D items
##   (Weapons, Shield Batteries, Medkits, Ammo Bricks, Attachments, Armor Cores) on the bin tray / ground that can be individually picked up with [E]!
## - Live Player Behavior Recording ([F8] Toggle Record, [F9] Train AI from Player Trajectory)

const ApexInventoryUI = preload("res://scripts/ApexInventoryUI.gd")

class ScopeAndHitHUD extends Control:
	var is_ads: bool = false
	var optic_id: String = "2x_bruiser"
	var alt_zoom: bool = false
	var hit_timer: float = 0.0
	var dmg_timer: float = 0.0
	var crack_timer: float = 0.0
	var pellet_timer: float = 0.0
	var last_pellet_pattern: String = ""
	var last_pellet_hits: Array = []
	var last_pellet_head: bool = false
	var bow_draw_ratio: float = 0.0
	var choke_ratio: float = 0.0
	var last_cum_dmg: int = 0
	var last_single_dmg: int = 0
	var last_target_name: String = ""
	var last_is_head: bool = false
	var last_shield_tier: int = 2
	var last_cracked_tier: int = 2
	var target_dist_m: float = 28.0
	var is_threat_locked: bool = false

	func _process(delta: float) -> void:
		var dirty: bool = false
		if hit_timer > 0.0:
			hit_timer = maxf(0.0, hit_timer - delta)
			dirty = true
		if dmg_timer > 0.0:
			dmg_timer = maxf(0.0, dmg_timer - delta)
			dirty = true
		if crack_timer > 0.0:
			crack_timer = maxf(0.0, crack_timer - delta)
			dirty = true
		if pellet_timer > 0.0:
			pellet_timer = maxf(0.0, pellet_timer - delta)
			dirty = true
		if PlayerState.heal_cast_timer > 0.0 or bow_draw_ratio > 0.0 or choke_ratio > 0.0:
			dirty = true
		if dirty:
			queue_redraw()

	func get_tier_color(tier: int) -> Color:
		match tier:
			1: return Color("#f8fafc")
			2: return Color("#38bdf8")
			3: return Color("#c084fc")
			4: return Color("#fbbf24")
			5: return Color("#ff1e42")
			_: return Color("#ff5252")

	func _draw() -> void:
		var vp: Vector2 = get_viewport_rect().size
		var c: Vector2 = vp * 0.5
		var tier_col: Color = get_tier_color(last_shield_tier)
		var font: Font = ThemeDB.fallback_font

		# 1. ADS Optic Scope Housing & Illuminated Reticle
		if is_ads:
			if optic_id == "6x_kraber":
				var r: float = minf(vp.x, vp.y) * 0.42
				var mask_col := Color("#020305")
				var segs: int = 48

				var top_poly := PackedVector2Array()
				top_poly.append(Vector2(0, 0))
				top_poly.append(Vector2(vp.x, 0))
				top_poly.append(Vector2(vp.x, c.y))
				for i in range(segs + 1):
					var th: float = float(i) * PI / float(segs)
					top_poly.append(c + Vector2(cos(th) * r, -sin(th) * r))
				top_poly.append(Vector2(0, c.y))
				draw_colored_polygon(top_poly, mask_col)

				var bot_poly := PackedVector2Array()
				bot_poly.append(Vector2(0, c.y))
				for i in range(segs + 1):
					var th: float = PI - float(i) * PI / float(segs)
					bot_poly.append(c + Vector2(cos(th) * r, sin(th) * r))
				bot_poly.append(Vector2(vp.x, c.y))
				bot_poly.append(Vector2(vp.x, vp.y))
				bot_poly.append(Vector2(0, vp.y))
				draw_colored_polygon(bot_poly, mask_col)

				draw_arc(c, r, 0, TAU, 96, Color("#090d16"), 6.0)
				draw_arc(c, r - 3.0, 0, TAU, 96, Color("#1e293b"), 3.0)
				draw_arc(c, r - 6.0, 0, TAU, 96, Color("#0ea5e9", 0.35), 1.5)

				var cross_col := Color(0.92, 0.96, 1.0, 0.85)
				draw_line(Vector2(c.x - r + 24, c.y), Vector2(c.x - 18, c.y), cross_col, 1.5)
				draw_line(Vector2(c.x + 18, c.y), Vector2(c.x + r - 24, c.y), cross_col, 1.5)
				draw_line(Vector2(c.x, c.y - r + 24), Vector2(c.x, c.y - 18), cross_col, 1.5)
				draw_line(Vector2(c.x, c.y + 18), Vector2(c.x, c.y + r - 24), cross_col, 1.5)

				for m in range(1, 6):
					var dy: float = float(m) * 36.0
					var w_tick: float = 12.0 + float(m) * 3.5
					draw_line(Vector2(c.x - w_tick, c.y + dy), Vector2(c.x + w_tick, c.y + dy), cross_col, 1.5)
					if m >= 2 and font != null:
						draw_string(font, Vector2(c.x + w_tick + 6, c.y + dy + 4), str(m), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#38bdf8"))
					var dx: float = float(m) * 36.0
					draw_line(Vector2(c.x - dx, c.y - 6), Vector2(c.x - dx, c.y + 6), cross_col, 1.5)
					draw_line(Vector2(c.x + dx, c.y - 6), Vector2(c.x + dx, c.y + 6), cross_col, 1.5)

				draw_arc(c, 10.0, 0, TAU, 32, Color("#ff1e42"), 2.0)
				draw_circle(c, 2.8, Color("#ff1e42"))

				if font != null:
					var zoom_str: String = "10X" if alt_zoom else "6X"
					var dist_str: String = "%.0f M" % maxf(12.0, target_dist_m)
					draw_string(font, Vector2(c.x - r + 35, c.y - 18), "RANGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#94a3b8"))
					draw_string(font, Vector2(c.x - r + 35, c.y + 4), dist_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#38bdf8"))
					draw_string(font, Vector2(c.x + r - 105, c.y - 18), "MAGNIFICATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#94a3b8"))
					draw_string(font, Vector2(c.x + r - 105, c.y + 4), "%s [SHIFT]" % zoom_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#f59e0b"))

			elif optic_id == "3x_ranger":
				var gcol := Color("#22c55e")
				draw_line(Vector2(c.x - 64, c.y), Vector2(c.x - 12, c.y), gcol, 2.2)
				draw_line(Vector2(c.x + 12, c.y), Vector2(c.x + 64, c.y), gcol, 2.2)
				draw_line(Vector2(c.x, c.y + 12), Vector2(c.x, c.y + 76), gcol, 2.2)
				draw_line(Vector2(c.x - 10, c.y + 26), Vector2(c.x + 10, c.y + 26), gcol, 2.0)
				draw_line(Vector2(c.x - 14, c.y + 46), Vector2(c.x + 14, c.y + 46), gcol, 2.0)
				draw_line(Vector2(c.x - 18, c.y + 64), Vector2(c.x + 18, c.y + 64), gcol, 2.0)
				draw_line(c, c + Vector2(-8, 9), Color("#ff1e42"), 2.8)
				draw_line(c, c + Vector2(8, 9), Color("#ff1e42"), 2.8)
				draw_circle(c, 2.2, Color("#ff1e42"))

			elif optic_id == "2x_bruiser":
				var chev := Color("#ff1e42")
				draw_line(c, c + Vector2(-12, 13), chev, 3.2)
				draw_line(c, c + Vector2(12, 13), chev, 3.2)
				draw_circle(c + Vector2(0, 22), 2.2, chev)
				draw_line(Vector2(c.x - 38, c.y), Vector2(c.x - 22, c.y), Color(1.0, 0.2, 0.3, 0.75), 2.0)
				draw_line(Vector2(c.x + 22, c.y), Vector2(c.x + 38, c.y), Color(1.0, 0.2, 0.3, 0.75), 2.0)

			elif optic_id == "1x_holo":
				var hcol := Color("#ff2a2a")
				draw_arc(c, 24.0, 0, TAU, 56, hcol, 2.2)
				draw_line(Vector2(c.x - 32, c.y), Vector2(c.x - 24, c.y), hcol, 2.4)
				draw_line(Vector2(c.x + 24, c.y), Vector2(c.x + 32, c.y), hcol, 2.4)
				draw_line(Vector2(c.x, c.y - 32), Vector2(c.x, c.y - 24), hcol, 2.4)
				draw_line(Vector2(c.x, c.y + 24), Vector2(c.x, c.y + 32), hcol, 2.4)
				draw_circle(c, 2.6, hcol)

			elif optic_id == "2x_4x_aog":
				var acol := Color("#ef4444")
				draw_arc(c, 34.0, 0, TAU, 64, acol, 1.8)
				draw_arc(c, 16.0, 0, TAU, 48, acol, 1.5)
				draw_line(Vector2(c.x - 46, c.y), Vector2(c.x - 16, c.y), acol, 1.8)
				draw_line(Vector2(c.x + 16, c.y), Vector2(c.x + 46, c.y), acol, 1.8)
				draw_line(Vector2(c.x, c.y + 16), Vector2(c.x, c.y + 60), acol, 1.8)
				draw_circle(c, 2.4, acol)

			elif optic_id == "1x_threat":
				var tcol := Color("#ff1e42") if is_threat_locked else Color("#ef4444")
				var box_sz: float = 38.0 if is_threat_locked else 34.0
				var br_len: float = 9.0
				draw_line(c + Vector2(-box_sz, -box_sz), c + Vector2(-box_sz + br_len, -box_sz), tcol, 2.2)
				draw_line(c + Vector2(-box_sz, -box_sz), c + Vector2(-box_sz, -box_sz + br_len), tcol, 2.2)
				draw_line(c + Vector2(box_sz, -box_sz), c + Vector2(box_sz - br_len, -box_sz), tcol, 2.2)
				draw_line(c + Vector2(box_sz, -box_sz), c + Vector2(box_sz, -box_sz + br_len), tcol, 2.2)
				draw_line(c + Vector2(-box_sz, box_sz), c + Vector2(-box_sz + br_len, box_sz), tcol, 2.2)
				draw_line(c + Vector2(-box_sz, box_sz), c + Vector2(-box_sz, box_sz - br_len), tcol, 2.2)
				draw_line(c + Vector2(box_sz, box_sz), c + Vector2(box_sz - br_len, box_sz), tcol, 2.2)
				draw_line(c + Vector2(box_sz, box_sz), c + Vector2(box_sz, box_sz - br_len), tcol, 2.2)
				draw_circle(c, 2.2, tcol)
			else:
				draw_circle(c, 5.0, Color(1.0, 0.15, 0.15, 0.28))
				draw_circle(c, 2.6, Color("#ff1e42"))

		# 1b. Bocek Compound Bow Draw Tension Arc & 3-Pin Sight
		if bow_draw_ratio > 0.0:
			var b_rad: float = lerpf(42.0, 18.0, bow_draw_ratio)
			var b_col: Color = Color("#22c55e") if bow_draw_ratio >= 0.95 else Color("#f59e0b")
			draw_arc(c, b_rad, -PI * 0.5, -PI * 0.5 + TAU * bow_draw_ratio, 32, b_col, 2.8)
			draw_circle(c, 2.5, b_col)
			draw_circle(c + Vector2(0, 12), 1.8, Color("#f59e0b"))
			draw_circle(c + Vector2(0, 24), 1.8, Color("#ef4444"))

		# 1c. Peacekeeper / Triple Take ADS Precision Choke Convergence Brackets
		if choke_ratio > 0.02:
			var ch_dist: float = lerpf(46.0, 14.0, choke_ratio)
			var ch_col: Color = Color("#38bdf8") if choke_ratio >= 0.95 else Color(0.22, 0.74, 0.98, 0.75)
			for side_x in [-1.0, 1.0]:
				draw_line(c + Vector2(side_x * ch_dist, -14), c + Vector2(side_x * (ch_dist - side_x * 6), 0), ch_col, 2.2)
				draw_line(c + Vector2(side_x * (ch_dist - side_x * 6), 0), c + Vector2(side_x * ch_dist, 14), ch_col, 2.2)

		# 1d. Authentic Apex Shotgun Pellet Hit Grid Feedback (Star-11 / Line-8 / Fig8-8 / Triangle-3)
		if pellet_timer > 0.0 and not last_pellet_hits.is_empty():
			var p_alpha: float = clampf(pellet_timer / 0.55, 0.0, 1.0)
			var pts: Array = GameData.get_pellet_pattern_offsets(last_pellet_pattern, last_pellet_hits.size())
			var grid_scale: float = 28.0
			for pi in range(mini(pts.size(), last_pellet_hits.size())):
				var p_off: Vector2 = pts[pi]
				var dot_pos: Vector2 = c + Vector2(p_off.x * grid_scale, -p_off.y * grid_scale)
				var did_hit: bool = bool(last_pellet_hits[pi])
				if did_hit:
					var h_col: Color = Color(1.0, 0.88, 0.15, p_alpha) if last_pellet_head else Color(1.0, 0.18, 0.24, p_alpha)
					draw_circle(dot_pos, 3.8, h_col)
					draw_arc(dot_pos, 4.5, 0, TAU, 12, Color(1, 1, 1, p_alpha * 0.8), 1.0)
				else:
					draw_circle(dot_pos, 2.4, Color(0.65, 0.72, 0.82, p_alpha * 0.45))

		# 1e. Live Consumable Cast Progress Bar & Ring (打药 / 使用电池进度条)
		if PlayerState.heal_cast_timer > 0.0 and font != null:
			var h_total: float = maxf(0.1, PlayerState.heal_cast_total)
			var h_prog: float = 1.0 - clampf(PlayerState.heal_cast_timer / h_total, 0.0, 1.0)
			var h_id: String = PlayerState.active_heal_id
			var is_bat: bool = (h_id == "shield_battery" or h_id == "shield_cell" or h_id == "phoenix_kit")
			var h_col: Color = Color("#38bdf8") if is_bat else Color("#22c55e")
			if h_id == "phoenix_kit":
				h_col = Color("#a855f7")

			var ring_c := Vector2(c.x, c.y + 95.0)
			draw_circle(ring_c, 28.0, Color(0.04, 0.07, 0.12, 0.88))
			draw_arc(ring_c, 28.0, -PI * 0.5, -PI * 0.5 + TAU * h_prog, 36, h_col, 4.0)
			var time_str := "%.1fs" % PlayerState.heal_cast_timer
			var tw: float = font.get_string_size(time_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 14).x
			draw_string(font, Vector2(ring_c.x - tw * 0.5, ring_c.y + 5.0), time_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

			var h_title := "正在使用【%s】..." % GameData.get_consumable_name(h_id)
			var htw: float = font.get_string_size(h_title, HORIZONTAL_ALIGNMENT_CENTER, -1, 14).x
			draw_string(font, Vector2(ring_c.x - htw * 0.5, ring_c.y + 48.0), h_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, h_col)

		# 2. Center Hitmarker X Flash
		if hit_timer > 0.0:
			var hm_col: Color = Color("#fde047") if last_is_head else tier_col
			var d1: float = 7.0
			var d2: float = 18.0 if last_is_head else 15.0
			var w_hm: float = 3.0 if last_is_head else 2.2
			draw_line(c + Vector2(-d2, -d2), c + Vector2(-d1, -d1), hm_col, w_hm)
			draw_line(c + Vector2(d1, -d1), c + Vector2(d2, -d2), hm_col, w_hm)
			draw_line(c + Vector2(-d2, d2), c + Vector2(-d1, d1), hm_col, w_hm)
			draw_line(c + Vector2(d1, d1), c + Vector2(d2, d2), hm_col, w_hm)

		# 3. Authentic Apex Broken Shield Crack Icon
		if crack_timer > 0.0:
			var prog: float = 1.0 - (crack_timer / 0.70)
			var cr_alpha: float = clampf(crack_timer / 0.70, 0.0, 1.0)
			var sc := c + Vector2(0, -62)
			var split: float = prog * 14.0
			var cracked_col: Color = get_tier_color(last_cracked_tier) if last_cracked_tier > 0 else Color("#38bdf8")
			var icon_col := Color(cracked_col.r, cracked_col.g, cracked_col.b, cr_alpha)
			var glow_col := Color(1.0, 1.0, 1.0, cr_alpha)

			var left_poly := PackedVector2Array([
				Vector2(sc.x - split - 2, sc.y - 18),
				Vector2(sc.x - split - 18, sc.y - 14),
				Vector2(sc.x - split - 22, sc.y - 2),
				Vector2(sc.x - split - 16, sc.y + 12),
				Vector2(sc.x - split - 2, sc.y + 20),
				Vector2(sc.x - split - 8, sc.y + 8),
				Vector2(sc.x - split - 3, sc.y - 2),
				Vector2(sc.x - split - 7, sc.y - 8),
				Vector2(sc.x - split - 2, sc.y - 18)
			])
			draw_colored_polygon(left_poly, Color(cracked_col.r, cracked_col.g, cracked_col.b, cr_alpha * 0.45))
			draw_polyline(left_poly, icon_col, 2.5)

			var right_poly := PackedVector2Array([
				Vector2(sc.x + split + 2, sc.y - 18),
				Vector2(sc.x + split + 18, sc.y - 14),
				Vector2(sc.x + split + 22, sc.y - 2),
				Vector2(sc.x + split + 16, sc.y + 12),
				Vector2(sc.x + split + 2, sc.y + 20),
				Vector2(sc.x + split + 8, sc.y + 8),
				Vector2(sc.x + split + 3, sc.y - 2),
				Vector2(sc.x + split + 7, sc.y - 8),
				Vector2(sc.x + split + 2, sc.y - 18)
			])
			draw_colored_polygon(right_poly, Color(cracked_col.r, cracked_col.g, cracked_col.b, cr_alpha * 0.45))
			draw_polyline(right_poly, icon_col, 2.5)

			draw_line(Vector2(sc.x - split - 2, sc.y - 14), Vector2(sc.x, sc.y - 4), glow_col, 2.5)
			draw_line(Vector2(sc.x, sc.y - 4), Vector2(sc.x + split + 2, sc.y + 4), glow_col, 2.5)
			draw_line(Vector2(sc.x + split + 2, sc.y + 4), Vector2(sc.x, sc.y + 16), glow_col, 2.5)

			var cr_rad: float = 24.0 + prog * 48.0
			draw_arc(sc, cr_rad, 0, TAU, 28, Color(cracked_col.r, cracked_col.g, cracked_col.b, cr_alpha * 0.7), 2.5)

			if font != null:
				var cr_txt: String = "⚡ 破 甲！ ⚡"
				var f_sz: int = 15
				var txt_sz := font.get_string_size(cr_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, f_sz).x
				var t_pos := Vector2(sc.x - txt_sz * 0.5, sc.y + 36)
				draw_string(font, t_pos + Vector2(1, 1), cr_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, Color(0, 0, 0, cr_alpha * 0.8))
				draw_string(font, t_pos, cr_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, icon_col)

var player: PlayerController
var weapon_ctrl: WeaponController
var ability_sys: AbilitySystem
var enemies: Array = []
var interactables: Array = []
var ring_mesh: MeshInstance3D

# HUD Elements
var authentic_hud: ApexAuthenticHUD
var screen_fx_rect: ColorRect
var scope_hit_hud: ScopeAndHitHUD
var inventory_ui: ApexInventoryUI
var kill_banner: PanelContainer
var kill_banner_title: Label
var kill_banner_sub: Label
var kill_banner_tween: Tween
var hud_reload_lbl: Label
var hud_toast_lbl: Label

# Battle Royale Match State & Flow
var ring_timer: float = 65.0
var ring_shrink_timer: float = 0.0
var ring_target_radius: float = 290.0
var ring_prev_radius: float = 290.0
var match_time: float = 0.0
var storm_damage_timer: float = 0.0
var victory_achieved: bool = false
var victory_panel: PanelContainer
var victory_stats_lbl: Label
var simulated_skirmish_timer: float = 6.5

var prev_keys: Dictionary = {}

func _ready() -> void:
	PlayerState.reset_for_match()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#131c2e")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#3b4c66")
	e.ambient_light_energy = 1.1
	e.fog_enabled = true
	e.fog_light_color = Color("#162032")
	e.fog_density = 0.0018
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.position = Vector3(120, 220, 90)
	sun.rotation_degrees = Vector3(-52, 35, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.25

	var built: Dictionary = CanyonWorldBuilder.build_canyon_world(self)
	interactables = built["interactables"]
	ring_mesh = built["ring_mesh"]

	player = PlayerController.new()
	player.name = "PlayerController"
	player.position = Vector3(0, 2.0, 0)
	add_child(player)

	weapon_ctrl = WeaponController.new()
	weapon_ctrl.player = player
	weapon_ctrl.world_root = self
	player.weapon_ctrl = weapon_ctrl
	add_child(weapon_ctrl)

	_spawn_enemies()
	weapon_ctrl.enemies = enemies

	ability_sys = AbilitySystem.new()
	ability_sys.player = player
	ability_sys.world_root = self
	ability_sys.enemies = enemies
	add_child(ability_sys)

	_build_hud()
	PlayerState.state_updated.connect(_refresh_hud)
	PlayerState.toast_pushed.connect(_on_toast_pushed)
	PlayerState.killfeed_pushed.connect(_on_killfeed_pushed)
	PlayerState.hit_feedback_pushed.connect(_on_hit_feedback_pushed)
	PlayerState.shotgun_pellet_feedback_pushed.connect(_on_shotgun_pellet_feedback_pushed)
	PlayerState.floating_damage_spawned.connect(_on_floating_damage_spawned)
	PlayerState.enemy_eliminated.connect(_on_enemy_eliminated)
	PlayerState.deathbox_spawn_requested.connect(_on_deathbox_spawn_requested)
	_refresh_hud()

	# Spawn authentic MMzi-beng-gou deathbox directly in front of the player
	_on_deathbox_spawn_requested(Vector3(0.5, 0.0, -3.8), "MMzi-beng-gou", 2, "莫桑比克")

	var all_args: Array = OS.get_cmdline_args()
	all_args.append_array(OS.get_cmdline_user_args())
	for arg in all_args:
		if arg == "--test-inventory":
			get_tree().create_timer(0.2).timeout.connect(_run_inventory_diagnostics)
		elif arg == "--test-victory":
			get_tree().create_timer(0.2).timeout.connect(_run_victory_diagnostics)

func _spawn_enemies() -> void:
	var count: int = 12 if PlayerState.selected_mode_id == "firing_range" else 21
	var tier_cycle := [1, 2, 3, 4, 5]
	for i in range(count):
		var leg: Dictionary = GameData.LEGENDS[i % GameData.LEGENDS.size()]
		var bot := ApexBotAI.new()
		var pos: Vector3
		if PlayerState.selected_mode_id == "firing_range":
			pos = Vector3((float(i % 6) - 2.5) * 6.5, 0.0, -25.0 - float(i / 6) * 12.0)
		else:
			var poi: Dictionary = GameData.MAP_POIS[i % GameData.MAP_POIS.size()]
			var p2: Vector2 = poi["pos"]
			pos = Vector3(p2.x + randf_range(-8.0, 8.0), 0.0, p2.y + randf_range(-8.0, 8.0))
		add_child(bot)
		var evo_lv: int = tier_cycle[i % tier_cycle.size()]
		var squad_id: int = (i / 3) + 2 if PlayerState.selected_mode_id != "firing_range" else 99
		bot.setup(leg, pos, "%s #%d" % [str(leg["name"]), i + 1], evo_lv, squad_id)
		enemies.append(bot)

func _is_key_just_pressed(k: int) -> bool:
	var cur: bool = Input.is_key_pressed(k)
	var prev: bool = prev_keys.get(k, false)
	prev_keys[k] = cur
	return cur and not prev

func _process(delta: float) -> void:
	match_time += delta
	if PlayerState.selected_mode_id != "firing_range":
		if ring_shrink_timer > 0.0:
			ring_shrink_timer -= delta
			var p: float = 1.0 - clampf(ring_shrink_timer / 25.0, 0.0, 1.0)
			PlayerState.ring_radius = lerpf(ring_prev_radius, ring_target_radius, p)
			if is_instance_valid(ring_mesh):
				ring_mesh.scale = Vector3(PlayerState.ring_radius, 1.0, PlayerState.ring_radius)
			if ring_shrink_timer <= 0.0:
				_on_toast_pushed("⭕ 第 %d 阶段毒圈收缩完毕！等待下一次收圈！" % PlayerState.ring_stage, "warn")
		else:
			ring_timer -= delta
			if ring_timer <= 0.0:
				PlayerState.ring_stage += 1
				ring_prev_radius = PlayerState.ring_radius
				var next_radii := [210.0, 135.0, 75.0, 30.0, 10.0]
				var r_idx: int = mini(PlayerState.ring_stage - 2, next_radii.size() - 1)
				ring_target_radius = next_radii[r_idx]
				ring_shrink_timer = 25.0
				ring_timer = 65.0
				AudioSynthesizer.play_shield_crack()
				_on_toast_pushed("⚠️ 警告：第 %d 阶段毒圈正在收缩至 %.0fm！请立即向安全区撤离！" % [PlayerState.ring_stage, ring_target_radius], "warn")

		var p_dist: float = player.global_position.length()
		if p_dist > PlayerState.ring_radius:
			screen_fx_rect.color = Color(1.0, 0.35, 0.0, 0.28)
			storm_damage_timer -= delta
			if storm_damage_timer <= 0.0:
				storm_damage_timer = 1.0
				PlayerState.hp = maxf(1.0, PlayerState.hp - 8.0)
				AudioSynthesizer.play_flesh_hit(false)
				_on_toast_pushed("⚠️ 毒圈辐射警报！正在持续扣除生命值！", "warn")
				PlayerState.state_updated.emit()

		if not victory_achieved and not PlayerState.match_ended:
			var living_bots: int = 0
			for e in enemies:
				if is_instance_valid(e) and e.visible and e.hp > 0.0:
					living_bots += 1
			var min_players: int = living_bots + 3
			if PlayerState.players_alive > min_players:
				var rate_mult: float = 1.0 + float(PlayerState.ring_stage - 1) * 0.45
				if ring_shrink_timer > 0.0:
					rate_mult *= 1.8
				simulated_skirmish_timer -= delta * rate_mult
				if simulated_skirmish_timer <= 0.0:
					simulated_skirmish_timer = randf_range(5.5, 9.5)
					PlayerState.players_alive -= 1
					var active_bot_squads: int = int(ceil(float(living_bots) / 3.0))
					var calc_squads: int = int(ceil(float(PlayerState.players_alive) / 3.0))
					PlayerState.squads_alive = maxi(active_bot_squads + 1, calc_squads)
					_push_simulated_skirmish()
					PlayerState.state_updated.emit()

		if not victory_achieved and (PlayerState.players_alive <= 3 or _check_all_enemies_dead()):
			victory_achieved = true
			_trigger_victory_screen()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not PlayerState.ui_modal_open and not PlayerState.inventory_open:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if PlayerState.heal_cast_timer > 0.0:
				# Firing cancels active consumable cast
				PlayerState.heal_cast_timer = 0.0
				_on_toast_pushed("⚠️ 开火打断了恢复品使用！", "warn")
			else:
				weapon_ctrl.try_fire(enemies)

	if _is_key_just_pressed(KEY_TAB) or _is_key_just_pressed(KEY_I):
		if is_instance_valid(inventory_ui):
			if inventory_ui.visible:
				inventory_ui.close()
			else:
				inventory_ui.open()
	elif _is_key_just_pressed(KEY_1):
		PlayerState.active_slot = 0
		weapon_ctrl.reload_timer = 0.0
		player.rebuild_viewmodel()
		_refresh_hud()
	elif _is_key_just_pressed(KEY_2):
		PlayerState.active_slot = 1
		weapon_ctrl.reload_timer = 0.0
		player.rebuild_viewmodel()
		_refresh_hud()
	elif _is_key_just_pressed(KEY_3):
		PlayerState.active_slot = 2
		weapon_ctrl.reload_timer = 0.0
		player.rebuild_viewmodel()
		AudioSynthesizer.play_melee_Whoosh(true)
		var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
		_on_toast_pushed("🗡️ 已拔出神话传家宝：【%s】！左键三段挥砍，按 N 转刀检视！" % str(leg["heirloom"]["name"]), "evo")
		_refresh_hud()
	elif _is_key_just_pressed(KEY_O):
		if PlayerState.active_slot != 2:
			var slot: Dictionary = PlayerState.loadout[PlayerState.active_slot]
			var cur_op: String = str(slot.get("optic", "2x_bruiser"))
			var idx: int = 0
			for oi in range(GameData.OPTICS.size()):
				if GameData.OPTICS[oi]["id"] == cur_op:
					idx = (oi + 1) % GameData.OPTICS.size()
					break
			slot["optic"] = GameData.OPTICS[idx]["id"]
			PlayerState.scope_alt_zoom = false
			player.rebuild_viewmodel()
			AudioSynthesizer.play_reload_step("lever_cock")
			_on_toast_pushed("🔭 已切换瞄准镜：【%s】 (右键开镜查看专属分划板)" % str(GameData.OPTICS[idx]["name"]), "info")
			_refresh_hud()
	elif _is_key_just_pressed(KEY_SHIFT) and player.is_ads:
		PlayerState.scope_alt_zoom = not PlayerState.scope_alt_zoom
		AudioSynthesizer.play_reload_step("lever_cock")
	elif _is_key_just_pressed(KEY_R):
		weapon_ctrl.start_reload()
	elif _is_key_just_pressed(KEY_V):
		weapon_ctrl.start_quick_melee(enemies)
	elif _is_key_just_pressed(KEY_N):
		weapon_ctrl.start_inspect()
	elif _is_key_just_pressed(KEY_B):
		weapon_ctrl.charge_active_weapon()
	elif _is_key_just_pressed(KEY_Q):
		ability_sys.use_tactical()
	elif _is_key_just_pressed(KEY_Z):
		ability_sys.use_ultimate()
	elif _is_key_just_pressed(KEY_4):
		ability_sys.start_heal_item()
	elif _is_key_just_pressed(KEY_H):
		var order := ["shield_battery", "shield_cell", "med_kit", "syringe", "phoenix_kit"]
		var idx: int = (order.find(PlayerState.selected_heal_id) + 1) % order.size()
		PlayerState.selected_heal_id = order[idx]
		var hname: String = GameData.get_consumable_name(PlayerState.selected_heal_id)
		var hcnt: int = int(PlayerState.consumables.get(PlayerState.selected_heal_id, 0))
		PlayerState.state_updated.emit()
		_on_toast_pushed("➕ 已切换恢复品槽位：【%s (剩余 x%d)】 (按 4 使用，带完整打药/打电动作)" % [hname, hcnt], "info")
	elif _is_key_just_pressed(KEY_G):
		ability_sys.throw_ordnance()
	elif _is_key_just_pressed(KEY_E):
		_try_interact()
	elif _is_key_just_pressed(KEY_F8):
		BehaviorRecorder.toggle_recording()
	elif _is_key_just_pressed(KEY_F9):
		BehaviorRecorder.train_ai_from_records()
		BehaviorRecorder.use_imitation_ai = true

	# Hold E progress handling for deathbox
	var near_it: Dictionary = _find_nearest_interactable()
	if not near_it.is_empty() and str(near_it.get("type", "")) == "deathbox":
		if Input.is_key_pressed(KEY_E):
			if is_instance_valid(authentic_hud):
				authentic_hud.hold_progress += delta / 0.35
				if authentic_hud.hold_progress >= 1.0:
					authentic_hud.hold_progress = 0.0
					_try_interact()
		else:
			if is_instance_valid(authentic_hud):
				authentic_hud.hold_progress = 0.0
	elif is_instance_valid(authentic_hud):
		authentic_hud.hold_progress = 0.0

	if _is_key_just_pressed(KEY_F1):
		var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
		var upg: Dictionary = leg["upgrades_lv2"][0]
		PlayerState.chosen_upgrades["lv2"] = str(upg["id"])
		AudioSynthesizer.play_evo_level_up()
		_on_toast_pushed("✨ 已激活蓝甲天赋分支 A：【%s】" % str(upg["name"]), "evo")
	elif _is_key_just_pressed(KEY_F2):
		var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
		var upg: Dictionary = leg["upgrades_lv3"][0]
		PlayerState.chosen_upgrades["lv3"] = str(upg["id"])
		AudioSynthesizer.play_evo_level_up()
		_on_toast_pushed("✨ 已激活紫甲天赋分支 B：【%s】" % str(upg["name"]), "evo")
	elif _is_key_just_pressed(KEY_ESCAPE):
		if is_instance_valid(inventory_ui) and inventory_ui.visible:
			inventory_ui.close()
		elif Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			_on_toast_pushed("🖱️ 鼠标已解锁（点击画面重新锁定准星，或点击右上角返回大厅）", "info")
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	_update_realtime_hud()

func _try_interact() -> void:
	var p_pos: Vector3 = player.global_position
	for zp in ability_sys.ziplines:
		if p_pos.distance_to(zp["start"]) < 5.0 or p_pos.distance_to(zp["end"]) < 5.0:
			player.start_zipline(zp["start"], zp["end"])
			return

	var best: Dictionary = _find_nearest_interactable()
	if best.is_empty():
		return
	var itype: String = str(best.get("type", ""))
	if itype == "weapon_rack":
		var wid: String = str(best["weapon_id"])
		var wep: Dictionary = GameData.get_weapon_by_id(wid)
		var target_slot: int = 0 if PlayerState.active_slot == 2 else PlayerState.active_slot
		PlayerState.active_slot = target_slot
		PlayerState.loadout[target_slot] = {
			"weapon_id": wid,
			"ammo": int(wep["mag"]),
			"max_ammo": int(wep["mag"]),
			"optic": "6x_kraber" if str(wep["cat"]) == "SNIPER" else "2x_bruiser",
			"charged": 0.0
		}
		weapon_ctrl.reload_timer = 0.0
		player.rebuild_viewmodel()
		AudioSynthesizer.play_reload_step("bolt_slap")
		_on_toast_pushed("🔫 已装备高精度 3D 武器：【%s】 [%s]" % [str(wep["name"]), str(wep["cat"])], "evo")
		_refresh_hud()
	elif itype == "supply_bin" and not bool(best.get("opened", false)):
		best["opened"] = true
		AudioSynthesizer.play_supply_bin_open()
		if is_instance_valid(best["node"]):
			var lid_p: Node3D = best["node"].get_node_or_null("LidPivot")
			if lid_p:
				var tw := create_tween()
				tw.tween_property(lid_p, "rotation:x", -1.25, 0.38)
			_spawn_supply_bin_loot_items(best["node"].global_position, str(best.get("bin_type", "normal")))
		PlayerState.add_damage_and_evo(50)
		_on_toast_pushed("📦 补给仓已开启！内部物资已生成在托盘上，对准物品按 [E] 即可自由拾取！", "evo")
		_refresh_hud()
	elif itype == "loot_tick" and not bool(best.get("opened", false)):
		best["opened"] = true
		AudioSynthesizer.play_loot_tick_open()
		if is_instance_valid(best["node"]):
			var tb: Node3D = best["node"].get_node_or_null("TickBody")
			if tb:
				var tw := create_tween()
				tw.tween_property(tb, "scale", Vector3(1.5, 1.5, 1.5), 0.18)
				tw.tween_property(tb, "scale", Vector3(0.05, 0.05, 0.05), 0.22)
			_spawn_loot_tick_items(best["node"].global_position, int(best.get("rarity", 4)))
		PlayerState.heirloom_shards = 150
		_on_toast_pushed("💎 战利品箱机器人已击碎！高阶红甲/金枪/凤凰包已爆出在地面，按 [E] 拾取！", "evo")
		_refresh_hud()
	elif itype == "jump_tower":
		AudioSynthesizer.play_ability("jumppad")
		player.global_position.y = 92.0
		player.is_skydiving = true
		_on_toast_pushed("🦅 已搭乘跳伞塔升入高空！按 W 控制方向滑翔重部署！", "evo")
	elif itype == "dropped_loot":
		var ldata: Dictionary = best.get("loot_data", {})
		var lkind: String = str(ldata.get("type", ""))
		if lkind == "armor":
			var new_lv: int = int(ldata.get("tier", 4))
			PlayerState.evo_level = maxi(PlayerState.evo_level, new_lv)
			var tinfo: Dictionary = GameData.get_evo_tier(PlayerState.evo_level)
			PlayerState.max_shield = float(tinfo["max_shield"])
			PlayerState.shield = PlayerState.max_shield
			AudioSynthesizer.play_evo_level_up()
			_on_toast_pushed("🛡️ 已拾取【Lv.%d %s】！护盾已充能至 %d！" % [new_lv, str(tinfo["name"]), int(PlayerState.max_shield)], "evo")
		else:
			PlayerState.add_loot_item(ldata)
			AudioSynthesizer.play_reload_step("mag_in")
			_on_toast_pushed("📦 已拾取物资：【%s】！" % str(best.get("name", "战利品")), "evo")
		if is_instance_valid(best.get("node")):
			best["node"].queue_free()
		interactables.erase(best)
		_refresh_hud()
	elif itype == "deathbox":
		var dbox_data: Dictionary = best.get("data", {})
		if not dbox_data.is_empty():
			inventory_ui.open_deathbox(dbox_data)
			_on_toast_pushed("📦 正在搜刮【%s】的死亡之箱！点击物品直接拾取或点击【⚡一键全拾取】！" % str(dbox_data.get("victim_name", "")), "evo")
	elif itype == "dropped_weapon":
		var w_dict: Dictionary = best.get("weapon_data", {})
		var wid: String = str(w_dict.get("weapon_id", "empty"))
		if wid != "empty" and wid != "":
			var wep: Dictionary = GameData.get_weapon_by_id(wid)
			var target_slot: int = clampi(PlayerState.active_slot, 0, 1)
			if str(PlayerState.loadout[0].get("weapon_id", "empty")) == "empty":
				target_slot = 0
			elif str(PlayerState.loadout[1].get("weapon_id", "empty")) == "empty":
				target_slot = 1

			var old_slot: Dictionary = PlayerState.loadout[target_slot]
			var old_wid: String = str(old_slot.get("weapon_id", "empty"))

			PlayerState.loadout[target_slot] = w_dict.duplicate(true)
			PlayerState.active_slot = target_slot

			if old_wid != "empty" and old_wid != "":
				var p_fwd: Vector3 = -player.global_transform.basis.z.normalized()
				var drop_p: Vector3 = player.global_position + p_fwd * 1.5 + Vector3(0, 0.35, 0)
				_spawn_dropped_weapon(old_slot, drop_p)

			if is_instance_valid(best.get("node")):
				best["node"].queue_free()
			interactables.erase(best)

			weapon_ctrl.reload_timer = 0.0
			player.rebuild_viewmodel()
			AudioSynthesizer.play_reload_step("bolt_slap")
			_on_toast_pushed("🔫 已拾取武器：【%s】！" % str(wep.get("name", wid)), "evo")
			_refresh_hud()
			return
	elif itype == "dropped_attachment":
		var att_k: String = str(best.get("att_type", ""))
		var tier: int = int(best.get("tier", 1))
		var op_id: String = str(best.get("optic_id", ""))
		var equipped: bool = false
		var cur_w_idx: int = clampi(PlayerState.active_slot, 0, 1)
		var cur_wep: Dictionary = PlayerState.loadout[cur_w_idx]

		if cur_wep.get("weapon_id", "empty") != "empty":
			if att_k == "optic" and op_id != "":
				cur_wep["optic"] = op_id
				equipped = true
			elif att_k != "optic" and int(cur_wep.get(att_k, 0)) < tier:
				cur_wep[att_k] = tier
				if att_k == "mag":
					cur_wep["max_ammo"] = GameData.get_weapon_mag_capacity(str(cur_wep["weapon_id"]), tier)
				equipped = true

		if not equipped:
			PlayerState.inventory_items.append({
				"type": "attachment",
				"id": op_id if att_k == "optic" else "%s_%d" % [att_k, tier],
				"tier": tier,
				"name": "Lv.%d 配件" % tier
			})
			_on_toast_pushed("📦 已拾取配件并放入背包！", "info")
		else:
			player.rebuild_viewmodel()
			_on_toast_pushed("✨ 已拾取并自动安装配件至当前武器！", "evo")

		if is_instance_valid(best.get("node")):
			best["node"].queue_free()
		interactables.erase(best)
		AudioSynthesizer.play_reload_step("lever_cock")
		_refresh_hud()
		return

func _spawn_supply_bin_loot_items(bin_pos: Vector3, bin_type: String) -> void:
	## Spawns 4 real interactive 3D pickupable items right on the Supply Bin's interior tray (y = 0.85)!
	var tray_y: float = bin_pos.y + 0.85
	var slot_offsets := [
		Vector3(-0.92, tray_y, bin_pos.z + 0.08),
		Vector3(-0.30, tray_y, bin_pos.z - 0.05),
		Vector3(0.32, tray_y, bin_pos.z + 0.08),
		Vector3(0.92, tray_y, bin_pos.z - 0.05)
	]
	slot_offsets[0].x += bin_pos.x
	slot_offsets[1].x += bin_pos.x
	slot_offsets[2].x += bin_pos.x
	slot_offsets[3].x += bin_pos.x

	if bin_type == "assault":
		var assault_pool := ["r301", "flatline", "peacekeeper", "mastiff", "hemlok", "volt", "nemesis"]
		var wid: String = assault_pool[randi() % assault_pool.size()]
		var winfo: Dictionary = GameData.get_weapon_by_id(wid)
		_spawn_dropped_weapon({
			"weapon_id": wid,
			"ammo": int(winfo["mag"]),
			"max_ammo": int(winfo["mag"]),
			"optic": "2x_bruiser",
			"barrel": 2,
			"mag": 2,
			"stock": 2,
			"charged": 0.0
		}, slot_offsets[0])
		_spawn_3d_loot_pickup(slot_offsets[1], {"type": "ammo", "id": str(winfo["ammo"]), "count": 60}, "弹药砖 x60", Color("#f97316"))
		_spawn_3d_loot_pickup(slot_offsets[2], {"type": "consumable", "id": "shield_battery", "count": 2}, "大型护盾电池 x2", Color("#38bdf8"))
		_spawn_dropped_attachment_at(slot_offsets[3], "mag", 3, "")
	elif bin_type == "support":
		_spawn_3d_loot_pickup(slot_offsets[0], {"type": "consumable", "id": "shield_battery", "count": 2}, "大型护盾电池 x2", Color("#38bdf8"))
		_spawn_3d_loot_pickup(slot_offsets[1], {"type": "consumable", "id": "med_kit", "count": 2}, "医疗箱 x2", Color("#22c55e"))
		_spawn_3d_loot_pickup(slot_offsets[2], {"type": "consumable", "id": "phoenix_kit", "count": 1}, "凤凰治疗包 x1", Color("#a855f7"))
		_spawn_3d_loot_pickup(slot_offsets[3], {"type": "consumable", "id": "shield_cell", "count": 4}, "小型护盾电池 x4", Color("#0ea5e9"))
	else:
		var std_pool := ["peacekeeper", "mastiff", "eva8", "bocek", "r99", "car", "wingman", "repeater3030", "spitfire"]
		var wid: String = std_pool[randi() % std_pool.size()]
		var winfo: Dictionary = GameData.get_weapon_by_id(wid)
		_spawn_dropped_weapon({
			"weapon_id": wid,
			"ammo": int(winfo["mag"]),
			"max_ammo": int(winfo["mag"]),
			"optic": "1x_hcog",
			"charged": 0.0
		}, slot_offsets[0])
		_spawn_3d_loot_pickup(slot_offsets[1], {"type": "ammo", "id": str(winfo["ammo"]), "count": 60}, "弹药补充 x60", Color("#f59e0b"))
		_spawn_3d_loot_pickup(slot_offsets[2], {"type": "consumable", "id": "shield_battery", "count": 1}, "大型护盾电池 x1", Color("#38bdf8"))
		_spawn_3d_loot_pickup(slot_offsets[3], {"type": "consumable", "id": "syringe", "count": 4}, "注射器 x4", Color("#22c55e"))

func _spawn_loot_tick_items(tick_pos: Vector3, rarity: int) -> void:
	## Spawns 3 high-tier Gold / Mythic 3D items around an opened Loot Tick Robot!
	var y_h: float = tick_pos.y + 0.45
	var mythic_weps := ["kraber", "bocek", "peacekeeper", "devotion", "wingman"]
	var wid: String = mythic_weps[randi() % mythic_weps.size()]
	var winfo: Dictionary = GameData.get_weapon_by_id(wid)

	_spawn_3d_loot_pickup(tick_pos + Vector3(-0.85, 0.45, 0.45), {"type": "armor", "tier": rarity}, "Lv.%d 进化护盾核心" % rarity, Color("#ff1e42") if rarity >= 5 else Color("#fbbf24"))
	_spawn_dropped_weapon({
		"weapon_id": wid,
		"ammo": int(winfo["mag"]),
		"max_ammo": int(winfo["mag"]),
		"optic": "6x_kraber" if wid == "kraber" else "2x_bruiser",
		"barrel": 3,
		"mag": 3,
		"stock": 3,
		"charged": 0.0
	}, Vector3(tick_pos.x, y_h, tick_pos.z + 0.75))
	_spawn_3d_loot_pickup(tick_pos + Vector3(0.85, 0.45, 0.45), {"type": "consumable", "id": "phoenix_kit", "count": 1}, "凤凰治疗包 x1", Color("#a855f7"))

func _spawn_3d_loot_pickup(spawn_pos: Vector3, loot_dict: Dictionary, label_text: String, glow_col: Color) -> void:
	var node := Node3D.new()
	node.name = "LootPickup_%d" % randi()
	node.position = spawn_pos
	add_child(node)

	var ltype: String = str(loot_dict.get("type", "consumable"))
	var lid: String = str(loot_dict.get("id", ""))

	var mat_glow := StandardMaterial3D.new()
	mat_glow.albedo_color = glow_col
	mat_glow.emission_enabled = true
	mat_glow.emission = glow_col
	mat_glow.emission_energy_multiplier = 2.6

	var mat_dark := StandardMaterial3D.new()
	mat_dark.albedo_color = Color("#0f172a")
	mat_dark.metallic = 0.75
	mat_dark.roughness = 0.30

	if ltype == "consumable" and (lid == "shield_battery" or lid == "shield_cell" or lid == "phoenix_kit"):
		# 3D Shield Battery Capacitor Mesh
		var cyl_m := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.11
		cm.bottom_radius = 0.11
		cm.height = 0.32
		cyl_m.mesh = cm
		cyl_m.material_override = mat_glow
		node.add_child(cyl_m)

		var cap_top := MeshInstance3D.new()
		var ctop := CylinderMesh.new()
		ctop.top_radius = 0.125
		ctop.bottom_radius = 0.125
		ctop.height = 0.06
		cap_top.mesh = ctop
		cap_top.material_override = mat_dark
		cap_top.position.y = 0.15
		node.add_child(cap_top)
	elif ltype == "armor":
		# 3D Hexagonal Armor Core Mesh
		var core_m := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.14
		tm.outer_radius = 0.24
		core_m.mesh = tm
		core_m.material_override = mat_glow
		core_m.rotation.x = PI * 0.5
		node.add_child(core_m)
	else:
		# 3D Medkit / Ammo Box Mesh
		var box_m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.28, 0.18, 0.22)
		box_m.mesh = bm
		box_m.material_override = mat_glow
		node.add_child(box_m)

	var tw := node.create_tween()
	tw.set_loops()
	tw.tween_property(node, "rotation_degrees:y", 360.0, 3.5).as_relative()

	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.fixed_size = true
	lbl.pixel_size = 0.0011
	lbl.font_size = 19
	lbl.outline_size = 3
	lbl.outline_modulate = Color(0, 0, 0, 0.95)
	lbl.text = "[E] %s" % label_text
	lbl.modulate = glow_col
	lbl.position = Vector3(0, 0.34, 0)
	node.add_child(lbl)

	interactables.append({
		"type": "dropped_loot",
		"pos": spawn_pos,
		"name": "拾取【%s】" % label_text,
		"node": node,
		"loot_data": loot_dict.duplicate(true)
	})

func _find_nearest_interactable() -> Dictionary:
	if player == null:
		return {}
	var p_pos: Vector3 = player.global_position
	var fwd: Vector3 = -player.global_transform.basis.z.normalized()
	if player.camera:
		fwd = -player.camera.global_transform.basis.z.normalized()

	var best: Dictionary = {}
	var best_score: float = -999.0
	for it in interactables:
		var t: String = str(it.get("type", ""))
		if (t == "supply_bin" or t == "loot_tick") and bool(it.get("opened", false)):
			continue
		var to_it: Vector3 = (it["pos"] - p_pos)
		var d: float = to_it.length()
		if d < 5.2:
			var dot: float = fwd.dot(to_it.normalized())
			if dot > 0.15:
				var score: float = dot * 2.2 - d * 0.45
				# Prioritize individual loot items inside an opened Supply Bin when aiming at them
				if t == "dropped_loot" or t == "dropped_weapon" or t == "dropped_attachment":
					score += 0.35
				if score > best_score:
					best_score = score
					best = it
	if best.is_empty():
		var best_d: float = 3.6
		for it in interactables:
			var t: String = str(it.get("type", ""))
			if (t == "supply_bin" or t == "loot_tick") and bool(it.get("opened", false)):
				continue
			var d: float = p_pos.distance_to(it["pos"])
			if d < best_d:
				best_d = d
				best = it
	return best

func _make_panel_style(bg_col: Color, border_col: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	screen_fx_rect = ColorRect.new()
	screen_fx_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_fx_rect.color = Color(0, 0, 0, 0)
	screen_fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(screen_fx_rect)

	scope_hit_hud = ScopeAndHitHUD.new()
	scope_hit_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	scope_hit_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scope_hit_hud)

	kill_banner = PanelContainer.new()
	kill_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	kill_banner.offset_left = -260.0
	kill_banner.offset_right = 260.0
	kill_banner.offset_top = 115.0
	kill_banner.offset_bottom = 205.0
	kill_banner.custom_minimum_size = Vector2(520, 90)
	var kb_style := StyleBoxFlat.new()
	kb_style.bg_color = Color(0.12, 0.04, 0.06, 0.94)
	kb_style.border_color = Color("#ef4444")
	kb_style.set_border_width_all(2)
	kb_style.set_corner_radius_all(6)
	kb_style.content_margin_left = 16
	kb_style.content_margin_right = 16
	kb_style.content_margin_top = 8
	kb_style.content_margin_bottom = 8
	kill_banner.add_theme_stylebox_override("panel", kb_style)
	kill_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kill_banner.modulate.a = 0.0
	kill_banner.visible = false
	root.add_child(kill_banner)

	var kb_vbox := VBoxContainer.new()
	kb_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	kb_vbox.add_theme_constant_override("separation", 3)
	kill_banner.add_child(kb_vbox)

	kill_banner_title = Label.new()
	kill_banner_title.text = "💀 你消灭了一名敌人"
	kill_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kill_banner_title.add_theme_font_size_override("font_size", 22)
	kill_banner_title.modulate = Color("#ff2a4b")
	kb_vbox.add_child(kill_banner_title)

	kill_banner_sub = Label.new()
	kill_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kill_banner_sub.add_theme_font_size_override("font_size", 13)
	kill_banner_sub.modulate = Color("#fde047")
	kb_vbox.add_child(kill_banner_sub)

	var dmg_anchor := Control.new()
	dmg_anchor.set_anchors_preset(Control.PRESET_CENTER)
	dmg_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dmg_anchor)

	hud_reload_lbl = Label.new()
	hud_reload_lbl.position = Vector2(-150, 48)
	hud_reload_lbl.add_theme_font_size_override("font_size", 17)
	hud_reload_lbl.modulate = Color("#38bdf8")
	hud_reload_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dmg_anchor.add_child(hud_reload_lbl)

	authentic_hud = ApexAuthenticHUD.new()
	authentic_hud.player = player
	authentic_hud.weapon_ctrl = weapon_ctrl
	authentic_hud.match_scene = self
	root.add_child(authentic_hud)

	var btn_lobby := Button.new()
	btn_lobby.text = "返回大厅 [ESC]"
	btn_lobby.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_lobby.position = Vector2(-150, 14)
	btn_lobby.custom_minimum_size = Vector2(120, 28)
	btn_lobby.pressed.connect(func():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/MainLobby.tscn")
	)
	root.add_child(btn_lobby)

	hud_toast_lbl = Label.new()
	hud_toast_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hud_toast_lbl.position = Vector2(-260, 95)
	hud_toast_lbl.custom_minimum_size = Vector2(520, 30)
	hud_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_toast_lbl.add_theme_font_size_override("font_size", 14)
	hud_toast_lbl.modulate = Color("#fde047")
	hud_toast_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud_toast_lbl)

	inventory_ui = ApexInventoryUI.new()
	inventory_ui.visible = false
	root.add_child(inventory_ui)
	inventory_ui.consumable_used.connect(func(cid: String):
		ability_sys.start_heal_item(cid)
		_refresh_hud()
	)
	inventory_ui.item_dropped.connect(func(cid: String):
		_on_toast_pushed("🗑️ 已从背包丢弃物品：%s" % cid, "info")
		_refresh_hud()
	)
	inventory_ui.weapon_dropped.connect(_on_weapon_dropped)
	inventory_ui.weapon_swapped.connect(_on_weapon_swapped)
	inventory_ui.attachment_dropped.connect(_on_attachment_dropped)

	victory_panel = PanelContainer.new()
	victory_panel.set_anchors_preset(Control.PRESET_CENTER)
	victory_panel.position = Vector2(-280, -160)
	victory_panel.custom_minimum_size = Vector2(560, 320)
	var vp_sb := StyleBoxFlat.new()
	vp_sb.bg_color = Color(0.04, 0.07, 0.12, 0.96)
	vp_sb.border_color = Color("#fbbf24")
	vp_sb.set_border_width_all(3)
	vp_sb.set_corner_radius_all(10)
	vp_sb.content_margin_left = 24
	vp_sb.content_margin_right = 24
	vp_sb.content_margin_top = 20
	vp_sb.content_margin_bottom = 20
	victory_panel.add_theme_stylebox_override("panel", vp_sb)
	victory_panel.visible = false
	root.add_child(victory_panel)

	var vp_vbox := VBoxContainer.new()
	vp_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vp_vbox.add_theme_constant_override("separation", 10)
	victory_panel.add_child(vp_vbox)

	var vp_title := Label.new()
	vp_title.text = "🏆 你是 APEX 捍卫者！"
	vp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vp_title.add_theme_font_size_override("font_size", 28)
	vp_title.modulate = Color("#fbbf24")
	vp_vbox.add_child(vp_title)

	var vp_sub := Label.new()
	vp_sub.text = "YOU ARE THE APEX CHAMPION"
	vp_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vp_sub.add_theme_font_size_override("font_size", 14)
	vp_sub.modulate = Color("#cbd5e1")
	vp_vbox.add_child(vp_sub)

	victory_stats_lbl = Label.new()
	victory_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_stats_lbl.add_theme_font_size_override("font_size", 16)
	victory_stats_lbl.modulate = Color("#f8fafc")
	vp_vbox.add_child(victory_stats_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vp_vbox.add_child(btn_row)

	var btn_again := Button.new()
	btn_again.text = "再来一局"
	btn_again.custom_minimum_size = Vector2(160, 42)
	btn_again.pressed.connect(func():
		get_tree().reload_current_scene()
	)
	btn_row.add_child(btn_again)

	var btn_exit := Button.new()
	btn_exit.text = "返回外域主大厅"
	btn_exit.custom_minimum_size = Vector2(160, 42)
	btn_exit.pressed.connect(func():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/MainLobby.tscn")
	)
	btn_row.add_child(btn_exit)

func _on_hit_feedback_pushed(target_name: String, single_dmg: int, cumulative_dmg: int, is_headshot: bool, shield_tier: int, cracked_now: bool) -> void:
	if scope_hit_hud == null:
		return
	scope_hit_hud.hit_timer = 0.22
	scope_hit_hud.dmg_timer = 1.65
	if cracked_now:
		scope_hit_hud.crack_timer = 0.70
		scope_hit_hud.last_cracked_tier = shield_tier
	scope_hit_hud.last_cum_dmg = cumulative_dmg
	scope_hit_hud.last_single_dmg = single_dmg
	scope_hit_hud.last_target_name = target_name
	scope_hit_hud.last_is_head = is_headshot
	scope_hit_hud.last_shield_tier = shield_tier
	scope_hit_hud.queue_redraw()

func _on_shotgun_pellet_feedback_pushed(pattern_name: String, hit_flags: Array, is_headshot: bool) -> void:
	if scope_hit_hud == null:
		return
	scope_hit_hud.pellet_timer = 0.55
	scope_hit_hud.last_pellet_pattern = pattern_name
	scope_hit_hud.last_pellet_hits = hit_flags
	scope_hit_hud.last_pellet_head = is_headshot
	scope_hit_hud.queue_redraw()

func _on_floating_damage_spawned(wpos: Vector3, dmg: int, is_headshot: bool, shield_tier: int, _cracked: bool) -> void:
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.fixed_size = true
	lbl.pixel_size = 0.00095
	lbl.font_size = 28 if is_headshot else 24
	lbl.outline_size = 3
	lbl.outline_modulate = Color(0, 0, 0, 0.95)
	lbl.text = str(dmg)

	var col: Color
	if is_headshot:
		col = Color("#fde047")
	elif shield_tier == 0:
		col = Color("#ff4757")
	else:
		col = GameData.get_evo_tier(shield_tier)["color"]
	lbl.modulate = col

	var offset := Vector3(randf_range(0.25, 0.45), randf_range(0.20, 0.38), randf_range(-0.12, 0.12))
	lbl.position = wpos + offset
	add_child(lbl)

	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position", lbl.position + Vector3(randf_range(0.04, 0.12), 0.50, randf_range(-0.04, 0.04)), 0.60).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	lbl.scale = Vector3(1.15, 1.15, 1.15)
	tw.tween_property(lbl, "scale", Vector3(1.0, 1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.22).set_delay(0.38)
	tw.chain().tween_callback(lbl.queue_free)

func _on_enemy_eliminated(victim_name: String, weapon_name: String, total_kills: int) -> void:
	if kill_banner == null:
		return
	kill_banner.visible = true
	kill_banner_title.text = "💀 你 消 灭 了 【%s】" % victim_name
	kill_banner_sub.text = "🔫 击杀武器：%s   |   💀 个人总击杀：%d" % [weapon_name, total_kills]

	if kill_banner_tween and kill_banner_tween.is_valid():
		kill_banner_tween.kill()

	kill_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	kill_banner.offset_left = -260.0
	kill_banner.offset_right = 260.0
	kill_banner.offset_top = 115.0
	kill_banner.offset_bottom = 205.0
	kill_banner.scale = Vector2(0.5, 0.5)
	kill_banner.pivot_offset = Vector2(260, 45)
	kill_banner.modulate.a = 0.0

	kill_banner_tween = create_tween()
	kill_banner_tween.set_parallel(true)
	kill_banner_tween.tween_property(kill_banner, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	kill_banner_tween.tween_property(kill_banner, "modulate:a", 1.0, 0.16)
	kill_banner_tween.tween_property(kill_banner, "modulate:a", 0.0, 0.35).set_delay(2.6)
	kill_banner_tween.tween_property(kill_banner, "offset_top", 85.0, 0.35).set_delay(2.6)
	kill_banner_tween.chain().tween_callback(func():
		kill_banner.visible = false
		kill_banner.offset_top = 115.0
	)

func _on_toast_pushed(msg: String, _kind: Variant) -> void:
	if hud_toast_lbl:
		hud_toast_lbl.text = msg

func _on_killfeed_pushed(msg: String, _col: Color) -> void:
	if is_instance_valid(authentic_hud):
		authentic_hud.push_killfeed(msg, "🔫", "")

func _refresh_hud() -> void:
	if is_instance_valid(authentic_hud):
		authentic_hud.queue_redraw()

func _update_realtime_hud() -> void:
	if scope_hit_hud != null:
		var want_ads: bool = (player.is_ads and PlayerState.active_slot != 2 and weapon_ctrl.reload_timer <= 0.0 and PlayerState.heal_cast_timer <= 0.0)
		var cur_op: String = str(PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)].get("optic", "2x_bruiser"))

		var cam := player.camera
		var p_pos := cam.global_position
		var fwd := -cam.global_transform.basis.z
		var min_d: float = 999.0
		var locked_threat: bool = false
		for bot in enemies:
			if not is_instance_valid(bot) or bot.hp <= 0.0:
				continue
			var to_bot: Vector3 = (bot.global_position + Vector3(0, 1.25, 0)) - p_pos
			var d: float = to_bot.length()
			if d < min_d:
				min_d = d
			if fwd.angle_to(to_bot.normalized()) < (0.12 if d < 30.0 else 0.065):
				locked_threat = true
			if want_ads and cur_op == "1x_threat":
				bot.set_scanned(0.25)

		scope_hit_hud.target_dist_m = min_d if min_d < 500.0 else 32.0
		scope_hit_hud.is_threat_locked = locked_threat
		scope_hit_hud.bow_draw_ratio = weapon_ctrl.bow_draw_progress
		scope_hit_hud.choke_ratio = weapon_ctrl.choke_progress

		if scope_hit_hud.is_ads != want_ads or scope_hit_hud.optic_id != cur_op or scope_hit_hud.alt_zoom != PlayerState.scope_alt_zoom:
			scope_hit_hud.is_ads = want_ads
			scope_hit_hud.optic_id = cur_op
			scope_hit_hud.alt_zoom = PlayerState.scope_alt_zoom
			scope_hit_hud.queue_redraw()

	if hud_reload_lbl:
		if weapon_ctrl.reload_timer > 0.0:
			var p: float = 1.0 - (weapon_ctrl.reload_timer / maxf(0.01, weapon_ctrl.reload_total))
			var st_txt: String = "单发装填弹壳..." if weapon_ctrl.is_segmented_reload else ("1/3 卸下空弹匣..." if p < 0.32 else ("2/3 插入新弹匣..." if p < 0.68 else "3/3 拉栓上膛!"))
			hud_reload_lbl.text = "🔄 战术换弹 [%s] (%.1fs)" % [st_txt, weapon_ctrl.reload_timer]
		elif weapon_ctrl.rechamber_timer > 0.0:
			hud_reload_lbl.text = "⚙️ 拉栓/泵动/杠杆退壳上膛中..."
		else:
			hud_reload_lbl.text = ""

	var near: Dictionary = _find_nearest_interactable()
	if not near.is_empty():
		var itype: String = str(near.get("type", ""))
		var is_hold: bool = (itype == "deathbox")
		var target_name: String = str(near.get("owner_name", near.get("name", "")))
		if is_instance_valid(authentic_hud):
			authentic_hud.set_interaction_prompt(true, is_hold, target_name, itype)
	else:
		if is_instance_valid(authentic_hud):
			authentic_hud.set_interaction_prompt(false, false, "")
			authentic_hud.hold_progress = 0.0

	if PlayerState.void_timer > 0.0:
		screen_fx_rect.color = Color(0.45, 0.18, 0.92, 0.25)
	elif PlayerState.beast_timer > 0.0:
		screen_fx_rect.color = Color(0.92, 0.12, 0.12, 0.18)
	elif PlayerState.stim_timer > 0.0:
		screen_fx_rect.color = Color(0.12, 0.88, 0.35, 0.14)
	else:
		screen_fx_rect.color = Color(0, 0, 0, 0)

func _check_all_enemies_dead() -> bool:
	if PlayerState.selected_mode_id == "firing_range":
		return false
	for e in enemies:
		if is_instance_valid(e) and e.visible and e.hp > 0.0:
			return false
	return true

func _push_simulated_skirmish() -> void:
	var weapons := ["VK-47 平行步枪", "R-301 卡宾枪", "和平捍卫者", "獒犬霰弹枪", "博塞克复合弓", "克雷贝尔 .50", "猎兽冲锋枪", "EVA-8 自动霰弹枪", "CAR 冲锋枪", "复仇女神"]
	var killer_leg: Dictionary = GameData.LEGENDS[randi() % GameData.LEGENDS.size()]
	var victim_leg: Dictionary = GameData.LEGENDS[randi() % GameData.LEGENDS.size()]
	var killer_name := "%s #%d" % [killer_leg["name"], randi_range(2, 20)]
	var victim_name := "%s #%d" % [victim_leg["name"], randi_range(2, 20)]
	var is_storm: bool = randf() < 0.22
	if is_storm:
		PlayerState.killfeed_pushed.emit("⭕ 毒圈辐射淘汰了 %s" % victim_name, Color("#f97316"))
		if is_instance_valid(authentic_hud):
			authentic_hud.push_killfeed("⭕ 毒圈收缩", "☠️", victim_name)
	else:
		var wep: String = weapons[randi() % weapons.size()]
		PlayerState.killfeed_pushed.emit("%s 使用 [%s] 淘汰了 %s" % [killer_name, wep, victim_name], Color("#cbd5e1"))
		if is_instance_valid(authentic_hud):
			authentic_hud.push_killfeed(killer_name, "🔫 " + wep, victim_name)

func _trigger_victory_screen() -> void:
	PlayerState.career_wins += 1
	PlayerState.match_ended = true
	PlayerState.squads_alive = 1
	PlayerState.players_alive = 3
	PlayerState.state_updated.emit()

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	AudioSynthesizer.play_loot_tick_open()
	AudioSynthesizer.play_kill_confirmed()
	_on_toast_pushed("🏆 战场全部敌对小队已肃清！荣登 APEX 捍卫者！", "evo")

	if victory_panel:
		victory_panel.visible = true
		victory_stats_lbl.text = "🏆 最终排名：#1 (冠军小队)\n💀 淘汰人数：%d\n💥 造成伤害：%d\n⏱️ 存活时间：%d分%d秒\n✦ 获得 1,500 赛季战斗通行证积分与 +250 EVO！" % [
			PlayerState.kills, PlayerState.damage_dealt, int(match_time) / 60, int(match_time) % 60
		]
		var tw := create_tween()
		victory_panel.scale = Vector2(0.6, 0.6)
		victory_panel.pivot_offset = Vector2(280, 160)
		victory_panel.modulate.a = 0.0
		tw.set_parallel(true)
		tw.tween_property(victory_panel, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(victory_panel, "modulate:a", 1.0, 0.25)

func _on_deathbox_spawn_requested(pos: Vector3, bot_name: String, evo_tier: int, weapon_name: String) -> void:
	var tier_info: Dictionary = GameData.get_evo_tier(evo_tier)
	var tier_col: Color = tier_info["color"]

	var root_box := Node3D.new()
	root_box.name = "Deathbox_%s" % bot_name
	root_box.position = pos
	add_child(root_box)

	var body_mesh := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(1.40, 0.72, 0.86)
	body_mesh.mesh = b_box
	var mat_body := StandardMaterial3D.new()
	mat_body.albedo_color = Color("#cbd5e1")
	mat_body.metallic = 0.45
	mat_body.roughness = 0.35
	body_mesh.material_override = mat_body
	body_mesh.position.y = 0.36
	root_box.add_child(body_mesh)

	var inset_mesh := MeshInstance3D.new()
	var i_box := BoxMesh.new()
	i_box.size = Vector3(1.42, 0.46, 0.74)
	inset_mesh.mesh = i_box
	var mat_inset := StandardMaterial3D.new()
	mat_inset.albedo_color = Color("#334155")
	mat_inset.metallic = 0.6
	mat_inset.roughness = 0.3
	inset_mesh.material_override = mat_inset
	inset_mesh.position.y = 0.36
	root_box.add_child(inset_mesh)

	for lx in [-0.28, 0.28]:
		var latch := MeshInstance3D.new()
		var l_mesh := BoxMesh.new()
		l_mesh.size = Vector3(0.08, 0.16, 0.06)
		latch.mesh = l_mesh
		var mat_latch := StandardMaterial3D.new()
		mat_latch.albedo_color = Color("#ef4444")
		latch.material_override = mat_latch
		latch.position = Vector3(lx, 0.42, 0.44)
		root_box.add_child(latch)

	var lid_mesh := MeshInstance3D.new()
	var l_box := BoxMesh.new()
	l_box.size = Vector3(1.44, 0.14, 0.90)
	lid_mesh.mesh = l_box
	var mat_lid := StandardMaterial3D.new()
	mat_lid.albedo_color = Color("#475569")
	mat_lid.metallic = 0.5
	mat_lid.roughness = 0.3
	lid_mesh.material_override = mat_lid
	lid_mesh.position.y = 0.78
	root_box.add_child(lid_mesh)

	var banner_plate := MeshInstance3D.new()
	var bp_box := BoxMesh.new()
	bp_box.size = Vector3(0.88, 0.03, 0.52)
	banner_plate.mesh = bp_box
	var mat_bp := StandardMaterial3D.new()
	mat_bp.albedo_color = Color("#7c3aed")
	mat_bp.emission_enabled = true
	mat_bp.emission = Color("#a855f7")
	mat_bp.emission_energy_multiplier = 2.4
	banner_plate.material_override = mat_bp
	banner_plate.position.y = 0.86
	root_box.add_child(banner_plate)

	var glow := OmniLight3D.new()
	glow.light_color = tier_col
	glow.light_energy = 1.2
	glow.omni_range = 2.4
	glow.position.y = 1.0
	root_box.add_child(glow)

	var outline_mesh := MeshInstance3D.new()
	outline_mesh.name = "InteractOutline"
	var o_box := BoxMesh.new()
	o_box.size = Vector3(1.46, 0.82, 0.92)
	outline_mesh.mesh = o_box
	var mat_out := StandardMaterial3D.new()
	mat_out.albedo_color = Color(1.0, 1.0, 1.0, 0.65)
	mat_out.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_out.cull_mode = BaseMaterial3D.CULL_FRONT
	mat_out.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_out.grow = true
	mat_out.grow_amount = 0.016
	outline_mesh.material_override = mat_out
	outline_mesh.position.y = 0.41
	root_box.add_child(outline_mesh)

	var sample_weap_ids := ["flatline", "peacekeeper", "wingman", "r301", "mastiff", "volt", "bocek", "eva8", "prowler", "hemlok"]
	var db_wep_id: String = sample_weap_ids[randi() % sample_weap_ids.size()]
	var db_wep_info: Dictionary = GameData.get_weapon_by_id(db_wep_id)

	var dbox_items := [
		{
			"type": "weapon",
			"id": db_wep_id,
			"name": str(db_wep_info.get("name", db_wep_id)),
			"count": 1,
			"ammo": int(db_wep_info.get("mag", 20)),
			"weapon_data": {
				"weapon_id": db_wep_id,
				"ammo": int(db_wep_info.get("mag", 20)),
				"max_ammo": int(db_wep_info.get("mag", 20)),
				"optic": "2x_bruiser",
				"barrel": randi_range(2, 3),
				"mag": randi_range(2, 3),
				"stock": randi_range(2, 3),
				"hopup": "",
				"charged": 0.0
			}
		},
		{"type": "attachment", "id": "optic_3x", "name": "3x 游骑兵瞄准镜", "tier": 3, "att_type": "optic"},
		{"type": "attachment", "id": "mag_3", "name": "Lv.3 紫色加长弹匣", "tier": 3, "att_type": "mag"},
		{"type": "consumable", "id": "shield_battery", "count": 2},
		{"type": "consumable", "id": "shield_cell", "count": 4},
		{"type": "consumable", "id": "med_kit", "count": 2},
		{"type": "consumable", "id": "syringe", "count": 4},
		{"type": "ammo", "id": str(db_wep_info.get("ammo", "light")), "count": 60},
		{"type": "ammo", "id": "shotgun" if randf() > 0.5 else "heavy", "count": 32},
		{"type": "ordnance", "id": "arc_star" if randf() > 0.5 else "frag", "count": 1}
	]

	var dbox_dict := {
		"victim_name": bot_name,
		"evo_tier": evo_tier,
		"weapon": weapon_name,
		"items": dbox_items,
		"armor_swapped": false
	}

	interactables.append({
		"type": "deathbox",
		"pos": pos,
		"owner_name": bot_name,
		"name": "搜刮【%s】的死亡之箱" % bot_name,
		"node": root_box,
		"data": dbox_dict
	})

func _on_weapon_dropped(_w_idx: int, weapon_dict: Dictionary) -> void:
	if player == null:
		return
	var wid: String = str(weapon_dict.get("weapon_id", "empty"))
	if wid == "empty" or wid == "":
		return
	var fwd: Vector3 = -player.global_transform.basis.z.normalized()
	var spawn_pos: Vector3 = player.global_position + fwd * 1.8 + Vector3(0, 0.45, 0)
	_spawn_dropped_weapon(weapon_dict, spawn_pos)
	player.rebuild_viewmodel()
	_refresh_hud()

func _spawn_dropped_weapon(weapon_dict: Dictionary, spawn_pos: Vector3) -> void:
	var wid: String = str(weapon_dict.get("weapon_id", "r301"))
	var wep_info: Dictionary = GameData.get_weapon_by_id(wid)
	var ammo_type: String = str(wep_info.get("ammo", "light"))

	var root_wep := Node3D.new()
	root_wep.name = "DroppedWeapon_%s_%d" % [wid, randi()]
	root_wep.position = spawn_pos
	add_child(root_wep)

	# Use actual 3D WeaponMeshBuilder model scaled for ground / bin tray display!
	var preview_rig := WeaponMeshBuilder.create_viewmodel(wep_info, false, {}, str(weapon_dict.get("optic", "2x_bruiser")))
	preview_rig.position = Vector3.ZERO
	preview_rig.scale = Vector3(0.85, 0.85, 0.85)
	var la := preview_rig.get_node_or_null("GunRig/LeftArmPivot")
	var ra := preview_rig.get_node_or_null("GunRig/RightArmPivot")
	if la:
		la.visible = false
	if ra:
		ra.visible = false
	root_wep.add_child(preview_rig)

	var ammo_col: Color = Color("#f97316")
	match ammo_type:
		"heavy": ammo_col = Color("#14b8a6")
		"energy": ammo_col = Color("#84cc16")
		"shotgun": ammo_col = Color("#ef4444")
		"sniper": ammo_col = Color("#38bdf8")
		"arrows": ammo_col = Color("#f59e0b")

	var rot_tw := root_wep.create_tween()
	rot_tw.set_loops()
	rot_tw.tween_property(root_wep, "rotation_degrees:y", 360.0, 4.0).as_relative()

	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.fixed_size = true
	lbl.pixel_size = 0.0011
	lbl.font_size = 19
	lbl.outline_size = 3
	lbl.outline_modulate = Color(0, 0, 0, 0.95)
	lbl.text = "[E] 【%s】" % str(wep_info.get("name", wid))
	lbl.modulate = ammo_col
	lbl.position = Vector3(0, 0.38, 0)
	root_wep.add_child(lbl)

	interactables.append({
		"type": "dropped_weapon",
		"pos": spawn_pos,
		"name": "拾取【%s】" % str(wep_info.get("name", wid)),
		"node": root_wep,
		"weapon_data": weapon_dict.duplicate(true)
	})

func _on_attachment_dropped(att_type: String, tier: int, optic_id: String) -> void:
	if player == null:
		return
	var fwd: Vector3 = -player.global_transform.basis.z.normalized()
	var spawn_pos: Vector3 = player.global_position + fwd * 1.5 + Vector3(0, 0.35, 0)
	_spawn_dropped_attachment_at(spawn_pos, att_type, tier, optic_id)

func _spawn_dropped_attachment_at(spawn_pos: Vector3, att_type: String, tier: int, optic_id: String) -> void:
	var root_att := Node3D.new()
	root_att.name = "DroppedAtt_%s_%d" % [att_type, randi()]
	root_att.position = spawn_pos
	add_child(root_att)

	var tier_info := GameData.get_evo_tier(tier)
	var tier_col: Color = tier_info["color"]

	var mesh_inst := MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = Vector3(0.24, 0.14, 0.24)
	mesh_inst.mesh = b_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tier_col
	mat.emission_enabled = true
	mat.emission = tier_col
	mat.emission_energy_multiplier = 2.0
	mesh_inst.material_override = mat
	root_att.add_child(mesh_inst)

	var tw := root_att.create_tween()
	tw.set_loops()
	tw.tween_property(root_att, "rotation_degrees:y", 360.0, 3.0).as_relative()

	var aname: String = "Lv.%d %s配件" % [tier, att_type]
	if att_type == "optic" and optic_id != "":
		aname = optic_id

	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.fixed_size = true
	lbl.pixel_size = 0.0011
	lbl.font_size = 18
	lbl.text = "[E] %s" % aname
	lbl.modulate = tier_col
	lbl.position = Vector3(0, 0.30, 0)
	root_att.add_child(lbl)

	interactables.append({
		"type": "dropped_attachment",
		"pos": spawn_pos,
		"name": "拾取【%s】" % aname,
		"node": root_att,
		"att_type": att_type,
		"tier": tier,
		"optic_id": optic_id
	})

func _on_weapon_swapped(_slot_a: int, _slot_b: int) -> void:
	if player:
		player.rebuild_viewmodel()
	_refresh_hud()

func _run_inventory_diagnostics() -> void:
	print("==================================================")
	print(">>> RUNNING HEALING VIEWMODEL & AMMO LINKAGE TESTS <<<")
	print("==================================================")

	# 1. Test PlayerState initial synchronization
	PlayerState.reset_for_match()
	print("[1] Verifying Initial Loadout and Ammo Reserves:")
	print("  Slot 0: %s (ammo: %d/%d)" % [PlayerState.loadout[0]["weapon_id"], PlayerState.loadout[0]["ammo"], PlayerState.loadout[0]["max_ammo"]])
	print("  Slot 1: %s (ammo: %d/%d)" % [PlayerState.loadout[1]["weapon_id"], PlayerState.loadout[1]["ammo"], PlayerState.loadout[1]["max_ammo"]])
	print("  Reserve light: %d (expected 120)" % PlayerState.ammo_reserve["light"])
	print("  Reserve shotgun: %d (expected 32)" % PlayerState.ammo_reserve["shotgun"])
	print("  Consumables battery: %d (expected 3)" % PlayerState.consumables["shield_battery"])
	assert(PlayerState.loadout[0]["weapon_id"] == "peacekeeper" and PlayerState.loadout[0]["ammo"] == 5)
	assert(PlayerState.loadout[1]["weapon_id"] == "r301" and PlayerState.loadout[1]["ammo"] == 28)
	assert(PlayerState.ammo_reserve["light"] == 120, "Light ammo reserve must equal backpack sum")
	assert(PlayerState.ammo_reserve["shotgun"] == 32, "Shotgun ammo reserve must equal backpack sum")
	assert(PlayerState.consumables["shield_battery"] == 3, "Battery count must equal backpack sum")
	print("  -> Initial synchronization test PASSED!")

	# 2. Test Ammo Deduction during Reload
	print("[2] Verifying Weapon Reload & Backpack Deduction Linkage:")
	PlayerState.active_slot = 1 # R-301
	var slot1: Dictionary = PlayerState.loadout[1]
	slot1["ammo"] = 0 # Simulate empty mag
	var needed: int = int(slot1["max_ammo"]) - int(slot1["ammo"])
	var loaded: int = PlayerState.deduct_ammo("light", needed)
	slot1["ammo"] += loaded
	print("  Reloaded R-301: loaded %d rounds, mag now %d/%d" % [loaded, slot1["ammo"], slot1["max_ammo"]])
	print("  New light ammo reserve: %d (expected 92)" % PlayerState.ammo_reserve["light"])
	assert(loaded == 28)
	assert(slot1["ammo"] == 28)
	assert(PlayerState.ammo_reserve["light"] == 92)

	var inv_light_sum: int = 0
	for it in PlayerState.inventory_items:
		if it.get("type") == "ammo" and it.get("id") == "light":
			inv_light_sum += int(it.get("count", 0))
	print("  Actual backpack light ammo sum: %d (expected 92)" % inv_light_sum)
	assert(inv_light_sum == 92, "Backpack inventory stacks must be deducted")
	print("  -> Reload deduction linkage test PASSED!")

	# 3. Test Viewmodel Weapon Mesh Hiding During Healing
	print("[3] Verifying Viewmodel Gun Mesh Hiding During Healing:")
	player.rebuild_viewmodel()
	var vm: Node3D = player.viewmodel_holder.get_child(0)
	var gun_rig: Node3D = vm.get_node_or_null("GunRig")
	assert(gun_rig != null, "GunRig must exist")

	var cons_pivot: Node3D = gun_rig.get_node_or_null("ConsumablePivot")
	var left_arm: Node3D = gun_rig.get_node_or_null("LeftArmPivot")
	var right_arm: Node3D = gun_rig.get_node_or_null("RightArmPivot")
	var upper_rec: Node3D = gun_rig.get_node_or_null("UpperReceiver")
	assert(cons_pivot != null and left_arm != null and right_arm != null and upper_rec != null)

	# State A: Normal Idle
	PlayerState.heal_cast_timer = 0.0
	weapon_ctrl._animate_viewmodel(0.016)
	assert(cons_pivot.visible == false, "Consumable prop must be hidden when idle")
	assert(upper_rec.visible == true, "Gun mesh must be visible when idle")
	print("  State A (Idle): Gun visible, Consumable hidden - OK")

	# State B: Using Shield Battery
	PlayerState.active_heal_id = "shield_battery"
	PlayerState.heal_cast_total = 5.0
	PlayerState.heal_cast_timer = 4.2
	weapon_ctrl._animate_viewmodel(0.016)
	assert(cons_pivot.visible == true, "Consumable prop must be visible when healing")
	assert(upper_rec.visible == false, "Gun chassis must be HIDDEN when healing")
	assert(left_arm.visible == true, "Left arm must remain visible")
	assert(right_arm.visible == true, "Right arm must remain visible")
	print("  State B (Using Battery): Gun HIDDEN, Hands & Battery visible - OK")

	# State C: Using Syringe / Medkit
	PlayerState.active_heal_id = "syringe"
	PlayerState.heal_cast_total = 5.0
	PlayerState.heal_cast_timer = 3.5
	weapon_ctrl._animate_viewmodel(0.016)
	assert(cons_pivot.visible == true, "Consumable prop must be visible when using syringe")
	assert(upper_rec.visible == false, "Gun chassis must remain HIDDEN when using syringe")
	print("  State C (Using Syringe): Gun HIDDEN, Hands & Syringe visible - OK")

	# State D: Healing Finishes
	PlayerState.heal_cast_timer = 0.0
	weapon_ctrl._animate_viewmodel(0.016)
	assert(cons_pivot.visible == false, "Consumable prop must hide when healing ends")
	assert(upper_rec.visible == true, "Gun chassis must be RESTORED when healing ends")
	print("  State D (Healing Finished): Gun restored to visible, Consumable hidden - OK")
	print("  -> Viewmodel Gun Mesh Hiding test PASSED with 100% SUCCESS!")

	# 4. Test Consumable & Ordnance Deduction
	print("[4] Verifying Consumable and Ordnance Deductions:")
	var pre_bat: int = int(PlayerState.consumables.get("shield_battery", 0))
	PlayerState.active_heal_id = "shield_battery"
	ability_sys._complete_heal_item()
	var post_bat: int = int(PlayerState.consumables.get("shield_battery", 0))
	print("  Shield battery count: %d -> %d" % [pre_bat, post_bat])
	assert(post_bat == pre_bat - 1)
	var inv_bat_cnt: int = 0
	for it in PlayerState.inventory_items:
		if it.get("type") == "consumable" and it.get("id") == "shield_battery":
			inv_bat_cnt += int(it.get("count", 0))
	assert(inv_bat_cnt == post_bat)
	print("  -> Consumable deduction test PASSED!")

	print("==================================================")
	print(">>> ALL HEALING & AMMO LINKAGE TESTS PASSED! <<<")
	print("==================================================")
	get_tree().quit(0)

func _run_victory_diagnostics() -> void:
	print("==================================================")
	print(">>> RUNNING BR SQUADS & VICTORY FLOW DIAGNOSTICS <<<")
	print("==================================================")
	print("Initial Squads Alive: %d (expected 20)" % PlayerState.squads_alive)
	print("Initial Players Alive: %d (expected 60)" % PlayerState.players_alive)
	assert(PlayerState.squads_alive == 20, "Must be 20 squads")
	assert(PlayerState.players_alive == 60, "Must be 60 players")

	# Verify spawned bots
	print("Enemies spawned: %d" % enemies.size())
	assert(enemies.size() == 21, "Must spawn 21 bots")
	var sq_map: Dictionary = {}
	for b in enemies:
		sq_map[b.squad_id] = sq_map.get(b.squad_id, 0) + 1
	print("Enemy Squads mapping: ", sq_map)
	assert(sq_map.size() == 7, "Must be 7 squads")
	for s in sq_map:
		assert(sq_map[s] == 3, "Each squad must have 3 bots")

	# Test simulated skirmish
	_push_simulated_skirmish()
	print("Simulated skirmish successfully pushed!")

	# Trigger Victory
	_trigger_victory_screen()
	print("After victory trigger:")
	print("  PlayerState.match_ended: ", PlayerState.match_ended)
	print("  PlayerState.squads_alive: %d (expected 1)" % PlayerState.squads_alive)
	print("  PlayerState.players_alive: %d (expected 3)" % PlayerState.players_alive)
	assert(PlayerState.match_ended == true)
	assert(PlayerState.squads_alive == 1)
	assert(PlayerState.players_alive == 3)
	print("==================================================")
	print(">>> ALL VICTORY DIAGNOSTICS PASSED WITH 100% SUCCESS! <<<")
	print("==================================================")
	get_tree().quit(0)
