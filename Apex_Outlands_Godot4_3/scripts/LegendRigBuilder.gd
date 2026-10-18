class_name LegendRigBuilder
extends RefCounted
## ============================================================================
## GENERATION 3: OPEN-SOURCE UAL1_STANDARD.GLB SKINNED CHARACTER & MOCAP SYSTEM
## (`人物模型的三次重构` — Powered by Quaternius Universal Animation Library)
## Upgrades:
## - Replaces procedural box/cylinder mannequin with the real 65-bone skinned 3D
##   humanoid (`Mannequin` + `Skeleton3D` + `AnimationPlayer`) from `UAL1_Standard.glb`!
## - Drives character locomotion, combat, jumping, crouching, reloading, and melee
##   directly through `UAL1_Standard.glb`'s 43 motion-captured animations (`Idle_Loop`,
##   `Walk_Loop`, `Jog_Fwd_Loop`, `Sprint_Loop`, `Crouch_Idle_Loop`, `Crouch_Fwd_Loop`,
##   `Jump_Start`, `Jump_Loop`, `Punch_Jab`, `Punch_Cross`, `Sword_Idle`, `Sword_Attack`,
##   `Pistol_Idle_Loop`, `Pistol_Shoot`, `Pistol_Reload`, `Interact`, `Hit_Chest`)!
## - Attaches 12 Legend-Specific 3D Tactical Helmets/Visors/Wings/Jumpkits and Open-Source
##   3D Weapons/Heirlooms directly onto `Skeleton3D` bones (`Head`, `spine_03`, `hand_r`, `hand_l`)
##   via Godot 4 `BoneAttachment3D`!
## ============================================================================

static var _ual_packed_scene: PackedScene = null
static var _ual_gltf_proto: Node3D = null

static func _make_mat(col: Color, met: float = 0.5, rough: float = 0.4, emit: bool = false, emit_col: Color = Color.BLACK, emit_energy: float = 1.0, pbr_kind: String = "") -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = met
	m.roughness = rough
	if emit:
		m.emission_enabled = true
		m.emission = emit_col
		m.emission_energy_multiplier = emit_energy
	else:
		var kind: String = pbr_kind
		if kind == "":
			if rough >= 0.55:
				kind = "carbon_weave"
			elif met >= 0.70:
				kind = "gunmetal"
			else:
				kind = "polymer_grip"
		m.normal_enabled = true
		m.normal_scale = 0.16 if kind == "gunmetal" else 0.20
		m.normal_texture = CanyonWorldBuilder.get_procedural_normal_tex(kind)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(14.0, 14.0, 14.0)
		m.rim_enabled = true
		m.rim = 0.24
		m.rim_tint = 0.35
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

static func _instantiate_ual_character() -> Node3D:
	var ual_path: String = "res://assets/animations/UAL1_Standard.glb"
	if _ual_packed_scene == null and ResourceLoader.exists(ual_path):
		var res := load(ual_path)
		if res is PackedScene:
			_ual_packed_scene = res
	if _ual_packed_scene != null:
		var inst := _ual_packed_scene.instantiate() as Node3D
		if inst != null:
			return inst
	if _ual_gltf_proto == null and FileAccess.file_exists(ual_path):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(ProjectSettings.globalize_path(ual_path), state) == OK:
			_ual_gltf_proto = doc.generate_scene(state) as Node3D
	if is_instance_valid(_ual_gltf_proto):
		return _ual_gltf_proto.duplicate() as Node3D
	return null

static func _build_tp_boxing_glove(parent: Node3D, is_left: bool, h_col: Color) -> void:
	var side_s: float = 1.0 if is_left else -1.0
	var mat_blue := _make_mat(Color("#0284c7"), 0.22, 0.28)
	var mat_navy := _make_mat(Color("#0369a1"), 0.26, 0.34)
	var mat_gold := _make_mat(Color("#facc15"), 0.85, 0.20)
	var mat_red := _make_mat(Color("#ef4444"), 0.40, 0.28)
	var mat_led := _make_mat(h_col, 0.2, 0.1, true, h_col, 3.2)

	var g_root := Node3D.new()
	g_root.name = "TP_LeftBoxingGlove" if is_left else "TP_RightBoxingGlove"
	parent.add_child(g_root)

	# In UAL1_Standard hand_r / hand_l bone space, +Y is wrist->knuckles
	_add_cyl(g_root, 0.052, 0.056, 0.11, Vector3(0, 0.02, 0), mat_gold, Vector3.ZERO, 16, "Cuff")
	_add_cyl(g_root, 0.055, 0.056, 0.025, Vector3(0, 0.07, 0), mat_red, Vector3.ZERO, 16, "CuffTrim")
	var dome := _add_sphere(g_root, 0.082, Vector3(0, 0.14, 0), mat_blue, "GloveDome", Vector3(1.12, 1.25, 0.92))
	var k_roll := _add_capsule(g_root, 0.048, 0.14, Vector3(0, 0.18, 0.01), mat_blue, Vector3(0, 0, PI * 0.5), "KnuckleRoll")
	k_roll.scale = Vector3(0.9, 1.0, 1.05)
	_add_capsule(g_root, 0.036, 0.10, Vector3(side_s * 0.068, 0.12, 0.02), mat_navy, Vector3(0, 0, -side_s * 0.25), "Thumb")
	_add_cyl(g_root, 0.028, 0.028, 0.01, Vector3(0, 0.04, -0.045), mat_led, Vector3(PI * 0.5, 0, 0), 12, "Badge")

static func create_legend_rig(legend_data: Dictionary, weapon_id: String = "r301") -> Node3D:
	var lid: String = str(legend_data.get("id", "wraith"))
	var root := Node3D.new()
	root.name = "LegendRig_" + lid
	root.set_meta("legend_id", lid)
	root.set_meta("weapon_id", weapon_id)

	var col_prim: Color = legend_data.get("primary_color", Color("#312e81"))
	var col_sec: Color = legend_data.get("secondary_color", Color("#38bdf8"))
	var col_visor: Color = legend_data.get("visor_color", Color("#a78bfa"))
	var h_info: Dictionary = legend_data.get("heirloom", {"color": Color("#38bdf8")})
	var h_col: Color = h_info.get("color", Color("#38bdf8"))

	var mat_prim := _make_mat(col_prim, 0.58, 0.32, false, Color.BLACK, 1.0, "gunmetal")
	var mat_sec := _make_mat(col_sec, 0.78, 0.22, false, Color.BLACK, 1.0, "gunmetal")
	var mat_dark := _make_mat(Color("#0f172a"), 0.38, 0.54, false, Color.BLACK, 1.0, "polymer_grip")
	var mat_suit := _make_mat(Color("#1e293b"), 0.30, 0.58, false, Color.BLACK, 1.0, "carbon_weave")
	var mat_metal := _make_mat(Color("#cbd5e1"), 0.92, 0.16, false, Color.BLACK, 1.0, "gunmetal")
	var mat_visor := _make_mat(col_visor, 0.2, 0.1, true, col_visor, 3.4)
	var mat_glow := _make_mat( Color("#38bdf8"), 0.1, 0.1, true, Color("#38bdf8"), 4.0)
	var mat_plasma := _make_mat(h_col, 0.3, 0.1, true, h_col, 3.6)

	var wep_data: Dictionary = GameData.get_weapon_by_id(weapon_id if (weapon_id != "empty" and weapon_id != "") else "r301")

	# =========================================================================
	# 1. INSTANTIATE UAL1_STANDARD.GLB 65-BONE SKINNED CHARACTER & ANIMATIONPLAYER
	# =========================================================================
	var ual_model := _instantiate_ual_character()
	if ual_model != null:
		ual_model.name = "UALCharacterModel"
		# UAL1_Standard.glb faces +Z in glTF space; rotate PI around Y so character faces -Z (Godot forward)!
		ual_model.rotation.y = PI
		root.add_child(ual_model)

		var skels := ual_model.find_children("*", "Skeleton3D", true, false)
		var skel: Skeleton3D = (skels[0] as Skeleton3D) if not skels.is_empty() else null
		var anim_players := ual_model.find_children("*", "AnimationPlayer", true, false)
		var anim_player: AnimationPlayer = (anim_players[0] as AnimationPlayer) if not anim_players.is_empty() else null

		# Style the skinned Mannequin mesh with Legend-specific PBR Armor & Trim materials!
		for child in ual_model.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi != null and mi.mesh != null:
				mi.set_surface_override_material(0, mat_prim)
				if mi.mesh.get_surface_count() > 1:
					mi.set_surface_override_material(1, mat_sec if lid != "wraith" else mat_suit)

		# Configure all looping clips in AnimationPlayer and start idle animation
		if anim_player != null:
			for anim_name in anim_player.get_animation_list():
				var anim_res: Animation = anim_player.get_animation(anim_name)
				if anim_res != null and ("Loop" in str(anim_name) or "Idle" in str(anim_name)):
					anim_res.loop_mode = Animation.LOOP_LINEAR
			if anim_player.has_animation("Pistol_Idle_Loop"):
				anim_player.play("Pistol_Idle_Loop")
			elif anim_player.has_animation("Idle_Loop"):
				anim_player.play("Idle_Loop")

		if skel != null:
			# -----------------------------------------------------------------
			# A. HEAD BONE ATTACHMENT ("Head") — 12 Legend-Specific Helmets & Visors
			# -----------------------------------------------------------------
			var head_att := BoneAttachment3D.new()
			head_att.name = "HeadBoneAttachment"
			head_att.bone_name = "Head"
			skel.add_child(head_att)

			var neck_pivot := Node3D.new()
			neck_pivot.name = "NeckPivot"
			neck_pivot.position = Vector3(0.0, 0.11, 0.01)
			head_att.add_child(neck_pivot)

			# Glowing tactical visor across face (+Z is forward in Head bone space)
			_add_box(neck_pivot, Vector3(0.15, 0.045, 0.06), Vector3(0, 0.02, 0.105), mat_visor, Vector3.ZERO, "VisorMesh")
			_add_Legend_headgear_gen3(neck_pivot, lid, mat_prim, mat_sec, mat_dark, mat_metal, mat_visor, mat_glow, mat_plasma)

			# -----------------------------------------------------------------
			# B. CHEST / BACK BONE ATTACHMENT ("spine_03") — Armor, Jumpkit & Back Holster
			# -----------------------------------------------------------------
			var chest_att := BoneAttachment3D.new()
			chest_att.name = "ChestBoneAttachment"
			chest_att.bone_name = "spine_03"
			skel.add_child(chest_att)

			_add_Legend_chestgear_gen3(chest_att, lid, mat_prim, mat_sec, mat_dark, mat_metal, mat_visor, mat_glow, mat_plasma)

			# IMC Jumpkit Thrusters on lower back (-Z in spine_03 space)
			for side_s in [-1.0, 1.0]:
				var j_nozzle := _add_cyl(chest_att, 0.036, 0.048, 0.12, Vector3(side_s * 0.11, -0.16, -0.15), mat_metal, Vector3(0.35, 0, side_s * 0.18), 10)
				var j_flame := _add_cyl(j_nozzle, 0.032, 0.004, 0.24, Vector3(0, -0.16, 0), mat_glow, Vector3.ZERO, 8, "JumpkitJetL" if side_s < 0.0 else "JumpkitJetR")
				j_flame.visible = false

			# Back Holster Root (visible when healing, climbing, or holding Heirloom)
			var back_holster := Node3D.new()
			back_holster.name = "BackHolsterRoot"
			back_holster.position = Vector3(0.05, 0.04, -0.17)
			back_holster.rotation = Vector3(0.0, PI * 0.5, 0.65)
			back_holster.visible = false
			chest_att.add_child(back_holster)
			var holstered_wep := WeaponMeshBuilder.create_third_person_weapon_mesh(wep_data)
			holstered_wep.scale = Vector3(0.85, 0.85, 0.85)
			back_holster.add_child(holstered_wep)

			# -----------------------------------------------------------------
			# C. RIGHT HAND BONE ATTACHMENT ("hand_r") — Held Firearm & Right Heirloom
			# -----------------------------------------------------------------
			var rhand_att := BoneAttachment3D.new()
			rhand_att.name = "RightHandBoneAttachment"
			rhand_att.bone_name = "hand_r"
			skel.add_child(rhand_att)

			var held_wep_root := Node3D.new()
			held_wep_root.name = "HeldWeaponRoot"
			# In UAL1_Standard hand_r: +Y is forward (wrist->knuckles) and +Z is up!
			held_wep_root.position = Vector3(0.0, 0.08, 0.02)
			held_wep_root.rotation = Vector3(PI * 0.5, 0.0, 0.0)
			rhand_att.add_child(held_wep_root)
			var tp_wep := WeaponMeshBuilder.create_third_person_weapon_mesh(wep_data)
			held_wep_root.add_child(tp_wep)

			var held_hl_root := Node3D.new()
			held_hl_root.name = "HeldHeirloomRoot"
			held_hl_root.visible = false
			rhand_att.add_child(held_hl_root)
			if lid == "pathfinder":
				_build_tp_boxing_glove(held_hl_root, false, h_col)
			else:
				held_hl_root.position = Vector3(0.0, 0.08, 0.02)
				held_hl_root.rotation = Vector3(0.0, 0.0, -PI * 0.5)
				var tp_hl := WeaponMeshBuilder.create_third_person_heirloom_mesh(legend_data)
				held_hl_root.add_child(tp_hl)

			# -----------------------------------------------------------------
			# D. LEFT HAND BONE ATTACHMENT ("hand_l") — Dual-Wield Heirloom & Heal Props
			# -----------------------------------------------------------------
			var lhand_att := BoneAttachment3D.new()
			lhand_att.name = "LeftHandBoneAttachment"
			lhand_att.bone_name = "hand_l"
			skel.add_child(lhand_att)

			var held_left_hl := Node3D.new()
			held_left_hl.name = "HeldLeftHeirloomRoot"
			held_left_hl.visible = false
			lhand_att.add_child(held_left_hl)
			if lid == "pathfinder":
				_build_tp_boxing_glove(held_left_hl, true, h_col)
			elif lid == "lifeline" or lid == "ash":
				held_left_hl.position = Vector3(0.0, 0.08, 0.02)
				held_left_hl.rotation = Vector3(0.0, 0.0, PI * 0.5)
				var tp_l_hl := WeaponMeshBuilder.create_third_person_heirloom_mesh(legend_data)
				held_left_hl.add_child(tp_l_hl)

			var heal_prop := Node3D.new()
			heal_prop.name = "HealPropRoot"
			heal_prop.position = Vector3(0.0, 0.08, 0.03)
			heal_prop.visible = false
			lhand_att.add_child(heal_prop)
			_add_cyl(heal_prop, 0.055, 0.055, 0.20, Vector3.ZERO, mat_dark, Vector3.ZERO, 12, "TP_BatteryBody")
			_add_cyl(heal_prop, 0.048, 0.048, 0.12, Vector3.ZERO, mat_glow, Vector3.ZERO, 12, "TP_BatteryCore")

	return root


static func _add_Legend_headgear_gen3(neck_pivot: Node3D, lid: String, mat_prim: Material, mat_sec: Material, mat_dark: Material, mat_metal: Material, mat_visor: Material, mat_glow: Material, mat_plasma: Material) -> void:
	match lid:
		"bloodhound":
			# Nordic Wide-Brim Respirator Helmet + Plague Beak (+Z forward)
			_add_cyl(neck_pivot, 0.12, 0.17, 0.05, Vector3(0, 0.09, 0), mat_prim, Vector3.ZERO, 14)
			_add_box(neck_pivot, Vector3(0.28, 0.03, 0.04), Vector3(0, 0.12, 0.02), mat_sec)
			_add_cyl(neck_pivot, 0.02, 0.06, 0.12, Vector3(0, -0.01, 0.14), mat_dark, Vector3(PI * 0.5, 0, 0), 8, "PlagueBeak")
		"pathfinder":
			# MRVN Cyclops Camera Head + Glowing Eye Lens
			_add_box(neck_pivot, Vector3(0.18, 0.18, 0.20), Vector3(0, 0.02, 0.02), mat_prim)
			_add_cyl(neck_pivot, 0.055, 0.055, 0.04, Vector3(0, 0.02, 0.12), mat_glow, Vector3(PI * 0.5, 0, 0), 16, "MRVNEye")
			_add_cyl(neck_pivot, 0.008, 0.012, 0.12, Vector3(0.10, 0.12, 0.0), mat_sec, Vector3(0, 0, -0.25), 8)
			_add_cyl(neck_pivot, 0.008, 0.012, 0.12, Vector3(-0.10, 0.12, 0.0), mat_sec, Vector3(0, 0, 0.25), 8)
		"wraith":
			# Void Scarf Collar + Side Hair Buns
			_add_cyl(neck_pivot, 0.13, 0.15, 0.09, Vector3(0, -0.07, 0.01), mat_dark, Vector3.ZERO, 14, "VoidScarf")
			_add_sphere(neck_pivot, 0.065, Vector3(0, 0.08, -0.09), mat_dark, "WraithHairBun")
		"octane":
			# Aviator Stim Goggles + Respirator Mask
			_add_cyl(neck_pivot, 0.044, 0.044, 0.04, Vector3(-0.048, 0.03, 0.11), mat_glow, Vector3(PI * 0.5, 0, 0), 12)
			_add_cyl(neck_pivot, 0.044, 0.044, 0.04, Vector3(0.048, 0.03, 0.11), mat_glow, Vector3(PI * 0.5, 0, 0), 12)
			_add_box(neck_pivot, Vector3(0.13, 0.065, 0.07), Vector3(0, -0.03, 0.10), mat_dark)
		"lifeline":
			# Medic Headband + Twin Side Hair Buns
			_add_cyl(neck_pivot, 0.115, 0.115, 0.035, Vector3(0, 0.06, 0.01), mat_sec, Vector3.ZERO, 16)
			_add_sphere(neck_pivot, 0.062, Vector3(-0.12, 0.07, -0.02), mat_prim, "LeftBun")
			_add_sphere(neck_pivot, 0.062, Vector3(0.12, 0.07, -0.02), mat_prim, "RightBun")
		"gibraltar":
			# Heavy Ballistic Helmet + Crest
			_add_sphere(neck_pivot, 0.128, Vector3(0, 0.04, 0.0), mat_prim, "GibbyHelm", Vector3(1.08, 1.0, 1.12))
			_add_box(neck_pivot, Vector3(0.05, 0.07, 0.22), Vector3(0, 0.12, 0.0), mat_sec)
		"valkyrie":
			# Viper Flight Helmet + Winged Fins
			_add_sphere(neck_pivot, 0.125, Vector3(0, 0.03, 0.01), mat_prim, "ViperHelm", Vector3(1.05, 1.05, 1.18))
			_add_box(neck_pivot, Vector3(0.02, 0.08, 0.16), Vector3(-0.11, 0.06, -0.04), mat_sec, Vector3(0.25, -0.2, 0))
			_add_box(neck_pivot, Vector3(0.02, 0.08, 0.16), Vector3(0.11, 0.06, -0.04), mat_sec, Vector3(0.25, 0.2, 0))
		"ash":
			# Cybernetic White Porcelain Faceplate + Hood Shroud
			_add_box(neck_pivot, Vector3(0.14, 0.16, 0.04), Vector3(0, 0.02, 0.10), mat_metal)
			_add_sphere(neck_pivot, 0.132, Vector3(0, 0.03, -0.01), mat_prim, "AshHood", Vector3(1.08, 1.12, 1.15))
		"caustic":
			# Dual-Filter Nox Gas Mask
			_add_cyl(neck_pivot, 0.038, 0.042, 0.06, Vector3(-0.055, -0.03, 0.12), mat_sec, Vector3(PI * 0.4, -0.35, 0), 10)
			_add_cyl(neck_pivot, 0.038, 0.042, 0.06, Vector3(0.055, -0.03, 0.12), mat_sec, Vector3(PI * 0.4, 0.35, 0), 10)
		"horizon":
			# Astro-Visor + Gravity Headset
			_add_box(neck_pivot, Vector3(0.04, 0.09, 0.14), Vector3(0, 0.12, 0.02), mat_sec, Vector3(-0.2, 0, 0))
		"mirage":
			# Holo-Pilot Goggles on Forehead
			_add_cyl(neck_pivot, 0.040, 0.040, 0.04, Vector3(-0.045, 0.07, 0.105), mat_plasma, Vector3(PI * 0.5, 0, 0), 12)
			_add_cyl(neck_pivot, 0.040, 0.040, 0.04, Vector3(0.045, 0.07, 0.105), mat_plasma, Vector3(PI * 0.5, 0, 0), 12)
		_:
			# Bangalore IMC Tactical Headset
			_add_cyl(neck_pivot, 0.042, 0.042, 0.03, Vector3(-0.11, 0.02, 0.0), mat_dark, Vector3(0, 0, PI * 0.5), 10)
			_add_cyl(neck_pivot, 0.042, 0.042, 0.03, Vector3(0.11, 0.02, 0.0), mat_dark, Vector3(0, 0, PI * 0.5), 10)


static func _add_Legend_chestgear_gen3(chest_att: Node3D, lid: String, mat_prim: Material, mat_sec: Material, mat_dark: Material, mat_metal: Material, _mat_visor: Material, mat_glow: Material, mat_plasma: Material) -> void:
	# Front Chest Tactical Plate (+Z) & Back Rig (-Z)
	_add_box(chest_att, Vector3(0.28, 0.24, 0.06), Vector3(0, 0.02, 0.11), mat_prim, Vector3.ZERO, "ChestArmorPlate")
	_add_box(chest_att, Vector3(0.12, 0.08, 0.02), Vector3(0, 0.04, 0.145), mat_sec, Vector3.ZERO, "ChestEmblem")

	match lid:
		"pathfinder":
			# Pathfinder Chest LCD Smiley Screen + Shoulder Grapple Winches
			_add_box(chest_att, Vector3(0.18, 0.14, 0.03), Vector3(0, 0.03, 0.14), mat_dark)
			_add_box(chest_att, Vector3(0.15, 0.11, 0.035), Vector3(0, 0.03, 0.145), mat_glow, Vector3.ZERO, "PathfinderChestScreen")
			_add_cyl(chest_att, 0.055, 0.055, 0.08, Vector3(-0.18, 0.14, -0.06), mat_metal, Vector3(0, 0, PI * 0.5), 12)
			_add_cyl(chest_att, 0.055, 0.055, 0.08, Vector3(0.18, 0.14, -0.06), mat_metal, Vector3(0, 0, PI * 0.5), 12)
		"valkyrie":
			# Valkyrie Swept VTOL Jetpack Wings on Back (-Z)
			_add_box(chest_att, Vector3(0.24, 0.30, 0.12), Vector3(0, 0.04, -0.15), mat_dark, Vector3.ZERO, "VTOLPack")
			_add_box(chest_att, Vector3(0.46, 0.10, 0.03), Vector3(-0.32, 0.14, -0.18), mat_sec, Vector3(0, -0.22, 0.38), "ValkWingL")
			_add_box(chest_att, Vector3(0.46, 0.10, 0.03), Vector3(0.32, 0.14, -0.18), mat_sec, Vector3(0, 0.22, -0.38), "ValkWingR")
		"gibraltar":
			# Gibraltar Back Dome Shield Disc
			_add_cyl(chest_att, 0.19, 0.19, 0.06, Vector3(0, 0.04, -0.15), mat_sec, Vector3(PI * 0.5, 0, 0), 16, "GibbyBackDome")
		"caustic":
			# Caustic Twin Nox Gas Cylinders on Back
			_add_cyl(chest_att, 0.055, 0.055, 0.32, Vector3(-0.09, 0.02, -0.16), mat_sec, Vector3.ZERO, 12)
			_add_cyl(chest_att, 0.055, 0.055, 0.32, Vector3(0.09, 0.02, -0.16), mat_sec, Vector3.ZERO, 12)
		"lifeline":
			# Lifeline D.O.C. Drone Docked on Back
			_add_cyl(chest_att, 0.13, 0.13, 0.05, Vector3(0, 0.04, -0.15), mat_metal, Vector3(PI * 0.5, 0, 0), 14)
			_add_sphere(chest_att, 0.05, Vector3(0, 0.04, -0.18), mat_plasma)
		"octane":
			# Octane Dual Glowing Stim Packs on Back
			_add_cyl(chest_att, 0.036, 0.036, 0.22, Vector3(-0.08, 0.02, -0.15), mat_glow, Vector3(0, 0, 0.18), 10)
			_add_cyl(chest_att, 0.036, 0.036, 0.22, Vector3(0.08, 0.02, -0.15), mat_glow, Vector3(0, 0, -0.18), 10)
		_:
			_add_box(chest_att, Vector3(0.22, 0.26, 0.09), Vector3(0, 0.02, -0.14), mat_dark, Vector3.ZERO, "TacticalBackpack")


static func _play_ual_anim(anim_player: AnimationPlayer, clip_name: String, speed: float = 1.0, blend: float = 0.15) -> void:
	if anim_player == null:
		return
	var target_clip: String = clip_name
	if not anim_player.has_animation(target_clip):
		# Fallback search if GLTF importer prefixed library name
		for cname in anim_player.get_animation_list():
			if str(cname).ends_with(clip_name):
				target_clip = str(cname)
				break
	if not anim_player.has_animation(target_clip):
		return
	anim_player.speed_scale = speed
	if anim_player.current_animation != target_clip or not anim_player.is_playing():
		anim_player.play(target_clip, blend)


static func animate_rig(rig: Node3D, delta: float, s: Dictionary = {}) -> void:
	if rig == null:
		return

	var ual_model: Node3D = rig.get_node_or_null("UALCharacterModel") as Node3D
	if ual_model == null:
		return

	var anim_players := ual_model.find_children("*", "AnimationPlayer", true, false)
	var anim_player: AnimationPlayer = (anim_players[0] as AnimationPlayer) if not anim_players.is_empty() else null
	var skels := ual_model.find_children("*", "Skeleton3D", true, false)
	var skel: Skeleton3D = (skels[0] as Skeleton3D) if not skels.is_empty() else null

	var mode: String = str(s.get("mode", "combat"))
	var lid: String = str(rig.get_meta("legend_id", "wraith"))
	var is_moving: bool = bool(s.get("is_moving", false))
	var is_sliding: bool = bool(s.get("is_sliding", false))
	var is_crouching: bool = bool(s.get("is_crouching", false))
	var is_in_air: bool = bool(s.get("is_in_air", false))
	var vel_y: float = float(s.get("vel_y", 0.0))
	var is_wall_climbing: bool = bool(s.get("is_wall_climbing", false))
	var is_mantling: bool = bool(s.get("is_mantling", false))
	var is_ziplining: bool = bool(s.get("is_ziplining", false))
	var is_grappling: bool = bool(s.get("is_grappling", false))
	var is_healing: bool = bool(s.get("is_healing", false))
	var is_heirloom: bool = bool(s.get("is_heirloom", false))
	var is_reloading: bool = bool(s.get("is_reloading", false))
	var is_firing: bool = bool(s.get("is_firing", false))
	var is_melee: bool = bool(s.get("is_melee", false))
	var melee_combo_idx: int = int(s.get("melee_combo_idx", 0))
	var is_ads: bool = bool(s.get("is_ads", false))
	var aim_pitch: float = float(s.get("aim_pitch", 0.0))
	var move_angle_local: float = float(s.get("move_angle_local", 0.0))
	var flinch: float = float(s.get("flinch", 0.0))
	var speed: float = float(s.get("speed", 6.5))

	# 1. Toggle Held Firearm / Held Heirloom / Dual-Wield Left Heirloom / Back Holster / Heal Prop
	var held_wep: Node3D = ual_model.find_child("HeldWeaponRoot", true, false) as Node3D
	var held_hl: Node3D = ual_model.find_child("HeldHeirloomRoot", true, false) as Node3D
	var held_left_hl: Node3D = ual_model.find_child("HeldLeftHeirloomRoot", true, false) as Node3D
	var back_holster: Node3D = ual_model.find_child("BackHolsterRoot", true, false) as Node3D
	var heal_prop: Node3D = ual_model.find_child("HealPropRoot", true, false) as Node3D
	var jet_l: Node3D = ual_model.find_child("JumpkitJetL", true, false) as Node3D
	var jet_r: Node3D = ual_model.find_child("JumpkitJetR", true, false) as Node3D

	var hands_busy: bool = (is_healing or is_wall_climbing or is_mantling)
	if held_wep:
		held_wep.visible = (not is_heirloom) and (not hands_busy)
	if held_hl:
		held_hl.visible = is_heirloom and (not hands_busy)
	if held_left_hl:
		held_left_hl.visible = is_heirloom and (not hands_busy) and (lid == "pathfinder" or lid == "lifeline" or lid == "ash")
	if back_holster:
		back_holster.visible = is_heirloom or hands_busy
	if heal_prop:
		heal_prop.visible = is_healing

	var jets_active: bool = (is_sliding or is_in_air or is_ziplining or is_grappling or is_wall_climbing)
	if jet_l:
		jet_l.visible = jets_active
	if jet_r:
		jet_r.visible = jets_active

	# 2. Smooth Lower-Body / Whole-Model Directional Alignment & Slide Tilt
	var target_model_pitch: float = -0.52 if is_sliding else 0.0
	var target_model_y: float = -0.32 if is_sliding else 0.0
	var target_model_yaw: float = PI + (clampf(move_angle_local * 0.45, -0.55, 0.55) if is_moving else 0.0)
	ual_model.position.y = lerpf(ual_model.position.y, target_model_y, delta * 14.0)
	ual_model.rotation.x = lerpf(ual_model.rotation.x, target_model_pitch, delta * 14.0)
	ual_model.rotation.y = lerp_angle(ual_model.rotation.y, target_model_yaw, delta * 12.0)

	# 3. Select & Play Real Open-Source Animation from UAL1_Standard.glb AnimationPlayer!
	if mode == "lobby":
		_play_ual_anim(anim_player, "Pistol_Idle_Loop", 0.90, 0.25)
		return

	if is_melee:
		if is_heirloom and lid != "pathfinder":
			if melee_combo_idx % 2 == 0:
				_play_ual_anim(anim_player, "Sword_Attack", 2.1, 0.06)
			else:
				_play_ual_anim(anim_player, "Punch_Cross", 1.9, 0.06)
		else:
			if melee_combo_idx % 2 == 0:
				_play_ual_anim(anim_player, "Punch_Jab", 1.95, 0.05)
			else:
				_play_ual_anim(anim_player, "Punch_Cross", 1.95, 0.05)
	elif flinch > 0.15:
		_play_ual_anim(anim_player, "Hit_Chest", 1.5, 0.05)
	elif is_healing:
		_play_ual_anim(anim_player, "Interact", 1.1, 0.15)
	elif is_reloading:
		_play_ual_anim(anim_player, "Pistol_Reload", 1.15, 0.12)
	elif is_wall_climbing or is_mantling:
		_play_ual_anim(anim_player, "Push_Loop", 1.6, 0.10)
	elif is_in_air or is_ziplining or is_grappling:
		if vel_y > 2.2:
			_play_ual_anim(anim_player, "Jump_Start", 1.2, 0.08)
		else:
			_play_ual_anim(anim_player, "Jump_Loop", 1.0, 0.12)
	elif is_sliding:
		_play_ual_anim(anim_player, "Crouch_Fwd_Loop", 1.4, 0.10)
	elif is_crouching:
		if is_moving:
			_play_ual_anim(anim_player, "Crouch_Fwd_Loop", clampf(speed / 3.2, 0.8, 1.4), 0.12)
		else:
			_play_ual_anim(anim_player, "Crouch_Idle_Loop", 1.0, 0.15)
	elif is_moving:
		var is_sprinting: bool = (speed > 7.4 and not is_ads and not is_firing)
		if is_sprinting:
			_play_ual_anim(anim_player, "Sprint_Loop", clampf(speed / 7.2, 0.85, 1.45), 0.12)
		elif speed > 3.2 and not is_ads:
			_play_ual_anim(anim_player, "Jog_Fwd_Loop", clampf(speed / 5.0, 0.85, 1.35), 0.12)
		else:
			_play_ual_anim(anim_player, "Walk_Loop", clampf(speed / 3.0, 0.80, 1.30), 0.12)
	else:
		if is_firing:
			_play_ual_anim(anim_player, "Pistol_Shoot", 1.6, 0.05)
		elif is_heirloom:
			_play_ual_anim(anim_player, "Sword_Idle", 1.0, 0.18)
		else:
			_play_ual_anim(anim_player, "Pistol_Idle_Loop", 1.0, 0.18)

	# 4. Apply Spine / Head Aim Pitch Tracking on Skeleton3D when aiming up/down
	if skel != null and absf(aim_pitch) > 0.01:
		var head_idx: int = skel.find_bone("Head")
		if head_idx >= 0:
			var cur_q: Quaternion = skel.get_bone_pose_rotation(head_idx)
			var pitch_q := Quaternion.from_euler(Vector3(-aim_pitch * 0.45, 0.0, 0.0))
			skel.set_bone_pose_rotation(head_idx, cur_q * pitch_q)
