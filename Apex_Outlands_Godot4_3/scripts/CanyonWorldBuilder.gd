class_name CanyonWorldBuilder
extends RefCounted
## Procedurally constructs the 640x640m "New Dawn Canyon" 3D map with:
## - High-Detail Multi-Part Supply Bins (matching reference image_55d43f.png: ribbed octagonal base, yellow hazard bumpers, hydraulic struts, glowing LED rim, clam-shell animated lid, and visible 3D interior loot items)
## - 3-Legged Apex Pack / Loot Tick Robots (matching reference image_55d4db.jpg: pyramidal armored body, red/white/gold plates, central glowing optical eye, 3 articulated mechanical legs)
## - Detailed Industrial Cargo Crates, Shipping Containers, Canyon Rock Formations, and Multi-Story POI Buildings with Ramps & Rooftop Parapets.

static func _make_mat(col: Color, metal: float = 0.65, rough: float = 0.35, emit: bool = false, emit_e: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = rough
	if emit:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit_e
	return m

static func _add_box(parent: Node3D, sz: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, name_str: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name_str != "":
		mi.name = name_str
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, rt: float, rb: float, h: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, sides: int = 10, name_str: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name_str != "":
		mi.name = name_str
	var cm := CylinderMesh.new()
	cm.top_radius = rt
	cm.bottom_radius = rb
	cm.height = h
	cm.radial_segments = sides
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

## Builds an authentic Apex Supply Bin (image_55d43f.png) with LidPivot & visible interior loot
static func create_supply_bin_node(bin_type: String = "normal") -> Node3D:
	var root := Node3D.new()
	root.name = "ApexSupplyBin"

	var lid_col := Color("#cbd5e1")
	var led_col := Color("#2dd4bf")
	if bin_type == "assault":
		lid_col = Color("#dc2626")
		led_col = Color("#ff2a4b")
	elif bin_type == "support":
		lid_col = Color("#0284c7")
		led_col = Color("#38bdf8")

	var mat_base := _make_mat(Color("#1e293b"), 0.78, 0.35)
	var mat_rib := _make_mat(Color("#0f172a"), 0.85, 0.28)
	var mat_hazard := _make_mat(Color("#f59e0b"), 0.45, 0.40)
	var mat_lid := _make_mat(lid_col, 0.68, 0.30)
	var mat_led := _make_mat(led_col, 0.2, 0.1, true, 3.2)

	# 1. Lower Octagonal Trough Base + Structural Ribs
	_add_box(root, Vector3(2.72, 0.68, 1.42), Vector3(0, 0.34, 0), mat_base, Vector3.ZERO, "BinBase")
	_add_box(root, Vector3(2.82, 0.24, 1.52), Vector3(0, 0.12, 0), mat_rib, Vector3.ZERO, "BinFootSkirt")
	for r in range(-2, 3):
		_add_box(root, Vector3(0.14, 0.66, 1.48), Vector3(float(r) * 0.54, 0.35, 0), mat_rib)

	# Yellow Hazard Corner Bumpers & Side Handles
	for sx in [-1.0, 1.0]:
		_add_box(root, Vector3(0.16, 0.36, 1.46), Vector3(sx * 1.36, 0.50, 0), mat_hazard)
		_add_cyl(root, 0.08, 0.08, 0.65, Vector3(sx * 1.38, 0.68, -0.55), mat_rib, Vector3(0.35, 0, 0), 8, "HydraulicStrut")

	# Glowing Cyan/Red LED Seam Strip & Interior Loot Tray
	_add_box(root, Vector3(2.68, 0.05, 1.44), Vector3(0, 0.69, 0), mat_led, Vector3.ZERO, "LedRim")
	_add_box(root, Vector3(2.48, 0.06, 1.22), Vector3(0, 0.66, 0), mat_rib, Vector3.ZERO, "InteriorTray")

	# Visible 3D Interior Loot Items (Shield Batteries, Ammo Boxes, Weapon Core)
	var mat_bat := _make_mat(Color("#38bdf8"), 0.5, 0.2, true, 2.2)
	var mat_purp := _make_mat(Color("#a855f7"), 0.5, 0.2, true, 2.4)
	_add_cyl(root, 0.11, 0.11, 0.32, Vector3(-0.75, 0.82, 0.12), mat_bat, Vector3.ZERO, 8)
	_add_cyl(root, 0.11, 0.11, 0.32, Vector3(-0.42, 0.82, -0.10), mat_bat, Vector3.ZERO, 8)
	_add_box(root, Vector3(0.58, 0.14, 0.24), Vector3(0.18, 0.76, 0.05), mat_purp)
	_add_box(root, Vector3(0.32, 0.18, 0.28), Vector3(0.82, 0.78, -0.08), mat_hazard)

	# 2. Articulated Clam-Shell Upper Lid (LidPivot at rear hinge so it swings open smoothly!)
	var lid_pivot := Node3D.new()
	lid_pivot.name = "LidPivot"
	lid_pivot.position = Vector3(0, 0.72, -0.68)
	root.add_child(lid_pivot)

	_add_box(lid_pivot, Vector3(2.74, 0.42, 1.42), Vector3(0, 0.21, 0.68), mat_lid, Vector3.ZERO, "LidMain")
	_add_box(lid_pivot, Vector3(2.56, 0.18, 1.12), Vector3(0, 0.46, 0.68), mat_base, Vector3.ZERO, "LidTopArch")
	for p in [-1, 0, 1]:
		_add_box(lid_pivot, Vector3(0.68, 0.10, 0.92), Vector3(float(p) * 0.82, 0.52, 0.68), mat_lid)
	# Front Latch Lock
	_add_box(lid_pivot, Vector3(0.38, 0.18, 0.08), Vector3(0, 0.12, 1.40), mat_led, Vector3.ZERO, "FrontLatch")

	return root

## Builds an authentic 3-Legged Apex Pack / Loot Tick Robot (image_55d4db.jpg)
static func create_loot_tick_node(tier_rarity: int = 4) -> Node3D:
	var root := Node3D.new()
	root.name = "ApexLootTick"

	var glow_col := Color("#f59e0b") if tier_rarity == 4 else (Color("#ff1e42") if tier_rarity >= 5 else Color("#a855f7"))
	var mat_shell := _make_mat(Color("#f8fafc"), 0.65, 0.25)
	var mat_red := _make_mat(Color("#dc2626"), 0.70, 0.28)
	var mat_dark := _make_mat(Color("#1e293b"), 0.80, 0.32)
	var mat_joint := _make_mat(Color("#f59e0b"), 0.75, 0.30)
	var mat_glow := _make_mat(glow_col, 0.2, 0.1, true, 3.8)

	var body_pivot := Node3D.new()
	body_pivot.name = "TickBody"
	body_pivot.position = Vector3(0, 0.58, 0)
	root.add_child(body_pivot)

	# Pyramidal 3-Sided Robotic Pod Core
	_add_cyl(body_pivot, 0.18, 0.46, 0.56, Vector3(0, 0.06, 0), mat_shell, Vector3.ZERO, 3, "PyramidCore")
	_add_cyl(body_pivot, 0.22, 0.48, 0.22, Vector3(0, -0.08, 0), mat_red, Vector3.ZERO, 3, "RedArmorBand")
	_add_cyl(body_pivot, 0.14, 0.14, 0.08, Vector3(0, 0.36, 0), mat_dark, Vector3.ZERO, 6, "TopCap")

	# Central Glowing Eye Lens on Front Face
	_add_cyl(body_pivot, 0.12, 0.12, 0.10, Vector3(0, 0.04, 0.24), mat_dark, Vector3(PI * 0.5, 0, 0), 12)
	_add_cyl(body_pivot, 0.085, 0.085, 0.12, Vector3(0, 0.04, 0.25), mat_glow, Vector3(PI * 0.5, 0, 0), 12, "GlowingEye")

	# 3 Articulated Mechanical Legs spaced at 120 degrees
	for i in range(3):
		var ang: float = float(i) * (TAU / 3.0) + PI * 0.33
		var leg_root := Node3D.new()
		leg_root.rotation.y = ang
		body_pivot.add_child(leg_root)

		_add_box(leg_root, Vector3(0.10, 0.12, 0.26), Vector3(0, -0.12, 0.32), mat_dark, Vector3(0.35, 0, 0), "UpperThigh")
		_add_cyl(leg_root, 0.065, 0.065, 0.12, Vector3(0, -0.20, 0.44), mat_joint, Vector3(0, 0, PI * 0.5), 8, "KneeServo")
		_add_box(leg_root, Vector3(0.08, 0.42, 0.10), Vector3(0, -0.38, 0.48), mat_shell, Vector3(-0.18, 0, 0), "LowerShin")
		_add_box(leg_root, Vector3(0.14, 0.06, 0.18), Vector3(0, -0.56, 0.52), mat_dark, Vector3.ZERO, "FootPad")

	return root

## Builds an Industrial Sci-Fi Cargo Crate / Cover Box
static func create_cargo_crate_node(w: float = 2.2, h: float = 1.6, d: float = 1.8, accent_col: Color = Color("#f59e0b")) -> StaticBody3D:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(w, h, d)
	col.shape = shape
	col.position = Vector3(0, h * 0.5, 0)
	body.add_child(col)

	var mat_main := _make_mat(Color("#273449"), 0.62, 0.42)
	var mat_frame := _make_mat(Color("#0f172a"), 0.82, 0.28)
	var mat_acc := _make_mat(accent_col, 0.4, 0.2, true, 2.0)

	_add_box(body, Vector3(w, h, d), Vector3(0, h * 0.5, 0), mat_main)
	_add_box(body, Vector3(w + 0.06, 0.14, d + 0.06), Vector3(0, h - 0.08, 0), mat_frame)
	_add_box(body, Vector3(w + 0.06, 0.14, d + 0.06), Vector3(0, 0.08, 0), mat_frame)
	_add_box(body, Vector3(w + 0.08, 0.08, d * 0.65), Vector3(0, h * 0.52, 0), mat_acc)

	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_box(body, Vector3(0.16, h + 0.04, 0.16), Vector3(sx * (w * 0.5), h * 0.5, sz * (d * 0.5)), mat_frame)

	return body

static func build_canyon_world(parent: Node3D) -> Dictionary:
	var interactables: Array = []

	# Terrain Floor + StaticBody3D
	var floor_body := StaticBody3D.new()
	floor_body.name = "CanyonTerrain"
	var terrain_col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(640, 1.0, 640)
	terrain_col.shape = box_shape
	terrain_col.position = Vector3(0, -0.5, 0)
	floor_body.add_child(terrain_col)

	var floor_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(640, 0.2, 640)
	floor_mesh.mesh = plane
	var mat_ground := StandardMaterial3D.new()
	mat_ground.albedo_color = Color("#1a2436")
	mat_ground.roughness = 0.88
	floor_mesh.material_override = mat_ground
	floor_body.add_child(floor_mesh)
	parent.add_child(floor_body)

	var mat_wall := _make_mat(Color("#334155"), 0.38, 0.52)
	var mat_roof := _make_mat(Color("#1e293b"), 0.55, 0.40)
	var mat_rock := _make_mat(Color("#3b312b"), 0.12, 0.88)

	# 1. Spawn Firing Range 22-Weapon Armory Racks + Supply Bins + Loot Ticks right near spawn (0, 0, -10)
	var rack_mat := _make_mat(Color("#0f172a"), 0.78, 0.28)
	for i in range(GameData.WEAPONS.size()):
		var w: Dictionary = GameData.WEAPONS[i]
		var rx: float = (float(i % 11) - 5.0) * 3.2
		var rz: float = -10.0 - float(i / 11) * 4.8
		var stand := MeshInstance3D.new()
		var sbox := BoxMesh.new()
		sbox.size = Vector3(2.2, 1.05, 0.9)
		stand.mesh = sbox
		stand.material_override = rack_mat
		stand.position = Vector3(rx, 0.525, rz)
		parent.add_child(stand)

		var gun_preview := WeaponMeshBuilder.create_viewmodel(w, false, {}, "2x_bruiser")
		gun_preview.position = Vector3(0, 0.82, 0)
		gun_preview.rotation = Vector3(0, PI * 0.5, 0)
		gun_preview.scale = Vector3(1.15, 1.15, 1.15)
		var l_arm := gun_preview.get_node_or_null("GunRig/LeftArmPivot")
		var r_arm := gun_preview.get_node_or_null("GunRig/RightArmPivot")
		if l_arm: l_arm.visible = false
		if r_arm: r_arm.visible = false
		stand.add_child(gun_preview)

		var lbl := Label3D.new()
		lbl.text = "[E] %s" % str(w["name"])
		lbl.font_size = 22
		lbl.pixel_size = 0.0038
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.modulate = w.get("accent", Color("#f97316"))
		lbl.position = Vector3(0, 1.25, 0)
		stand.add_child(lbl)

		interactables.append({
			"type": "weapon_rack",
			"weapon_id": str(w["id"]),
			"name": "装备 【%s】" % str(w["name"]),
			"pos": stand.position,
			"node": stand
		})

	# Spawn 3 High-Detail Supply Bins & 2 Loot Ticks right beside spawn so player can inspect & open them immediately!
	var spawn_bin_types := ["normal", "assault", "support"]
	for sb in range(3):
		var btype: String = spawn_bin_types[sb]
		var bin_node := create_supply_bin_node(btype)
		bin_node.position = Vector3(-11.0 + float(sb) * 4.2, 0.0, -4.5)
		parent.add_child(bin_node)
		var bname: String = "红色突击武器补给仓" if btype == "assault" else ("蓝色支援医疗补给仓" if btype == "support" else "外域标准补给仓")
		interactables.append({
			"type": "supply_bin",
			"bin_type": btype,
			"name": "开启 %s (大电/满甲/+100 EVO)" % bname,
			"pos": bin_node.position,
			"node": bin_node,
			"opened": false
		})

	for lt in range(2):
		var tick_node := create_loot_tick_node(5 if lt == 0 else 4)
		tick_node.position = Vector3(6.5 + float(lt) * 3.2, 0.0, -4.5)
		parent.add_child(tick_node)
		interactables.append({
			"type": "loot_tick",
			"rarity": 5 if lt == 0 else 4,
			"name": "开启 💎 战利品箱机器人 (必爆红甲/传家宝碎片/空投金枪)",
			"pos": tick_node.position,
			"node": tick_node,
			"opened": false
		})

	# Spawn tactical cover crates in the firing range duel zone
	for c_idx in range(6):
		var cr := create_cargo_crate_node(2.4, 1.55, 1.6, Color("#38bdf8") if c_idx % 2 == 0 else Color("#f97316"))
		cr.position = Vector3((float(c_idx) - 2.5) * 6.2, 0.0, -18.5)
		parent.add_child(cr)

	# 2. Build 12 Named POIs across the Canyon with Buildings, Rooftop Parapets, Ramps, Supply Bins, Loot Ticks & Cargo Crates
	for poi in GameData.MAP_POIS:
		var p_pos: Vector2 = poi["pos"]
		var b_count: int = int(poi["buildings"])
		var accent_mat := _make_mat(poi["color"], 0.4, 0.2, true, 1.8)

		for b in range(b_count):
			var ang: float = (float(b) / float(b_count)) * TAU
			var dist: float = 16.0 + float(b % 2) * 8.0
			var bx: float = p_pos.x + cos(ang) * dist
			var bz: float = p_pos.y + sin(ang) * dist
			var bw: float = 12.0 + float(b % 3) * 2.0
			var bh: float = 5.2 + float(b % 2) * 2.0
			var bd: float = 12.0 + float((b + 1) % 3) * 2.0

			var b_root := Node3D.new()
			b_root.position = Vector3(bx, 0.0, bz)
			parent.add_child(b_root)

			# 1. Solid Ground Floor with Collision (Embedded flush with terrain y=0 so doorways have zero step/snagging!)
			var floor_sb := StaticBody3D.new()
			var floor_col := CollisionShape3D.new()
			var floor_shape := BoxShape3D.new()
			floor_shape.size = Vector3(bw, 0.40, bd)
			floor_col.shape = floor_shape
			floor_col.position = Vector3(0, -0.20, 0)
			floor_sb.add_child(floor_col)
			_add_box(floor_sb, Vector3(bw, 0.40, bd), Vector3(0, -0.20, 0), mat_roof)
			b_root.add_child(floor_sb)

			# 2. Solid Rooftop Ceiling with Collision
			var roof_sb := StaticBody3D.new()
			var roof_col := CollisionShape3D.new()
			var roof_shape := BoxShape3D.new()
			roof_shape.size = Vector3(bw + 0.4, 0.35, bd + 0.4)
			roof_col.shape = roof_shape
			roof_col.position = Vector3(0, bh + 0.175, 0)
			roof_sb.add_child(roof_col)
			_add_box(roof_sb, Vector3(bw + 0.4, 0.35, bd + 0.4), Vector3(0, bh + 0.175, 0), mat_roof)
			_add_box(roof_sb, Vector3(bw + 0.6, 0.25, bd + 0.6), Vector3(0, bh, 0), accent_mat)
			b_root.add_child(roof_sb)

			# 3. Rooftop Parapets (Waist-height cover walls on roof with real collision & ramp doorway opening!)
			for p_side in [0, 1, 2, 3]:
				if p_side == 0: # North Parapet
					var p_sz := Vector3(bw, 1.05, 0.35)
					var pw_pos := Vector3(0, bh + 0.35 + 0.525, -bd * 0.5)
					var sb := StaticBody3D.new()
					var col_north := CollisionShape3D.new()
					var sh := BoxShape3D.new()
					sh.size = p_sz
					col_north.shape = sh
					col_north.position = pw_pos
					sb.add_child(col_north)
					_add_box(sb, p_sz, pw_pos, mat_roof)
					b_root.add_child(sb)
				elif p_side == 1: # South Parapet
					var p_sz := Vector3(bw, 1.05, 0.35)
					var pw_pos := Vector3(0, bh + 0.35 + 0.525, bd * 0.5)
					var sb := StaticBody3D.new()
					var col_south := CollisionShape3D.new()
					var sh := BoxShape3D.new()
					sh.size = p_sz
					col_south.shape = sh
					col_south.position = pw_pos
					sb.add_child(col_south)
					_add_box(sb, p_sz, pw_pos, mat_roof)
					b_root.add_child(sb)
				elif p_side == 2: # West Parapet
					var p_sz := Vector3(0.35, 1.05, bd)
					var pw_pos := Vector3(-bw * 0.5, bh + 0.35 + 0.525, 0)
					var sb := StaticBody3D.new()
					var col_west := CollisionShape3D.new()
					var sh := BoxShape3D.new()
					sh.size = p_sz
					col_west.shape = sh
					col_west.position = pw_pos
					sb.add_child(col_west)
					_add_box(sb, p_sz, pw_pos, mat_roof)
					b_root.add_child(sb)
				else: # East Parapet: Split with 2.6m doorway for ramp rooftop entrance!
					var n_len: float = maxf(0.5, bd * 0.5 - 6.3)
					if n_len > 0.5:
						var n_sz := Vector3(0.35, 1.05, n_len)
						var n_pos := Vector3(bw * 0.5, bh + 0.35 + 0.525, -bd * 0.5 + n_len * 0.5)
						var sb_n := StaticBody3D.new()
						var col_n := CollisionShape3D.new()
						var sh_n := BoxShape3D.new()
						sh_n.size = n_sz
						col_n.shape = sh_n
						col_n.position = n_pos
						sb_n.add_child(col_n)
						_add_box(sb_n, n_sz, n_pos, mat_roof)
						b_root.add_child(sb_n)
					var s_len: float = maxf(0.5, bd * 0.5 + 3.7)
					var s_sz := Vector3(0.35, 1.05, s_len)
					var s_pos := Vector3(bw * 0.5, bh + 0.35 + 0.525, bd * 0.5 - s_len * 0.5)
					var sb_s := StaticBody3D.new()
					var col_s := CollisionShape3D.new()
					var sh_s := BoxShape3D.new()
					sh_s.size = s_sz
					col_s.shape = sh_s
					col_s.position = s_pos
					sb_s.add_child(col_s)
					_add_box(sb_s, s_sz, s_pos, mat_roof)
					b_root.add_child(sb_s)

			# 4. 4 Exterior Walls with 3.4m Walk-Through Doorways (Zero Clipping!)
			# West Wall (Solid)
			var w_wall_sb := StaticBody3D.new()
			var w_col := CollisionShape3D.new()
			var w_shape := BoxShape3D.new()
			w_shape.size = Vector3(0.4, bh, bd)
			w_col.shape = w_shape
			w_col.position = Vector3(-bw * 0.5 + 0.2, bh * 0.5, 0)
			w_wall_sb.add_child(w_col)
			_add_box(w_wall_sb, Vector3(0.4, bh, bd), Vector3(-bw * 0.5 + 0.2, bh * 0.5, 0), mat_wall)
			b_root.add_child(w_wall_sb)

			# East Wall (Solid)
			var e_wall_sb := StaticBody3D.new()
			var e_col := CollisionShape3D.new()
			var e_shape := BoxShape3D.new()
			e_shape.size = Vector3(0.4, bh, bd)
			e_col.shape = e_shape
			e_col.position = Vector3(bw * 0.5 - 0.2, bh * 0.5, 0)
			e_wall_sb.add_child(e_col)
			_add_box(e_wall_sb, Vector3(0.4, bh, bd), Vector3(bw * 0.5 - 0.2, bh * 0.5, 0), mat_wall)
			b_root.add_child(e_wall_sb)

			# North Wall (Front with 3.4m Doorway)
			var half_w: float = (bw - 3.4) * 0.5
			for s in [-1.0, 1.0]:
				var nw_sb := StaticBody3D.new()
				var nw_col := CollisionShape3D.new()
				var nw_shape := BoxShape3D.new()
				nw_shape.size = Vector3(half_w, bh, 0.4)
				nw_col.shape = nw_shape
				var nw_pos := Vector3(s * (3.4 * 0.5 + half_w * 0.5), bh * 0.5, -bd * 0.5 + 0.2)
				nw_col.position = nw_pos
				nw_sb.add_child(nw_col)
				_add_box(nw_sb, Vector3(half_w, bh, 0.4), nw_pos, mat_wall)
				b_root.add_child(nw_sb)

			# Door Header / Lintel
			var lintel_sb := StaticBody3D.new()
			var lintel_col := CollisionShape3D.new()
			var lintel_shape := BoxShape3D.new()
			lintel_shape.size = Vector3(3.4, bh - 3.0, 0.4)
			lintel_col.shape = lintel_shape
			var lintel_pos := Vector3(0, 3.0 + (bh - 3.0) * 0.5, -bd * 0.5 + 0.2)
			lintel_col.position = lintel_pos
			lintel_sb.add_child(lintel_col)
			_add_box(lintel_sb, Vector3(3.4, bh - 3.0, 0.4), lintel_pos, accent_mat)
			b_root.add_child(lintel_sb)

			# South Wall (Back with Doorway)
			for s in [-1.0, 1.0]:
				var sw_sb := StaticBody3D.new()
				var sw_col := CollisionShape3D.new()
				var sw_shape := BoxShape3D.new()
				sw_shape.size = Vector3(half_w, bh, 0.4)
				sw_col.shape = sw_shape
				var sw_pos := Vector3(s * (3.4 * 0.5 + half_w * 0.5), bh * 0.5, bd * 0.5 - 0.2)
				sw_col.position = sw_pos
				sw_sb.add_child(sw_col)
				_add_box(sw_sb, Vector3(half_w, bh, 0.4), sw_pos, mat_wall)
				b_root.add_child(sw_sb)

			# 5. Exterior Walkable Rooftop Ramp + Solid Catwalk Landing (Walk from ground to roof with zero clipping!)
			var ramp_sb := StaticBody3D.new()
			var ramp_col := CollisionShape3D.new()
			var ramp_shape := BoxShape3D.new()
			var ramp_len: float = sqrt(bh * bh + 10.0 * 10.0)
			ramp_shape.size = Vector3(2.4, 0.25, ramp_len)
			ramp_col.shape = ramp_shape
			var ramp_angle: float = atan2(bh, 10.0)
			ramp_col.rotation = Vector3(-ramp_angle, 0, 0)
			ramp_col.position = Vector3(bw * 0.5 + 1.2, bh * 0.5, 0)
			ramp_sb.add_child(ramp_col)
			_add_box(ramp_sb, Vector3(2.4, 0.25, ramp_len), ramp_col.position, mat_roof, ramp_col.rotation)
			b_root.add_child(ramp_sb)

			# Horizontal Rooftop Catwalk Landing Platform bridging ramp directly into the rooftop doorway
			var land_sb := StaticBody3D.new()
			var land_col := CollisionShape3D.new()
			var land_shape := BoxShape3D.new()
			land_shape.size = Vector3(2.4, 0.35, 2.6)
			land_col.shape = land_shape
			land_col.position = Vector3(bw * 0.5 + 1.2, bh + 0.175, -5.0)
			land_sb.add_child(land_col)
			_add_box(land_sb, Vector3(2.4, 0.35, 2.6), land_col.position, mat_roof)
			b_root.add_child(land_sb)

			# Exterior Cargo Crates near each building
			var crate := create_cargo_crate_node(2.2, 1.5, 1.6, poi["color"])
			crate.position = Vector3(bx + bw * 0.65, 0.0, bz)
			parent.add_child(crate)

		# Canyon Rock Pillars around POI perimeter (With real CollisionShape3D!)
		var rock_b := StaticBody3D.new()
		rock_b.position = Vector3(p_pos.x - 22.0, 4.5, p_pos.y - 18.0)
		var rock_col := CollisionShape3D.new()
		var rock_cyl := CylinderShape3D.new()
		rock_cyl.radius = 4.2
		rock_cyl.height = 9.0
		rock_col.shape = rock_cyl
		rock_b.add_child(rock_col)
		_add_cyl(rock_b, 3.2, 5.8, 9.0, Vector3.ZERO, mat_rock, Vector3.ZERO, 7)
		parent.add_child(rock_b)

		# 3 High-Detail Supply Bins per POI
		for s_idx in range(3):
			var b_kind: String = "assault" if s_idx == 0 else ("support" if s_idx == 1 else "normal")
			var s_bin := create_supply_bin_node(b_kind)
			s_bin.position = Vector3(p_pos.x + float(s_idx - 1) * 4.5, 0.0, p_pos.y + 5.5)
			parent.add_child(s_bin)
			interactables.append({
				"type": "supply_bin",
				"bin_type": b_kind,
				"name": "开启 %s 补给仓 (补满弹药/电池/EVO)" % str(poi["name"]),
				"pos": s_bin.position,
				"node": s_bin,
				"opened": false
			})

		# 1 Loot Tick per POI
		var poi_tick := create_loot_tick_node(4)
		poi_tick.position = Vector3(p_pos.x, 0.0, p_pos.y - 4.0)
		parent.add_child(poi_tick)
		interactables.append({
			"type": "loot_tick",
			"rarity": 4,
			"name": "开启 %s 战利品箱机器人" % str(poi["name"]),
			"pos": poi_tick.position,
			"node": poi_tick,
			"opened": false
		})

	# Shrinking Orange Energy Ring Cylinder
	var ring_inst := MeshInstance3D.new()
	ring_inst.name = "ApexRingCylinder"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 140.0
	ring_inst.mesh = cyl
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.33, 0.0, 0.22)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring_mat.emission_enabled = true
	ring_mat.emission = Color("#ff5500")
	ring_inst.material_override = ring_mat
	ring_inst.position = Vector3(0, 70, 0)
	ring_inst.scale = Vector3(290, 1, 290)
	parent.add_child(ring_inst)

	return {"interactables": interactables, "ring_mesh": ring_inst}
