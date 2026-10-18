class_name CanyonWorldBuilder
extends RefCounted
## Procedurally constructs the 640x640m "New Dawn Canyon" 3D map for Godot 4.3 with:
## - Procedural PBR Texture & Normal-Map Material Library (`FastNoiseLite` + `NoiseTexture2D` with Triplanar mapping)
##   for Sandstone Cliff Rocks, Weathered Concrete Walls, Diamond-Plate Metal Floors, Corrugated Steel, and Carbon/Polymer
## - High-Detail Multi-Part Supply Bins & 3-Legged Apex Pack / Loot Tick Robots
## - 28-Weapon Armory Racks + Dedicated Wall-Climb & Mantle Parkour Training Tower in Firing Range
## - Upgraded 2-Story IMC POI Buildings with Interior Mezzanine 2nd Floor, Indoor Staircase, Tactical Window Openings,
##   Rooftop Skylights, Industrial Pipework, and Climbable Exterior Wall Ledges/Crates
## - Sculpted Multi-Tiered Kings Canyon Sandstone Strata Cliffs & Arches.

static var _noise_tex_cache: Dictionary = {}
static var _pbr_mat_cache: Dictionary = {}

static func get_procedural_normal_tex(kind: String) -> NoiseTexture2D:
	if _noise_tex_cache.has(kind):
		return _noise_tex_cache[kind]

	var fn := FastNoiseLite.new()
	var tex := NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	tex.as_normal_map = true

	match kind:
		"sandstone":
			fn.noise_type = FastNoiseLite.TYPE_CELLULAR
			fn.frequency = 0.045
			fn.fractal_type = FastNoiseLite.FRACTAL_FBM
			fn.fractal_octaves = 3
			fn.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
			tex.bump_strength = 12.5
		"concrete":
			fn.noise_type = FastNoiseLite.TYPE_PERLIN
			fn.frequency = 0.065
			fn.fractal_type = FastNoiseLite.FRACTAL_FBM
			fn.fractal_octaves = 3
			tex.bump_strength = 7.5
		"metal_plate":
			fn.noise_type = FastNoiseLite.TYPE_CELLULAR
			fn.frequency = 0.11
			fn.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
			tex.bump_strength = 8.0
		"gunmetal":
			fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
			fn.frequency = 0.14
			fn.fractal_type = FastNoiseLite.FRACTAL_RIDGED
			fn.fractal_octaves = 2
			tex.bump_strength = 4.5
		"carbon_weave":
			fn.noise_type = FastNoiseLite.TYPE_CELLULAR
			fn.frequency = 0.18
			fn.cellular_distance_function = FastNoiseLite.DISTANCE_MANHATTAN
			tex.bump_strength = 6.5
		"polymer_grip":
			fn.noise_type = FastNoiseLite.TYPE_VALUE
			fn.frequency = 0.24
			tex.bump_strength = 9.0
		_:
			fn.noise_type = FastNoiseLite.TYPE_PERLIN
			fn.frequency = 0.055
			tex.bump_strength = 6.0

	tex.noise = fn
	_noise_tex_cache[kind] = tex
	return tex

static func _make_pbr_mat(cache_key: String, col: Color, metal: float, rough: float, normal_kind: String, triplanar: bool = true, uv_scale: float = 0.22) -> StandardMaterial3D:
	if _pbr_mat_cache.has(cache_key):
		return _pbr_mat_cache[cache_key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = rough
	m.normal_enabled = true
	m.normal_scale = 0.28
	m.normal_texture = get_procedural_normal_tex(normal_kind)
	if triplanar:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	else:
		m.uv1_scale = Vector3(uv_scale * 12.0, uv_scale * 12.0, uv_scale * 12.0)
	_pbr_mat_cache[cache_key] = m
	return m

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

## Builds an authentic Apex Supply Bin with StaticBody3D physics collision & LidPivot
static func create_supply_bin_node(bin_type: String = "normal") -> Node3D:
	var root := StaticBody3D.new()
	root.name = "ApexSupplyBin"
	root.collision_layer = 1
	root.collision_mask = 0

	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(2.76, 1.08, 1.46)
	col.shape = bshape
	col.position = Vector3(0, 0.54, 0)
	root.add_child(col)

	var lid_col := Color("#cbd5e1")
	var led_col := Color("#2dd4bf")
	if bin_type == "assault":
		lid_col = Color("#dc2626")
		led_col = Color("#ff2a4b")
	elif bin_type == "support":
		lid_col = Color("#0284c7")
		led_col = Color("#38bdf8")

	var mat_base := _make_pbr_mat("bin_base", Color("#1e293b"), 0.80, 0.32, "metal_plate", false, 0.35)
	var mat_rib := _make_pbr_mat("bin_rib", Color("#0f172a"), 0.86, 0.26, "gunmetal", false, 0.40)
	var mat_hazard := _make_mat(Color("#f59e0b"), 0.45, 0.40)
	var mat_lid := _make_pbr_mat("bin_lid_" + bin_type, lid_col, 0.72, 0.28, "gunmetal", false, 0.35)
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
	_add_box(root, Vector3(2.54, 0.06, 1.26), Vector3(0, 0.68, 0), mat_rib, Vector3.ZERO, "InteriorTray")

	# 2. Articulated Clam-Shell Upper Lid
	var lid_pivot := Node3D.new()
	lid_pivot.name = "LidPivot"
	lid_pivot.position = Vector3(0, 0.72, -0.68)
	root.add_child(lid_pivot)

	_add_box(lid_pivot, Vector3(2.74, 0.42, 1.42), Vector3(0, 0.21, 0.68), mat_lid, Vector3.ZERO, "LidMain")
	_add_box(lid_pivot, Vector3(2.56, 0.18, 1.12), Vector3(0, 0.46, 0.68), mat_base, Vector3.ZERO, "LidTopArch")
	for p in [-1, 0, 1]:
		_add_box(lid_pivot, Vector3(0.68, 0.10, 0.92), Vector3(float(p) * 0.82, 0.52, 0.68), mat_lid)
	_add_box(lid_pivot, Vector3(0.38, 0.18, 0.08), Vector3(0, 0.12, 1.40), mat_led, Vector3.ZERO, "FrontLatch")

	return root

## Builds an authentic 3-Legged Apex Pack / Loot Tick Robot
static func create_loot_tick_node(tier_rarity: int = 4) -> Node3D:
	var root := StaticBody3D.new()
	root.name = "ApexLootTick"
	root.collision_layer = 1
	root.collision_mask = 0

	var col := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.radius = 0.55
	cshape.height = 1.05
	col.shape = cshape
	col.position = Vector3(0, 0.525, 0)
	root.add_child(col)

	var glow_col := Color("#f59e0b") if tier_rarity == 4 else (Color("#ff1e42") if tier_rarity >= 5 else Color("#a855f7"))
	var mat_shell := _make_pbr_mat("tick_shell", Color("#f8fafc"), 0.68, 0.24, "gunmetal", false, 0.4)
	var mat_red := _make_mat(Color("#dc2626"), 0.70, 0.28)
	var mat_dark := _make_pbr_mat("tick_dark", Color("#1e293b"), 0.82, 0.30, "carbon_weave", false, 0.5)
	var mat_joint := _make_mat(Color("#f59e0b"), 0.75, 0.30)
	var mat_glow := _make_mat(glow_col, 0.2, 0.1, true, 3.8)

	var body_pivot := Node3D.new()
	body_pivot.name = "TickBody"
	body_pivot.position = Vector3(0, 0.58, 0)
	root.add_child(body_pivot)

	_add_cyl(body_pivot, 0.18, 0.46, 0.56, Vector3(0, 0.06, 0), mat_shell, Vector3.ZERO, 3, "PyramidCore")
	_add_cyl(body_pivot, 0.22, 0.48, 0.22, Vector3(0, -0.08, 0), mat_red, Vector3.ZERO, 3, "RedArmorBand")
	_add_cyl(body_pivot, 0.14, 0.14, 0.08, Vector3(0, 0.36, 0), mat_dark, Vector3.ZERO, 6, "TopCap")

	_add_cyl(body_pivot, 0.12, 0.12, 0.10, Vector3(0, 0.04, 0.24), mat_dark, Vector3(PI * 0.5, 0, 0), 12)
	_add_cyl(body_pivot, 0.085, 0.085, 0.12, Vector3(0, 0.04, 0.25), mat_glow, Vector3(PI * 0.5, 0, 0), 12, "GlowingEye")

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

## Builds an Industrial Sci-Fi Cargo Crate / Climbable Cover Box with PBR Metal Normal Map
static func create_cargo_crate_node(w: float = 2.2, h: float = 1.6, d: float = 1.8, accent_col: Color = Color("#f59e0b")) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(w, h, d)
	col.shape = shape
	col.position = Vector3(0, h * 0.5, 0)
	body.add_child(col)

	var mat_main := _make_pbr_mat("crate_main", Color("#273449"), 0.68, 0.38, "metal_plate", true, 0.35)
	var mat_frame := _make_pbr_mat("crate_frame", Color("#0f172a"), 0.85, 0.26, "gunmetal", true, 0.40)
	var mat_acc := _make_mat(accent_col, 0.4, 0.2, true, 2.2)

	_add_box(body, Vector3(w, h, d), Vector3(0, h * 0.5, 0), mat_main)
	_add_box(body, Vector3(w + 0.06, 0.14, d + 0.06), Vector3(0, h - 0.08, 0), mat_frame)
	_add_box(body, Vector3(w + 0.06, 0.14, d + 0.06), Vector3(0, 0.08, 0), mat_frame)
	_add_box(body, Vector3(w + 0.08, 0.08, d * 0.65), Vector3(0, h * 0.52, 0), mat_acc)

	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_box(body, Vector3(0.16, h + 0.04, 0.16), Vector3(sx * (w * 0.5), h * 0.5, sz * (d * 0.5)), mat_frame)

	return body

## Builds an Interactive Jump Tower / Redeploy Balloon
static func create_jump_tower_node() -> StaticBody3D:
	var tower := StaticBody3D.new()
	tower.name = "ApexJumpTower"
	tower.collision_layer = 1
	tower.collision_mask = 0

	var col := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.radius = 0.65
	cshape.height = 28.0
	col.shape = cshape
	col.position = Vector3(0, 14.0, 0)
	tower.add_child(col)

	var mat_pole := _make_pbr_mat("tower_pole", Color("#334155"), 0.84, 0.28, "gunmetal", true, 0.30)
	var mat_balloon := _make_mat(Color("#dc2626"), 0.25, 0.45, true, 1.6)
	var mat_cable := _make_mat(Color("#facc15"), 0.85, 0.20, true, 2.2)

	_add_cyl(tower, 0.45, 0.85, 2.2, Vector3(0, 1.1, 0), mat_pole, Vector3.ZERO, 8)
	_add_cyl(tower, 0.22, 0.28, 28.0, Vector3(0, 14.0, 0), mat_pole, Vector3.ZERO, 10)
	_add_cyl(tower, 0.035, 0.035, 27.0, Vector3(0, 13.5, 0.45), mat_cable, Vector3.ZERO, 8)
	_add_cyl(tower, 3.2, 1.8, 5.5, Vector3(0, 30.5, 0), mat_balloon, Vector3.ZERO, 14, "RedeployBalloon")

	var lbl := Label3D.new()
	lbl.text = "[E] 搭乘跳伞塔高空重部署"
	lbl.font_size = 24
	lbl.pixel_size = 0.0045
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color("#facc15")
	lbl.position = Vector3(0, 2.4, 0.6)
	tower.add_child(lbl)

	return tower

static func build_canyon_world(parent: Node3D) -> Dictionary:
	var interactables: Array = []

	# Terrain Floor + StaticBody3D with Procedural Triplanar Normal & Roughness Map
	var floor_body := StaticBody3D.new()
	floor_body.name = "CanyonTerrain"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
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
	var mat_ground := _make_pbr_mat("canyon_terrain_floor", Color("#1e293b"), 0.18, 0.82, "sandstone", true, 0.08)
	floor_mesh.material_override = mat_ground
	floor_body.add_child(floor_mesh)
	parent.add_child(floor_body)

	# Firing Range Concrete Tactical Deck Pad
	var pad_mat := _make_pbr_mat("firing_range_pad", Color("#263246"), 0.55, 0.42, "metal_plate", true, 0.24)
	_add_box(floor_body, Vector3(68.0, 0.08, 46.0), Vector3(0, 0.04, -14.0), pad_mat, Vector3.ZERO, "FiringRangeDeck")

	var mat_wall := _make_pbr_mat("imc_wall", Color("#334155"), 0.35, 0.54, "concrete", true, 0.18)
	var mat_roof := _make_pbr_mat("imc_roof", Color("#1e293b"), 0.72, 0.34, "metal_plate", true, 0.25)
	var mat_rock := _make_pbr_mat("canyon_sandstone_cliff", Color("#523a28"), 0.12, 0.86, "sandstone", true, 0.06)
	var mat_rock_top := _make_pbr_mat("canyon_sandstone_top", Color("#6b4c35"), 0.10, 0.88, "sandstone", true, 0.08)

	# 1. Spawn Firing Range 28-Weapon Armory Racks (2 rows of 14 stands)
	var rack_mat := _make_pbr_mat("armory_rack", Color("#0f172a"), 0.82, 0.26, "gunmetal", false, 0.4)
	var cols_per_row: int = 14
	for i in range(GameData.WEAPONS.size()):
		var w: Dictionary = GameData.WEAPONS[i]
		var rx: float = (float(i % cols_per_row) - 6.5) * 2.85
		@warning_ignore("integer_division")
		var rz: float = -10.5 - float(i / cols_per_row) * 4.6
		var stand := StaticBody3D.new()
		stand.collision_layer = 1
		stand.collision_mask = 0
		var st_col := CollisionShape3D.new()
		var st_shape := BoxShape3D.new()
		st_shape.size = Vector3(2.1, 1.05, 0.88)
		st_col.shape = st_shape
		st_col.position = Vector3(0, 0.525, 0)
		stand.add_child(st_col)
		_add_box(stand, Vector3(2.1, 1.05, 0.88), Vector3(0, 0.525, 0), rack_mat)
		_add_box(stand, Vector3(2.16, 0.06, 0.92), Vector3(0, 1.04, 0), _make_mat(w.get("accent", Color("#38bdf8")), 0.3, 0.2, true, 1.8))
		stand.position = Vector3(rx, 0.0, rz)
		parent.add_child(stand)

		var gun_preview := WeaponMeshBuilder.create_viewmodel(w, false, {}, "2x_bruiser")
		gun_preview.position = Vector3(0, 1.34, 0)
		gun_preview.rotation = Vector3(0, PI * 0.5, 0)
		gun_preview.scale = Vector3(1.12, 1.12, 1.12)
		var l_arm := gun_preview.get_node_or_null("GunRig/LeftArmPivot")
		var r_arm := gun_preview.get_node_or_null("GunRig/RightArmPivot")
		if l_arm:
			l_arm.visible = false
		if r_arm:
			r_arm.visible = false
		stand.add_child(gun_preview)

		var lbl := Label3D.new()
		lbl.name = "ItemLabel3D"
		lbl.text = "[E] [%s] %s" % [str(w["cat"]), str(w["name"])]
		lbl.font_size = 20
		lbl.pixel_size = 0.0036
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = false
		lbl.modulate = w.get("accent", Color("#f97316"))
		lbl.position = Vector3(0, 1.78, 0)
		lbl.visible = false
		stand.add_child(lbl)

		interactables.append({
			"type": "weapon_rack",
			"weapon_id": str(w["id"]),
			"name": "装备 【%s】" % str(w["name"]),
			"pos": stand.position + Vector3(0, 0.8, 0),
			"node": stand
		})

	# 1B. Build Dedicated Firing Range Wall-Climb & Ledge-Mantle Training Course (East of Racks)
	_build_climb_parkour_course(parent, Vector3(25.5, 0.0, -14.0), mat_wall, mat_roof)

	# Spawn 3 High-Detail Supply Bins & 2 Loot Ticks right beside spawn
	var spawn_bin_types := ["normal", "assault", "support"]
	for sb in range(3):
		var btype: String = spawn_bin_types[sb]
		var bin_node := create_supply_bin_node(btype)
		bin_node.position = Vector3(-11.5 + float(sb) * 4.4, 0.0, -4.5)
		parent.add_child(bin_node)
		var bname: String = "红色突击武器补给仓" if btype == "assault" else ("蓝色支援医疗补给仓" if btype == "support" else "外域标准补给仓")
		interactables.append({
			"type": "supply_bin",
			"bin_type": btype,
			"name": "开启 %s (生成可拾取3D枪械/电池/医疗品)" % bname,
			"pos": bin_node.position,
			"node": bin_node,
			"opened": false
		})

	for tk in range(2):
		var rarity: int = 4 if tk == 0 else 5
		var tick_node := create_loot_tick_node(rarity)
		tick_node.position = Vector3(8.5 + float(tk) * 3.4, 0.0, -4.8)
		tick_node.rotation.y = -0.45
		parent.add_child(tick_node)
		interactables.append({
			"type": "loot_tick",
			"rarity": rarity,
			"name": "开启 %s 战利品机器人 (爆出满配金枪/传家宝红武!)" % ("传说金色" if rarity == 4 else "神话红色"),
			"pos": tick_node.position,
			"node": tick_node,
			"opened": false
		})

	for cv in range(3):
		var crate := create_cargo_crate_node(2.6, 1.45, 1.6, Color("#38bdf8"))
		crate.position = Vector3(-9.0 + float(cv) * 9.0, 0.0, -20.5)
		parent.add_child(crate)

	var fr_tower := create_jump_tower_node()
	fr_tower.position = Vector3(-24.0, 0.0, -14.0)
	parent.add_child(fr_tower)
	interactables.append({
		"type": "jump_tower",
		"name": "搭乘 跳伞塔高空滑索重部署 (飞向全图任意落点)",
		"pos": fr_tower.position + Vector3(0, 1.5, 0),
		"node": fr_tower
	})

	# 2. Build 12 Named POIs with Multi-Story Climbable Buildings, Supply Bins, Loot Ticks, Jump Towers, Beacons & Crafters
	var poi_idx: int = 0
	for poi in GameData.MAP_POIS:
		var p2: Vector2 = poi["pos"]
		var center := Vector3(p2.x, 0.0, p2.y)
		var b_count: int = int(poi["buildings"])
		var col_accent: Color = poi["color"]
		var mat_accent := _make_mat(col_accent, 0.5, 0.2, true, 2.2)

		for b in range(b_count):
			var ang: float = float(b) * (TAU / float(b_count))
			var b_pos: Vector3 = center + Vector3(cos(ang) * 19.5, 0.0, sin(ang) * 19.5)
			var bw: float = 11.6
			var bh: float = 5.2
			var bd: float = 9.6
			_build_poi_building(parent, b_pos, Vector3(bw, bh, bd), mat_wall, mat_roof, mat_accent)

		for cb in range(2):
			var c_ang: float = float(cb) * PI + 0.4
			var crate_poi := create_cargo_crate_node(2.4, 1.6, 2.0, col_accent)
			crate_poi.position = center + Vector3(cos(c_ang) * 9.5, 0.0, sin(c_ang) * 9.5)
			crate_poi.rotation.y = c_ang
			parent.add_child(crate_poi)

		var poi_bin_types := ["normal", "assault", "support"]
		for pb in range(3):
			var pb_ang: float = float(pb) * (TAU / 3.0) + 0.35
			var pb_type: String = poi_bin_types[(poi_idx + pb) % 3]
			var pb_node := create_supply_bin_node(pb_type)
			pb_node.position = center + Vector3(cos(pb_ang) * 6.5, 0.0, sin(pb_ang) * 6.5)
			pb_node.rotation.y = -pb_ang + PI * 0.5
			parent.add_child(pb_node)
			var pb_title: String = "红色突击补给仓" if pb_type == "assault" else ("蓝色支援补给仓" if pb_type == "support" else "标准物资补给仓")
			interactables.append({
				"type": "supply_bin",
				"bin_type": pb_type,
				"name": "%s · %s" % [str(poi["name"]), pb_title],
				"pos": pb_node.position,
				"node": pb_node,
				"opened": false
			})

		var tick_rarity: int = 5 if (poi_idx % 3 == 0) else 4
		var poi_tick := create_loot_tick_node(tick_rarity)
		poi_tick.position = center + Vector3(2.8, 0.0, -2.8)
		parent.add_child(poi_tick)
		interactables.append({
			"type": "loot_tick",
			"rarity": tick_rarity,
			"name": "%s · %s战利品机器人" % [str(poi["name"]), "神话红光" if tick_rarity == 5 else "传说金光"],
			"pos": poi_tick.position,
			"node": poi_tick,
			"opened": false
		})

		if poi_idx % 2 == 0:
			var j_tower := create_jump_tower_node()
			j_tower.position = center + Vector3(-11.0, 0.0, 11.0)
			parent.add_child(j_tower)
			interactables.append({
				"type": "jump_tower",
				"name": "%s · 跳伞塔高空重部署" % str(poi["name"]),
				"pos": j_tower.position + Vector3(0, 1.5, 0),
				"node": j_tower
			})

		if bool(poi["beacon"]):
			var beacon_body := StaticBody3D.new()
			beacon_body.collision_layer = 1
			beacon_body.collision_mask = 0
			var bcol := CollisionShape3D.new()
			var bcyl := CylinderShape3D.new()
			bcyl.radius = 0.55
			bcyl.height = 3.2
			bcol.shape = bcyl
			bcol.position = Vector3(0, 1.6, 0)
			beacon_body.add_child(bcol)
			_add_cyl(beacon_body, 0.35, 0.55, 3.2, Vector3(0, 1.6, 0), _make_mat(Color("#38bdf8"), 0.8, 0.2, true, 2.5))
			beacon_body.position = center + Vector3(4.0, 0.0, 4.0)
			parent.add_child(beacon_body)
			interactables.append({
				"type": "beacon",
				"name": "扫描调查信标 / 毒圈控制台 (%s)" % str(poi["name"]),
				"pos": beacon_body.position,
				"node": beacon_body
			})

		if bool(poi["crafter"]):
			var crafter_body := StaticBody3D.new()
			crafter_body.collision_layer = 1
			crafter_body.collision_mask = 0
			var ccol := CollisionShape3D.new()
			var ccyl := CylinderShape3D.new()
			ccyl.radius = 1.45
			ccyl.height = 2.8
			ccol.shape = ccyl
			ccol.position = Vector3(0, 1.4, 0)
			crafter_body.add_child(ccol)
			_add_cyl(crafter_body, 1.3, 1.5, 2.8, Vector3(0, 1.4, 0), _make_mat(Color("#f97316"), 0.7, 0.2, true, 2.2), Vector3.ZERO, 6)
			crafter_body.position = center + Vector3(-4.2, 0.0, -3.5)
			parent.add_child(crafter_body)
			interactables.append({
				"type": "crafter",
				"name": "使用复制器制造台 (%s)" % str(poi["name"]),
				"pos": crafter_body.position,
				"node": crafter_body
			})

		var banner := Label3D.new()
		banner.text = "📍 " + str(poi["name"])
		banner.font_size = 44
		banner.pixel_size = 0.015
		banner.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		banner.modulate = col_accent
		banner.position = center + Vector3(0, 12.5, 0)
		parent.add_child(banner)
		poi_idx += 1

	# 3. Sculpted Multi-Tiered Kings Canyon Sandstone Rock Cliffs & Strata Formations
	for r in range(36):
		var ang: float = float(r) * 0.62
		var dist: float = 55.0 + float((r * 29) % 210)
		var rpos := Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		if rpos.length() < 36.0:
			continue
		var rh: float = 7.0 + float(r % 5) * 3.8
		var rw: float = 5.0 + float(r % 4) * 1.8

		var rock_body := StaticBody3D.new()
		rock_body.collision_layer = 1
		rock_body.collision_mask = 0
		var rcol := CollisionShape3D.new()
		var rcyl := CylinderShape3D.new()
		rcyl.radius = rw * 0.92
		rcyl.height = rh
		rcol.shape = rcyl
		rcol.position = Vector3(0, rh * 0.5, 0)
		rock_body.add_child(rcol)

		# Tier 1: Wide weathered sandstone base
		_add_cyl(rock_body, rw * 0.85, rw * 1.15, rh * 0.52, Vector3(0, rh * 0.26, 0), mat_rock, Vector3.ZERO, 7)
		# Tier 2: Offset middle strata shelf (creates natural climbable rock ledges!)
		_add_cyl(rock_body, rw * 0.68, rw * 0.88, rh * 0.45, Vector3(rw * 0.12, rh * 0.62, -rw * 0.08), mat_rock, Vector3(0.04, 0.5, -0.03), 7)
		# Tier 3: Flat mesa cap rock
		_add_cyl(rock_body, rw * 0.55, rw * 0.65, rh * 0.22, Vector3(-rw * 0.06, rh * 0.89, rw * 0.05), mat_rock_top, Vector3.ZERO, 6)

		# Add a climbable lower boulder step beside every 2nd cliff so players can scale up the canyon rocks
		if r % 2 == 0:
			var step_h: float = 3.2
			var step_col := CollisionShape3D.new()
			var step_shape := BoxShape3D.new()
			step_shape.size = Vector3(3.4, step_h, 3.0)
			step_col.shape = step_shape
			step_col.position = Vector3(rw * 0.95, step_h * 0.5, 0)
			rock_body.add_child(step_col)
			_add_box(rock_body, Vector3(3.4, step_h, 3.0), Vector3(rw * 0.95, step_h * 0.5, 0), mat_rock_top, Vector3(0, 0.25, 0))

		rock_body.position = rpos
		parent.add_child(rock_body)

	# 4. Giant Glowing Orange Boundary Ring Cylinder with ShaderMaterial (`ring_energy_wall.gdshader`)
	var ring_mesh := MeshInstance3D.new()
	ring_mesh.name = "CanyonRingBoundaryWall"
	var rcyl_mesh := CylinderMesh.new()
	rcyl_mesh.top_radius = 1.0
	rcyl_mesh.bottom_radius = 1.0
	rcyl_mesh.height = 90.0
	rcyl_mesh.radial_segments = 64
	rcyl_mesh.cap_top = false
	rcyl_mesh.cap_bottom = false
	ring_mesh.mesh = rcyl_mesh

	var ring_shader: Shader = load("res://shaders/ring_energy_wall.gdshader")
	if ring_shader != null:
		var smat := ShaderMaterial.new()
		smat.shader = ring_shader
		smat.set_shader_parameter("ring_color", Color(1.0, 0.36, 0.04, 0.32))
		ring_mesh.material_override = smat
	else:
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = Color(1.0, 0.38, 0.05, 0.24)
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		rmat.emission_enabled = true
		rmat.emission = Color("#ff5500")
		rmat.emission_energy_multiplier = 2.4
		ring_mesh.material_override = rmat

	ring_mesh.position = Vector3(0, 45.0, 0)
	ring_mesh.scale = Vector3(PlayerState.ring_radius, 1.0, PlayerState.ring_radius)
	parent.add_child(ring_mesh)

	return {
		"interactables": interactables,
		"ring_mesh": ring_mesh
	}


static func _build_climb_parkour_course(parent: Node3D, origin: Vector3, mat_wall: Material, mat_roof: Material) -> void:
	## Dedicated Firing Range Wall-Climb & Ledge-Mantle Training Structure:
	## Features a 3.2m Low Ledge, 4.8m Medium Climb Wall, and 6.2m High Apex Climb Tower with glowing climb chevrons!
	var course := StaticBody3D.new()
	course.name = "WallClimbTrainingTower"
	course.collision_layer = 1
	course.collision_mask = 0
	course.position = origin
	parent.add_child(course)

	var mat_chevron := _make_mat(Color("#f59e0b"), 0.3, 0.2, true, 2.8)
	var mat_cyan := _make_mat(Color("#38bdf8"), 0.3, 0.2, true, 3.0)

	# 1. Stage 1 Ledge (Height = 3.0m)
	_add_static_box_part(course, Vector3(4.6, 3.0, 4.2), Vector3(-5.2, 1.5, 0.0), mat_wall)
	_add_box(course, Vector3(4.7, 0.14, 4.3), Vector3(-5.2, 3.02, 0.0), mat_roof)
	_add_box(course, Vector3(2.4, 0.12, 0.08), Vector3(-5.2, 2.85, 2.14), mat_cyan)

	# 2. Stage 2 Wall-Climb Platform (Height = 4.8m — standard single climb & mantle)
	_add_static_box_part(course, Vector3(5.2, 4.8, 4.8), Vector3(0.0, 2.4, 0.0), mat_wall)
	_add_box(course, Vector3(5.3, 0.16, 4.9), Vector3(0.0, 4.82, 0.0), mat_roof)
	for ch in range(4):
		_add_box(course, Vector3(1.8, 0.10, 0.08), Vector3(0.0, 1.2 + float(ch) * 1.0, 2.44), mat_chevron)

	# 3. Stage 3 High Tower (Height = 6.2m — full Apex climb height / wall-bounce wall)
	_add_static_box_part(course, Vector3(5.2, 6.2, 5.2), Vector3(5.6, 3.1, 0.0), mat_wall)
	_add_box(course, Vector3(5.3, 0.16, 5.3), Vector3(5.6, 6.22, 0.0), mat_roof)
	for ch2 in range(5):
		_add_box(course, Vector3(1.8, 0.10, 0.08), Vector3(5.6, 1.2 + float(ch2) * 1.05, 2.64), mat_cyan)

	var sign_lbl := Label3D.new()
	sign_lbl.text = "🧗 爬墙与翻越训练台 (贴墙按住 W 向上攀爬 / 登顶自动双手撑地翻越 / 爬墙中松W按空格蹬墙跳)"
	sign_lbl.font_size = 24
	sign_lbl.pixel_size = 0.0042
	sign_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_lbl.modulate = Color("#38bdf8")
	sign_lbl.position = Vector3(0.0, 7.3, 1.5)
	course.add_child(sign_lbl)


static func _build_poi_building(parent: Node3D, b_pos: Vector3, sz: Vector3, mat_wall: Material, mat_roof: Material, mat_accent: Material) -> void:
	## Builds a Multi-Story Enterable 2-Floor Apex Legends IMC Building:
	## - Flush ground floor diamond-plate deck (`y = 0.04`)
	## - Interior 2nd-floor Mezzanine Balcony (`y = 2.55`) with indoor staircase
	## - Side wall tactical windows (`East` & `West`) + Front/Back walk-in doorways
	## - Rooftop Skylight Opening (`y = 5.2m`), Parapet Cover Walls, Exterior Stair Ramp,
	##   and Climbable Wall-Side HVAC / Cargo Units so players & bots can climb onto the roof from any side!
	var b_root := StaticBody3D.new()
	b_root.name = "EnterableBuilding"
	b_root.collision_layer = 1
	b_root.collision_mask = 0
	b_root.position = b_pos
	parent.add_child(b_root)

	var bw: float = sz.x
	var bh: float = sz.y
	var bd: float = sz.z
	var wt: float = 0.36
	var door_w: float = 3.2
	var door_h: float = 3.1
	var side_w: float = (bw - door_w) * 0.5

	var mat_floor := _make_pbr_mat("bldg_metal_floor", Color("#1e293b"), 0.78, 0.34, "metal_plate", true, 0.28)
	var mat_pipe := _make_pbr_mat("bldg_pipe", Color("#475569"), 0.88, 0.22, "gunmetal", false, 0.4)
	var mat_light := _make_mat(Color("#e0f2fe"), 0.1, 0.1, true, 3.2)

	# 1. Ground Floor Diamond-Plate Deck (Flush at y = 0.04)
	_add_static_box_part(b_root, Vector3(bw, 0.08, bd), Vector3(0, 0.04, 0), mat_floor)

	# 2. Interior 2nd-Floor Mezzanine Platform (Back half of building at y = 2.55m) + Indoor Staircase
	var mezz_d: float = bd * 0.44
	var mezz_z: float = -bd * 0.5 + mezz_d * 0.5 + wt
	_add_static_box_part(b_root, Vector3(bw - wt * 2.0, 0.22, mezz_d), Vector3(0, 2.55, mezz_z), mat_floor)
	# Mezzanine safety railing with center gap for indoor stairs
	_add_static_box_part(b_root, Vector3(bw * 0.32, 0.85, 0.16), Vector3(-bw * 0.28, 3.05, mezz_z + mezz_d * 0.5), mat_roof)
	_add_static_box_part(b_root, Vector3(bw * 0.32, 0.85, 0.16), Vector3(bw * 0.28, 3.05, mezz_z + mezz_d * 0.5), mat_roof)
	# Indoor Staircase connecting Ground Floor to 2nd-Floor Mezzanine
	_add_static_box_part(b_root, Vector3(1.95, 0.24, 4.4), Vector3(-bw * 0.22, 1.28, mezz_z + mezz_d * 0.5 + 1.65), mat_floor, Vector3(0.54, 0, 0))

	# 3. Roof Ceiling Slab with Walk-Through Rooftop Skylight Access (so 2nd-floor or climbers can drop in/out)
	var roof_side_w: float = (bw - 2.8) * 0.5
	_add_static_box_part(b_root, Vector3(roof_side_w, 0.32, bd + 0.3), Vector3(-(bw * 0.5 - roof_side_w * 0.5), bh, 0), mat_roof)
	_add_static_box_part(b_root, Vector3(roof_side_w, 0.32, bd + 0.3), Vector3((bw * 0.5 - roof_side_w * 0.5), bh, 0), mat_roof)
	_add_static_box_part(b_root, Vector3(2.8, 0.32, (bd - 2.6) * 0.5), Vector3(0, bh, -bd * 0.36), mat_roof)
	_add_static_box_part(b_root, Vector3(2.8, 0.32, (bd - 2.6) * 0.5), Vector3(0, bh, bd * 0.36), mat_roof)

	# 4. Front Wall (+Z) & Back Wall (-Z) with Open Walk-In Doorways
	for z_sign in [-1.0, 1.0]:
		var wz: float = z_sign * (bd * 0.5 - wt * 0.5)
		_add_static_box_part(b_root, Vector3(side_w, bh, wt), Vector3(-(bw * 0.5 - side_w * 0.5), bh * 0.5, wz), mat_wall)
		_add_static_box_part(b_root, Vector3(side_w, bh, wt), Vector3((bw * 0.5 - side_w * 0.5), bh * 0.5, wz), mat_wall)
		var lintel_h: float = bh - door_h
		_add_static_box_part(b_root, Vector3(door_w, lintel_h, wt), Vector3(0, door_h + lintel_h * 0.5, wz), mat_wall)
		# Glowing Doorway Frame Trim
		_add_box(b_root, Vector3(door_w + 0.24, 0.14, wt + 0.08), Vector3(0, door_h + 0.05, wz), mat_accent)
		_add_box(b_root, Vector3(0.14, door_h, wt + 0.08), Vector3(-door_w * 0.5 - 0.06, door_h * 0.5, wz), mat_accent)
		_add_box(b_root, Vector3(0.14, door_h, wt + 0.08), Vector3(door_w * 0.5 + 0.06, door_h * 0.5, wz), mat_accent)

	# 5. Left Wall (-X) & Right Wall (+X) with Tactical Sightline Windows
	var win_w: float = 2.8
	var win_h: float = 1.35
	var win_y: float = 1.85
	var wall_seg_d: float = (bd - wt * 2.0 - win_w) * 0.5
	for x_sign in [-1.0, 1.0]:
		var wx: float = x_sign * (bw * 0.5 - wt * 0.5)
		_add_static_box_part(b_root, Vector3(wt, bh, wall_seg_d), Vector3(wx, bh * 0.5, -(win_w * 0.5 + wall_seg_d * 0.5)), mat_wall)
		_add_static_box_part(b_root, Vector3(wt, bh, wall_seg_d), Vector3(wx, bh * 0.5, (win_w * 0.5 + wall_seg_d * 0.5)), mat_wall)
		# Below window & above window
		_add_static_box_part(b_root, Vector3(wt, win_y - win_h * 0.5, win_w), Vector3(wx, (win_y - win_h * 0.5) * 0.5, 0), mat_wall)
		var top_h: float = bh - (win_y + win_h * 0.5)
		_add_static_box_part(b_root, Vector3(wt, top_h, win_w), Vector3(wx, bh - top_h * 0.5, 0), mat_wall)
		# Window Sill Trim
		_add_box(b_root, Vector3(wt + 0.10, 0.10, win_w + 0.16), Vector3(wx, win_y - win_h * 0.5, 0), mat_roof)

	# 6. Interior Ceiling Lighting Fixtures & Industrial Pipe Conduits
	_add_box(b_root, Vector3(3.6, 0.08, 0.35), Vector3(0, bh - 0.22, 1.8), mat_light)
	_add_cyl(b_root, 0.11, 0.11, bw - 0.8, Vector3(0, bh - 0.35, -1.2), mat_pipe, Vector3(0, 0, PI * 0.5), 10)

	# 7. Rooftop Tactical Parapet Cover & Neon Trim
	_add_box(b_root, Vector3(bw + 0.4, 0.18, bd + 0.4), Vector3(0, bh + 0.12, 0), mat_accent)
	_add_static_box_part(b_root, Vector3(bw * 0.65, 1.15, 0.35), Vector3(0, bh + 0.65, bd * 0.5 - 0.2), mat_wall)
	_add_static_box_part(b_root, Vector3(bw * 0.65, 1.15, 0.35), Vector3(0, bh + 0.65, -bd * 0.5 + 0.2), mat_wall)

	# 8. Walkable Exterior Roof Access Ramp (+X side) AND Climbable HVAC Box (-X side) for Wall-Climb & Mantle!
	var ramp_len: float = sqrt(bd * bd + bh * bh)
	var ramp_pitch: float = atan2(bh, bd)
	_add_static_box_part(b_root, Vector3(2.2, 0.30, ramp_len), Vector3(bw * 0.5 + 1.2, bh * 0.5, 0.0), mat_roof, Vector3(ramp_pitch, 0, 0))
	# Exterior HVAC Climb Box on -X wall (y = 2.4m step + climbable wall face with chevron stripes)
	_add_static_box_part(b_root, Vector3(1.8, 2.4, 2.6), Vector3(-bw * 0.5 - 0.95, 1.2, -1.8), mat_roof)
	_add_box(b_root, Vector3(0.08, 0.14, 2.2), Vector3(-bw * 0.5 - 0.04, 3.8, -1.8), mat_accent)


static func _add_static_box_part(body: StaticBody3D, sz: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = sz
	col.shape = shape
	col.position = pos
	col.rotation = rot
	body.add_child(col)
	_add_box(body, sz, pos, mat, rot)
