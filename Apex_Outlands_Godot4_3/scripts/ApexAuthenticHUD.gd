class_name ApexAuthenticHUD
extends Control
## Authentic Apex Legends In-Game HUD for Godot 4.3
## Features:
## - Dynamic Interaction Prompts for Deathboxes, Supply Bins, Loot Ticks, Dropped 3D Weapons/Loot, Ziplines & Jump Towers
## - Top-Left Minimap + Live Behavior Recorder & AI Imitation Status Badge ([F8] Record / [F9] Train AI)
## - Bottom-Left Squad & Player Card with Live Consumable Count & Cast Progress
## - Bottom-Right Dual Weapon Tabs, Silhouettes, and Live-Synced Backpack Ammo Reserve Readout (`PlayerState.get_reserve_ammo`)

var player: CharacterBody3D
var weapon_ctrl: Node
var match_scene: Node

var prompt_visible: bool = false
var prompt_is_hold: bool = true
var prompt_target_name: String = "MMzi-beng-gou"
var prompt_action_type: String = "deathbox"
var prompt_custom_text: String = ""
var hold_progress: float = 0.0

var camera_heading_deg: float = 62.0
var round_timer: float = 228.0
var round_stage: int = 1

var killfeed_items: Array = [
	{"text": "[OTTO] 欢迎来到外域协议！按 [F8] 可录制玩家行为训练AI", "wep": "⚡", "victim": "APEX", "time": 14.0}
]

var diag_fps: int = 62
var diag_ping: int = 28

var compass_widget: CompassWidget
var minimap_widget: MinimapWidget
var round_ring_widget: RoundRingWidget
var top_right_widget: TopRightWidget
var bottom_left_widget: BottomLeftWidget
var bottom_center_widget: BottomCenterWidget
var bottom_right_widget: BottomRightWidget
var interact_prompt_widget: InteractPromptWidget
var reticle_widget: ReticleWidget

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	reticle_widget = ReticleWidget.new()
	reticle_widget.hud = self
	add_child(reticle_widget)

	compass_widget = CompassWidget.new()
	compass_widget.hud = self
	add_child(compass_widget)

	minimap_widget = MinimapWidget.new()
	minimap_widget.hud = self
	add_child(minimap_widget)

	round_ring_widget = RoundRingWidget.new()
	round_ring_widget.hud = self
	add_child(round_ring_widget)

	top_right_widget = TopRightWidget.new()
	top_right_widget.hud = self
	add_child(top_right_widget)

	bottom_left_widget = BottomLeftWidget.new()
	bottom_left_widget.hud = self
	add_child(bottom_left_widget)

	bottom_center_widget = BottomCenterWidget.new()
	bottom_center_widget.hud = self
	add_child(bottom_center_widget)

	bottom_right_widget = BottomRightWidget.new()
	bottom_right_widget.hud = self
	add_child(bottom_right_widget)

	interact_prompt_widget = InteractPromptWidget.new()
	interact_prompt_widget.hud = self
	add_child(interact_prompt_widget)

func _process(delta: float) -> void:
	if is_instance_valid(player):
		var cam: Camera3D = player.get_node_or_null("PlayerCamera3D")
		if cam:
			camera_heading_deg = fposmod(-rad_to_deg(cam.global_rotation.y), 360.0)
		else:
			camera_heading_deg = fposmod(-rad_to_deg(player.global_rotation.y), 360.0)

	round_timer = maxf(0.0, round_timer - delta)
	if round_timer <= 0.0:
		round_timer = 240.0
		round_stage = clampi(round_stage + 1, 1, 5)

	for i in range(killfeed_items.size() - 1, -1, -1):
		killfeed_items[i]["time"] -= delta
		if killfeed_items[i]["time"] <= 0.0 and killfeed_items.size() > 1:
			killfeed_items.remove_at(i)

	diag_fps = int(Engine.get_frames_per_second())
	if diag_fps <= 0:
		diag_fps = 62

	if compass_widget: compass_widget.queue_redraw()
	if minimap_widget: minimap_widget.queue_redraw()
	if round_ring_widget: round_ring_widget.queue_redraw()
	if top_right_widget: top_right_widget.queue_redraw()
	if bottom_left_widget: bottom_left_widget.queue_redraw()
	if bottom_center_widget: bottom_center_widget.queue_redraw()
	if bottom_right_widget: bottom_right_widget.queue_redraw()
	if interact_prompt_widget: interact_prompt_widget.queue_redraw()
	if reticle_widget: reticle_widget.queue_redraw()

func push_killfeed(killer: String, wep: String, victim: String) -> void:
	killfeed_items.insert(0, {
		"text": killer,
		"wep": wep,
		"victim": victim,
		"time": 8.0
	})
	if killfeed_items.size() > 4:
		killfeed_items.pop_back()

func set_interaction_prompt(visible_state: bool, is_hold: bool, target_name: String, action_type: String = "deathbox", custom_txt: String = "") -> void:
	prompt_visible = visible_state
	prompt_is_hold = is_hold
	prompt_target_name = target_name
	prompt_action_type = action_type
	prompt_custom_text = custom_txt

class InteractPromptWidget extends Control:
	var hud: ApexAuthenticHUD

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if hud == null or not hud.prompt_visible:
			return

		var vp_size: Vector2 = get_viewport_rect().size
		var center_x: float = vp_size.x * 0.58
		var center_y: float = vp_size.y * 0.57

		var font: Font = get_theme_default_font()
		var font_size: int = 18

		var is_hold: bool = hud.prompt_is_hold
		var prefix_text: String = "长按" if is_hold else ""
		var suffix_text: String = ""

		if hud.prompt_custom_text != "":
			suffix_text = hud.prompt_custom_text
		elif hud.prompt_action_type == "deathbox":
			suffix_text = "使用 %s 的物品" % hud.prompt_target_name
		elif hud.prompt_action_type == "supply_bin":
			suffix_text = "打开 补给仓 (生成可拾取3D物资)"
		elif hud.prompt_action_type == "loot_tick":
			suffix_text = "击碎 战利品箱机器人"
		elif hud.prompt_action_type == "jump_tower":
			suffix_text = "搭乘 跳伞塔高空重部署"
		else:
			suffix_text = "%s" % hud.prompt_target_name

		var prefix_w: float = font.get_string_size(prefix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x if is_hold else 0.0
		var suffix_w: float = font.get_string_size(suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var key_w: float = 28.0
		var key_h: float = 28.0
		var gap: float = 10.0
		var pad_h: float = 16.0

		var total_content_w: float = (prefix_w + gap if is_hold else 0.0) + key_w + gap + suffix_w
		var pill_w: float = total_content_w + pad_h * 2.0
		var pill_h: float = 38.0

		var pill_rect := Rect2(center_x - pill_w * 0.5, center_y - pill_h * 0.5, pill_w, pill_h)
		draw_rect(pill_rect, Color(0.06, 0.08, 0.11, 0.86), true)
		draw_rect(pill_rect, Color(1.0, 1.0, 1.0, 0.16), false, 1.0)

		var cur_x: float = pill_rect.position.x + pad_h
		if is_hold:
			draw_string(font, Vector2(cur_x, pill_rect.position.y + 25.0), prefix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#f8fafc"))
			cur_x += prefix_w + gap

		var key_rect := Rect2(cur_x, pill_rect.position.y + (pill_h - key_h) * 0.5, key_w, key_h)
		draw_rect(key_rect, Color("#f8fafc"), true)
		draw_rect(key_rect, Color("#94a3b8"), false, 1.0)

		var e_w: float = font.get_string_size("E", HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_string(font, Vector2(key_rect.position.x + (key_w - e_w) * 0.5, key_rect.position.y + 20.0), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#0f172a"))

		if hud.hold_progress > 0.0:
			var center_pt: Vector2 = key_rect.get_center()
			draw_arc(center_pt, key_w * 0.72, -PI * 0.5, -PI * 0.5 + TAU * clampf(hud.hold_progress, 0.0, 1.0), 24, Color("#f59e0b"), 3.0, true)

		cur_x += key_w + gap
		var suf_pos := Vector2(cur_x, pill_rect.position.y + 25.0)
		if hud.prompt_action_type == "deathbox":
			var p1 := "使用 "
			var p1_w: float = font.get_string_size(p1, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_string(font, suf_pos, p1, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#f8fafc"))
			var p2 := hud.prompt_target_name
			var p2_w: float = font.get_string_size(p2, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_string(font, Vector2(suf_pos.x + p1_w, suf_pos.y), p2, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#fb7185"))
			draw_string(font, Vector2(suf_pos.x + p1_w + p2_w, suf_pos.y), " 的物品", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#f8fafc"))
		else:
			draw_string(font, suf_pos, suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#f8fafc"))

class MinimapWidget extends Control:
	var hud: ApexAuthenticHUD

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if hud == null:
			return

		var font: Font = get_theme_default_font()
		var map_pos := Vector2(24.0, 44.0)
		var map_size := Vector2(170.0, 170.0)

		var m_badge_rect := Rect2(map_pos.x, map_pos.y - 24.0, 20.0, 20.0)
		draw_rect(m_badge_rect, Color("#f8fafc"), true)
		var m_w: float = font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(font, Vector2(m_badge_rect.position.x + (20.0 - m_w) * 0.5, m_badge_rect.position.y + 15.0), "M", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#0f172a"))

		var rec_txt: String = "🔴 [F8] 行为录制中 (%d)" % BehaviorRecorder.recorded_frames.size() if BehaviorRecorder.is_recording else ("🧠 [F9] AI模仿已激活" if BehaviorRecorder.use_imitation_ai else "[F8] 录行为 [F9] 训AI")
		var rec_col: Color = Color("#ef4444") if BehaviorRecorder.is_recording else (Color("#22c55e") if BehaviorRecorder.use_imitation_ai else Color("#94a3b8"))
		draw_string(font, Vector2(map_pos.x + 26.0, map_pos.y - 9.0), rec_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, rec_col)

		var map_rect := Rect2(map_pos, map_size)
		draw_rect(map_rect, Color(0.06, 0.09, 0.13, 0.82), true)
		draw_rect(map_rect, Color(0.35, 0.42, 0.52, 0.65), false, 1.5)

		var center := map_rect.get_center()
		var col_topo := Color(0.18, 0.24, 0.32, 0.75)
		draw_line(Vector2(map_pos.x + 20, map_pos.y + 40), Vector2(map_pos.x + 85, map_pos.y + 60), col_topo, 1.5)
		draw_line(Vector2(map_pos.x + 85, map_pos.y + 60), Vector2(map_pos.x + 140, map_pos.y + 35), col_topo, 1.5)
		draw_line(Vector2(map_pos.x + 30, map_pos.y + 110), Vector2(map_pos.x + 90, map_pos.y + 130), col_topo, 1.5)

		draw_arc(center + Vector2(6, -4), 62.0, 0, TAU, 32, Color(0.13, 0.77, 0.36, 0.7), 2.0)
		draw_arc(center + Vector2(10, 8), 76.0, 0, TAU, 32, Color(0.98, 0.55, 0.15, 0.85), 2.0)

		var tm1_pos: Vector2 = center + Vector2(-32, -38)
		draw_circle(tm1_pos, 5.0, Color("#22c55e"))
		var tm2_pos: Vector2 = center + Vector2(-55, 24)
		draw_circle(tm2_pos, 5.0, Color("#06b6d4"))

		var yaw_rad: float = deg_to_rad(-hud.camera_heading_deg)
		var fwd := Vector2(sin(yaw_rad), -cos(yaw_rad))
		var rgt := Vector2(-fwd.y, fwd.x)
		var tri_pts := PackedVector2Array([center + fwd * 9.0, center - fwd * 6.0 + rgt * 6.0, center - fwd * 2.0, center - fwd * 6.0 - rgt * 6.0])
		draw_colored_polygon(tri_pts, Color("#facc15"))

class RoundRingWidget extends Control:
	var hud: ApexAuthenticHUD

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if hud == null:
			return
		var font: Font = get_theme_default_font()
		var center := Vector2(88.0, 276.0)
		var radius: float = 46.0

		draw_circle(center, radius, Color(0.06, 0.08, 0.11, 0.88))
		draw_circle(center, radius, Color(0.25, 0.3, 0.38, 0.5), false, 2.0)

		var frac: float = clampf(hud.round_timer / 240.0, 0.0, 1.0)
		draw_arc(center, radius + 2.5, -PI * 0.5, -PI * 0.5 + TAU * frac, 36, Color("#ea580c"), 3.5, true)

		var r_txt := "第 %d 回合" % hud.round_stage
		var r_w: float = font.get_string_size(r_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2(center.x - r_w * 0.5, center.y - 12.0), r_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#cbd5e1"))

		var mins: int = int(hud.round_timer) / 60
		var secs: int = int(hud.round_timer) % 60
		var t_txt := "%d %02d" % [mins, secs]
		var t_w: float = font.get_string_size(t_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		draw_string(font, Vector2(center.x - t_w * 0.5, center.y + 18.0), t_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#ffffff"))

class CompassWidget extends Control:
	var hud: ApexAuthenticHUD

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if hud == null:
			return
		var vp_w: float = get_viewport_rect().size.x
		var center_x: float = vp_w * 0.50
		var compass_y: float = 22.0
		var font: Font = get_theme_default_font()

		var cur_bearing: float = hud.camera_heading_deg
		var px_per_deg: float = 4.8
		var half_span_deg: float = 55.0

		draw_line(Vector2(center_x - 260, compass_y + 12), Vector2(center_x + 260, compass_y + 12), Color(1, 1, 1, 0.15), 1.0)

		var min_deg: int = int(cur_bearing - half_span_deg) - 5
		var max_deg: int = int(cur_bearing + half_span_deg) + 5

		for d in range(min_deg, max_deg + 1):
			if d % 5 != 0:
				continue
			var norm_deg: int = posmod(d, 360)
			var offset_deg: float = float(d) - cur_bearing
			var draw_x: float = center_x + offset_deg * px_per_deg
			if draw_x < center_x - 250 or draw_x > center_x + 250:
				continue
			var is_major: bool = (norm_deg % 15 == 0)
			var is_cardinal: bool = (norm_deg % 45 == 0)
			var tick_h: float = 8.0 if is_major else 4.0
			draw_line(Vector2(draw_x, compass_y + 12), Vector2(draw_x, compass_y + 12 - tick_h), Color(1, 1, 1, 0.6) if is_major else Color(1, 1, 1, 0.25), 1.2)
			if is_major:
				var lbl := str(norm_deg)
				match norm_deg:
					0: lbl = "N"
					45: lbl = "NE"
					90: lbl = "E"
					135: lbl = "SE"
					180: lbl = "S"
					225: lbl = "SW"
					270: lbl = "W"
					315: lbl = "NW"
				var col := Color("#ffffff") if is_cardinal else Color("#94a3b8")
				var f_sz: int = 13 if is_cardinal else 11
				var w: float = font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz).x
				draw_string(font, Vector2(draw_x - w * 0.5, compass_y - 2.0), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, col)

		var b_str := str(int(cur_bearing))
		var b_w: float = font.get_string_size(b_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		draw_string(font, Vector2(center_x - b_w * 0.5, compass_y + 36.0), b_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffffff"))

class TopRightWidget extends Control:
	var hud: ApexAuthenticHUD

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if hud == null:
			return
		var vp_w: float = get_viewport_rect().size.x
		var font: Font = get_theme_default_font()
		var right_margin: float = 30.0
		var top_y: float = 40.0

		var is_victory: bool = PlayerState.match_ended or PlayerState.squads_alive <= 1
		var is_final_two: bool = not is_victory and PlayerState.squads_alive == 2

		var badge_w: float = 248.0 if is_victory else 230.0
		var badge_h: float = 30.0
		var badge_x: float = vp_w - right_margin - badge_w
		var badge_y: float = top_y
		var slant: float = 10.0
		var b_pts := PackedVector2Array([
			Vector2(badge_x + slant, badge_y),
			Vector2(badge_x + badge_w, badge_y),
			Vector2(badge_x + badge_w - slant, badge_y + badge_h),
			Vector2(badge_x, badge_y + badge_h)
		])

		if is_victory:
			draw_colored_polygon(b_pts, Color(0.22, 0.16, 0.04, 0.94))
			draw_polyline(b_pts, Color(0.96, 0.78, 0.20, 1.0), 2.0)
			draw_line(Vector2(badge_x + slant + 4, badge_y + 2), Vector2(badge_x + badge_w - 4, badge_y + 2), Color(1.0, 0.9, 0.4, 0.6), 1.2)

			draw_string(font, Vector2(badge_x + 12, badge_y + 21), "🏆 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fbbf24"))
			draw_string(font, Vector2(badge_x + 54, badge_y + 20), "捍卫者小队 (CHAMPION)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#fef08a"))
			draw_string(font, Vector2(badge_x + 204, badge_y + 21), "👥 %d" % PlayerState.players_alive, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#86efac"))
		elif is_final_two:
			draw_colored_polygon(b_pts, Color(0.18, 0.06, 0.06, 0.92))
			draw_polyline(b_pts, Color(0.95, 0.35, 0.15, 0.95), 1.6)

			draw_string(font, Vector2(badge_x + 16, badge_y + 21), "2", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ef4444"))
			draw_string(font, Vector2(badge_x + 48, badge_y + 20), "决胜剩余小队", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#fca5a5"))
			var pl_txt := "👥 %d" % PlayerState.players_alive
			draw_string(font, Vector2(badge_x + 160, badge_y + 21), pl_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffffff"))
		else:
			draw_colored_polygon(b_pts, Color(0.06, 0.08, 0.12, 0.88))
			draw_polyline(b_pts, Color(1.0, 1.0, 1.0, 0.2), 1.2)

			var sq_num := str(PlayerState.squads_alive)
			draw_string(font, Vector2(badge_x + 16, badge_y + 21), sq_num, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffffff"))
			draw_string(font, Vector2(badge_x + 48, badge_y + 20), "剩余小队数量", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#cbd5e1"))
			var pl_txt := "👥 %d" % PlayerState.players_alive
			draw_string(font, Vector2(badge_x + 160, badge_y + 21), pl_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffffff"))

		var stats_y: float = badge_y + badge_h + 8.0
		var stats_w: float = 210.0
		var stats_h: float = 26.0
		var stats_x: float = vp_w - right_margin - stats_w
		var s_pts := PackedVector2Array([
			Vector2(stats_x + slant, stats_y),
			Vector2(stats_x + stats_w, stats_y),
			Vector2(stats_x + stats_w - slant, stats_y + stats_h),
			Vector2(stats_x, stats_y + stats_h)
		])
		draw_colored_polygon(s_pts, Color(0.06, 0.08, 0.12, 0.82))
		draw_string(font, Vector2(stats_x + 16, stats_y + 18), "💀 %d" % PlayerState.kills, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffffff"))
		draw_string(font, Vector2(stats_x + 85, stats_y + 18), "🎯 0", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#cbd5e1"))
		draw_string(font, Vector2(stats_x + 146, stats_y + 18), "💥 %d" % PlayerState.damage_dealt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffffff"))

		var kf_y: float = stats_y + stats_h + 20.0
		for item in hud.killfeed_items:
			var full_kf: String = "%s  %s  %s" % [item["text"], item["wep"], item["victim"]]
			var kw: float = font.get_string_size(full_kf, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			var kf_x: float = vp_w - right_margin - kw - 12.0
			draw_rect(Rect2(kf_x, kf_y - 14, kw + 20, 20), Color(0.08, 0.10, 0.14, 0.72), true)
			draw_string(font, Vector2(kf_x + 8, kf_y), full_kf, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffffff"))
			kf_y += 24.0

class BottomLeftWidget extends Control:
	var hud: ApexAuthenticHUD

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if hud == null:
			return
		var vp_h: float = get_viewport_rect().size.y
		var font: Font = get_theme_default_font()
		var base_x: float = 24.0
		var base_y: float = vp_h - 28.0

		_draw_teammate_card(base_x, base_y - 200.0, "chenbiubiu", "bloodhound", false)
		_draw_teammate_card(base_x, base_y - 150.0, "Mostimamywife", "octane", true)

		var p_card_y: float = base_y - 72.0
		var p_card_w: float = 330.0
		var p_card_h: float = 72.0

		var slant: float = 12.0
		var card_pts := PackedVector2Array([
			Vector2(base_x, p_card_y),
			Vector2(base_x + p_card_w, p_card_y),
			Vector2(base_x + p_card_w + slant, p_card_y + p_card_h),
			Vector2(base_x, p_card_y + p_card_h)
		])
		draw_colored_polygon(card_pts, Color(0.06, 0.08, 0.12, 0.88))
		draw_polyline(card_pts, Color(1.0, 1.0, 1.0, 0.15), 1.0)

		var av_rect := Rect2(base_x + 8, p_card_y + 9, 54.0, 54.0)
		_draw_legend_avatar(av_rect, PlayerState.selected_legend_id)

		var info_x: float = base_x + 72.0
		var leg_info: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
		draw_string(font, Vector2(info_x, p_card_y + 20), "%s // kisskiss" % str(leg_info["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f8fafc"))

		var tier: Dictionary = GameData.get_evo_tier(PlayerState.evo_level)
		var tier_col: Color = tier["color"]
		var evo_diff: int = maxi(0, PlayerState.next_evo_points - PlayerState.evo_points)
		draw_string(font, Vector2(info_x, p_card_y + 35), "距下次进化 🛡️ %d" % evo_diff, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, tier_col)

		var num_segs: int = maxi(1, int(tier["segments"]))
		var bar_w: float = 230.0
		var seg_gap: float = 4.0
		var seg_w: float = (bar_w - float(num_segs - 1) * seg_gap) / float(num_segs)
		var bar_y: float = p_card_y + 40.0

		for s in range(num_segs):
			var sx: float = info_x + float(s) * (seg_w + seg_gap)
			var s_pts := PackedVector2Array([
				Vector2(sx + 3.0, bar_y),
				Vector2(sx + seg_w + 3.0, bar_y),
				Vector2(sx + seg_w, bar_y + 8.0),
				Vector2(sx, bar_y + 8.0)
			])
			draw_colored_polygon(s_pts, Color(0.12, 0.16, 0.22, 0.85))
			var seg_fill: float = clampf((PlayerState.shield - float(s * 25)) / 25.0, 0.0, 1.0)
			if seg_fill > 0.0:
				var fill_w: float = seg_w * seg_fill
				var f_pts := PackedVector2Array([
					Vector2(sx + 3.0, bar_y),
					Vector2(sx + fill_w + 3.0, bar_y),
					Vector2(sx + fill_w, bar_y + 8.0),
					Vector2(sx, bar_y + 8.0)
				])
				draw_colored_polygon(f_pts, tier_col)

		var hp_y: float = bar_y + 11.0
		var hp_frac: float = clampf(PlayerState.hp / maxf(1.0, PlayerState.max_hp), 0.0, 1.0)
		draw_rect(Rect2(info_x, hp_y, 230.0, 7.0), Color(0.1, 0.14, 0.18, 0.9), true)
		draw_rect(Rect2(info_x, hp_y, 230.0 * hp_frac, 7.0), Color("#ffffff"), true)

		var heal_x: float = base_x + p_card_w + 24.0
		var heal_y: float = p_card_y + 22.0
		var hid: String = PlayerState.selected_heal_id
		var hcnt: int = int(PlayerState.consumables.get(hid, 0))
		var h_icon: String = "🔋%d" % hcnt if (hid == "shield_battery" or hid == "shield_cell" or hid == "phoenix_kit") else "💉%d" % hcnt
		var h_col: Color = Color("#38bdf8") if (hid == "shield_battery" or hid == "shield_cell") else (Color("#a855f7") if hid == "phoenix_kit" else Color("#22c55e"))
		_draw_quick_slot(Vector2(heal_x, heal_y), "4 [H切]", h_icon, h_col)

		var tac_x: float = heal_x + 52.0
		var tac_txt: String = "Q" if PlayerState.tac_cooldown <= 0.0 else "%.0fs" % PlayerState.tac_cooldown
		_draw_quick_slot(Vector2(tac_x, heal_y), tac_txt, "⚡", Color("#fbbf24"))

	func _draw_teammate_card(tx: float, ty: float, tname: String, leg_id: String, is_healing: bool) -> void:
		var font: Font = get_theme_default_font()
		var card_w: float = 210.0
		var card_h: float = 38.0
		var c_pts := PackedVector2Array([
			Vector2(tx, ty),
			Vector2(tx + card_w, ty),
			Vector2(tx + card_w + 8.0, ty + card_h),
			Vector2(tx, ty + card_h)
		])
		draw_colored_polygon(c_pts, Color(0.06, 0.08, 0.12, 0.82))
		_draw_legend_avatar(Rect2(tx + 4, ty + 4, 30, 30), leg_id)
		draw_string(font, Vector2(tx + 40.0, ty + 16), "%s 🔊" % tname, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f1f5f9"))
		draw_rect(Rect2(tx + 40.0, ty + 20.0, 58.0, 4.0), Color("#f8fafc"), true)
		draw_rect(Rect2(tx + 102.0, ty + 20.0, 58.0, 4.0), Color("#f8fafc"), true)
		draw_rect(Rect2(tx + 40.0, ty + 26.0, 120.0, 4.0), Color("#ffffff"), true)
		if is_healing:
			draw_rect(Rect2(tx + card_w - 22.0, ty + 6, 18, 18), Color(0.1, 0.6, 0.4, 0.9), true)

	func _draw_legend_avatar(rect: Rect2, leg_id: String) -> void:
		var center := rect.get_center()
		var rad: float = rect.size.x * 0.5
		var hex := PackedVector2Array()
		for i in range(6):
			var ang: float = float(i) * TAU / 6.0 - PI * 0.5
			hex.append(center + Vector2(cos(ang), sin(ang)) * rad)
		draw_colored_polygon(hex, Color(0.15, 0.18, 0.25, 0.95))
		draw_polyline(hex, Color("#38bdf8"), 1.5)
		var leg: Dictionary = GameData.get_legend_by_id(leg_id)
		draw_circle(center, rad * 0.58, leg.get("primary_color", Color("#64748b")))
		draw_rect(Rect2(center.x - rad * 0.38, center.y - rad * 0.14, rad * 0.76, rad * 0.28), leg.get("visor_color", Color("#38bdf8")), true)

	func _draw_quick_slot(pos: Vector2, key: String, icon_txt: String, col: Color) -> void:
		var font: Font = get_theme_default_font()
		var slot_size := Vector2(44.0, 40.0)
		var s_rect := Rect2(pos, slot_size)
		draw_rect(s_rect, Color(0.06, 0.08, 0.12, 0.85), true)
		draw_rect(s_rect, Color(1, 1, 1, 0.2), false, 1.0)
		var iw: float = font.get_string_size(icon_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2(pos.x + (slot_size.x - iw) * 0.5, pos.y + 18), icon_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		var kw: float = font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(font, Vector2(pos.x + (slot_size.x - kw) * 0.5, pos.y + 34), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#cbd5e1"))

class BottomCenterWidget extends Control:
	var hud: ApexAuthenticHUD

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if hud == null:
			return
		var vp := get_viewport_rect().size
		var center := Vector2(vp.x * 0.49, vp.y - 48.0)
		var font: Font = get_theme_default_font()
		var d_rad: float = 24.0
		var diamond := PackedVector2Array([
			center + Vector2(0, -d_rad),
			center + Vector2(d_rad * 0.9, 0),
			center + Vector2(0, d_rad * 0.8),
			center + Vector2(-d_rad * 0.9, 0)
		])
		draw_colored_polygon(diamond, Color(0.06, 0.08, 0.12, 0.88))
		draw_polyline(diamond, Color(1.0, 1.0, 1.0, 0.2), 1.2)
		var charge_frac: float = clampf(PlayerState.ult_charge / 100.0, 0.0, 1.0)
		draw_arc(center, d_rad + 4.0, -PI * 0.5, -PI * 0.5 + TAU * charge_frac, 24, Color("#f59e0b") if charge_frac >= 1.0 else Color("#cbd5e1"), 2.5, true)
		var u_txt := "就绪 [Z]" if PlayerState.ult_charge >= 100.0 else "%d%%" % int(PlayerState.ult_charge)
		var u_w: float = font.get_string_size(u_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(font, Vector2(center.x - u_w * 0.5, center.y + d_rad + 18.0), u_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#cbd5e1"))

class BottomRightWidget extends Control:
	var hud: ApexAuthenticHUD

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if hud == null:
			return
		var vp := get_viewport_rect().size
		var font: Font = get_theme_default_font()
		var right_margin: float = 30.0
		var panel_w: float = 380.0
		var panel_h: float = 76.0
		var base_x: float = vp.x - right_margin - panel_w
		var base_y: float = vp.y - 128.0

		var tab_y: float = base_y + panel_h + 4.0
		var tab_w: float = 140.0
		var wep0_name := "空槽位"
		var wep1_name := "空槽位"

		if PlayerState.loadout.size() > 0:
			var wid0: String = str(PlayerState.loadout[0].get("weapon_id", "empty"))
			if wid0 != "empty" and wid0 != "":
				wep0_name = str(GameData.get_weapon_by_id(wid0).get("name", "武器 1")).replace(" ", "")
		if PlayerState.loadout.size() > 1:
			var wid1: String = str(PlayerState.loadout[1].get("weapon_id", "empty"))
			if wid1 != "empty" and wid1 != "":
				wep1_name = str(GameData.get_weapon_by_id(wid1).get("name", "武器 2")).replace(" ", "")

		var active_slot: int = clampi(PlayerState.active_slot, 0, 1)
		var t0_x: float = vp.x - right_margin - (tab_w * 2.0 + 8.0)
		_draw_weapon_tab(Vector2(t0_x, tab_y), "1", wep0_name, active_slot == 0 and PlayerState.active_slot != 2)
		_draw_weapon_tab(Vector2(t0_x + tab_w + 6.0, tab_y), "2", wep1_name, active_slot == 1 and PlayerState.active_slot != 2)

		var slant: float = 16.0
		var p_pts := PackedVector2Array([
			Vector2(base_x + slant, base_y),
			Vector2(base_x + panel_w, base_y),
			Vector2(base_x + panel_w, base_y + panel_h),
			Vector2(base_x, base_y + panel_h)
		])
		draw_colored_polygon(p_pts, Color(0.06, 0.08, 0.12, 0.88))
		draw_polyline(p_pts, Color(1.0, 1.0, 1.0, 0.15), 1.0)

		var cur_slot: Dictionary = PlayerState.loadout[active_slot] if active_slot < PlayerState.loadout.size() else {}
		var cur_wid: String = str(cur_slot.get("weapon_id", "empty"))
		var is_cur_empty: bool = (cur_wid == "empty" or cur_wid == "" or PlayerState.active_slot == 2)
		var cur_ammo: int = int(cur_slot.get("ammo", 0)) if not is_cur_empty else 0
		var wep_info: Dictionary = GameData.get_weapon_by_id(cur_wid) if not is_cur_empty else {}
		var sil_pos := Vector2(base_x + 36.0, base_y + 24.0)

		if not is_cur_empty:
			_draw_weapon_silhouette(sil_pos, cur_wid, str(wep_info.get("cat", "AR")))
			var cat_txt := "[%s]" % str(wep_info.get("cat", "AR"))
			draw_string(font, Vector2(base_x + 62.0, base_y + 62.0), cat_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#38bdf8"))

			var ammo_type: String = str(wep_info.get("ammo", "light"))
			# Live-read reserve ammo directly from backpack inventory so HUD & Backpack NEVER diverge!
			var res_ammo: int = PlayerState.get_reserve_ammo(ammo_type)
			if cur_wid == "bocek":
				cur_ammo = res_ammo

			var ammo_str := str(cur_ammo)
			var ammo_w: float = font.get_string_size(ammo_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x
			var num_x: float = base_x + 185.0
			draw_string(font, Vector2(num_x, base_y + 52.0), ammo_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color("#ffffff"))

			var res_str := "| %d" % res_ammo
			draw_string(font, Vector2(num_x + ammo_w + 10.0, base_y + 44.0), res_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#cbd5e1"))

			var caliber_pos := Vector2(base_x + panel_w - 38.0, base_y + 36.0)
			_draw_ammo_type_badge(caliber_pos, ammo_type)
		else:
			draw_string(font, Vector2(base_x + 45.0, base_y + 42.0), "🗡️ 传家宝 / 近战", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c084fc"))
			draw_string(font, Vector2(base_x + 190.0, base_y + 52.0), "--", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color("#64748b"))

	func _draw_weapon_tab(pos: Vector2, slot_num: String, title: String, is_active: bool) -> void:
		var font: Font = get_theme_default_font()
		var tab_w: float = 140.0
		var tab_h: float = 24.0
		var slant: float = 6.0
		var pts := PackedVector2Array([
			Vector2(pos.x + slant, pos.y),
			Vector2(pos.x + tab_w, pos.y),
			Vector2(pos.x + tab_w - slant, pos.y + tab_h),
			Vector2(pos.x, pos.y + tab_h)
		])
		if is_active:
			draw_colored_polygon(pts, Color("#f8fafc"))
			var k_rect := Rect2(pos.x + 10.0, pos.y + 4.0, 16.0, 16.0)
			draw_rect(k_rect, Color("#0f172a"), true)
			draw_string(font, Vector2(k_rect.position.x + 4.0, k_rect.position.y + 12.0), slot_num, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f8fafc"))
			draw_string(font, Vector2(pos.x + 32.0, pos.y + 17), title, HORIZONTAL_ALIGNMENT_LEFT, 102, 13, Color("#0f172a"))
		else:
			draw_colored_polygon(pts, Color(0.1, 0.14, 0.2, 0.85))
			draw_polyline(pts, Color(1, 1, 1, 0.15), 1.0)
			var k_rect := Rect2(pos.x + 10.0, pos.y + 4.0, 16.0, 16.0)
			draw_rect(k_rect, Color(1, 1, 1, 0.15), true)
			draw_string(font, Vector2(k_rect.position.x + 4.0, k_rect.position.y + 12.0), slot_num, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#cbd5e1"))
			draw_string(font, Vector2(pos.x + 32.0, pos.y + 16), title, HORIZONTAL_ALIGNMENT_LEFT, 102, 12, Color("#94a3b8"))

	func _draw_weapon_silhouette(pos: Vector2, wid: String = "r301", cat: String = "AR") -> void:
		var col := Color(1.0, 1.0, 1.0, 0.9)
		if wid == "bocek":
			draw_arc(pos + Vector2(18, 4), 18.0, -PI * 0.45, PI * 0.45, 16, Color("#f59e0b"), 2.5)
			draw_line(pos + Vector2(6, -12), pos + Vector2(6, 20), col, 1.5)
			draw_line(pos + Vector2(-4, 4), pos + Vector2(42, 4), Color("#38bdf8"), 2.0)
		elif cat == "SHOTGUN":
			draw_line(pos + Vector2(-18, 0), pos + Vector2(54, 0), col, 3.2)
			draw_line(pos + Vector2(-18, 5), pos + Vector2(36, 5), Color("#ef4444"), 2.2)
			draw_line(pos + Vector2(-18, 2), pos + Vector2(-32, 14), col, 2.5)
		elif wid == "chargerifle":
			draw_line(pos + Vector2(-22, -2), pos + Vector2(62, -2), col, 2.2)
			draw_line(pos + Vector2(-22, 4), pos + Vector2(62, 4), col, 2.2)
			draw_line(pos + Vector2(10, -5), pos + Vector2(10, 7), Color("#ff7700"), 2.0)
			draw_line(pos + Vector2(28, -5), pos + Vector2(28, 7), Color("#ff7700"), 2.0)
		else:
			draw_line(pos + Vector2(0, 0), pos + Vector2(58, 0), col, 2.0)
			draw_line(pos + Vector2(0, 0), pos + Vector2(-22, 6), col, 2.0)
			draw_line(pos + Vector2(-22, 6), pos + Vector2(-34, 14), col, 2.0)
			draw_line(pos + Vector2(16, 2), pos + Vector2(12, 16), col, 2.0)

	func _draw_ammo_type_badge(pos: Vector2, atype: String) -> void:
		match atype:
			"light":
				var b_rect := Rect2(pos.x - 11, pos.y - 18, 22, 36)
				draw_rect(b_rect, Color("#ea580c"), true)
				draw_rect(b_rect, Color("#fdba74"), false, 1.0)
			"heavy":
				draw_rect(Rect2(pos.x - 9, pos.y - 14, 18, 28), Color("#14b8a6"), true)
			"energy":
				draw_rect(Rect2(pos.x - 9, pos.y - 14, 18, 28), Color("#84cc16"), true)
			"shotgun":
				draw_rect(Rect2(pos.x - 9, pos.y - 14, 18, 28), Color("#ef4444"), true)
			"sniper":
				draw_rect(Rect2(pos.x - 9, pos.y - 14, 18, 28), Color("#38bdf8"), true)
			"arrows":
				draw_rect(Rect2(pos.x - 9, pos.y - 14, 18, 28), Color("#f59e0b"), true)
			_:
				draw_circle(pos, 8.0, Color("#ffffff"))

class ReticleWidget extends Control:
	var hud: ApexAuthenticHUD

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if hud == null:
			return
		if hud.player != null and hud.player.is_ads:
			return
		var vp: Vector2 = get_viewport_rect().size
		var c: Vector2 = vp * 0.5
		var col := Color(1.0, 1.0, 1.0, 0.78)
		var t_len: float = 7.0
		var gap: float = 6.0
		draw_line(c + Vector2(0, -gap - t_len), c + Vector2(0, -gap), col, 1.5)
		draw_line(c + Vector2(0, gap), c + Vector2(0, gap + t_len), col, 1.5)
		draw_line(c + Vector2(-gap - t_len, 0), c + Vector2(-gap, 0), col, 1.5)
		draw_line(c + Vector2(gap, 0), c + Vector2(gap + t_len, 0), col, 1.5)
		draw_circle(c, 1.4, Color(1, 1, 1, 0.88))
