class_name ApexAuthenticHUD
extends Control
## Authentic Apex Legends In-Game HUD for Godot 4.3
## Replicates 100% of the UI elements shown in the reference screenshot:
## 1. Deathbox Interaction Prompt: "长按 [E] 使用 MMzi-beng-gou 的物品" with white rounded keycap & circular hold progress
## 2. Top-Left: Square Minimap with [M] badge, topography, player & teammate icons, ring boundaries
## 3. Round Timer Gauge: Circular progress ring with "第 1 回合" and "3 90"
## 4. Top Compass Bar: Dynamic sliding compass tape with degree ticks, cardinals, and centered "< 62 >" bearing
## 5. Top-Right: "18 剩余小队数量 👥 54" badge, "💀 1 | 🎯 0 | 💥 250" stats row, diagnostic line, killfeed
## 6. Bottom-Left: Teammate 1 (Bloodhound chenbiubiu), Teammate 2 (Octane Mostimamywife), and Player (Valkyrie kisskiss)
##    with avatar portraits, helmet/shield badges, "距下次进化 300", 3 blue segments, health bar, [4] heal, [Q] tactical
## 7. Bottom-Center: Winged diamond ultimate charge widget with Valkyrie wings icon & "38%"
## 8. Bottom-Right: Dual weapon tabs ("1 莫桑比克", "2 R-301卡宾枪"), active weapon silhouette, fire selector [B],
##    giant "18 / 36" ammo display, orange light ammo chevron, [G] grenade, [LALT] survival slot

var player: CharacterBody3D
var weapon_ctrl: Node
var match_scene: Node

# Prompt state
var prompt_visible: bool = false
var prompt_is_hold: bool = true
var prompt_target_name: String = "MMzi-beng-gou"
var prompt_action_type: String = "deathbox" # "deathbox", "weapon", "supply_bin", "zipline", "generic"
var prompt_custom_text: String = ""
var hold_progress: float = 0.0 # 0.0 to 1.0

# Compass & Camera
var camera_heading_deg: float = 62.0

# Match time & Round timer
var round_timer: float = 228.0 # 3:48 (Matching reference screenshot digits)
var round_stage: int = 1

# Killfeed messages
var killfeed_items: Array = [
	{"text": "[OTTO] 输了可不好玩，所以我一直觉得不好玩", "wep": "🔫", "victim": "zcf_0205", "time": 12.0}
]

# Diagnostics
var diag_fps: int = 62
var diag_ping: int = 70

# Child components
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

	# 0. Center Reticle / Hipfire Crosshairs
	reticle_widget = ReticleWidget.new()
	reticle_widget.hud = self
	add_child(reticle_widget)

	# 1. Top Compass
	compass_widget = CompassWidget.new()
	compass_widget.hud = self
	add_child(compass_widget)

	# 2. Top-Left Minimap
	minimap_widget = MinimapWidget.new()
	minimap_widget.hud = self
	add_child(minimap_widget)

	# 3. Round Ring Timer
	round_ring_widget = RoundRingWidget.new()
	round_ring_widget.hud = self
	add_child(round_ring_widget)

	# 4. Top-Right Squads & Stats & Killfeed
	top_right_widget = TopRightWidget.new()
	top_right_widget.hud = self
	add_child(top_right_widget)

	# 5. Bottom-Left Squad & Player Card
	bottom_left_widget = BottomLeftWidget.new()
	bottom_left_widget.hud = self
	add_child(bottom_left_widget)

	# 6. Bottom-Center Ultimate Widget
	bottom_center_widget = BottomCenterWidget.new()
	bottom_center_widget.hud = self
	add_child(bottom_center_widget)

	# 7. Bottom-Right Weapon & Ammo HUD
	bottom_right_widget = BottomRightWidget.new()
	bottom_right_widget.hud = self
	add_child(bottom_right_widget)

	# 8. Center Interaction Prompt (Red-boxed prompt in user screenshot)
	interact_prompt_widget = InteractPromptWidget.new()
	interact_prompt_widget.hud = self
	add_child(interact_prompt_widget)

func _process(delta: float) -> void:
	# Update camera heading for compass & minimap
	if is_instance_valid(player):
		var cam: Camera3D = player.get_node_or_null("Camera3D")
		if cam:
			var rot_y: float = cam.global_rotation.y
			camera_heading_deg = fposmod(-rad_to_deg(rot_y), 360.0)
		else:
			camera_heading_deg = fposmod(-rad_to_deg(player.global_rotation.y), 360.0)
	
	# Update Round timer countdown
	round_timer = maxf(0.0, round_timer - delta)
	if round_timer <= 0.0:
		round_timer = 240.0 # reset to next round
		round_stage = clampi(round_stage + 1, 1, 5)

	# Update killfeed expiration
	for i in range(killfeed_items.size() - 1, -1, -1):
		killfeed_items[i]["time"] -= delta
		if killfeed_items[i]["time"] <= 0.0 and killfeed_items.size() > 1:
			killfeed_items.remove_at(i)

	diag_fps = int(Engine.get_frames_per_second())
	if diag_fps <= 0:
		diag_fps = 62

	# Request redraw on dynamic elements
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

# ==============================================================================
# SUB-WIDGET 1: CENTER INTERACTION PROMPT (MATCHING SCREENSHOT RED BOX)
# ==============================================================================
class InteractPromptWidget extends Control:
	var hud: ApexAuthenticHUD

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if hud == null or not hud.prompt_visible:
			return

		var vp_size: Vector2 = get_viewport_rect().size
		var center_x: float = vp_size.x * 0.58 # slightly right of center, matching screenshot position!
		var center_y: float = vp_size.y * 0.57

		var font: Font = get_theme_default_font()
		var font_size: int = 18

		# Determine text elements
		var is_hold: bool = hud.prompt_is_hold
		var prefix_text: String = "长按" if is_hold else ""
		var suffix_text: String = ""

		if hud.prompt_custom_text != "":
			suffix_text = hud.prompt_custom_text
		elif hud.prompt_action_type == "deathbox":
			suffix_text = "使用 %s 的物品" % hud.prompt_target_name
		elif hud.prompt_action_type == "weapon":
			suffix_text = "拾取 %s" % hud.prompt_target_name
		elif hud.prompt_action_type == "supply_bin":
			suffix_text = "打开 补给仓"
		elif hud.prompt_action_type == "zipline":
			suffix_text = "搭乘 滑索"
		else:
			suffix_text = "%s" % hud.prompt_target_name

		var prefix_w: float = font.get_string_size(prefix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x if is_hold else 0.0
		var suffix_w: float = font.get_string_size(suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var key_w: float = 28.0
		var key_h: float = 28.0
		var gap: float = 10.0
		var pad_h: float = 16.0
		var pad_v: float = 7.0

		var total_content_w: float = (prefix_w + gap if is_hold else 0.0) + key_w + gap + suffix_w
		var pill_w: float = total_content_w + pad_h * 2.0
		var pill_h: float = 38.0

		var pill_rect := Rect2(center_x - pill_w * 0.5, center_y - pill_h * 0.5, pill_w, pill_h)

		# 1. Dark pill translucent background (Authentic Apex dark pill)
		draw_rect(pill_rect, Color(0.06, 0.08, 0.11, 0.86), true)
		draw_rect(pill_rect, Color(1.0, 1.0, 1.0, 0.16), false, 1.0)

		# Subtle rounded corners by drawing small corner ticks/softening
		var cur_x: float = pill_rect.position.x + pad_h

		# 2. Draw "长按" prefix if hold
		if is_hold:
			var prefix_pos := Vector2(cur_x, pill_rect.position.y + 25.0)
			draw_string(font, prefix_pos, prefix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#f8fafc"))
			cur_x += prefix_w + gap

		# 3. Draw Key Badge [ E ]
		var key_rect := Rect2(cur_x, pill_rect.position.y + (pill_h - key_h) * 0.5, key_w, key_h)
		# White solid rounded keycap
		draw_rect(key_rect, Color("#f8fafc"), true)
		draw_rect(key_rect, Color("#94a3b8"), false, 1.0)

		# Center "E" letter in bold black
		var e_letter := "E"
		var e_w: float = font.get_string_size(e_letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		var e_pos := Vector2(key_rect.position.x + (key_w - e_w) * 0.5, key_rect.position.y + 20.0)
		draw_string(font, e_pos, e_letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#0f172a"))

		# Hold progress ring around keycap
		if hud.hold_progress > 0.0:
			var center_pt: Vector2 = key_rect.get_center()
			var radius: float = key_w * 0.72
			var start_ang: float = -PI * 0.5
			var sweep_ang: float = TAU * clampf(hud.hold_progress, 0.0, 1.0)
			draw_arc(center_pt, radius, start_ang, start_ang + sweep_ang, 24, Color("#f59e0b"), 3.0, true)

		cur_x += key_w + gap

		# 4. Draw Action & Target Name: "使用 MMzi-beng-gou 的物品"
		var suf_pos := Vector2(cur_x, pill_rect.position.y + 25.0)
		if hud.prompt_action_type == "deathbox":
			# Parse "使用 " + name + " 的物品" for highlighted target name
			var p1 := "使用 "
			var p1_w: float = font.get_string_size(p1, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_string(font, suf_pos, p1, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#f8fafc"))

			var p2 := hud.prompt_target_name
			var p2_w: float = font.get_string_size(p2, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var p2_pos := Vector2(suf_pos.x + p1_w, suf_pos.y)
			# Highlight enemy name in vibrant coral/orange
			draw_string(font, p2_pos, p2, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#fb7185"))

			var p3 := " 的物品"
			var p3_pos := Vector2(p2_pos.x + p2_w, suf_pos.y)
			draw_string(font, p3_pos, p3, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#f8fafc"))
		else:
			draw_string(font, suf_pos, suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#f8fafc"))

# ==============================================================================
# SUB-WIDGET 2: TOP-LEFT SQUARE MINIMAP WITH [M] BADGE & TOPOGRAPHY
# ==============================================================================
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

		# 1. [M] Key badge above top-left of minimap
		var m_badge_rect := Rect2(map_pos.x, map_pos.y - 24.0, 20.0, 20.0)
		draw_rect(m_badge_rect, Color("#f8fafc"), true)
		var m_w: float = font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(font, Vector2(m_badge_rect.position.x + (20.0 - m_w) * 0.5, m_badge_rect.position.y + 15.0), "M", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#0f172a"))

		# 2. Minimap frame and background
		var map_rect := Rect2(map_pos, map_size)
		draw_rect(map_rect, Color(0.06, 0.09, 0.13, 0.82), true)
		draw_rect(map_rect, Color(0.35, 0.42, 0.52, 0.65), false, 1.5)

		# 3. Topographic lines & canyon curves
		var center := map_rect.get_center()
		var col_topo := Color(0.18, 0.24, 0.32, 0.75)
		draw_line(Vector2(map_pos.x + 20, map_pos.y + 40), Vector2(map_pos.x + 85, map_pos.y + 60), col_topo, 1.5)
		draw_line(Vector2(map_pos.x + 85, map_pos.y + 60), Vector2(map_pos.x + 140, map_pos.y + 35), col_topo, 1.5)
		draw_line(Vector2(map_pos.x + 30, map_pos.y + 110), Vector2(map_pos.x + 90, map_pos.y + 130), col_topo, 1.5)
		draw_line(Vector2(map_pos.x + 90, map_pos.y + 130), Vector2(map_pos.x + 155, map_pos.y + 105), col_topo, 1.5)

		# Mountain ridges / canyon walls
		var col_ridge := Color(0.24, 0.32, 0.44, 0.55)
		draw_arc(Vector2(map_pos.x + 45, map_pos.y + 70), 30.0, 0.2, 2.8, 12, col_ridge, 2.0)
		draw_arc(Vector2(map_pos.x + 125, map_pos.y + 120), 35.0, 1.2, 4.2, 12, col_ridge, 2.0)

		# 4. Safe Ring Zone & Ring Closing Arc
		draw_arc(center + Vector2(6, -4), 62.0, 0, TAU, 32, Color(0.13, 0.77, 0.36, 0.7), 2.0) # Green Safe Zone
		draw_arc(center + Vector2(10, 8), 76.0, 0, TAU, 32, Color(0.98, 0.55, 0.15, 0.85), 2.0) # Orange Ring

		# 5. POI Indicators
		draw_circle(map_pos + Vector2(40, 50), 3.0, Color("#38bdf8"))
		draw_circle(map_pos + Vector2(130, 60), 3.0, Color("#f59e0b"))
		draw_circle(map_pos + Vector2(85, 140), 3.0, Color("#a855f7"))

		# 6. Deathbox Icon (matching the deathbox looked at in front!)
		var dbox_icon_pos: Vector2 = center + Vector2(8, -26)
		var d_pts := PackedVector2Array([
			dbox_icon_pos + Vector2(0, -5),
			dbox_icon_pos + Vector2(5, 0),
			dbox_icon_pos + Vector2(0, 5),
			dbox_icon_pos + Vector2(-5, 0)
		])
		draw_colored_polygon(d_pts, Color("#c084fc"))
		draw_polyline(d_pts, Color("#f8fafc"), 1.0)

		# 7. Teammate Icons (chenbiubiu & Mostimamywife)
		# Teammate 1 (Green 1)
		var tm1_pos: Vector2 = center + Vector2(-32, -38)
		draw_circle(tm1_pos, 5.0, Color("#22c55e"))
		draw_circle(tm1_pos, 5.0, Color("#ffffff"), false, 1.0)
		draw_string(font, tm1_pos + Vector2(-3, 4), "1", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#000000"))

		# Teammate 2 (Cyan 2)
		var tm2_pos: Vector2 = center + Vector2(-55, 24)
		draw_circle(tm2_pos, 5.0, Color("#06b6d4"))
		draw_circle(tm2_pos, 5.0, Color("#ffffff"), false, 1.0)
		draw_string(font, tm2_pos + Vector2(-3, 4), "2", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#000000"))

		# 8. Local Player Triangle Arrow in Center (Rotated to camera forward)
		var yaw_rad: float = deg_to_rad(-hud.camera_heading_deg)
		var fwd := Vector2(sin(yaw_rad), -cos(yaw_rad))
		var rgt := Vector2(-fwd.y, fwd.x)

		var p_tip := center + fwd * 9.0
		var p_left := center - fwd * 6.0 - rgt * 6.0
		var p_right := center - fwd * 6.0 + rgt * 6.0
		var p_inner := center - fwd * 2.0

		var tri_pts := PackedVector2Array([p_tip, p_right, p_inner, p_left])
		draw_colored_polygon(tri_pts, Color("#facc15"))
		draw_polyline(tri_pts, Color("#000000"), 1.2)

		# Compass tick on map rim (N)
		draw_string(font, Vector2(center.x - 4, map_pos.y + 12), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#94a3b8"))

# ==============================================================================
# SUB-WIDGET 3: ROUND 1 CIRCULAR PROGRESS GAUGE (第 1 回合 3 90)
# ==============================================================================
class RoundRingWidget extends Control:
	var hud: ApexAuthenticHUD

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if hud == null:
			return

		var font: Font = get_theme_default_font()
		var center := Vector2(88.0, 276.0) # Nestled directly below minimap as in screenshot
		var radius: float = 46.0

		# 1. Dark circular interior
		draw_circle(center, radius, Color(0.06, 0.08, 0.11, 0.88))
		draw_circle(center, radius, Color(0.25, 0.3, 0.38, 0.5), false, 2.0)

		# 2. Outer glowing orange circular arc (progress)
		var frac: float = clampf(hud.round_timer / 240.0, 0.0, 1.0)
		var start_ang: float = -PI * 0.5
		var sweep: float = TAU * frac
		draw_arc(center, radius + 2.5, start_ang, start_ang + sweep, 36, Color("#ea580c"), 3.5, true)
		draw_arc(center, radius + 2.5, start_ang + sweep, start_ang + TAU, 36, Color(0.2, 0.25, 0.35, 0.35), 2.0, true)

		# 3. Inner text: "第 1 回合"
		var r_txt := "第 %d 回合" % hud.round_stage
		var r_w: float = font.get_string_size(r_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2(center.x - r_w * 0.5, center.y - 12.0), r_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#cbd5e1"))

		# 4. Large bold countdown digits: "3 90" (or 3:45)
		var mins: int = int(hud.round_timer) / 60
		var secs: int = int(hud.round_timer) % 60
		var t_txt := "%d %02d" % [mins, secs]
		var t_w: float = font.get_string_size(t_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		draw_string(font, Vector2(center.x - t_w * 0.5, center.y + 18.0), t_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#ffffff"))

# ==============================================================================
# SUB-WIDGET 4: TOP COMPASS BAR WITH CENTER "< 62 >" BEARING
# ==============================================================================
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

		# 1. Subtle horizontal divider line
		draw_line(Vector2(center_x - 260, compass_y + 12), Vector2(center_x + 260, compass_y + 12), Color(1, 1, 1, 0.15), 1.0)

		# 2. Draw degree ticks and labels
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
			var tick_col := Color(1, 1, 1, 0.6) if is_major else Color(1, 1, 1, 0.25)
			draw_line(Vector2(draw_x, compass_y + 12), Vector2(draw_x, compass_y + 12 - tick_h), tick_col, 1.2)

			if is_major:
				var lbl := ""
				match norm_deg:
					0: lbl = "N"
					45: lbl = "NE"
					90: lbl = "E"
					135: lbl = "SE"
					180: lbl = "S"
					225: lbl = "SW"
					270: lbl = "W"
					315: lbl = "NW"
					_: lbl = str(norm_deg)

				var col := Color("#ffffff") if is_cardinal else Color("#94a3b8")
				var f_sz: int = 13 if is_cardinal else 11
				var w: float = font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz).x
				draw_string(font, Vector2(draw_x - w * 0.5, compass_y - 2.0), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, col)

		# 3. Authentic Apex Centered Bracket Notch: "< 62 >" or "[ 62 ]"
		var b_str := str(int(cur_bearing))
		var b_w: float = font.get_string_size(b_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x

		# Top pointer triangle
		var tri := PackedVector2Array([
			Vector2(center_x, compass_y + 14),
			Vector2(center_x - 4, compass_y + 20),
			Vector2(center_x + 4, compass_y + 20)
		])
		draw_colored_polygon(tri, Color("#ffffff"))

		# Bracket lines and bearing number
		var b_box_w: float = b_w + 20.0
		var b_y: float = compass_y + 36.0
		# Left bracket chevron
		draw_line(Vector2(center_x - b_box_w * 0.5, b_y - 10), Vector2(center_x - b_box_w * 0.5 - 5, b_y - 4), Color("#ffffff"), 1.8)
		draw_line(Vector2(center_x - b_box_w * 0.5 - 5, b_y - 4), Vector2(center_x - b_box_w * 0.5, b_y + 2), Color("#ffffff"), 1.8)
		# Bearing text
		draw_string(font, Vector2(center_x - b_w * 0.5, b_y), b_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffffff"))
		# Right bracket chevron
		draw_line(Vector2(center_x + b_box_w * 0.5, b_y - 10), Vector2(center_x + b_box_w * 0.5 + 5, b_y - 4), Color("#ffffff"), 1.8)
		draw_line(Vector2(center_x + b_box_w * 0.5 + 5, b_y - 4), Vector2(center_x + b_box_w * 0.5, b_y + 2), Color("#ffffff"), 1.8)

# ==============================================================================
# SUB-WIDGET 5: TOP-RIGHT (18 剩余小队数量 👥 54, 💀 1 | 🎯 0 | 💥 250, DIAGNOSTICS & KILLFEED)
# ==============================================================================
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

		# 1. Diagnostic info line (FPS 62 IO 60 5 loss 0/0 choke 0/0 ping 70ms)
		var diag_txt := "FPS %d  IO 60 5  loss 0/0  choke 0/0  ping %dms  887610:1403540618181" % [hud.diag_fps, hud.diag_ping]
		var diag_w: float = font.get_string_size(diag_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(font, Vector2(vp_w - right_margin - diag_w, 24.0), diag_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.75, 0.82, 0.6))

		# 2. "18 剩余小队数量 👥 54" Badge
		var badge_w: float = 230.0
		var badge_h: float = 30.0
		var badge_x: float = vp_w - right_margin - badge_w
		var badge_y: float = top_y

		# Slanted parallelogram badge
		var slant: float = 10.0
		var b_pts := PackedVector2Array([
			Vector2(badge_x + slant, badge_y),
			Vector2(badge_x + badge_w, badge_y),
			Vector2(badge_x + badge_w - slant, badge_y + badge_h),
			Vector2(badge_x, badge_y + badge_h)
		])
		draw_colored_polygon(b_pts, Color(0.06, 0.08, 0.12, 0.88))
		draw_polyline(b_pts, Color(1.0, 1.0, 1.0, 0.2), 1.2)

		# Squad count "18"
		var sq_num := str(PlayerState.squads_alive)
		draw_string(font, Vector2(badge_x + 16, badge_y + 21), sq_num, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffffff"))

		# "剩余小队数量"
		draw_string(font, Vector2(badge_x + 48, badge_y + 20), "剩余小队数量", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#cbd5e1"))

		# Player count "👥 54"
		var pl_txt := "👥 %d" % PlayerState.players_alive
		draw_string(font, Vector2(badge_x + 160, badge_y + 21), pl_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffffff"))

		# 3. Player Match Stats Strip: 💀 1 | 🎯 0 | 💥 250
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
		draw_polyline(s_pts, Color(1.0, 1.0, 1.0, 0.15), 1.0)

		# Skull Kills
		var k_txt := "💀 %d" % PlayerState.kills
		draw_string(font, Vector2(stats_x + 16, stats_y + 18), k_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffffff"))
		# Divider 1
		draw_line(Vector2(stats_x + 72, stats_y + 4), Vector2(stats_x + 72, stats_y + 22), Color(1, 1, 1, 0.2), 1.0)

		# Knockdowns/Assists
		var a_txt := "🎯 0"
		draw_string(font, Vector2(stats_x + 85, stats_y + 18), a_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#cbd5e1"))
		# Divider 2
		draw_line(Vector2(stats_x + 135, stats_y + 4), Vector2(stats_x + 135, stats_y + 22), Color(1, 1, 1, 0.2), 1.0)

		# Damage
		var d_txt := "💥 %d" % PlayerState.damage_dealt
		draw_string(font, Vector2(stats_x + 146, stats_y + 18), d_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffffff"))

		# 4. Authentic Apex Killfeed
		var kf_y: float = stats_y + stats_h + 20.0
		for item in hud.killfeed_items:
			var txt: String = item["text"]
			var wep: String = item["wep"]
			var vic: String = item["victim"]
			var full_kf: String = "%s  %s  %s" % [txt, wep, vic]
			var kw: float = font.get_string_size(full_kf, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			var kf_x: float = vp_w - right_margin - kw - 12.0

			# Subtle dark pill background
			var k_rect := Rect2(kf_x, kf_y - 14, kw + 20, 20)
			draw_rect(k_rect, Color(0.08, 0.10, 0.14, 0.72), true)

			# Attacker name
			var tw1: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string(font, Vector2(kf_x + 8, kf_y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffffff"))

			# Weapon icon
			var tw2: float = font.get_string_size(wep, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string(font, Vector2(kf_x + 8 + tw1 + 8, kf_y), wep, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#94a3b8"))

			# Victim name in red
			draw_string(font, Vector2(kf_x + 8 + tw1 + 8 + tw2 + 8, kf_y), vic, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ff4757"))

			kf_y += 24.0

# ==============================================================================
# SUB-WIDGET 6: BOTTOM-LEFT SQUAD & PLAYER MAIN HUD (Valkyrie kisskiss, chenbiubiu, Mostimamywife)
# ==============================================================================
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

		# ----------------------------------------------------------------------
		# 0. In-World Teammate Location Indicator: "▲ Mostimamywife"
		# ----------------------------------------------------------------------
		var pin_pos := Vector2(base_x + 8.0, base_y - 224.0)
		draw_string(font, pin_pos, "▲ Mostimamywife", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#22c55e"))

		# ----------------------------------------------------------------------
		# 1. Teammate 1 Banner: Bloodhound "chenbiubiu"
		# ----------------------------------------------------------------------
		var tm1_y: float = base_y - 200.0
		_draw_teammate_card(base_x, tm1_y, "chenbiubiu", "bloodhound", 50.0, 100.0, false)

		# ----------------------------------------------------------------------
		# 2. Teammate 2 Banner: Octane "Mostimamywife" (with Medkit healing icon)
		# ----------------------------------------------------------------------
		var tm2_y: float = base_y - 150.0
		_draw_teammate_card(base_x, tm2_y, "Mostimamywife", "octane", 50.0, 100.0, true)

		# ----------------------------------------------------------------------
		# 3. Local Player Main Card: Valkyrie "kisskiss"
		# ----------------------------------------------------------------------
		var p_card_y: float = base_y - 72.0
		var p_card_w: float = 330.0
		var p_card_h: float = 72.0

		# Dark angled card background
		var slant: float = 12.0
		var card_pts := PackedVector2Array([
			Vector2(base_x, p_card_y),
			Vector2(base_x + p_card_w, p_card_y),
			Vector2(base_x + p_card_w + slant, p_card_y + p_card_h),
			Vector2(base_x, p_card_y + p_card_h)
		])
		draw_colored_polygon(card_pts, Color(0.06, 0.08, 0.12, 0.88))
		draw_polyline(card_pts, Color(1.0, 1.0, 1.0, 0.15), 1.0)

		# Avatar Box (Valkyrie Portrait in hexagon/angled frame)
		var av_size: float = 54.0
		var av_rect := Rect2(base_x + 8, p_card_y + 9, av_size, av_size)
		_draw_legend_avatar(av_rect, "valkyrie")

		# Player Name & Speaker icon: "kisskiss 🔊"
		var info_x: float = base_x + 72.0
		draw_string(font, Vector2(info_x, p_card_y + 20), "kisskiss 🔊", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#f8fafc"))

		# Helmet & Shield tier badges (Blue Lv.2)
		var icon_x: float = base_x + 240.0
		_draw_helmet_icon(Vector2(icon_x, p_card_y + 10), Color("#38bdf8"))
		_draw_armor_shield_icon(Vector2(icon_x + 22, p_card_y + 10), Color("#38bdf8"))

		# "距下次进化 300"
		var evo_diff: int = maxi(0, PlayerState.next_evo_points - PlayerState.evo_points)
		var evo_txt := "距下次进化 🛡️ %d" % evo_diff
		draw_string(font, Vector2(info_x, p_card_y + 35), evo_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#38bdf8"))

		# Segmented Evo Shield Bars (3 Blue segments of 25 HP each)
		var tier: Dictionary = GameData.get_evo_tier(PlayerState.evo_level)
		var num_segs: int = int(tier["segments"])
		var tier_col: Color = tier["color"]
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
			# Background empty segment
			draw_colored_polygon(s_pts, Color(0.12, 0.16, 0.22, 0.85))

			# Filled portion
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

		# Health Bar (Solid wide white bar, 100 HP)
		var hp_y: float = bar_y + 11.0
		var hp_bar_w: float = 230.0
		var hp_bar_h: float = 7.0
		var hp_frac: float = clampf(PlayerState.hp / maxf(1.0, PlayerState.max_hp), 0.0, 1.0)

		# HP track
		draw_rect(Rect2(info_x, hp_y, hp_bar_w, hp_bar_h), Color(0.1, 0.14, 0.18, 0.9), true)
		# HP fill (Solid white/bright green)
		draw_rect(Rect2(info_x, hp_y, hp_bar_w * hp_frac, hp_bar_h), Color("#ffffff"), true)

		# 4. Quick Heal Slot [4] & Tactical Skill Slot [Q] to the right/below
		# Quick Heal [4]
		var heal_x: float = base_x + p_card_w + 24.0
		var heal_y: float = p_card_y + 22.0
		_draw_quick_slot(Vector2(heal_x, heal_y), "4", "💉 5", Color("#38bdf8"))

		# Tactical [Q]
		var tac_x: float = heal_x + 52.0
		var tac_y: float = heal_y
		var tac_txt: String = "Q" if PlayerState.tac_cooldown <= 0.0 else "%.0f" % PlayerState.tac_cooldown
		_draw_quick_slot(Vector2(tac_x, tac_y), "Q", "🚀", Color("#fbbf24"))

	func _draw_teammate_card(tx: float, ty: float, tname: String, leg_id: String, shield_hp: float, hp_val: float, is_healing: bool) -> void:
		var font: Font = get_theme_default_font()
		var card_w: float = 210.0
		var card_h: float = 38.0

		# Background
		var slant: float = 8.0
		var c_pts := PackedVector2Array([
			Vector2(tx, ty),
			Vector2(tx + card_w, ty),
			Vector2(tx + card_w + slant, ty + card_h),
			Vector2(tx, ty + card_h)
		])
		draw_colored_polygon(c_pts, Color(0.06, 0.08, 0.12, 0.82))
		draw_polyline(c_pts, Color(1.0, 1.0, 1.0, 0.12), 1.0)

		# Teammate avatar
		var av_rect := Rect2(tx + 4, ty + 4, 30, 30)
		_draw_legend_avatar(av_rect, leg_id)

		# Name: "chenbiubiu 🔊"
		var nx: float = tx + 40.0
		draw_string(font, Vector2(nx, ty + 16), "%s 🔊" % tname, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f1f5f9"))

		# Shield bar (2 white segments of 25 HP each)
		var bar_w: float = 120.0
		var seg_w: float = 58.0
		var bar_y: float = ty + 20.0
		for s in range(2):
			var sx: float = nx + float(s) * 62.0
			draw_rect(Rect2(sx, bar_y, seg_w, 4.0), Color("#f8fafc"), true)

		# HP bar (solid white)
		draw_rect(Rect2(nx, bar_y + 6.0, bar_w, 4.0), Color("#ffffff"), true)

		# Healing icon if healing
		if is_healing:
			var h_x: float = tx + card_w - 22.0
			var h_rect := Rect2(h_x, ty + 6, 18, 18)
			draw_rect(h_rect, Color(0.1, 0.6, 0.4, 0.9), true)
			draw_rect(h_rect, Color("#22c55e"), false, 1.0)
			draw_string(font, Vector2(h_x + 4, ty + 20), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#ffffff"))

	func _draw_legend_avatar(rect: Rect2, leg_id: String) -> void:
		# Hexagon/angled frame
		var center := rect.get_center()
		var rad: float = rect.size.x * 0.5

		# Hexagon points
		var hex := PackedVector2Array()
		for i in range(6):
			var ang: float = float(i) * TAU / 6.0 - PI * 0.5
			hex.append(center + Vector2(cos(ang), sin(ang)) * rad)

		draw_colored_polygon(hex, Color(0.15, 0.18, 0.25, 0.95))
		draw_polyline(hex, Color("#38bdf8"), 1.5)

		# Legend stylized vector face
		match leg_id:
			"valkyrie":
				# Valkyrie aviator helmet with orange visor & headset
				var head_c := center + Vector2(0, 2)
				draw_circle(head_c, rad * 0.62, Color("#6d28d9")) # Purple flight helmet
				# Orange visor
				var visor_rect := Rect2(head_c.x - rad * 0.45, head_c.y - rad * 0.15, rad * 0.9, rad * 0.35)
				draw_rect(visor_rect, Color("#f97316"), true)
				# Chin strap
				draw_line(Vector2(head_c.x - rad * 0.3, head_c.y + rad * 0.35), Vector2(head_c.x + rad * 0.3, head_c.y + rad * 0.35), Color("#cbd5e1"), 2.0)
			"bloodhound":
				# Brown hunter cowl with red glowing lenses
				var head_c := center + Vector2(0, 2)
				draw_circle(head_c, rad * 0.65, Color("#78350f"))
				# Red goggles
				draw_circle(head_c + Vector2(-6, -2), 4.0, Color("#ef4444"))
				draw_circle(head_c + Vector2(6, -2), 4.0, Color("#ef4444"))
			"octane":
				# Dark green skull mask with goggles
				var head_c := center + Vector2(0, 2)
				draw_circle(head_c, rad * 0.65, Color("#365314"))
				# Green goggles
				draw_circle(head_c + Vector2(-5, -2), 4.5, Color("#84cc16"))
				draw_circle(head_c + Vector2(5, -2), 4.5, Color("#84cc16"))
			_:
				draw_circle(center, rad * 0.6, Color("#64748b"))

	func _draw_helmet_icon(pos: Vector2, col: Color) -> void:
		# Small stylized helmet icon
		var pts := PackedVector2Array([
			pos + Vector2(0, -6),
			pos + Vector2(6, -3),
			pos + Vector2(6, 4),
			pos + Vector2(0, 6),
			pos + Vector2(-6, 4),
			pos + Vector2(-6, -3)
		])
		draw_polyline(pts, col, 1.5)

	func _draw_armor_shield_icon(pos: Vector2, col: Color) -> void:
		# Small shield crest icon
		var pts := PackedVector2Array([
			pos + Vector2(-6, -6),
			pos + Vector2(6, -6),
			pos + Vector2(6, 0),
			pos + Vector2(0, 7),
			pos + Vector2(-6, 0)
		])
		draw_polyline(pts, col, 1.5)

	func _draw_quick_slot(pos: Vector2, key: String, icon_txt: String, col: Color) -> void:
		var font: Font = get_theme_default_font()
		var slot_size := Vector2(38.0, 38.0)
		var s_rect := Rect2(pos, slot_size)

		draw_rect(s_rect, Color(0.06, 0.08, 0.12, 0.85), true)
		draw_rect(s_rect, Color(1, 1, 1, 0.2), false, 1.0)

		# Icon text
		var iw: float = font.get_string_size(icon_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2(pos.x + (slot_size.x - iw) * 0.5, pos.y + 18), icon_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)

		# Key badge below
		var kw: float = font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(font, Vector2(pos.x + (slot_size.x - kw) * 0.5, pos.y + 32), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#cbd5e1"))

# ==============================================================================
# SUB-WIDGET 7: BOTTOM-CENTER ULTIMATE WIDGET (VALKYRIE WINGS & 38%)
# ==============================================================================
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

		# 1. Outer Diamond Frame with Jet Wings
		var d_rad: float = 24.0
		var diamond := PackedVector2Array([
			center + Vector2(0, -d_rad),
			center + Vector2(d_rad * 0.9, 0),
			center + Vector2(0, d_rad * 0.8),
			center + Vector2(-d_rad * 0.9, 0)
		])
		draw_colored_polygon(diamond, Color(0.06, 0.08, 0.12, 0.88))
		draw_polyline(diamond, Color(1.0, 1.0, 1.0, 0.2), 1.2)

		# Outer Arc Charge Meter
		var charge_frac: float = clampf(PlayerState.ult_charge / 100.0, 0.0, 1.0)
		var start_ang: float = -PI * 0.5
		var sweep: float = TAU * charge_frac
		var arc_col := Color("#f59e0b") if charge_frac >= 1.0 else Color("#cbd5e1")
		draw_arc(center, d_rad + 4.0, start_ang, start_ang + sweep, 24, arc_col, 2.5, true)

		# 2. Valkyrie Skyward Dive / Jet Wings Icon in Center
		# Left wing
		draw_line(center + Vector2(-2, 2), center + Vector2(-12, -8), Color("#ffffff"), 2.0)
		draw_line(center + Vector2(-12, -8), center + Vector2(-14, -2), Color("#ffffff"), 1.5)
		# Right wing
		draw_line(center + Vector2(2, 2), center + Vector2(12, -8), Color("#ffffff"), 2.0)
		draw_line(center + Vector2(12, -8), center + Vector2(14, -2), Color("#ffffff"), 1.5)
		# Central thruster jet
		draw_line(center + Vector2(0, -10), center + Vector2(0, 4), Color("#f59e0b"), 2.0)

		# 3. Percentage Text below diamond: "38%" (or "100% [Z]")
		var u_txt := "%d%%" % int(PlayerState.ult_charge)
		if PlayerState.ult_charge >= 100.0:
			u_txt = "就绪 [Z]"
		var u_w: float = font.get_string_size(u_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(font, Vector2(center.x - u_w * 0.5, center.y + d_rad + 18.0), u_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#cbd5e1"))

# ==============================================================================
# SUB-WIDGET 8: BOTTOM-RIGHT WEAPON HUD (DUAL TABS, GIANT 18 / 36, ORANGE CHEVRONS)
# ==============================================================================
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

		# 1. Dual Weapon Selector Tabs at bottom of weapon HUD
		# In screenshot:
		# Tab 1: "1 莫桑比克" (Inactive, dark)
		# Tab 2: "2 R-301卡宾枪" (Active, bright white background, dark bold text)
		var tab_y: float = base_y + panel_h + 4.0
		var tab_w: float = 140.0
		var tab_h: float = 24.0

		var wep0_name := "莫桑比克"
		var wep1_name := "R-301卡宾枪"

		# Resolve actual loadout names if available
		if PlayerState.loadout.size() > 0:
			var wid0: String = str(PlayerState.loadout[0].get("weapon_id", "empty"))
			if wid0 == "empty" or wid0 == "":
				wep0_name = "空槽位"
			else:
				var w0: Dictionary = GameData.get_weapon_by_id(wid0)
				wep0_name = str(w0.get("name", "武器 1")).replace(" ", "")
		if PlayerState.loadout.size() > 1:
			var wid1: String = str(PlayerState.loadout[1].get("weapon_id", "empty"))
			if wid1 == "empty" or wid1 == "":
				wep1_name = "空槽位"
			else:
				var w1: Dictionary = GameData.get_weapon_by_id(wid1)
				wep1_name = str(w1.get("name", "武器 2")).replace(" ", "")

		var active_slot: int = clampi(PlayerState.active_slot, 0, 1)

		# Tab 0: Slot 1
		var t0_x: float = vp.x - right_margin - (tab_w * 2.0 + 8.0)
		_draw_weapon_tab(Vector2(t0_x, tab_y), "1", wep0_name, active_slot == 0 and PlayerState.active_slot != 2)

		# Tab 1: Slot 2
		var t1_x: float = t0_x + tab_w + 6.0
		_draw_weapon_tab(Vector2(t1_x, tab_y), "2", wep1_name, active_slot == 1 and PlayerState.active_slot != 2)

		# 2. Main Angled Weapon Panel Background
		var slant: float = 16.0
		var p_pts := PackedVector2Array([
			Vector2(base_x + slant, base_y),
			Vector2(base_x + panel_w, base_y),
			Vector2(base_x + panel_w, base_y + panel_h),
			Vector2(base_x, base_y + panel_h)
		])
		draw_colored_polygon(p_pts, Color(0.06, 0.08, 0.12, 0.88))
		draw_polyline(p_pts, Color(1.0, 1.0, 1.0, 0.15), 1.0)

		# 3. Active Weapon Wireframe Silhouette (R-301 Carbine / Charge Rifle / Empty)
		var cur_slot: Dictionary = PlayerState.loadout[active_slot] if active_slot < PlayerState.loadout.size() else {}
		var cur_wid: String = str(cur_slot.get("weapon_id", "empty"))
		var is_cur_empty: bool = (cur_wid == "empty" or cur_wid == "" or PlayerState.active_slot == 2)
		var cur_ammo: int = int(cur_slot.get("ammo", 0)) if not is_cur_empty else 0
		var wep_info: Dictionary = GameData.get_weapon_by_id(cur_wid) if not is_cur_empty else {}
		var sil_pos := Vector2(base_x + 36.0, base_y + 24.0)

		if not is_cur_empty:
			_draw_weapon_silhouette(sil_pos, cur_wid)
			# 4. Fire Selector: "[B] ∞"
			var mode_txt := "[B] ∞"
			var mode_col: Color = Color("#cbd5e1")
			draw_string(font, Vector2(base_x + 72.0, base_y + 60.0), mode_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, mode_col)

			# 5. GIANT Ammo Counter & Reserve
			var ammo_type: String = str(wep_info.get("ammo", "light"))
			var res_ammo: int = int(PlayerState.ammo_reserve.get(ammo_type, 36))

			var ammo_str := str(cur_ammo)
			var ammo_w: float = font.get_string_size(ammo_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x
			var num_x: float = base_x + 190.0
			draw_string(font, Vector2(num_x, base_y + 52.0), ammo_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color("#ffffff"))

			# Reserve ammo: "| 36" (or "/ 36")
			var res_str := "| %d" % res_ammo
			draw_string(font, Vector2(num_x + ammo_w + 10.0, base_y + 44.0), res_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#cbd5e1"))

			# 6. Ammo Caliber Badge: Light Ammo Orange Chevron Icon (Exact match to screenshot!)
			var caliber_pos := Vector2(base_x + panel_w - 38.0, base_y + 36.0)
			_draw_ammo_type_badge(caliber_pos, ammo_type)
		else:
			# Fists / Heirloom / Empty slot
			draw_string(font, Vector2(base_x + 45.0, base_y + 42.0), "👊 近战 / 徒手", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#94a3b8"))
			draw_string(font, Vector2(base_x + 190.0, base_y + 52.0), "--", HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color("#64748b"))

		# 7. Grenade Slot [G] & Survival Slot [LALT] to the left of weapon panel
		var side_x: float = base_x - 110.0
		_draw_side_slot(Vector2(side_x, base_y + 16), "LALT", "🛡️", Color("#38bdf8")) # Heat Shield
		_draw_side_slot(Vector2(side_x + 52.0, base_y + 16), "G", "✦ 1", Color("#f59e0b")) # Grenade

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
			# Solid bright white active tab with bold dark text
			draw_colored_polygon(pts, Color("#f8fafc"))
			# Key badge [ 2 ]
			var k_rect := Rect2(pos.x + 10.0, pos.y + 4.0, 16.0, 16.0)
			draw_rect(k_rect, Color("#0f172a"), true)
			var kw: float = font.get_string_size(slot_num, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(font, Vector2(k_rect.position.x + (16.0 - kw) * 0.5, k_rect.position.y + 12.0), slot_num, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f8fafc"))
			# Title
			draw_string(font, Vector2(pos.x + 32.0, pos.y + 17), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#0f172a"))
		else:
			# Dark muted inactive tab
			draw_colored_polygon(pts, Color(0.1, 0.14, 0.2, 0.85))
			draw_polyline(pts, Color(1, 1, 1, 0.15), 1.0)
			# Key badge [ 1 ]
			var k_rect := Rect2(pos.x + 10.0, pos.y + 4.0, 16.0, 16.0)
			draw_rect(k_rect, Color(1, 1, 1, 0.15), true)
			var kw: float = font.get_string_size(slot_num, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(font, Vector2(k_rect.position.x + (16.0 - kw) * 0.5, k_rect.position.y + 12.0), slot_num, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#cbd5e1"))
			# Title
			draw_string(font, Vector2(pos.x + 32.0, pos.y + 16), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#94a3b8"))

	func _draw_weapon_silhouette(pos: Vector2, wid: String = "r301") -> void:
		var col := Color(1.0, 1.0, 1.0, 0.9)
		if wid == "chargerifle":
			# Heavy dual-prong linear rail silhouette of Charge Rifle
			draw_line(pos + Vector2(-22, -2), pos + Vector2(62, -2), col, 2.2)
			draw_line(pos + Vector2(-22, 4), pos + Vector2(62, 4), col, 2.2)
			draw_line(pos + Vector2(62, -2), pos + Vector2(62, 4), col, 2.2)
			# 3 Glowing plasma coils
			draw_line(pos + Vector2(10, -5), pos + Vector2(10, 7), Color("#ff7700"), 2.0)
			draw_line(pos + Vector2(28, -5), pos + Vector2(28, 7), Color("#ff7700"), 2.0)
			draw_line(pos + Vector2(46, -5), pos + Vector2(46, 7), Color("#ff7700"), 2.0)
			# Stock & Receiver
			draw_line(pos + Vector2(-22, 1), pos + Vector2(-38, 12), col, 2.2)
			draw_line(pos + Vector2(-8, 4), pos + Vector2(-12, 16), Color("#38bdf8"), 2.2)
			draw_line(pos + Vector2(-10, -5), pos + Vector2(20, -5), col, 2.0)
		else:
			# Sleek line-art silhouette of R-301 assault rifle
			# Barrel & Handguard
			draw_line(pos + Vector2(0, 0), pos + Vector2(58, 0), col, 2.0)
			# Receiver & Stock
			draw_line(pos + Vector2(0, 0), pos + Vector2(-22, 6), col, 2.0)
			draw_line(pos + Vector2(-22, 6), pos + Vector2(-34, 14), col, 2.0)
			# Magazine curve
			draw_line(pos + Vector2(16, 2), pos + Vector2(12, 16), col, 2.0)
			# Grip
			draw_line(pos + Vector2(-4, 4), pos + Vector2(-10, 16), col, 2.0)
			# Scope rail & Optic
			draw_line(pos + Vector2(4, -4), pos + Vector2(28, -4), col, 1.8)

	func _draw_ammo_type_badge(pos: Vector2, atype: String) -> void:
		# Draw authentic Apex ammo icons
		match atype:
			"light":
				# Light Ammo: Solid orange rounded shield with black stacked chevrons
				var b_rect := Rect2(pos.x - 11, pos.y - 18, 22, 36)
				draw_rect(b_rect, Color("#ea580c"), true)
				draw_rect(b_rect, Color("#fdba74"), false, 1.0)
				for i in range(3):
					var cy: float = pos.y - 9.0 + float(i) * 9.0
					var ch := PackedVector2Array([
						Vector2(pos.x - 7, cy - 3),
						Vector2(pos.x + 1, cy + 3),
						Vector2(pos.x + 9, cy - 3)
					])
					draw_polyline(ch, Color("#18181b"), 2.2)
			"heavy":
				# Heavy Ammo: Teal cyan double block
				var col := Color("#14b8a6")
				draw_rect(Rect2(pos.x, pos.y - 8, 8, 16), col, true)
				draw_rect(Rect2(pos.x + 10, pos.y - 8, 8, 16), col, true)
			"energy":
				# Energy Ammo: Lime green lightning zig-zag
				var col := Color("#84cc16")
				var pts := PackedVector2Array([
					Vector2(pos.x + 4, pos.y - 10),
					Vector2(pos.x - 4, pos.y),
					Vector2(pos.x + 8, pos.y),
					Vector2(pos.x, pos.y + 10)
				])
				draw_polyline(pts, col, 2.0)
			"shotgun":
				# Shotgun Ammo: Red shells
				var col := Color("#ef4444")
				draw_circle(pos + Vector2(-4, -4), 4.0, col)
				draw_circle(pos + Vector2(4, -4), 4.0, col)
				draw_circle(pos + Vector2(0, 4), 4.0, col)
			"sniper":
				# Sniper Ammo: Royal blue arrow
				var col := Color("#38bdf8")
				var pts := PackedVector2Array([
					Vector2(pos.x - 8, pos.y + 6),
					Vector2(pos.x, pos.y - 10),
					Vector2(pos.x + 8, pos.y + 6)
				])
				draw_polyline(pts, col, 2.5)
			_:
				draw_circle(pos, 8.0, Color("#ffffff"))

	func _draw_side_slot(pos: Vector2, key: String, icon: String, col: Color) -> void:
		var font: Font = get_theme_default_font()
		var s_rect := Rect2(pos, Vector2(42.0, 42.0))
		draw_rect(s_rect, Color(0.06, 0.08, 0.12, 0.85), true)
		draw_rect(s_rect, Color(1, 1, 1, 0.18), false, 1.0)

		# Icon
		var iw: float = font.get_string_size(icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(font, Vector2(pos.x + (42.0 - iw) * 0.5, pos.y + 20), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)

		# Key
		var kw: float = font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(font, Vector2(pos.x + (42.0 - kw) * 0.5, pos.y + 35), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#cbd5e1"))

# ==============================================================================
# SUB-WIDGET 9: CENTER RETICLE / HIPFIRE CROSSHAIR
# ==============================================================================
class ReticleWidget extends Control:
	var hud: ApexAuthenticHUD

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if hud == null:
			return
		if hud.player != null and hud.player.is_ads:
			return # ADS scope overlay handles aiming reticle

		var vp: Vector2 = get_viewport_rect().size
		var c: Vector2 = vp * 0.5
		var col := Color(1.0, 1.0, 1.0, 0.75)
		var t_len: float = 7.0
		var gap: float = 6.0

		# 4 subtle hipfire ticks
		draw_line(c + Vector2(0, -gap - t_len), c + Vector2(0, -gap), col, 1.5)
		draw_line(c + Vector2(0, gap), c + Vector2(0, gap + t_len), col, 1.5)
		draw_line(c + Vector2(-gap - t_len, 0), c + Vector2(-gap, 0), col, 1.5)
		draw_line(c + Vector2(gap, 0), c + Vector2(gap + t_len, 0), col, 1.5)
		draw_circle(c, 1.2, Color(1, 1, 1, 0.85))
