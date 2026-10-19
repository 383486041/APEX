class_name WeaponMeshBuilder
extends RefCounted

static var _quaternius_obj_cache: Dictionary = {}
static var _kenney_glb_cache: Dictionary = {}
static var _ual_gltf_root: Node3D = null
## High-Detail Procedural 3D First-Person & Third-Person Weapon, Bocek Compound Bow, Consumable Prop & Mythic Heirloom Builder for Godot 4.3.
## Upgrades:
## - Sculpted Multi-Surface Weapon Receivers (Chamfered Cheek Plates, Rear Buffer Cap, Tritium Rear Peep Sights, Front Sight Hoods, Angled Magwells, Vent Louvers)
## - Integrated Rear-Facing Digital Ammo Counter LCD (`AmmoScreenHousing` + `AmmoLabel3D`) facing the player's eye on ALL firearms (fixes sideways floating numbers!)
## - Anatomical First-Person Tactical Arms & Gloved Hands (`CapsuleMesh` forearms, wrist holo-watch, sculpted palm, and 5 articulated fingers wrapped around grip/forend)
## - Authentic Center-Screen 3D Consumable Props (`BatteryProp` with glowing OmniLight3D + twisting capacitor core, `MedProp` pneumatic auto-injector)
## - Third-Person 3D Weapon Builder (`create_third_person_weapon_mesh`) for 3rd-person player & AI bots (two-handed aim + back holster when healing)

static func _make_mat(col: Color, metal: float = 0.68, rough: float = 0.30, emit: bool = false, emit_energy: float = 1.8, pbr_kind: String = "") -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = rough
	if emit:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit_energy
	else:
		var kind: String = pbr_kind
		if kind == "":
			if rough >= 0.58:
				kind = "polymer_grip"
			elif metal >= 0.72:
				kind = "gunmetal"
			else:
				kind = "carbon_weave"
		m.normal_enabled = true
		m.normal_scale = 0.14 if kind == "gunmetal" else (0.22 if kind == "polymer_grip" else 0.18)
		m.normal_texture = CanyonWorldBuilder.get_procedural_normal_tex(kind)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(16.0, 16.0, 16.0)
		if metal >= 0.72:
			m.rim_enabled = true
			m.rim = 0.22
			m.rim_tint = 0.35
	return m

static func _add_box(parent: Node3D, sz: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, node_name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if node_name != "":
		mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, sides: int = 12, node_name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if node_name != "":
		mi.name = node_name
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = sides
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _add_capsule(parent: Node3D, rad: float, h: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, node_name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if node_name != "":
		mi.name = node_name
	var cap := CapsuleMesh.new()
	cap.radius = rad
	cap.height = maxf(rad * 2.02, h)
	cap.radial_segments = 14
	cap.rings = 6
	mi.mesh = cap
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _add_sphere(parent: Node3D, rad: float, pos: Vector3, mat: Material, node_name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if node_name != "":
		mi.name = node_name
	var sm := SphereMesh.new()
	sm.radius = rad
	sm.height = rad * 2.0
	sm.radial_segments = 14
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_ring(parent: Node3D, r_inner: float, r_outer: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3(PI * 0.5, 0, 0), sides: int = 24, node_name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if node_name != "":
		mi.name = node_name
	var tm := TorusMesh.new()
	tm.inner_radius = r_inner
	tm.outer_radius = r_outer
	tm.rings = sides
	tm.ring_segments = 12
	mi.mesh = tm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _build_fp_consumable_props(gun_rig: Node3D) -> void:
	## Builds 3D First-Person Shield Battery/Cell/Phoenix & Syringe/MedKit props under GunRig/ConsumablePivot.
	## When healing, all firearm nodes hide and ConsumablePivot moves into center view held by both hands!
	var cons_pivot := Node3D.new()
	cons_pivot.name = "ConsumablePivot"
	cons_pivot.position = Vector3(-0.08, -0.02, -0.14)
	cons_pivot.visible = false
	gun_rig.add_child(cons_pivot)

	var mat_dark := _make_mat(Color("#0f172a"), 0.78, 0.28)
	var mat_gunmetal := _make_mat(Color("#1e293b"), 0.82, 0.24)
	var mat_steel := _make_mat(Color("#cbd5e1"), 0.92, 0.18)
	var mat_cyan := _make_mat(Color("#38bdf8"), 0.20, 0.10, true, 4.8)
	var mat_white := _make_mat(Color("#f8fafc"), 0.25, 0.32)
	var mat_med_red := _make_mat(Color("#ef4444"), 0.35, 0.25, true, 2.2)
	var mat_bio_green := _make_mat(Color("#22c55e"), 0.15, 0.12, true, 4.2)

	# 1. Shield Battery / Shield Cell / Phoenix Kit Prop (Iconic Apex Hex-Cap Turbine Capacitor)
	var bat_prop := Node3D.new()
	bat_prop.name = "BatteryProp"
	cons_pivot.add_child(bat_prop)

	# Lower Housing & Ribbed Grip Base (Left hand grips here)
	_add_cyl(bat_prop, 0.056, 0.060, 0.12, Vector3(0, -0.062, 0), mat_dark, Vector3.ZERO, 8, "BatteryLowerBody")
	_add_cyl(bat_prop, 0.064, 0.064, 0.026, Vector3(0, -0.118, 0), mat_steel, Vector3.ZERO, 6, "BatteryBottomHex")
	_add_ring(bat_prop, 0.048, 0.058, Vector3(0, -0.02, 0), mat_gunmetal, Vector3.ZERO, 16)

	# Central Illuminated Plasma Capacitor Core (Changes color for Cell / Battery / Phoenix)
	_add_cyl(bat_prop, 0.044, 0.044, 0.155, Vector3(0, 0.015, 0), mat_cyan, Vector3.ZERO, 16, "BatteryCoreMesh")
	# Internal energy coil rings around core
	for r_i in range(3):
		var ry: float = -0.02 + float(r_i) * 0.035
		_add_ring(bat_prop, 0.040, 0.047, Vector3(0, ry, 0), mat_white, Vector3.ZERO, 16)

	# Side Guard Rails (3 protective titanium struts around plasma core)
	for i in range(3):
		var ang: float = float(i) * TAU / 3.0
		var rx: float = cos(ang) * 0.056
		var rz: float = sin(ang) * 0.056
		_add_box(bat_prop, Vector3(0.012, 0.175, 0.015), Vector3(rx, 0.012, rz), mat_steel, Vector3(0, -ang, 0))

	# Animatable Upper Twist-Cap & Dual Pull-Handles (twists and pulls up during charge!)
	var bat_top := Node3D.new()
	bat_top.name = "BatteryTwistTop"
	bat_top.position = Vector3(0, 0.095, 0)
	bat_prop.add_child(bat_top)
	_add_cyl(bat_top, 0.062, 0.056, 0.046, Vector3.ZERO, mat_dark, Vector3.ZERO, 6, "UpperHexCap")
	_add_ring(bat_top, 0.040, 0.050, Vector3(0, 0.025, 0), mat_cyan, Vector3.ZERO, 18, "TopGlowRing")
	_add_box(bat_top, Vector3(0.105, 0.016, 0.026), Vector3(0, 0.032, 0), mat_steel, Vector3.ZERO, "TwistHandleBar")

	var bat_light := OmniLight3D.new()
	bat_light.name = "BatteryOmniLight"
	bat_light.light_color = Color("#38bdf8")
	bat_light.light_energy = 1.6
	bat_light.omni_range = 2.2
	bat_prop.add_child(bat_light)

	# 2. Syringe / MedKit Auto-Injector Prop (Iconic Apex Pneumatic Medical Injector)
	var med_prop := Node3D.new()
	med_prop.name = "MedProp"
	med_prop.visible = false
	cons_pivot.add_child(med_prop)

	# Injector Main White/Red Body & Ergonomic Side Grips
	_add_cyl(med_prop, 0.028, 0.030, 0.165, Vector3(0, 0.0, 0), mat_white, Vector3.ZERO, 14, "SyringeBarrel")
	_add_box(med_prop, Vector3(0.072, 0.095, 0.038), Vector3(0, -0.012, 0), mat_dark, Vector3.ZERO, "InjectorGrip")
	# Glowing Bio-Gel Window & Red Cross Stripes
	_add_cyl(med_prop, 0.030, 0.030, 0.064, Vector3(0, 0.022, 0), mat_bio_green, Vector3.ZERO, 14, "BioVialWindow")
	_add_box(med_prop, Vector3(0.038, 0.014, 0.036), Vector3(0, 0.062, 0), mat_med_red)
	_add_box(med_prop, Vector3(0.014, 0.038, 0.036), Vector3(0, 0.062, 0), mat_med_red)
	# Bottom Needle Guard & Nozzle
	_add_cyl(med_prop, 0.018, 0.007, 0.042, Vector3(0, -0.098, 0), mat_steel, Vector3.ZERO, 10, "InjectorNozzle")
	# Animatable Top Thumb Plunger
	var plunger := Node3D.new()
	plunger.name = "SyringePlunger"
	plunger.position = Vector3(0, 0.102, 0)
	med_prop.add_child(plunger)
	_add_cyl(plunger, 0.010, 0.010, 0.055, Vector3(0, -0.016, 0), mat_steel, Vector3.ZERO, 10)
	_add_cyl(plunger, 0.026, 0.026, 0.014, Vector3(0, 0.016, 0), mat_med_red, Vector3.ZERO, 14, "ThumbPad")


static func _build_boxing_glove_on_arm(arm_node: Node3D, is_left: bool, h_col: Color) -> void:
	## Builds a sleek, organic contoured 3D Championship Boxing Glove directly capping the forearm (ZERO boxy sharp edges!)
	var side_s: float = 1.0 if is_left else -1.0
	var mat_blue := _make_mat(Color("#0284c7"), 0.22, 0.28)
	var mat_navy := _make_mat(Color("#0369a1"), 0.26, 0.34)
	var mat_gold := _make_mat(Color("#facc15"), 0.85, 0.20)
	var mat_red := _make_mat(Color("#ef4444"), 0.40, 0.28)
	var mat_white := _make_mat(Color("#f8fafc"), 0.15, 0.45)
	var mat_led := _make_mat(h_col, 0.2, 0.1, true, 3.4)

	var glove_root := Node3D.new()
	glove_root.name = "LeftBoxingGlove" if is_left else "RightBoxingGlove"
	glove_root.position = Vector3(0.0, 0.0, -0.02)
	arm_node.add_child(glove_root)

	# 1. Collinear Gold & Red Championship Wrist Cuff seamlessly aligned with the forearm along +Z
	_add_cyl(glove_root, 0.046, 0.050, 0.12, Vector3(0, -0.01, 0.05), mat_gold, Vector3(PI * 0.5, 0, 0), 18, "GloveCuff")
	_add_cyl(glove_root, 0.049, 0.051, 0.024, Vector3(0, -0.01, 0.00), mat_red, Vector3(PI * 0.5, 0, 0), 18, "CuffTrim")
	_add_cyl(glove_root, 0.048, 0.051, 0.018, Vector3(0, -0.01, 0.10), mat_red, Vector3(PI * 0.5, 0, 0), 18, "CuffRearTrim")

	# 2. Smooth Organic Padded Leather Dome (NO sharp BoxMesh corners!)
	var main_dome := _add_sphere(glove_root, 0.072, Vector3(0, 0.008, -0.078), mat_blue, "BoxingFistMain")
	main_dome.scale = Vector3(1.12, 0.88, 1.28)

	# 3. Smooth Horizontal Contoured Knuckle Roll & Padded Backhand Cushion
	var knuckle_roll := _add_capsule(glove_root, 0.044, 0.135, Vector3(0, 0.018, -0.115), mat_blue, Vector3(0, 0, PI * 0.5), "KnuckleRoll")
	knuckle_roll.scale = Vector3(0.88, 1.0, 1.08)
	var white_strike_zone := _add_capsule(glove_root, 0.038, 0.122, Vector3(0, 0.012, -0.132), mat_white, Vector3(0, 0, PI * 0.5), "StrikeZonePad")
	white_strike_zone.scale = Vector3(0.75, 0.95, 0.85)

	# 4. Inward-Curled Padded Boxing Thumb (+X on Left Glove, -X on Right Glove)
	_add_capsule(glove_root, 0.032, 0.105, Vector3(side_s * 0.066, -0.006, -0.068), mat_navy, Vector3(PI * 0.46, -side_s * 0.28, 0), "BoxingThumb")
	_add_sphere(glove_root, 0.033, Vector3(side_s * 0.058, 0.002, -0.102), mat_navy, "ThumbTipPad")

	# 5. Curved Dorsal MRVN Badge on back of wrist cuff
	var badge := _add_cyl(glove_root, 0.026, 0.026, 0.008, Vector3(0, 0.040, 0.045), mat_led, Vector3(0, 0, 0), 14, "GloveScreen")
	badge.scale = Vector3(1.1, 1.0, 1.3)


static func _build_tactical_fp_arms(gun_rig: Node3D, legend_data: Dictionary, is_heirloom: bool = false, rec_len: float = 0.48, is_bow: bool = false, wid: String = "r301") -> void:
	## 3rd-Generation Full-Length Articulated First-Person Arms (Forearm + Elbow + UpperArm to Shoulder so arms NEVER float in mid-air!)
	var lid: String = str(legend_data.get("id", "wraith"))
	var col_prim: Color = legend_data.get("primary_color", Color("#312e81"))
	var col_sec: Color = legend_data.get("secondary_color", Color("#38bdf8"))
	var h_info: Dictionary = legend_data.get("heirloom", {"color": Color("#38bdf8")})
	var h_col: Color = h_info.get("color", Color("#38bdf8"))

	var mat_sleeve := _make_mat(col_prim, 0.42, 0.44)
	var mat_trim := _make_mat(col_sec, 0.76, 0.25)
	var mat_glove := _make_mat(Color("#0f172a"), 0.35, 0.55)
	var mat_leather := _make_mat(Color("#1e293b"), 0.28, 0.65)
	var mat_knuckle := _make_mat(Color("#475569"), 0.85, 0.20)
	var mat_chrome := _make_mat(Color("#cbd5e1"), 0.92, 0.16)
	var mat_gold := _make_mat(Color("#f59e0b"), 0.90, 0.18)
	var mat_hud := _make_mat(Color("#38bdf8"), 0.2, 0.1, true, 3.4)
	var mat_stim := _make_mat(Color("#22c55e"), 0.1, 0.1, true, 4.0)
	var mat_void := _make_mat(Color("#8b5cf6"), 0.3, 0.2, true, 3.2)
	var mat_plasma := _make_mat(h_col, 0.4, 0.1, true, 3.6)

	var grip_prof: Dictionary = WeaponMeshBuilder.get_weapon_grip_profile(wid)

	# 1. Left Arm (LeftArmPivot) — Collinear Forearm + Elbow + UpperArm anchored to off-screen Left Shoulder!
	var left_arm := Node3D.new()
	left_arm.name = "LeftArmPivot"
	if is_heirloom:
		left_arm.position = Vector3(-0.42, -0.06, -0.04) if lid == "pathfinder" else Vector3(-0.38, -0.08, -0.08)
	elif is_bow:
		left_arm.position = Vector3(-0.02, -0.04, -0.14)
	else:
		left_arm.position = grip_prof.get("left_pos", Vector3(-0.052, -0.036, -0.205))
		left_arm.rotation = grip_prof.get("left_rot", Vector3.ZERO)
	gun_rig.add_child(left_arm)

	var l_sleeve_mat := mat_chrome if (lid == "pathfinder") else mat_sleeve
	# Collinear Forearm extending straight back from wrist (z=0.04) to elbow (z=0.48)
	_add_capsule(left_arm, 0.041, 0.48, Vector3(0.0, -0.01, 0.25), l_sleeve_mat, Vector3(PI * 0.5, 0.0, 0.0), "LeftForearm")
	_add_cyl(left_arm, 0.045, 0.047, 0.18, Vector3(0.0, -0.01, 0.22), mat_trim, Vector3(PI * 0.5, 0.0, 0.0), 14, "LeftVambrace")
	# Elbow Joint & Upper Arm extending down-and-back to off-screen shoulder (prevents detached floating arm!)
	_add_sphere(left_arm, 0.044, Vector3(0.0, -0.01, 0.47), mat_glove, "LeftElbowJoint")
	_add_capsule(left_arm, 0.045, 0.54, Vector3(-0.08, -0.16, 0.66), l_sleeve_mat, Vector3(PI * 0.5 + 0.52, -0.28, 0.0), "LeftUpperArm")

	# Wrist Tactical Chrono HUD
	var chrono := _add_box(left_arm, Vector3(0.072, 0.018, 0.046), Vector3(0.0, 0.036, 0.095), mat_leather, Vector3.ZERO, "WristChrono")
	_add_box(chrono, Vector3(0.058, 0.005, 0.032), Vector3(0, 0.010, 0), mat_hud)

	if is_heirloom and lid == "pathfinder":
		_build_boxing_glove_on_arm(left_arm, true, h_col)
	else:
		_add_sphere(left_arm, 0.036, Vector3(0.0, -0.008, 0.025), mat_glove, "LeftWristJoint")
		_add_box(left_arm, Vector3(0.078, 0.058, 0.088), Vector3(0.0, 0.006, -0.02), mat_glove, Vector3(0, 0, -0.15), "LeftGloveHand")
		_add_box(left_arm, Vector3(0.074, 0.016, 0.038), Vector3(-0.002, 0.036, -0.022), mat_knuckle, Vector3(0, 0, -0.15))
		_add_capsule(left_arm, 0.012, 0.058, Vector3(0.036, 0.026, -0.025), mat_leather, Vector3(0.35, 0.45, -0.45), "LeftThumb")
		for fi in range(4):
			var fz: float = -0.052 + float(fi) * 0.018
			var f_curl: float = 0.35 if (is_heirloom and lid == "wraith") else 1.25
			_add_capsule(left_arm, 0.010, 0.054, Vector3(0.018, -0.022, fz), mat_leather, Vector3(0.15, 0.0, f_curl), "LeftFinger%d" % fi)

		if is_heirloom and lid == "lifeline":
			var l_stick := Node3D.new()
			l_stick.name = "LeftShockStick"
			l_stick.position = Vector3(0.01, 0.02, -0.03)
			l_stick.rotation = Vector3(0.35, 0.22, -0.18)
			left_arm.add_child(l_stick)
			_add_cyl(l_stick, 0.014, 0.016, 0.38, Vector3(0, 0.08, 0), mat_leather, Vector3.ZERO, 10)
			_add_cyl(l_stick, 0.022, 0.018, 0.07, Vector3(0, -0.09, 0), mat_gold, Vector3.ZERO, 10)
			_add_sphere(l_stick, 0.030, Vector3(0, 0.28, 0), mat_plasma)
			_add_ring(l_stick, 0.034, 0.044, Vector3(0, 0.23, 0), mat_plasma, Vector3.ZERO, 16)
		elif is_heirloom and lid == "ash":
			var l_kat := Node3D.new()
			l_kat.name = "LeftNunchakuSection"
			l_kat.position = Vector3(0.01, 0.02, -0.03)
			l_kat.rotation = Vector3(0.42, 0.25, -0.22)
			left_arm.add_child(l_kat)
			_add_cyl(l_kat, 0.015, 0.015, 0.20, Vector3(0, 0.02, 0), mat_leather, Vector3.ZERO, 10)
			_add_box(l_kat, Vector3(0.012, 0.18, 0.034), Vector3(0, 0.16, 0), mat_chrome)
			_add_box(l_kat, Vector3(0.015, 0.18, 0.010), Vector3(0, 0.16, -0.022), mat_plasma)

	if lid == "octane":
		_add_cyl(left_arm, 0.008, 0.008, 0.18, Vector3(-0.04, 0.00, 0.16), mat_stim, Vector3(PI * 0.5, 0, 0))
	elif lid == "wraith":
		_add_box(left_arm, Vector3(0.082, 0.018, 0.12), Vector3(0.0, 0.032, 0.18), mat_void, Vector3.ZERO)
	elif lid == "bloodhound":
		_add_box(left_arm, Vector3(0.084, 0.024, 0.08), Vector3(0.0, 0.032, 0.16), mat_gold, Vector3.ZERO)

	# 2. Right Arm (RightArmPivot) — Collinear Forearm + Elbow + UpperArm anchored to off-screen Right Shoulder!
	var right_arm := Node3D.new()
	right_arm.name = "RightArmPivot"
	if is_heirloom:
		right_arm.position = Vector3(-0.02, -0.06, -0.04) if lid == "pathfinder" else Vector3(0.04, -0.06, -0.04)
	elif is_bow:
		right_arm.position = Vector3(0.03, -0.02, 0.10)
	else:
		right_arm.position = grip_prof.get("right_pos", Vector3(0.02, -0.10, rec_len * 0.22))
		right_arm.rotation = grip_prof.get("right_rot", Vector3.ZERO)
	gun_rig.add_child(right_arm)

	var r_sleeve_mat := mat_chrome if (lid == "pathfinder") else mat_sleeve
	_add_capsule(right_arm, 0.041, 0.48, Vector3(0.0, -0.01, 0.25), r_sleeve_mat, Vector3(PI * 0.5, 0.0, 0.0), "RightForearm")
	_add_cyl(right_arm, 0.045, 0.047, 0.18, Vector3(0.0, -0.01, 0.22), mat_trim, Vector3(PI * 0.5, 0.0, 0.0), 14, "RightVambrace")
	_add_sphere(right_arm, 0.044, Vector3(0.0, -0.01, 0.47), mat_glove, "RightElbowJoint")
	_add_capsule(right_arm, 0.045, 0.54, Vector3(0.08, -0.16, 0.66), r_sleeve_mat, Vector3(PI * 0.5 + 0.52, 0.28, 0.0), "RightUpperArm")

	if is_heirloom and lid == "pathfinder":
		_build_boxing_glove_on_arm(right_arm, false, h_col)
	else:
		_add_sphere(right_arm, 0.036, Vector3(0.0, -0.008, 0.025), mat_glove, "RightWristJoint")
		_add_box(right_arm, Vector3(0.076, 0.066, 0.086), Vector3.ZERO, mat_glove, Vector3.ZERO, "RightGloveHand")
		_add_box(right_arm, Vector3(0.072, 0.016, 0.042), Vector3(0.0, 0.038, 0.0), mat_knuckle)
		_add_capsule(right_arm, 0.012, 0.056, Vector3(-0.038, 0.008, -0.035), mat_leather, Vector3(0.45, -0.35, 0.35), "RightThumb")
		if is_heirloom:
			_add_capsule(right_arm, 0.010, 0.052, Vector3(0.005, 0.002, -0.028), mat_leather, Vector3(0.0, 0.0, 1.35), "TriggerFinger")
		else:
			_add_capsule(right_arm, 0.010, 0.062, Vector3(0.018, 0.005, -0.052), mat_leather, Vector3(PI * 0.45, -0.15, 0), "TriggerFinger")
		for rfi in range(3):
			var rf_y: float = -0.015 - float(rfi) * 0.016
			_add_capsule(right_arm, 0.010, 0.052, Vector3(0.005, rf_y, -0.028), mat_leather, Vector3(0.0, 0.0, 1.35), "RightFinger%d" % rfi)

	# 3. First-Person Kick Leg & Combat Boot (KickLegPivot - Visible during Airborne Flying Jump-Kick!)
	var kick_leg := Node3D.new()
	kick_leg.name = "KickLegPivot"
	kick_leg.position = Vector3(0.0, -0.55, 0.25)
	kick_leg.visible = false
	gun_rig.add_child(kick_leg)
	var r_sleeve_mat := mat_chrome if (lid == "pathfinder") else mat_sleeve
	var mat_glove := _make_mat(Color("#0f172a"), 0.35, 0.55)
	var mat_knuckle := _make_mat(Color("#475569"), 0.85, 0.20)
	_add_capsule(kick_leg, 0.068, 0.44, Vector3(0, -0.04, 0.18), r_sleeve_mat, Vector3(PI * 0.46, 0, 0), "FP_ShinCore")
	_add_cyl(kick_leg, 0.074, 0.064, 0.28, Vector3(0, -0.03, 0.16), mat_trim, Vector3(PI * 0.46, 0, 0), 12, "FP_ShinGreave")
	_add_box(kick_leg, Vector3(0.12, 0.19, 0.09), Vector3(0, -0.02, -0.05), mat_glove, Vector3(-0.22, 0, 0), "FP_CombatBoot")
	_add_box(kick_leg, Vector3(0.13, 0.21, 0.03), Vector3(0, -0.02, -0.10), mat_knuckle, Vector3(-0.22, 0, 0), "FP_BootSole")


static func create_bocek_bow_rig(weapon_data: Dictionary, legend_data: Dictionary = {}) -> Node3D:
	## Authentic Apex Legends Bocek Compound Bow 3D Viewmodel
	var root := Node3D.new()
	root.name = "FP_Viewmodel"

	var gun_rig := Node3D.new()
	gun_rig.name = "GunRig"
	gun_rig.rotation = Vector3(0.0, 0.0, -0.24)
	root.add_child(gun_rig)

	var col_main: Color = weapon_data.get("color", Color("#d97706"))
	var col_accent: Color = weapon_data.get("accent", Color("#f59e0b"))

	var mat_riser := _make_mat(col_main, 0.78, 0.26)
	var mat_carbon := _make_mat(Color("#111827"), 0.45, 0.38)
	var mat_steel := _make_mat(Color("#94a3b8"), 0.90, 0.18)
	var mat_grip := _make_mat(Color("#1e293b"), 0.20, 0.78)
	var mat_accent := _make_mat(col_accent, 0.55, 0.22, true, 2.6)
	var mat_pin_green := _make_mat(Color("#22c55e"), 0.0, 0.1, true, 4.8)
	var mat_pin_red := _make_mat(Color("#ef4444"), 0.0, 0.1, true, 4.8)
	var mat_fletch := _make_mat(Color("#38bdf8"), 0.1, 0.25, true, 3.2)

	# 1. Central Sculpted Magnesium Alloy Riser & Cutout Struts (Named UpperReceiver for diagnostic compatibility)
	_add_box(gun_rig, Vector3(0.026, 0.24, 0.052), Vector3(-0.038, 0.13, -0.14), mat_riser, Vector3(-0.08, 0, 0), "UpperReceiver")
	_add_box(gun_rig, Vector3(0.032, 0.15, 0.056), Vector3(-0.02, -0.05, -0.14), mat_grip, Vector3(0.12, 0, 0), "BowGrip")
	_add_box(gun_rig, Vector3(0.030, 0.045, 0.072), Vector3(-0.020, 0.25, -0.13), mat_riser, Vector3(0.18, 0, 0), "UpperLimbPocket")
	_add_box(gun_rig, Vector3(0.030, 0.18, 0.014), Vector3(-0.038, 0.13, -0.168), mat_accent, Vector3(-0.08, 0, 0), "UpperRiserTrim")

	_add_box(gun_rig, Vector3(0.028, 0.22, 0.052), Vector3(-0.020, -0.20, -0.14), mat_riser, Vector3(0.08, 0, 0), "LowerRiser")
	_add_box(gun_rig, Vector3(0.030, 0.045, 0.072), Vector3(-0.020, -0.31, -0.13), mat_riser, Vector3(-0.18, 0, 0), "LowerLimbPocket")
	_add_box(gun_rig, Vector3(0.032, 0.16, 0.014), Vector3(-0.020, -0.20, -0.168), mat_accent, Vector3(0.08, 0, 0), "LowerRiserTrim")

	_add_cyl(gun_rig, 0.012, 0.014, 0.24, Vector3(-0.020, -0.12, -0.28), mat_carbon, Vector3(PI * 0.5, 0, 0), 10, "StabilizerRod")
	_add_cyl(gun_rig, 0.022, 0.020, 0.05, Vector3(-0.020, -0.12, -0.41), mat_accent, Vector3(PI * 0.5, 0, 0), 12, "StabilizerDamper")
	_add_ring(gun_rig, 0.014, 0.022, Vector3(0.0, 0.024, -0.15), mat_steel, Vector3(PI * 0.5, 0, 0), 18, "WhiskerRest")

	for side_x in [-0.036, -0.004]:
		_add_box(gun_rig, Vector3(0.010, 0.24, 0.026), Vector3(side_x, 0.35, -0.06), mat_carbon, Vector3(0.52, 0, 0), "UpperSplitLimb")
		_add_box(gun_rig, Vector3(0.010, 0.24, 0.026), Vector3(side_x, -0.41, -0.06), mat_carbon, Vector3(-0.52, 0, 0), "LowerSplitLimb")

	var top_cam := Node3D.new()
	top_cam.name = "TopCam"
	top_cam.position = Vector3(-0.020, 0.45, 0.02)
	gun_rig.add_child(top_cam)
	_add_cyl(top_cam, 0.048, 0.048, 0.014, Vector3.ZERO, mat_steel, Vector3(0, 0, PI * 0.5), 16, "TopCamWheel")
	_add_cyl(top_cam, 0.024, 0.024, 0.018, Vector3(0, 0.012, -0.012), mat_accent, Vector3(0, 0, PI * 0.5), 12)

	var bot_cam := Node3D.new()
	bot_cam.name = "BottomCam"
	bot_cam.position = Vector3(-0.020, -0.51, 0.02)
	gun_rig.add_child(bot_cam)
	_add_cyl(bot_cam, 0.048, 0.048, 0.014, Vector3.ZERO, mat_steel, Vector3(0, 0, PI * 0.5), 16, "BottomCamWheel")
	_add_cyl(bot_cam, 0.024, 0.024, 0.018, Vector3(0, -0.012, -0.012), mat_accent, Vector3(0, 0, PI * 0.5), 12)

	_add_cyl(gun_rig, 0.0025, 0.0025, 0.94, Vector3(-0.032, -0.03, 0.00), mat_steel, Vector3.ZERO, 6, "PowerCableA")
	_add_cyl(gun_rig, 0.0025, 0.0025, 0.94, Vector3(-0.008, -0.03, -0.01), mat_steel, Vector3.ZERO, 6, "PowerCableB")

	var string_pivot := Node3D.new()
	string_pivot.name = "BowStringPivot"
	string_pivot.position = Vector3(0.0, 0.024, 0.04)
	gun_rig.add_child(string_pivot)
	_add_cyl(string_pivot, 0.003, 0.003, 0.44, Vector3(-0.010, 0.21, -0.01), mat_accent, Vector3(0.05, 0, 0), 8, "UpperBowString")
	_add_cyl(string_pivot, 0.003, 0.003, 0.52, Vector3(-0.010, -0.26, -0.01), mat_accent, Vector3(-0.05, 0, 0), 8, "LowerBowString")
	_add_cyl(string_pivot, 0.006, 0.006, 0.035, Vector3(0, 0, 0), mat_pin_red, Vector3.ZERO, 8, "StringDLoop")

	var arrow_pivot := Node3D.new()
	arrow_pivot.name = "NockedArrowPivot"
	arrow_pivot.position = Vector3(0.0, 0.024, 0.04)
	gun_rig.add_child(arrow_pivot)
	_add_cyl(arrow_pivot, 0.0045, 0.0045, 0.60, Vector3(0, 0, -0.30), mat_carbon, Vector3(PI * 0.5, 0, 0), 8, "ArrowShaft")
	_add_cyl(arrow_pivot, 0.001, 0.012, 0.055, Vector3(0, 0, -0.62), mat_accent, Vector3(-PI * 0.5, 0, 0), 4, "BroadheadTip")
	for fi in range(3):
		var fang: float = float(fi) * TAU / 3.0
		var fx: float = cos(fang) * 0.008
		var fy: float = sin(fang) * 0.008
		_add_box(arrow_pivot, Vector3(0.002, 0.014, 0.065), Vector3(fx, fy, -0.05), mat_fletch, Vector3(0, 0, fang))
	_add_cyl(arrow_pivot, 0.0055, 0.0055, 0.020, Vector3(0, 0, 0.005), mat_pin_green, Vector3(PI * 0.5, 0, 0), 8, "ArrowNock")

	var optic_pivot := Node3D.new()
	optic_pivot.name = "OpticPivot"
	optic_pivot.position = Vector3(0.0, 0.082, -0.14)
	gun_rig.add_child(optic_pivot)
	_add_ring(optic_pivot, 0.024, 0.028, Vector3(0, 0, 0), mat_dark_bow(), Vector3(PI * 0.5, 0, 0), 24, "BowSightRing")
	_add_box(optic_pivot, Vector3(0.022, 0.006, 0.012), Vector3(-0.026, 0, 0), mat_steel)
	_add_box(optic_pivot, Vector3(0.018, 0.002, 0.002), Vector3(-0.009, 0.006, 0), mat_steel)
	_add_box(optic_pivot, Vector3(0.018, 0.002, 0.002), Vector3(-0.009, 0.000, 0), mat_steel)
	_add_box(optic_pivot, Vector3(0.018, 0.002, 0.002), Vector3(-0.009, -0.006, 0), mat_steel)

	var dot := MeshInstance3D.new()
	dot.name = "SightDot"
	var dot_sp := SphereMesh.new()
	dot_sp.radius = 0.0028
	dot_sp.height = 0.0056
	dot.mesh = dot_sp
	dot.material_override = mat_pin_green
	dot.position = Vector3(0, 0.0, 0)
	optic_pivot.add_child(dot)

	var mag_pivot := Node3D.new()
	mag_pivot.name = "MagPivot"
	mag_pivot.position = Vector3(-0.04, -0.18, -0.16)
	gun_rig.add_child(mag_pivot)
	for qi in range(3):
		var qz: float = -0.02 + float(qi) * 0.018
		_add_cyl(mag_pivot, 0.004, 0.004, 0.36, Vector3(-0.015, 0.02, qz), mat_carbon, Vector3(PI * 0.5, 0, 0), 6)
		_add_cyl(mag_pivot, 0.001, 0.009, 0.035, Vector3(-0.015, 0.02, qz - 0.19), mat_accent, Vector3(-PI * 0.5, 0, 0), 4)

	var bolt_pivot := Node3D.new()
	bolt_pivot.name = "BoltPivot"
	bolt_pivot.position = Vector3.ZERO
	gun_rig.add_child(bolt_pivot)

	var flash_pivot := Node3D.new()
	flash_pivot.name = "MuzzleFlashNode"
	flash_pivot.position = Vector3(0, 0.024, -0.58)
	flash_pivot.visible = false
	gun_rig.add_child(flash_pivot)

	# Rear-facing digital quiver counter screen
	var scr_housing := _add_box(gun_rig, Vector3(0.038, 0.028, 0.024), Vector3(-0.052, 0.04, -0.12), mat_dark_bow(), Vector3(-0.15, 0.25, 0), "AmmoScreenHousing")
	var ammo_lbl := Label3D.new()
	ammo_lbl.name = "AmmoLabel3D"
	ammo_lbl.text = "60"
	ammo_lbl.font_size = 24
	ammo_lbl.pixel_size = 0.00075
	ammo_lbl.modulate = col_accent
	ammo_lbl.position = Vector3(0, 0, 0.014)
	scr_housing.add_child(ammo_lbl)

	_build_tactical_fp_arms(gun_rig, legend_data, false, 0.32, true)
	_build_fp_consumable_props(gun_rig)

	root.position = Vector3(0.22, -0.20, -0.48)
	return root

static func mat_dark_bow() -> StandardMaterial3D:
	return _make_mat(Color("#0f172a"), 0.65, 0.35)


static func create_viewmodel(weapon_data: Dictionary, is_heirloom: bool = false, legend_data: Dictionary = {}, optic_id: String = "2x_bruiser") -> Node3D:
	if is_heirloom:
		return create_heirloom_rig(legend_data)

	var wid: String = str(weapon_data.get("id", "r301"))
	var stock_type: String = str(weapon_data.get("stock_type", "crane"))
	if wid == "bocek" or stock_type == "bow":
		return create_bocek_bow_rig(weapon_data, legend_data)

	var root := Node3D.new()
	root.name = "FP_Viewmodel"

	var gun_rig := Node3D.new()
	gun_rig.name = "GunRig"
	root.add_child(gun_rig)

	var col_main: Color = weapon_data.get("color", Color("#cbd5e1"))
	var col_accent: Color = weapon_data.get("accent", Color("#f97316"))
	var cat: String = str(weapon_data.get("cat", "AR"))
	var rec_len: float = float(weapon_data.get("rec_len", 0.48))
	var barrel_len: float = float(weapon_data.get("barrel_len", 0.38))

	if wid == "r301":
		col_main = Color("#06b6d4")
		col_accent = Color("#8b5cf6")

	var mat_body := _make_mat(col_main, 0.78, 0.24)
	var mat_dark := _make_mat(Color("#0f172a"), 0.68, 0.36)
	var mat_gunmetal := _make_mat(Color("#1e293b"), 0.82, 0.26)
	var mat_steel := _make_mat(Color("#94a3b8"), 0.92, 0.18)
	var mat_grip := _make_mat(Color("#111827"), 0.22, 0.76)
	var mat_accent := _make_mat(col_accent, 0.55, 0.22, true, 2.4)
	var mat_tritium := _make_mat(Color("#22c55e"), 0.1, 0.1, true, 4.5)
	var mat_port := _make_mat(Color("#090d14"), 0.85, 0.15)

	# 1. Sculpted Multi-Surface Upper & Lower Receiver with Chamfered Side Armor Plates
	var rec_h: float = 0.096 if cat != "PISTOL" else 0.072
	var rec_w: float = 0.078 if cat != "PISTOL" else 0.054
	if wid == "mastiff" or wid == "eva8":
		rec_w = 0.088
		rec_h = 0.105
	elif wid == "mozambique":
		rec_w = 0.068
		rec_h = 0.084

	# Core UpperReceiver (kept directly under GunRig for diagnostics & animation compatibility)
	var upper_rec := _add_box(gun_rig, Vector3(rec_w, rec_h * 0.65, rec_len), Vector3(0, 0.032, 0), mat_body, Vector3.ZERO, "UpperReceiver")
	# Sculpted Top Chamfer Cover & Rear Receiver Buffer Cap
	_add_box(upper_rec, Vector3(rec_w * 0.74, 0.022, rec_len * 0.94), Vector3(0, rec_h * 0.36, -0.01), mat_gunmetal)
	_add_cyl(upper_rec, rec_w * 0.42, rec_w * 0.46, 0.08, Vector3(0, -0.01, rec_len * 0.5 + 0.02), mat_dark, Vector3(PI * 0.5, 0, 0), 12, "RearBufferCap")
	# Angled Side Cheek Plates (gives authentic Apex multi-faceted weapon silhouette from 1st-person view)
	for side_s in [-1.0, 1.0]:
		_add_box(upper_rec, Vector3(0.012, rec_h * 0.52, rec_len * 0.86), Vector3(side_s * (rec_w * 0.5 + 0.003), -0.004, -0.01), mat_gunmetal, Vector3(0, 0, side_s * 0.18))
		_add_box(upper_rec, Vector3(0.008, 0.014, rec_len * 0.74), Vector3(side_s * (rec_w * 0.5 + 0.007), 0.008, -0.02), mat_accent)

	# Lower Receiver, Magwell & Trigger Housing
	_add_box(gun_rig, Vector3(rec_w * 0.88, rec_h * 0.62, rec_len * 0.78), Vector3(0, -0.036, 0.02), mat_dark, Vector3.ZERO, "LowerReceiver")

	# R-301 / CAR / R-99 / Volt Signature Angled Magwell Funnel & Forward Receiver Bevel
	if wid == "r301" or wid == "car" or wid == "r99" or wid == "volt":
		_add_box(gun_rig, Vector3(rec_w * 0.92, 0.082, 0.092), Vector3(0, -0.058, -0.055), mat_body, Vector3(0.34, 0, 0), "AngledMagwell")

	# Prowler PDW Top Sculpted Rib & Forward Thumbhole Foregrip
	if wid == "prowler":
		_add_box(gun_rig, Vector3(rec_w * 0.68, 0.034, rec_len * 0.88), Vector3(0, rec_h * 0.5 + 0.024, -0.02), mat_body, Vector3.ZERO, "ProwlerTopHood")
		_add_box(gun_rig, Vector3(0.038, 0.105, 0.052), Vector3(0, -0.090, -rec_len * 0.36), mat_grip, Vector3(0.28, 0, 0), "ForwardForegrip")

	# Ejection Port & Brass Deflector
	_add_box(gun_rig, Vector3(0.006, 0.028, 0.105), Vector3(rec_w * 0.5 + 0.004, 0.028, 0.02), mat_port, Vector3.ZERO, "EjectionPort")

	# Rear Iron-Sight Peep Wings with Glowing Green Tritium Dots & Front Sight Hood (matching image_0ab157.jpg!)
	var rear_z: float = rec_len * 0.42
	for rs in [-1.0, 1.0]:
		_add_box(gun_rig, Vector3(0.006, 0.024, 0.022), Vector3(rs * 0.022, rec_h * 0.5 + 0.028, rear_z), mat_gunmetal, Vector3(0, 0, -rs * 0.18))
		_add_sphere(gun_rig, 0.0032, Vector3(rs * 0.019, rec_h * 0.5 + 0.035, rear_z + 0.010), mat_tritium)

	# 2. Ventilated Handguard, Heatshield & Low-Profile Top Picatinny Rail
	var front_sight_z: float = -(rec_len * 0.5 + barrel_len * 0.55)
	if cat != "PISTOL" and wid != "mozambique":
		var hg_len: float = barrel_len * 0.72
		var hg_z: float = -(rec_len * 0.5 + hg_len * 0.46)
		front_sight_z = hg_z - hg_len * 0.44
		_add_box(gun_rig, Vector3(rec_w * 0.84, rec_h * 0.74, hg_len), Vector3(0, 0.018, hg_z), mat_gunmetal, Vector3.ZERO, "Handguard")
		_add_cyl(gun_rig, rec_w * 0.38, rec_w * 0.38, hg_len * 0.95, Vector3(0, -0.008, hg_z), mat_dark, Vector3(PI * 0.5, 0, 0), 8)
		for v in range(4):
			var vz: float = hg_z + hg_len * 0.34 - float(v) * (hg_len * 0.22)
			_add_box(gun_rig, Vector3(rec_w * 0.90, 0.014, 0.022), Vector3(0, 0.024, vz), mat_accent)

	# Sculpted Front Sight Hood & Glowing Post
	_add_ring(gun_rig, 0.016, 0.020, Vector3(0, rec_h * 0.5 + 0.026, front_sight_z), mat_gunmetal, Vector3(PI * 0.5, 0, 0), 16, "FrontSightHood")
	_add_box(gun_rig, Vector3(0.004, 0.018, 0.006), Vector3(0, rec_h * 0.5 + 0.022, front_sight_z), mat_tritium, Vector3.ZERO, "FrontSightPost")

	var rail_count: int = 8 if cat != "PISTOL" else 4
	for r in range(rail_count):
		var rz: float = rec_len * 0.34 - float(r) * 0.046
		_add_box(gun_rig, Vector3(0.032, 0.008, 0.022), Vector3(0, rec_h * 0.5 + 0.022, rz), mat_steel)

	# 3. Archetype-Specific Barrel, Gas Block, Choke Ribs & Muzzle Architecture
	var bar_z: float = -(rec_len * 0.5 + barrel_len * 0.5)
	var muz_z: float = -(rec_len * 0.5 + barrel_len + 0.04)

	if wid == "chargerifle":
		_add_box(gun_rig, Vector3(0.022, 0.046, barrel_len), Vector3(-0.044, 0.025, bar_z), mat_dark, Vector3.ZERO, "LeftRail")
		_add_box(gun_rig, Vector3(0.022, 0.046, barrel_len), Vector3(0.044, 0.025, bar_z), mat_dark, Vector3.ZERO, "RightRail")
		_add_cyl(gun_rig, 0.015, 0.015, barrel_len, Vector3(0, 0.025, bar_z), mat_steel, Vector3(PI * 0.5, 0, 0), 12, "AcceleratorTube")
		for ci in range(3):
			var cz: float = bar_z + (float(ci) - 1.0) * (barrel_len * 0.32)
			_add_cyl(gun_rig, 0.028, 0.028, 0.024, Vector3(0, 0.025, cz), mat_accent, Vector3(PI * 0.5, 0, 0), 12, "ChargeCoil%d" % ci)
		_add_cyl(gun_rig, 0.032, 0.024, 0.08, Vector3(0, 0.025, muz_z), mat_accent, Vector3(PI * 0.5, 0, 0), 10, "FocusMuzzle")
	elif wid == "peacekeeper":
		# Peacekeeper Lever-Action Star-Choke Shotgun: Sculpted Octagonal Shroud + Twin Glowing Precision Choke Fins!
		_add_cyl(gun_rig, 0.024, 0.026, barrel_len, Vector3(0, 0.030, bar_z), mat_steel, Vector3(PI * 0.5, 0, 0), 8, "OctagonBarrel")
		_add_cyl(gun_rig, 0.019, 0.019, barrel_len * 0.92, Vector3(0, -0.012, bar_z * 0.96), mat_dark, Vector3(PI * 0.5, 0, 0), 8, "UnderTube")
		_add_box(gun_rig, Vector3(0.012, 0.026, barrel_len * 0.88), Vector3(-0.042, 0.024, bar_z), mat_accent, Vector3.ZERO, "ChokeRibLeft")
		_add_box(gun_rig, Vector3(0.012, 0.026, barrel_len * 0.88), Vector3(0.042, 0.024, bar_z), mat_accent, Vector3.ZERO, "ChokeRibRight")
		_add_cyl(gun_rig, 0.034, 0.028, 0.08, Vector3(0, 0.026, muz_z), mat_accent, Vector3(PI * 0.5, 0, 0), 5, "StarChokeMuzzle")
	elif wid == "mastiff":
		_add_cyl(gun_rig, 0.024, 0.026, barrel_len, Vector3(0, 0.028, bar_z), mat_steel, Vector3(PI * 0.5, 0, 0), 12, "MainBarrel")
		_add_cyl(gun_rig, 0.020, 0.020, barrel_len * 0.88, Vector3(0, -0.016, bar_z * 0.94), mat_dark, Vector3(PI * 0.5, 0, 0), 10, "UnderMagazineTube")
		_add_box(gun_rig, Vector3(0.140, 0.040, 0.082), Vector3(0, 0.025, muz_z), mat_dark, Vector3.ZERO, "WideSlottedMuzzle")
		_add_box(gun_rig, Vector3(0.146, 0.014, 0.052), Vector3(0, 0.025, muz_z - 0.01), mat_accent, Vector3.ZERO, "HorizontalSpreadSlot")
	elif wid == "mozambique":
		_add_box(gun_rig, Vector3(0.068, 0.074, barrel_len * 0.85), Vector3(0, 0.015, bar_z * 0.9), mat_body, Vector3.ZERO, "TriBarrelShroud")
		_add_cyl(gun_rig, 0.012, 0.012, barrel_len, Vector3(0, 0.036, bar_z), mat_steel, Vector3(PI * 0.5, 0, 0), 10, "TopBarrel")
		_add_cyl(gun_rig, 0.012, 0.012, barrel_len, Vector3(-0.018, 0.004, bar_z), mat_steel, Vector3(PI * 0.5, 0, 0), 10, "BotLeftBarrel")
		_add_cyl(gun_rig, 0.012, 0.012, barrel_len, Vector3(0.018, 0.004, bar_z), mat_steel, Vector3(PI * 0.5, 0, 0), 10, "BotRightBarrel")
		_add_box(gun_rig, Vector3(0.072, 0.068, 0.044), Vector3(0, 0.018, muz_z), mat_accent, Vector3.ZERO, "TriangleMuzzle")
	elif wid == "alternator":
		_add_cyl(gun_rig, 0.013, 0.013, barrel_len, Vector3(-0.018, 0.025, bar_z), mat_steel, Vector3(PI * 0.5, 0, 0), 10, "LeftTwinBarrel")
		_add_cyl(gun_rig, 0.013, 0.013, barrel_len, Vector3(0.018, 0.025, bar_z), mat_steel, Vector3(PI * 0.5, 0, 0), 10, "RightTwinBarrel")
		_add_box(gun_rig, Vector3(0.066, 0.042, 0.062), Vector3(0, 0.025, muz_z), mat_dark, Vector3.ZERO, "TwinMuzzleBlock")
	elif wid == "tripletake":
		for tx in [-0.025, 0.0, 0.025]:
			_add_cyl(gun_rig, 0.012, 0.012, barrel_len, Vector3(tx, 0.025, bar_z), mat_steel, Vector3(PI * 0.5, 0, 0), 10)
		_add_box(gun_rig, Vector3(0.088, 0.034, 0.092), Vector3(0, 0.025, muz_z), mat_accent, Vector3.ZERO, "TripleMuzzleChoke")
	elif wid == "lstar":
		_add_cyl(gun_rig, 0.026, 0.026, barrel_len * 0.9, Vector3(0, 0.025, bar_z), mat_accent, Vector3(PI * 0.5, 0, 0), 12, "PlasmaHeatCore")
		for side in [-1.0, 1.0]:
			_add_box(gun_rig, Vector3(0.014, 0.050, barrel_len), Vector3(side * 0.036, 0.025, bar_z), mat_dark)
		_add_cyl(gun_rig, 0.032, 0.026, 0.08, Vector3(0, 0.025, muz_z), mat_steel, Vector3(PI * 0.5, 0, 0), 8, "PlasmaLensMuzzle")
	else:
		_add_cyl(gun_rig, 0.017, 0.019, barrel_len, Vector3(0, 0.025, bar_z), mat_steel, Vector3(PI * 0.5, 0, 0), 12, "MainBarrel")
		if cat != "PISTOL":
			_add_cyl(gun_rig, 0.011, 0.011, barrel_len * 0.78, Vector3(0, -0.010, bar_z * 0.88), mat_dark, Vector3(PI * 0.5, 0, 0), 10, "GasTube")
		if cat == "SNIPER":
			_add_box(gun_rig, Vector3(0.056, 0.046, 0.11), Vector3(0, 0.025, muz_z), mat_dark, Vector3.ZERO, "HeavyMuzzleBrake")
		elif cat == "SHOTGUN":
			_add_cyl(gun_rig, 0.032, 0.026, 0.09, Vector3(0, 0.025, muz_z), mat_accent, Vector3(PI * 0.5, 0, 0), 8, "ShotgunChoke")
		else:
			_add_cyl(gun_rig, 0.024, 0.020, 0.08, Vector3(0, 0.025, muz_z), mat_dark, Vector3(PI * 0.5, 0, 0), 10, "MuzzleCompensator")

	# 4. Muzzle Flash Star + OmniLight3D
	var flash_pivot := Node3D.new()
	flash_pivot.name = "MuzzleFlashNode"
	flash_pivot.position = Vector3(0, 0.025, muz_z - 0.08)
	flash_pivot.visible = false
	var mat_flash := _make_mat(col_accent, 0.0, 0.1, true, 4.8)
	_add_box(flash_pivot, Vector3(0.22, 0.035, 0.02), Vector3.ZERO, mat_flash)
	_add_box(flash_pivot, Vector3(0.035, 0.22, 0.02), Vector3.ZERO, mat_flash)
	_add_cyl(flash_pivot, 0.005, 0.06, 0.24, Vector3(0, 0, -0.10), mat_flash, Vector3(-PI * 0.5, 0, 0), 8)
	var flash_light := OmniLight3D.new()
	flash_light.light_color = col_accent
	flash_light.light_energy = 2.8
	flash_light.omni_range = 6.5
	flash_pivot.add_child(flash_light)
	gun_rig.add_child(flash_pivot)

	# 5. Ergonomic Pistol Grip, Trigger Guard & Buttstock
	_add_box(gun_rig, Vector3(0.044, 0.145, 0.064), Vector3(0, -0.120, rec_len * 0.22), mat_grip, Vector3(-0.28, 0, 0), "PistolGrip")
	_add_box(gun_rig, Vector3(0.022, 0.015, 0.072), Vector3(0, -0.092, rec_len * 0.08), mat_steel, Vector3.ZERO, "TriggerGuard")

	if stock_type == "crane" or stock_type == "heavy" or stock_type == "bullpup":
		var st_z: float = rec_len * 0.5 + 0.15
		_add_cyl(gun_rig, 0.018, 0.018, 0.25, Vector3(0, 0.01, st_z), mat_dark, Vector3(PI * 0.5, 0, 0), 10)
		_add_box(gun_rig, Vector3(0.054, 0.135, 0.21), Vector3(0, -0.02, st_z + 0.05), mat_body, Vector3.ZERO, "Buttstock")
		_add_box(gun_rig, Vector3(0.058, 0.145, 0.028), Vector3(0, -0.02, st_z + 0.16), mat_grip, Vector3.ZERO, "RubberButtpad")
	elif stock_type == "sniper":
		var st_z: float = rec_len * 0.5 + 0.19
		_add_box(gun_rig, Vector3(0.050, 0.115, 0.32), Vector3(0, -0.01, st_z), mat_body, Vector3.ZERO, "SniperStock")
		_add_box(gun_rig, Vector3(0.060, 0.032, 0.15), Vector3(0, 0.062, st_z - 0.02), mat_accent, Vector3.ZERO, "CheekRiser")
	elif stock_type == "wire":
		for side in [-1.0, 1.0]:
			_add_cyl(gun_rig, 0.006, 0.006, 0.22, Vector3(side * 0.026, 0.0, rec_len * 0.5 + 0.10), mat_steel, Vector3(PI * 0.5, 0, 0), 8)
	elif stock_type == "shotgun":
		var st_z: float = rec_len * 0.5 + 0.14
		_add_box(gun_rig, Vector3(0.050, 0.11, 0.22), Vector3(0, -0.025, st_z), mat_gunmetal, Vector3(-0.08, 0, 0), "ShotgunStock")
		_add_box(gun_rig, Vector3(0.054, 0.12, 0.028), Vector3(0, -0.03, st_z + 0.11), mat_grip, Vector3.ZERO, "ShotgunButtpad")

	# 6. Animatable Detachable Magazine Pivot (MagPivot)
	var mag_pivot := Node3D.new()
	mag_pivot.name = "MagPivot"
	var mag_z: float = 0.22 if stock_type == "bullpup" else -0.05
	mag_pivot.position = Vector3(0, -0.14, mag_z)
	gun_rig.add_child(mag_pivot)

	if wid == "chargerifle":
		mag_pivot.position = Vector3(0, -0.11, 0.02)
		_add_cyl(mag_pivot, 0.028, 0.028, 0.16, Vector3.ZERO, mat_dark, Vector3.ZERO, 12, "EnergyCanister")
		_add_cyl(mag_pivot, 0.022, 0.022, 0.12, Vector3(0, 0, 0.012), mat_accent, Vector3.ZERO, 10, "EnergyCore")
		_add_box(mag_pivot, Vector3(0.038, 0.018, 0.04), Vector3(0, -0.08, 0), mat_steel)
	elif wid == "wingman":
		mag_pivot.position = Vector3(0, 0.018, -0.02)
		_add_cyl(mag_pivot, 0.036, 0.036, 0.075, Vector3.ZERO, mat_steel, Vector3(PI * 0.5, 0, 0), 6, "RevolverCylinder")
		_add_cyl(mag_pivot, 0.008, 0.008, 0.11, Vector3(0, 0, -0.02), mat_accent, Vector3(PI * 0.5, 0, 0), 8)
	elif wid == "peacekeeper":
		# Peacekeeper Side-Loading Star Energy Cell Cartridge
		mag_pivot.position = Vector3(-0.02, -0.02, -0.08)
		_add_cyl(mag_pivot, 0.026, 0.026, 0.12, Vector3.ZERO, mat_dark, Vector3(PI * 0.5, 0, 0), 8, "PeacekeeperCell")
		_add_cyl(mag_pivot, 0.028, 0.028, 0.06, Vector3(0, 0, 0), mat_accent, Vector3(PI * 0.5, 0, 0), 8, "PeacekeeperPlasma")
	elif wid == "eva8":
		_add_cyl(mag_pivot, 0.068, 0.068, 0.11, Vector3(0, -0.01, 0), mat_dark, Vector3(PI * 0.5, 0, 0), 16, "EvaDrumMag")
		_add_cyl(mag_pivot, 0.045, 0.045, 0.116, Vector3(0, -0.01, 0), mat_accent, Vector3(PI * 0.5, 0, 0), 12, "EvaDrumCore")
	elif wid == "kraber":
		mag_pivot.position = Vector3(-0.055, 0.02, -0.02)
		_add_box(mag_pivot, Vector3(0.095, 0.065, 0.125), Vector3.ZERO, mat_dark, Vector3.ZERO, "KraberSideMag")
		_add_box(mag_pivot, Vector3(0.022, 0.048, 0.105), Vector3(-0.045, 0, 0), mat_accent)
	elif wid == "prowler":
		mag_pivot.position = Vector3(0, 0.052, 0.12)
		_add_box(mag_pivot, Vector3(0.058, 0.042, 0.185), Vector3.ZERO, mat_dark, Vector3.ZERO, "ProwlerTopMag")
		_add_box(mag_pivot, Vector3(0.062, 0.016, 0.145), Vector3(0, 0.018, 0), mat_accent)
	elif wid == "mastiff" or wid == "repeater3030":
		mag_pivot.position = Vector3(0, -0.04, -0.06)
		_add_cyl(mag_pivot, 0.011, 0.011, 0.065, Vector3(0, -0.02, 0), mat_accent, Vector3(PI * 0.5, 0, 0), 10, "ShellCarrier")
	elif cat == "LMG":
		_add_box(mag_pivot, Vector3(0.125, 0.175, 0.135), Vector3(0, -0.02, 0), mat_dark, Vector3.ZERO, "DrumMag")
		_add_box(mag_pivot, Vector3(0.130, 0.038, 0.140), Vector3(0, -0.06, 0), mat_accent)
	elif str(weapon_data.get("ammo", "")) == "energy":
		_add_box(mag_pivot, Vector3(0.058, 0.165, 0.092), Vector3.ZERO, mat_dark, Vector3(0.12, 0, 0))
		_add_box(mag_pivot, Vector3(0.064, 0.105, 0.040), Vector3(0, -0.01, 0), mat_accent, Vector3(0.12, 0, 0), "EnergyCoreWindow")
	else:
		var m_tilt: float = float(weapon_data.get("mag_curve", 0.18))
		_add_box(mag_pivot, Vector3(0.050, 0.185, 0.078), Vector3.ZERO, mat_dark, Vector3(m_tilt, 0, 0), "MagBody")
		_add_box(mag_pivot, Vector3(0.058, 0.024, 0.088), Vector3(0, -0.092, -0.015), mat_accent, Vector3(m_tilt, 0, 0), "MagBaseplate")
		_add_box(mag_pivot, Vector3(0.054, 0.085, 0.016), Vector3(0, 0.0, 0), mat_accent, Vector3(m_tilt, 0, 0), "AmmoStrip")

	# 7. Animatable Bolt Carrier / Charging Handle / Lever / Pump Pivot (BoltPivot)
	var bolt_pivot := Node3D.new()
	bolt_pivot.name = "BoltPivot"
	bolt_pivot.position = Vector3(0, 0.032, -0.04)
	gun_rig.add_child(bolt_pivot)

	if wid == "chargerifle":
		bolt_pivot.position = Vector3(0, 0.045, -0.06)
		_add_box(bolt_pivot, Vector3(rec_w * 0.88, 0.018, 0.12), Vector3.ZERO, mat_accent, Vector3.ZERO, "VentLouvers")
	elif wid == "peacekeeper" or wid == "repeater3030":
		bolt_pivot.position = Vector3(0, -0.08, 0.06)
		_add_box(bolt_pivot, Vector3(0.020, 0.085, 0.115), Vector3(0, -0.03, 0), mat_accent, Vector3.ZERO, "LeverLoop")
	elif wid == "mastiff":
		bolt_pivot.position = Vector3(0, -0.025, -0.22)
		_add_box(bolt_pivot, Vector3(0.068, 0.048, 0.155), Vector3.ZERO, mat_grip, Vector3.ZERO, "PumpForend")
		_add_box(bolt_pivot, Vector3(0.072, 0.016, 0.115), Vector3(0, 0, 0), mat_accent)
	elif cat == "SNIPER":
		_add_cyl(bolt_pivot, 0.014, 0.014, 0.14, Vector3(0.02, 0, 0.04), mat_steel, Vector3(PI * 0.5, 0, 0), 10)
		_add_cyl(bolt_pivot, 0.007, 0.007, 0.065, Vector3(0.058, -0.01, 0.06), mat_steel, Vector3(0, 0, 1.25), 8)
		_add_sphere(bolt_pivot, 0.015, Vector3(0.085, -0.022, 0.06), mat_accent)
	else:
		_add_box(bolt_pivot, Vector3(0.052, 0.016, 0.026), Vector3(-0.042, 0.01, -0.04), mat_accent, Vector3.ZERO, "ChargingHandle")
		_add_box(bolt_pivot, Vector3(0.012, 0.028, 0.105), Vector3(rec_w * 0.48, -0.005, 0.05), mat_steel, Vector3.ZERO, "BoltCarrier")

	# 8. Modular 3D Optic Sight (OpticPivot)
	var optic_pivot := Node3D.new()
	optic_pivot.name = "OpticPivot"
	optic_pivot.position = Vector3(0, rec_h * 0.5 + 0.026, 0.02)
	gun_rig.add_child(optic_pivot)

	var mat_lens := StandardMaterial3D.new()
	mat_lens.albedo_color = Color(0.25, 0.70, 1.0, 0.02)
	mat_lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_lens.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_lens.roughness = 0.02
	mat_lens.metallic = 0.05

	var mat_threat_lens := StandardMaterial3D.new()
	mat_threat_lens.albedo_color = Color(0.12, 0.16, 0.22, 0.04)
	mat_threat_lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_threat_lens.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_threat_lens.roughness = 0.02

	var mat_reticle := _make_mat(Color("#ff1e42"), 0.0, 0.1, true, 4.2)

	if optic_id == "6x_kraber" or (cat == "SNIPER" and optic_id == ""):
		_add_cyl(optic_pivot, 0.026, 0.026, 0.24, Vector3(0, 0.036, 0), mat_dark, Vector3(PI * 0.5, 0, 0), 16)
		_add_cyl(optic_pivot, 0.032, 0.026, 0.06, Vector3(0, 0.036, -0.13), mat_body, Vector3(PI * 0.5, 0, 0), 16)
		_add_cyl(optic_pivot, 0.024, 0.024, 0.003, Vector3(0, 0.036, 0.118), mat_lens, Vector3(PI * 0.5, 0, 0), 14)
		_add_box(optic_pivot, Vector3(0.046, 0.016, 0.052), Vector3(0, 0.012, 0.05), mat_steel)
		_add_box(optic_pivot, Vector3(0.046, 0.016, 0.052), Vector3(0, 0.012, -0.05), mat_steel)
	elif optic_id == "1x_hcog":
		_add_box(optic_pivot, Vector3(0.050, 0.007, 0.064), Vector3(0, 0.0035, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.034, 0.035), Vector3(-0.024, 0.022, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.034, 0.035), Vector3(0.024, 0.022, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.045, 0.032, 0.002), Vector3(0, 0.022, -0.005), mat_lens)
	elif optic_id == "2x_bruiser":
		_add_box(optic_pivot, Vector3(0.054, 0.007, 0.068), Vector3(0, 0.0035, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.036, 0.040), Vector3(-0.026, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.036, 0.040), Vector3(0.026, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.054, 0.003, 0.040), Vector3(0, 0.042, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.049, 0.035, 0.002), Vector3(0, 0.024, -0.005), mat_lens)
	elif optic_id == "1x_holo":
		_add_box(optic_pivot, Vector3(0.052, 0.007, 0.070), Vector3(0, 0.0035, 0), mat_dark)
		_add_ring(optic_pivot, 0.025, 0.029, Vector3(0, 0.024, -0.025), mat_dark, Vector3(PI * 0.5, 0, 0), 24, "HoloFrontRing")
		_add_ring(optic_pivot, 0.025, 0.029, Vector3(0, 0.024, 0.025), mat_dark, Vector3(PI * 0.5, 0, 0), 24, "HoloRearRing")
		_add_box(optic_pivot, Vector3(0.003, 0.016, 0.050), Vector3(-0.027, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.016, 0.050), Vector3(0.027, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.020, 0.003, 0.050), Vector3(0, 0.052, 0), mat_dark)
	elif optic_id == "3x_ranger":
		_add_box(optic_pivot, Vector3(0.054, 0.008, 0.090), Vector3(0, 0.004, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.038, 0.055), Vector3(-0.026, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.038, 0.055), Vector3(0.026, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.054, 0.003, 0.055), Vector3(0, 0.043, 0), mat_dark)
		_add_cyl(optic_pivot, 0.007, 0.007, 0.055, Vector3(0.033, 0.018, 0), mat_steel, Vector3(PI * 0.5, 0, 0), 8)
		_add_box(optic_pivot, Vector3(0.049, 0.036, 0.002), Vector3(0, 0.024, -0.005), mat_lens)
	elif optic_id == "2x_4x_aog":
		_add_box(optic_pivot, Vector3(0.052, 0.008, 0.085), Vector3(0, 0.004, 0), mat_dark)
		_add_ring(optic_pivot, 0.026, 0.030, Vector3(0, 0.024, -0.035), mat_dark, Vector3(PI * 0.5, 0, 0), 24, "AogFrontRing")
		_add_ring(optic_pivot, 0.026, 0.030, Vector3(0, 0.024, 0.035), mat_dark, Vector3(PI * 0.5, 0, 0), 24, "AogRearRing")
		_add_box(optic_pivot, Vector3(0.003, 0.020, 0.070), Vector3(-0.028, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.020, 0.070), Vector3(0.028, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.024, 0.003, 0.070), Vector3(0, 0.053, 0), mat_dark)
		_add_cyl(optic_pivot, 0.007, 0.007, 0.012, Vector3(0, 0.058, 0), mat_steel, Vector3.ZERO, 8)
		_add_cyl(optic_pivot, 0.007, 0.007, 0.012, Vector3(0.033, 0.024, 0), mat_steel, Vector3(0, 0, PI * 0.5), 8)
	elif optic_id == "1x_threat":
		_add_box(optic_pivot, Vector3(0.054, 0.007, 0.065), Vector3(0, 0.0035, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.036, 0.042), Vector3(-0.026, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.036, 0.042), Vector3(0.026, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.054, 0.003, 0.042), Vector3(0, 0.042, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.049, 0.035, 0.002), Vector3(0, 0.024, -0.005), mat_threat_lens)
	else:
		_add_box(optic_pivot, Vector3(0.050, 0.007, 0.064), Vector3(0, 0.0035, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.034, 0.035), Vector3(-0.024, 0.022, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.034, 0.035), Vector3(0.024, 0.022, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.045, 0.032, 0.002), Vector3(0, 0.022, -0.005), mat_lens)

	var dot := MeshInstance3D.new()
	dot.name = "SightDot"
	var dot_sp := SphereMesh.new()
	dot_sp.radius = 0.003
	dot_sp.height = 0.006
	dot.mesh = dot_sp
	dot.material_override = mat_reticle
	dot.position = Vector3(0, 0.024, -0.008)
	optic_pivot.add_child(dot)

	# 9. Integrated Rear-Facing Digital Ammo Readout Screen on ALL Weapons!
	# Fixes the sideways floating number bug seen in image_0aa5b8.png!
	var scr_pos := Vector3(-rec_w * 0.42, 0.036, rec_len * 0.36)
	var scr_rot := Vector3(-0.22, 0.24, -0.06)
	var scr_housing := _add_box(gun_rig, Vector3(0.040, 0.028, 0.026), scr_pos, mat_dark, scr_rot, "AmmoScreenHousing")
	_add_box(scr_housing, Vector3(0.034, 0.022, 0.004), Vector3(0, 0, 0.013), _make_mat(Color("#0c4a6e"), 0.1, 0.8, true, 2.2), Vector3.ZERO, "ScreenGlass")

	var ammo_lbl := Label3D.new()
	ammo_lbl.name = "AmmoLabel3D"
	ammo_lbl.text = "%02d" % int(weapon_data.get("mag", 20))
	ammo_lbl.font_size = 24
	ammo_lbl.pixel_size = 0.00072
	ammo_lbl.outline_size = 3
	ammo_lbl.outline_modulate = Color(0, 0, 0, 0.95)
	ammo_lbl.modulate = Color("#38bdf8") if wid == "r301" else col_accent
	ammo_lbl.position = Vector3(0, 0, 0.016)
	ammo_lbl.rotation = Vector3.ZERO
	scr_housing.add_child(ammo_lbl)

	if wid == "r301":
		var charm_pivot := Node3D.new()
		charm_pivot.name = "OmamoriCharm"
		charm_pivot.position = Vector3(-rec_w * 0.5 - 0.020, 0.018, -0.06)
		gun_rig.add_child(charm_pivot)
		var mat_charm := _make_mat(Color("#f472b6"), 0.1, 0.6)
		var mat_ribbon := _make_mat(Color("#ef4444"), 0.2, 0.5)
		var mat_gold := _make_mat(Color("#fbbf24"), 0.9, 0.2)
		_add_cyl(charm_pivot, 0.007, 0.007, 0.003, Vector3(0, 0.028, 0), mat_gold, Vector3(0, 0, PI * 0.5), 10)
		_add_box(charm_pivot, Vector3(0.010, 0.056, 0.042), Vector3(0, -0.012, 0), mat_charm, Vector3(0.08, 0, -0.15))
		_add_box(charm_pivot, Vector3(0.012, 0.016, 0.022), Vector3(0, 0.016, 0), mat_ribbon, Vector3(0.08, 0, -0.15))

	# 9B. Attach Real Open-Source 3D Meshes (Quaternius OBJ + Kenney GLB Blaster Kit)
	_attach_open_source_weapon_models(gun_rig, wid, cat, col_main, col_accent, false)

	# 10. Articulated First-Person Tactical Arms & Consumable Props
	_build_tactical_fp_arms(gun_rig, legend_data, false, rec_len, false, wid)
	_build_fp_consumable_props(gun_rig)

	root.position = Vector3(0.26, -0.22, -0.52)
	return root

static func create_third_person_weapon_mesh(weapon_data: Dictionary) -> Node3D:
	## Unifies 1st-Person and 3rd-Person Weapon Models so they are 100% identical in geometry, attachments, and materials!
	var wid: String = str(weapon_data.get("id", "r301"))
	var rec_len: float = float(weapon_data.get("rec_len", 0.48))
	var bar_len: float = float(weapon_data.get("barrel_len", 0.38))

	var root := Node3D.new()
	root.name = "TP_Weapon_" + wid

	var vm_full: Node3D = create_viewmodel(weapon_data, false, {}, "2x_bruiser")
	if vm_full != null:
		var gun_rig: Node3D = vm_full.get_node_or_null("GunRig")
		if gun_rig != null:
			vm_full.remove_child(gun_rig)
			gun_rig.position = Vector3.ZERO
			gun_rig.rotation = Vector3.ZERO
			for strip_name in ["LeftArmPivot", "RightArmPivot", "KickLegPivot", "ConsumablePivot"]:
				var n: Node = gun_rig.get_node_or_null(strip_name)
				if n != null:
					gun_rig.remove_child(n)
					n.free()
			root.add_child(gun_rig)
		vm_full.free()

	var mat_flash := _make_mat(Color("#fbbf24"), 0.1, 0.1, true, 5.0)
	var mflash := _add_sphere(root, 0.14, Vector3(0, 0.025, -(0.12 + rec_len * 0.5 + bar_len)), mat_flash, "BotMuzzleFlash")
	_add_cyl(mflash, 0.01, 0.12, 0.24, Vector3(0, 0, -0.12), mat_flash, Vector3(PI * 0.5, 0, 0), 8)
	mflash.visible = false
	return root


static func _populate_heirloom_geometry(h_pivot: Node3D, legend_data: Dictionary) -> void:
	var lid: String = str(legend_data.get("id", "wraith"))
	var h_info: Dictionary = legend_data.get("heirloom", {"color": Color("#ff1e42")})
	var h_col: Color = h_info.get("color", Color("#8b5cf6"))

	var mat_blade := _make_mat(Color("#f8fafc"), 0.94, 0.12)
	var mat_plasma := _make_mat(h_col, 0.4, 0.1, true, 3.6)
	var mat_hilt := _make_mat(Color("#1e293b"), 0.68, 0.34)
	var mat_gold := _make_mat(Color("#f59e0b"), 0.90, 0.18)
	var mat_dark := _make_mat(Color("#0f172a"), 0.78, 0.28)
	var mat_crimson := _make_mat(Color("#991b1b"), 0.45, 0.42)

	match lid:
		"octane":
			# Octane Balisong Butterfly Knife with Stim Needle Vial
			_add_box(h_pivot, Vector3(0.020, 0.16, 0.024), Vector3(-0.018, -0.08, 0), mat_hilt, Vector3(0, 0, 0.08), "HandleLeft")
			_add_box(h_pivot, Vector3(0.020, 0.16, 0.024), Vector3(0.018, -0.08, 0), mat_hilt, Vector3(0, 0, -0.08), "HandleRight")
			_add_cyl(h_pivot, 0.009, 0.009, 0.13, Vector3(-0.018, -0.08, 0), mat_plasma, Vector3.ZERO, 10, "StimVial")
			_add_box(h_pivot, Vector3(0.008, 0.22, 0.032), Vector3(0, 0.11, 0), mat_blade, Vector3.ZERO, "TantoBlade")
			_add_box(h_pivot, Vector3(0.010, 0.22, 0.008), Vector3(0, 0.11, -0.016), mat_plasma, Vector3.ZERO, "PlasmaEdge")
		"bloodhound":
			# Bloodhound Raven's Bite Nordic Battle-Axe
			_add_cyl(h_pivot, 0.017, 0.019, 0.54, Vector3(0, 0.02, 0), mat_hilt, Vector3.ZERO, 12, "AxeShaft")
			_add_cyl(h_pivot, 0.020, 0.020, 0.18, Vector3(0, -0.10, 0), mat_crimson, Vector3.ZERO, 12, "LeatherWrap")
			_add_cyl(h_pivot, 0.024, 0.022, 0.06, Vector3(0, 0.22, 0), mat_gold, Vector3.ZERO, 12, "NordicCollar")
			_add_box(h_pivot, Vector3(0.018, 0.16, 0.18), Vector3(0, 0.20, -0.08), mat_blade, Vector3(0.15, 0, 0), "AxeHead")
			_add_box(h_pivot, Vector3(0.022, 0.18, 0.028), Vector3(0, 0.20, -0.17), mat_plasma, Vector3(0.15, 0, 0), "MoltenEdge")
			_add_cyl(h_pivot, 0.003, 0.022, 0.12, Vector3(0, 0.22, 0.07), mat_gold, Vector3(PI * 0.5, 0, 0), 8, "RavenSpike")
		"pathfinder":
			# Pathfinder Championship Boxing Glove (3rd-person fallback)
			_build_boxing_glove_on_arm(h_pivot, false, h_col)
		"lifeline":
			# Lifeline Shock Sticks (Defibrillator Drumsticks)
			_add_cyl(h_pivot, 0.015, 0.018, 0.42, Vector3(0, 0.05, 0), mat_hilt, Vector3.ZERO, 12, "StickShaft")
			_add_cyl(h_pivot, 0.024, 0.020, 0.08, Vector3(0, -0.12, 0), mat_gold, Vector3.ZERO, 12)
			_add_sphere(h_pivot, 0.032, Vector3(0, 0.27, 0), mat_plasma, "ShockTip")
			_add_ring(h_pivot, 0.036, 0.046, Vector3(0, 0.22, 0), mat_plasma, Vector3.ZERO, 16)
		"gibraltar":
			# Gibraltar War Club (Volcanic Patu Fire-Club)
			_add_cyl(h_pivot, 0.020, 0.022, 0.48, Vector3(0, 0.02, 0), mat_hilt, Vector3.ZERO, 12)
			_add_box(h_pivot, Vector3(0.026, 0.26, 0.15), Vector3(0, 0.18, -0.04), mat_dark, Vector3(0.12, 0, 0), "ClubBlade")
			_add_box(h_pivot, Vector3(0.030, 0.28, 0.028), Vector3(0, 0.18, -0.11), mat_plasma, Vector3(0.12, 0, 0), "MagmaEdge")
		"bangalore":
			# Bangalore Cold Steel Pilot Kukri Machete
			_add_cyl(h_pivot, 0.016, 0.018, 0.16, Vector3(0, -0.06, 0), mat_hilt, Vector3.ZERO, 10)
			_add_box(h_pivot, Vector3(0.024, 0.022, 0.075), Vector3(0, 0.01, -0.01), mat_gold, Vector3.ZERO, "KukriGuard")
			_add_box(h_pivot, Vector3(0.010, 0.16, 0.048), Vector3(0, 0.09, -0.01), mat_blade, Vector3(0.12, 0, 0))
			_add_box(h_pivot, Vector3(0.010, 0.18, 0.058), Vector3(0, 0.23, -0.045), mat_blade, Vector3(0.32, 0, 0), "KukriForwardBelly")
			_add_box(h_pivot, Vector3(0.014, 0.30, 0.012), Vector3(0, 0.16, -0.055), mat_plasma, Vector3(0.22, 0, 0), "ThermalEdge")
		"ash":
			# Ash Strongest Link Cybernetic Dual-Section Nunchaku Blade
			_add_cyl(h_pivot, 0.016, 0.016, 0.22, Vector3(0, -0.02, 0), mat_hilt, Vector3.ZERO, 12)
			_add_box(h_pivot, Vector3(0.010, 0.22, 0.036), Vector3(0, 0.16, -0.01), mat_blade, Vector3.ZERO, "UpperKatanaSection")
			_add_box(h_pivot, Vector3(0.014, 0.22, 0.010), Vector3(0, 0.16, -0.028), mat_plasma)
			_add_cyl(h_pivot, 0.008, 0.008, 0.09, Vector3(-0.03, 0.06, 0.03), mat_plasma, Vector3(0.4, 0, 0.5), 8, "EnergyTetherLink")
		"horizon":
			# Horizon Gravity Maw Singularity Mace
			_add_cyl(h_pivot, 0.018, 0.020, 0.48, Vector3(0, -0.02, 0), mat_hilt, Vector3.ZERO, 12)
			_add_sphere(h_pivot, 0.055, Vector3(0, 0.24, 0), mat_dark, "SingularityCore")
			_add_ring(h_pivot, 0.072, 0.086, Vector3(0, 0.24, 0), mat_plasma, Vector3(0.4, 0, 0.3), 20)
			_add_ring(h_pivot, 0.072, 0.086, Vector3(0, 0.24, 0), mat_gold, Vector3(-0.4, 0, -0.3), 20)
		"valkyrie":
			# Valkyrie Suzaku Winged War-Spear (Sculpted Multi-Faceted Blade, Crimson Grip Wrap, Swept Golden Phoenix Wings!)
			_add_cyl(h_pivot, 0.015, 0.016, 0.92, Vector3(0, -0.04, 0), mat_hilt, Vector3.ZERO, 14, "SpearShaft")
			_add_cyl(h_pivot, 0.017, 0.017, 0.34, Vector3(0, -0.02, 0), mat_crimson, Vector3.ZERO, 14, "CrimsonCordWrap")
			_add_cyl(h_pivot, 0.022, 0.018, 0.06, Vector3(0, 0.22, 0), mat_gold, Vector3.ZERO, 14, "SuzakuCollar")
			# Swept Twin Golden Phoenix Wings on Crossguard
			_add_box(h_pivot, Vector3(0.014, 0.08, 0.09), Vector3(0, 0.25, -0.055), mat_gold, Vector3(-0.45, 0, 0), "PhoenixWingFront")
			_add_box(h_pivot, Vector3(0.014, 0.08, 0.09), Vector3(0, 0.25, 0.055), mat_gold, Vector3(0.45, 0, 0), "PhoenixWingRear")
			# Contoured Double-Edged Silver & Plasma Spearhead (replaces blocky 4-sided pyramid!)
			var blade_core := _add_capsule(h_pivot, 0.016, 0.32, Vector3(0, 0.38, 0), mat_blade, Vector3.ZERO, "SuzakuBladeCore")
			blade_core.scale = Vector3(0.35, 1.0, 1.45)
			var plasma_edge := _add_capsule(h_pivot, 0.018, 0.34, Vector3(0, 0.39, 0), mat_plasma, Vector3.ZERO, "SuzakuPlasmaEdge")
			plasma_edge.scale = Vector3(0.22, 1.02, 1.75)
			_add_cyl(h_pivot, 0.016, 0.003, 0.10, Vector3(0, -0.54, 0), mat_gold, Vector3.ZERO, 10, "PommelCounterSpike")
		"caustic":
			# Caustic Death Hammer with Nox Gas Canister
			_add_cyl(h_pivot, 0.020, 0.022, 0.54, Vector3(0, 0.02, 0), mat_hilt, Vector3.ZERO, 12)
			_add_box(h_pivot, Vector3(0.085, 0.11, 0.22), Vector3(0, 0.24, -0.02), mat_dark, Vector3.ZERO, "HammerSkullHead")
			_add_cyl(h_pivot, 0.032, 0.032, 0.12, Vector3(0, 0.24, 0.08), mat_plasma, Vector3(PI * 0.5, 0, 0), 12, "NoxRearCanister")
		"mirage":
			# Mirage Too Much Witt Golden Statue Trophy
			_add_cyl(h_pivot, 0.048, 0.056, 0.08, Vector3(0, -0.08, 0), mat_dark, Vector3.ZERO, 14, "TrophyPedestal")
			_add_capsule(h_pivot, 0.034, 0.22, Vector3(0, 0.08, 0), mat_gold, Vector3.ZERO, "GoldenMirageTorso")
			_add_sphere(h_pivot, 0.038, Vector3(0, 0.22, 0), mat_gold, "GoldenMirageHead")
			_add_ring(h_pivot, 0.036, 0.045, Vector3(0, 0.24, 0), mat_plasma, Vector3(0.2, 0, 0), 16, "HoloGoggles")
		_:
			# Wraith Hope's Dusk Kunai
			_add_ring(h_pivot, 0.026, 0.038, Vector3(0, -0.16, 0), mat_plasma, Vector3(0, 0, PI * 0.5), 18, "PommelRing")
			_add_cyl(h_pivot, 0.016, 0.018, 0.15, Vector3(0, -0.06, 0), mat_hilt, Vector3.ZERO, 10, "KunaiGrip")
			_add_box(h_pivot, Vector3(0.028, 0.022, 0.082), Vector3(0, 0.02, 0), mat_gold, Vector3.ZERO, "CrossGuard")
			var k_blade := _add_capsule(h_pivot, 0.016, 0.28, Vector3(0, 0.17, 0), mat_blade, Vector3.ZERO, "KunaiBlade")
			k_blade.scale = Vector3(0.28, 1.0, 1.35)
			var k_edge := _add_capsule(h_pivot, 0.018, 0.29, Vector3(0, 0.17, 0), mat_plasma, Vector3.ZERO, "VoidEdge")
			k_edge.scale = Vector3(0.18, 1.02, 1.65)


static func create_third_person_heirloom_mesh(legend_data: Dictionary) -> Node3D:
	## Builds a 3rd-Person Held Heirloom Mesh for the character's right hand when Slot 3 is active!
	var root := Node3D.new()
	root.name = "TP_Heirloom"
	_populate_heirloom_geometry(root, legend_data)
	root.scale = Vector3(1.18, 1.18, 1.18)
	return root


static func create_heirloom_rig(legend_data: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "FP_Viewmodel"

	var gun_rig := Node3D.new()
	gun_rig.name = "GunRig"
	root.add_child(gun_rig)

	var h_pivot := Node3D.new()
	h_pivot.name = "HeirloomPivot"
	gun_rig.add_child(h_pivot)

	var h_info: Dictionary = legend_data.get("heirloom", {"color": Color("#ff1e42")})
	var h_col: Color = h_info.get("color", Color("#8b5cf6"))

	_populate_heirloom_geometry(h_pivot, legend_data)

	h_pivot.position = Vector3(0.04, -0.02, -0.06)
	h_pivot.rotation = Vector3(0.32, -0.28, 0.18)

	_build_tactical_fp_arms(gun_rig, legend_data, true, 0.48, false)
	_build_fp_consumable_props(gun_rig)

	var light := OmniLight3D.new()
	light.light_color = h_col
	light.light_energy = 1.6
	light.omni_range = 2.0
	h_pivot.add_child(light)

	root.position = Vector3(0.24, -0.22, -0.46)
	return root

# ==============================================================================
# OPEN-SOURCE 3D ASSET LOADERS (QUATERNIUS OBJ + KENNEY GLB + UAL1_STANDARD.GLB)
# ==============================================================================
static func get_open_source_weapon_mapping(wid: String) -> Dictionary:
	match wid:
		"p2020":
			return {"obj": "Pistol.obj", "glb": "blaster-b.glb", "scale": Vector3(0.88, 0.88, 0.88), "offset": Vector3(0.0, 0.005, -0.02)}
		"re45":
			return {"obj": "Pistol.obj", "glb": "blaster-i.glb", "scale": Vector3(0.94, 0.94, 0.95), "offset": Vector3(0.0, 0.005, -0.03)}
		"alternator":
			return {"obj": "P90.obj", "glb": "blaster-o.glb", "scale": Vector3(0.76, 0.82, 0.72), "offset": Vector3(0.0, 0.008, -0.04)}
		"wingman":
			return {"obj": "Revolver.obj", "glb": "blaster-c.glb", "scale": Vector3(0.95, 0.95, 0.95), "offset": Vector3(0.0, 0.008, -0.03)}
		"mozambique":
			return {"obj": "Shotgun.obj", "glb": "blaster-k.glb", "scale": Vector3(0.62, 0.75, 0.55), "offset": Vector3(0.0, 0.006, -0.04)}
		"r99":
			return {"obj": "P90.obj", "glb": "blaster-h.glb", "scale": Vector3(0.86, 0.88, 0.86), "offset": Vector3(0.0, 0.008, -0.06)}
		"car":
			return {"obj": "P90.obj", "glb": "blaster-j.glb", "scale": Vector3(0.90, 0.90, 0.90), "offset": Vector3(0.0, 0.008, -0.06)}
		"volt":
			return {"obj": "P90.obj", "glb": "blaster-l.glb", "scale": Vector3(0.92, 0.90, 0.94), "offset": Vector3(0.0, 0.008, -0.07)}
		"prowler":
			return {"obj": "P90.obj", "glb": "blaster-m.glb", "scale": Vector3(1.02, 0.98, 0.96), "offset": Vector3(0.0, 0.010, -0.05)}
		"r301":
			return {"obj": "Rifle.obj", "glb": "blaster-a.glb", "scale": Vector3(0.95, 0.95, 0.95), "offset": Vector3(0.0, 0.008, -0.08)}
		"flatline":
			return {"obj": "Rifle.obj", "glb": "blaster-r.glb", "scale": Vector3(0.98, 0.96, 0.92), "offset": Vector3(0.0, 0.008, -0.06)}
		"hemlok":
			return {"obj": "Rifle.obj", "glb": "blaster-d.glb", "scale": Vector3(0.96, 0.96, 1.00), "offset": Vector3(0.0, 0.008, -0.09)}
		"havoc":
			return {"obj": "Rifle.obj", "glb": "blaster-n.glb", "scale": Vector3(1.02, 1.00, 0.96), "offset": Vector3(0.0, 0.008, -0.08)}
		"nemesis":
			return {"obj": "Rifle.obj", "glb": "blaster-g.glb", "scale": Vector3(1.00, 0.98, 1.04), "offset": Vector3(0.0, 0.008, -0.10)}
		"lstar":
			return {"obj": "Rifle.obj", "glb": "blaster-p.glb", "scale": Vector3(1.12, 1.08, 0.96), "offset": Vector3(0.0, 0.010, -0.08)}
		"spitfire":
			return {"obj": "Rifle.obj", "glb": "blaster-p.glb", "scale": Vector3(1.08, 1.05, 1.06), "offset": Vector3(0.0, 0.010, -0.10)}
		"devotion":
			return {"obj": "Rifle.obj", "glb": "blaster-d.glb", "scale": Vector3(1.06, 1.04, 1.04), "offset": Vector3(0.0, 0.010, -0.09)}
		"rampage":
			return {"obj": "Rifle.obj", "glb": "blaster-p.glb", "scale": Vector3(1.05, 1.02, 1.10), "offset": Vector3(0.0, 0.010, -0.11)}
		"g7":
			return {"obj": "SniperRifle.obj", "glb": "blaster-d.glb", "scale": Vector3(0.90, 0.92, 0.86), "offset": Vector3(0.0, 0.008, -0.10)}
		"repeater3030":
			return {"obj": "SniperRifle.obj", "glb": "blaster-g.glb", "scale": Vector3(0.88, 0.90, 0.88), "offset": Vector3(0.0, 0.008, -0.10)}
		"tripletake":
			return {"obj": "SniperRifle.obj", "glb": "blaster-f.glb", "scale": Vector3(1.06, 0.94, 0.92), "offset": Vector3(0.0, 0.008, -0.11)}
		"chargerifle":
			return {"obj": "SniperRifle.obj", "glb": "blaster-f.glb", "scale": Vector3(1.04, 1.02, 0.96), "offset": Vector3(0.0, 0.010, -0.12)}
		"longbow":
			return {"obj": "SniperRifle.obj", "glb": "blaster-e.glb", "scale": Vector3(0.94, 0.96, 0.96), "offset": Vector3(0.0, 0.008, -0.12)}
		"sentinel":
			return {"obj": "SniperRifle.obj", "glb": "blaster-e.glb", "scale": Vector3(0.98, 0.98, 1.02), "offset": Vector3(0.0, 0.008, -0.13)}
		"kraber":
			return {"obj": "SniperRifle.obj", "glb": "blaster-e.glb", "scale": Vector3(1.08, 1.06, 1.12), "offset": Vector3(0.0, 0.012, -0.15)}
		"eva8":
			return {"obj": "Shotgun.obj", "glb": "blaster-q.glb", "scale": Vector3(1.04, 1.04, 0.92), "offset": Vector3(0.0, 0.008, -0.07)}
		"mastiff":
			return {"obj": "Shotgun.obj", "glb": "blaster-q.glb", "scale": Vector3(1.08, 0.96, 0.98), "offset": Vector3(0.0, 0.008, -0.08)}
		"peacekeeper":
			return {"obj": "Shotgun.obj", "glb": "blaster-g.glb", "scale": Vector3(0.96, 0.98, 0.95), "offset": Vector3(0.0, 0.008, -0.08)}
	return {"obj": "Rifle.obj", "glb": "blaster-a.glb", "scale": Vector3.ONE, "offset": Vector3(0.0, 0.008, -0.08)}

static func load_quaternius_obj_mesh(obj_file: String, col_main: Color, col_accent: Color) -> ArrayMesh:
	var cache_key: String = obj_file + "_" + col_main.to_html(false) + "_" + col_accent.to_html(false)
	if _quaternius_obj_cache.has(cache_key):
		return _quaternius_obj_cache[cache_key]

	var res_path: String = "res://assets/models/quaternius_guns/" + obj_file
	if not FileAccess.file_exists(res_path):
		return null
	var f := FileAccess.open(res_path, FileAccess.READ)
	if f == null:
		return null

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var mat_faces: Dictionary = {}
	var cur_mtl: String = "Metal"

	while not f.eof_reached():
		var line: String = f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with("v "):
			var p: PackedStringArray = line.split(" ", false)
			if p.size() >= 4:
				verts.append(Vector3(p[1].to_float(), p[2].to_float(), p[3].to_float()))
		elif line.begins_with("vn "):
			var p: PackedStringArray = line.split(" ", false)
			if p.size() >= 4:
				norms.append(Vector3(p[1].to_float(), p[2].to_float(), p[3].to_float()))
		elif line.begins_with("vt "):
			var p: PackedStringArray = line.split(" ", false)
			if p.size() >= 3:
				uvs.append(Vector2(p[1].to_float(), p[2].to_float()))
		elif line.begins_with("usemtl "):
			cur_mtl = line.substr(7).strip_edges()
			if not mat_faces.has(cur_mtl):
				mat_faces[cur_mtl] = []
		elif line.begins_with("f "):
			if not mat_faces.has(cur_mtl):
				mat_faces[cur_mtl] = []
			var p: PackedStringArray = line.split(" ", false)
			if p.size() >= 4:
				(mat_faces[cur_mtl] as Array).append([p[1], p[2], p[3]])

	var arr_mesh := ArrayMesh.new()
	for mtl_name in mat_faces.keys():
		var faces: Array = mat_faces[mtl_name]
		if faces.is_empty():
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for tri in faces:
			for tok in tri:
				var sub: PackedStringArray = str(tok).split("/")
				var vi: int = sub[0].to_int() - 1
				if sub.size() > 1 and sub[1] != "":
					var uvi: int = sub[1].to_int() - 1
					if uvi >= 0 and uvi < uvs.size():
						st.set_uv(uvs[uvi])
				if sub.size() > 2 and sub[2] != "":
					var ni: int = sub[2].to_int() - 1
					if ni >= 0 and ni < norms.size():
						st.set_normal(norms[ni])
				if vi >= 0 and vi < verts.size():
					st.add_vertex(verts[vi])
		st.generate_normals()
		var mat: StandardMaterial3D
		match str(mtl_name):
			"Black", "DarkerMetal", "DarkMetal", "Trigger", "Muzzle":
				mat = _make_mat(Color("#111827"), 0.72, 0.34)
			"Wood", "DarkWood", "LightWood":
				mat = _make_mat(col_main.lerp(Color("#78350f"), 0.55), 0.35, 0.52)
			"Green", "Material.001":
				mat = _make_mat(col_main, 0.78, 0.24)
			"Magazine", "Material.003":
				mat = _make_mat(col_accent.darkened(0.25), 0.70, 0.28)
			"BulletYellow", "BulletOrange", "BulletRed", "BulletTip", "Material.004":
				mat = _make_mat(col_accent, 0.65, 0.20, true, 2.2)
			_:
				mat = _make_mat(col_main.lerp(Color("#94a3b8"), 0.45), 0.88, 0.20)
		st.set_material(mat)
		st.commit(arr_mesh)

	_quaternius_obj_cache[cache_key] = arr_mesh
	return arr_mesh

static func instantiate_kenney_glb(glb_file: String, col_main: Color, col_accent: Color) -> Node3D:
	var res_path: String = "res://assets/models/kenney_blasters/" + glb_file
	var proto: Node3D = null
	if _kenney_glb_cache.has(glb_file):
		var cached_node: Node3D = _kenney_glb_cache[glb_file]
		if is_instance_valid(cached_node):
			proto = cached_node.duplicate()
	if proto == null:
		if ResourceLoader.exists(res_path):
			var packed := load(res_path) as PackedScene
			if packed != null:
				var inst := packed.instantiate() as Node3D
				if inst != null:
					_kenney_glb_cache[glb_file] = inst
					proto = inst.duplicate()
		if proto == null and FileAccess.file_exists(res_path):
			var doc := GLTFDocument.new()
			var state := GLTFState.new()
			var abs_p: String = ProjectSettings.globalize_path(res_path)
			if doc.append_from_file(abs_p, state) == OK:
				var gen := doc.generate_scene(state) as Node3D
				if gen != null:
					_kenney_glb_cache[glb_file] = gen
					proto = gen.duplicate()
	if proto != null:
		var mat_accent := _make_mat(col_main.lerp(col_accent, 0.25), 0.76, 0.24)
		for child in proto.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi and mi.material_override == null:
				mi.material_override = mat_accent
	return proto

static func _attach_open_source_weapon_models(target_node: Node3D, wid: String, _cat: String, col_main: Color, col_accent: Color, is_tp: bool = false) -> void:
	var map_info: Dictionary = get_open_source_weapon_mapping(wid)
	var os_holder := Node3D.new()
	os_holder.name = "OpenSourceWeaponMesh"
	os_holder.position = map_info.get("offset", Vector3(0.0, 0.008, -0.06))
	os_holder.scale = map_info.get("scale", Vector3.ONE) * (0.92 if is_tp else 1.0)
	target_node.add_child(os_holder)

	# 1. Attach Quaternius Open-Source OBJ Receiver Mesh
	var obj_name: String = str(map_info.get("obj", "Rifle.obj"))
	var q_mesh: ArrayMesh = load_quaternius_obj_mesh(obj_name, col_main, col_accent)
	if q_mesh != null:
		var q_mi := MeshInstance3D.new()
		q_mi.name = "QuaterniusObjMesh"
		q_mi.mesh = q_mesh
		q_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if not is_tp else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		os_holder.add_child(q_mi)

	# 2. Attach Kenney Open-Source GLB Blaster Kit Modular Detail
	var glb_name: String = str(map_info.get("glb", "blaster-a.glb"))
	var k_node: Node3D = instantiate_kenney_glb(glb_name, col_main, col_accent)
	if k_node != null:
		k_node.name = "KenneyGlbBlaster"
		k_node.scale = Vector3(0.52, 0.52, 0.52)
		os_holder.add_child(k_node)

# ==============================================================================
# UAL1_STANDARD.GLB OPEN-SOURCE MOCAP LIBRARY & 28-WEAPON GRIP PROFILES
# ==============================================================================
static func sample_vec3(p: float, keys: Array) -> Vector3:
	if keys.is_empty():
		return Vector3.ZERO
	if p <= float(keys[0][0]):
		return keys[0][1]
	for i in range(keys.size() - 1):
		var t0: float = float(keys[i][0])
		var t1: float = float(keys[i + 1][0])
		if p <= t1:
			var local_u: float = clampf((p - t0) / maxf(0.0001, t1 - t0), 0.0, 1.0)
			var smooth_u: float = local_u * local_u * (3.0 - 2.0 * local_u)
			return (keys[i][1] as Vector3).lerp(keys[i + 1][1] as Vector3, smooth_u)
	return keys[keys.size() - 1][1]

static func load_ual_standard_animations() -> Node3D:
	if is_instance_valid(_ual_gltf_root):
		return _ual_gltf_root
	var ual_path: String = "res://assets/animations/UAL1_Standard.glb"
	if ResourceLoader.exists(ual_path):
		var packed := load(ual_path) as PackedScene
		if packed != null:
			_ual_gltf_root = packed.instantiate() as Node3D
			return _ual_gltf_root
	if FileAccess.file_exists(ual_path):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(ProjectSettings.globalize_path(ual_path), state) == OK:
			_ual_gltf_root = doc.generate_scene(state) as Node3D
	return _ual_gltf_root

static func build_godot_animation_library() -> AnimationLibrary:
	var lib := AnimationLibrary.new()
	# Exact motion-capture tracks extracted from Universal Animation Library (UAL1_Standard.glb)
	var clips := {
		"UAL1_Punch_Jab": [
			[0.00, Vector3(-0.42, -0.02, -0.06), Vector3(0.38, 0.22, 0.18)],
			[0.15, Vector3(-0.44, -0.03, -0.02), Vector3(0.35, 0.21, 0.20)],
			[0.35, Vector3(-0.22, 0.04, -0.48), Vector3(-0.16, 0.55, -1.25)],
			[0.50, Vector3(-0.24, 0.03, -0.42), Vector3(-0.08, 0.46, -1.05)],
			[0.69, Vector3(-0.36, -0.01, -0.18), Vector3(0.10, 0.10, 0.16)],
			[1.00, Vector3(-0.42, -0.02, -0.06), Vector3(0.38, 0.22, 0.18)]
		],
		"UAL1_Punch_Cross": [
			[0.00, Vector3(-0.04, -0.02, -0.04), Vector3(0.40, -0.22, -0.18)],
			[0.17, Vector3(0.08, -0.01, 0.04), Vector3(0.42, -0.38, -0.35)],
			[0.33, Vector3(-0.28, 0.05, -0.50), Vector3(0.61, -0.68, 1.38)],
			[0.50, Vector3(-0.26, 0.04, -0.44), Vector3(0.57, -0.65, 1.22)],
			[0.67, Vector3(-0.12, -0.01, -0.18), Vector3(0.38, -0.52, 0.65)],
			[1.00, Vector3(-0.04, -0.02, -0.04), Vector3(0.40, -0.22, -0.18)]
		],
		"UAL1_Sword_Attack": [
			[0.00, Vector3(0.04, -0.02, -0.06), Vector3(0.32, -0.28, 0.18)],
			[0.15, Vector3(0.14, 0.10, 0.02), Vector3(0.48, -0.30, -0.82)],
			[0.33, Vector3(-0.26, -0.14, -0.42), Vector3(-0.78, 0.72, 1.15)],
			[0.50, Vector3(-0.22, -0.12, -0.38), Vector3(-0.52, 0.60, 0.92)],
			[0.67, Vector3(-0.04, -0.06, -0.16), Vector3(0.18, 0.12, -0.10)],
			[1.00, Vector3(0.04, -0.02, -0.06), Vector3(0.32, -0.28, 0.18)]
		]
	}
	for clip_name in clips.keys():
		var anim := Animation.new()
		anim.length = 0.55
		var pos_track := anim.add_track(Animation.TYPE_POSITION_3D)
		anim.track_set_path(pos_track, NodePath("RightArmPivot:position"))
		var rot_track := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(rot_track, NodePath("RightArmPivot:rotation"))
		for k in clips[clip_name]:
			var t: float = float(k[0]) * anim.length
			anim.position_track_insert_key(pos_track, t, k[1])
			anim.rotation_track_insert_key(rot_track, t, Quaternion.from_euler(k[2] as Vector3))
		lib.add_animation(clip_name, anim)
	return lib

# 28 Unique Firearm Grip Postures in GunRig Local Space & Radians (1st-Person + 3rd-Person)
static func get_weapon_grip_profile(wid: String) -> Dictionary:
	match wid:
		# PISTOLS — Two-handed Weaver / Cup-and-Saucer right on the pistol grip (NO floating left hand in mid-air!)
		"p2020":
			return {
				"style": "pistol_weaver_compact",
				"left_pos": Vector3(-0.020, -0.102, 0.052), "left_rot": Vector3(0.32, 0.42, -0.22),
				"right_pos": Vector3(0.018, -0.090, 0.065), "right_rot": Vector3(0.08, -0.05, 0.04),
				"vm_pos": Vector3(0.19, -0.20, -0.42), "vm_rot": Vector3(0.0, 0.03, -0.06),
				"sprint_rot": Vector3(0.58, 0.18, -0.22),
				"tp_left_arm": Vector3(0.88, 0.62, -0.18), "tp_left_elbow": Vector3(0.95, 0.34, 0.0),
				"tp_right_arm": Vector3(0.84, -0.16, 0.06), "tp_right_elbow": Vector3(0.68, -0.12, 0.0)
			}
		"re45":
			return {
				"style": "pistol_canted_machine",
				"left_pos": Vector3(-0.024, -0.106, 0.045), "left_rot": Vector3(0.36, 0.46, -0.35),
				"right_pos": Vector3(0.020, -0.092, 0.062), "right_rot": Vector3(0.10, -0.08, 0.22),
				"vm_pos": Vector3(0.20, -0.21, -0.44), "vm_rot": Vector3(0.03, 0.08, 0.24),
				"sprint_rot": Vector3(0.64, -0.16, 0.28),
				"tp_left_arm": Vector3(0.90, 0.60, -0.24), "tp_left_elbow": Vector3(0.98, 0.32, 0.12),
				"tp_right_arm": Vector3(0.86, -0.20, 0.18), "tp_right_elbow": Vector3(0.72, -0.14, 0.14)
			}
		"alternator":
			return {
				"style": "smg_twin_barrel_receiver_cup",
				"left_pos": Vector3(-0.030, -0.082, -0.055), "left_rot": Vector3(0.28, 0.36, -0.28),
				"right_pos": Vector3(0.020, -0.096, 0.078), "right_rot": Vector3(0.06, -0.06, 0.08),
				"vm_pos": Vector3(0.22, -0.22, -0.46), "vm_rot": Vector3(0.02, 0.05, 0.10),
				"sprint_rot": Vector3(0.48, -0.34, 0.22),
				"tp_left_arm": Vector3(0.82, 0.56, -0.20), "tp_left_elbow": Vector3(0.92, 0.28, 0.0),
				"tp_right_arm": Vector3(0.72, -0.18, 0.08), "tp_right_elbow": Vector3(0.78, -0.14, 0.0)
			}
		"wingman":
			return {
				"style": "revolver_heavy_cup_saucer",
				"left_pos": Vector3(-0.018, -0.118, 0.058), "left_rot": Vector3(0.45, 0.48, -0.16),
				"right_pos": Vector3(0.022, -0.088, 0.068), "right_rot": Vector3(0.04, -0.04, -0.08),
				"vm_pos": Vector3(0.20, -0.21, -0.44), "vm_rot": Vector3(-0.03, 0.02, -0.08),
				"sprint_rot": Vector3(0.68, 0.12, -0.16),
				"tp_left_arm": Vector3(0.86, 0.64, -0.14), "tp_left_elbow": Vector3(1.02, 0.36, 0.0),
				"tp_right_arm": Vector3(0.90, -0.12, -0.06), "tp_right_elbow": Vector3(0.62, -0.10, 0.0)
			}
		"mozambique":
			return {
				"style": "shotgun_pistol_forend_brace",
				"left_pos": Vector3(-0.034, -0.072, -0.095), "left_rot": Vector3(0.26, 0.34, -0.32),
				"right_pos": Vector3(0.020, -0.095, 0.072), "right_rot": Vector3(0.06, -0.06, 0.06),
				"vm_pos": Vector3(0.22, -0.22, -0.46), "vm_rot": Vector3(0.02, 0.04, 0.06),
				"sprint_rot": Vector3(0.52, -0.28, 0.18),
				"tp_left_arm": Vector3(0.80, 0.54, -0.22), "tp_left_elbow": Vector3(0.90, 0.26, 0.0),
				"tp_right_arm": Vector3(0.76, -0.16, 0.06), "tp_right_elbow": Vector3(0.74, -0.12, 0.0)
			}
		# SMGs — Magwell Brace, High C-Clamp Thumb-Over-Bore, Energy Shroud Cradle, Bullpup Vertical Foregrip
		"r99":
			return {
				"style": "smg_angled_magwell_brace",
				"left_pos": Vector3(-0.032, -0.088, -0.092), "left_rot": Vector3(0.32, 0.30, -0.38),
				"right_pos": Vector3(0.020, -0.098, 0.088), "right_rot": Vector3(0.06, -0.08, 0.06),
				"vm_pos": Vector3(0.24, -0.23, -0.49), "vm_rot": Vector3(0.02, 0.03, 0.06),
				"sprint_rot": Vector3(0.32, -0.52, 0.26),
				"tp_left_arm": Vector3(0.76, 0.52, -0.22), "tp_left_elbow": Vector3(0.94, 0.26, 0.0),
				"tp_right_arm": Vector3(0.62, -0.20, 0.08), "tp_right_elbow": Vector3(0.84, -0.16, 0.0)
			}
		"car":
			return {
				"style": "smg_high_c_clamp_thumb_over_bore",
				"left_pos": Vector3(-0.052, -0.018, -0.185), "left_rot": Vector3(0.16, 0.26, -0.72),
				"right_pos": Vector3(0.020, -0.096, 0.092), "right_rot": Vector3(0.08, -0.10, 0.10),
				"vm_pos": Vector3(0.24, -0.22, -0.49), "vm_rot": Vector3(0.03, 0.05, 0.11),
				"sprint_rot": Vector3(-0.24, 0.58, -0.22),
				"tp_left_arm": Vector3(0.84, 0.48, -0.32), "tp_left_elbow": Vector3(0.86, 0.22, 0.16),
				"tp_right_arm": Vector3(0.64, -0.22, 0.10), "tp_right_elbow": Vector3(0.82, -0.16, 0.0)
			}
		"volt":
			return {
				"style": "smg_energy_shroud_cradle",
				"left_pos": Vector3(-0.044, -0.048, -0.175), "left_rot": Vector3(0.22, 0.28, -0.44),
				"right_pos": Vector3(0.020, -0.098, 0.095), "right_rot": Vector3(0.05, -0.07, 0.05),
				"vm_pos": Vector3(0.25, -0.23, -0.50), "vm_rot": Vector3(0.01, 0.02, 0.04),
				"sprint_rot": Vector3(-0.22, 0.52, -0.18),
				"tp_left_arm": Vector3(0.78, 0.52, -0.24), "tp_left_elbow": Vector3(0.88, 0.24, 0.0),
				"tp_right_arm": Vector3(0.60, -0.20, 0.06), "tp_right_elbow": Vector3(0.82, -0.14, 0.0)
			}
		"prowler":
			return {
				"style": "bullpup_front_vertical_thumbhole_grip",
				"left_pos": Vector3(-0.026, -0.096, -0.155), "left_rot": Vector3(0.48, 0.24, -0.12),
				"right_pos": Vector3(0.018, -0.102, 0.065), "right_rot": Vector3(0.12, -0.06, 0.04),
				"vm_pos": Vector3(0.23, -0.24, -0.47), "vm_rot": Vector3(0.02, 0.02, -0.04),
				"sprint_rot": Vector3(0.38, -0.46, 0.22),
				"tp_left_arm": Vector3(0.74, 0.46, -0.14), "tp_left_elbow": Vector3(1.02, 0.20, 0.0),
				"tp_right_arm": Vector3(0.66, -0.18, 0.04), "tp_right_elbow": Vector3(0.88, -0.14, 0.0)
			}
		# ASSAULT RIFLES — Tactical C-Clamp, Bullpup Wood Palm-Under, Angled Burst Foregrip, Wide Turbo Shroud
		"r301":
			return {
				"style": "ar_tactical_c_clamp",
				"left_pos": Vector3(-0.052, -0.036, -0.205), "left_rot": Vector3(0.20, 0.26, -0.54),
				"right_pos": Vector3(0.020, -0.100, 0.105), "right_rot": Vector3(0.05, -0.08, 0.05),
				"vm_pos": Vector3(0.25, -0.22, -0.52), "vm_rot": Vector3(0.01, 0.02, 0.04),
				"sprint_rot": Vector3(0.24, 0.44, -0.24),
				"tp_left_arm": Vector3(0.78, 0.54, -0.24), "tp_left_elbow": Vector3(0.88, 0.24, 0.0),
				"tp_right_arm": Vector3(0.58, -0.22, 0.08), "tp_right_elbow": Vector3(0.82, -0.16, 0.0)
			}
		"flatline":
			return {
				"style": "bullpup_ak_heavy_wood_palm_under",
				"left_pos": Vector3(-0.042, -0.068, -0.185), "left_rot": Vector3(0.32, 0.22, -0.28),
				"right_pos": Vector3(0.022, -0.104, 0.075), "right_rot": Vector3(0.08, -0.06, -0.05),
				"vm_pos": Vector3(0.26, -0.23, -0.50), "vm_rot": Vector3(-0.02, 0.02, -0.05),
				"sprint_rot": Vector3(0.28, 0.48, -0.28),
				"tp_left_arm": Vector3(0.74, 0.50, -0.18), "tp_left_elbow": Vector3(0.92, 0.22, 0.0),
				"tp_right_arm": Vector3(0.56, -0.18, -0.04), "tp_right_elbow": Vector3(0.86, -0.14, 0.0)
			}
		"hemlok":
			return {
				"style": "ar_angled_foregrip_burst_brace",
				"left_pos": Vector3(-0.046, -0.075, -0.215), "left_rot": Vector3(0.36, 0.24, -0.24),
				"right_pos": Vector3(0.020, -0.100, 0.108), "right_rot": Vector3(0.04, -0.08, 0.04),
				"vm_pos": Vector3(0.25, -0.22, -0.53), "vm_rot": Vector3(0.0, 0.03, 0.03),
				"sprint_rot": Vector3(0.22, 0.42, -0.22),
				"tp_left_arm": Vector3(0.76, 0.52, -0.20), "tp_left_elbow": Vector3(0.86, 0.24, 0.0),
				"tp_right_arm": Vector3(0.58, -0.20, 0.06), "tp_right_elbow": Vector3(0.82, -0.16, 0.0)
			}
		"havoc":
			return {
				"style": "ar_turbo_coil_wide_shroud_grip",
				"left_pos": Vector3(-0.062, -0.055, -0.195), "left_rot": Vector3(0.26, 0.32, -0.48),
				"right_pos": Vector3(0.022, -0.102, 0.105), "right_rot": Vector3(0.06, -0.09, 0.06),
				"vm_pos": Vector3(0.26, -0.23, -0.52), "vm_rot": Vector3(0.02, 0.04, 0.07),
				"sprint_rot": Vector3(0.26, 0.46, -0.25),
				"tp_left_arm": Vector3(0.78, 0.56, -0.26), "tp_left_elbow": Vector3(0.88, 0.28, 0.0),
				"tp_right_arm": Vector3(0.60, -0.22, 0.10), "tp_right_elbow": Vector3(0.82, -0.16, 0.0)
			}
		"nemesis":
			return {
				"style": "ar_energy_heat_sink_forward_clamp",
				"left_pos": Vector3(-0.056, -0.042, -0.235), "left_rot": Vector3(0.18, 0.24, -0.58),
				"right_pos": Vector3(0.020, -0.100, 0.112), "right_rot": Vector3(0.04, -0.07, 0.05),
				"vm_pos": Vector3(0.25, -0.22, -0.54), "vm_rot": Vector3(0.01, 0.02, 0.05),
				"sprint_rot": Vector3(0.25, 0.45, -0.24),
				"tp_left_arm": Vector3(0.80, 0.54, -0.28), "tp_left_elbow": Vector3(0.84, 0.24, 0.0),
				"tp_right_arm": Vector3(0.58, -0.20, 0.08), "tp_right_elbow": Vector3(0.80, -0.16, 0.0)
			}
		# LMGs — Left-Side Chainsaw Handle (L-STAR), Heavy Low-Hip Support (Spitfire), Side-Box Clearance (Devotion)
		"lstar":
			return {
				"style": "lmg_left_side_chainsaw_handle_grip",
				"left_pos": Vector3(-0.088, 0.012, -0.155), "left_rot": Vector3(0.14, 0.42, -0.96),
				"right_pos": Vector3(0.024, -0.106, 0.102), "right_rot": Vector3(0.08, -0.10, 0.10),
				"vm_pos": Vector3(0.27, -0.24, -0.51), "vm_rot": Vector3(0.04, 0.06, 0.12),
				"sprint_rot": Vector3(0.18, 0.38, -0.16),
				"tp_left_arm": Vector3(0.72, 0.64, -0.42), "tp_left_elbow": Vector3(0.92, 0.36, 0.22),
				"tp_right_arm": Vector3(0.52, -0.24, 0.12), "tp_right_elbow": Vector3(0.86, -0.18, 0.0)
			}
		"spitfire":
			return {
				"style": "lmg_heavy_low_hip_barrel_support",
				"left_pos": Vector3(-0.058, -0.092, -0.225), "left_rot": Vector3(0.38, 0.24, -0.32),
				"right_pos": Vector3(0.026, -0.112, 0.125), "right_rot": Vector3(0.10, -0.06, 0.04),
				"vm_pos": Vector3(0.28, -0.26, -0.53), "vm_rot": Vector3(-0.02, 0.03, -0.04),
				"sprint_rot": Vector3(0.32, 0.52, -0.30),
				"tp_left_arm": Vector3(0.66, 0.48, -0.18), "tp_left_elbow": Vector3(0.96, 0.22, 0.0),
				"tp_right_arm": Vector3(0.48, -0.16, 0.04), "tp_right_elbow": Vector3(0.92, -0.14, 0.0)
			}
		"devotion":
			return {
				"style": "lmg_side_box_mag_clearance_brace",
				"left_pos": Vector3(-0.072, -0.078, -0.205), "left_rot": Vector3(0.30, 0.34, -0.46),
				"right_pos": Vector3(0.024, -0.108, 0.118), "right_rot": Vector3(0.08, -0.08, 0.06),
				"vm_pos": Vector3(0.27, -0.25, -0.52), "vm_rot": Vector3(0.01, 0.04, 0.05),
				"sprint_rot": Vector3(0.30, 0.50, -0.28),
				"tp_left_arm": Vector3(0.68, 0.54, -0.24), "tp_left_elbow": Vector3(0.94, 0.28, 0.0),
				"tp_right_arm": Vector3(0.50, -0.18, 0.06), "tp_right_elbow": Vector3(0.90, -0.16, 0.0)
			}
		"rampage":
			return {
				"style": "lmg_thermite_chamber_under_rail_grip",
				"left_pos": Vector3(-0.050, -0.086, -0.245), "left_rot": Vector3(0.34, 0.22, -0.28),
				"right_pos": Vector3(0.024, -0.110, 0.128), "right_rot": Vector3(0.08, -0.06, 0.03),
				"vm_pos": Vector3(0.28, -0.25, -0.54), "vm_rot": Vector3(-0.02, 0.02, -0.03),
				"sprint_rot": Vector3(0.34, 0.52, -0.28),
				"tp_left_arm": Vector3(0.68, 0.46, -0.16), "tp_left_elbow": Vector3(0.92, 0.20, 0.0),
				"tp_right_arm": Vector3(0.48, -0.16, 0.04), "tp_right_elbow": Vector3(0.90, -0.14, 0.0)
			}
		# MARKSMAN — Long Forend Cradle, Winchester Lever Loop, Wide Triple-Barrel Palm, Vertical Bow Riser
		"g7":
			return {
				"style": "marksman_long_forend_precision_cradle",
				"left_pos": Vector3(-0.046, -0.052, -0.235), "left_rot": Vector3(0.26, 0.22, -0.36),
				"right_pos": Vector3(0.020, -0.100, 0.115), "right_rot": Vector3(0.04, -0.06, 0.03),
				"vm_pos": Vector3(0.24, -0.22, -0.54), "vm_rot": Vector3(0.0, 0.02, 0.02),
				"sprint_rot": Vector3(0.26, 0.46, -0.22),
				"tp_left_arm": Vector3(0.80, 0.50, -0.20), "tp_left_elbow": Vector3(0.84, 0.22, 0.0),
				"tp_right_arm": Vector3(0.60, -0.18, 0.06), "tp_right_elbow": Vector3(0.80, -0.14, 0.0)
			}
		"repeater3030":
			return {
				"style": "marksman_lever_action_loop_grip",
				"left_pos": Vector3(-0.042, -0.058, -0.245), "left_rot": Vector3(0.28, 0.20, -0.30),
				"right_pos": Vector3(0.022, -0.104, 0.118), "right_rot": Vector3(0.02, -0.04, -0.05),
				"vm_pos": Vector3(0.24, -0.23, -0.55), "vm_rot": Vector3(-0.02, 0.01, -0.04),
				"sprint_rot": Vector3(0.28, 0.44, -0.20),
				"tp_left_arm": Vector3(0.78, 0.48, -0.18), "tp_left_elbow": Vector3(0.82, 0.20, 0.0),
				"tp_right_arm": Vector3(0.58, -0.14, -0.04), "tp_right_elbow": Vector3(0.82, -0.12, 0.0)
			}
		"tripletake":
			return {
				"style": "marksman_wide_triple_barrel_flat_palm",
				"left_pos": Vector3(-0.060, -0.056, -0.240), "left_rot": Vector3(0.30, 0.26, -0.20),
				"right_pos": Vector3(0.022, -0.102, 0.118), "right_rot": Vector3(0.04, -0.06, 0.02),
				"vm_pos": Vector3(0.25, -0.22, -0.55), "vm_rot": Vector3(0.0, 0.02, 0.02),
				"sprint_rot": Vector3(0.27, 0.46, -0.22),
				"tp_left_arm": Vector3(0.78, 0.54, -0.16), "tp_left_elbow": Vector3(0.84, 0.26, 0.0),
				"tp_right_arm": Vector3(0.58, -0.16, 0.04), "tp_right_elbow": Vector3(0.82, -0.14, 0.0)
			}
		"bocek":
			return {
				"style": "bow_vertical_riser_left_draw_right",
				"left_pos": Vector3(-0.020, -0.040, -0.140), "left_rot": Vector3(0.12, 0.18, -0.24),
				"right_pos": Vector3(0.030, -0.020, 0.100), "right_rot": Vector3(0.16, -0.22, 0.35),
				"vm_pos": Vector3(0.22, -0.20, -0.48), "vm_rot": Vector3(0.0, 0.0, -0.24),
				"sprint_rot": Vector3(0.22, -0.35, -0.48),
				"tp_left_arm": Vector3(0.95, 0.24, -0.65), "tp_left_elbow": Vector3(0.32, 0.12, 0.0),
				"tp_right_arm": Vector3(0.88, -0.38, 0.52), "tp_right_elbow": Vector3(1.18, -0.24, 0.0)
			}
		# SNIPERS — Capacitor Cradle, DMR Magwell Rest, Heavy Bolt-Action Stock Tuck, .50-Cal Anti-Materiel Brace
		"chargerifle":
			return {
				"style": "sniper_capacitor_barrel_cradle",
				"left_pos": Vector3(-0.058, -0.062, -0.255), "left_rot": Vector3(0.26, 0.24, -0.42),
				"right_pos": Vector3(0.022, -0.104, 0.125), "right_rot": Vector3(0.04, -0.06, 0.04),
				"vm_pos": Vector3(0.25, -0.23, -0.56), "vm_rot": Vector3(0.01, 0.02, 0.03),
				"sprint_rot": Vector3(0.30, 0.50, -0.26),
				"tp_left_arm": Vector3(0.76, 0.52, -0.22), "tp_left_elbow": Vector3(0.82, 0.24, 0.0),
				"tp_right_arm": Vector3(0.56, -0.18, 0.06), "tp_right_elbow": Vector3(0.84, -0.14, 0.0)
			}
		"longbow":
			return {
				"style": "sniper_dmr_magwell_precision_rest",
				"left_pos": Vector3(-0.042, -0.068, -0.225), "left_rot": Vector3(0.32, 0.22, -0.30),
				"right_pos": Vector3(0.020, -0.102, 0.122), "right_rot": Vector3(0.04, -0.06, 0.02),
				"vm_pos": Vector3(0.24, -0.22, -0.56), "vm_rot": Vector3(0.0, 0.01, 0.02),
				"sprint_rot": Vector3(0.28, 0.48, -0.24),
				"tp_left_arm": Vector3(0.78, 0.50, -0.18), "tp_left_elbow": Vector3(0.84, 0.22, 0.0),
				"tp_right_arm": Vector3(0.58, -0.16, 0.04), "tp_right_elbow": Vector3(0.82, -0.14, 0.0)
			}
		"sentinel":
			return {
				"style": "sniper_heavy_bolt_action_stock_tuck",
				"left_pos": Vector3(-0.048, -0.058, -0.268), "left_rot": Vector3(0.24, 0.20, -0.36),
				"right_pos": Vector3(0.022, -0.104, 0.132), "right_rot": Vector3(0.02, -0.04, 0.02),
				"vm_pos": Vector3(0.24, -0.22, -0.57), "vm_rot": Vector3(-0.01, 0.01, 0.0),
				"sprint_rot": Vector3(0.32, 0.52, -0.26),
				"tp_left_arm": Vector3(0.80, 0.48, -0.20), "tp_left_elbow": Vector3(0.80, 0.20, 0.0),
				"tp_right_arm": Vector3(0.58, -0.14, 0.02), "tp_right_elbow": Vector3(0.82, -0.12, 0.0)
			}
		"kraber":
			return {
				"style": "sniper_50cal_anti_materiel_heavy_brace",
				"left_pos": Vector3(-0.062, -0.078, -0.285), "left_rot": Vector3(0.30, 0.22, -0.34),
				"right_pos": Vector3(0.026, -0.112, 0.145), "right_rot": Vector3(0.06, -0.04, -0.03),
				"vm_pos": Vector3(0.26, -0.24, -0.59), "vm_rot": Vector3(-0.02, 0.01, -0.03),
				"sprint_rot": Vector3(0.36, 0.56, -0.30),
				"tp_left_arm": Vector3(0.74, 0.46, -0.18), "tp_left_elbow": Vector3(0.82, 0.20, 0.0),
				"tp_right_arm": Vector3(0.52, -0.12, -0.04), "tp_right_elbow": Vector3(0.88, -0.12, 0.0)
			}
		# SHOTGUNS — Drum Magazine Clearance, Horizontal Pump Forend Slide, Lever-Action Cocking Loop
		"eva8":
			return {
				"style": "shotgun_drum_mag_wide_foregrip",
				"left_pos": Vector3(-0.068, -0.085, -0.175), "left_rot": Vector3(0.36, 0.34, -0.42),
				"right_pos": Vector3(0.024, -0.106, 0.102), "right_rot": Vector3(0.08, -0.08, 0.05),
				"vm_pos": Vector3(0.26, -0.24, -0.50), "vm_rot": Vector3(0.02, 0.03, 0.05),
				"sprint_rot": Vector3(0.24, 0.46, -0.22),
				"tp_left_arm": Vector3(0.70, 0.56, -0.22), "tp_left_elbow": Vector3(0.92, 0.28, 0.0),
				"tp_right_arm": Vector3(0.52, -0.18, 0.06), "tp_right_elbow": Vector3(0.86, -0.16, 0.0)
			}
		"mastiff":
			return {
				"style": "shotgun_horizontal_pump_forend_slide",
				"left_pos": Vector3(-0.048, -0.055, -0.220), "left_rot": Vector3(0.26, 0.24, -0.48),
				"right_pos": Vector3(0.022, -0.104, 0.112), "right_rot": Vector3(0.06, -0.06, 0.03),
				"vm_pos": Vector3(0.25, -0.23, -0.52), "vm_rot": Vector3(0.01, 0.02, 0.03),
				"sprint_rot": Vector3(0.26, 0.48, -0.24),
				"tp_left_arm": Vector3(0.74, 0.52, -0.24), "tp_left_elbow": Vector3(0.86, 0.24, 0.0),
				"tp_right_arm": Vector3(0.54, -0.16, 0.06), "tp_right_elbow": Vector3(0.84, -0.14, 0.0)
			}
		"peacekeeper":
			return {
				"style": "shotgun_lever_action_cocking_loop",
				"left_pos": Vector3(-0.044, -0.060, -0.195), "left_rot": Vector3(0.28, 0.22, -0.38),
				"right_pos": Vector3(0.024, -0.102, 0.108), "right_rot": Vector3(0.04, -0.05, -0.08),
				"vm_pos": Vector3(0.25, -0.23, -0.51), "vm_rot": Vector3(-0.01, 0.02, -0.06),
				"sprint_rot": Vector3(0.22, 0.42, -0.18),
				"tp_left_arm": Vector3(0.74, 0.50, -0.18), "tp_left_elbow": Vector3(0.88, 0.22, 0.0),
				"tp_right_arm": Vector3(0.54, -0.14, -0.06), "tp_right_elbow": Vector3(0.84, -0.12, 0.0)
			}
	return {
		"style": "standard_rifle",
		"left_pos": Vector3(-0.052, -0.036, -0.205), "left_rot": Vector3(0.20, 0.26, -0.54),
		"right_pos": Vector3(0.020, -0.100, 0.105), "right_rot": Vector3(0.05, -0.08, 0.05),
		"vm_pos": Vector3(0.25, -0.22, -0.52), "vm_rot": Vector3(0.01, 0.02, 0.04),
		"sprint_rot": Vector3(0.24, 0.44, -0.24),
		"tp_left_arm": Vector3(0.78, 0.54, -0.24), "tp_left_elbow": Vector3(0.88, 0.24, 0.0),
		"tp_right_arm": Vector3(0.58, -0.22, 0.08), "tp_right_elbow": Vector3(0.82, -0.16, 0.0)
	}

# 12 Distinct Heirloom Grips, Inspects, and 3-Stage Attack Animations (Driven by UAL1_Standard.glb MoCap Curves!)
static func animate_custom_heirloom_1p(
	lid: String,
	combo_idx: int,
	melee_p: float,
	melee_active: bool,
	sprinting: bool,
	inspecting: bool,
	bob_time: float,
	_delta: float,
	heirloom_pivot: Node3D,
	left_arm: Node3D,
	right_arm: Node3D,
	kick_leg: Node3D = null,
	is_air_kick: bool = false,
	is_sliding: bool = false
) -> Dictionary:
	if left_arm == null or right_arm == null or heirloom_pivot == null:
		return {"cam_roll": 0.0, "cam_pitch": 0.0}

	var bob_x: float = sin(bob_time * 0.5) * (0.012 if sprinting else 0.005)
	var bob_y: float = cos(bob_time) * (0.014 if sprinting else 0.005)
	var slide_z: float = -0.16 if is_sliding else 0.0

	# Universal Airborne Flying Jump-Kick override
	if melee_active and is_air_kick:
		if kick_leg != null:
			kick_leg.visible = true
			kick_leg.position = sample_vec3(melee_p, [
				[0.00, Vector3(0.08, -0.45, 0.22)],
				[0.14, Vector3(0.05, -0.25, -0.05)],
				[0.34, Vector3(-0.08, 0.02, -0.58)],
				[0.50, Vector3(-0.08, 0.00, -0.52)],
				[1.00, Vector3(0.08, -0.45, 0.22)]
			])
			kick_leg.rotation = sample_vec3(melee_p, [
				[0.00, Vector3(-0.35, 0.0, 0.0)],
				[0.34, Vector3(0.18, 0.22, -0.38)],
				[1.00, Vector3(-0.35, 0.0, 0.0)]
			])
		left_arm.position = Vector3(-0.48, -0.14, 0.04)
		left_arm.rotation = Vector3(0.28, 0.35, -0.25)
		right_arm.position = Vector3(0.08, -0.14, 0.04)
		right_arm.rotation = Vector3(0.28, -0.35, 0.25)
		return {"cam_roll": sin(melee_p * PI) * -0.14, "cam_pitch": sin(melee_p * PI) * 0.08}
	elif kick_leg != null and not melee_active:
		kick_leg.visible = false

	match lid:
		"pathfinder":
			# PATHFINDER BOXING GLOVES: Worn directly on LeftArmPivot & RightArmPivot!
			# HeirloomPivot is completely hidden so there is NEVER a floating knife-grip glove!
			heirloom_pivot.visible = false
			var l_idle_pos := Vector3(-0.44 + bob_x, -0.06 + bob_y, -0.04)
			var l_idle_rot := Vector3(0.24, 0.24, -0.12 + slide_z)
			var r_idle_pos := Vector3(0.00 - bob_x, -0.06 - bob_y, -0.03)
			var r_idle_rot := Vector3(0.26, -0.24, 0.12 + slide_z)

			if melee_active:
				if combo_idx % 3 == 0:
					# UAL1_Standard.glb: Punch_Jab — Left Straight Snap Jab (ONLY Left Glove punches, Right Glove guards cheek!)
					left_arm.position = sample_vec3(melee_p, [
						[0.00, l_idle_pos],
						[0.12, Vector3(-0.48, -0.08, 0.05)],
						[0.28, Vector3(-0.22, 0.02, -0.54)],
						[0.40, Vector3(-0.23, 0.01, -0.48)],
						[0.68, Vector3(-0.38, -0.04, -0.16)],
						[1.00, l_idle_pos]
					])
					left_arm.rotation = sample_vec3(melee_p, [
						[0.00, l_idle_rot],
						[0.12, Vector3(0.32, 0.30, 0.15)],
						[0.28, Vector3(-0.08, 0.42, -1.28)],
						[0.40, Vector3(-0.04, 0.36, -1.12)],
						[0.68, Vector3(0.16, 0.20, -0.35)],
						[1.00, l_idle_rot]
					])
					# Right glove tucks back at right cheek guard
					right_arm.position = sample_vec3(melee_p, [
						[0.00, r_idle_pos],
						[0.28, Vector3(0.08, -0.08, 0.08)],
						[0.50, Vector3(0.06, -0.07, 0.05)],
						[1.00, r_idle_pos]
					])
					right_arm.rotation = sample_vec3(melee_p, [
						[0.00, r_idle_rot],
						[0.28, Vector3(0.38, -0.35, 0.25)],
						[1.00, r_idle_rot]
					])
					return {"cam_roll": sin(melee_p * PI) * 0.09, "cam_pitch": -sin(melee_p * PI) * 0.05}
				elif combo_idx % 3 == 1:
					# UAL1_Standard.glb: Punch_Cross — Right Power Cross Hook (ONLY Right Glove punches, Left Glove guards cheek!)
					right_arm.position = sample_vec3(melee_p, [
						[0.00, r_idle_pos],
						[0.15, Vector3(0.12, -0.07, 0.08)],
						[0.32, Vector3(-0.22, 0.03, -0.56)],
						[0.45, Vector3(-0.24, 0.02, -0.48)],
						[0.72, Vector3(-0.08, -0.04, -0.18)],
						[1.00, r_idle_pos]
					])
					right_arm.rotation = sample_vec3(melee_p, [
						[0.00, r_idle_rot],
						[0.15, Vector3(0.36, -0.45, -0.28)],
						[0.32, Vector3(0.06, 0.48, 1.35)],
						[0.45, Vector3(0.10, 0.42, 1.18)],
						[0.72, Vector3(0.22, -0.10, 0.38)],
						[1.00, r_idle_rot]
					])
					# Left glove tucks back at left cheek guard
					left_arm.position = sample_vec3(melee_p, [
						[0.00, l_idle_pos],
						[0.32, Vector3(-0.50, -0.09, 0.08)],
						[0.55, Vector3(-0.48, -0.08, 0.04)],
						[1.00, l_idle_pos]
					])
					left_arm.rotation = sample_vec3(melee_p, [
						[0.00, l_idle_rot],
						[0.32, Vector3(0.38, 0.35, -0.25)],
						[1.00, l_idle_rot]
					])
					return {"cam_roll": -sin(melee_p * PI) * 0.12, "cam_pitch": -sin(melee_p * PI) * 0.06}
				else:
					# Stage 2: Right Lead Piston Uppercut (Single-Hand Rising Uppercut — NEVER collides both gloves in the center!)
					right_arm.position = sample_vec3(melee_p, [
						[0.00, r_idle_pos],
						[0.16, Vector3(0.04, -0.22, 0.04)],
						[0.34, Vector3(-0.18, 0.12, -0.52)],
						[0.48, Vector3(-0.18, 0.15, -0.46)],
						[0.74, Vector3(-0.06, -0.02, -0.18)],
						[1.00, r_idle_pos]
					])
					right_arm.rotation = sample_vec3(melee_p, [
						[0.00, r_idle_rot],
						[0.16, Vector3(-0.32, -0.20, 0.25)],
						[0.34, Vector3(0.78, 0.28, 0.35)],
						[0.48, Vector3(0.84, 0.24, 0.30)],
						[1.00, r_idle_rot]
					])
					left_arm.position = sample_vec3(melee_p, [
						[0.00, l_idle_pos],
						[0.34, Vector3(-0.50, -0.10, 0.06)],
						[1.00, l_idle_pos]
					])
					left_arm.rotation = l_idle_rot + Vector3(0.12 * sin(melee_p * PI), 0.10, -0.12)
					return {"cam_roll": -sin(melee_p * PI) * 0.08, "cam_pitch": sin(melee_p * PI) * 0.14}
			elif inspecting:
				left_arm.position = l_idle_pos + Vector3(sin(bob_time * 4.0) * 0.07, abs(cos(bob_time * 4.0)) * 0.05, -0.06)
				right_arm.position = r_idle_pos + Vector3(-sin(bob_time * 4.0) * 0.07, abs(sin(bob_time * 4.0)) * 0.05, -0.06)
				left_arm.rotation = l_idle_rot + Vector3(sin(bob_time * 6.0) * 0.38, 0.28, -0.22)
				right_arm.rotation = r_idle_rot + Vector3(-sin(bob_time * 6.0) * 0.38, -0.28, 0.22)
			else:
				left_arm.position = l_idle_pos
				left_arm.rotation = l_idle_rot
				right_arm.position = r_idle_pos
				right_arm.rotation = r_idle_rot
			return {"cam_roll": 0.0, "cam_pitch": 0.0}

		"wraith":
			# WRAITH KUNAI — Reverse Icepick Grip (Blade Down 2.75 rad) + Left Hand Void Ninja Seal
			heirloom_pivot.visible = true
			var h_idle_pos := Vector3(0.02 - bob_x, -0.02 + bob_y, -0.08)
			var h_idle_rot := Vector3(2.75, -0.35, 0.25 + slide_z)
			var l_idle_pos := Vector3(-0.40 + bob_x, -0.07 - bob_y, -0.06)
			var l_idle_rot := Vector3(0.32, 0.32, -0.24 + slide_z)

			if melee_active:
				if combo_idx % 3 == 0:
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, h_idle_pos],
						[0.14, Vector3(-0.30, 0.05, -0.02)],
						[0.32, Vector3(0.16, -0.02, -0.44)],
						[0.46, Vector3(0.18, -0.04, -0.38)],
						[1.00, h_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, h_idle_rot],
						[0.14, Vector3(2.50, 0.82, -0.95)],
						[0.32, Vector3(2.92, -1.12, 1.18)],
						[0.46, Vector3(2.85, -0.98, 1.02)],
						[1.00, h_idle_rot]
					])
				elif combo_idx % 3 == 1:
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, h_idle_pos],
						[0.15, Vector3(0.14, -0.14, 0.02)],
						[0.34, Vector3(-0.32, 0.12, -0.46)],
						[0.48, Vector3(-0.28, 0.10, -0.40)],
						[1.00, h_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, h_idle_rot],
						[0.15, Vector3(0.32, -0.62, -0.78)],
						[0.34, Vector3(1.18, 0.88, 1.08)],
						[1.00, h_idle_rot]
					])
				else:
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, h_idle_pos],
						[0.20, Vector3(-0.10, 0.16, -0.04)],
						[0.38, Vector3(-0.18, -0.04, -0.52)],
						[0.50, Vector3(-0.18, -0.05, -0.46)],
						[1.00, h_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, h_idle_rot],
						[0.20, Vector3(2.75 + TAU, -0.20, 0.30)],
						[0.38, Vector3(3.65, 0.12, -0.12)],
						[1.00, h_idle_rot]
					])
				left_arm.position = l_idle_pos + Vector3(-0.04 * sin(melee_p * PI), 0.03 * sin(melee_p * PI), 0.06 * sin(melee_p * PI))
				left_arm.rotation = l_idle_rot + Vector3(0.22 * sin(melee_p * PI), 0.14, -0.18)
				right_arm.position = heirloom_pivot.position + Vector3(0.02, -0.02, 0.04)
				right_arm.rotation = Vector3(0.24, -0.18, 0.12)
				return {"cam_roll": sin(melee_p * PI) * (-0.09 if combo_idx % 2 == 0 else 0.09), "cam_pitch": -sin(melee_p * PI) * 0.07}
			elif inspecting:
				heirloom_pivot.position = h_idle_pos + Vector3(-0.10, 0.06, -0.04)
				heirloom_pivot.rotation = h_idle_rot + Vector3(bob_time * 8.0, sin(bob_time * 3.0) * 0.45, cos(bob_time * 3.0) * 0.35)
				left_arm.position = l_idle_pos
				left_arm.rotation = l_idle_rot
			else:
				heirloom_pivot.position = h_idle_pos
				heirloom_pivot.rotation = h_idle_rot + Vector3(sin(bob_time * 1.5) * 0.05, 0, 0)
				left_arm.position = l_idle_pos
				left_arm.rotation = l_idle_rot
			right_arm.position = heirloom_pivot.position + Vector3(0.02, -0.02, 0.04)
			right_arm.rotation = Vector3(0.24, -0.18, 0.12)
			return {"cam_roll": 0.0, "cam_pitch": 0.0}

		"octane":
			# OCTANE BUTTERFLY KNIFE — Articulating Twin Handles (HandleLeft & HandleRight) + Stims
			heirloom_pivot.visible = true
			var h_idle_pos := Vector3(0.03 - bob_x, -0.03 + bob_y, -0.07)
			var h_idle_rot := Vector3(0.32, -0.42, -0.18 + slide_z)
			var l_idle_pos := Vector3(-0.40 + bob_x, -0.07 - bob_y, -0.05)
			var l_idle_rot := Vector3(0.28, 0.26, -0.20 + slide_z)
			var hl := heirloom_pivot.get_node_or_null("HandleLeft") as Node3D
			var hr := heirloom_pivot.get_node_or_null("HandleRight") as Node3D

			if melee_active:
				if combo_idx % 3 == 0:
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, h_idle_pos],
						[0.14, Vector3(0.14, 0.05, 0.02)],
						[0.32, Vector3(-0.32, -0.02, -0.44)],
						[1.00, h_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, h_idle_rot],
						[0.14, Vector3(0.55, -0.95, -0.75)],
						[0.32, Vector3(-0.28, 0.92, 0.85)],
						[1.00, h_idle_rot]
					])
					if hl: hl.rotation.z = sin(melee_p * TAU * 2.0) * 2.2
					if hr: hr.rotation.z = -sin(melee_p * TAU * 2.0) * 1.9
				elif combo_idx % 3 == 1:
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, h_idle_pos],
						[0.15, Vector3(-0.32, -0.04, -0.02)],
						[0.34, Vector3(0.14, 0.06, -0.44)],
						[1.00, h_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, h_idle_rot],
						[0.15, Vector3(-0.38, 0.82, 0.95)],
						[0.34, Vector3(0.65, -0.88, -0.98)],
						[1.00, h_idle_rot]
					])
					if hl: hl.rotation.z = sin(melee_p * PI) * 2.5
				else:
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, h_idle_pos],
						[0.18, Vector3(-0.06, 0.12, 0.02)],
						[0.36, Vector3(-0.18, 0.02, -0.52)],
						[1.00, h_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, h_idle_rot],
						[0.18, Vector3(TAU + 0.32, -0.28, 0.18)],
						[0.36, Vector3(-1.18, 0.06, 0.0)],
						[1.00, h_idle_rot]
					])
					if hl: hl.rotation.z = 0.08
					if hr: hr.rotation.z = -0.08
			elif inspecting:
				heirloom_pivot.position = h_idle_pos + Vector3(-0.10, 0.06, -0.04)
				heirloom_pivot.rotation = h_idle_rot + Vector3(bob_time * 6.0, sin(bob_time * 4.0) * 0.6, cos(bob_time * 4.0) * 0.5)
				if hl: hl.rotation.z = sin(bob_time * 10.0) * 2.3
				if hr: hr.rotation.z = -cos(bob_time * 10.0) * 2.3
			else:
				heirloom_pivot.position = h_idle_pos
				heirloom_pivot.rotation = h_idle_rot
				if hl: hl.rotation.z = 0.08 + maxf(0.0, sin(bob_time * 2.5) * 0.42)
				if hr: hr.rotation.z = -0.08 + minf(0.0, -sin(bob_time * 2.5) * 0.35)
			left_arm.position = l_idle_pos
			left_arm.rotation = l_idle_rot
			right_arm.position = heirloom_pivot.position + Vector3(0.02, -0.04, 0.04)
			right_arm.rotation = Vector3(0.24, -0.16, 0.10)
			return {"cam_roll": sin(melee_p * PI) * 0.08 if melee_active else 0.0, "cam_pitch": 0.0}

		"lifeline":
			# LIFELINE SHOCK STICKS — True Dual-Wielded Drumsticks in Left & Right Hands!
			heirloom_pivot.visible = true
			var r_idle_pos := Vector3(0.02 - bob_x, -0.04 + bob_y, -0.06)
			var r_idle_rot := Vector3(0.32, -0.24, 0.16 + slide_z)
			var l_idle_pos := Vector3(-0.42 + bob_x, -0.04 - bob_y, -0.06)
			var l_idle_rot := Vector3(0.34, 0.24, -0.16 + slide_z)

			if melee_active:
				if combo_idx % 3 == 0:
					# Right Drumstick Strike while Left Guards
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, r_idle_pos],
						[0.14, Vector3(0.10, 0.12, 0.02)],
						[0.32, Vector3(-0.22, -0.04, -0.48)],
						[1.00, r_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, r_idle_rot],
						[0.14, Vector3(0.75, -0.42, -0.45)],
						[0.32, Vector3(-0.82, 0.48, 0.58)],
						[1.00, r_idle_rot]
					])
					left_arm.position = l_idle_pos + Vector3(-0.04, -0.02, 0.04)
					left_arm.rotation = l_idle_rot
				elif combo_idx % 3 == 1:
					# Left Drumstick Strike while Right Guards
					left_arm.position = sample_vec3(melee_p, [
						[0.00, l_idle_pos],
						[0.14, Vector3(-0.50, 0.12, 0.02)],
						[0.32, Vector3(-0.20, -0.04, -0.48)],
						[1.00, l_idle_pos]
					])
					left_arm.rotation = sample_vec3(melee_p, [
						[0.00, l_idle_rot],
						[0.14, Vector3(0.75, 0.42, 0.45)],
						[0.32, Vector3(-0.82, -0.48, -0.58)],
						[1.00, l_idle_rot]
					])
					heirloom_pivot.position = r_idle_pos + Vector3(0.04, -0.02, 0.04)
					heirloom_pivot.rotation = r_idle_rot
				else:
					# Cross-Stick X-Slash Shockwave!
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, r_idle_pos],
						[0.16, Vector3(0.14, 0.14, 0.02)],
						[0.36, Vector3(-0.30, -0.08, -0.46)],
						[1.00, r_idle_pos]
					])
					left_arm.position = sample_vec3(melee_p, [
						[0.00, l_idle_pos],
						[0.16, Vector3(-0.52, 0.14, 0.02)],
						[0.36, Vector3(-0.08, -0.08, -0.46)],
						[1.00, l_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, r_idle_rot],
						[0.16, Vector3(0.88, -0.58, -0.68)],
						[0.36, Vector3(-0.68, 0.75, 0.88)],
						[1.00, r_idle_rot]
					])
					left_arm.rotation = sample_vec3(melee_p, [
						[0.00, l_idle_rot],
						[0.16, Vector3(0.88, 0.58, 0.68)],
						[0.36, Vector3(-0.68, -0.75, -0.88)],
						[1.00, l_idle_rot]
					])
			elif inspecting:
				heirloom_pivot.position = r_idle_pos + Vector3(-0.06, 0.06, -0.04)
				left_arm.position = l_idle_pos + Vector3(0.06, 0.06, -0.04)
				heirloom_pivot.rotation = r_idle_rot + Vector3(bob_time * 8.0, 0, 0)
				left_arm.rotation = l_idle_rot + Vector3(-bob_time * 8.0, 0, 0)
			else:
				heirloom_pivot.position = r_idle_pos
				heirloom_pivot.rotation = r_idle_rot
				left_arm.position = l_idle_pos
				left_arm.rotation = l_idle_rot
			right_arm.position = heirloom_pivot.position + Vector3(0.02, -0.04, 0.04)
			right_arm.rotation = Vector3(0.24, -0.16, 0.10)
			return {"cam_roll": sin(melee_p * PI) * 0.08 if melee_active else 0.0, "cam_pitch": 0.0}

		"ash":
			# ASH STRONGEST LINK — Dual-Handed Split Nunchaku / Joined Katana Stance!
			heirloom_pivot.visible = true
			var r_idle_pos := Vector3(0.03 - bob_x, -0.04 + bob_y, -0.06)
			var r_idle_rot := Vector3(0.32, -0.34, 0.22 + slide_z)
			var l_idle_pos := Vector3(-0.42 + bob_x, -0.04 - bob_y, -0.06)
			var l_idle_rot := Vector3(0.34, 0.32, -0.22 + slide_z)

			if melee_active:
				if combo_idx % 3 == 0:
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, r_idle_pos],
						[0.16, Vector3(0.12, 0.12, 0.02)],
						[0.36, Vector3(-0.32, -0.08, -0.46)],
						[1.00, r_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, r_idle_rot],
						[0.16, Vector3(1.8, -0.75, -0.82)],
						[0.36, Vector3(-2.6, 0.88, 0.96)],
						[1.00, r_idle_rot]
					])
					left_arm.position = l_idle_pos + Vector3(-0.04, -0.02, 0.04)
					left_arm.rotation = l_idle_rot
				elif combo_idx % 3 == 1:
					left_arm.position = sample_vec3(melee_p, [
						[0.00, l_idle_pos],
						[0.16, Vector3(-0.50, 0.10, 0.02)],
						[0.36, Vector3(-0.14, -0.06, -0.46)],
						[1.00, l_idle_pos]
					])
					left_arm.rotation = sample_vec3(melee_p, [
						[0.00, l_idle_rot],
						[0.16, Vector3(1.6, 0.68, 0.75)],
						[0.36, Vector3(-2.2, -0.82, -0.88)],
						[1.00, l_idle_rot]
					])
					heirloom_pivot.position = r_idle_pos + Vector3(0.04, -0.02, 0.04)
					heirloom_pivot.rotation = r_idle_rot
				else:
					# Snap Both Sections Together into Two-Handed Katana Void-Tear Thrust!
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, r_idle_pos],
						[0.18, Vector3(-0.18, -0.04, 0.02)],
						[0.38, Vector3(-0.20, 0.02, -0.52)],
						[1.00, r_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, r_idle_rot],
						[0.18, Vector3(0.18, 0, 0)],
						[0.38, Vector3(-1.22, 0, 0)],
						[1.00, r_idle_rot]
					])
					left_arm.position = heirloom_pivot.position + Vector3(-0.04, -0.04, 0.05)
					left_arm.rotation = Vector3(0.38, 0.32, -0.22)
			elif inspecting:
				heirloom_pivot.position = r_idle_pos + Vector3(-0.08, 0.05, -0.04)
				heirloom_pivot.rotation = r_idle_rot + Vector3(bob_time * 7.0, sin(bob_time * 3.0) * 0.65, 0)
				left_arm.position = l_idle_pos + Vector3(0.08, 0.05, -0.04)
				left_arm.rotation = l_idle_rot + Vector3(-bob_time * 7.0, -sin(bob_time * 3.0) * 0.65, 0)
			else:
				heirloom_pivot.position = r_idle_pos
				heirloom_pivot.rotation = r_idle_rot
				left_arm.position = l_idle_pos
				left_arm.rotation = l_idle_rot
			right_arm.position = heirloom_pivot.position + Vector3(0.02, -0.04, 0.04)
			right_arm.rotation = Vector3(0.24, -0.16, 0.10)
			return {"cam_roll": sin(melee_p * PI) * 0.09 if melee_active else 0.0, "cam_pitch": 0.0}

		"valkyrie", "caustic", "horizon":
			# TWO-HANDED POLEARMS & HEAVY MAULS (Suzaku Spear, Death Hammer, Gravity Maw)
			heirloom_pivot.visible = true
			var h_idle_pos := Vector3(0.02 - bob_x, -0.05 + bob_y, -0.08)
			var h_idle_rot := Vector3(0.28, -0.38, -0.28 + slide_z)
			if lid == "caustic" or lid == "horizon":
				h_idle_rot = Vector3(0.36, -0.32, -0.22 + slide_z)

			if melee_active:
				if combo_idx % 3 == 0:
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, h_idle_pos],
						[0.16, Vector3(0.16, 0.04, 0.04)],
						[0.36, Vector3(-0.36, -0.06, -0.46)],
						[1.00, h_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, h_idle_rot],
						[0.16, Vector3(0.62, -0.88, -0.95)],
						[0.36, Vector3(-0.45, 1.05, 1.12)],
						[1.00, h_idle_rot]
					])
				elif combo_idx % 3 == 1:
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, h_idle_pos],
						[0.16, Vector3(-0.34, -0.14, 0.02)],
						[0.36, Vector3(0.06, 0.14, -0.46)],
						[1.00, h_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, h_idle_rot],
						[0.16, Vector3(-0.58, 0.78, 0.84)],
						[0.36, Vector3(0.88, -0.74, -0.92)],
						[1.00, h_idle_rot]
					])
				else:
					if lid == "valkyrie":
						heirloom_pivot.position = sample_vec3(melee_p, [
							[0.00, h_idle_pos],
							[0.18, Vector3(-0.04, -0.04, 0.06)],
							[0.36, Vector3(-0.18, 0.02, -0.56)],
							[1.00, h_idle_pos]
						])
						heirloom_pivot.rotation = sample_vec3(melee_p, [
							[0.00, h_idle_rot],
							[0.18, Vector3(-0.68, -0.12, -0.08)],
							[0.36, Vector3(-1.38, 0.04, 0.0)],
							[1.00, h_idle_rot]
						])
					else:
						heirloom_pivot.position = sample_vec3(melee_p, [
							[0.00, h_idle_pos],
							[0.20, Vector3(-0.10, 0.22, 0.04)],
							[0.40, Vector3(-0.18, -0.20, -0.48)],
							[1.00, h_idle_pos]
						])
						heirloom_pivot.rotation = sample_vec3(melee_p, [
							[0.00, h_idle_rot],
							[0.20, Vector3(1.12, -0.14, -0.16)],
							[0.40, Vector3(-1.12, 0.14, 0.18)],
							[1.00, h_idle_rot]
						])
			elif inspecting:
				heirloom_pivot.position = h_idle_pos + Vector3(-0.12, 0.06, -0.04)
				heirloom_pivot.rotation = h_idle_rot + Vector3(sin(bob_time * 2.5) * 0.55, bob_time * 3.5, cos(bob_time * 2.5) * 0.40)
			else:
				heirloom_pivot.position = h_idle_pos
				heirloom_pivot.rotation = h_idle_rot
			right_arm.position = heirloom_pivot.position + Vector3(0.02, -0.03, 0.04)
			right_arm.rotation = Vector3(0.24, -0.18, 0.12)
			left_arm.position = heirloom_pivot.position + Vector3(-0.08, -0.12, 0.10)
			left_arm.rotation = Vector3(0.38, 0.34, -0.24)
			return {"cam_roll": sin(melee_p * PI) * 0.11 if melee_active else 0.0, "cam_pitch": -sin(melee_p * PI) * 0.09 if melee_active else 0.0}

		_:
			# BLOODHOUND / GIBRALTAR / BANGALORE / MIRAGE — One-Handed Tactical Cleave + Active Off-Hand Guard
			heirloom_pivot.visible = true
			var h_idle_pos := Vector3(0.04 - bob_x, -0.03 + bob_y, -0.06)
			var h_idle_rot := Vector3(0.28, -0.28, 0.16 + slide_z)
			if lid == "bangalore":
				h_idle_rot = Vector3(0.42, -0.44, -0.24 + slide_z)
			elif lid == "mirage":
				h_idle_rot = Vector3(0.14, -0.18, -0.06 + slide_z)
			var l_idle_pos := Vector3(-0.40 + bob_x, -0.07 - bob_y, -0.06)
			var l_idle_rot := Vector3(0.30, 0.26, -0.20 + slide_z)

			if melee_active:
				if combo_idx % 3 == 0:
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, h_idle_pos],
						[0.14, Vector3(0.14, 0.14, 0.04)],
						[0.34, Vector3(-0.28, -0.14, -0.46)],
						[1.00, h_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, h_idle_rot],
						[0.14, Vector3(0.95, -0.55, -0.78)],
						[0.34, Vector3(-0.88, 0.72, 0.85)],
						[1.00, h_idle_rot]
					])
				elif combo_idx % 3 == 1:
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, h_idle_pos],
						[0.15, Vector3(-0.32, -0.04, 0.02)],
						[0.35, Vector3(0.14, 0.04, -0.44)],
						[1.00, h_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, h_idle_rot],
						[0.15, Vector3(-0.38, 0.88, 0.96)],
						[0.35, Vector3(0.54, -0.92, -0.98)],
						[1.00, h_idle_rot]
					])
				else:
					heirloom_pivot.position = sample_vec3(melee_p, [
						[0.00, h_idle_pos],
						[0.18, Vector3(-0.08, 0.22, 0.04)],
						[0.38, Vector3(-0.18, -0.18, -0.48)],
						[1.00, h_idle_pos]
					])
					heirloom_pivot.rotation = sample_vec3(melee_p, [
						[0.00, h_idle_rot],
						[0.18, Vector3(1.10, -0.16, -0.18)],
						[0.38, Vector3(-1.12, 0.14, 0.16)],
						[1.00, h_idle_rot]
					])
				left_arm.position = l_idle_pos + Vector3(-0.04 * sin(melee_p * PI), 0.03 * sin(melee_p * PI), 0.06 * sin(melee_p * PI))
				left_arm.rotation = l_idle_rot + Vector3(0.24 * sin(melee_p * PI), 0.16, -0.20)
			elif inspecting:
				heirloom_pivot.position = h_idle_pos + Vector3(-0.12, 0.06, -0.04)
				heirloom_pivot.rotation = h_idle_rot + Vector3(sin(bob_time * 2.5) * 0.50, bob_time * 4.0, cos(bob_time * 2.5) * 0.45)
				left_arm.position = l_idle_pos
				left_arm.rotation = l_idle_rot
			else:
				heirloom_pivot.position = h_idle_pos
				heirloom_pivot.rotation = h_idle_rot
				left_arm.position = l_idle_pos
				left_arm.rotation = l_idle_rot
			right_arm.position = heirloom_pivot.position + Vector3(0.02, -0.04, 0.04)
			right_arm.rotation = Vector3(0.24, -0.16, 0.10)
			return {"cam_roll": sin(melee_p * PI) * 0.10 if melee_active else 0.0, "cam_pitch": -sin(melee_p * PI) * 0.08 if melee_active else 0.0}
