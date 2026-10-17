class_name LegendRigBuilder
extends RefCounted
## ============================================================================
## APEX LEGENDS HIGH-FIDELITY ARTICULATED CHARACTER RIG & ANIMATION SYSTEM
## Features:
## - Full Multi-Segment Skeletal Anatomy (Pelvis, Articulated Legs/Knees/Boots, Torso/Chest/Jumpkit, Neck/Head, Arms/Elbows/Hands)
## - Detailed Signature Silhouette Accessories for ALL 12 Outlands Legends
## - 3D Third-Person Held Consumable Props (HeldBatteryProp & HeldSyringeProp on LeftElbowPivot)
##   so both Player (in 3rd-person) and AI Bots visually display authentic Shield Battery & Medkit/Syringe animations!
## - Anti-Clipping Joint Angles for Crouch, Slide, Air, Reload, and Consumable Healing
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

static func _add_cyl(parent: Node3D, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, segs: int = 12, name: String = "") -> MeshInstance3D:
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

static func _add_sphere(parent: Node3D, rad: float, pos: Vector3, mat: Material, name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
	var sm := SphereMesh.new()
	sm.radius = rad
	sm.height = rad * 2.0
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

static func create_legend_rig(legend_data: Dictionary) -> Node3D:
	var lid: String = str(legend_data.get("id", "wraith"))
	var root := Node3D.new()
	root.name = "LegendRig_" + lid

	var col_prim: Color = legend_data.get("primary_color", Color("#312e81"))
	var col_sec: Color = legend_data.get("secondary_color", Color("#38bdf8"))
	var col_visor: Color = legend_data.get("visor_color", Color("#a78bfa"))
	var col_dark := Color("#0f172a")
	var col_metal := Color("#cbd5e1")
	var col_glow := Color("#38bdf8")

	var mat_prim := _make_mat(col_prim, 0.48, 0.36)
	var mat_sec := _make_mat(col_sec, 0.76, 0.24)
	var mat_dark := _make_mat(col_dark, 0.35, 0.55)
	var mat_metal := _make_mat(col_metal, 0.94, 0.16)
	var mat_visor := _make_mat(col_visor, 0.2, 0.1, true, col_visor, 3.4)
	var mat_glow := _make_mat(col_glow, 0.1, 0.1, true, col_glow, 4.2)
	var mat_flash := _make_mat(Color("#fbbf24"), 0.1, 0.1, true, Color("#f97316"), 5.0)
	var mat_med_green := _make_mat(Color("#22c55e"), 0.1, 0.1, true, Color("#22c55e"), 3.8)
	var mat_med_red := _make_mat(Color("#ef4444"), 0.2, 0.2, true, Color("#ef4444"), 2.0)

	# -------------------------------------------------------------------------
	# 1. PELVIS & LOWER BODY ROOT (y = 0.96)
	# -------------------------------------------------------------------------
	var pelvis_pivot := Node3D.new()
	pelvis_pivot.name = "PelvisPivot"
	pelvis_pivot.position = Vector3(0, 0.96, 0)
	root.add_child(pelvis_pivot)

	_add_box(pelvis_pivot, Vector3(0.54, 0.24, 0.36), Vector3(0, 0, 0), mat_prim, Vector3.ZERO, "PelvisMesh")
	_add_box(pelvis_pivot, Vector3(0.58, 0.11, 0.40), Vector3(0, 0.08, 0), mat_dark, Vector3.ZERO, "BeltMesh")
	_add_box(pelvis_pivot, Vector3(0.13, 0.11, 0.07), Vector3(-0.16, 0.08, -0.21), mat_sec)
	_add_box(pelvis_pivot, Vector3(0.13, 0.11, 0.07), Vector3(0.16, 0.08, -0.21), mat_sec)
	_add_cyl(pelvis_pivot, 0.03, 0.03, 0.11, Vector3(-0.29, 0.08, 0), mat_metal, Vector3(0, 0, PI * 0.5))

	# Iconic Titanfall / Apex IMC Jumpkit
	var jumpkit := Node3D.new()
	jumpkit.name = "Jumpkit"
	jumpkit.position = Vector3(0, 0.04, 0.22)
	pelvis_pivot.add_child(jumpkit)
	_add_box(jumpkit, Vector3(0.36, 0.22, 0.15), Vector3(0, 0, 0), mat_dark)
	_add_box(jumpkit, Vector3(0.38, 0.06, 0.17), Vector3(0, 0.07, 0), mat_sec)
	for js in [-1.0, 1.0]:
		_add_cyl(jumpkit, 0.045, 0.065, 0.12, Vector3(js * 0.12, -0.09, 0.02), mat_metal, Vector3(0.35, 0, js * 0.18))
		_add_cyl(jumpkit, 0.038, 0.038, 0.03, Vector3(js * 0.12, -0.15, 0.04), mat_glow, Vector3(0.35, 0, js * 0.18))
		var flame := _add_cyl(jumpkit, 0.005, 0.036, 0.18, Vector3(js * 0.12, -0.24, 0.07), mat_glow, Vector3(0.35, 0, js * 0.18), 8, "ThrusterFlameL" if js < 0.0 else "ThrusterFlameR")
		flame.visible = false

	# -------------------------------------------------------------------------
	# 2. ARTICULATED LEGS & KNEES (Left & Right)
	# -------------------------------------------------------------------------
	for side in [-1.0, 1.0]:
		var leg_pivot := Node3D.new()
		leg_pivot.name = "LeftLegPivot" if side < 0.0 else "RightLegPivot"
		leg_pivot.position = Vector3(side * 0.20, 0.84, 0)
		root.add_child(leg_pivot)

		_add_box(leg_pivot, Vector3(0.24, 0.44, 0.26), Vector3(0, -0.22, 0), mat_dark, Vector3.ZERO, "ThighCore")
		_add_box(leg_pivot, Vector3(0.26, 0.32, 0.10), Vector3(0, -0.20, -0.10), mat_prim)
		_add_box(leg_pivot, Vector3(0.08, 0.24, 0.20), Vector3(side * 0.11, -0.22, 0), mat_sec)

		if side > 0.0:
			var holster := _add_box(leg_pivot, Vector3(0.09, 0.26, 0.15), Vector3(0.14, -0.22, 0), mat_dark)
			_add_box(holster, Vector3(0.07, 0.08, 0.09), Vector3(0, 0.12, -0.03), mat_metal)

		var knee_pivot := Node3D.new()
		knee_pivot.name = "LeftKneePivot" if side < 0.0 else "RightKneePivot"
		knee_pivot.position = Vector3(0, -0.44, 0)
		leg_pivot.add_child(knee_pivot)

		if lid == "octane":
			_add_cyl(knee_pivot, 0.07, 0.07, 0.18, Vector3.ZERO, mat_metal, Vector3(0, 0, PI * 0.5))
			_add_cyl(knee_pivot, 0.032, 0.032, 0.44, Vector3(0, -0.22, 0), mat_metal)
			_add_cyl(knee_pivot, 0.052, 0.052, 0.24, Vector3(0, -0.22, 0), mat_sec)
			_add_box(knee_pivot, Vector3(0.12, 0.06, 0.28), Vector3(0, -0.44, -0.06), mat_metal)
		else:
			_add_cyl(knee_pivot, 0.075, 0.075, 0.18, Vector3.ZERO, mat_metal, Vector3(0, 0, PI * 0.5))
			_add_box(knee_pivot, Vector3(0.20, 0.16, 0.12), Vector3(0, 0.02, -0.10), mat_sec, Vector3(-0.25, 0, 0), "KneeGuard")
			_add_box(knee_pivot, Vector3(0.22, 0.42, 0.24), Vector3(0, -0.22, 0), mat_dark, Vector3.ZERO, "ShinCore")
			_add_box(knee_pivot, Vector3(0.18, 0.36, 0.07), Vector3(0, -0.20, -0.10), mat_prim)
			_add_cyl(knee_pivot, 0.022, 0.022, 0.34, Vector3(0, -0.22, 0.09), mat_metal)

			var boot_root := Node3D.new()
			boot_root.position = Vector3(0, -0.42, 0)
			knee_pivot.add_child(boot_root)
			_add_box(boot_root, Vector3(0.22, 0.14, 0.36), Vector3(0, 0.05, -0.06), mat_dark)
			_add_box(boot_root, Vector3(0.20, 0.09, 0.14), Vector3(0, 0.05, -0.19), mat_sec)
			_add_box(boot_root, Vector3(0.24, 0.04, 0.40), Vector3(0, -0.02, -0.06), mat_dark)

	# -------------------------------------------------------------------------
	# 3. TORSO, CHEST ARMOR & EVO CORE (y = 1.26)
	# -------------------------------------------------------------------------
	var torso_pivot := Node3D.new()
	torso_pivot.name = "TorsoPivot"
	torso_pivot.position = Vector3(0, 1.26, 0)
	root.add_child(torso_pivot)

	_add_box(torso_pivot, Vector3(0.50, 0.24, 0.32), Vector3(0, -0.22, 0), mat_dark, Vector3.ZERO, "AbdomenMesh")
	var chest := _add_box(torso_pivot, Vector3(0.68, 0.50, 0.40), Vector3(0, 0.12, 0), mat_prim, Vector3.ZERO, "TorsoMesh")
	_add_box(chest, Vector3(0.58, 0.36, 0.10), Vector3(0, 0.04, -0.18), mat_sec, Vector3.ZERO, "ChestPlate")

	var core_node := _add_cyl(torso_pivot, 0.095, 0.095, 0.44, Vector3(0, 0.14, 0), mat_metal, Vector3(PI * 0.5, 0, 0), 12, "EvoCoreHousing")
	_add_cyl(core_node, 0.075, 0.075, 0.46, Vector3.ZERO, mat_visor, Vector3.ZERO, 8, "EvoCoreCrystal")
	_add_box(torso_pivot, Vector3(0.18, 0.42, 0.09), Vector3(0, 0.12, 0.22), mat_metal)

	# -------------------------------------------------------------------------
	# 4. NECK & SCULPTED HEAD HELMET
	# -------------------------------------------------------------------------
	var neck_pivot := Node3D.new()
	neck_pivot.name = "NeckPivot"
	neck_pivot.position = Vector3(0, 0.48, 0)
	torso_pivot.add_child(neck_pivot)

	_add_cyl(neck_pivot, 0.12, 0.14, 0.12, Vector3(0, 0.06, 0), mat_dark)

	var head := Node3D.new()
	head.name = "HeadMesh"
	head.position = Vector3(0, 0.20, 0)
	neck_pivot.add_child(head)

	_add_box(head, Vector3(0.42, 0.44, 0.44), Vector3(0, 0.06, 0), mat_prim)
	_add_box(head, Vector3(0.38, 0.20, 0.18), Vector3(0, -0.06, -0.16), mat_sec, Vector3(0.22, 0, 0))
	_add_box(head, Vector3(0.44, 0.08, 0.36), Vector3(0, 0.24, 0.02), mat_sec)

	if lid == "bloodhound":
		for gs in [-1.0, 1.0]:
			_add_cyl(head, 0.065, 0.075, 0.10, Vector3(gs * 0.11, 0.06, -0.22), mat_visor, Vector3(PI * 0.5, 0, 0), 10)
	elif lid == "pathfinder":
		_add_cyl(head, 0.11, 0.13, 0.14, Vector3(0, 0.06, -0.22), mat_sec, Vector3(PI * 0.5, 0, 0), 14)
		_add_cyl(head, 0.085, 0.085, 0.16, Vector3(0, 0.06, -0.22), mat_visor, Vector3(PI * 0.5, 0, 0), 12)
	else:
		_add_box(head, Vector3(0.38, 0.13, 0.46), Vector3(0, 0.07, -0.02), mat_visor, Vector3.ZERO, "VisorMesh")

	_add_cyl(head, 0.06, 0.06, 0.06, Vector3(-0.23, 0.06, 0), mat_dark, Vector3(0, 0, PI * 0.5))
	_add_cyl(head, 0.008, 0.008, 0.24, Vector3(-0.23, 0.22, -0.04), mat_metal)
	_add_cyl(head, 0.009, 0.009, 0.18, Vector3(-0.18, -0.04, -0.18), mat_metal, Vector3(0.45, -0.75, 0))

	# -------------------------------------------------------------------------
	# 5. LEGEND-SPECIFIC SILHOUETTES & ACCESSORIES
	# -------------------------------------------------------------------------
	match lid:
		"wraith":
			_add_box(neck_pivot, Vector3(0.58, 0.16, 0.52), Vector3(0, -0.02, 0), mat_sec)
			_add_cyl(head, 0.08, 0.06, 0.14, Vector3(0, 0.24, 0.18), mat_dark, Vector3(-0.45, 0, 0))
			_add_cyl(head, 0.085, 0.085, 0.04, Vector3(0, 0.18, 0.14), mat_visor, Vector3(-0.45, 0, 0))
			var kunai_sheath := _add_box(pelvis_pivot, Vector3(0.06, 0.32, 0.10), Vector3(-0.31, -0.06, -0.04), mat_dark, Vector3(0.2, 0, 0.4))
			_add_box(kunai_sheath, Vector3(0.04, 0.10, 0.05), Vector3(0, 0.16, 0), mat_visor)
		"bloodhound":
			_add_cyl(head, 0.08, 0.46, 0.22, Vector3(0, 0.32, -0.02), mat_sec, Vector3(-0.10, 0, 0), 14)
			_add_box(head, Vector3(0.03, 0.22, 0.10), Vector3(0.18, 0.36, 0.08), mat_prim, Vector3(0, 0, -0.35))
			for hs in [-1.0, 1.0]:
				_add_cyl(head, 0.045, 0.045, 0.12, Vector3(hs * 0.14, -0.12, -0.18), mat_dark, Vector3(0.4, hs * 0.3, 0))
				_add_cyl(head, 0.025, 0.025, 0.26, Vector3(hs * 0.20, -0.06, 0.04), mat_dark, Vector3(0.2, 0, hs * 0.25))
		"octane":
			_add_box(head, Vector3(0.44, 0.46, 0.44), Vector3(0, 0.08, 0.02), mat_dark)
			for gs in [-1.0, 1.0]:
				_add_cyl(head, 0.055, 0.055, 0.08, Vector3(gs * 0.11, 0.22, -0.18), mat_glow, Vector3(PI * 0.5, 0, 0))
			var jaw_mask := _add_box(head, Vector3(0.34, 0.18, 0.16), Vector3(0, -0.10, -0.18), mat_dark, Vector3(0.2, 0, 0))
			_add_box(jaw_mask, Vector3(0.22, 0.06, 0.02), Vector3(0, -0.01, -0.09), mat_metal)
			_add_cyl(pelvis_pivot, 0.045, 0.045, 0.20, Vector3(-0.30, 0.06, 0), mat_glow, Vector3(0, 0, 0.3))
		"pathfinder":
			_add_cyl(head, 0.012, 0.012, 0.28, Vector3(0.18, 0.34, 0.02), mat_sec, Vector3(0, 0, -0.15))
			_add_sphere(head, 0.025, Vector3(0.20, 0.48, 0.02), mat_glow)
			var scr := _add_box(torso_pivot, Vector3(0.32, 0.22, 0.06), Vector3(0, 0.18, -0.22), mat_dark)
			_add_box(scr, Vector3(0.26, 0.16, 0.02), Vector3(0, 0, -0.02), mat_visor)
		"gibraltar":
			_add_box(torso_pivot, Vector3(0.96, 0.28, 0.62), Vector3(0, 0.28, 0), mat_prim)
			_add_box(torso_pivot, Vector3(0.48, 0.44, 0.22), Vector3(0, 0.14, 0.26), mat_sec)
		"valkyrie":
			for ws in [-1.0, 1.0]:
				var wing := Node3D.new()
				wing.position = Vector3(ws * 0.38, 0.24, 0.26)
				wing.rotation = Vector3(0.18, -ws * 0.25, -ws * 0.36)
				torso_pivot.add_child(wing)
				_add_box(wing, Vector3(0.16, 1.05, 0.38), Vector3(ws * 0.26, 0.28, 0), mat_sec)
				_add_cyl(wing, 0.065, 0.085, 0.32, Vector3(ws * 0.26, -0.18, 0.05), mat_metal, Vector3(-0.35, 0, 0))
		"bangalore":
			_add_box(head, Vector3(0.38, 0.14, 0.38), Vector3(0, 0.24, 0), mat_dark)
			var launcher := Node3D.new()
			launcher.position = Vector3(-0.38, 0.44, 0.12)
			launcher.rotation = Vector3(-0.35, 0.25, -0.15)
			torso_pivot.add_child(launcher)
			for b_idx in range(3):
				_add_cyl(launcher, 0.038, 0.038, 0.28, Vector3((float(b_idx) - 1.0) * 0.09, 0, 0), mat_sec)
		"caustic":
			for ms in [-1.0, 0.0, 1.0]:
				_add_cyl(head, 0.038, 0.048, 0.10, Vector3(ms * 0.10, -0.14, -0.22), mat_sec, Vector3(0.4, ms * 0.2, 0))
			for ts in [-1.0, 1.0]:
				_add_cyl(pelvis_pivot, 0.07, 0.07, 0.32, Vector3(ts * 0.18, -0.02, 0.28), mat_sec)
		"horizon":
			_add_box(head, Vector3(0.46, 0.24, 0.18), Vector3(0, 0.08, 0.14), mat_sec)
			var newt := Node3D.new()
			newt.position = Vector3(0, 0.32, 0.26)
			torso_pivot.add_child(newt)
			_add_sphere(newt, 0.16, Vector3.ZERO, mat_sec)
			_add_sphere(newt, 0.10, Vector3(0, 0, 0.08), mat_glow)
		"loba":
			for bs in [-1.0, 1.0]:
				_add_sphere(head, 0.09, Vector3(bs * 0.16, 0.20, 0.18), mat_dark)
				_add_cyl(head, 0.095, 0.095, 0.03, Vector3(bs * 0.16, 0.20, 0.18), mat_sec, Vector3(0, 0, PI * 0.5))
		"fuse":
			_add_box(head, Vector3(0.09, 0.09, 0.04), Vector3(0.10, 0.06, -0.23), mat_dark)
			_add_cyl(torso_pivot, 0.095, 0.11, 1.08, Vector3(0.12, 0.24, 0.26), mat_sec, Vector3(0.35, 0, 0.55))
		"conduit":
			var batt := Node3D.new()
			batt.position = Vector3(0, 0.22, 0.25)
			torso_pivot.add_child(batt)
			_add_box(batt, Vector3(0.36, 0.44, 0.16), Vector3.ZERO, mat_prim)
			_add_box(batt, Vector3(0.24, 0.32, 0.08), Vector3(0, 0, 0.08), mat_glow)

	# -------------------------------------------------------------------------
	# 6. ARTICULATED ARMS, ELBOWS, HELD WEAPON & HELD CONSUMABLES
	# -------------------------------------------------------------------------
	for side in [-1.0, 1.0]:
		_add_box(torso_pivot, Vector3(0.26, 0.28, 0.34), Vector3(side * 0.48, 0.34, 0), mat_sec, Vector3(0, 0, -side * 0.22))

		var arm_pivot := Node3D.new()
		arm_pivot.name = "LeftArmPivot" if side < 0.0 else "RightArmPivot"
		arm_pivot.position = Vector3(side * 0.48, 0.26, 0)
		torso_pivot.add_child(arm_pivot)

		var use_fuse_bionic: bool = (lid == "fuse" and side > 0.0)
		var arm_mat := mat_metal if use_fuse_bionic else mat_dark
		var plate_mat := mat_metal if use_fuse_bionic else mat_prim

		_add_box(arm_pivot, Vector3(0.18, 0.34, 0.18), Vector3(0, -0.17, 0), arm_mat, Vector3.ZERO, "BicepMesh")
		_add_box(arm_pivot, Vector3(0.08, 0.24, 0.16), Vector3(side * 0.08, -0.17, 0), plate_mat)

		var elbow_pivot := Node3D.new()
		elbow_pivot.name = "LeftElbowPivot" if side < 0.0 else "RightElbowPivot"
		elbow_pivot.position = Vector3(0, -0.34, 0)
		arm_pivot.add_child(elbow_pivot)

		_add_cyl(elbow_pivot, 0.065, 0.065, 0.16, Vector3.ZERO, mat_metal, Vector3(0, 0, PI * 0.5))
		_add_box(elbow_pivot, Vector3(0.18, 0.32, 0.18), Vector3(0, -0.16, 0), arm_mat, Vector3.ZERO, "ForearmMesh")
		_add_box(elbow_pivot, Vector3(0.16, 0.26, 0.08), Vector3(0, -0.16, -0.08), plate_mat)

		var hand_pos := Vector3(0, -0.34, 0)
		_add_box(elbow_pivot, Vector3(0.15, 0.12, 0.16), hand_pos, arm_mat, Vector3.ZERO, "HandMesh")
		_add_box(elbow_pivot, Vector3(0.14, 0.03, 0.09), hand_pos + Vector3(0, 0.05, 0.01), mat_sec, Vector3.ZERO, "KnucklePlate")
		_add_box(elbow_pivot, Vector3(0.04, 0.04, 0.08), hand_pos + Vector3(side * 0.07, 0.01, -0.04), arm_mat, Vector3(0, side * 0.35, 0))
		_add_box(elbow_pivot, Vector3(0.14, 0.05, 0.07), hand_pos + Vector3(0, -0.03, -0.06), arm_mat)

		# Left Forearm: Wrist HUD + 3D Consumable Props (Shield Battery & Syringe/Medkit!)
		if side < 0.0:
			if lid == "gibraltar":
				var g_shield := _add_box(elbow_pivot, Vector3(0.10, 0.54, 0.46), Vector3(-0.12, -0.16, -0.10), mat_visor, Vector3(0, 0.25, 0), "ArmGunShield")
				_add_box(g_shield, Vector3(0.04, 0.48, 0.40), Vector3(-0.04, 0, 0), mat_glow)
			elif lid == "loba":
				_add_cyl(elbow_pivot, 0.11, 0.11, 0.08, Vector3(0, -0.26, 0), mat_sec, Vector3.ZERO, 10)
			else:
				var pad := _add_box(elbow_pivot, Vector3(0.12, 0.16, 0.04), Vector3(0, -0.16, -0.11), mat_dark)
				_add_box(pad, Vector3(0.10, 0.13, 0.02), Vector3(0, 0, -0.01), mat_visor)

			# 3D Third-Person Held Shield Battery Capacitor Prop
			var bat_node := Node3D.new()
			bat_node.name = "HeldBatteryProp"
			bat_node.position = hand_pos + Vector3(0.06, -0.04, -0.10)
			bat_node.visible = false
			elbow_pivot.add_child(bat_node)
			_add_cyl(bat_node, 0.085, 0.085, 0.28, Vector3.ZERO, mat_dark, Vector3(0, 0, PI * 0.5), 8)
			_add_cyl(bat_node, 0.072, 0.072, 0.18, Vector3.ZERO, mat_glow, Vector3(0, 0, PI * 0.5), 12, "TP_BatteryCore")
			_add_cyl(bat_node, 0.095, 0.095, 0.04, Vector3(0.13, 0, 0), mat_metal, Vector3(0, 0, PI * 0.5), 6)
			_add_cyl(bat_node, 0.095, 0.095, 0.04, Vector3(-0.13, 0, 0), mat_metal, Vector3(0, 0, PI * 0.5), 6)

			# 3D Third-Person Held Syringe / MedKit Auto-Injector Prop
			var syr_node := Node3D.new()
			syr_node.name = "HeldSyringeProp"
			syr_node.position = hand_pos + Vector3(0.04, -0.04, -0.10)
			syr_node.visible = false
			elbow_pivot.add_child(syr_node)
			_add_cyl(syr_node, 0.042, 0.042, 0.24, Vector3.ZERO, mat_metal, Vector3(PI * 0.5, 0, 0), 10)
			_add_cyl(syr_node, 0.046, 0.046, 0.10, Vector3(0, 0, -0.02), mat_med_green, Vector3(PI * 0.5, 0, 0), 10)
			_add_box(syr_node, Vector3(0.06, 0.02, 0.06), Vector3(0, 0, 0.11), mat_med_red)

		# Right Arm: Held Tactical Carbine Rifle
		if side > 0.0:
			arm_pivot.rotation.x = 0.42
			elbow_pivot.rotation.x = 0.65

			var weapon_root := Node3D.new()
			weapon_root.name = "HeldWeaponRoot"
			weapon_root.position = hand_pos + Vector3(0, -0.04, -0.12)
			elbow_pivot.add_child(weapon_root)

			_add_box(weapon_root, Vector3(0.09, 0.14, 0.48), Vector3(0, 0, 0), mat_dark)
			_add_cyl(weapon_root, 0.022, 0.022, 0.42, Vector3(0, 0.02, -0.42), mat_metal, Vector3(PI * 0.5, 0, 0))
			_add_cyl(weapon_root, 0.032, 0.032, 0.08, Vector3(0, 0.02, -0.63), mat_dark, Vector3(PI * 0.5, 0, 0))
			_add_box(weapon_root, Vector3(0.07, 0.24, 0.12), Vector3(0, -0.16, -0.06), mat_sec, Vector3(0.28, 0, 0))
			var op := _add_box(weapon_root, Vector3(0.07, 0.08, 0.18), Vector3(0, 0.11, -0.04), mat_dark)
			_add_cyl(op, 0.025, 0.025, 0.03, Vector3(0, 0.01, 0), mat_visor, Vector3(PI * 0.5, 0, 0))

			var mflash := _add_sphere(weapon_root, 0.16, Vector3(0, 0.02, -0.72), mat_flash, "BotMuzzleFlash")
			_add_cyl(mflash, 0.01, 0.14, 0.28, Vector3(0, 0, -0.12), mat_flash, Vector3(PI * 0.5, 0, 0))
			mflash.visible = false

	root.scale = legend_data.get("scale", Vector3.ONE)
	return root

static func animate_rig(rig: Node3D, delta: float, s: Dictionary) -> void:
	if not is_instance_valid(rig):
		return

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
	var phase: float = float(s.get("strafe_phase", 0.0))
	var strafe_dir: float = float(s.get("strafe_dir", 1.0))
	var flinch: float = float(s.get("hit_flinch", 0.0))
	var death_time: float = float(s.get("death_time", -1.0))
	var speed: float = float(s.get("speed", 0.0))
	var t: float = float(s.get("time", Time.get_ticks_msec() / 1000.0))

	# Dynamic IMC Jumpkit Jet Thrusters
	var thruster_l: Node3D = rig.find_child("ThrusterFlameL", true, false)
	var thruster_r: Node3D = rig.find_child("ThrusterFlameR", true, false)
	var flame_on: bool = is_sliding or is_in_air or (is_moving and speed > 9.0)
	if thruster_l:
		thruster_l.visible = flame_on
		if flame_on:
			thruster_l.scale = Vector3.ONE * (1.75 if is_sliding else (1.15 + sin(t * 26.0) * 0.22))
	if thruster_r:
		thruster_r.visible = flame_on
		if flame_on:
			thruster_r.scale = Vector3.ONE * (1.75 if is_sliding else (1.15 + cos(t * 26.0) * 0.22))

	# Toggle 3rd-Person Weapon vs Consumable Props (Shield Battery / Syringe)
	var wep_mesh: Node3D = rig.find_child("HeldWeaponRoot", true, false)
	var bat_prop: Node3D = rig.find_child("HeldBatteryProp", true, false)
	var syr_prop: Node3D = rig.find_child("HeldSyringeProp", true, false)
	var is_bat_heal: bool = (heal_id == "shield_battery" or heal_id == "shield_cell" or heal_id == "phoenix_kit")

	if wep_mesh:
		wep_mesh.visible = (not is_heirloom) and (not is_healing) and (mode != "death")
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
		if torso_p:
			torso_p.position.y = lerpf(1.26, 0.38, ease_p)
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

	# 2. MAIN LOBBY HERO SHOWCASE ANIMATION
	if mode == "lobby":
		var breath: float = sin(t * 2.2) * 0.024
		var sway: float = cos(t * 1.1) * 0.018
		if torso_p:
			torso_p.position.y = lerpf(torso_p.position.y, 1.26 + breath * 0.25, delta * 8.0)
			torso_p.rotation.x = lerpf(torso_p.rotation.x, breath, delta * 6.0)
			torso_p.rotation.y = lerpf(torso_p.rotation.y, sway * 1.5, delta * 5.0)
			torso_p.rotation.z = lerpf(torso_p.rotation.z, sway * 0.5, delta * 5.0)
		if neck_p:
			neck_p.rotation.y = lerpf(neck_p.rotation.y, -sway * 2.0, delta * 4.0)
			neck_p.rotation.x = lerpf(neck_p.rotation.x, -breath * 0.5, delta * 6.0)
		if arm_r and elbow_r:
			arm_r.rotation = arm_r.rotation.lerp(Vector3(0.28 + breath, -0.12, 0.08), delta * 8.0)
			elbow_r.rotation.x = lerpf(elbow_r.rotation.x, 0.82, delta * 8.0)
		if arm_l and elbow_l:
			arm_l.rotation = arm_l.rotation.lerp(Vector3(0.38 + breath, 0.26, -0.14), delta * 8.0)
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x, 0.95, delta * 8.0)
		if leg_l and knee_l:
			leg_l.rotation = leg_l.rotation.lerp(Vector3(0.08, 0, -0.05), delta * 6.0)
			knee_l.rotation.x = lerpf(knee_l.rotation.x, 0.12, delta * 6.0)
		if leg_r and knee_r:
			leg_r.rotation = leg_r.rotation.lerp(Vector3(-0.04, 0, 0.05), delta * 6.0)
			knee_r.rotation.x = lerpf(knee_r.rotation.x, 0.06, delta * 6.0)
		return

	# 3. SPECIAL MOTION STATES: SLIDING, AIRBORNE, ZIPLINING
	if is_sliding:
		if torso_p:
			torso_p.position.y = lerpf(torso_p.position.y, 0.56, delta * 16.0)
			torso_p.rotation.x = lerpf(torso_p.rotation.x, -0.35, delta * 16.0)
			torso_p.rotation.z = lerpf(torso_p.rotation.z, -0.12 * strafe_dir, delta * 14.0)
		if leg_l and knee_l:
			leg_l.rotation.x = lerpf(leg_l.rotation.x, -1.12, delta * 18.0)
			knee_l.rotation.x = lerpf(knee_l.rotation.x, 0.14, delta * 18.0)
		if leg_r and knee_r:
			leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.62, delta * 18.0)
			knee_r.rotation.x = lerpf(knee_r.rotation.x, 1.48, delta * 18.0)
		if arm_r and elbow_r:
			arm_r.rotation = arm_r.rotation.lerp(Vector3(0.24, -0.12, 0.05), delta * 14.0)
			elbow_r.rotation.x = lerpf(elbow_r.rotation.x, 0.55, delta * 14.0)
		if arm_l and elbow_l:
			arm_l.rotation = arm_l.rotation.lerp(Vector3(-0.35, 0.22, -0.35), delta * 14.0)
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x, 0.45, delta * 14.0)
		return

	if is_ziplining or is_grappling:
		if torso_p:
			torso_p.position.y = lerpf(torso_p.position.y, 1.26, delta * 12.0)
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
			torso_p.position.y = lerpf(torso_p.position.y, 1.22, delta * 14.0)
			torso_p.rotation.x = lerpf(torso_p.rotation.x, 0.12, delta * 12.0)
		if leg_l and knee_l:
			leg_l.rotation.x = lerpf(leg_l.rotation.x, -0.35, delta * 14.0)
			knee_l.rotation.x = lerpf(knee_l.rotation.x, 0.52, delta * 14.0)
		if leg_r and knee_r:
			leg_r.rotation.x = lerpf(leg_r.rotation.x, -0.28, delta * 14.0)
			knee_r.rotation.x = lerpf(knee_r.rotation.x, 0.58, delta * 14.0)
		if arm_l and elbow_l:
			arm_l.rotation = arm_l.rotation.lerp(Vector3(0.35, 0.25, -0.38), delta * 12.0)
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x, 0.65, delta * 12.0)
		if arm_r and elbow_r:
			arm_r.rotation = arm_r.rotation.lerp(Vector3(0.38, -0.20, 0.32), delta * 12.0)
			elbow_r.rotation.x = lerpf(elbow_r.rotation.x, 0.60, delta * 12.0)
		return

	# 4. IN-GAME GROUND COMBAT, HEALING & LOCOMOTION ANIMATION
	var swing: float = sin(phase * 1.8) * 0.56 if is_moving else 0.0
	var knee_swing_l: float = maxf(0.0, -swing * 1.18) if is_moving else 0.0
	var knee_swing_r: float = maxf(0.0, swing * 1.18) if is_moving else 0.0

	var target_torso_y: float = 0.90 if is_crouching else (1.26 + (absf(cos(phase * 1.8)) * 0.04 if is_moving else 0.0))
	var target_torso_rot_x: float = (0.18 if is_crouching else (0.06 if is_moving else 0.02)) - flinch * 0.42
	var target_torso_rot_z: float = (-0.08 * strafe_dir if is_moving else 0.0) + flinch * 0.25

	if torso_p:
		torso_p.position.y = lerpf(torso_p.position.y, target_torso_y, delta * 14.0)
		torso_p.rotation.x = lerpf(torso_p.rotation.x, target_torso_rot_x, delta * 14.0)
		torso_p.rotation.z = lerpf(torso_p.rotation.z, target_torso_rot_z, delta * 12.0)

	if leg_l and leg_r:
		var base_leg_x: float = 0.48 if is_crouching else 0.0
		leg_l.rotation.x = lerpf(leg_l.rotation.x, swing + base_leg_x, delta * 16.0)
		leg_r.rotation.x = lerpf(leg_r.rotation.x, -swing + base_leg_x, delta * 16.0)

	if knee_l and knee_r:
		var crouch_knee: float = 0.88 if is_crouching else 0.06
		knee_l.rotation.x = lerpf(knee_l.rotation.x, knee_swing_l + crouch_knee, delta * 18.0)
		knee_r.rotation.x = lerpf(knee_r.rotation.x, knee_swing_r + crouch_knee, delta * 18.0)

	# Left & Right Arms: Coordinate Two-Handed Battery Twist / Syringe Injection / Reload / Aiming
	if arm_l and elbow_l:
		if is_healing:
			var heal_bob: float = sin(t * 8.0) * 0.08
			arm_l.rotation = arm_l.rotation.lerp(Vector3(0.78 + heal_bob, 0.46, -0.32), delta * 14.0)
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x, 1.28, delta * 14.0)
		elif is_reloading:
			var r_t: float = sin(t * 7.0)
			arm_l.rotation = arm_l.rotation.lerp(Vector3(0.18, 0.32, -0.42) if r_t < 0.0 else Vector3(0.62, 0.22, -0.16), delta * 14.0)
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x, 1.15, delta * 14.0)
		elif is_heirloom and not is_moving:
			arm_l.rotation = arm_l.rotation.lerp(Vector3(0.72, 0.45, -0.32), delta * 12.0)
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x, 1.35, delta * 12.0)
		elif is_moving and not is_firing:
			arm_l.rotation.x = lerpf(arm_l.rotation.x, -swing * 0.60 + 0.28, delta * 14.0)
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x, 0.65 + absf(swing) * 0.35, delta * 14.0)
		else:
			arm_l.rotation = arm_l.rotation.lerp(Vector3(0.52, 0.32, -0.18), delta * 12.0)
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x, 0.95, delta * 12.0)

	if arm_r and elbow_r:
		if is_healing:
			# Right hand reaches across chest to twist Shield Battery top cap or press Syringe plunger!
			var twist_w: float = cos(t * 10.0) * 0.14
			arm_r.rotation = arm_r.rotation.lerp(Vector3(0.82, -0.48, 0.28 + twist_w), delta * 14.0)
			elbow_r.rotation.x = lerpf(elbow_r.rotation.x, 1.25 + twist_w * 0.4, delta * 14.0)
		elif is_heirloom and not is_moving:
			arm_r.rotation = arm_r.rotation.lerp(Vector3(0.55, -0.25, 0.18), delta * 12.0)
			elbow_r.rotation.x = lerpf(elbow_r.rotation.x, 1.15, delta * 12.0)
		else:
			var recoil_kick: float = 0.22 if is_firing else 0.0
			var r_rot_x: float = 0.48 + sin(phase * 0.9) * 0.04 + flinch * 0.35 + recoil_kick
			arm_r.rotation = arm_r.rotation.lerp(Vector3(r_rot_x, -0.08, 0.05), delta * 16.0)
			elbow_r.rotation.x = lerpf(elbow_r.rotation.x, 0.68 - recoil_kick * 0.5, delta * 16.0)
