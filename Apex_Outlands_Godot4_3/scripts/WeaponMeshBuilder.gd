class_name WeaponMeshBuilder
extends RefCounted
## High-Detail Procedural 3D First-Person & Third-Person Weapon, Bocek Compound Bow, Consumable Prop & Mythic Heirloom Builder for Godot 4.3.
## Upgrades:
## - Sculpted Multi-Surface Weapon Receivers (Chamfered Cheek Plates, Rear Buffer Cap, Tritium Rear Peep Sights, Front Sight Hoods, Angled Magwells, Vent Louvers)
## - Integrated Rear-Facing Digital Ammo Counter LCD (`AmmoScreenHousing` + `AmmoLabel3D`) facing the player's eye on ALL firearms (fixes sideways floating numbers!)
## - Anatomical First-Person Tactical Arms & Gloved Hands (`CapsuleMesh` forearms, wrist holo-watch, sculpted palm, and 5 articulated fingers wrapped around grip/forend)
## - Authentic Center-Screen 3D Consumable Props (`BatteryProp` with glowing OmniLight3D + twisting capacitor core, `MedProp` pneumatic auto-injector)
## - Third-Person 3D Weapon Builder (`create_third_person_weapon_mesh`) for 3rd-person player & AI bots (two-handed aim + back holster when healing)

static func _make_mat(col: Color, metal: float = 0.68, rough: float = 0.30, emit: bool = false, emit_energy: float = 1.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = rough
	if emit:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit_energy
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


static func _build_tactical_fp_arms(gun_rig: Node3D, legend_data: Dictionary, is_heirloom: bool = false, rec_len: float = 0.48, is_bow: bool = false) -> void:
	## Anatomical First-Person Arms & Hands using smooth Capsules, Spheres, Wrist Guards, and 5 Articulated Fingers!
	var lid: String = str(legend_data.get("id", "wraith"))
	var col_prim: Color = legend_data.get("primary_color", Color("#312e81"))
	var col_sec: Color = legend_data.get("secondary_color", Color("#38bdf8"))

	var mat_sleeve := _make_mat(col_prim, 0.42, 0.44)
	var mat_trim := _make_mat(col_sec, 0.76, 0.25)
	var mat_glove := _make_mat(Color("#0f172a"), 0.35, 0.55)
	var mat_leather := _make_mat(Color("#1e293b"), 0.28, 0.65)
	var mat_knuckle := _make_mat(Color("#475569"), 0.85, 0.20)
	var mat_chrome := _make_mat(Color("#cbd5e1"), 0.95, 0.12)
	var mat_gold := _make_mat(Color("#f59e0b"), 0.90, 0.18)
	var mat_hud := _make_mat(Color("#38bdf8"), 0.2, 0.1, true, 3.8)
	var mat_stim := _make_mat(Color("#22c55e"), 0.1, 0.1, true, 4.2)
	var mat_void := _make_mat(Color("#8b5cf6"), 0.3, 0.2, true, 3.5)

	# 1. Left Arm (LeftArmPivot) - Supporting Handguard / Bow Riser Grip / Battery Base Grip
	var left_arm := Node3D.new()
	left_arm.name = "LeftArmPivot"
	if is_heirloom:
		left_arm.position = Vector3(-0.24, -0.13, -0.10)
	elif is_bow:
		left_arm.position = Vector3(-0.02, -0.04, -0.14)
	else:
		left_arm.position = Vector3(-0.055, -0.045, -0.18)
	gun_rig.add_child(left_arm)

	var l_sleeve_mat := mat_chrome if (lid == "pathfinder") else mat_sleeve
	# Smooth anatomical forearm capsule + armored vambrace
	_add_capsule(left_arm, 0.040, 0.34, Vector3(-0.08, -0.06, 0.15), l_sleeve_mat, Vector3(PI * 0.5 + 0.24, -0.30, 0), "LeftForearm")
	_add_cyl(left_arm, 0.044, 0.046, 0.14, Vector3(-0.09, -0.07, 0.18), mat_trim, Vector3(PI * 0.5 + 0.24, -0.30, 0), 12, "LeftVambrace")
	_add_sphere(left_arm, 0.036, Vector3(-0.025, -0.01, 0.025), mat_glove, "LeftWristJoint")

	# Wrist Tactical Chrono HUD / Holo-Watch
	var chrono := _add_box(left_arm, Vector3(0.082, 0.022, 0.052), Vector3(-0.035, -0.005, 0.055), mat_leather, Vector3(0.24, -0.30, 0), "WristChrono")
	_add_box(chrono, Vector3(0.066, 0.006, 0.036), Vector3(0, 0.012, 0), mat_hud)

	# Sculpted Left Glove Palm, Knuckle Carbon Plate & 5 Articulated Fingers wrapping the handguard
	_add_box(left_arm, Vector3(0.078, 0.058, 0.088), Vector3(0.0, 0.008, -0.02), mat_glove, Vector3(0, 0, -0.15), "LeftGloveHand")
	_add_box(left_arm, Vector3(0.074, 0.016, 0.038), Vector3(-0.002, 0.038, -0.022), mat_knuckle, Vector3(0, 0, -0.15))
	# Left Thumb C-clamp over top-left of handguard
	_add_capsule(left_arm, 0.012, 0.058, Vector3(0.036, 0.028, -0.025), mat_leather, Vector3(0.35, 0.45, -0.45), "LeftThumb")
	# 4 Curled Fingers under handguard
	for fi in range(4):
		var fz: float = -0.052 + float(fi) * 0.018
		_add_capsule(left_arm, 0.010, 0.054, Vector3(0.018, -0.022, fz), mat_leather, Vector3(0.15, 0.0, 1.25), "LeftFinger%d" % fi)

	if lid == "octane":
		_add_cyl(left_arm, 0.008, 0.008, 0.18, Vector3(-0.04, 0.00, 0.09), mat_stim, Vector3(0, 0, PI * 0.4))
	elif lid == "wraith":
		_add_box(left_arm, Vector3(0.080, 0.018, 0.12), Vector3(-0.08, -0.04, 0.14), mat_void, Vector3(0.24, -0.30, 0))
	elif lid == "bloodhound":
		_add_box(left_arm, Vector3(0.084, 0.024, 0.08), Vector3(-0.035, -0.005, 0.055), mat_gold, Vector3(0.24, -0.30, 0))

	# 2. Right Arm (RightArmPivot) - Pistol Grip / Trigger Finger / Battery Top Twist Hand
	var right_arm := Node3D.new()
	right_arm.name = "RightArmPivot"
	if is_heirloom:
		right_arm.position = Vector3(0.04, -0.08, -0.05)
	elif is_bow:
		right_arm.position = Vector3(0.03, -0.02, 0.10)
	else:
		right_arm.position = Vector3(0.02, -0.10, rec_len * 0.22)
	gun_rig.add_child(right_arm)

	var r_sleeve_mat := mat_chrome if (lid == "pathfinder") else mat_sleeve
	_add_capsule(right_arm, 0.040, 0.32, Vector3(0.065, -0.05, 0.16), r_sleeve_mat, Vector3(PI * 0.5 + 0.18, 0.20, 0), "RightForearm")
	_add_cyl(right_arm, 0.044, 0.046, 0.12, Vector3(0.075, -0.06, 0.19), mat_trim, Vector3(PI * 0.5 + 0.18, 0.20, 0), 12, "RightVambrace")
	_add_sphere(right_arm, 0.036, Vector3(0.022, -0.015, 0.03), mat_glove, "RightWristJoint")

	# Right Glove Palm, Knuckle Plate, Trigger Index Finger & 3 Grip Fingers
	_add_box(right_arm, Vector3(0.076, 0.066, 0.086), Vector3.ZERO, mat_glove, Vector3.ZERO, "RightGloveHand")
	_add_box(right_arm, Vector3(0.072, 0.016, 0.042), Vector3(0.0, 0.038, 0.0), mat_knuckle)
	# Right Thumb wrapped around left side of pistol grip
	_add_capsule(right_arm, 0.012, 0.056, Vector3(-0.038, 0.008, -0.035), mat_leather, Vector3(0.45, -0.35, 0.35), "RightThumb")
	# Trigger Finger extended forward onto trigger
	_add_capsule(right_arm, 0.010, 0.062, Vector3(0.018, 0.005, -0.052), mat_leather, Vector3(PI * 0.45, -0.15, 0), "TriggerFinger")
	# 3 Lower Grip Fingers
	for rfi in range(3):
		var rf_y: float = -0.015 - float(rfi) * 0.016
		_add_capsule(right_arm, 0.010, 0.052, Vector3(0.005, rf_y, -0.028), mat_leather, Vector3(0.0, 0.0, 1.35), "RightFinger%d" % rfi)


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

	# 10. Articulated First-Person Tactical Arms & Consumable Props
	_build_tactical_fp_arms(gun_rig, legend_data, false, rec_len, false)
	_build_fp_consumable_props(gun_rig)

	root.position = Vector3(0.26, -0.22, -0.52)
	return root

static func create_third_person_weapon_mesh(weapon_data: Dictionary) -> Node3D:
	## Builds a lightweight, authentic 3D weapon assembly for Third-Person Character Hands & Back Holster!
	var wid: String = str(weapon_data.get("id", "r301"))
	var cat: String = str(weapon_data.get("cat", "AR"))
	var col_main: Color = weapon_data.get("color", Color("#334155"))
	var col_accent: Color = weapon_data.get("accent", Color("#38bdf8"))
	var rec_len: float = float(weapon_data.get("rec_len", 0.48))
	var bar_len: float = float(weapon_data.get("barrel_len", 0.38))

	var root := Node3D.new()
	root.name = "TP_Weapon_" + wid

	var mat_body := _make_mat(col_main, 0.78, 0.25)
	var mat_dark := _make_mat(Color("#0f172a"), 0.68, 0.35)
	var mat_steel := _make_mat(Color("#94a3b8"), 0.92, 0.18)
	var mat_accent := _make_mat(col_accent, 0.55, 0.22, true, 2.5)
	var mat_flash := _make_mat(Color("#fbbf24"), 0.1, 0.1, true, 5.0)

	if wid == "bocek":
		_add_box(root, Vector3(0.036, 0.56, 0.06), Vector3(0, 0.02, -0.10), mat_body)
		_add_box(root, Vector3(0.024, 0.36, 0.04), Vector3(0, 0.38, -0.02), mat_dark, Vector3(0.45, 0, 0))
		_add_box(root, Vector3(0.024, 0.36, 0.04), Vector3(0, -0.34, -0.02), mat_dark, Vector3(-0.45, 0, 0))
		_add_cyl(root, 0.004, 0.004, 0.88, Vector3(0, 0.02, 0.08), mat_accent)
	else:
		var rw: float = 0.075 if cat != "PISTOL" else 0.052
		var rh: float = 0.115 if cat != "PISTOL" else 0.085
		_add_box(root, Vector3(rw, rh, rec_len), Vector3(0, 0.02, -0.08), mat_body)
		_add_box(root, Vector3(rw + 0.008, 0.022, rec_len * 0.78), Vector3(0, 0.035, -0.08), mat_accent)
		_add_box(root, Vector3(0.045, 0.15, 0.065), Vector3(0, -0.08, 0.04), mat_dark, Vector3(-0.26, 0, 0))
		if wid == "mastiff":
			_add_box(root, Vector3(0.15, 0.045, 0.08), Vector3(0, 0.025, -(0.08 + rec_len * 0.5 + bar_len)), mat_accent)
		_add_cyl(root, 0.020, 0.022, bar_len, Vector3(0, 0.025, -(0.08 + rec_len * 0.5 + bar_len * 0.5)), mat_steel, Vector3(PI * 0.5, 0, 0), 10)
		if cat != "PISTOL":
			_add_box(root, Vector3(0.054, 0.13, 0.22), Vector3(0, -0.01, rec_len * 0.5 + 0.04), mat_dark)
			if cat != "SHOTGUN" or wid == "eva8":
				_add_box(root, Vector3(0.055, 0.20, 0.085), Vector3(0, -0.14, -0.12), mat_accent, Vector3(0.22, 0, 0))
		var op := _add_box(root, Vector3(0.056, 0.06, 0.12), Vector3(0, rh * 0.5 + 0.04, -0.06), mat_dark)
		_add_cyl(op, 0.020, 0.020, 0.025, Vector3(0, 0.008, 0), mat_accent, Vector3(PI * 0.5, 0, 0), 10)

	var mflash := _add_sphere(root, 0.15, Vector3(0, 0.025, -(0.12 + rec_len * 0.5 + bar_len)), mat_flash, "BotMuzzleFlash")
	_add_cyl(mflash, 0.01, 0.13, 0.26, Vector3(0, 0, -0.12), mat_flash, Vector3(PI * 0.5, 0, 0), 8)
	mflash.visible = false
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

	var lid: String = str(legend_data.get("id", "wraith"))
	var h_info: Dictionary = legend_data.get("heirloom", {"color": Color("#ff1e42")})
	var h_col: Color = h_info.get("color", Color("#8b5cf6"))

	var mat_blade := _make_mat(Color("#f8fafc"), 0.92, 0.12)
	var mat_plasma := _make_mat(h_col, 0.4, 0.1, true, 3.6)
	var mat_hilt := _make_mat(Color("#1e293b"), 0.65, 0.35)
	var mat_gold := _make_mat(Color("#f59e0b"), 0.88, 0.20)

	if lid == "octane":
		_add_box(h_pivot, Vector3(0.022, 0.16, 0.026), Vector3(-0.018, -0.08, 0), mat_hilt, Vector3(0, 0, 0.08), "HandleLeft")
		_add_box(h_pivot, Vector3(0.022, 0.16, 0.026), Vector3(0.018, -0.08, 0), mat_hilt, Vector3(0, 0, -0.08), "HandleRight")
		_add_cyl(h_pivot, 0.009, 0.009, 0.12, Vector3(-0.018, -0.08, 0), mat_plasma, Vector3.ZERO, 8, "StimVial")
		_add_box(h_pivot, Vector3(0.012, 0.22, 0.036), Vector3(0, 0.11, 0), mat_blade, Vector3.ZERO, "TantoBlade")
		_add_box(h_pivot, Vector3(0.015, 0.22, 0.008), Vector3(0, 0.11, -0.016), mat_plasma, Vector3.ZERO, "PlasmaEdge")
	elif lid == "bloodhound":
		_add_cyl(h_pivot, 0.018, 0.020, 0.52, Vector3(0, 0.02, 0), mat_hilt, Vector3.ZERO, 10, "AxeShaft")
		_add_cyl(h_pivot, 0.024, 0.022, 0.06, Vector3(0, 0.22, 0), mat_gold, Vector3.ZERO, 10, "NordicCollar")
		_add_box(h_pivot, Vector3(0.024, 0.16, 0.18), Vector3(0, 0.20, -0.08), mat_blade, Vector3(0.15, 0, 0), "AxeHead")
		_add_box(h_pivot, Vector3(0.028, 0.18, 0.035), Vector3(0, 0.20, -0.17), mat_plasma, Vector3(0.15, 0, 0), "MoltenEdge")
		_add_cyl(h_pivot, 0.004, 0.022, 0.12, Vector3(0, 0.22, 0.07), mat_gold, Vector3(PI * 0.5, 0, 0), 6, "RavenSpike")
	else:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.026
		torus.outer_radius = 0.038
		ring.mesh = torus
		ring.material_override = mat_plasma
		ring.position = Vector3(0, -0.16, 0)
		ring.rotation.z = PI * 0.5
		h_pivot.add_child(ring)

		_add_cyl(h_pivot, 0.016, 0.018, 0.15, Vector3(0, -0.06, 0), mat_hilt, Vector3.ZERO, 8, "KunaiGrip")
		_add_box(h_pivot, Vector3(0.036, 0.024, 0.086), Vector3(0, 0.02, 0), mat_gold, Vector3.ZERO, "CrossGuard")
		_add_cyl(h_pivot, 0.003, 0.046, 0.30, Vector3(0, 0.18, 0), mat_blade, Vector3.ZERO, 4, "KunaiBlade")
		_add_box(h_pivot, Vector3(0.010, 0.26, 0.068), Vector3(0, 0.16, 0), mat_plasma, Vector3.ZERO, "VoidEdge")

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
