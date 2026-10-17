class_name LegendRigBuilder
extends RefCounted
## ============================================================================
## APEX LEGENDS ANATOMICAL HUMANOID SKELETON & THIRD-PERSON ANIMATION SYSTEM
## Upgrades:
## - Replaces boxy primitives with organic Mixamo/Humanoid-style CapsuleMesh, SphereMesh, and tapered CylinderMesh anatomy
##   (Clavicles, Deltoids, Tapered Biceps/Forearms, Spherical Elbows/Wrists/Knees/Ankles, Sculpted Ribcage, Contoured Pelvis & Boots)
## - Authentic Two-Handed 3rd-Person Weapon Holding & Pitch Aiming (`HeldWeaponRoot` gripped by Right Hand + Left Hand C-Clamp on Forend!)
## - Automatic Back Weapon Holster (`BackHolsterRoot` on `TorsoPivot`) that shows the weapon slung on the character's back when Healing or using Heirloom!
## - 3D Third-Person Held Consumables (`HeldBatteryProp` & `HeldSyringeProp`) with two-handed capacitor twist / injector animation
## - Upgraded Low-Friction Knee-Tuck Slide Animation (`滑铲`) with dual IMC Jumpkit plasma jet trails
## ============================================================================

static func _make_mat(col: Color, met: float = 0.5, rough: float = 0.4, emit: bool = false, emit_col: Color = Color.BLACK, emit_energy: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = met
	m.roughness = rough
	if emit:
		m.emission_enabled = true
		m.emission = emit_col
		m.emission_energy_multiplier = emit_energy
	return m

static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, segs: int = 14, name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	cm.radial_segments = segs
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _add_capsule(parent: Node3D, rad: float, h: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
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

static func _add_sphere(parent: Node3D, rad: float, pos: Vector3, mat: Material, name: String = "", scale_v: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
	var sm := SphereMesh.new()
	sm.radius = rad
	sm.height = rad * 2.0
	sm.radial_segments = 14
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	mi.scale = scale_v
	parent.add_child(mi)
	return mi

static func create_legend_rig(legend_data: Dictionary, weapon_id: String = "r301") -> Node3D:
	var lid: String = str(legend_data.get("id", "wraith"))
	var root := Node3D.new()
	root.name = "LegendRig_" + lid

	var col_prim: Color = legend_data.get("primary_color", Color("#312e81"))
	var col_sec: Color = legend_data.get("secondary_color", Color("#38bdf8"))
	var col_visor: Color = legend_data.get("visor_color", Color("#a78bfa"))
	var col_dark := Color("#0f172a")
	var col_suit := Color("#1e293b")
	var col_metal := Color("#cbd5e1")
	var col_glow := Color("#38bdf8")

	var mat_prim := _make_mat(col_prim, 0.52, 0.34)
	var mat_sec := _make_mat(col_sec, 0.78, 0.22)
	var mat_dark := _make_mat(col_dark, 0.38, 0.52)
	var mat_suit := _make_mat(col_suit, 0.30, 0.58)
	var mat_metal := _make_mat(col_metal, 0.94, 0.16)
	var mat_visor := _make_mat(col_visor, 0.2, 0.1, true, col_visor, 3.4)
	var mat_glow := _make_mat(col_glow, 0.1, 0.1, true, col_glow, 4.2)
	var mat_med_green := _make_mat(Color("#22c55e"), 0.1, 0.1, true, Color("#22c55e"), 3.8)
	var mat_med_red := _make_mat(Color("#ef4444"), 0.2, 0.2, true, Color("#ef4444"), 2.0)

	var wep_data: Dictionary = GameData.get_weapon_by_id(weapon_id if (weapon_id != "empty" and weapon_id != "") else "r301")

	# -------------------------------------------------------------------------
	# 1. ANATOMICAL PELVIS & IMC JUMPKIT ROOT (y = 0.96)
	# -------------------------------------------------------------------------
	var pelvis_pivot := Node3D.new()
	pelvis_pivot.name = "PelvisPivot"
	pelvis_pivot.position = Vector3(0, 0.96, 0)
	root.add_child(pelvis_pivot)

	# Smooth contoured pelvic capsule + tactical utility belt
	_add_capsule(pelvis_pivot, 0.15, 0.46, Vector3(0, -0.02, 0), mat_prim, Vector3(0, 0, PI * 0.5), "PelvisMesh")
	_add_cyl(pelvis_pivot, 0.21, 0.22, 0.11, Vector3(0, 0.07, 0), mat_dark, Vector3.ZERO, 16, "BeltMesh")
	_add_box(pelvis_pivot, Vector3(0.11, 0.09, 0.06), Vector3(-0.14, 0.07, -0.19), mat_sec, Vector3(0, 0.22, 0))
	_add_box(pelvis_pivot, Vector3(0.11, 0.09, 0.06), Vector3(0.14, 0.07, -0.19), mat_sec, Vector3(0, -0.22, 0))

	# Iconic Titanfall / Apex IMC Jumpkit on Lower Back
	var jumpkit := Node3D.new()
	jumpkit.name = "Jumpkit"
	jumpkit.position = Vector3(0, 0.04, 0.20)
	pelvis_pivot.add_child(jumpkit)
	_add_capsule(jumpkit, 0.08, 0.34, Vector3(0, 0, 0), mat_dark, Vector3(0, 0, PI * 0.5))
	_add_box(jumpkit, Vector3(0.32, 0.06, 0.14), Vector3(0, 0.05, 0), mat_sec)
	for js in [-1.0, 1.0]:
		_add_cyl(jumpkit, 0.042, 0.060, 0.12, Vector3(js * 0.12, -0.08, 0.02), mat_metal, Vector3(0.35, 0, js * 0.20))
		_add_cyl(jumpkit, 0.036, 0.036, 0.03, Vector3(js * 0.12, -0.14, 0.04), mat_glow, Vector3(0.35, 0, js * 0.20))
		var flame := _add_cyl(jumpkit, 0.005, 0.042, 0.24, Vector3(js * 0.12, -0.25, 0.08), mat_glow, Vector3(0.35, 0, js * 0.20), 10, "ThrusterFlameL" if js < 0.0 else "ThrusterFlameR")
		flame.visible = false

	# -------------------------------------------------------------------------
	# 2. ANATOMICAL LEGS, KNEES, CALVES & BOOTS (Left & Right)
	# -------------------------------------------------------------------------
	for side in [-1.0, 1.0]:
		var leg_pivot := Node3D.new()
		leg_pivot.name = "LeftLegPivot" if side < 0.0 else "RightLegPivot"
		leg_pivot.position = Vector3(side * 0.17, 0.86, 0)
		root.add_child(leg_pivot)

		# Hip Ball Joint + Tapered Muscular Thigh Capsule + Contoured Thigh Armor Plate
		_add_sphere(leg_pivot, 0.115, Vector3.ZERO, mat_suit, "HipJoint")
		_add_capsule(leg_pivot, 0.112, 0.48, Vector3(0, -0.22, 0), mat_suit, Vector3.ZERO, "ThighCore")
		_add_cyl(leg_pivot, 0.118, 0.105, 0.28, Vector3(0, -0.20, -0.01), mat_prim, Vector3.ZERO, 12, "ThighArmor")
		_add_box(leg_pivot, Vector3(0.05, 0.24, 0.14), Vector3(side * 0.10, -0.22, 0), mat_sec)

		if side > 0.0:
			var holster := _add_box(leg_pivot, Vector3(0.07, 0.22, 0.13), Vector3(0.12, -0.21, 0), mat_dark)
			_add_box(holster, Vector3(0.05, 0.07, 0.08), Vector3(0, 0.10, -0.02), mat_metal)

		var knee_pivot := Node3D.new()
		knee_pivot.name = "LeftKneePivot" if side < 0.0 else "RightKneePivot"
		knee_pivot.position = Vector3(0, -0.44, 0)
		leg_pivot.add_child(knee_pivot)

		if lid == "octane":
			# Octane Bionic Running-Blade Prosthetic Legs
			_add_sphere(knee_pivot, 0.082, Vector3.ZERO, mat_metal, "KneeJoint")
			_add_cyl(knee_pivot, 0.036, 0.028, 0.42, Vector3(0, -0.22, 0), mat_metal)
			_add_cyl(knee_pivot, 0.055, 0.048, 0.20, Vector3(0, -0.18, 0), mat_sec)
			_add_box(knee_pivot, Vector3(0.11, 0.05, 0.26), Vector3(0, -0.43, -0.05), mat_metal, Vector3(0.08, 0, 0))
		else:
			# Spherical Knee Joint + Beveled Tactical Knee Guard + Tapered Calf Capsule
			_add_sphere(knee_pivot, 0.092, Vector3.ZERO, mat_dark, "KneeJoint")
			_add_capsule(knee_pivot, 0.065, 0.16, Vector3(0, 0.01, -0.09), mat_sec, Vector3(-0.20, 0, 0), "KneeGuard")
			_add_capsule(knee_pivot, 0.095, 0.44, Vector3(0, -0.21, 0), mat_suit, Vector3.ZERO, "ShinCore")
			_add_cyl(knee_pivot, 0.100, 0.082, 0.30, Vector3(0, -0.20, -0.01), mat_prim, Vector3.ZERO, 12, "ShinGreave")

			# Ankle Joint & Sculpted Combat Boot
			var boot_root := Node3D.new()
			boot_root.position = Vector3(0, -0.41, 0)
			knee_pivot.add_child(boot_root)
			_add_sphere(boot_root, 0.075, Vector3(0, 0.04, 0), mat_dark, "AnkleJoint")
			_add_capsule(boot_root, 0.082, 0.30, Vector3(0, -0.01, -0.05), mat_dark, Vector3(PI * 0.5, 0, 0), "BootBody")
			_add_box(boot_root, Vector3(0.16, 0.06, 0.14), Vector3(0, 0.01, -0.13), mat_sec, Vector3(0.18, 0, 0))
			_add_box(boot_root, Vector3(0.17, 0.035, 0.32), Vector3(0, -0.06, -0.05), mat_dark)

	# -------------------------------------------------------------------------
	# 3. SPINE, SCULPTED CHEST ARMOR, EVO CORE & BACK WEAPON HOLSTER (y = 1.24)
	# -------------------------------------------------------------------------
	var torso_pivot := Node3D.new()
	torso_pivot.name = "TorsoPivot"
	torso_pivot.position = Vector3(0, 1.24, 0)
	root.add_child(torso_pivot)

	# Tapered Waist/Abdomen + Sculpted V-Taper Ribcage/Chest
	_add_cyl(torso_pivot, 0.21, 0.18, 0.26, Vector3(0, -0.18, 0), mat_suit, Vector3.ZERO, 16, "AbdomenMesh")
	var chest := _add_cyl(torso_pivot, 0.26, 0.21, 0.44, Vector3(0, 0.12, 0), mat_prim, Vector3.ZERO, 16, "TorsoMesh")
	# Contoured Pectoral Armor Plates
	for cs in [-1.0, 1.0]:
		_add_box(chest, Vector3(0.22, 0.24, 0.10), Vector3(cs * 0.11, 0.05, -0.16), mat_sec, Vector3(-0.08, cs * 0.18, 0), "ChestPlate")
	# Clavicle / Traps Collar
	_add_capsule(torso_pivot, 0.11, 0.58, Vector3(0, 0.30, 0), mat_prim, Vector3(0, 0, PI * 0.5), "ClavicleBar")

	# Glowing Evo Shield Core on Sternum & Spine Rig
	var core_node := _add_cyl(torso_pivot, 0.072, 0.072, 0.38, Vector3(0, 0.14, -0.03), mat_metal, Vector3(PI * 0.5, 0, 0), 12, "EvoCoreHousing")
	_add_cyl(core_node, 0.054, 0.054, 0.40, Vector3.ZERO, mat_visor, Vector3.ZERO, 8, "EvoCoreCrystal")
	_add_box(torso_pivot, Vector3(0.16, 0.38, 0.08), Vector3(0, 0.12, 0.20), mat_metal)

	# Back Holstered 3D Weapon (Appears automatically when Healing or using Heirloom!)
	var back_holster := Node3D.new()
	back_holster.name = "BackHolsterRoot"
	back_holster.position = Vector3(0.06, 0.16, 0.25)
	back_holster.rotation = Vector3(0.15, PI * 0.5, -0.68)
	back_holster.visible = false
	torso_pivot.add_child(back_holster)
	var holstered_wep_mesh := WeaponMeshBuilder.create_third_person_weapon_mesh(wep_data)
	holstered_wep_mesh.scale = Vector3(0.92, 0.92, 0.92)
	back_holster.add_child(holstered_wep_mesh)

	# -------------------------------------------------------------------------
	# 4. NECK & SCULPTED ANATOMICAL HEAD / HELMET
	# -------------------------------------------------------------------------
	var neck_pivot := Node3D.new()
	neck_pivot.name = "NeckPivot"
	neck_pivot.position = Vector3(0, 0.42, 0)
	torso_pivot.add_child(neck_pivot)

	_add_cyl(neck_pivot, 0.085, 0.105, 0.14, Vector3(0, 0.05, 0), mat_suit)

	var head := Node3D.new()
	head.name = "HeadMesh"
	head.position = Vector3(0, 0.20, 0)
	neck_pivot.add_child(head)

	if lid == "pathfinder":
		# Pathfinder MRVN Cyclops Head
		_add_capsule(head, 0.14, 0.34, Vector3(0, 0.04, 0), mat_prim, Vector3.ZERO)
		_add_cyl(head, 0.10, 0.11, 0.14, Vector3(0, 0.05, -0.14), mat_sec, Vector3(PI * 0.5, 0, 0), 16)
		_add_cyl(head, 0.075, 0.075, 0.16, Vector3(0, 0.05, -0.14), mat_visor, Vector3(PI * 0.5, 0, 0), 14)
	else:
		# Smooth Ovoid Cranium + Sculpted Jaw/Mask + Glowing Visor
		_add_sphere(head, 0.19, Vector3(0, 0.06, 0), mat_prim, "CraniumSphere", Vector3(0.92, 1.05, 0.98))
		_add_cyl(head, 0.15, 0.11, 0.18, Vector3(0, -0.04, -0.04), mat_sec, Vector3(0.15, 0, 0), 12, "JawGuard")
		_add_sphere(head, 0.175, Vector3(0, 0.14, 0.01), mat_sec, "HelmetCrown", Vector3(0.96, 0.65, 0.98))

		if lid == "bloodhound":
			for gs in [-1.0, 1.0]:
				_add_cyl(head, 0.055, 0.065, 0.10, Vector3(gs * 0.085, 0.05, -0.17), mat_visor, Vector3(PI * 0.5, 0, 0), 12)
		else:
			_add_cyl(head, 0.168, 0.162, 0.09, Vector3(0, 0.06, -0.03), mat_visor, Vector3(0.08, 0, 0), 14, "VisorMesh")

	# Tactical Comms Earpiece & Mic Boom
	_add_cyl(head, 0.05, 0.05, 0.05, Vector3(-0.18, 0.05, 0), mat_dark, Vector3(0, 0, PI * 0.5))
	_add_cyl(head, 0.006, 0.006, 0.20, Vector3(-0.18, 0.18, -0.03), mat_metal)

	# -------------------------------------------------------------------------
	# 5. LEGEND-SPECIFIC SILHOUETTES & SIGNATURE ACCESSORIES
	# -------------------------------------------------------------------------
	match lid:
		"wraith":
			_add_cyl(neck_pivot, 0.24, 0.28, 0.16, Vector3(0, 0.0, 0), mat_sec, Vector3.ZERO, 14)
			_add_sphere(head, 0.09, Vector3(0, 0.20, 0.14), mat_dark)
			var kunai_sheath := _add_box(pelvis_pivot, Vector3(0.05, 0.28, 0.09), Vector3(-0.24, -0.04, -0.04), mat_dark, Vector3(0.2, 0, 0.4))
			_add_box(kunai_sheath, Vector3(0.04, 0.08, 0.05), Vector3(0, 0.14, 0), mat_visor)
		"bloodhound":
			_add_cyl(head, 0.06, 0.36, 0.18, Vector3(0, 0.24, -0.01), mat_sec, Vector3(-0.10, 0, 0), 14)
			for hs in [-1.0, 1.0]:
				_add_cyl(head, 0.038, 0.038, 0.12, Vector3(hs * 0.11, -0.09, -0.15), mat_dark, Vector3(0.4, hs * 0.3, 0))
		"octane":
			for gs in [-1.0, 1.0]:
				_add_cyl(head, 0.052, 0.052, 0.08, Vector3(gs * 0.085, 0.08, -0.16), mat_glow, Vector3(PI * 0.5, 0, 0))
			_add_cyl(pelvis_pivot, 0.040, 0.040, 0.18, Vector3(-0.24, 0.06, 0), mat_glow, Vector3(0, 0, 0.3))
		"pathfinder":
			var scr := _add_box(torso_pivot, Vector3(0.26, 0.20, 0.06), Vector3(0, 0.14, -0.22), mat_dark)
			_add_box(scr, Vector3(0.22, 0.15, 0.02), Vector3(0, 0, -0.02), mat_visor)
		"gibraltar":
			_add_capsule(torso_pivot, 0.18, 0.72, Vector3(0, 0.24, 0.04), mat_prim, Vector3(0, 0, PI * 0.5))
			_add_box(torso_pivot, Vector3(0.42, 0.40, 0.20), Vector3(0, 0.14, 0.24), mat_sec)
		"valkyrie":
			for ws in [-1.0, 1.0]:
				var wing := Node3D.new()
				wing.position = Vector3(ws * 0.32, 0.22, 0.24)
				wing.rotation = Vector3(0.18, -ws * 0.25, -ws * 0.36)
				torso_pivot.add_child(wing)
				_add_box(wing, Vector3(0.14, 0.96, 0.34), Vector3(ws * 0.22, 0.26, 0), mat_sec)
				_add_cyl(wing, 0.055, 0.075, 0.28, Vector3(ws * 0.22, -0.16, 0.04), mat_metal, Vector3(-0.35, 0, 0))
		"bangalore":
			var launcher := Node3D.new()
			launcher.position = Vector3(-0.32, 0.38, 0.12)
			launcher.rotation = Vector3(-0.35, 0.25, -0.15)
			torso_pivot.add_child(launcher)
			for b_idx in range(3):
				_add_cyl(launcher, 0.032, 0.032, 0.24, Vector3((float(b_idx) - 1.0) * 0.075, 0, 0), mat_sec)
		"caustic":
			for ms in [-1.0, 1.0]:
				_add_cyl(head, 0.038, 0.048, 0.10, Vector3(ms * 0.09, -0.08, -0.17), mat_sec, Vector3(0.4, ms * 0.2, 0))
			for ts in [-1.0, 1.0]:
				_add_cyl(pelvis_pivot, 0.06, 0.06, 0.28, Vector3(ts * 0.16, -0.02, 0.24), mat_sec)
		"horizon":
			var newt := Node3D.new()
			newt.position = Vector3(0, 0.28, 0.24)
			torso_pivot.add_child(newt)
			_add_sphere(newt, 0.14, Vector3.ZERO, mat_sec)
			_add_sphere(newt, 0.09, Vector3(0, 0, 0.07), mat_glow)

	# -------------------------------------------------------------------------
	# 6. ANATOMICAL ARMS, ELBOWS, TWO-HANDED HELD WEAPON & HELD CONSUMABLES
	# -------------------------------------------------------------------------
	for side in [-1.0, 1.0]:
		# Sculpted Shoulder Pauldron
		_add_sphere(torso_pivot, 0.125, Vector3(side * 0.34, 0.28, 0), mat_sec, "ShoulderPauldron", Vector3(1.1, 0.9, 1.1))

		var arm_pivot := Node3D.new()
		arm_pivot.name = "LeftArmPivot" if side < 0.0 else "RightArmPivot"
		arm_pivot.position = Vector3(side * 0.34, 0.26, 0)
		torso_pivot.add_child(arm_pivot)

		var use_fuse_bionic: bool = (lid == "fuse" and side > 0.0)
		var arm_mat := mat_metal if use_fuse_bionic else mat_suit
		var plate_mat := mat_metal if use_fuse_bionic else mat_prim

		# Spherical Shoulder Joint + Tapered Bicep Capsule + Bicep Armor Plate
		_add_sphere(arm_pivot, 0.088, Vector3.ZERO, arm_mat, "ShoulderBall")
		_add_capsule(arm_pivot, 0.078, 0.36, Vector3(0, -0.16, 0), arm_mat, Vector3.ZERO, "BicepMesh")
		_add_cyl(arm_pivot, 0.084, 0.076, 0.20, Vector3(side * 0.01, -0.16, 0), plate_mat, Vector3.ZERO, 12)

		var elbow_pivot := Node3D.new()
		elbow_pivot.name = "LeftElbowPivot" if side < 0.0 else "RightElbowPivot"
		elbow_pivot.position = Vector3(0, -0.32, 0)
		arm_pivot.add_child(elbow_pivot)

		# Spherical Elbow Joint + Tapered Forearm Capsule + Armored Vambrace
		_add_sphere(elbow_pivot, 0.074, Vector3.ZERO, mat_metal, "ElbowJoint")
		_add_capsule(elbow_pivot, 0.070, 0.34, Vector3(0, -0.15, 0), arm_mat, Vector3.ZERO, "ForearmMesh")
		_add_cyl(elbow_pivot, 0.076, 0.064, 0.22, Vector3(0, -0.15, -0.01), plate_mat, Vector3.ZERO, 12)

		var hand_pos := Vector3(0, -0.32, 0)
		_add_sphere(elbow_pivot, 0.056, hand_pos + Vector3(0, 0.03, 0), mat_dark, "WristJoint")
		_add_box(elbow_pivot, Vector3(0.11, 0.10, 0.13), hand_pos, mat_dark, Vector3.ZERO, "HandMesh")
		_add_box(elbow_pivot, Vector3(0.10, 0.025, 0.08), hand_pos + Vector3(0, 0.04, 0.01), mat_sec, Vector3.ZERO, "KnucklePlate")
		_add_capsule(elbow_pivot, 0.022, 0.08, hand_pos + Vector3(side * 0.05, 0.01, -0.04), mat_dark, Vector3(0, side * 0.35, 0))

		# Left Forearm: Wrist HUD + 3D Consumable Props (Shield Battery & Syringe/Medkit!)
		if side < 0.0:
			if lid == "gibraltar":
				var g_shield := _add_box(elbow_pivot, Vector3(0.08, 0.50, 0.42), Vector3(-0.10, -0.15, -0.08), mat_visor, Vector3(0, 0.25, 0), "ArmGunShield")
				_add_box(g_shield, Vector3(0.03, 0.44, 0.36), Vector3(-0.03, 0, 0), mat_glow)
			else:
				var pad := _add_box(elbow_pivot, Vector3(0.09, 0.14, 0.03), Vector3(0, -0.15, -0.08), mat_dark)
				_add_box(pad, Vector3(0.07, 0.11, 0.015), Vector3(0, 0, -0.01), mat_visor)

			# 3D Third-Person Held Shield Battery Capacitor Prop
			var bat_node := Node3D.new()
			bat_node.name = "HeldBatteryProp"
			bat_node.position = hand_pos + Vector3(0.08, -0.02, -0.10)
			bat_node.visible = false
			elbow_pivot.add_child(bat_node)
			_add_cyl(bat_node, 0.082, 0.082, 0.28, Vector3.ZERO, mat_dark, Vector3(0, 0, PI * 0.5), 8)
			_add_cyl(bat_node, 0.070, 0.070, 0.18, Vector3.ZERO, mat_glow, Vector3(0, 0, PI * 0.5), 12, "TP_BatteryCore")
			_add_cyl(bat_node, 0.092, 0.092, 0.04, Vector3(0.13, 0, 0), mat_metal, Vector3(0, 0, PI * 0.5), 6)
			_add_cyl(bat_node, 0.092, 0.092, 0.04, Vector3(-0.13, 0, 0), mat_metal, Vector3(0, 0, PI * 0.5), 6)

			# 3D Third-Person Held Syringe / MedKit Auto-Injector Prop
			var syr_node := Node3D.new()
			syr_node.name = "HeldSyringeProp"
			syr_node.position = hand_pos + Vector3(0.06, -0.02, -0.10)
			syr_node.visible = false
			elbow_pivot.add_child(syr_node)
			_add_cyl(syr_node, 0.040, 0.040, 0.24, Vector3.ZERO, mat_metal, Vector3(PI * 0.5, 0, 0), 10)
			_add_cyl(syr_node, 0.044, 0.044, 0.10, Vector3(0, 0, -0.02), mat_med_green, Vector3(PI * 0.5, 0, 0), 10)
			_add_box(syr_node, Vector3(0.06, 0.02, 0.06), Vector3(0, 0, 0.11), mat_med_red)

		# Right Arm: Held Authentic 3D Weapon (Two-Handed Aim Pose!)
		if side > 0.0:
			arm_pivot.rotation = Vector3(0.58, -0.22, 0.08)
			elbow_pivot.rotation = Vector3(0.82, -0.16, 0.0)

			var weapon_root := Node3D.new()
			weapon_root.name = "HeldWeaponRoot"
			weapon_root.position = hand_pos + Vector3(-0.04, -0.02, -0.10)
			# Counter-rotate so rifle barrel points straight forward (-Z of character torso) while both hands grip it!
			weapon_root.rotation = Vector3(-1.38, 0.32, -0.06)
			elbow_pivot.add_child(weapon_root)

			var tp_wep := WeaponMeshBuilder.create_third_person_weapon_mesh(wep_data)
			weapon_root.add_child(tp_wep)

	# Set default Left Arm into Two-Handed Rifle Forend Grip Pose so even before first animate_rig tick it holds the gun!
	var init_arm_l: Node3D = torso_pivot.get_node_or_null("LeftArmPivot")
	var init_elbow_l: Node3D = init_arm_l.get_node_or_null("LeftElbowPivot") if init_arm_l else null
	if init_arm_l and init_elbow_l:
		init_arm_l.rotation = Vector3(0.76, 0.52, -0.22)
		init_elbow_l.rotation = Vector3(0.88, 0.24, 0.0)

	root.scale = legend_data.get("scale", Vector3.ONE)
	return root

static func animate_rig(rig: Node3D, delta: float, s: Dictionary) -> void:
	if not is_instance_valid(rig):
		return

	var pelvis_p: Node3D = rig.get_node_or_null("PelvisPivot")
	var torso_p: Node3D = rig.get_node_or_null("TorsoPivot")
	var leg_l: Node3D = rig.get_node_or_null("LeftLegPivot")
	var leg_r: Node3D = rig.get_node_or_null("RightLegPivot")
	var arm_l: Node3D = torso_p.get_node_or_null("LeftArmPivot") if torso_p else null
	var arm_r: Node3D = torso_p.get_node_or_null("RightArmPivot") if torso_p else null
	var knee_l: Node3D = leg_l.get_node_or_null("LeftKneePivot") if leg_l else null
	var knee_r: Node3D = leg_r.get_node_or_null("RightKneePivot") if leg_r else null
	var elbow_l: Node3D = arm_l.get_node_or_null("LeftElbowPivot") if arm_l else null
	var elbow_r: Node3D = arm_r.get_node_or_null("RightElbowPivot") if arm_r else null
	var neck_p: Node3D = torso_p.get_node_or_null("NeckPivot") if torso_p else null

	var mode: String = str(s.get("mode", "idle"))
	var is_moving: bool = bool(s.get("is_moving", false))
	var is_crouching: bool = bool(s.get("is_crouching", false))
	var is_sliding: bool = bool(s.get("is_sliding", false))
	var is_in_air: bool = bool(s.get("is_in_air", false))
	var is_ziplining: bool = bool(s.get("is_ziplining", false))
	var is_grappling: bool = bool(s.get("is_grappling", false))
	var is_healing: bool = bool(s.get("is_healing", false))
	var heal_id: String = str(s.get("heal_id", "shield_battery"))
	var is_heirloom: bool = bool(s.get("is_heirloom", false))
	var is_reloading: bool = bool(s.get("is_reloading", false))
	var is_firing: bool = bool(s.get("is_firing", false))
	var is_ads: bool = bool(s.get("is_ads", false))
	var aim_pitch: float = clampf(float(s.get("aim_pitch", 0.0)), -0.85, 0.85)
	var phase: float = float(s.get("strafe_phase", 0.0))
	var strafe_dir: float = float(s.get("strafe_dir", 1.0))
	var flinch: float = float(s.get("hit_flinch", 0.0))
	var death_time: float = float(s.get("death_time", -1.0))
	var speed: float = float(s.get("speed", 0.0))
	var t: float = float(s.get("time", Time.get_ticks_msec() / 1000.0))

	# Dynamic IMC Jumpkit Jet Thrusters
	var thruster_l: Node3D = rig.find_child("ThrusterFlameL", true, false)
	var thruster_r: Node3D = rig.find_child("ThrusterFlameR", true, false)
	var flame_on: bool = is_sliding or is_in_air or (is_moving and speed > 9.2)
	if thruster_l:
		thruster_l.visible = flame_on
		if flame_on:
			thruster_l.scale = Vector3.ONE * (1.85 if is_sliding else (1.18 + sin(t * 26.0) * 0.22))
	if thruster_r:
		thruster_r.visible = flame_on
		if flame_on:
			thruster_r.scale = Vector3.ONE * (1.85 if is_sliding else (1.18 + cos(t * 26.0) * 0.22))

	# Toggle 3rd-Person Held Weapon vs Back Holster vs Consumable Props (Shield Battery / Syringe)
	var wep_mesh: Node3D = rig.find_child("HeldWeaponRoot", true, false)
	var back_holster: Node3D = rig.find_child("BackHolsterRoot", true, false)
	var bat_prop: Node3D = rig.find_child("HeldBatteryProp", true, false)
	var syr_prop: Node3D = rig.find_child("HeldSyringeProp", true, false)
	var is_bat_heal: bool = (heal_id == "shield_battery" or heal_id == "shield_cell" or heal_id == "phoenix_kit")

	var holster_gun_now: bool = is_heirloom or is_healing
	if wep_mesh:
		wep_mesh.visible = (not holster_gun_now) and (mode != "death")
	if back_holster:
		back_holster.visible = holster_gun_now and (mode != "death")
	if bat_prop:
		bat_prop.visible = is_healing and is_bat_heal and (mode != "death")
		if bat_prop.visible:
			bat_prop.rotation.x = t * 5.5
	if syr_prop:
		syr_prop.visible = is_healing and (not is_bat_heal) and (mode != "death")

	# 1. ELIMINATION DEATH COLLAPSE ANIMATION
	if death_time >= 0.0:
		var p: float = clampf(death_time / 0.38, 0.0, 1.0)
		var ease_p: float = 1.0 - pow(1.0 - p, 3.0)
		if pelvis_p:
			pelvis_p.position.y = lerpf(0.96, 0.28, ease_p)
		if torso_p:
			torso_p.position.y = lerpf(1.24, 0.38, ease_p)
			torso_p.rotation.x = lerpf(0.0, -0.85, ease_p)
			torso_p.rotation.z = lerpf(0.0, 0.42, ease_p)
		if leg_l and knee_l:
			leg_l.rotation.x = lerpf(0.0, 0.85, ease_p)
			knee_l.rotation.x = lerpf(0.0, 1.55, ease_p)
		if leg_r and knee_r:
			leg_r.rotation.x = lerpf(0.0, -0.45, ease_p)
			knee_r.rotation.x = lerpf(0.0, 1.35, ease_p)
		if arm_l:
			arm_l.rotation = arm_l.rotation.lerp(Vector3(-0.4, 0.6, 0.8), delta * 12.0)
		if arm_r:
			arm_r.rotation = arm_r.rotation.lerp(Vector3(-0.6, -0.4, -0.7), delta * 12.0)
		return

	# 2. MAIN LOBBY HERO SHOWCASE ANIMATION (With Two-Handed Tactical Ready Pose)
	if mode == "lobby":
		var breath: float = sin(t * 2.2) * 0.024
		var sway: float = cos(t * 1.1) * 0.018
		if pelvis_p:
			pelvis_p.position.y = lerpf(pelvis_p.position.y, 0.96 + breath * 0.15, delta * 8.0)
		if torso_p:
			torso_p.position.y = lerpf(torso_p.position.y, 1.24 + breath * 0.25, delta * 8.0)
			torso_p.rotation.x = lerpf(torso_p.rotation.x, breath, delta * 6.0)
			torso_p.rotation.y = lerpf(torso_p.rotation.y, sway * 1.5, delta * 5.0)
			torso_p.rotation.z = lerpf(torso_p.rotation.z, sway * 0.5, delta * 5.0)
		if neck_p:
			neck_p.rotation.y = lerpf(neck_p.rotation.y, -sway * 2.0, delta * 4.0)
			neck_p.rotation.x = lerpf(neck_p.rotation.x, -breath * 0.5, delta * 6.0)
		if arm_r and elbow_r:
			arm_r.rotation = arm_r.rotation.lerp(Vector3(0.54 + breath, -0.22, 0.08), delta * 8.0)
			elbow_r.rotation = elbow_r.rotation.lerp(Vector3(0.82, -0.16, 0.0), delta * 8.0)
		if arm_l and elbow_l:
			arm_l.rotation = arm_l.rotation.lerp(Vector3(0.72 + breath, 0.52, -0.20), delta * 8.0)
			elbow_l.rotation = elbow_l.rotation.lerp(Vector3(0.88, 0.24, 0.0), delta * 8.0)
		if leg_l and knee_l:
			leg_l.rotation = leg_l.rotation.lerp(Vector3(0.08, 0, -0.05), delta * 6.0)
			knee_l.rotation.x = lerpf(knee_l.rotation.x, 0.12, delta * 6.0)
		if leg_r and knee_r:
			leg_r.rotation = leg_r.rotation.lerp(Vector3(-0.04, 0, 0.05), delta * 6.0)
			knee_r.rotation.x = lerpf(knee_r.rotation.x, 0.06, delta * 6.0)
		return

	# 3. SPECIAL MOTION STATES: MOMENTUM SLIDING (`滑铲`), AIRBORNE, ZIPLINING
	if is_sliding:
		# Authentic Apex Legends Low-Friction Slide: Pelvis & Torso drop low, Left leg extends forward, Right knee tucks deep,
		# and Both Hands hold the weapon canted across the chest while aiming!
		if pelvis_p:
			pelvis_p.position.y = lerpf(pelvis_p.position.y, 0.48, delta * 16.0)
			pelvis_p.rotation.x = lerpf(pelvis_p.rotation.x, -0.32, delta * 16.0)
		if torso_p:
			torso_p.position.y = lerpf(torso_p.position.y, 0.62, delta * 16.0)
			torso_p.rotation.x = lerpf(torso_p.rotation.x, -0.28 + aim_pitch * 0.45, delta * 16.0)
			torso_p.rotation.z = lerpf(torso_p.rotation.z, -0.18 * (strafe_dir if absf(strafe_dir) > 0.1 else 1.0), delta * 14.0)
		if leg_l and knee_l:
			leg_l.position.y = lerpf(leg_l.position.y, 0.48, delta * 16.0)
			leg_l.rotation.x = lerpf(leg_l.rotation.x, 1.08, delta * 18.0)
			knee_l.rotation.x = lerpf(knee_l.rotation.x, 0.18, delta * 18.0)
		if leg_r and knee_r:
			leg_r.position.y = lerpf(leg_r.position.y, 0.48, delta * 16.0)
			leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.35, delta * 18.0)
			knee_r.rotation.x = lerpf(knee_r.rotation.x, 1.58, delta * 18.0)
		if is_healing:
			if arm_l and elbow_l:
				arm_l.rotation = arm_l.rotation.lerp(Vector3(0.78, 0.46, -0.32), delta * 14.0)
				elbow_l.rotation.x = lerpf(elbow_l.rotation.x, 1.28, delta * 14.0)
			if arm_r and elbow_r:
				arm_r.rotation = arm_r.rotation.lerp(Vector3(0.82, -0.48, 0.28), delta * 14.0)
				elbow_r.rotation.x = lerpf(elbow_r.rotation.x, 1.25, delta * 14.0)
		else:
			if arm_r and elbow_r:
				arm_r.rotation = arm_r.rotation.lerp(Vector3(0.62 + aim_pitch * 0.5, -0.20, 0.12), delta * 16.0)
				elbow_r.rotation = elbow_r.rotation.lerp(Vector3(0.80, -0.16, 0.0), delta * 16.0)
			if arm_l and elbow_l:
				arm_l.rotation = arm_l.rotation.lerp(Vector3(0.74 + aim_pitch * 0.5, 0.48, -0.26), delta * 16.0)
				elbow_l.rotation = elbow_l.rotation.lerp(Vector3(0.86, 0.22, 0.0), delta * 16.0)
		return

	# Restore leg hip height when not sliding
	var hip_y: float = 0.66 if is_crouching else 0.86
	if pelvis_p:
		pelvis_p.position.y = lerpf(pelvis_p.position.y, 0.72 if is_crouching else 0.96, delta * 14.0)
		pelvis_p.rotation.x = lerpf(pelvis_p.rotation.x, 0.0, delta * 14.0)
	if leg_l:
		leg_l.position.y = lerpf(leg_l.position.y, hip_y, delta * 14.0)
	if leg_r:
		leg_r.position.y = lerpf(leg_r.position.y, hip_y, delta * 14.0)

	if is_ziplining or is_grappling:
		if torso_p:
			torso_p.position.y = lerpf(torso_p.position.y, 1.24, delta * 12.0)
			torso_p.rotation.x = lerpf(torso_p.rotation.x, -0.22, delta * 12.0)
			torso_p.rotation.z = lerpf(torso_p.rotation.z, sin(t * 3.5) * 0.08, delta * 10.0)
		if arm_l and elbow_l:
			arm_l.rotation = arm_l.rotation.lerp(Vector3(2.35, 0.15, -0.18), delta * 14.0)
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x, 0.35, delta * 14.0)
		if arm_r and elbow_r:
			arm_r.rotation = arm_r.rotation.lerp(Vector3(2.35, -0.15, 0.18), delta * 14.0)
			elbow_r.rotation.x = lerpf(elbow_r.rotation.x, 0.35, delta * 14.0)
		if leg_l and leg_r:
			leg_l.rotation.x = lerpf(leg_l.rotation.x, -0.25 + sin(t * 3.0) * 0.15, delta * 10.0)
			leg_r.rotation.x = lerpf(leg_r.rotation.x, -0.20 - sin(t * 3.0) * 0.15, delta * 10.0)
		return

	if is_in_air:
		if torso_p:
			torso_p.position.y = lerpf(torso_p.position.y, 1.20, delta * 14.0)
			torso_p.rotation.x = lerpf(torso_p.rotation.x, 0.12 - aim_pitch * 0.35, delta * 12.0)
		if leg_l and knee_l:
			leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.42, delta * 14.0)
			knee_l.rotation.x = lerpf(knee_l.rotation.x, 0.68, delta * 14.0)
		if leg_r and knee_r:
			leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.25, delta * 14.0)
			knee_r.rotation.x = lerpf(knee_r.rotation.x, 0.82, delta * 14.0)
		if arm_r and elbow_r:
			arm_r.rotation = arm_r.rotation.lerp(Vector3(0.58 + aim_pitch * 0.6, -0.22, 0.08), delta * 14.0)
			elbow_r.rotation = elbow_r.rotation.lerp(Vector3(0.82, -0.16, 0.0), delta * 14.0)
		if arm_l and elbow_l:
			arm_l.rotation = arm_l.rotation.lerp(Vector3(0.74 + aim_pitch * 0.6, 0.50, -0.22), delta * 14.0)
			elbow_l.rotation = elbow_l.rotation.lerp(Vector3(0.88, 0.24, 0.0), delta * 14.0)
		return

	# 4. IN-GAME GROUND COMBAT, TWO-HANDED AIMING, HEALING & LOCOMOTION ANIMATION
	var swing: float = sin(phase * 1.8) * 0.56 if is_moving else 0.0
	var knee_swing_l: float = maxf(0.0, -swing * 1.18) if is_moving else 0.0
	var knee_swing_r: float = maxf(0.0, swing * 1.18) if is_moving else 0.0

	var target_torso_y: float = 0.92 if is_crouching else (1.24 + (absf(cos(phase * 1.8)) * 0.035 if is_moving else 0.0))
	var target_torso_rot_x: float = (0.18 if is_crouching else (0.06 if is_moving else 0.02)) - aim_pitch * 0.35 - flinch * 0.38
	var target_torso_rot_z: float = (-0.07 * strafe_dir if is_moving else 0.0) + flinch * 0.22

	if torso_p:
		torso_p.position.y = lerpf(torso_p.position.y, target_torso_y, delta * 14.0)
		torso_p.rotation.x = lerpf(torso_p.rotation.x, target_torso_rot_x, delta * 14.0)
		torso_p.rotation.y = lerpf(torso_p.rotation.y, 0.14 if is_ads else 0.08, delta * 12.0)
		torso_p.rotation.z = lerpf(torso_p.rotation.z, target_torso_rot_z, delta * 12.0)

	if neck_p:
		neck_p.rotation.x = lerpf(neck_p.rotation.x, -aim_pitch * 0.45, delta * 14.0)
		neck_p.rotation.y = lerpf(neck_p.rotation.y, -0.14 if is_ads else -0.08, delta * 12.0)

	if leg_l and leg_r:
		var base_leg_x: float = 0.52 if is_crouching else 0.0
		leg_l.rotation.x = lerpf(leg_l.rotation.x, swing + base_leg_x, delta * 16.0)
		leg_r.rotation.x = lerpf(leg_r.rotation.x, -swing + base_leg_x, delta * 16.0)

	if knee_l and knee_r:
		var crouch_knee: float = 0.92 if is_crouching else 0.08
		knee_l.rotation.x = lerpf(knee_l.rotation.x, knee_swing_l + crouch_knee, delta * 18.0)
		knee_r.rotation.x = lerpf(knee_r.rotation.x, knee_swing_r + crouch_knee, delta * 18.0)

	# Left & Right Arms: Coordinate Two-Handed Weapon Aiming / Battery Twist / Syringe Injection / Reload!
	var recoil_kick: float = 0.18 if is_firing else 0.0
	var breath_bob: float = sin(t * 2.6) * 0.02

	if arm_l and elbow_l:
		if is_healing:
			var heal_bob: float = sin(t * 8.0) * 0.08
			arm_l.rotation = arm_l.rotation.lerp(Vector3(0.78 + heal_bob, 0.46, -0.32), delta * 14.0)
			elbow_l.rotation = elbow_l.rotation.lerp(Vector3(1.28, 0.15, 0.0), delta * 14.0)
		elif is_reloading:
			var r_t: float = sin(t * 7.5)
			arm_l.rotation = arm_l.rotation.lerp(Vector3(0.28, 0.35, -0.38) if r_t < 0.0 else Vector3(0.74, 0.48, -0.20), delta * 15.0)
			elbow_l.rotation = elbow_l.rotation.lerp(Vector3(1.15, 0.20, 0.0), delta * 15.0)
		elif is_heirloom:
			arm_l.rotation = arm_l.rotation.lerp(Vector3(0.68 - swing * 0.25, 0.42, -0.28), delta * 12.0)
			elbow_l.rotation = elbow_l.rotation.lerp(Vector3(1.25, 0.0, 0.0), delta * 12.0)
		else:
			# AUTHENTIC TWO-HANDED FOREGRIP / HANDGUARD HOLD (Even while moving/strafing!)
			var sprint_cant: float = 0.12 if (is_moving and speed > 11.5 and not is_firing and not is_ads) else 0.0
			var l_pitch: float = (0.82 if is_ads else 0.76) + aim_pitch * 0.65 + recoil_kick * 0.8 + breath_bob - sprint_cant
			arm_l.rotation = arm_l.rotation.lerp(Vector3(l_pitch, 0.52, -0.22 - sprint_cant), delta * 16.0)
			elbow_l.rotation = elbow_l.rotation.lerp(Vector3(0.88, 0.24, 0.0), delta * 16.0)

	if arm_r and elbow_r:
		if is_healing:
			var twist_w: float = cos(t * 10.0) * 0.14
			arm_r.rotation = arm_r.rotation.lerp(Vector3(0.82, -0.48, 0.28 + twist_w), delta * 14.0)
			elbow_r.rotation = elbow_r.rotation.lerp(Vector3(1.25 + twist_w * 0.4, -0.15, 0.0), delta * 14.0)
		elif is_heirloom:
			arm_r.rotation = arm_r.rotation.lerp(Vector3(0.55 + swing * 0.25, -0.25, 0.18), delta * 12.0)
			elbow_r.rotation = elbow_r.rotation.lerp(Vector3(1.15, 0.0, 0.0), delta * 12.0)
		else:
			# AUTHENTIC TWO-HANDED SHOULDER STOCK / PISTOL GRIP HOLD
			var r_pitch: float = (0.64 if is_ads else 0.58) + aim_pitch * 0.65 + recoil_kick + breath_bob + flinch * 0.28
			arm_r.rotation = arm_r.rotation.lerp(Vector3(r_pitch, -0.22, 0.08), delta * 16.0)
			elbow_r.rotation = elbow_r.rotation.lerp(Vector3(0.82 - recoil_kick * 0.4, -0.16, 0.0), delta * 16.0)
