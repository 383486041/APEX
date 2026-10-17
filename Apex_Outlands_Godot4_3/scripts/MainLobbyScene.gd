extends Node3D
## ============================================================================
## APEX: OUTLANDS PROTOCOL — Master Lobby Controller (Godot 4.3 Pro Edition)
## Complete AAA Flow integrating:
## - 6 Apex Top Navigation Tabs: [PLAY], [传奇 LEGENDS], [军械库 ARMORY],
##   [通行证 BATTLE PASS], [组合包 APEX PACKS], [设置 SETTINGS]
## - Top-Right Level & Currencies (Level 142, Apex Coins, Crafting Metals, 150 Heirloom Shards)
## - Interactive 360° Mouse-Drag 3D Legend Rig & 3D Weapon / Heirloom Showcase
## - Full 12-Legend Selector with Class Perks, Lore, Passive/Q/Z Abilities & 3D Pedestal
## - 22-Weapon Armory with 7 Category Filters, Ballistic Stats & 3D Viewmodel Showcase
## - Interactive 3D Loot Tick Pack Opening with Red Light Heirloom Shards Unboxing
## - Mode Selector Modal (Battle Royale 12 POIs vs. Firing Range 22 Weapons Rack)
## - Full Legend Draft Screen (选人阶段) with Countdown, Voice Lines & Lock-In Deploy!
## ============================================================================

var pedestal_root: Node3D
var weapon_pedestal_root: Node3D
var hero_rig: Node3D
var weapon_preview_rig: Node3D
var tick_ped: Node3D
var dragging_stage: bool = false
var lobby_time: float = 0.0

# UI Canvas & Tab Views
var canvas_layer: CanvasLayer
var root_ctrl: Control
var current_tab_idx: int = 0
var tab_buttons: Array = []
var tab_views: Array = []

# Draft Overlay
var draft_overlay: Control
var draft_countdown_timer: float = 0.0
var draft_timer_lbl: Label
var draft_voice_lbl: Label

# Mode Selection & Play Tab Graphic References
var mode_modal: Control
var mode_banner_rect: TextureRect
var mode_tag_lbl: Label
var mode_name_lbl: Label
var mode_map_lbl: Label
var ready_btn: Button
var is_matchmaking: bool = false
var match_queue_timer: float = 0.0
var hero_tag_lbl: Label

# Dynamic Views References
var armory_wep_box: VBoxContainer
var armory_detail_box: VBoxContainer
var current_armory_cat: String = "ALL"
var selected_armory_wep_id: String = "r301"

func _ready() -> void:
	PlayerState.ui_modal_open = false
	PlayerState.inventory_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_setup_3d_stage()
	_setup_lobby_ui()
	_switch_tab(0)

func _setup_3d_stage() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#070a10")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#1e293b")
	e.ambient_light_energy = 1.25
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.glow_enabled = true
	e.glow_intensity = 0.8
	e.glow_bloom = 0.15
	env.environment = e
	add_child(env)

	var cam := Camera3D.new()
	cam.position = Vector3(-0.15, 1.48, 3.85)
	cam.fov = 48.0
	cam.current = true
	add_child(cam)

	# Key Light (Front spotlight on Legend)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.position = Vector3(2, 6, 5)
	sun.rotation_degrees = Vector3(-35, 18, 0)
	sun.light_energy = 1.45
	sun.light_color = Color("#f8fafc")

	# Rim Light 1 (Cyan Rim from back-left)
	var rim_cyan := OmniLight3D.new()
	rim_cyan.position = Vector3(-2.8, 2.2, -1.8)
	rim_cyan.light_color = Color("#06b6d4")
	rim_cyan.light_energy = 2.4
	rim_cyan.omni_range = 10.0
	add_child(rim_cyan)

	# Rim Light 2 (Apex Red Rim from back-right)
	var rim_red := OmniLight3D.new()
	rim_red.position = Vector3(2.5, 2.0, -1.2)
	rim_red.light_color = Color("#ef4444")
	rim_red.light_energy = 2.0
	rim_red.omni_range = 8.0
	add_child(rim_red)

	# --- 3D Hangar Environment Stage ---
	var stage_root := Node3D.new()
	stage_root.name = "HangarStage"
	add_child(stage_root)

	# 1. Metallic Hangar Floor
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(36, 36)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("#0b0f19")
	floor_mat.metallic = 0.82
	floor_mat.roughness = 0.32
	floor_mesh.material_override = floor_mat
	floor_mesh.position = Vector3(0, -0.22, 0)
	stage_root.add_child(floor_mesh)

	# 2. Glowing Floor Hazard Stripes
	var hazard_mat := StandardMaterial3D.new()
	hazard_mat.albedo_color = Color("#f59e0b")
	hazard_mat.metallic = 0.4
	hazard_mat.roughness = 0.5
	for i in range(-5, 6):
		var stripe := MeshInstance3D.new()
		var s_box := BoxMesh.new()
		s_box.size = Vector3(0.18, 0.01, 1.2)
		stripe.mesh = s_box
		stripe.material_override = hazard_mat
		stripe.position = Vector3(float(i) * 0.9, -0.21, 1.8)
		stripe.rotation_degrees = Vector3(0, 35, 0)
		stage_root.add_child(stripe)

	# 3. Back Wall & High-Tech Structural Frame
	var wall := MeshInstance3D.new()
	var wall_box := BoxMesh.new()
	wall_box.size = Vector3(32, 12, 0.5)
	wall.mesh = wall_box
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color("#080c14")
	wall_mat.metallic = 0.9
	wall_mat.roughness = 0.4
	wall.material_override = wall_mat
	wall.position = Vector3(0, 4.5, -4.8)
	stage_root.add_child(wall)

	var pillar_mat := StandardMaterial3D.new()
	pillar_mat.albedo_color = Color("#1e293b")
	pillar_mat.metallic = 0.75
	pillar_mat.roughness = 0.35
	for px in [-7.0, -3.5, 3.5, 7.0]:
		var pil := MeshInstance3D.new()
		var p_box := BoxMesh.new()
		p_box.size = Vector3(0.65, 12, 0.8)
		pil.mesh = p_box
		pil.material_override = pillar_mat
		pil.position = Vector3(px, 4.5, -4.4)
		stage_root.add_child(pil)

		var neon := MeshInstance3D.new()
		var n_box := BoxMesh.new()
		n_box.size = Vector3(0.08, 10.0, 0.08)
		neon.mesh = n_box
		var n_mat := StandardMaterial3D.new()
		n_mat.albedo_color = Color("#ef4444") if px < 0 else Color("#06b6d4")
		n_mat.emission_enabled = true
		n_mat.emission = n_mat.albedo_color
		n_mat.emission_energy_multiplier = 1.6
		neon.material_override = n_mat
		neon.position = Vector3(px, 4.5, -3.95)
		stage_root.add_child(neon)

	# 4. Floating Holographic Stadium Rings in Background (Sci-Fi Stadium Portal)
	var holo_ring1 := MeshInstance3D.new()
	var torus1 := TorusMesh.new()
	torus1.inner_radius = 2.3
	torus1.outer_radius = 2.45
	holo_ring1.mesh = torus1
	var r1_mat := StandardMaterial3D.new()
	r1_mat.albedo_color = Color("#ef4444")
	r1_mat.emission_enabled = true
	r1_mat.emission = Color("#ef4444")
	r1_mat.emission_energy_multiplier = 2.2
	r1_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r1_mat.albedo_color.a = 0.75
	holo_ring1.material_override = r1_mat
	holo_ring1.position = Vector3(0, 4.2, -4.5)
	holo_ring1.rotation_degrees = Vector3(90, 0, 0)
	stage_root.add_child(holo_ring1)

	var holo_ring2 := MeshInstance3D.new()
	var torus2 := TorusMesh.new()
	torus2.inner_radius = 1.55
	torus2.outer_radius = 1.68
	holo_ring2.mesh = torus2
	var r2_mat := StandardMaterial3D.new()
	r2_mat.albedo_color = Color("#06b6d4")
	r2_mat.emission_enabled = true
	r2_mat.emission = Color("#06b6d4")
	r2_mat.emission_energy_multiplier = 1.8
	r2_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r2_mat.albedo_color.a = 0.65
	holo_ring2.material_override = r2_mat
	holo_ring2.position = Vector3(0, 4.2, -4.5)
	holo_ring2.rotation_degrees = Vector3(90, 0, 0)
	stage_root.add_child(holo_ring2)

	# 5. Left-Side Double-Tier 3D Legend Pedestal
	pedestal_root = Node3D.new()
	pedestal_root.position = Vector3(-0.45, 0.0, 0.0)
	add_child(pedestal_root)

	var ped_mat := StandardMaterial3D.new()
	ped_mat.albedo_color = Color("#111827")
	ped_mat.metallic = 0.88
	ped_mat.roughness = 0.22

	var ped_lower := MeshInstance3D.new()
	var cyl1 := CylinderMesh.new()
	cyl1.top_radius = 1.6
	cyl1.bottom_radius = 1.85
	cyl1.height = 0.14
	cyl1.radial_segments = 24
	ped_lower.mesh = cyl1
	ped_lower.material_override = ped_mat
	ped_lower.position = Vector3(0, -0.15, 0)
	pedestal_root.add_child(ped_lower)

	var ped_upper := MeshInstance3D.new()
	var cyl2 := CylinderMesh.new()
	cyl2.top_radius = 1.4
	cyl2.bottom_radius = 1.45
	cyl2.height = 0.12
	cyl2.radial_segments = 24
	ped_upper.mesh = cyl2
	ped_upper.material_override = ped_mat
	ped_upper.position = Vector3(0, -0.02, 0)
	pedestal_root.add_child(ped_upper)

	var rim_mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.38
	torus.outer_radius = 1.44
	rim_mesh.mesh = torus
	var rim_ring_mat := StandardMaterial3D.new()
	rim_ring_mat.albedo_color = Color("#ef4444")
	rim_ring_mat.emission_enabled = true
	rim_ring_mat.emission = Color("#ef4444")
	rim_ring_mat.emission_energy_multiplier = 2.2
	rim_mesh.material_override = rim_ring_mat
	rim_mesh.position = Vector3(0, 0.05, 0)
	pedestal_root.add_child(rim_mesh)

	# Right-Side 3D Weapon & Heirloom Showcase Pedestal
	weapon_pedestal_root = Node3D.new()
	weapon_pedestal_root.position = Vector3(1.35, 1.15, 1.15)
	add_child(weapon_pedestal_root)

	tick_ped = CanyonWorldBuilder.create_loot_tick_node(5)
	tick_ped.position = Vector3(1.40, 0.0, 0.65)
	add_child(tick_ped)

	_refresh_showcase()

func _refresh_showcase() -> void:
	if is_instance_valid(hero_rig):
		hero_rig.queue_free()
	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	hero_rig = LegendRigBuilder.create_legend_rig(leg)
	hero_rig.rotation.y = PI # Face directly towards camera / player!
	pedestal_root.add_child(hero_rig)

	if is_instance_valid(weapon_preview_rig):
		weapon_preview_rig.queue_free()
	var wep_to_show: Dictionary = GameData.get_weapon_by_id(selected_armory_wep_id if current_tab_idx == 2 else PlayerState.loadout[0]["weapon_id"])
	weapon_preview_rig = WeaponMeshBuilder.create_viewmodel(wep_to_show, false, leg, "2x_bruiser")
	weapon_preview_rig.position = Vector3.ZERO
	weapon_preview_rig.scale = Vector3(1.65, 1.65, 1.65)
	var la := weapon_preview_rig.get_node_or_null("GunRig/LeftArmPivot")
	var ra := weapon_preview_rig.get_node_or_null("GunRig/RightArmPivot")
	if la: la.visible = false
	if ra: ra.visible = false
	weapon_pedestal_root.add_child(weapon_preview_rig)

	if is_instance_valid(hero_tag_lbl):
		hero_tag_lbl.text = "[%s] %s" % [leg["class_id"], leg["name"]]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			dragging_stage = mb.pressed
	elif event is InputEventMouseMotion and dragging_stage:
		var mm := event as InputEventMouseMotion
		if is_instance_valid(hero_rig):
			hero_rig.rotation.y += mm.relative.x * 0.01
		if is_instance_valid(weapon_preview_rig):
			weapon_preview_rig.rotation.y += mm.relative.x * 0.012

func _process(delta: float) -> void:
	lobby_time += delta
	if is_instance_valid(hero_rig):
		LegendRigBuilder.animate_rig(hero_rig, delta, {
			"mode": "lobby",
			"time": lobby_time
		})
		if not dragging_stage:
			hero_rig.rotation.y = PI + sin(lobby_time * 0.8) * 0.04

	if is_instance_valid(weapon_preview_rig) and not dragging_stage:
		weapon_preview_rig.rotation.y -= delta * 0.45

	if is_matchmaking:
		match_queue_timer -= delta
		if is_instance_valid(ready_btn):
			ready_btn.text = "✔ 正在匹配中...\n[%.1fs]" % maxf(0.0, match_queue_timer)
		if match_queue_timer <= 0.0:
			is_matchmaking = false
			if PlayerState.selected_mode_id == "br_trios":
				_open_draft_screen()
			else:
				_deploy_into_match()

	if draft_countdown_timer > 0.0:
		draft_countdown_timer -= delta
		if draft_timer_lbl:
			draft_timer_lbl.text = "⏱️ 空投倒计时: %.1f 秒" % maxf(0.0, draft_countdown_timer)
		if draft_countdown_timer <= 0.0:
			draft_countdown_timer = 0.0
			_deploy_into_match()

	if lobby_time > 0.2 and not has_meta("screenshot_taken"):
		set_meta("screenshot_taken", true)
		var vp_tex := get_viewport().get_texture()
		if vp_tex != null and not DisplayServer.get_name().to_lower().contains("headless"):
			var img := vp_tex.get_image()
			if img and not img.is_empty():
				img.save_png("res://lobby_preview.png")

func _make_panel_style(bg_col: Color, border_col: Color, border_w: int = 2, corner_r: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(corner_r)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _create_pill(text: String, text_col: Color, bg_col: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _make_panel_style(bg_col, Color(text_col.r, text_col.g, text_col.b, 0.35), 1, 4))
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = text_col
	pc.add_child(lbl)
	return pc

func _create_icon_pill(icon_tex: Texture2D, text: String, text_col: Color, bg_col: Color = Color(0.04, 0.07, 0.12, 0.94)) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _make_panel_style(bg_col, Color(text_col.r, text_col.g, text_col.b, 0.35), 1, 4))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	pc.add_child(hb)
	var tr := TextureRect.new()
	tr.texture = icon_tex
	tr.custom_minimum_size = Vector2(18, 18)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(tr)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = text_col
	hb.add_child(lbl)
	return pc

func _setup_lobby_ui() -> void:
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)

	root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(root_ctrl)

	# 1. Top Navigation Bar & Account Info
	_build_top_navbar()

	# 2. Build 6 Tab Views
	_build_play_tab()
	_build_legends_tab()
	_build_armory_tab()
	_build_battlepass_tab()
	_build_packs_tab()
	_build_settings_tab()

	# 3. Mode Selection Modal
	_build_mode_modal()

	# 4. Draft Screen Overlay
	_build_draft_screen()

## ============================================================================
## 1. Top Navigation Bar (Authentic Apex Header & Account Hub)
## ============================================================================
func _build_top_navbar() -> void:
	var top_bar := PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 58)
	top_bar.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.05, 0.08, 0.96), Color("#1e293b"), 1, 0))
	root_ctrl.add_child(top_bar)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	top_bar.add_child(hbox)

	# Left: Official Apex Logo Graphic & Brand Title
	var brand_box := HBoxContainer.new()
	brand_box.add_theme_constant_override("separation", 8)
	hbox.add_child(brand_box)

	var logo_icon := TextureRect.new()
	logo_icon.texture = ApexLobbyArt.create_apex_logo_texture(34)
	logo_icon.custom_minimum_size = Vector2(34, 34)
	logo_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand_box.add_child(logo_icon)

	var brand_title := Label.new()
	brand_title.text = "APEX LEGENDS"
	brand_title.add_theme_font_size_override("font_size", 16)
	brand_title.modulate = Color.WHITE
	brand_box.add_child(brand_title)

	var brand_sub := Label.new()
	brand_sub.text = "// 外域协议"
	brand_sub.add_theme_font_size_override("font_size", 12)
	brand_sub.modulate = Color("#ef4444")
	brand_box.add_child(brand_sub)

	# Center: Navigation Tabs
	var nav_tabs := ["就绪 (PLAY)", "传奇 (LEGENDS)", "军械库 (ARMORY)", "通行证 (PASS)", "组合包 (PACKS)", "设置 (SETTINGS)"]
	var tabs_box := HBoxContainer.new()
	tabs_box.add_theme_constant_override("separation", 4)
	tabs_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(tabs_box)

	for i in range(nav_tabs.size()):
		var btn := Button.new()
		btn.text = nav_tabs[i]
		btn.custom_minimum_size = Vector2(115, 38)
		btn.flat = true
		btn.add_theme_font_size_override("font_size", 13)
		var t_idx: int = i
		btn.pressed.connect(func():
			_switch_tab(t_idx)
			AudioSynthesizer.play_reload_step("lever_cock")
		)
		tabs_box.add_child(btn)
		tab_buttons.append(btn)

	# Right: Account Badges & Currencies Hub
	var acc_box := HBoxContainer.new()
	acc_box.add_theme_constant_override("separation", 8)
	hbox.add_child(acc_box)

	var rank_pill := _create_pill("🏆 铂金 I (4,850 RP)", Color("#38bdf8"), Color(0.05, 0.1, 0.18, 0.9))
	acc_box.add_child(rank_pill)

	var lvl_pill := _create_pill("🏅 Lv.%d" % PlayerState.account_level, Color("#f8fafc"), Color(0.08, 0.12, 0.20, 0.9))
	acc_box.add_child(lvl_pill)

	var coins_pill := _create_icon_pill(ApexLobbyArt.create_currency_icon("coins", 20), "%d" % PlayerState.apex_coins, Color("#fde047"))
	acc_box.add_child(coins_pill)

	var metals_pill := _create_icon_pill(ApexLobbyArt.create_currency_icon("metals", 20), "%d" % PlayerState.crafting_metals, Color("#38bdf8"))
	acc_box.add_child(metals_pill)

	var shards_pill := _create_icon_pill(ApexLobbyArt.create_currency_icon("shards", 20), "%d/150" % PlayerState.heirloom_shards, Color("#ff1e42"))
	acc_box.add_child(shards_pill)

	var packs_pill := _create_icon_pill(ApexLobbyArt.create_currency_icon("pack_tick", 20), "1 组合包", Color("#f8fafc"), Color("#dc2626"))
	acc_box.add_child(packs_pill)

	var ping_pill := _create_pill("📶 32ms (HKG)", Color("#22c55e"), Color(0.03, 0.08, 0.05, 0.9))
	acc_box.add_child(ping_pill)

func _switch_tab(idx: int) -> void:
	current_tab_idx = idx
	for i in range(tab_views.size()):
		tab_views[i].visible = (i == idx)

	for i in range(tab_buttons.size()):
		var b: Button = tab_buttons[i]
		if i == idx:
			b.modulate = Color.WHITE
		else:
			b.modulate = Color(0.7, 0.75, 0.85, 0.75)

	# Update 3D Stage focus per tab
	if idx == 1: # LEGENDS tab
		pedestal_root.position = Vector3(0.0, 0.0, 0.0)
		weapon_pedestal_root.visible = false
		tick_ped.visible = false
	elif idx == 2: # ARMORY tab
		pedestal_root.position = Vector3(-1.8, 0.0, -1.0)
		weapon_pedestal_root.visible = true
		weapon_pedestal_root.position = Vector3(0.35, 1.35, 1.2)
		tick_ped.visible = false
		_refresh_showcase()
	elif idx == 4: # PACKS tab
		pedestal_root.position = Vector3(-1.6, 0.0, -1.0)
		weapon_pedestal_root.visible = false
		tick_ped.visible = true
		tick_ped.position = Vector3(0.0, 0.25, 1.2)
	else: # PLAY tab & others
		pedestal_root.position = Vector3(-0.45, 0.0, 0.0)
		weapon_pedestal_root.visible = true
		weapon_pedestal_root.position = Vector3(1.35, 1.15, 1.15)
		tick_ped.visible = true
		tick_ped.position = Vector3(1.40, 0.0, 0.65)
		_refresh_showcase()

## ============================================================================
## 2. PLAY TAB (Authentic Apex Screen Composition)
## ============================================================================
func _build_play_tab() -> void:
	var view := Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(view)
	tab_views.append(view)

	# 1. Bottom-Left Mode Selector Card (Visual Illustrated Map Card)
	var mode_card := PanelContainer.new()
	mode_card.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	mode_card.position = Vector2(36, -200)
	mode_card.custom_minimum_size = Vector2(380, 165)
	mode_card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.06, 0.10, 0.94), Color("#475569"), 2, 6))
	view.add_child(mode_card)

	var mc_vb := VBoxContainer.new()
	mc_vb.add_theme_constant_override("separation", 6)
	mode_card.add_child(mc_vb)

	# Banner Container with Overlay Controls
	var banner_box := Control.new()
	banner_box.custom_minimum_size = Vector2(356, 115)
	mc_vb.add_child(banner_box)

	mode_banner_rect = TextureRect.new()
	mode_banner_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	mode_banner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mode_banner_rect.stretch_mode = TextureRect.STRETCH_SCALE
	banner_box.add_child(mode_banner_rect)

	# Top-Left Tag Pill on Banner
	var tag_pill := PanelContainer.new()
	tag_pill.position = Vector2(10, 8)
	tag_pill.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.08, 0.14, 0.85), Color("#ef4444"), 1, 3))
	banner_box.add_child(tag_pill)

	mode_tag_lbl = Label.new()
	mode_tag_lbl.text = "CORE 核心模式"
	mode_tag_lbl.add_theme_font_size_override("font_size", 10)
	mode_tag_lbl.modulate = Color("#ef4444")
	tag_pill.add_child(mode_tag_lbl)

	# Top-Right Timer on Banner
	var timer_lbl := Label.new()
	timer_lbl.text = "⏱️ 45分后轮换：奥林匹斯"
	timer_lbl.position = Vector2(185, 10)
	timer_lbl.add_theme_font_size_override("font_size", 10)
	timer_lbl.modulate = Color("#fde047")
	banner_box.add_child(timer_lbl)

	# Bottom-Left Mode Name on Banner
	mode_name_lbl = Label.new()
	mode_name_lbl.text = "大逃杀：三人标准赛"
	mode_name_lbl.position = Vector2(12, 60)
	mode_name_lbl.add_theme_font_size_override("font_size", 18)
	mode_name_lbl.modulate = Color.WHITE
	banner_box.add_child(mode_name_lbl)

	# Bottom-Right Map Name & Change Cue on Banner
	mode_map_lbl = Label.new()
	mode_map_lbl.text = "诸王峡谷 (12 据点) ▲ 更换模式"
	mode_map_lbl.position = Vector2(12, 88)
	mode_map_lbl.add_theme_font_size_override("font_size", 11)
	mode_map_lbl.modulate = Color("#94a3b8")
	banner_box.add_child(mode_map_lbl)

	var banner_btn := Button.new()
	banner_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner_btn.flat = true
	banner_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	banner_btn.pressed.connect(func():
		mode_modal.visible = true
		AudioSynthesizer.play_reload_step("lever_cock")
	)
	banner_box.add_child(banner_btn)

	# Bottom Strip: Fill Teammates checkbox & Current Legend Badge
	var b_strip := HBoxContainer.new()
	b_strip.add_theme_constant_override("separation", 12)
	mc_vb.add_child(b_strip)

	var fill_chk := CheckBox.new()
	fill_chk.text = "补满队友 (FILL TEAMMATES)"
	fill_chk.button_pressed = true
	fill_chk.add_theme_font_size_override("font_size", 11)
	fill_chk.modulate = Color("#cbd5e1")
	b_strip.add_child(fill_chk)

	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	hero_tag_lbl = Label.new()
	hero_tag_lbl.text = "[%s] %s" % [leg["class_id"], leg["name"]]
	hero_tag_lbl.add_theme_font_size_override("font_size", 11)
	hero_tag_lbl.modulate = Color("#fde047")
	b_strip.add_child(hero_tag_lbl)

	_update_mode_card()

	# 2. Iconic Apex "READY" Button (Adjacent to Mode Card)
	ready_btn = Button.new()
	ready_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ready_btn.position = Vector2(430, -200)
	ready_btn.custom_minimum_size = Vector2(230, 165)
	var ready_style := StyleBoxFlat.new()
	ready_style.bg_color = Color("#dc2626")
	ready_style.border_color = Color("#f97316")
	ready_style.set_border_width_all(2)
	ready_style.set_corner_radius_all(6)
	ready_btn.add_theme_stylebox_override("normal", ready_style)
	ready_btn.add_theme_stylebox_override("hover", ready_style)
	ready_btn.add_theme_font_size_override("font_size", 20)
	ready_btn.text = "准备就绪\nREADY"
	ready_btn.pressed.connect(_on_ready_pressed)
	view.add_child(ready_btn)

	# 3. Bottom-Center Squad Party Slots
	var party_box := HBoxContainer.new()
	party_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	party_box.position = Vector2(680, -110)
	party_box.add_theme_constant_override("separation", 10)
	view.add_child(party_box)

	var self_card := PanelContainer.new()
	self_card.custom_minimum_size = Vector2(170, 75)
	self_card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.09, 0.15, 0.92), Color("#3b82f6"), 1, 4))
	party_box.add_child(self_card)

	var s_vb := VBoxContainer.new()
	self_card.add_child(s_vb)
	var s_name := Label.new()
	s_name.text = "👤 kisskiss"
	s_name.add_theme_font_size_override("font_size", 13)
	s_name.modulate = Color.WHITE
	s_vb.add_child(s_name)
	var s_role := Label.new()
	s_role.text = "Lv.%d · %s" % [PlayerState.account_level, leg["name"]]
	s_role.add_theme_font_size_override("font_size", 11)
	s_role.modulate = Color("#38bdf8")
	s_vb.add_child(s_role)
	var s_status := Label.new()
	s_status.text = "✔ 已就绪 PARTY READY"
	s_status.add_theme_font_size_override("font_size", 10)
	s_status.modulate = Color("#22c55e")
	s_vb.add_child(s_status)

	for slot_idx in [2, 3]:
		var invite_card := Button.new()
		invite_card.text = "+ 邀请好友\n(INVITE)"
		invite_card.custom_minimum_size = Vector2(120, 75)
		invite_card.modulate = Color(0.8, 0.85, 0.95, 0.75)
		invite_card.pressed.connect(func():
			AudioSynthesizer.play_reload_step("bolt_slap")
		)
		party_box.add_child(invite_card)

	# 4. Right-Side Season 20 "Breakthrough" Hub & Daily Challenges
	var right_box := VBoxContainer.new()
	right_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_box.position = Vector2(-370, 72)
	right_box.custom_minimum_size = Vector2(350, 560)
	right_box.add_theme_constant_override("separation", 10)
	view.add_child(right_box)

	# Card A: Season 20 Event Banner Card
	var season_card := PanelContainer.new()
	season_card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.06, 0.10, 0.94), Color("#d97706"), 2, 6))
	right_box.add_child(season_card)

	var sc_vb := VBoxContainer.new()
	sc_vb.add_theme_constant_override("separation", 6)
	season_card.add_child(sc_vb)

	var s_banner := TextureRect.new()
	s_banner.texture = ApexLobbyArt.create_season_hub_banner(326, 95)
	s_banner.custom_minimum_size = Vector2(326, 95)
	s_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s_banner.stretch_mode = TextureRect.STRETCH_SCALE
	sc_vb.add_child(s_banner)

	var sc_title := Label.new()
	sc_title.text = "🔥 第 20 赛季：突破 // BREAKTHROUGH"
	sc_title.add_theme_font_size_override("font_size", 14)
	sc_title.modulate = Color("#fbbf24")
	sc_vb.add_child(sc_title)

	var bp_prog_lbl := Label.new()
	bp_prog_lbl.text = "通行证进度：Lv.58 / 110  |  下一级：恶灵【虚空守望者】"
	bp_prog_lbl.add_theme_font_size_override("font_size", 11)
	bp_prog_lbl.modulate = Color("#cbd5e1")
	sc_vb.add_child(bp_prog_lbl)

	var bp_bar := ProgressBar.new()
	bp_bar.custom_minimum_size = Vector2(326, 14)
	bp_bar.value = 58.0
	bp_bar.max_value = 110.0
	bp_bar.show_percentage = false
	sc_vb.add_child(bp_bar)

	var bp_btn := Button.new()
	bp_btn.text = "🎁 检视赛季奖励 / 通行证 (VIEW PASS)"
	bp_btn.custom_minimum_size = Vector2(326, 34)
	bp_btn.pressed.connect(func():
		_switch_tab(3)
		AudioSynthesizer.play_reload_step("lever_cock")
	)
	sc_vb.add_child(bp_btn)

	# Card B: Daily Challenges Card (每日外域挑战)
	var daily_card := PanelContainer.new()
	daily_card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.06, 0.10, 0.94), Color("#334155"), 1, 6))
	right_box.add_child(daily_card)

	var dc_vb := VBoxContainer.new()
	dc_vb.add_theme_constant_override("separation", 8)
	daily_card.add_child(dc_vb)

	var dc_head := HBoxContainer.new()
	dc_vb.add_child(dc_head)
	var dc_title := Label.new()
	dc_title.text = "📋 每日外域挑战"
	dc_title.add_theme_font_size_override("font_size", 13)
	dc_title.modulate = Color("#38bdf8")
	dc_head.add_child(dc_title)
	var dc_timer := Label.new()
	dc_timer.text = "⏱️ 14:22:05"
	dc_timer.add_theme_font_size_override("font_size", 11)
	dc_timer.modulate = Color("#94a3b8")
	dc_timer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dc_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dc_head.add_child(dc_timer)

	var tasks := [
		{"desc": "🎯 使用突击步枪造成 1,500 点伤害", "prog": "1500 / 1500", "done": true, "star": "+2⭐"},
		{"desc": "🛡️ 进化护盾升至紫甲或红甲 3 次", "prog": "2 / 3", "done": false, "star": "+1⭐"},
		{"desc": "📦 搜刮死亡之箱秒换甲 1 次", "prog": "0 / 1", "done": false, "star": "+1⭐"},
		{"desc": "🔥 排位赛进入前 5 名", "prog": "1 / 2", "done": false, "star": "+2⭐"}
	]

	for t in tasks:
		var task_row := HBoxContainer.new()
		dc_vb.add_child(task_row)

		var t_lbl := Label.new()
		t_lbl.text = t["desc"]
		t_lbl.add_theme_font_size_override("font_size", 11)
		t_lbl.modulate = Color.WHITE if not t["done"] else Color("#64748b")
		t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		task_row.add_child(t_lbl)

		var p_lbl := Label.new()
		p_lbl.text = "[已完成]" if t["done"] else t["prog"]
		p_lbl.add_theme_font_size_override("font_size", 10)
		p_lbl.modulate = Color("#22c55e") if t["done"] else Color("#fde047")
		task_row.add_child(p_lbl)

		var star_lbl := Label.new()
		star_lbl.text = t["star"]
		star_lbl.add_theme_font_size_override("font_size", 10)
		star_lbl.modulate = Color("#fbbf24")
		task_row.add_child(star_lbl)

func _update_mode_card() -> void:
	if not is_instance_valid(mode_banner_rect):
		return
	if PlayerState.selected_mode_id == "br_trios":
		mode_banner_rect.texture = ApexLobbyArt.create_kings_canyon_banner(380, 115)
		if mode_tag_lbl: mode_tag_lbl.text = "CORE 核心模式"
		if mode_name_lbl: mode_name_lbl.text = "大逃杀：三人标准赛"
		if mode_map_lbl: mode_map_lbl.text = "诸王峡谷 (12 据点) ▲ 更换模式"
	else:
		mode_banner_rect.texture = ApexLobbyArt.create_firing_range_banner(380, 115)
		if mode_tag_lbl: mode_tag_lbl.text = "TRAINING 训练靶场"
		if mode_name_lbl: mode_name_lbl.text = "全武器训练靶场"
		if mode_map_lbl: mode_map_lbl.text = "22把真实枪架 & 假人 ▲ 更换模式"

func _on_ready_pressed() -> void:
	if is_matchmaking:
		is_matchmaking = false
		ready_btn.text = "准备就绪\nREADY"
		ready_btn.modulate = Color.WHITE
		AudioSynthesizer.play_reload_step("lever_cock")
	else:
		is_matchmaking = true
		match_queue_timer = 1.6
		ready_btn.text = "✔ 正在匹配中...\n[1.6s]"
		ready_btn.modulate = Color("#22c55e")
		AudioSynthesizer.play_evo_level_up()

func _deploy_into_match() -> void:
	get_tree().change_scene_to_file("res://scenes/MatchWorld.tscn")

## ============================================================================
## 3. LEGENDS TAB (12-Hero Dossier & 3D Pedestal)
## ============================================================================
func _build_legends_tab() -> void:
	var view := Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.visible = false
	root_ctrl.add_child(view)
	tab_views.append(view)

	# Left Column: 12 Legend Roster Grid
	var left_panel := PanelContainer.new()
	left_panel.position = Vector2(32, 75)
	left_panel.custom_minimum_size = Vector2(380, 580)
	left_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.07, 0.12, 0.94), Color("#334155"), 2, 8))
	view.add_child(left_panel)

	var l_vb := VBoxContainer.new()
	l_vb.add_theme_constant_override("separation", 8)
	left_panel.add_child(l_vb)

	var l_title := Label.new()
	l_title.text = "【参赛传奇名册 (12位全技能传奇)】"
	l_title.add_theme_font_size_override("font_size", 16)
	l_title.modulate = Color("#fbbf24")
	l_vb.add_child(l_title)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	l_vb.add_child(grid)

	# Right Column: Full Legend Dossier & Skills
	var right_panel := PanelContainer.new()
	right_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_panel.position = Vector2(-440, 75)
	right_panel.custom_minimum_size = Vector2(410, 580)
	right_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.07, 0.12, 0.94), Color("#334155"), 2, 8))
	view.add_child(right_panel)

	var r_vb := VBoxContainer.new()
	r_vb.add_theme_constant_override("separation", 10)
	right_panel.add_child(r_vb)

	var dossier_title := Label.new()
	dossier_title.add_theme_font_size_override("font_size", 18)
	dossier_title.modulate = Color.WHITE
	r_vb.add_child(dossier_title)

	var dossier_lore := Label.new()
	dossier_lore.add_theme_font_size_override("font_size", 13)
	dossier_lore.modulate = Color("#94a3b8")
	dossier_lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r_vb.add_child(dossier_lore)

	var dossier_skills := Label.new()
	dossier_skills.add_theme_font_size_override("font_size", 13)
	dossier_skills.modulate = Color("#cbd5e1")
	dossier_skills.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r_vb.add_child(dossier_skills)

	var dossier_heirloom := Label.new()
	dossier_heirloom.add_theme_font_size_override("font_size", 14)
	dossier_heirloom.modulate = Color("#c084fc")
	r_vb.add_child(dossier_heirloom)

	var update_dossier := func():
		var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
		var cls: Dictionary = GameData.CLASSES.get(leg["class_id"], {})
		dossier_title.text = "%s %s // %s" % [cls.get("name", ""), leg["name"], leg["en"]]
		dossier_title.modulate = leg["primary_color"]
		dossier_lore.text = "称号：%s  |  定位：%s\n专属特性：%s" % [
			leg["title"], cls.get("name", ""), cls.get("perks", [""])[0]
		]
		dossier_skills.text = "• 被动【%s】：%s\n\n• 战术 [Q]【%s】(冷却 %.0fs)：\n%s\n\n• 终极 [Z]【%s】：\n%s" % [
			leg["passive_name"], leg["passive_desc"],
			leg["tac_name"], float(leg["tac_cd"]), leg["tac_desc"],
			leg["ult_name"], leg["ult_desc"]
		]
		dossier_heirloom.text = "🗡️ 专属神话传家宝：【%s】" % leg["heirloom"]["name"]

	update_dossier.call()

	for l in GameData.LEGENDS:
		var btn := Button.new()
		btn.text = "%s\n%s" % [l["name"], l["en"]]
		btn.custom_minimum_size = Vector2(110, 48)
		var lid: String = l["id"]
		btn.pressed.connect(func():
			PlayerState.selected_legend_id = lid
			AudioSynthesizer.play_evo_level_up()
			_refresh_showcase()
			update_dossier.call()
		)
		grid.add_child(btn)

## ============================================================================
## 4. ARMORY TAB (22 Weapons & 3D Viewmodel Showcase)
## ============================================================================
func _build_armory_tab() -> void:
	var view := Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.visible = false
	root_ctrl.add_child(view)
	tab_views.append(view)

	# Left Column: Category Filters & Weapon List
	var left_panel := PanelContainer.new()
	left_panel.position = Vector2(32, 75)
	left_panel.custom_minimum_size = Vector2(390, 580)
	left_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.07, 0.12, 0.94), Color("#334155"), 2, 8))
	view.add_child(left_panel)

	var l_vb := VBoxContainer.new()
	l_vb.add_theme_constant_override("separation", 8)
	left_panel.add_child(l_vb)

	var cat_row := HFlowContainer.new()
	cat_row.add_theme_constant_override("h_separation", 6)
	cat_row.add_theme_constant_override("v_separation", 6)
	l_vb.add_child(cat_row)

	var cats := ["ALL", "AR", "SMG", "LMG", "MARKSMAN", "SNIPER", "SHOTGUN", "PISTOL"]
	var cat_names := ["全部", "突击", "冲锋", "机枪", "射手", "狙击", "霰弹", "手枪"]

	armory_wep_box = VBoxContainer.new()
	armory_wep_box.add_theme_constant_override("separation", 4)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 480)
	scroll.add_child(armory_wep_box)
	l_vb.add_child(scroll)

	# Right Column: Weapon Ballistic Inspection
	var right_panel := PanelContainer.new()
	right_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_panel.position = Vector2(-440, 75)
	right_panel.custom_minimum_size = Vector2(410, 580)
	right_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.07, 0.12, 0.94), Color("#334155"), 2, 8))
	view.add_child(right_panel)

	armory_detail_box = VBoxContainer.new()
	armory_detail_box.add_theme_constant_override("separation", 10)
	right_panel.add_child(armory_detail_box)

	var refresh_armory_list := func():
		for c in armory_wep_box.get_children(): c.queue_free()
		for w in GameData.WEAPONS:
			if current_armory_cat != "ALL" and w["cat"] != current_armory_cat:
				continue
			var btn := Button.new()
			btn.text = "【%s】 %s (弹药: %s)" % [w["cat"], w["name"], w["ammo"]]
			btn.custom_minimum_size = Vector2(350, 36)
			var wid: String = w["id"]
			btn.pressed.connect(func():
				selected_armory_wep_id = wid
				AudioSynthesizer.play_reload_step("bolt_slap")
				_refresh_showcase()
				_update_armory_detail()
			)
			armory_wep_box.add_child(btn)
		_update_armory_detail()

	for i in range(cats.size()):
		var b := Button.new()
		b.text = cat_names[i]
		b.custom_minimum_size = Vector2(40, 28)
		var c_id: String = cats[i]
		b.pressed.connect(func():
			current_armory_cat = c_id
			refresh_armory_list.call()
		)
		cat_row.add_child(b)

	refresh_armory_list.call()

func _update_armory_detail() -> void:
	for c in armory_detail_box.get_children(): c.queue_free()
	var w: Dictionary = GameData.get_weapon_by_id(selected_armory_wep_id)
	var title := Label.new()
	title.text = "%s // %s" % [w["cat"], w["name"]]
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = w.get("accent", Color("#38bdf8"))
	armory_detail_box.add_child(title)

	var stats := Label.new()
	stats.text = "• 弹药口径：%s\n• 射速 (RPM)：%.0f\n• 单发躯干伤害：%d\n• 爆头倍率：%.2fx\n• 弹丸数量：%d\n• 默认弹匣容量：%d 发\n• 战术换弹时间：%.2f 秒\n• 腰射扩散：%.3f  |  开镜扩散：%.4f" % [
		w["ammo"], float(w["rpm"]), int(w["dmg"]), float(w["head"]), int(w["pellets"]), int(w["mag"]), float(w["reload"]), float(w["spread"]), float(w["ads_spread"])
	]
	stats.add_theme_font_size_override("font_size", 14)
	stats.modulate = Color("#cbd5e1")
	armory_detail_box.add_child(stats)

	var equip_btn := Button.new()
	equip_btn.text = "🎯 装备为主武器并加载 3D 枪模"
	equip_btn.custom_minimum_size = Vector2(360, 46)
	equip_btn.modulate = Color("#38bdf8")
	equip_btn.pressed.connect(func():
		PlayerState.loadout[0]["weapon_id"] = selected_armory_wep_id
		PlayerState.loadout[0]["ammo"] = int(w["mag"])
		PlayerState.loadout[0]["max_ammo"] = int(w["mag"])
		AudioSynthesizer.play_reload_step("bolt_slap")
		_refresh_showcase()
	)
	armory_detail_box.add_child(equip_btn)

## ============================================================================
## 5. BATTLE PASS TAB
## ============================================================================
func _build_battlepass_tab() -> void:
	var view := Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.visible = false
	root_ctrl.add_child(view)
	tab_views.append(view)

	var card := PanelContainer.new()
	card.position = Vector2(80, 100)
	card.custom_minimum_size = Vector2(800, 480)
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.07, 0.12, 0.94), Color("#f59e0b"), 2, 8))
	view.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	card.add_child(vb)

	var bp_title := Label.new()
	bp_title.text = "🔥 APEX 外域协议通行证 // 第 20 赛季：救世之光"
	bp_title.add_theme_font_size_override("font_size", 22)
	bp_title.modulate = Color("#fbbf24")
	vb.add_child(bp_title)

	var bp_lvl := Label.new()
	bp_lvl.text = "当前通行证等级：Lv.58 / 110  |  下一级奖励：恶灵金色神话皮肤【虚空守望者】"
	bp_lvl.add_theme_font_size_override("font_size", 15)
	vb.add_child(bp_lvl)

	var prog := ProgressBar.new()
	prog.custom_minimum_size = Vector2(740, 24)
	prog.value = 58.0
	prog.max_value = 110.0
	vb.add_child(prog)

	var claim_btn := Button.new()
	claim_btn.text = "🎁 一键领取全部已解锁通行证奖励"
	claim_btn.custom_minimum_size = Vector2(300, 48)
	claim_btn.pressed.connect(func():
		AudioSynthesizer.play_evo_level_up()
		PlayerState.apex_coins += 500
		PlayerState.crafting_metals += 800
	)
	vb.add_child(claim_btn)

## ============================================================================
## 6. APEX PACKS TAB (Interactive 3D Loot Tick Opening)
## ============================================================================
func _build_packs_tab() -> void:
	var view := Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.visible = false
	root_ctrl.add_child(view)
	tab_views.append(view)

	var card := PanelContainer.new()
	card.position = Vector2(80, 100)
	card.custom_minimum_size = Vector2(500, 280)
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.07, 0.12, 0.94), Color("#ff1e42"), 2, 8))
	view.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	card.add_child(vb)

	var p_title := Label.new()
	p_title.text = "💎 APEX 组合包 // 神话开箱"
	p_title.add_theme_font_size_override("font_size", 22)
	p_title.modulate = Color("#ff1e42")
	vb.add_child(p_title)

	var p_desc := Label.new()
	p_desc.text = "点击开启正前方 3D 机械战利品箱机器人，有概率暴击获得红光神话传家宝碎片！"
	p_desc.add_theme_font_size_override("font_size", 14)
	p_desc.modulate = Color("#cbd5e1")
	p_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(p_desc)

	var open_btn := Button.new()
	open_btn.text = "💥 开启 Apex 组合包 (3D 动画开箱)"
	open_btn.custom_minimum_size = Vector2(360, 52)
	open_btn.modulate = Color("#ff1e42")
	open_btn.pressed.connect(func():
		AudioSynthesizer.play_loot_tick_open()
		if is_instance_valid(tick_ped):
			var tb: Node3D = tick_ped.get_node_or_null("TickBody")
			if tb:
				var tw := create_tween()
				tw.tween_property(tb, "scale", Vector3(1.6, 1.6, 1.6), 0.2)
				tw.tween_property(tb, "scale", Vector3(1.0, 1.0, 1.0), 0.25)
		PlayerState.heirloom_shards = 150
		AudioSynthesizer.play_evo_level_up()
	)
	vb.add_child(open_btn)

## ============================================================================
## 7. SETTINGS TAB
## ============================================================================
func _build_settings_tab() -> void:
	var view := Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.visible = false
	root_ctrl.add_child(view)
	tab_views.append(view)

	var card := PanelContainer.new()
	card.position = Vector2(80, 80)
	card.custom_minimum_size = Vector2(800, 560)
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.07, 0.12, 0.94), Color("#38bdf8"), 2, 8))
	view.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var s_title := Label.new()
	s_title.text = "⚙️ 游戏控制按键指南 (AUTHENTIC CONTROLS)"
	s_title.add_theme_font_size_override("font_size", 20)
	s_title.modulate = Color("#38bdf8")
	vb.add_child(s_title)

	var keys_lbl := Label.new()
	keys_lbl.text = """
• 移动与机动：[W/A/S/D] 行走 | [Shift] 极速冲刺 | [Ctrl / C] 动力滑铲 (支持超滑与蹬墙跳) | [空格] 跳跃
• 武器与战斗：[鼠标左键] 开火 / 传家宝三段连斩 | [鼠标右键] 精确瞄准 (ADS) | [O] 即时切换7种真实分划倍镜
• 换弹与战术：[R] 三阶段战术换弹 (卸弹匣/入匣/拉栓) | [V] 近战出拳 | [N] 检视武器与转刀 | [B] 哨兵/暴走充能
• 技能与恢复：[Q] 传奇战术技能 | [Z] 终极技能 | [4] 使用恢复品 | [H] 切换大电/小电/大药/小药 | [G] 投掷物
• 背包与地图：[TAB] 打开 Apex 纯视觉图标背包 | [E] 开启补给仓与掠夺战利品 | [F1 / F2] 激活蓝紫甲天赋分支
• 视角与退出：[ESC] 解锁/锁定鼠标视角
"""
	keys_lbl.add_theme_font_size_override("font_size", 14)
	keys_lbl.modulate = Color("#f8fafc")
	vb.add_child(keys_lbl)

## ============================================================================
## 8. MODE MODAL
## ============================================================================
func _build_mode_modal() -> void:
	mode_modal = Control.new()
	mode_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	mode_modal.visible = false
	root_ctrl.add_child(mode_modal)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.04, 0.07, 0.90)
	mode_modal.add_child(bg)

	var center_panel := PanelContainer.new()
	center_panel.set_anchors_preset(Control.PRESET_CENTER)
	center_panel.position = Vector2(-460, -260)
	center_panel.custom_minimum_size = Vector2(920, 520)
	center_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.07, 0.12, 0.98), Color("#ef4444"), 2, 8))
	mode_modal.add_child(center_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	center_panel.add_child(vb)

	var title_lbl := Label.new()
	title_lbl.text = "// 选择外域协议赛事模式 (SELECT GAME MODE)"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.modulate = Color("#fde047")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title_lbl)

	var card_row := HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 24)
	card_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(card_row)

	# Mode 1 Card: Battle Royale
	var card_br := PanelContainer.new()
	card_br.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_br.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.09, 0.15, 0.95), Color("#dc2626"), 2, 6))
	card_row.add_child(card_br)

	var br_vb := VBoxContainer.new()
	br_vb.add_theme_constant_override("separation", 10)
	card_br.add_child(br_vb)

	var br_img := TextureRect.new()
	br_img.texture = ApexLobbyArt.create_kings_canyon_banner(400, 150)
	br_img.custom_minimum_size = Vector2(380, 150)
	br_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	br_img.stretch_mode = TextureRect.STRETCH_SCALE
	br_vb.add_child(br_img)

	var br_title := Label.new()
	br_title.text = "🚀 大逃杀：三人标准赛 (TRIOS)"
	br_title.add_theme_font_size_override("font_size", 18)
	br_title.modulate = Color("#ef4444")
	br_vb.add_child(br_title)

	var br_desc := Label.new()
	br_desc.text = "• 60 人同局空投争夺外域捍卫者\n• 新黎明峡谷 12 据点全开 (雷达站/水坝/骷髅镇)\n• 5 阶段毒圈动态收缩 · 补给舱与空投补给\n• 队伍重生信标与秒换甲机制"
	br_desc.add_theme_font_size_override("font_size", 12)
	br_desc.modulate = Color("#cbd5e1")
	br_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	br_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	br_vb.add_child(br_desc)

	var br_select_btn := Button.new()
	br_select_btn.text = "🎯 确认选择此模式"
	br_select_btn.custom_minimum_size = Vector2(0, 44)
	br_select_btn.modulate = Color("#ef4444")
	br_select_btn.pressed.connect(func():
		PlayerState.selected_mode_id = "br_trios"
		_update_mode_card()
		mode_modal.visible = false
		AudioSynthesizer.play_reload_step("lever_cock")
	)
	br_vb.add_child(br_select_btn)

	# Mode 2 Card: Firing Range
	var card_fr := PanelContainer.new()
	card_fr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_fr.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.09, 0.15, 0.95), Color("#06b6d4"), 2, 6))
	card_row.add_child(card_fr)

	var fr_vb := VBoxContainer.new()
	fr_vb.add_theme_constant_override("separation", 10)
	card_fr.add_child(fr_vb)

	var fr_img := TextureRect.new()
	fr_img.texture = ApexLobbyArt.create_firing_range_banner(400, 150)
	fr_img.custom_minimum_size = Vector2(380, 150)
	fr_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fr_img.stretch_mode = TextureRect.STRETCH_SCALE
	fr_vb.add_child(fr_img)

	var fr_title := Label.new()
	fr_title.text = "🎯 全武器训练靶场 (FIRING RANGE)"
	fr_title.add_theme_font_size_override("font_size", 18)
	fr_title.modulate = Color("#06b6d4")
	fr_vb.add_child(fr_title)

	var fr_desc := Label.new()
	fr_desc.text = "• 22 把真实 3D 枪械陈列架 (含先滋后崩滋崩)\n• 无限轻型/重型/能量/狙击/霰弹备弹\n• 智能战斗假人移动与射击练习\n• 全套 7 种真实分划瞄准镜即时切换 [O]"
	fr_desc.add_theme_font_size_override("font_size", 12)
	fr_desc.modulate = Color("#cbd5e1")
	fr_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fr_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fr_vb.add_child(fr_desc)

	var fr_select_btn := Button.new()
	fr_select_btn.text = "🎯 确认选择此模式"
	fr_select_btn.custom_minimum_size = Vector2(0, 44)
	fr_select_btn.modulate = Color("#06b6d4")
	fr_select_btn.pressed.connect(func():
		PlayerState.selected_mode_id = "firing_range"
		_update_mode_card()
		mode_modal.visible = false
		AudioSynthesizer.play_reload_step("lever_cock")
	)
	fr_vb.add_child(fr_select_btn)

	var close_btn := Button.new()
	close_btn.text = "返回大厅 (BACK)"
	close_btn.custom_minimum_size = Vector2(200, 38)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func():
		mode_modal.visible = false
	)
	vb.add_child(close_btn)

## ============================================================================
## 9. DRAFT SCREEN (选人阶段)
## ============================================================================
func _build_draft_screen() -> void:
	draft_overlay = Control.new()
	draft_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	draft_overlay.visible = false
	root_ctrl.add_child(draft_overlay)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.04, 0.07, 0.95)
	draft_overlay.add_child(bg)

	var center_box := VBoxContainer.new()
	center_box.set_anchors_preset(Control.PRESET_CENTER)
	center_box.position = Vector2(-460, -280)
	center_box.custom_minimum_size = Vector2(920, 560)
	center_box.add_theme_constant_override("separation", 16)
	draft_overlay.add_child(center_box)

	var d_title := Label.new()
	d_title.text = "// 部署就绪：选择你的出战传奇 (SELECT YOUR LEGEND)"
	d_title.add_theme_font_size_override("font_size", 22)
	d_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_title.modulate = Color("#ef4444")
	center_box.add_child(d_title)

	draft_timer_lbl = Label.new()
	draft_timer_lbl.text = "⏱️ 空投倒计时: 10.0 秒"
	draft_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	draft_timer_lbl.add_theme_font_size_override("font_size", 16)
	draft_timer_lbl.modulate = Color("#fde047")
	center_box.add_child(draft_timer_lbl)

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	center_box.add_child(grid)

	for l in GameData.LEGENDS:
		var btn := Button.new()
		btn.text = "%s\n%s" % [l["name"], l["en"]]
		btn.custom_minimum_size = Vector2(140, 68)
		var lid: String = l["id"]
		btn.pressed.connect(func():
			PlayerState.selected_legend_id = lid
			AudioSynthesizer.play_evo_level_up()
			_update_draft_voice()
		)
		grid.add_child(btn)

	draft_voice_lbl = Label.new()
	draft_voice_lbl.add_theme_font_size_override("font_size", 16)
	draft_voice_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	draft_voice_lbl.modulate = Color("#38bdf8")
	center_box.add_child(draft_voice_lbl)

	var lock_btn := Button.new()
	lock_btn.text = "🚀 锁定当前传奇并立即跳伞空投部署！"
	lock_btn.custom_minimum_size = Vector2(400, 52)
	lock_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lock_btn.modulate = Color("#22c55e")
	lock_btn.pressed.connect(_deploy_into_match)
	center_box.add_child(lock_btn)

func _open_draft_screen() -> void:
	draft_overlay.visible = true
	draft_countdown_timer = 10.0
	_update_draft_voice()

func _update_draft_voice() -> void:
	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	var quotes: Dictionary = {
		"wraith": "恶灵：'虚空在呼唤我。我知道正确的道路。'",
		"octane": "动力小子：'快点！再快点！慢吞吞的家伙只配吃我的尾气！'",
		"bloodhound": "寻血猎犬：'以众神之父之名，我将指引这场神圣狩猎。'",
		"lifeline": "命脉：'放轻松，只要我不倒下，没人能淘汰你。'",
		"pathfinder": "探路者：'你好朋友！准备好乘上我的滑索了吗？'",
		"gibraltar": "直布罗陀：'哈哈哈！躲在老哥的护盾后面，保证你毫发无损！'"
	}
	var q: String = quotes.get(PlayerState.selected_legend_id, "%s：'外域协议已就绪，捍卫者归属于我们！'" % leg["name"])
	if draft_voice_lbl:
		draft_voice_lbl.text = q
