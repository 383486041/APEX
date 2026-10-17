class_name WeaponMeshBuilder
extends RefCounted
## High-Detail Procedural 3D First-Person Weapon & Mythic Heirloom Builder for Godot 4.3.
## Constructs multi-part animatable weapon rigs:
## - GunRig (UpperReceiver, LowerReceiver, Handguard, Picatinny Rail Teeth, Barrel, MuzzleBrake, Buttstock, PistolGrip)
## - MagPivot (Detachable Magazine / Energy Cell / Drum / Revolver Cylinder for multi-stage reload animations)
## - BoltPivot (Reciprocating Bolt Carrier / Charging Handle / Sniper Bolt / Peacekeeper Lever)
## - OpticPivot (1x HCOG, 2x Bruiser, 1x Threat, 6x Sniper Scope with glowing glass lens & reticle)
## - MuzzleFlashNode (Multi-fin 3D star flash + OmniLight3D)
## - AmmoLabel3D (Live digital ammo counter screen on receiver)
## - LeftArmPivot & RightArmPivot (First-person tactical gloved forearms & hands that animate during reload & melee)

static func _make_mat(col: Color, metal: float = 0.65, rough: float = 0.32, emit: bool = false, emit_energy: float = 1.8) -> StandardMaterial3D:
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


static func _build_tactical_fp_arms(gun_rig: Node3D, legend_data: Dictionary, is_heirloom: bool = false, rec_len: float = 0.48) -> void:
	var lid: String = str(legend_data.get("id", "wraith"))
	var col_prim: Color = legend_data.get("primary_color", Color("#312e81"))
	var col_sec: Color = legend_data.get("secondary_color", Color("#38bdf8"))
	var col_visor: Color = legend_data.get("visor_color", Color("#a78bfa"))

	var mat_sleeve := _make_mat(col_prim, 0.38, 0.48)
	var mat_trim := _make_mat(col_sec, 0.72, 0.28)
	var mat_glove := _make_mat(Color("#0f172a"), 0.32, 0.62)
	var mat_knuckle := _make_mat(Color("#334155"), 0.82, 0.22)
	var mat_chrome := _make_mat(Color("#cbd5e1"), 0.95, 0.12)
	var mat_gold := _make_mat(Color("#f59e0b"), 0.90, 0.18)
	var mat_hud := _make_mat(Color("#38bdf8"), 0.2, 0.1, true, 3.8)
	var mat_stim := _make_mat(Color("#22c55e"), 0.1, 0.1, true, 4.2)
	var mat_void := _make_mat(Color("#8b5cf6"), 0.3, 0.2, true, 3.5)

	# 1. Left Arm (LeftArmPivot) - Supporting Handguard / Tactical Pose
	var left_arm := Node3D.new()
	left_arm.name = "LeftArmPivot"
	if is_heirloom:
		left_arm.position = Vector3(-0.26, -0.14, -0.10)
	else:
		left_arm.position = Vector3(-0.06, -0.05, -0.18)
	gun_rig.add_child(left_arm)

	# Forearm Sleeve & Elbow Guard
	var l_sleeve_mat := mat_chrome if (lid == "pathfinder") else mat_sleeve
	_add_box(left_arm, Vector3(0.076, 0.076, 0.34), Vector3(-0.08, -0.06, 0.14), l_sleeve_mat, Vector3(0.25, -0.32, 0), "LeftForearm")
	_add_box(left_arm, Vector3(0.082, 0.082, 0.08), Vector3(-0.11, -0.08, 0.24), mat_trim, Vector3(0.25, -0.32, 0))

	# Wrist Tactical Chrono HUD / Communicator
	var chrono := _add_box(left_arm, Vector3(0.088, 0.024, 0.056), Vector3(-0.04, -0.01, 0.06), mat_glove, Vector3(0.25, -0.32, 0), "WristChrono")
	_add_box(chrono, Vector3(0.070, 0.008, 0.040), Vector3(0, 0.014, 0), mat_hud)

	# Left Glove & Articulated Hand
	_add_box(left_arm, Vector3(0.082, 0.068, 0.095), Vector3(0.0, 0.01, -0.02), mat_glove, Vector3.ZERO, "LeftGloveHand")
	# Reinforced Knuckle Guard
	_add_box(left_arm, Vector3(0.078, 0.016, 0.042), Vector3(0.0, 0.044, -0.02), mat_knuckle)
	# Gripping Thumb
	_add_box(left_arm, Vector3(0.024, 0.024, 0.055), Vector3(0.046, 0.015, -0.01), mat_glove, Vector3(0, 0.35, 0))
	# Gripping Fingers wrapping weapon rail
	_add_box(left_arm, Vector3(0.076, 0.034, 0.040), Vector3(-0.01, -0.028, -0.035), mat_glove)

	# Left Arm Legend-Specific Signature Features
	if lid == "octane":
		_add_cyl(left_arm, 0.007, 0.007, 0.18, Vector3(-0.04, -0.01, 0.08), mat_stim, Vector3(0, 0, PI * 0.4))
	elif lid == "loba":
		_add_box(left_arm, Vector3(0.092, 0.032, 0.065), Vector3(-0.04, -0.01, 0.06), mat_gold)
	elif lid == "wraith":
		_add_box(left_arm, Vector3(0.084, 0.020, 0.12), Vector3(-0.08, -0.05, 0.14), mat_void, Vector3(0.25, -0.32, 0))
	elif lid == "bloodhound":
		_add_box(left_arm, Vector3(0.086, 0.026, 0.08), Vector3(-0.04, -0.01, 0.06), mat_gold)

	# 2. Right Arm (RightArmPivot) - Trigger Finger & Pistol Grip
	var right_arm := Node3D.new()
	right_arm.name = "RightArmPivot"
	if is_heirloom:
		right_arm.position = Vector3(0.04, -0.08, -0.05)
	else:
		right_arm.position = Vector3(0.02, -0.10, rec_len * 0.22)
	gun_rig.add_child(right_arm)

	if lid == "fuse":
		# Fuse's Iconic Full Bionic Chrome Mechanical Arm & Titanium Fingers!
		_add_cyl(right_arm, 0.042, 0.046, 0.32, Vector3(0.07, -0.05, 0.16), mat_chrome, Vector3(0.18, 0.18, 0), 12, "RightForearm")
		_add_cyl(right_arm, 0.014, 0.014, 0.26, Vector3(0.04, -0.01, 0.14), mat_gold, Vector3(0.18, 0.18, 0))
		_add_box(right_arm, Vector3(0.078, 0.072, 0.088), Vector3.ZERO, mat_chrome, Vector3.ZERO, "RightGloveHand")
		_add_box(right_arm, Vector3(0.024, 0.024, 0.058), Vector3(-0.045, -0.01, -0.05), mat_chrome, Vector3(0, -0.25, 0))
	elif lid == "pathfinder":
		# Pathfinder Robotic MRVN Arm with Yellow Warning Stripes
		_add_box(right_arm, Vector3(0.078, 0.078, 0.32), Vector3(0.07, -0.05, 0.16), mat_trim, Vector3(0.18, 0.18, 0), "RightForearm")
		_add_box(right_arm, Vector3(0.082, 0.082, 0.06), Vector3(0.07, -0.05, 0.22), mat_glove, Vector3(0.18, 0.18, 0))
		_add_box(right_arm, Vector3(0.076, 0.070, 0.088), Vector3.ZERO, mat_chrome, Vector3.ZERO, "RightGloveHand")
		_add_box(right_arm, Vector3(0.022, 0.022, 0.056), Vector3(-0.045, -0.01, -0.05), mat_chrome)
	else:
		# Standard Tactical Arm with Legend Uniform Sleeves & Carbon Knuckle Gloves
		_add_box(right_arm, Vector3(0.080, 0.080, 0.32), Vector3(0.07, -0.05, 0.16), mat_sleeve, Vector3(0.18, 0.18, 0), "RightForearm")
		_add_box(right_arm, Vector3(0.084, 0.084, 0.06), Vector3(0.07, -0.05, 0.22), mat_trim, Vector3(0.18, 0.18, 0))
		_add_box(right_arm, Vector3(0.078, 0.072, 0.088), Vector3.ZERO, mat_glove, Vector3.ZERO, "RightGloveHand")
		_add_box(right_arm, Vector3(0.074, 0.016, 0.042), Vector3(0.0, 0.042, 0.0), mat_knuckle)
		# Trigger Finger extending forward to trigger
		_add_box(right_arm, Vector3(0.022, 0.022, 0.060), Vector3(-0.042, -0.01, -0.055), mat_glove, Vector3(0, -0.22, 0))
		# Curled Fingers wrapped around weapon grip
		_add_box(right_arm, Vector3(0.065, 0.042, 0.050), Vector3(0.015, -0.032, -0.01), mat_glove)

static func create_viewmodel(weapon_data: Dictionary, is_heirloom: bool = false, legend_data: Dictionary = {}, optic_id: String = "2x_bruiser") -> Node3D:
	if is_heirloom:
		return create_heirloom_rig(legend_data)

	var root := Node3D.new()
	root.name = "FP_Viewmodel"

	var gun_rig := Node3D.new()
	gun_rig.name = "GunRig"
	root.add_child(gun_rig)

	var col_main: Color = weapon_data.get("color", Color("#cbd5e1"))
	var col_accent: Color = weapon_data.get("accent", Color("#f97316"))
	var cat: String = str(weapon_data.get("cat", "AR"))
	var wid: String = str(weapon_data.get("id", "r301"))
	var rec_len: float = float(weapon_data.get("rec_len", 0.48))
	var barrel_len: float = float(weapon_data.get("barrel_len", 0.38))
	var stock_type: String = str(weapon_data.get("stock_type", "crane"))

	if wid == "r301":
		col_main = Color("#06b6d4") # Teal / cyan camo skin (matching screenshot!)
		col_accent = Color("#8b5cf6") # Purple geometric patterns

	var mat_body := _make_mat(col_main, 0.72, 0.28)
	var mat_dark := _make_mat(Color("#0f172a"), 0.60, 0.42)
	var mat_steel := _make_mat(Color("#64748b"), 0.88, 0.22)
	var mat_grip := _make_mat(Color("#1e293b"), 0.25, 0.75)
	var mat_accent := _make_mat(col_accent, 0.50, 0.25, true, 2.0)
	var mat_Port := _make_mat(Color("#090d14"), 0.80, 0.20)

	# 1. Upper & Lower Stepped Receiver
	var rec_h: float = 0.11 if cat != "PISTOL" else 0.085
	var rec_w: float = 0.088 if cat != "PISTOL" else 0.064
	_add_box(gun_rig, Vector3(rec_w, rec_h, rec_len), Vector3(0, 0.02, 0), mat_body, Vector3.ZERO, "UpperReceiver")
	_add_box(gun_rig, Vector3(rec_w * 0.92, rec_h * 0.68, rec_len * 0.82), Vector3(0, -0.045, 0.02), mat_dark, Vector3.ZERO, "LowerReceiver")

	# Glowing Accent Trim & Side Bevels
	_add_box(gun_rig, Vector3(rec_w + 0.008, 0.022, rec_len * 0.76), Vector3(0, 0.032, -0.02), mat_accent)
	_add_box(gun_rig, Vector3(0.006, 0.032, 0.11), Vector3(rec_w * 0.5 + 0.002, 0.025, 0.02), mat_Port, Vector3.ZERO, "EjectionPort")

	# 2. Ventilated Handguard & Top Picatinny Rail Teeth
	if cat != "PISTOL" and stock_type != "bow":
		var hg_len: float = barrel_len * 0.68
		var hg_z: float = -(rec_len * 0.5 + hg_len * 0.45)
		_add_box(gun_rig, Vector3(rec_w * 0.86, rec_h * 0.82, hg_len), Vector3(0, 0.015, hg_z), mat_dark, Vector3.ZERO, "Handguard")
		# Cooling Vents on Handguard
		for v in range(4):
			var vz: float = hg_z + hg_len * 0.35 - float(v) * (hg_len * 0.22)
			_add_box(gun_rig, Vector3(rec_w * 0.92, 0.018, 0.024), Vector3(0, 0.02, vz), mat_accent)

	# Stepped Top Picatinny Rail
	var rail_count: int = 9 if cat != "PISTOL" else 4
	for r in range(rail_count):
		var rz: float = rec_len * 0.38 - float(r) * 0.048
		_add_box(gun_rig, Vector3(0.036, 0.014, 0.026), Vector3(0, rec_h * 0.5 + 0.024, rz), mat_steel)

	# 3. Fluted Barrel, Gas Block & Category-Specific Muzzle Brake
	var bar_z: float = -(rec_len * 0.5 + barrel_len * 0.5)
	var muz_z: float = -(rec_len * 0.5 + barrel_len + 0.04)

	if wid == "chargerifle":
		# Iconic Apex Charge Rifle (滋崩): Twin horizontal capacitor rails with 3 illuminated plasma coils
		_add_box(gun_rig, Vector3(0.022, 0.046, barrel_len), Vector3(-0.046, 0.025, bar_z), mat_dark, Vector3.ZERO, "LeftRail")
		_add_box(gun_rig, Vector3(0.022, 0.046, barrel_len), Vector3(0.046, 0.025, bar_z), mat_dark, Vector3.ZERO, "RightRail")
		_add_box(gun_rig, Vector3(0.024, 0.016, 0.08), Vector3(-0.046, 0.025, bar_z + 0.08), mat_accent)
		_add_box(gun_rig, Vector3(0.024, 0.016, 0.08), Vector3(0.046, 0.025, bar_z + 0.08), mat_accent)
		_add_cyl(gun_rig, 0.015, 0.015, barrel_len, Vector3(0, 0.025, bar_z), mat_steel, Vector3(PI * 0.5, 0, 0), 12, "AcceleratorTube")
		for ci in range(3):
			var cz: float = bar_z + (float(ci) - 1.0) * (barrel_len * 0.32)
			_add_cyl(gun_rig, 0.028, 0.028, 0.024, Vector3(0, 0.025, cz), mat_accent, Vector3(PI * 0.5, 0, 0), 12, "ChargeCoil%d" % ci)
		_add_cyl(gun_rig, 0.032, 0.024, 0.08, Vector3(0, 0.025, muz_z), mat_accent, Vector3(PI * 0.5, 0, 0), 10, "FocusMuzzle")
	else:
		_add_cyl(gun_rig, 0.018, 0.020, barrel_len, Vector3(0, 0.025, bar_z), mat_steel, Vector3(PI * 0.5, 0, 0), 12, "MainBarrel")
		if cat != "PISTOL":
			_add_cyl(gun_rig, 0.011, 0.011, barrel_len * 0.72, Vector3(0, -0.012, bar_z * 0.85), mat_dark, Vector3(PI * 0.5, 0, 0), 10, "GasTube")

		if cat == "SNIPER":
			_add_box(gun_rig, Vector3(0.056, 0.048, 0.11), Vector3(0, 0.025, muz_z), mat_dark, Vector3.ZERO, "HeavyMuzzleBrake")
		elif cat == "SHOTGUN":
			_add_cyl(gun_rig, 0.032, 0.026, 0.09, Vector3(0, 0.025, muz_z), mat_accent, Vector3(PI * 0.5, 0, 0), 8, "ShotgunChoke")
		else:
			_add_cyl(gun_rig, 0.025, 0.022, 0.08, Vector3(0, 0.025, muz_z), mat_dark, Vector3(PI * 0.5, 0, 0), 10, "MuzzleCompensator")

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
	_add_box(gun_rig, Vector3(0.046, 0.15, 0.068), Vector3(0, -0.125, rec_len * 0.22), mat_grip, Vector3(-0.28, 0, 0), "PistolGrip")
	_add_box(gun_rig, Vector3(0.024, 0.016, 0.075), Vector3(0, -0.095, rec_len * 0.08), mat_steel, Vector3.ZERO, "TriggerGuard")

	if stock_type == "crane" or stock_type == "heavy":
		var st_z: float = rec_len * 0.5 + 0.16
		_add_cyl(gun_rig, 0.018, 0.018, 0.26, Vector3(0, 0.01, st_z), mat_dark, Vector3(PI * 0.5, 0, 0), 10)
		_add_box(gun_rig, Vector3(0.058, 0.14, 0.22), Vector3(0, -0.02, st_z + 0.05), mat_body, Vector3.ZERO, "Buttstock")
		_add_box(gun_rig, Vector3(0.062, 0.15, 0.03), Vector3(0, -0.02, st_z + 0.16), mat_grip, Vector3.ZERO, "RubberButtpad")
	elif stock_type == "sniper":
		var st_z: float = rec_len * 0.5 + 0.20
		_add_box(gun_rig, Vector3(0.052, 0.12, 0.34), Vector3(0, -0.01, st_z), mat_body, Vector3.ZERO, "SniperStock")
		_add_box(gun_rig, Vector3(0.064, 0.035, 0.16), Vector3(0, 0.065, st_z - 0.02), mat_accent, Vector3.ZERO, "CheekRiser")
	elif stock_type == "wire":
		for side in [-1.0, 1.0]:
			_add_cyl(gun_rig, 0.006, 0.006, 0.22, Vector3(side * 0.028, 0.0, rec_len * 0.5 + 0.10), mat_steel, Vector3(PI * 0.5, 0, 0), 8)

	# 6. Animatable Detachable Magazine Pivot (MagPivot)
	var mag_pivot := Node3D.new()
	mag_pivot.name = "MagPivot"
	var mag_z: float = 0.14 if stock_type == "bullpup" else -0.05
	mag_pivot.position = Vector3(0, -0.14, mag_z)
	gun_rig.add_child(mag_pivot)

	if wid == "chargerifle":
		# Removable High-Capacity Plasma Battery Cell
		mag_pivot.position = Vector3(0, -0.11, 0.02)
		_add_cyl(mag_pivot, 0.028, 0.028, 0.16, Vector3.ZERO, mat_dark, Vector3.ZERO, 12, "EnergyCanister")
		_add_cyl(mag_pivot, 0.022, 0.022, 0.12, Vector3(0, 0, 0.012), mat_accent, Vector3.ZERO, 10, "EnergyCore")
		_add_box(mag_pivot, Vector3(0.038, 0.018, 0.04), Vector3(0, -0.08, 0), mat_steel)
	elif wid == "wingman":
		# Swing-out Revolver Cylinder
		mag_pivot.position = Vector3(0, 0.018, -0.02)
		_add_cyl(mag_pivot, 0.036, 0.036, 0.075, Vector3.ZERO, mat_steel, Vector3(PI * 0.5, 0, 0), 6, "RevolverCylinder")
		_add_cyl(mag_pivot, 0.008, 0.008, 0.11, Vector3(0, 0, -0.02), mat_accent, Vector3(PI * 0.5, 0, 0), 8)
	elif cat == "LMG":
		# Heavy Box Drum Magazine
		_add_box(mag_pivot, Vector3(0.13, 0.18, 0.14), Vector3(0, -0.02, 0), mat_dark, Vector3.ZERO, "DrumMag")
		_add_box(mag_pivot, Vector3(0.136, 0.04, 0.144), Vector3(0, -0.06, 0), mat_accent)
	elif str(weapon_data.get("ammo", "")) == "energy":
		# Glowing Energy Battery Pack
		_add_box(mag_pivot, Vector3(0.062, 0.17, 0.095), Vector3.ZERO, mat_dark, Vector3(0.12, 0, 0))
		_add_box(mag_pivot, Vector3(0.068, 0.11, 0.042), Vector3(0, -0.01, 0), mat_accent, Vector3(0.12, 0, 0), "EnergyCoreWindow")
	else:
		# Curved Tactical Box Magazine with Baseplate & Ammo Window
		var m_tilt: float = float(weapon_data.get("mag_curve", 0.18))
		_add_box(mag_pivot, Vector3(0.054, 0.19, 0.082), Vector3.ZERO, mat_dark, Vector3(m_tilt, 0, 0), "MagBody")
		_add_box(mag_pivot, Vector3(0.062, 0.026, 0.092), Vector3(0, -0.095, -0.015), mat_accent, Vector3(m_tilt, 0, 0), "MagBaseplate")
		_add_box(mag_pivot, Vector3(0.058, 0.09, 0.018), Vector3(0, 0.0, 0), mat_accent, Vector3(m_tilt, 0, 0), "AmmoStrip")

	# 7. Animatable Bolt Carrier / Charging Handle / Lever Pivot (BoltPivot)
	var bolt_pivot := Node3D.new()
	bolt_pivot.name = "BoltPivot"
	bolt_pivot.position = Vector3(0, 0.032, -0.04)
	gun_rig.add_child(bolt_pivot)

	if wid == "chargerifle":
		# Pneumatic Heat Release Vent Louvers
		bolt_pivot.position = Vector3(0, 0.045, -0.06)
		_add_box(bolt_pivot, Vector3(rec_w * 0.88, 0.018, 0.12), Vector3.ZERO, mat_accent, Vector3.ZERO, "VentLouvers")
	elif wid == "peacekeeper":
		# Lever-Action Loop under grip
		bolt_pivot.position = Vector3(0, -0.08, 0.06)
		_add_box(bolt_pivot, Vector3(0.022, 0.09, 0.12), Vector3(0, -0.03, 0), mat_accent, Vector3.ZERO, "PeacekeeperLever")
	elif cat == "SNIPER":
		# Sniper Bent Bolt Handle with Spherical Knob
		_add_cyl(bolt_pivot, 0.014, 0.014, 0.14, Vector3(0.02, 0, 0.04), mat_steel, Vector3(PI * 0.5, 0, 0), 10)
		_add_cyl(bolt_pivot, 0.007, 0.007, 0.065, Vector3(0.058, -0.01, 0.06), mat_steel, Vector3(0, 0, 1.25), 8)
		var knob := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.016
		sp.height = 0.032
		knob.mesh = sp
		knob.material_override = mat_accent
		knob.position = Vector3(0.085, -0.022, 0.06)
		bolt_pivot.add_child(knob)
	else:
		# Side Reciprocating Charging Handle
		_add_box(bolt_pivot, Vector3(0.055, 0.018, 0.028), Vector3(-0.045, 0.01, -0.04), mat_accent, Vector3.ZERO, "ChargingHandle")
		_add_box(bolt_pivot, Vector3(0.014, 0.032, 0.11), Vector3(rec_w * 0.48, -0.005, 0.05), mat_steel, Vector3.ZERO, "BoltCarrier")

	# 8. Modular 3D Optic Sight (OpticPivot) - Ultra-Clean Apex Frames & 100% Crystal-Clear Glass
	var optic_pivot := Node3D.new()
	optic_pivot.name = "OpticPivot"
	optic_pivot.position = Vector3(0, rec_h * 0.5 + 0.032, 0.02)
	gun_rig.add_child(optic_pivot)

	# Anti-reflective high-transparency optical glass (zero opaque glow, completely unobstructed view!)
	var mat_lens := StandardMaterial3D.new()
	mat_lens.albedo_color = Color(0.25, 0.70, 1.0, 0.02)
	mat_lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_lens.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_lens.roughness = 0.02
	mat_lens.metallic = 0.05
	mat_lens.emission_enabled = false

	var mat_threat_lens := StandardMaterial3D.new()
	mat_threat_lens.albedo_color = Color(0.12, 0.16, 0.22, 0.04)
	mat_threat_lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_threat_lens.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_threat_lens.roughness = 0.02
	mat_threat_lens.emission_enabled = false

	var mat_reticle := _make_mat(Color("#ff1e42"), 0.0, 0.1, true, 4.2)

	if optic_id == "6x_kraber" or (cat == "SNIPER" and optic_id == ""):
		# Dual-Lens Long Sniper Scope (authentic exterior cylinder, dropped out of camera during ADS)
		_add_cyl(optic_pivot, 0.026, 0.026, 0.24, Vector3(0, 0.036, 0), mat_dark, Vector3(PI * 0.5, 0, 0), 16)
		_add_cyl(optic_pivot, 0.032, 0.026, 0.06, Vector3(0, 0.036, -0.13), mat_body, Vector3(PI * 0.5, 0, 0), 16)
		_add_cyl(optic_pivot, 0.024, 0.024, 0.003, Vector3(0, 0.036, 0.118), mat_lens, Vector3(PI * 0.5, 0, 0), 14)
		_add_box(optic_pivot, Vector3(0.048, 0.016, 0.055), Vector3(0, 0.012, 0.05), mat_steel)
		_add_box(optic_pivot, Vector3(0.048, 0.016, 0.055), Vector3(0, 0.012, -0.05), mat_steel)
	elif optic_id == "1x_hcog":
		# 1x HCOG "Classic": Authentic open-top reflex sight with slim side uprights and panoramic aperture
		_add_box(optic_pivot, Vector3(0.052, 0.007, 0.065), Vector3(0, 0.0035, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.034, 0.035), Vector3(-0.025, 0.022, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.034, 0.035), Vector3(0.025, 0.022, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.047, 0.032, 0.002), Vector3(0, 0.022, -0.005), mat_lens)
	elif optic_id == "2x_bruiser":
		# 2x HCOG "Bruiser": Sleek chamfered hood, slim side walls, crystal-clear rectangular window
		_add_box(optic_pivot, Vector3(0.056, 0.007, 0.068), Vector3(0, 0.0035, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.036, 0.040), Vector3(-0.027, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.036, 0.040), Vector3(0.027, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.056, 0.003, 0.040), Vector3(0, 0.042, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.051, 0.035, 0.002), Vector3(0, 0.024, -0.005), mat_lens)
	elif optic_id == "1x_holo":
		# 1x-2x Holo: Sleek circular tubular hood with hollow TorusMesh aperture (100% transparent sightline!)
		_add_box(optic_pivot, Vector3(0.054, 0.007, 0.070), Vector3(0, 0.0035, 0), mat_dark)
		_add_ring(optic_pivot, 0.025, 0.029, Vector3(0, 0.024, -0.025), mat_dark, Vector3(PI * 0.5, 0, 0), 24, "HoloFrontRing")
		_add_ring(optic_pivot, 0.025, 0.029, Vector3(0, 0.024, 0.025), mat_dark, Vector3(PI * 0.5, 0, 0), 24, "HoloRearRing")
		_add_box(optic_pivot, Vector3(0.003, 0.016, 0.050), Vector3(-0.028, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.016, 0.050), Vector3(0.028, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.020, 0.003, 0.050), Vector3(0, 0.052, 0), mat_dark)
	elif optic_id == "3x_ranger":
		# 3x HCOG Ranger: Elongated hexagonal hood with side battery compartment
		_add_box(optic_pivot, Vector3(0.056, 0.008, 0.090), Vector3(0, 0.004, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.038, 0.055), Vector3(-0.027, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.038, 0.055), Vector3(0.027, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.056, 0.003, 0.055), Vector3(0, 0.043, 0), mat_dark)
		_add_cyl(optic_pivot, 0.007, 0.007, 0.055, Vector3(0.034, 0.018, 0), mat_steel, Vector3(PI * 0.5, 0, 0), 8)
		_add_box(optic_pivot, Vector3(0.051, 0.036, 0.002), Vector3(0, 0.024, -0.005), mat_lens)
	elif optic_id == "2x_4x_aog":
		# 2x-4x AOG: Tactical tubular scope with open aperture & elevation/windage turrets
		_add_box(optic_pivot, Vector3(0.054, 0.008, 0.085), Vector3(0, 0.004, 0), mat_dark)
		_add_ring(optic_pivot, 0.026, 0.030, Vector3(0, 0.024, -0.035), mat_dark, Vector3(PI * 0.5, 0, 0), 24, "AogFrontRing")
		_add_ring(optic_pivot, 0.026, 0.030, Vector3(0, 0.024, 0.035), mat_dark, Vector3(PI * 0.5, 0, 0), 24, "AogRearRing")
		_add_box(optic_pivot, Vector3(0.003, 0.020, 0.070), Vector3(-0.029, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.020, 0.070), Vector3(0.029, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.024, 0.003, 0.070), Vector3(0, 0.053, 0), mat_dark)
		_add_cyl(optic_pivot, 0.007, 0.007, 0.012, Vector3(0, 0.058, 0), mat_steel, Vector3.ZERO, 8)
		_add_cyl(optic_pivot, 0.007, 0.007, 0.012, Vector3(0.034, 0.024, 0), mat_steel, Vector3(0, 0, PI * 0.5), 8)
	elif optic_id == "1x_threat":
		# 1x Digital Threat: Angular tactical frame with polarized anti-glare lens
		_add_box(optic_pivot, Vector3(0.056, 0.007, 0.065), Vector3(0, 0.0035, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.036, 0.042), Vector3(-0.027, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.036, 0.042), Vector3(0.027, 0.024, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.056, 0.003, 0.042), Vector3(0, 0.042, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.051, 0.035, 0.002), Vector3(0, 0.024, -0.005), mat_threat_lens)
	else:
		# Fallback Iron Sight / Basic Reflex
		_add_box(optic_pivot, Vector3(0.052, 0.007, 0.065), Vector3(0, 0.0035, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.034, 0.035), Vector3(-0.025, 0.022, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.003, 0.034, 0.035), Vector3(0.025, 0.022, 0), mat_dark)
		_add_box(optic_pivot, Vector3(0.047, 0.032, 0.002), Vector3(0, 0.022, -0.005), mat_lens)

	# Hipfire illuminated dot (automatically hidden during ADS to give way to crisp 2D projected reticle)
	var dot := MeshInstance3D.new()
	dot.name = "SightDot"
	var dot_sp := SphereMesh.new()
	dot_sp.radius = 0.003
	dot_sp.height = 0.006
	dot.mesh = dot_sp
	dot.material_override = mat_reticle
	dot.position = Vector3(0, 0.024, -0.008)
	optic_pivot.add_child(dot)

	# 9. Digital Ammo Readout Screen on Receiver Back
	var ammo_lbl := Label3D.new()
	ammo_lbl.name = "AmmoLabel3D"
	ammo_lbl.text = "18" if wid == "r301" else str(weapon_data.get("mag", 28))
	ammo_lbl.font_size = 28
	ammo_lbl.pixel_size = 0.00085
	ammo_lbl.outline_size = 3
	ammo_lbl.outline_modulate = Color(0, 0, 0, 0.95)
	ammo_lbl.modulate = Color("#38bdf8") if wid == "r301" else col_accent

	if wid == "r301":
		# Screen housing mounted on LEFT shoulder of receiver - authentic to Apex Legends and never obstructs the optic!
		var scr_housing := _add_box(gun_rig, Vector3(0.046, 0.036, 0.042), Vector3(-rec_w * 0.5 - 0.016, 0.020, 0.08), mat_dark, Vector3(-0.35, 0.38, -0.12), "AmmoScreenHousing")
		var scr_face := _add_box(scr_housing, Vector3(0.040, 0.030, 0.006), Vector3(0, 0, 0.022), _make_mat(Color("#0369a1"), 0.1, 0.8, true, 2.8), Vector3.ZERO, "ScreenGlass")
		ammo_lbl.position = Vector3(0, 0, 0.026)
		ammo_lbl.rotation = Vector3.ZERO
		scr_housing.add_child(ammo_lbl)

		# Omamori Talisman Lucky Charm hanging on left side of rail (Matching reference screenshot!)
		var charm_pivot := Node3D.new()
		charm_pivot.name = "OmamoriCharm"
		charm_pivot.position = Vector3(-rec_w * 0.5 - 0.024, 0.02, -0.06)
		gun_rig.add_child(charm_pivot)
		var mat_charm := _make_mat(Color("#f472b6"), 0.1, 0.6) # Pink silk
		var mat_ribbon := _make_mat(Color("#ef4444"), 0.2, 0.5) # Red knot cord
		var mat_gold := _make_mat(Color("#fbbf24"), 0.9, 0.2) # Gold ring
		_add_cyl(charm_pivot, 0.008, 0.008, 0.003, Vector3(0, 0.030, 0), mat_gold, Vector3(0, 0, PI * 0.5), 10)
		_add_box(charm_pivot, Vector3(0.012, 0.062, 0.046), Vector3(0, -0.012, 0), mat_charm, Vector3(0.08, 0, -0.15))
		_add_box(charm_pivot, Vector3(0.014, 0.018, 0.024), Vector3(0, 0.018, 0), mat_ribbon, Vector3(0.08, 0, -0.15))
	else:
		ammo_lbl.position = Vector3(-rec_w * 0.5 - 0.004, 0.028, 0.11)
		ammo_lbl.rotation.y = -PI * 0.5
		gun_rig.add_child(ammo_lbl)

	# 10. Articulated First-Person Tactical Arms & Legend Uniform Sleeves
	_build_tactical_fp_arms(gun_rig, legend_data, false, rec_len)

	root.position = Vector3(0.28, -0.24, -0.54)
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
		# Octane Butterfly Knife with Stim Syringe Handle
		_add_box(h_pivot, Vector3(0.022, 0.16, 0.026), Vector3(-0.018, -0.08, 0), mat_hilt, Vector3(0, 0, 0.08), "HandleLeft")
		_add_box(h_pivot, Vector3(0.022, 0.16, 0.026), Vector3(0.018, -0.08, 0), mat_hilt, Vector3(0, 0, -0.08), "HandleRight")
		_add_cyl(h_pivot, 0.009, 0.009, 0.12, Vector3(-0.018, -0.08, 0), mat_plasma, Vector3.ZERO, 8, "StimVial")
		_add_box(h_pivot, Vector3(0.012, 0.22, 0.036), Vector3(0, 0.11, 0), mat_blade, Vector3.ZERO, "TantoBlade")
		_add_box(h_pivot, Vector3(0.015, 0.22, 0.008), Vector3(0, 0.11, -0.016), mat_plasma, Vector3.ZERO, "PlasmaEdge")
	elif lid == "bloodhound":
		# Bloodhound Raven's Bite Battle Axe
		_add_cyl(h_pivot, 0.018, 0.020, 0.52, Vector3(0, 0.02, 0), mat_hilt, Vector3.ZERO, 10, "AxeShaft")
		_add_cyl(h_pivot, 0.024, 0.022, 0.06, Vector3(0, 0.22, 0), mat_gold, Vector3.ZERO, 10, "NordicCollar")
		_add_box(h_pivot, Vector3(0.024, 0.16, 0.18), Vector3(0, 0.20, -0.08), mat_blade, Vector3(0.15, 0, 0), "AxeHead")
		_add_box(h_pivot, Vector3(0.028, 0.18, 0.035), Vector3(0, 0.20, -0.17), mat_plasma, Vector3(0.15, 0, 0), "MoltenEdge")
		_add_cyl(h_pivot, 0.004, 0.022, 0.12, Vector3(0, 0.22, 0.07), mat_gold, Vector3(PI * 0.5, 0, 0), 6, "RavenSpike")
	else:
		# Wraith Kunai "Hope's Dusk" / Universal Cyber-Kunai with Pommel Ring & Void Plasma Edge
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

	# Right Hand Holding Heirloom + Left Hand Tactical Pose with Legend Uniform Sleeves
	_build_tactical_fp_arms(gun_rig, legend_data, true, 0.48)

	var light := OmniLight3D.new()
	light.light_color = h_col
	light.light_energy = 1.6
	light.omni_range = 2.5
	h_pivot.add_child(light)

	root.position = Vector3(0.24, -0.22, -0.46)
	return root




