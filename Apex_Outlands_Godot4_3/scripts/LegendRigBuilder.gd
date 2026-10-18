class_name LegendRigBuilder
extends RefCounted
## ============================================================================
## GENERATION 5.0: 12-LEGEND BESPOKE 3D ARMOR/SYLHOUETTE OVERHAUL & LOSSLESS
## 65-BONE 30FPS MOCAP ENGINE (`ual_mocap_bank.bin` + `Mannequin_F.glb` + `UAL1/2`)
## ============================================================================
## Key Features:
## 1. Lossless 65-Bone 30FPS Mocap Bank (`res://assets/animations/ual_mocap_bank.bin`):
##    Directly poses all 65 bones of `Skeleton3D` every frame from 33 motion-captured
##    clips in `UAL1_Standard.glb` & `UAL2_Standard.glb`, completely bypassing Godot's
##    `remove_immutable_tracks` stripping and `AnimationPlayer` path-binding issues!
## 2. True 12-Legend Visual Differentiation (`全12位传奇角色差异化建模`):
##    - Female Legends (`wraith`, `lifeline`, `bangalore`, `ash`, `horizon`, `valkyrie`)
##      use the sculpted female mesh (`Mannequin_F.glb`).
##    - Male & Robotic Legends (`bloodhound`, `pathfinder`, `octane`, `gibraltar`,
##      `caustic`, `mirage`) use `UAL1_Standard.glb`.
##    - Distinct per-Legend body proportions (`legend_scale`), 2-tone base materials,
##      and 10-zone bone-attached 3D helmets/hair, chest cuirasses, jetpacks/wings/drones,
##      waist coats/kilts/aprons, shoulder pauldrons, forearm gauntlets, baggy cargo pants,
##      and prosthetic/robotic lower legs!
## 3. Fixes All 6 Animation & Unified 1P/3P Camera Requirements:
##    - Reload (`Pistol_Reload`) is driven 1:1 by `reload_progress` (`0.0 -> 1.0`) so it
##      plays strictly ONCE and never repeats.
##    - Jump landing, Slide exit (`Slide_Loop`), and Wall-Climb (`ClimbUp_1m`) reset all
##      65 bones cleanly every frame with zero residual stuck poses.
##    - Full lower-body `Walk_Loop`, `Jog_Fwd_Loop`, and `Sprint_Loop` combined with
##      pelvis-compensated upper-body weapon aiming.
##    - Unified 1st-person & 3rd-person character hands and weapons with zero head clipping.
## ============================================================================

const BONE_NAMES_65: Array = [
	"root", "pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head",
	"clavicle_l", "upperarm_l", "lowerarm_l", "hand_l",
	"index_01_l", "index_02_l", "index_03_l", "index_04_leaf_l",
	"middle_01_l", "middle_02_l", "middle_03_l", "middle_04_leaf_l",
	"pinky_01_l", "pinky_02_l", "pinky_03_l", "pinky_04_leaf_l",
	"ring_01_l", "ring_02_l", "ring_03_l", "ring_04_leaf_l",
	"thumb_01_l", "thumb_02_l", "thumb_03_l", "thumb_04_leaf_l",
	"clavicle_r", "upperarm_r", "lowerarm_r", "hand_r",
	"index_01_r", "index_02_r", "index_03_r", "index_04_leaf_r",
	"middle_01_r", "middle_02_r", "middle_03_r", "middle_04_leaf_r",
	"pinky_01_r", "pinky_02_r", "pinky_03_r", "pinky_04_leaf_r",
	"ring_01_r", "ring_02_r", "ring_03_r", "ring_04_leaf_r",
	"thumb_01_r", "thumb_02_r", "thumb_03_r", "thumb_04_leaf_r",
	"thigh_l", "calf_l", "foot_l", "ball_l", "ball_leaf_l",
	"thigh_r", "calf_r", "foot_r", "ball_r", "ball_leaf_r"
]

# Bone indices (in BONE_NAMES_65) for upper-body firearm aiming overlay (spine_02..thumb_04_leaf_r)
const UPPER_BODY_INDICES: Array = [
	3, 4, 5, 6,
	7, 8, 9, 10,
	11, 12, 13, 15, 16, 17, 19, 20, 21, 23, 24, 25, 27, 28, 29,
	31, 32, 33, 34,
	35, 36, 37, 39, 40, 41, 43, 44, 45, 47, 48, 49, 51, 52, 53
]

const FEMALE_LEGENDS: Array = ["wraith", "lifeline", "bangalore", "ash", "horizon", "valkyrie"]

static var _mocap_loaded: bool = false
static var _mocap_bank: Dictionary = {}
static var _male_packed: PackedScene = null
static var _female_packed: PackedScene = null


static func _ensure_mocap_bank_loaded() -> void:
	if _mocap_loaded:
		return
	_mocap_loaded = true
	var bin_path: String = "res://assets/animations/ual_mocap_bank.bin"
	if not FileAccess.file_exists(bin_path):
		return
	var f := FileAccess.open(bin_path, FileAccess.READ)
	if f == null:
		return
	var magic: int = f.get_32()
	if magic != 0x55414C34:
		return
	var num_clips: int = f.get_32()
	var num_bones: int = f.get_32()
	var stride: int = 3 + num_bones * 4
	for _c in range(num_clips):
		var name_len: int = f.get_32()
		var dur: float = f.get_float()
		var nframes: int = f.get_32()
		var cname: String = f.get_buffer(name_len).get_string_from_utf8()
		var byte_len: int = nframes * stride * 4
		var raw_bytes: PackedByteArray = f.get_buffer(byte_len)
		var floats: PackedFloat32Array = raw_bytes.to_float32_array()
		_mocap_bank[cname] = {
			"duration": maxf(0.01, dur),
			"num_frames": max(1, nframes),
			"floats": floats
		}


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
		m.normal_scale = 0.14 if kind == "gunmetal" else 0.18
		m.normal_texture = CanyonWorldBuilder.get_procedural_normal_tex(kind)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(16.0, 16.0, 16.0)
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


static func _instantiate_character_model(is_female: bool) -> Node3D:
	var fem_paths: Array = ["res://assets/animations/Mannequin_F.glb", "res://assets/models/character/Mannequin_F.glb"]
	var male_paths: Array = ["res://assets/animations/UAL1_Standard.glb", "res://assets/models/character/UAL1_Standard.glb"]
	var search_paths: Array = (fem_paths + male_paths) if is_female else male_paths

	if is_female and _female_packed != null:
		var inst_f := _female_packed.instantiate() as Node3D
		if inst_f != null:
			return inst_f
	elif (not is_female) and _male_packed != null:
		var inst_m := _male_packed.instantiate() as Node3D
		if inst_m != null:
			return inst_m

	for p_item in search_paths:
		var p: String = str(p_item)
		if ResourceLoader.exists(p):
			var res := load(p)
			if res is PackedScene:
				if is_female and "Mannequin_F" in p:
					_female_packed = res
				elif "UAL1_Standard" in p:
					_male_packed = res
				var inst := (res as PackedScene).instantiate() as Node3D
				if inst != null:
					return inst
		if FileAccess.file_exists(p):
			var doc := GLTFDocument.new()
			var state := GLTFState.new()
			if doc.append_from_file(ProjectSettings.globalize_path(p), state) == OK:
				var gen := doc.generate_scene(state) as Node3D
				if gen != null:
					return gen
	return null


static func _build_bone_map(skel: Skeleton3D) -> PackedInt32Array:
	var bmap := PackedInt32Array()
	bmap.resize(65)
	for i in range(65):
		bmap[i] = skel.find_bone(str(BONE_NAMES_65[i])) if skel != null else -1
	return bmap


static func _sample_mocap_clip_to_skeleton(skel: Skeleton3D, bone_map: PackedInt32Array, clip_name: String, sample_time: float, loop: bool = true) -> bool:
	if skel == null or bone_map.size() < 65:
		return false
	_ensure_mocap_bank_loaded()
	var clip: Dictionary = _mocap_bank.get(clip_name, {})
	if clip.is_empty():
		clip = _mocap_bank.get("Pistol_Idle_Loop", {})
		if clip.is_empty():
			return false
	var num_frames: int = int(clip["num_frames"])
	var duration: float = maxf(0.001, float(clip["duration"]))
	var floats: PackedFloat32Array = clip["floats"]
	var t_norm: float = (fposmod(sample_time, duration) / duration) if loop else clampf(sample_time / duration, 0.0, 1.0)
	var f_exact: float = t_norm * float(max(0, num_frames - 1))
	var f0: int = clampi(int(floor(f_exact)), 0, num_frames - 1)
	var f1: int = clampi(f0 + 1, 0, num_frames - 1)
	var frac: float = clampf(f_exact - float(f0), 0.0, 1.0)
	var base0: int = f0 * 263
	var base1: int = f1 * 263

	var pel_idx: int = bone_map[1]
	if pel_idx >= 0:
		var px: float = lerpf(floats[base0 + 0], floats[base1 + 0], frac)
		var py: float = lerpf(floats[base0 + 1], floats[base1 + 1], frac)
		var pz: float = lerpf(floats[base0 + 2], floats[base1 + 2], frac)
		skel.set_bone_pose_position(pel_idx, Vector3(px, py, pz))

	for b_i in range(65):
		var skel_b: int = bone_map[b_i]
		if skel_b < 0:
			continue
		var o0: int = base0 + 3 + b_i * 4
		var o1: int = base1 + 3 + b_i * 4
		var q0 := Quaternion(floats[o0], floats[o0 + 1], floats[o0 + 2], floats[o0 + 3])
		var q1 := Quaternion(floats[o1], floats[o1 + 1], floats[o1 + 2], floats[o1 + 3])
		skel.set_bone_pose_rotation(skel_b, q0.slerp(q1, frac))
	return true


static func _overlay_upper_body_pistol_aim(skel: Skeleton3D, bone_map: PackedInt32Array, aim_time: float, bob_phase: float = 0.0, is_moving: bool = false, is_sprinting: bool = false) -> void:
	if skel == null or bone_map.size() < 65:
		return
	var clip: Dictionary = _mocap_bank.get("Pistol_Idle_Loop", {})
	if clip.is_empty():
		return
	var num_frames: int = int(clip["num_frames"])
	var duration: float = maxf(0.001, float(clip["duration"]))
	var floats: PackedFloat32Array = clip["floats"]
	var t_norm: float = fposmod(aim_time, duration) / duration
	var f_exact: float = t_norm * float(max(0, num_frames - 1))
	var f0: int = clampi(int(floor(f_exact)), 0, num_frames - 1)
	var f1: int = clampi(f0 + 1, 0, num_frames - 1)
	var frac: float = clampf(f_exact - float(f0), 0.0, 1.0)
	var base0: int = f0 * 263
	var base1: int = f1 * 263

	for idx_item in UPPER_BODY_INDICES:
		var b_i: int = int(idx_item)
		var skel_b: int = bone_map[b_i]
		if skel_b < 0:
			continue
		var o0: int = base0 + 3 + b_i * 4
		var o1: int = base1 + 3 + b_i * 4
		var q0 := Quaternion(floats[o0], floats[o0 + 1], floats[o0 + 2], floats[o0 + 3])
		var q1 := Quaternion(floats[o1], floats[o1 + 1], floats[o1 + 2], floats[o1 + 3])
		var q_aim: Quaternion = q0.slerp(q1, frac)
		if is_moving and (b_i == 32 or b_i == 8):
			var bob_amp: float = 0.035 if is_sprinting else 0.018
			q_aim = q_aim * Quaternion(Vector3.RIGHT, sin(bob_phase) * bob_amp)
		skel.set_bone_pose_rotation(skel_b, q_aim)


static func _get_pistol_ref_quat(b_i: int) -> Quaternion:
	var clip: Dictionary = _mocap_bank.get("Pistol_Idle_Loop", {})
	if clip.is_empty():
		return Quaternion.IDENTITY
	var floats: PackedFloat32Array = clip["floats"]
	var o: int = 3 + b_i * 4
	return Quaternion(floats[o], floats[o + 1], floats[o + 2], floats[o + 3])


static func _get_legend_body_scale(lid: String) -> Vector3:
	match lid:
		"gibraltar":
			return Vector3(1.24, 1.08, 1.26)
		"caustic":
			return Vector3(1.16, 1.05, 1.18)
		"pathfinder":
			return Vector3(1.04, 1.06, 1.04)
		"bloodhound":
			return Vector3(1.02, 1.01, 1.02)
		"mirage":
			return Vector3(1.00, 1.00, 1.00)
		"bangalore":
			return Vector3(0.97, 1.00, 0.97)
		"horizon":
			return Vector3(0.94, 0.99, 0.94)
		"valkyrie":
			return Vector3(0.93, 0.97, 0.93)
		"octane":
			return Vector3(0.92, 0.97, 0.92)
		"ash":
			return Vector3(0.90, 1.00, 0.90)
		"lifeline":
			return Vector3(0.91, 0.94, 0.91)
		"wraith":
			return Vector3(0.90, 0.95, 0.90)
		_:
			return Vector3.ONE


static func _get_legend_undersuit_color(lid: String) -> Color:
	match lid:
		"wraith":
			return Color("#1e1b4b")
		"octane":
			return Color("#1c1917")
		"bloodhound":
			return Color("#451a03")
		"pathfinder":
			return Color("#334155")
		"lifeline":
			return Color("#f1f5f9")
		"gibraltar":
			return Color("#431407")
		"bangalore":
			return Color("#292524")
		"ash":
			return Color("#cbd5e1")
		"horizon":
			return Color("#f8fafc")
		"valkyrie":
			return Color("#1e1b4b")
		"caustic":
			return Color("#1a2e05")
		"mirage":
			return Color("#27272a")
		_:
			return Color("#1e293b")


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

	_add_cyl(g_root, 0.050, 0.054, 0.11, Vector3(0, 0.02, 0), mat_gold, Vector3.ZERO, 16, "Cuff")
	_add_cyl(g_root, 0.053, 0.055, 0.024, Vector3(0, 0.07, 0), mat_red, Vector3.ZERO, 16, "CuffTrim")
	_add_sphere(g_root, 0.080, Vector3(0, 0.14, 0), mat_blue, "GloveDome", Vector3(1.10, 1.22, 0.90))
	var k_roll := _add_capsule(g_root, 0.046, 0.135, Vector3(0, 0.18, 0.01), mat_blue, Vector3(0, 0, PI * 0.5), "KnuckleRoll")
	k_roll.scale = Vector3(0.88, 1.0, 1.05)
	_add_capsule(g_root, 0.034, 0.10, Vector3(side_s * 0.066, 0.12, 0.02), mat_navy, Vector3(0, 0, -side_s * 0.25), "Thumb")
	_add_cyl(g_root, 0.026, 0.026, 0.01, Vector3(0, 0.04, -0.045), mat_led, Vector3(PI * 0.5, 0, 0), 12, "Badge")


static func _create_bone_att(skel: Skeleton3D, att_name: String, bone_name: String) -> BoneAttachment3D:
	var att := BoneAttachment3D.new()
	att.name = att_name
	att.bone_name = bone_name
	skel.add_child(att)
	return att


static func create_legend_rig(legend_data: Dictionary, weapon_id: String = "r301") -> Node3D:
	_ensure_mocap_bank_loaded()
	var lid: String = str(legend_data.get("id", "wraith"))
	var is_female: bool = lid in FEMALE_LEGENDS
	var root := Node3D.new()
	root.name = "LegendRig_" + lid
	root.set_meta("legend_id", lid)
	root.set_meta("weapon_id", weapon_id)
	root.set_meta("anim_clip", "Pistol_Idle_Loop")
	root.set_meta("anim_time", 0.0)
	root.set_meta("legend_scale", _get_legend_body_scale(lid))

	var col_prim: Color = legend_data.get("primary_color", Color("#312e81"))
	var col_sec: Color = legend_data.get("secondary_color", Color("#38bdf8"))
	var col_visor: Color = legend_data.get("visor_color", Color("#a78bfa"))
	var col_under: Color = _get_legend_undersuit_color(lid)
	var h_info: Dictionary = legend_data.get("heirloom", {"color": Color("#38bdf8")})
	var h_col: Color = h_info.get("color", Color("#38bdf8"))

	var is_robot: bool = (lid == "pathfinder" or lid == "ash")
	var mat_prim := _make_mat(col_prim, 0.72 if is_robot else 0.45, 0.26 if is_robot else 0.42, false, Color.BLACK, 1.0, "gunmetal" if is_robot else "carbon_weave")
	var mat_sec := _make_mat(col_sec, 0.76, 0.24, false, Color.BLACK, 1.0, "gunmetal")
	var mat_under := _make_mat(col_under, 0.65 if is_robot else 0.25, 0.30 if is_robot else 0.62, false, Color.BLACK, 1.0, "polymer_grip")
	var mat_dark := _make_mat(Color("#0f172a"), 0.38, 0.52, false, Color.BLACK, 1.0, "polymer_grip")
	var mat_metal := _make_mat(Color("#cbd5e1"), 0.92, 0.16, false, Color.BLACK, 1.0, "gunmetal")
	var mat_visor := _make_mat(col_visor, 0.2, 0.1, true, col_visor, 3.4)
	var mat_glow := _make_mat(Color("#38bdf8"), 0.1, 0.1, true, Color("#38bdf8"), 4.0)
	var mat_plasma := _make_mat(h_col, 0.3, 0.1, true, h_col, 3.6)

	var wep_data: Dictionary = GameData.get_weapon_by_id(weapon_id if (weapon_id != "empty" and weapon_id != "") else "r301")

	var ual_model := _instantiate_character_model(is_female)
	if ual_model != null:
		ual_model.name = "UALCharacterModel"
		ual_model.rotation.y = PI
		ual_model.scale = _get_legend_body_scale(lid)
		root.add_child(ual_model)

		var skels := ual_model.find_children("*", "Skeleton3D", true, false)
		var skel: Skeleton3D = (skels[0] as Skeleton3D) if not skels.is_empty() else null
		var anim_players := ual_model.find_children("*", "AnimationPlayer", true, false)
		for ap_node in anim_players:
			var ap := ap_node as AnimationPlayer
			if ap != null:
				ap.stop()
				ap.active = false

		for child in ual_model.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi != null and mi.mesh != null:
				mi.set_surface_override_material(0, mat_prim)
				if mi.mesh.get_surface_count() > 1:
					mi.set_surface_override_material(1, mat_under)

		if skel != null:
			var bone_map: PackedInt32Array = _build_bone_map(skel)
			root.set_meta("bone_map", bone_map)
			# Immediately pose Skeleton3D in Pistol_Idle_Loop on creation so character is NEVER in T-Pose!
			_sample_mocap_clip_to_skeleton(skel, bone_map, "Pistol_Idle_Loop", 0.0, true)

			# -----------------------------------------------------------------
			# 1. HEAD BONE ATTACHMENT ("Head") — 12 Bespoke Helmets, Masks & Hair
			# -----------------------------------------------------------------
			var head_att := _create_bone_att(skel, "HeadBoneAttachment", "Head")
			var neck_pivot := Node3D.new()
			neck_pivot.name = "NeckPivot"
			neck_pivot.position = Vector3(0.0, 0.11, 0.01)
			head_att.add_child(neck_pivot)

			_add_Legend_headgear_gen5(neck_pivot, lid, mat_prim, mat_sec, mat_under, mat_dark, mat_metal, mat_visor, mat_glow, mat_plasma)

			# -----------------------------------------------------------------
			# 2. CHEST / BACK BONE ATTACHMENT ("spine_03") — Armor, Wings & Drones
			# -----------------------------------------------------------------
			var chest_att := _create_bone_att(skel, "ChestBoneAttachment", "spine_03")
			_add_Legend_chestgear_gen5(chest_att, lid, mat_prim, mat_sec, mat_under, mat_dark, mat_metal, mat_visor, mat_glow, mat_plasma)

			for side_s in [-1.0, 1.0]:
				var j_nozzle := _add_cyl(chest_att, 0.032, 0.044, 0.11, Vector3(side_s * 0.10, -0.14, -0.15), mat_metal, Vector3(0.35, 0, side_s * 0.18), 10)
				var j_flame := _add_cyl(j_nozzle, 0.028, 0.004, 0.22, Vector3(0, -0.15, 0), mat_glow, Vector3.ZERO, 8, "JumpkitJetL" if side_s < 0.0 else "JumpkitJetR")
				j_flame.visible = false

			# Unified 3D Back Holster Root
			var back_holster := Node3D.new()
			back_holster.name = "BackHolsterRoot"
			back_holster.position = Vector3(0.02, 0.06, -0.17)
			back_holster.rotation = Vector3(0.0, PI * 0.5, 0.68)
			back_holster.scale = Vector3(0.76, 0.76, 0.76)
			back_holster.visible = false
			chest_att.add_child(back_holster)
			var holstered_wep := WeaponMeshBuilder.create_third_person_weapon_mesh(wep_data)
			back_holster.add_child(holstered_wep)

			# -----------------------------------------------------------------
			# 3. PELVIS / WAIST BONE ATTACHMENT ("pelvis") — Coats, Kilts & Belts
			# -----------------------------------------------------------------
			var pelvis_att := _create_bone_att(skel, "PelvisBoneAttachment", "pelvis")
			_add_Legend_pelvis_gear_gen5(pelvis_att, lid, mat_prim, mat_sec, mat_under, mat_dark, mat_metal, mat_glow, mat_plasma)

			# -----------------------------------------------------------------
			# 4. SHOULDER / UPPER-ARM BONE ATTACHMENTS ("upperarm_l", "upperarm_r")
			# -----------------------------------------------------------------
			var uarm_l := _create_bone_att(skel, "LeftUpperArmAttachment", "upperarm_l")
			var uarm_r := _create_bone_att(skel, "RightUpperArmAttachment", "upperarm_r")
			_add_Legend_upperarm_gear_gen5(uarm_l, uarm_r, lid, mat_prim, mat_sec, mat_under, mat_dark, mat_metal, mat_glow, mat_plasma)

			# -----------------------------------------------------------------
			# 5. FOREARM BONE ATTACHMENTS ("lowerarm_l", "lowerarm_r") — Visible in 1P & 3P!
			# -----------------------------------------------------------------
			var larm_l := _create_bone_att(skel, "LeftLowerArmAttachment", "lowerarm_l")
			var larm_r := _create_bone_att(skel, "RightLowerArmAttachment", "lowerarm_r")
			_add_Legend_forearm_gear_gen5(larm_l, larm_r, lid, mat_prim, mat_sec, mat_under, mat_dark, mat_metal, mat_glow, mat_plasma)

			# -----------------------------------------------------------------
			# 6. THIGH & CALF BONE ATTACHMENTS ("thigh_l/r", "calf_l/r") — Boots, Cargo Pants & Prosthetics
			# -----------------------------------------------------------------
			var thigh_l := _create_bone_att(skel, "LeftThighAttachment", "thigh_l")
			var thigh_r := _create_bone_att(skel, "RightThighAttachment", "thigh_r")
			var calf_l := _create_bone_att(skel, "LeftCalfAttachment", "calf_l")
			var calf_r := _create_bone_att(skel, "RightCalfAttachment", "calf_r")
			_add_Legend_leg_gear_gen5(thigh_l, thigh_r, calf_l, calf_r, lid, mat_prim, mat_sec, mat_under, mat_dark, mat_metal, mat_glow, mat_plasma)

			# -----------------------------------------------------------------
			# 7. RIGHT & LEFT HAND BONE ATTACHMENTS ("hand_r", "hand_l") — Weapons & Heirlooms
			# -----------------------------------------------------------------
			var rhand_att := _create_bone_att(skel, "RightHandBoneAttachment", "hand_r")
			var held_wep_root := Node3D.new()
			held_wep_root.name = "HeldWeaponRoot"
			held_wep_root.position = Vector3(0.0, 0.08, 0.02)
			held_wep_root.rotation = Vector3(PI * 0.5, 0.0, 0.0)
			held_wep_root.scale = Vector3(0.84, 0.84, 0.84)
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

			var lhand_att := _create_bone_att(skel, "LeftHandBoneAttachment", "hand_l")
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
			_add_cyl(heal_prop, 0.052, 0.052, 0.18, Vector3.ZERO, mat_dark, Vector3.ZERO, 12, "TP_BatteryBody")
			_add_cyl(heal_prop, 0.045, 0.045, 0.11, Vector3.ZERO, mat_glow, Vector3.ZERO, 12, "TP_BatteryCore")

	return root


static func _add_Legend_headgear_gen5(neck_pivot: Node3D, lid: String, mat_prim: Material, mat_sec: Material, mat_under: Material, mat_dark: Material, mat_metal: Material, mat_visor: Material, mat_glow: Material, mat_plasma: Material) -> void:
	match lid:
		"bloodhound":
			# Wide-Brim Nordic Tracker Helmet + Red Samurai Crest + Plague Respirator Beak + Glowing Red Eyes
			_add_cyl(neck_pivot, 0.11, 0.19, 0.055, Vector3(0, 0.085, 0.0), mat_prim, Vector3.ZERO, 16, "BH_Brim")
			_add_sphere(neck_pivot, 0.11, Vector3(0, 0.10, 0.0), mat_dark, "BH_Dome", Vector3(1.05, 0.85, 1.08))
			_add_box(neck_pivot, Vector3(0.28, 0.038, 0.04), Vector3(0, 0.135, 0.03), mat_sec, Vector3.ZERO, "BH_HornBar")
			_add_box(neck_pivot, Vector3(0.035, 0.09, 0.03), Vector3(-0.13, 0.16, 0.03), mat_sec, Vector3(0, 0, 0.35))
			_add_box(neck_pivot, Vector3(0.035, 0.09, 0.03), Vector3(0.13, 0.16, 0.03), mat_sec, Vector3(0, 0, -0.35))
			_add_cyl(neck_pivot, 0.022, 0.068, 0.13, Vector3(0, -0.015, 0.135), mat_dark, Vector3(PI * 0.52, 0, 0), 10, "PlagueBeak")
			_add_box(neck_pivot, Vector3(0.13, 0.032, 0.04), Vector3(0, 0.03, 0.105), mat_visor)
		"pathfinder":
			# Iconic Blue MRVN Cyclops Camera Head (Completely encapsulates human head!)
			_add_box(neck_pivot, Vector3(0.20, 0.21, 0.23), Vector3(0, 0.025, 0.015), mat_prim, Vector3.ZERO, "MRVNHeadChassis")
			_add_box(neck_pivot, Vector3(0.16, 0.17, 0.24), Vector3(0, 0.025, 0.015), mat_sec)
			_add_cyl(neck_pivot, 0.068, 0.068, 0.05, Vector3(0, 0.025, 0.125), mat_dark, Vector3(PI * 0.5, 0, 0), 18, "MRVNEyeRing")
			_add_cyl(neck_pivot, 0.054, 0.054, 0.055, Vector3(0, 0.025, 0.128), mat_visor, Vector3(PI * 0.5, 0, 0), 18, "MRVNEyeLens")
			_add_cyl(neck_pivot, 0.010, 0.014, 0.13, Vector3(0.11, 0.12, 0.0), mat_metal, Vector3(0, 0, -0.25), 8)
			_add_cyl(neck_pivot, 0.010, 0.014, 0.13, Vector3(-0.11, 0.12, 0.0), mat_metal, Vector3(0, 0, 0.25), 8)
		"wraith":
			# Thick Coiled Dark-Indigo Void Scarf + Swept Ninja Hair Bun + Glowing Violet Void Eyes
			_add_cyl(neck_pivot, 0.135, 0.155, 0.10, Vector3(0, -0.065, 0.015), mat_dark, Vector3.ZERO, 16, "VoidScarf")
			_add_sphere(neck_pivot, 0.108, Vector3(0, 0.055, -0.015), mat_dark, "WraithHairCap", Vector3(1.02, 1.0, 1.08))
			_add_sphere(neck_pivot, 0.068, Vector3(0, 0.105, -0.105), mat_dark, "WraithHairBun")
			_add_box(neck_pivot, Vector3(0.16, 0.04, 0.04), Vector3(0, 0.05, 0.095), mat_dark, Vector3(0, 0, -0.18), "WraithBangs")
			_add_box(neck_pivot, Vector3(0.12, 0.026, 0.03), Vector3(0, 0.022, 0.105), mat_visor, Vector3.ZERO, "VoidEyes")
		"octane":
			# Dual Round Neon-Green Bug-Eye Goggles + Spiked respirator mask + Head Hood
			_add_sphere(neck_pivot, 0.108, Vector3(0, 0.04, -0.005), mat_dark, "OctaneHood", Vector3(1.02, 1.04, 1.05))
			_add_cyl(neck_pivot, 0.048, 0.048, 0.045, Vector3(-0.048, 0.035, 0.105), mat_sec, Vector3(PI * 0.5, 0, 0), 14, "GoggleL")
			_add_cyl(neck_pivot, 0.048, 0.048, 0.045, Vector3(0.048, 0.035, 0.105), mat_sec, Vector3(PI * 0.5, 0, 0), 14, "GoggleR")
			_add_cyl(neck_pivot, 0.038, 0.038, 0.050, Vector3(-0.048, 0.035, 0.107), mat_visor, Vector3(PI * 0.5, 0, 0), 14)
			_add_cyl(neck_pivot, 0.038, 0.038, 0.050, Vector3(0.048, 0.035, 0.107), mat_visor, Vector3(PI * 0.5, 0, 0), 14)
			_add_box(neck_pivot, Vector3(0.135, 0.070, 0.08), Vector3(0, -0.032, 0.095), mat_dark, Vector3.ZERO, "RespiratorMask")
			_add_box(neck_pivot, Vector3(0.10, 0.022, 0.02), Vector3(0, -0.032, 0.138), mat_visor, Vector3.ZERO, "MaskTeeth")
		"lifeline":
			# White/Teal Rescue Headband + Signature Twin Large Crimson-Pink Hair Puffs
			_add_cyl(neck_pivot, 0.112, 0.112, 0.038, Vector3(0, 0.065, 0.005), mat_sec, Vector3.ZERO, 16, "MedicHeadband")
			_add_sphere(neck_pivot, 0.078, Vector3(-0.128, 0.085, -0.02), mat_prim, "LeftBun", Vector3(1.0, 1.08, 1.0))
			_add_sphere(neck_pivot, 0.078, Vector3(0.128, 0.085, -0.02), mat_prim, "RightBun", Vector3(1.0, 1.08, 1.0))
			_add_box(neck_pivot, Vector3(0.125, 0.028, 0.03), Vector3(0, 0.022, 0.102), mat_visor)
		"gibraltar":
			# Massive Juggernaut Ballistic Helmet + Tribal White/Orange Crest + Thick Armored Collar
			_add_cyl(neck_pivot, 0.16, 0.19, 0.09, Vector3(0, -0.065, 0.0), mat_prim, Vector3.ZERO, 16, "GibbyCollar")
			_add_sphere(neck_pivot, 0.132, Vector3(0, 0.05, 0.0), mat_prim, "GibbyHelm", Vector3(1.12, 1.02, 1.15))
			_add_box(neck_pivot, Vector3(0.055, 0.075, 0.23), Vector3(0, 0.125, 0.0), mat_sec, Vector3.ZERO, "GibbyCrest")
			_add_box(neck_pivot, Vector3(0.15, 0.036, 0.05), Vector3(0, 0.025, 0.112), mat_visor)
		"valkyrie":
			# Enclosed Northstar Viper Flight Helmet + Swept Side Wings + Full Cyan Visor Dome
			_add_sphere(neck_pivot, 0.128, Vector3(0, 0.035, 0.01), mat_prim, "ViperHelm", Vector3(1.06, 1.06, 1.18))
			_add_sphere(neck_pivot, 0.112, Vector3(0, 0.025, 0.045), mat_visor, "ViperVisorDome", Vector3(0.96, 0.78, 1.0))
			_add_box(neck_pivot, Vector3(0.022, 0.085, 0.18), Vector3(-0.118, 0.065, -0.04), mat_sec, Vector3(0.28, -0.22, 0))
			_add_box(neck_pivot, Vector3(0.022, 0.085, 0.18), Vector3(0.118, 0.065, -0.04), mat_sec, Vector3(0.28, 0.22, 0))
		"ash":
			# White Porcelain Simulacrum Faceplate + Dark Draped Ronin Hood with Gold/Cyan Trim
			_add_sphere(neck_pivot, 0.138, Vector3(0, 0.035, -0.015), mat_prim, "AshHood", Vector3(1.10, 1.16, 1.18))
			_add_cyl(neck_pivot, 0.13, 0.16, 0.09, Vector3(0, -0.06, -0.01), mat_prim, Vector3.ZERO, 14, "AshCowl")
			_add_box(neck_pivot, Vector3(0.135, 0.165, 0.045), Vector3(0, 0.022, 0.092), mat_under, Vector3.ZERO, "PorcelainMask")
			_add_box(neck_pivot, Vector3(0.115, 0.024, 0.05), Vector3(0, 0.032, 0.102), mat_visor, Vector3.ZERO, "AshEyes")
		"caustic":
			# Slicked Hair + Dual-Filter Yellow/Green Nox Gas Mask + Glowing Green Goggles
			_add_sphere(neck_pivot, 0.112, Vector3(0, 0.06, -0.01), mat_dark, "CausticHair", Vector3(1.02, 0.95, 1.08))
			_add_box(neck_pivot, Vector3(0.135, 0.075, 0.085), Vector3(0, -0.03, 0.09), mat_dark, Vector3.ZERO, "GasMaskBody")
			_add_cyl(neck_pivot, 0.042, 0.046, 0.065, Vector3(-0.062, -0.035, 0.12), mat_sec, Vector3(PI * 0.4, -0.42, 0), 12, "NoxFilterL")
			_add_cyl(neck_pivot, 0.042, 0.046, 0.065, Vector3(0.062, -0.035, 0.12), mat_sec, Vector3(PI * 0.4, 0.42, 0), 12, "NoxFilterR")
			_add_box(neck_pivot, Vector3(0.135, 0.034, 0.045), Vector3(0, 0.028, 0.105), mat_visor)
		"horizon":
			# Swept Orange/Red Gravity Hair Crest + White EVA Space-Helmet Collar Ring + Blue Visor
			_add_cyl(neck_pivot, 0.145, 0.16, 0.055, Vector3(0, -0.065, 0.0), mat_under, Vector3.ZERO, 16, "SpaceCollar")
			_add_sphere(neck_pivot, 0.112, Vector3(0, 0.065, 0.0), mat_sec, "HorizonHair", Vector3(1.02, 1.08, 1.06))
			_add_box(neck_pivot, Vector3(0.065, 0.095, 0.15), Vector3(0, 0.125, 0.03), mat_sec, Vector3(-0.25, 0, 0), "HairPompadour")
			_add_box(neck_pivot, Vector3(0.135, 0.034, 0.045), Vector3(0, 0.025, 0.105), mat_visor)
		"mirage":
			# Yellow Bandana + Dark Curls + Uplifted Glowing Gold Holo-Goggles on Forehead
			_add_cyl(neck_pivot, 0.114, 0.114, 0.036, Vector3(0, 0.06, 0.005), mat_prim, Vector3.ZERO, 16, "MirageBandana")
			_add_sphere(neck_pivot, 0.108, Vector3(0, 0.09, -0.01), mat_dark, "MirageCurls", Vector3(1.04, 0.88, 1.04))
			_add_cyl(neck_pivot, 0.042, 0.042, 0.04, Vector3(-0.046, 0.075, 0.105), mat_plasma, Vector3(PI * 0.5, 0, 0), 12)
			_add_cyl(neck_pivot, 0.042, 0.042, 0.04, Vector3(0.046, 0.075, 0.105), mat_plasma, Vector3(PI * 0.5, 0, 0), 12)
			_add_box(neck_pivot, Vector3(0.13, 0.030, 0.04), Vector3(0, 0.02, 0.102), mat_visor)
		_:
			# Bangalore High-Top Military Frohawk Curls + IMC Tactical Earpiece & Amber Visor
			_add_box(neck_pivot, Vector3(0.095, 0.095, 0.18), Vector3(0, 0.115, 0.01), mat_dark, Vector3(-0.1, 0, 0), "BangaloreHair")
			_add_cyl(neck_pivot, 0.044, 0.044, 0.032, Vector3(-0.11, 0.02, 0.0), mat_sec, Vector3(0, 0, PI * 0.5), 10)
			_add_cyl(neck_pivot, 0.044, 0.044, 0.032, Vector3(0.11, 0.02, 0.0), mat_sec, Vector3(0, 0, PI * 0.5), 10)
			_add_box(neck_pivot, Vector3(0.135, 0.034, 0.045), Vector3(0, 0.025, 0.105), mat_visor)


static func _add_Legend_chestgear_gen5(chest_att: Node3D, lid: String, mat_prim: Material, mat_sec: Material, mat_under: Material, mat_dark: Material, mat_metal: Material, _mat_visor: Material, mat_glow: Material, mat_plasma: Material) -> void:
	match lid:
		"pathfinder":
			# Heavy Robot Chest Chassis + Glowing Cyan LCD Smiley Screen + Twin Shoulder Zipline Winches
			_add_box(chest_att, Vector3(0.31, 0.28, 0.16), Vector3(0, 0.02, 0.02), mat_prim, Vector3.ZERO, "RobotTorsoBox")
			_add_box(chest_att, Vector3(0.19, 0.15, 0.03), Vector3(0, 0.03, 0.115), mat_dark)
			_add_box(chest_att, Vector3(0.16, 0.12, 0.035), Vector3(0, 0.03, 0.120), mat_glow, Vector3.ZERO, "PathfinderChestScreen")
			_add_cyl(chest_att, 0.065, 0.065, 0.09, Vector3(-0.19, 0.15, -0.06), mat_metal, Vector3(0, 0, PI * 0.5), 14, "ZipSpoolL")
			_add_cyl(chest_att, 0.065, 0.065, 0.09, Vector3(0.19, 0.15, -0.06), mat_metal, Vector3(0, 0, PI * 0.5), 14, "ZipSpoolR")
		"valkyrie":
			# Flight Harness + Huge Swept Northstar VTOL Jetpack Wings & Twin Shoulder Missile Pods
			_add_box(chest_att, Vector3(0.27, 0.22, 0.08), Vector3(0, 0.03, 0.09), mat_prim, Vector3.ZERO, "ValkFlightVest")
			_add_box(chest_att, Vector3(0.24, 0.30, 0.13), Vector3(0, 0.04, -0.14), mat_dark, Vector3.ZERO, "VTOLPack")
			# Twin Swept Main Wings
			_add_box(chest_att, Vector3(0.56, 0.11, 0.032), Vector3(-0.36, 0.16, -0.17), mat_prim, Vector3(0, -0.22, 0.38), "ValkWingL")
			_add_box(chest_att, Vector3(0.56, 0.11, 0.032), Vector3(0.36, 0.16, -0.17), mat_prim, Vector3(0, 0.22, -0.38), "ValkWingR")
			# Secondary Lower Aero Fins
			_add_box(chest_att, Vector3(0.38, 0.075, 0.025), Vector3(-0.26, -0.02, -0.16), mat_sec, Vector3(0, -0.15, -0.28), "ValkSubWingL")
			_add_box(chest_att, Vector3(0.38, 0.075, 0.025), Vector3(0.26, -0.02, -0.16), mat_sec, Vector3(0, 0.15, 0.28), "ValkSubWingR")
			# Shoulder Missile Pods
			_add_box(chest_att, Vector3(0.11, 0.12, 0.16), Vector3(-0.18, 0.22, -0.10), mat_sec, Vector3(-0.2, 0, 0), "MissilePodL")
			_add_box(chest_att, Vector3(0.11, 0.12, 0.16), Vector3(0.18, 0.22, -0.10), mat_sec, Vector3(-0.2, 0, 0), "MissilePodR")
		"gibraltar":
			# Massive Layered Bomb-Suit Juggernaut Cuirass + Giant Glowing Back Protection Dome Shield Disc
			_add_box(chest_att, Vector3(0.36, 0.30, 0.14), Vector3(0, 0.02, 0.07), mat_prim, Vector3.ZERO, "GibbyCuirass")
			_add_box(chest_att, Vector3(0.26, 0.22, 0.06), Vector3(0, 0.03, 0.135), mat_sec, Vector3.ZERO, "GibbyFrontPlate")
			_add_cyl(chest_att, 0.23, 0.23, 0.07, Vector3(0, 0.05, -0.15), mat_sec, Vector3(PI * 0.5, 0, 0), 18, "GibbyBackDome")
			_add_cyl(chest_att, 0.16, 0.16, 0.08, Vector3(0, 0.05, -0.155), mat_glow, Vector3(PI * 0.5, 0, 0), 16, "GibbyBackCore")
		"caustic":
			# Bright Yellow Hazmat Chest Apron + Three Pressurized Nox Gas Cylinders on Back
			_add_box(chest_att, Vector3(0.32, 0.28, 0.11), Vector3(0, 0.01, 0.07), mat_sec, Vector3.ZERO, "CausticHazmatChest")
			_add_cyl(chest_att, 0.045, 0.045, 0.06, Vector3(-0.09, 0.08, 0.13), mat_dark, Vector3(PI * 0.5, 0, 0), 10)
			_add_cyl(chest_att, 0.045, 0.045, 0.06, Vector3(0.09, 0.08, 0.13), mat_dark, Vector3(PI * 0.5, 0, 0), 10)
			_add_cyl(chest_att, 0.058, 0.058, 0.34, Vector3(-0.10, 0.03, -0.15), mat_sec, Vector3.ZERO, 14, "NoxTankL")
			_add_cyl(chest_att, 0.058, 0.058, 0.34, Vector3(0.10, 0.03, -0.15), mat_sec, Vector3.ZERO, 14, "NoxTankR")
			_add_cyl(chest_att, 0.045, 0.045, 0.28, Vector3(0.0, 0.05, -0.19), mat_plasma, Vector3.ZERO, 12, "NoxTankCenter")
		"lifeline":
			# White/Magenta Combat Medic Rescue Vest + Docked D.O.C. Healing Drone on Back
			_add_box(chest_att, Vector3(0.27, 0.22, 0.09), Vector3(0, 0.03, 0.07), mat_under, Vector3.ZERO, "MedicVest")
			_add_box(chest_att, Vector3(0.09, 0.09, 0.02), Vector3(0, 0.05, 0.12), mat_prim, Vector3.ZERO, "MedicCross")
			_add_cyl(chest_att, 0.15, 0.15, 0.06, Vector3(0, 0.05, -0.14), mat_metal, Vector3(PI * 0.5, 0, 0), 16, "DOCDroneBody")
			_add_sphere(chest_att, 0.065, Vector3(0, 0.05, -0.175), mat_plasma, "DOCDroneCore")
		"octane":
			# Cropped Green Stunt Vest + Twin Glowing Neon-Green Stim Dialysis Cylinders on Back
			_add_box(chest_att, Vector3(0.26, 0.21, 0.08), Vector3(0, 0.04, 0.065), mat_prim, Vector3.ZERO, "StuntVest")
			_add_cyl(chest_att, 0.044, 0.044, 0.26, Vector3(-0.085, 0.03, -0.14), mat_plasma, Vector3(0, 0, 0.18), 12, "StimTankL")
			_add_cyl(chest_att, 0.044, 0.044, 0.26, Vector3(0.085, 0.03, -0.14), mat_plasma, Vector3(0, 0, -0.18), 12, "StimTankR")
		"bloodhound":
			# Layered Bronze Hunter Mantle + Fur Collar + Sonar Radar Pack on Back
			_add_box(chest_att, Vector3(0.31, 0.26, 0.11), Vector3(0, 0.02, 0.065), mat_prim, Vector3.ZERO, "HunterCuirass")
			_add_cyl(chest_att, 0.16, 0.19, 0.08, Vector3(0, 0.14, 0.0), mat_dark, Vector3.ZERO, 14, "FurCollar")
			_add_box(chest_att, Vector3(0.22, 0.26, 0.10), Vector3(0, 0.03, -0.14), mat_dark, Vector3.ZERO, "SonarPack")
			_add_cyl(chest_att, 0.012, 0.012, 0.28, Vector3(-0.09, 0.22, -0.15), mat_metal, Vector3.ZERO, 8, "SonarAntenna")
		"bangalore":
			# Heavy IMC Ballistic Flak Vest with Triple Mag Pouches + Shoulder-Mounted Smoke Launcher!
			_add_box(chest_att, Vector3(0.29, 0.26, 0.11), Vector3(0, 0.02, 0.07), mat_prim, Vector3.ZERO, "IMCFlakVest")
			for m_i in [-1, 0, 1]:
				_add_box(chest_att, Vector3(0.055, 0.09, 0.04), Vector3(float(m_i) * 0.075, -0.02, 0.135), mat_sec)
			# Iconic Over-the-Shoulder 3-Barrel Smoke Launcher on Left Back/Shoulder
			_add_box(chest_att, Vector3(0.11, 0.24, 0.12), Vector3(0.13, 0.16, -0.13), mat_dark, Vector3(0.45, 0, -0.15), "SmokeLauncher")
			_add_cyl(chest_att, 0.028, 0.028, 0.16, Vector3(0.13, 0.25, -0.07), mat_metal, Vector3(0.45, 0, -0.15), 10)
		"ash":
			# Sleek Cybernetic Corset + Diagonal Phase-Breach Katana Scabbard on Back
			_add_box(chest_att, Vector3(0.25, 0.24, 0.09), Vector3(0, 0.02, 0.06), mat_prim, Vector3.ZERO, "AshChestPlate")
			_add_box(chest_att, Vector3(0.08, 0.18, 0.02), Vector3(0, 0.03, 0.11), mat_sec, Vector3.ZERO, "AshRibCore")
			_add_box(chest_att, Vector3(0.04, 0.72, 0.055), Vector3(0.0, 0.06, -0.15), mat_dark, Vector3(0, 0, 0.58), "AshSwordSheath")
			_add_box(chest_att, Vector3(0.045, 0.70, 0.02), Vector3(0.0, 0.06, -0.175), mat_sec, Vector3(0, 0, 0.58))
		"horizon":
			# White/Blue EVA Astronaut Chest + N.E.W.T. Black-Hole Singularity Backpack
			_add_box(chest_att, Vector3(0.28, 0.25, 0.10), Vector3(0, 0.02, 0.065), mat_under, Vector3.ZERO, "EVAChest")
			_add_box(chest_att, Vector3(0.14, 0.12, 0.03), Vector3(0, 0.04, 0.12), mat_prim, Vector3.ZERO, "EVAConsole")
			_add_cyl(chest_att, 0.14, 0.14, 0.09, Vector3(0, 0.05, -0.15), mat_under, Vector3(PI * 0.5, 0, 0), 16, "NewtPack")
			_add_cyl(chest_att, 0.095, 0.095, 0.10, Vector3(0, 0.05, -0.16), mat_glow, Vector3(PI * 0.5, 0, 0), 16, "NewtSingularity")
		"wraith":
			# Voidrunner Cropped Jacket + Diagonal Silver Cross-Strap + Glowing Violet Phase Reactor
			_add_box(chest_att, Vector3(0.26, 0.22, 0.09), Vector3(0, 0.03, 0.06), mat_prim, Vector3.ZERO, "VoidJacket")
			_add_box(chest_att, Vector3(0.055, 0.28, 0.11), Vector3(0, 0.02, 0.065), mat_metal, Vector3(0, 0, 0.52), "CrossBelt")
			_add_cyl(chest_att, 0.085, 0.085, 0.07, Vector3(0, 0.04, -0.13), mat_plasma, Vector3(PI * 0.5, 0, 0), 14, "PhaseReactor")
		"mirage":
			# Quilted Gold/Dark Stunt Jacket + Glowing Cyan Holo-Emitter Discs on Chest & Back
			_add_box(chest_att, Vector3(0.29, 0.25, 0.10), Vector3(0, 0.02, 0.065), mat_prim, Vector3.ZERO, "MirageJacket")
			_add_cyl(chest_att, 0.042, 0.042, 0.025, Vector3(-0.085, 0.06, 0.12), mat_glow, Vector3(PI * 0.5, 0, 0), 12)
			_add_cyl(chest_att, 0.042, 0.042, 0.025, Vector3(0.085, 0.06, 0.12), mat_glow, Vector3(PI * 0.5, 0, 0), 12)
			_add_box(chest_att, Vector3(0.20, 0.24, 0.08), Vector3(0, 0.03, -0.13), mat_dark, Vector3.ZERO, "HoloPack")


static func _add_Legend_pelvis_gear_gen5(pelvis_att: Node3D, lid: String, mat_prim: Material, mat_sec: Material, _mat_under: Material, mat_dark: Material, mat_metal: Material, mat_glow: Material, mat_plasma: Material) -> void:
	# Tactical Utility Belt at Waist (y = 0.02)
	_add_box(pelvis_att, Vector3(0.29, 0.065, 0.22), Vector3(0, 0.01, 0.0), mat_dark, Vector3.ZERO, "WaistBelt")
	_add_box(pelvis_att, Vector3(0.07, 0.075, 0.03), Vector3(0, 0.01, 0.115), mat_metal, Vector3.ZERO, "BeltBuckle")

	match lid:
		"bloodhound":
			# Long Split Hunter Tunic Coat-Tails / Kama Skirt hanging down (-Y) around hips!
			_add_box(pelvis_att, Vector3(0.32, 0.28, 0.04), Vector3(0, -0.14, -0.11), mat_prim, Vector3(-0.12, 0, 0), "HunterBackCoat")
			_add_box(pelvis_att, Vector3(0.04, 0.26, 0.22), Vector3(-0.155, -0.13, 0.0), mat_prim, Vector3(0, 0, -0.12), "HunterSideCoatR")
			_add_box(pelvis_att, Vector3(0.04, 0.26, 0.22), Vector3(0.155, -0.13, 0.0), mat_prim, Vector3(0, 0, 0.12), "HunterSideCoatL")
		"bangalore":
			# Pleated Crimson/Amber Tactical Battle-Skirt around Hips & Upper Thighs!
			_add_box(pelvis_att, Vector3(0.33, 0.27, 0.045), Vector3(0, -0.14, -0.11), mat_prim, Vector3(-0.10, 0, 0), "BattleSkirtBack")
			_add_box(pelvis_att, Vector3(0.045, 0.26, 0.23), Vector3(-0.16, -0.13, 0.0), mat_prim, Vector3(0, 0, -0.10), "BattleSkirtR")
			_add_box(pelvis_att, Vector3(0.045, 0.26, 0.23), Vector3(0.16, -0.13, 0.0), mat_prim, Vector3(0, 0, 0.10), "BattleSkirtL")
			_add_box(pelvis_att, Vector3(0.14, 0.22, 0.035), Vector3(0, -0.12, 0.115), mat_sec, Vector3(0.08, 0, 0), "BattleSkirtFront")
		"ash":
			# Long Flowing Dark/Cyan Ronin Kama Split Coat-Tails
			_add_box(pelvis_att, Vector3(0.13, 0.34, 0.035), Vector3(-0.085, -0.17, -0.11), mat_prim, Vector3(-0.14, 0, -0.08), "AshTailR")
			_add_box(pelvis_att, Vector3(0.13, 0.34, 0.035), Vector3(0.085, -0.17, -0.11), mat_prim, Vector3(-0.14, 0, 0.08), "AshTailL")
			_add_box(pelvis_att, Vector3(0.035, 0.28, 0.20), Vector3(-0.15, -0.14, 0.0), mat_sec, Vector3(0, 0, -0.12))
			_add_box(pelvis_att, Vector3(0.035, 0.28, 0.20), Vector3(0.15, -0.14, 0.0), mat_sec, Vector3(0, 0, 0.12))
		"caustic":
			# Heavy Yellow Rubberized Hazmat Lab Apron Draping Front & Back
			_add_box(pelvis_att, Vector3(0.28, 0.26, 0.04), Vector3(0, -0.13, 0.115), mat_sec, Vector3(0.10, 0, 0), "HazmatFrontApron")
			_add_box(pelvis_att, Vector3(0.32, 0.28, 0.04), Vector3(0, -0.14, -0.115), mat_sec, Vector3(-0.10, 0, 0), "HazmatBackApron")
		"gibraltar":
			# Heavy Juggernaut Armored Hip & Groin Ballistic Tassets
			_add_box(pelvis_att, Vector3(0.20, 0.22, 0.06), Vector3(0, -0.11, 0.125), mat_prim, Vector3(0.08, 0, 0), "GibbyGroinPlate")
			_add_box(pelvis_att, Vector3(0.06, 0.22, 0.24), Vector3(-0.175, -0.10, 0.0), mat_sec, Vector3(0, 0, -0.15), "GibbyTassetR")
			_add_box(pelvis_att, Vector3(0.06, 0.22, 0.24), Vector3(0.175, -0.10, 0.0), mat_sec, Vector3(0, 0, 0.15), "GibbyTassetL")
		"wraith":
			# Asymmetric Flowing Ninja Sash + Kunai Holster Pouch
			_add_box(pelvis_att, Vector3(0.04, 0.26, 0.18), Vector3(0.15, -0.12, -0.02), mat_prim, Vector3(0, 0, 0.16), "WraithSash")
			_add_box(pelvis_att, Vector3(0.06, 0.12, 0.08), Vector3(-0.155, -0.04, 0.04), mat_plasma, Vector3(0, 0, -0.2), "KunaiPouch")
		"octane":
			# Compact Green Jump-Pad Disc Holstered on Rear Waist
			_add_cyl(pelvis_att, 0.11, 0.11, 0.04, Vector3(0, 0.0, -0.125), mat_plasma, Vector3(PI * 0.5, 0, 0), 14, "WaistJumpPad")
		"horizon":
			# Padded White EVA Space-Suit Hip Ring + Gravity Lift Discs
			_add_cyl(pelvis_att, 0.165, 0.175, 0.08, Vector3(0, 0.0, 0.0), mat_sec, Vector3.ZERO, 16, "EVAWaistRing")
			_add_cyl(pelvis_att, 0.055, 0.055, 0.03, Vector3(-0.16, -0.02, 0.04), mat_glow, Vector3(0, 0, PI * 0.5), 12)


static func _add_Legend_upperarm_gear_gen5(uarm_l: Node3D, uarm_r: Node3D, lid: String, mat_prim: Material, mat_sec: Material, mat_under: Material, mat_dark: Material, mat_metal: Material, mat_glow: Material, mat_plasma: Material) -> void:
	# Note: in upperarm_l/r local space, +Y runs from shoulder (y=0.0) to elbow (y=0.26)
	match lid:
		"gibraltar":
			# Huge Rounded Juggernaut Bomb-Suit Shoulder Pauldrons
			_add_sphere(uarm_l, 0.115, Vector3(0.03, 0.05, 0.0), mat_prim, "GibbyPauldronL", Vector3(1.15, 1.25, 1.15))
			_add_sphere(uarm_r, 0.115, Vector3(-0.03, 0.05, 0.0), mat_prim, "GibbyPauldronR", Vector3(1.15, 1.25, 1.15))
			_add_box(uarm_l, Vector3(0.04, 0.16, 0.14), Vector3(0.09, 0.07, 0.0), mat_sec)
			_add_box(uarm_r, Vector3(0.04, 0.16, 0.14), Vector3(-0.09, 0.07, 0.0), mat_sec)
		"bloodhound":
			# Layered Samurai-Style Bronze Shoulder Armor Plates
			_add_box(uarm_l, Vector3(0.14, 0.16, 0.15), Vector3(0.03, 0.06, 0.0), mat_prim, Vector3(0, 0, -0.22), "BHPauldronL")
			_add_box(uarm_r, Vector3(0.14, 0.16, 0.15), Vector3(-0.03, 0.06, 0.0), mat_prim, Vector3(0, 0, 0.22), "BHPauldronR")
			_add_box(uarm_l, Vector3(0.15, 0.04, 0.16), Vector3(0.04, 0.12, 0.0), mat_sec)
			_add_box(uarm_r, Vector3(0.15, 0.04, 0.16), Vector3(-0.04, 0.12, 0.0), mat_sec)
		"pathfinder":
			# Cylindrical Mechanical Robot Upper-Arm Struts & Shoulder Ball-Joints
			_add_sphere(uarm_l, 0.078, Vector3(0, 0.02, 0), mat_sec, "RobotShoulderL")
			_add_sphere(uarm_r, 0.078, Vector3(0, 0.02, 0), mat_sec, "RobotShoulderR")
			_add_cyl(uarm_l, 0.058, 0.052, 0.22, Vector3(0, 0.13, 0), mat_prim, Vector3.ZERO, 12, "RobotUpperArmL")
			_add_cyl(uarm_r, 0.058, 0.052, 0.22, Vector3(0, 0.13, 0), mat_prim, Vector3.ZERO, 12, "RobotUpperArmR")
		"mirage":
			# Padded Stunt Sleeves + Signature Glowing Cyan Circular Holo-Emitter Discs!
			_add_cyl(uarm_l, 0.068, 0.060, 0.18, Vector3(0, 0.11, 0), mat_prim, Vector3.ZERO, 14)
			_add_cyl(uarm_r, 0.068, 0.060, 0.18, Vector3(0, 0.11, 0), mat_prim, Vector3.ZERO, 14)
			_add_cyl(uarm_l, 0.042, 0.042, 0.03, Vector3(0.065, 0.08, 0.0), mat_glow, Vector3(0, 0, PI * 0.5), 14, "HoloDiscShoulderL")
			_add_cyl(uarm_r, 0.042, 0.042, 0.03, Vector3(-0.065, 0.08, 0.0), mat_glow, Vector3(0, 0, PI * 0.5), 14, "HoloDiscShoulderR")
		"horizon":
			# Padded White/Orange EVA Astronaut Spacesuit Shoulder Spheres
			_add_sphere(uarm_l, 0.088, Vector3(0.02, 0.06, 0), mat_under, "EVAShoulderL", Vector3(1.1, 1.2, 1.1))
			_add_sphere(uarm_r, 0.088, Vector3(-0.02, 0.06, 0), mat_under, "EVAShoulderR", Vector3(1.1, 1.2, 1.1))
			_add_cyl(uarm_l, 0.066, 0.066, 0.035, Vector3(0, 0.14, 0), mat_sec, Vector3.ZERO, 14)
			_add_cyl(uarm_r, 0.066, 0.066, 0.035, Vector3(0, 0.14, 0), mat_sec, Vector3.ZERO, 14)
		"ash":
			# Angular Cybernetic Shoulder Fins
			_add_box(uarm_l, Vector3(0.035, 0.18, 0.13), Vector3(0.065, 0.05, 0), mat_sec, Vector3(0, 0, -0.35), "AshPauldronL")
			_add_box(uarm_r, Vector3(0.035, 0.18, 0.13), Vector3(-0.065, 0.05, 0), mat_sec, Vector3(0, 0, 0.35), "AshPauldronR")
		"wraith":
			# Asymmetric Silver Left Shoulder Pauldron + Padded Indigo Sleeves
			_add_sphere(uarm_l, 0.082, Vector3(0.02, 0.05, 0), mat_metal, "WraithPauldronL", Vector3(1.1, 1.15, 1.1))
			_add_cyl(uarm_r, 0.060, 0.055, 0.16, Vector3(0, 0.10, 0), mat_dark, Vector3.ZERO, 12)
		"caustic":
			# Heavy Olive/Yellow Hazmat Padded Upper Arms
			_add_cyl(uarm_l, 0.075, 0.068, 0.20, Vector3(0, 0.11, 0), mat_prim, Vector3.ZERO, 14)
			_add_cyl(uarm_r, 0.075, 0.068, 0.20, Vector3(0, 0.11, 0), mat_prim, Vector3.ZERO, 14)
		_:
			# Tactical Shoulder Pads for Valkyrie, Bangalore, Octane, Lifeline
			_add_box(uarm_l, Vector3(0.11, 0.13, 0.12), Vector3(0.02, 0.06, 0), mat_sec)
			_add_box(uarm_r, Vector3(0.11, 0.13, 0.12), Vector3(-0.02, 0.06, 0), mat_sec)


static func _add_Legend_forearm_gear_gen5(larm_l: Node3D, larm_r: Node3D, lid: String, mat_prim: Material, mat_sec: Material, _mat_under: Material, mat_dark: Material, mat_metal: Material, mat_glow: Material, mat_plasma: Material) -> void:
	# Visible in BOTH 1st-Person and 3rd-Person! (+Y runs elbow -> wrist, y = 0.04..0.22)
	match lid:
		"wraith":
			# Wraith Signature Left Forearm Dimensional Void Gauntlet + Glowing Violet Coils!
			_add_cyl(larm_l, 0.054, 0.046, 0.16, Vector3(0, 0.12, 0), mat_dark, Vector3.ZERO, 14, "VoidGauntletL")
			_add_box(larm_l, Vector3(0.04, 0.12, 0.07), Vector3(0.035, 0.13, 0), mat_metal)
			_add_cyl(larm_l, 0.056, 0.056, 0.025, Vector3(0, 0.15, 0), mat_plasma, Vector3.ZERO, 14, "VoidCoil")
			_add_cyl(larm_r, 0.050, 0.044, 0.14, Vector3(0, 0.13, 0), mat_dark, Vector3.ZERO, 12)
		"pathfinder":
			# Pathfinder Left Forearm Grappling Hook Winch & Right Robotic Forearm Strut
			_add_cyl(larm_l, 0.055, 0.048, 0.20, Vector3(0, 0.11, 0), mat_prim, Vector3.ZERO, 12)
			_add_cyl(larm_r, 0.055, 0.048, 0.20, Vector3(0, 0.11, 0), mat_prim, Vector3.ZERO, 12)
			_add_cyl(larm_l, 0.038, 0.038, 0.12, Vector3(0.045, 0.14, 0), mat_metal, Vector3.ZERO, 10, "GrappleLauncher")
			_add_cyl(larm_l, 0.042, 0.042, 0.03, Vector3(0.045, 0.19, 0), mat_glow, Vector3.ZERO, 10)
		"gibraltar":
			# Gibraltar Left Forearm Hard-Light Gun-Shield Projector Emitter + Heavy Arm Guards
			_add_box(larm_l, Vector3(0.11, 0.18, 0.11), Vector3(0, 0.12, 0), mat_prim, Vector3.ZERO, "GibbyBracerL")
			_add_box(larm_r, Vector3(0.10, 0.17, 0.10), Vector3(0, 0.12, 0), mat_prim, Vector3.ZERO, "GibbyBracerR")
			_add_cyl(larm_l, 0.055, 0.055, 0.03, Vector3(0.055, 0.13, 0), mat_glow, Vector3(0, 0, PI * 0.5), 14, "GunShieldEmitter")
		"mirage":
			# Mirage Signature Glowing Cyan Holo-Decoy Emitters on Both Forearms
			_add_cyl(larm_l, 0.052, 0.045, 0.16, Vector3(0, 0.12, 0), mat_dark, Vector3.ZERO, 12)
			_add_cyl(larm_r, 0.052, 0.045, 0.16, Vector3(0, 0.12, 0), mat_dark, Vector3.ZERO, 12)
			_add_cyl(larm_l, 0.034, 0.034, 0.025, Vector3(0.048, 0.13, 0), mat_glow, Vector3(0, 0, PI * 0.5), 12)
			_add_cyl(larm_r, 0.034, 0.034, 0.025, Vector3(-0.048, 0.13, 0), mat_glow, Vector3(0, 0, PI * 0.5), 12)
		"bloodhound":
			# Bloodhound Left Forearm Sonar Tracker Screen & Raven Bracer
			_add_cyl(larm_l, 0.056, 0.048, 0.17, Vector3(0, 0.12, 0), mat_prim, Vector3.ZERO, 12)
			_add_cyl(larm_r, 0.054, 0.046, 0.16, Vector3(0, 0.12, 0), mat_prim, Vector3.ZERO, 12)
			_add_box(larm_l, Vector3(0.03, 0.09, 0.06), Vector3(0.048, 0.13, 0), mat_plasma, Vector3.ZERO, "SonarWristScreen")
		"octane":
			# Octane Glowing Green Stim Syringe Injector on Left Forearm
			_add_cyl(larm_l, 0.048, 0.042, 0.14, Vector3(0, 0.13, 0), mat_dark, Vector3.ZERO, 12)
			_add_cyl(larm_l, 0.018, 0.018, 0.12, Vector3(0.045, 0.13, 0), mat_plasma, Vector3.ZERO, 10, "WristStimTube")
		_:
			# Sleek Tactical Bracers for Ash, Horizon, Valkyrie, Lifeline, Bangalore, Caustic
			_add_cyl(larm_l, 0.050, 0.044, 0.15, Vector3(0, 0.12, 0), mat_sec, Vector3.ZERO, 12)
			_add_cyl(larm_r, 0.050, 0.044, 0.15, Vector3(0, 0.12, 0), mat_sec, Vector3.ZERO, 12)


static func _add_Legend_leg_gear_gen5(thigh_l: Node3D, thigh_r: Node3D, calf_l: Node3D, calf_r: Node3D, lid: String, mat_prim: Material, mat_sec: Material, mat_under: Material, mat_dark: Material, mat_metal: Material, mat_glow: Material, mat_plasma: Material) -> void:
	# Note: in thigh_l/r and calf_l/r local space, +Y runs proximal->distal (0.0 -> 0.38), and -Z is forward!
	match lid:
		"octane":
			# OCTANE SIGNATURE ROBOTIC PROSTHETIC METAL BLADE-RUNNER CALVES!
			_add_cyl(calf_l, 0.062, 0.042, 0.34, Vector3(0, 0.19, 0), mat_metal, Vector3.ZERO, 14, "ProstheticCalfL")
			_add_cyl(calf_r, 0.062, 0.042, 0.34, Vector3(0, 0.19, 0), mat_metal, Vector3.ZERO, 14, "ProstheticCalfR")
			_add_box(calf_l, Vector3(0.04, 0.24, 0.08), Vector3(0, 0.22, 0.03), mat_dark, Vector3.ZERO, "BladeSpringL")
			_add_box(calf_r, Vector3(0.04, 0.24, 0.08), Vector3(0, 0.22, 0.03), mat_dark, Vector3.ZERO, "BladeSpringR")
			_add_cyl(calf_l, 0.066, 0.066, 0.04, Vector3(0, 0.05, 0), mat_plasma, Vector3.ZERO, 12)
			_add_cyl(calf_r, 0.066, 0.066, 0.04, Vector3(0, 0.05, 0), mat_plasma, Vector3.ZERO, 12)
		"pathfinder":
			# PATHFINDER MECHANICAL HYDRAULIC ROBOT THIGHS & PISTON LEGS!
			_add_cyl(thigh_l, 0.078, 0.068, 0.32, Vector3(0, 0.18, 0), mat_prim, Vector3.ZERO, 14, "RobotThighL")
			_add_cyl(thigh_r, 0.078, 0.068, 0.32, Vector3(0, 0.18, 0), mat_prim, Vector3.ZERO, 14, "RobotThighR")
			_add_cyl(calf_l, 0.064, 0.048, 0.34, Vector3(0, 0.19, 0), mat_sec, Vector3.ZERO, 14, "RobotCalfL")
			_add_cyl(calf_r, 0.064, 0.048, 0.34, Vector3(0, 0.19, 0), mat_sec, Vector3.ZERO, 14, "RobotCalfR")
			_add_sphere(calf_l, 0.072, Vector3(0, 0.02, 0), mat_metal, "RobotKneeL")
			_add_sphere(calf_r, 0.072, Vector3(0, 0.02, 0), mat_metal, "RobotKneeR")
		"lifeline":
			# LIFELINE SIGNATURE BAGGY RESCUE CARGO PANTS & POCKETS!
			_add_cyl(thigh_l, 0.095, 0.105, 0.32, Vector3(0, 0.18, 0), mat_sec, Vector3.ZERO, 14, "CargoThighL")
			_add_cyl(thigh_r, 0.095, 0.105, 0.32, Vector3(0, 0.18, 0), mat_sec, Vector3.ZERO, 14, "CargoThighR")
			_add_box(thigh_l, Vector3(0.05, 0.14, 0.12), Vector3(0.085, 0.18, 0), mat_prim, Vector3.ZERO, "CargoPocketL")
			_add_box(thigh_r, Vector3(0.05, 0.14, 0.12), Vector3(-0.085, 0.18, 0), mat_prim, Vector3.ZERO, "CargoPocketR")
			_add_cyl(calf_l, 0.095, 0.078, 0.30, Vector3(0, 0.17, 0), mat_sec, Vector3.ZERO, 14, "CargoCalfL")
			_add_cyl(calf_r, 0.095, 0.078, 0.30, Vector3(0, 0.17, 0), mat_sec, Vector3.ZERO, 14, "CargoCalfR")
		"gibraltar":
			# GIBRALTAR MASSIVE JUGGERNAUT RIOT LEG ARMOR & SHIN PLATES!
			_add_box(thigh_l, Vector3(0.18, 0.30, 0.19), Vector3(0, 0.18, 0), mat_prim, Vector3.ZERO, "GibbyThighL")
			_add_box(thigh_r, Vector3(0.18, 0.30, 0.19), Vector3(0, 0.18, 0), mat_prim, Vector3.ZERO, "GibbyThighR")
			_add_box(calf_l, Vector3(0.16, 0.32, 0.18), Vector3(0, 0.18, -0.01), mat_prim, Vector3.ZERO, "GibbyShinL")
			_add_box(calf_r, Vector3(0.16, 0.32, 0.18), Vector3(0, 0.18, -0.01), mat_prim, Vector3.ZERO, "GibbyShinR")
			_add_box(calf_l, Vector3(0.12, 0.24, 0.04), Vector3(0, 0.18, -0.095), mat_sec)
			_add_box(calf_r, Vector3(0.12, 0.24, 0.04), Vector3(0, 0.18, -0.095), mat_sec)
		"horizon":
			# HORIZON ANTI-GRAVITY SPACEWALK THRUSTER BOOTS!
			_add_cyl(calf_l, 0.078, 0.092, 0.30, Vector3(0, 0.20, 0), mat_under, Vector3.ZERO, 14, "SpaceBootL")
			_add_cyl(calf_r, 0.078, 0.092, 0.30, Vector3(0, 0.20, 0), mat_under, Vector3.ZERO, 14, "SpaceBootR")
			_add_cyl(calf_l, 0.088, 0.088, 0.035, Vector3(0, 0.12, 0), mat_glow, Vector3.ZERO, 14, "GravRingL")
			_add_cyl(calf_r, 0.088, 0.088, 0.035, Vector3(0, 0.12, 0), mat_glow, Vector3.ZERO, 14, "GravRingR")
		"ash":
			# ASH SLEEK CYBERNETIC SIMULACRUM BLADE CALVES!
			_add_cyl(calf_l, 0.062, 0.038, 0.34, Vector3(0, 0.19, 0), mat_prim, Vector3.ZERO, 12, "AshBladeCalfL")
			_add_cyl(calf_r, 0.062, 0.038, 0.34, Vector3(0, 0.19, 0), mat_prim, Vector3.ZERO, 12, "AshBladeCalfR")
			_add_box(calf_l, Vector3(0.03, 0.28, 0.09), Vector3(0, 0.18, -0.04), mat_sec)
			_add_box(calf_r, Vector3(0.03, 0.28, 0.09), Vector3(0, 0.18, -0.04), mat_sec)
		"caustic":
			# CAUSTIC HEAVY CHEMICAL WADER BOOTS!
			_add_cyl(calf_l, 0.085, 0.082, 0.32, Vector3(0, 0.19, 0), mat_dark, Vector3.ZERO, 14)
			_add_cyl(calf_r, 0.085, 0.082, 0.32, Vector3(0, 0.19, 0), mat_dark, Vector3.ZERO, 14)
			_add_box(calf_l, Vector3(0.11, 0.09, 0.05), Vector3(0, 0.04, -0.075), mat_sec)
			_add_box(calf_r, Vector3(0.11, 0.09, 0.05), Vector3(0, 0.04, -0.075), mat_sec)
		_:
			# Armored Knee Pads & Tactical Shin Greaves for Wraith, Bloodhound, Valkyrie, Bangalore, Mirage
			_add_box(calf_l, Vector3(0.095, 0.09, 0.05), Vector3(0, 0.04, -0.07), mat_sec, Vector3.ZERO, "KneePadL")
			_add_box(calf_r, Vector3(0.095, 0.09, 0.05), Vector3(0, 0.04, -0.07), mat_sec, Vector3.ZERO, "KneePadR")
			_add_cyl(calf_l, 0.068, 0.058, 0.24, Vector3(0, 0.21, 0), mat_dark, Vector3.ZERO, 12, "ShinGreaveL")
			_add_cyl(calf_r, 0.068, 0.058, 0.24, Vector3(0, 0.21, 0), mat_dark, Vector3.ZERO, 12, "ShinGreaveR")


static func animate_rig(rig: Node3D, delta: float, s: Dictionary = {}) -> void:
	if rig == null:
		return

	var ual_model: Node3D = rig.get_node_or_null("UALCharacterModel") as Node3D
	if ual_model == null:
		return

	var skels := ual_model.find_children("*", "Skeleton3D", true, false)
	var skel: Skeleton3D = (skels[0] as Skeleton3D) if not skels.is_empty() else null
	if skel == null:
		return

	var bone_map: PackedInt32Array
	if rig.has_meta("bone_map"):
		bone_map = rig.get_meta("bone_map")
	else:
		bone_map = _build_bone_map(skel)
		rig.set_meta("bone_map", bone_map)

	var mode: String = str(s.get("mode", "combat"))
	var lid: String = str(rig.get_meta("legend_id", "wraith"))
	var is_first_person: bool = bool(s.get("is_first_person", false))
	var is_moving: bool = bool(s.get("is_moving", false))
	var is_sprinting: bool = bool(s.get("is_sprinting", false))
	var is_sliding: bool = bool(s.get("is_sliding", false))
	var is_crouching: bool = bool(s.get("is_crouching", false))
	var is_in_air: bool = bool(s.get("is_in_air", false))
	var vel_y: float = float(s.get("vel_y", 0.0))
	var land_compress: float = float(s.get("land_compress", 0.0))
	var is_wall_climbing: bool = bool(s.get("is_wall_climbing", false))
	var is_mantling: bool = bool(s.get("is_mantling", false))
	var is_ziplining: bool = bool(s.get("is_ziplining", false))
	var is_grappling: bool = bool(s.get("is_grappling", false))
	var is_healing: bool = bool(s.get("is_healing", false))
	var is_heirloom: bool = bool(s.get("is_heirloom", false))
	var is_reloading: bool = bool(s.get("is_reloading", false))
	var reload_progress: float = clampf(float(s.get("reload_progress", 0.0)), 0.0, 1.0)
	var is_firing: bool = bool(s.get("is_firing", false))
	var is_melee: bool = bool(s.get("is_melee", false))
	var melee_prog: float = clampf(float(s.get("melee_prog", 0.0)), 0.0, 1.0)
	var melee_combo_idx: int = int(s.get("melee_combo_idx", 0))
	var is_ads: bool = bool(s.get("is_ads", false))
	var aim_pitch: float = float(s.get("aim_pitch", 0.0))
	var move_angle_local: float = float(s.get("move_angle_local", 0.0))
	var flinch: float = float(s.get("flinch", s.get("hit_flinch", 0.0)))
	var speed: float = float(s.get("speed", 6.5))
	var bob_phase: float = float(s.get("strafe_phase", 0.0))

	if not is_sprinting and is_moving and speed > 10.0 and not is_ads and not is_firing and not is_crouching and not is_sliding:
		is_sprinting = true

	# Apply Legend-specific body stature in 3rd-person / Lobby, and invariant 1.0 scale in 1st-person ADS/view
	var target_scale: Vector3 = Vector3.ONE if is_first_person else rig.get_meta("legend_scale", Vector3.ONE)
	ual_model.scale = target_scale

	# 1. Toggle Held Firearm / Held Heirloom / Dual-Wield Left Heirloom / Back Holster / Heal Prop / Body Attachments
	var held_wep: Node3D = ual_model.find_child("HeldWeaponRoot", true, false) as Node3D
	var held_hl: Node3D = ual_model.find_child("HeldHeirloomRoot", true, false) as Node3D
	var held_left_hl: Node3D = ual_model.find_child("HeldLeftHeirloomRoot", true, false) as Node3D
	var back_holster: Node3D = ual_model.find_child("BackHolsterRoot", true, false) as Node3D
	var heal_prop: Node3D = ual_model.find_child("HealPropRoot", true, false) as Node3D
	var jet_l: Node3D = ual_model.find_child("JumpkitJetL", true, false) as Node3D
	var jet_r: Node3D = ual_model.find_child("JumpkitJetR", true, false) as Node3D
	var head_att: Node3D = ual_model.find_child("HeadBoneAttachment", true, false) as Node3D
	var chest_att: Node3D = ual_model.find_child("ChestBoneAttachment", true, false) as Node3D
	var pelvis_att: Node3D = ual_model.find_child("PelvisBoneAttachment", true, false) as Node3D
	var uarm_l: Node3D = ual_model.find_child("LeftUpperArmAttachment", true, false) as Node3D
	var uarm_r: Node3D = ual_model.find_child("RightUpperArmAttachment", true, false) as Node3D

	var hands_busy: bool = (is_healing or is_wall_climbing or is_mantling)
	if held_wep:
		held_wep.visible = (not is_heirloom) and (not hands_busy)
	if held_hl:
		held_hl.visible = is_heirloom and (not hands_busy)
	if held_left_hl:
		held_left_hl.visible = is_heirloom and (not hands_busy) and (lid == "pathfinder" or lid == "lifeline" or lid == "ash")
	if back_holster:
		back_holster.visible = (not is_first_person) and (is_heirloom or hands_busy)
	if heal_prop:
		heal_prop.visible = is_healing

	# Hide Head/Chest/Pelvis/Shoulder attachments in 1st-person so nothing ever clips into the camera lens!
	if head_att:
		head_att.visible = not is_first_person
	if chest_att:
		chest_att.visible = not is_first_person
	if pelvis_att:
		pelvis_att.visible = not is_first_person
	if uarm_l:
		uarm_l.visible = not is_first_person
	if uarm_r:
		uarm_r.visible = not is_first_person

	var jets_active: bool = (not is_first_person) and (is_sliding or is_in_air or is_ziplining or is_grappling or is_wall_climbing)
	if jet_l:
		jet_l.visible = jets_active
	if jet_r:
		jet_r.visible = jets_active

	# 2. Keep ual_model strictly level on the floor (y = 0.0, pitch = 0.0)
	var yaw_twist: float = (clampf(move_angle_local * 0.40, -0.48, 0.48) if (is_moving and not is_first_person) else 0.0)
	ual_model.position.y = lerpf(ual_model.position.y, 0.0, delta * 18.0)
	ual_model.rotation.x = lerpf(ual_model.rotation.x, 0.0, delta * 18.0)
	ual_model.rotation.y = lerp_angle(ual_model.rotation.y, PI + yaw_twist, delta * 14.0)

	# 3. Lobby Showcase & Death States
	var prev_clip: String = str(rig.get_meta("anim_clip", "Pistol_Idle_Loop"))
	var anim_time: float = float(rig.get_meta("anim_time", 0.0))

	if mode == "lobby":
		anim_time += delta * 0.95
		rig.set_meta("anim_clip", "Pistol_Idle_Loop")
		rig.set_meta("anim_time", anim_time)
		_sample_mocap_clip_to_skeleton(skel, bone_map, "Pistol_Idle_Loop", anim_time, true)
		var sp1_lobby: int = bone_map[2]
		if sp1_lobby >= 0:
			var q_sp1_l: Quaternion = skel.get_bone_pose_rotation(sp1_lobby)
			skel.set_bone_pose_rotation(sp1_lobby, Quaternion(Vector3.RIGHT, 0.185) * q_sp1_l)
		return
	elif mode == "death":
		if prev_clip != "Death01":
			anim_time = 0.0
		else:
			anim_time += delta * 1.15
		rig.set_meta("anim_clip", "Death01")
		rig.set_meta("anim_time", anim_time)
		_sample_mocap_clip_to_skeleton(skel, bone_map, "Death01", anim_time, false)
		return

	# 4. Select Active Mocap Clip & Advance Playhead Deterministically
	var target_clip: String = "Pistol_Idle_Loop"
	var clip_speed: float = 1.0
	var is_looping: bool = true
	var explicit_norm_progress: float = -1.0

	if is_melee:
		is_looping = false
		explicit_norm_progress = clampf(melee_prog, 0.0, 0.999)
		if is_heirloom and lid != "pathfinder":
			var stage_hl: int = posmod(melee_combo_idx, 3)
			if stage_hl == 0:
				target_clip = "Sword_Regular_A"
			elif stage_hl == 1:
				target_clip = "Sword_Regular_B"
			else:
				target_clip = "Sword_Attack"
		else:
			var stage_fist: int = posmod(melee_combo_idx, 3)
			if stage_fist == 0:
				target_clip = "Punch_Jab"
			elif stage_fist == 1:
				target_clip = "Punch_Cross"
			else:
				target_clip = "Melee_Hook"
	elif flinch > 0.15:
		target_clip = "Hit_Chest"
		clip_speed = 1.4
		is_looping = false
	elif is_healing:
		target_clip = "Consume"
		clip_speed = 1.15
		is_looping = true
	elif is_reloading:
		# STRICT SINGLE-CYCLE RELOAD (`1.换弹动画只播放一遍`):
		# Playhead is locked 1:1 to `reload_progress` (0.0 -> 1.0) so it plays strictly ONCE!
		target_clip = "Pistol_Reload"
		is_looping = false
		explicit_norm_progress = clampf(reload_progress, 0.0, 0.999)
	elif is_wall_climbing or is_mantling:
		target_clip = "ClimbUp_1m"
		clip_speed = 1.45
		is_looping = true
	elif is_in_air or is_ziplining or is_grappling:
		var use_ninja: bool = (lid == "wraith" or lid == "octane" or lid == "ash" or lid == "valkyrie")
		if vel_y > 1.8:
			target_clip = "NinjaJump_Start" if use_ninja else "Jump_Start"
			clip_speed = 1.25
			is_looping = false
		else:
			target_clip = "NinjaJump_Idle_Loop" if use_ninja else "Jump_Loop"
			clip_speed = 1.05
			is_looping = true
	elif is_sliding:
		target_clip = "Slide_Loop"
		clip_speed = 1.15
		is_looping = true
	elif is_crouching:
		if is_moving:
			target_clip = "Crouch_Fwd_Loop"
			clip_speed = clampf(speed / 4.2, 0.90, 1.45)
			is_looping = true
		else:
			target_clip = "Crouch_Idle_Loop"
			clip_speed = 1.0
			is_looping = true
	elif is_moving:
		if is_sprinting:
			target_clip = "Sprint_Loop"
			clip_speed = clampf(speed / 9.8, 0.95, 1.50)
			is_looping = true
		elif speed > 4.0 and not is_ads:
			target_clip = "Jog_Fwd_Loop"
			clip_speed = clampf(speed / 6.8, 0.95, 1.45)
			is_looping = true
		else:
			target_clip = "Walk_Loop"
			clip_speed = clampf(speed / 4.2, 0.90, 1.35)
			is_looping = true
	else:
		if land_compress > 0.35:
			target_clip = "Jump_Land"
			clip_speed = 1.6
			is_looping = false
		elif is_firing:
			target_clip = "Pistol_Shoot"
			clip_speed = 1.6
			is_looping = true
		elif is_heirloom and not is_first_person:
			target_clip = "Sword_Idle"
			clip_speed = 1.0
			is_looping = true
		else:
			target_clip = "Pistol_Idle_Loop"
			clip_speed = 1.0
			is_looping = true

	var clip_info: Dictionary = _mocap_bank.get(target_clip, _mocap_bank.get("Pistol_Idle_Loop", {}))
	var clip_dur: float = float(clip_info.get("duration", 1.0))

	if explicit_norm_progress >= 0.0:
		anim_time = explicit_norm_progress * clip_dur
	else:
		if prev_clip != target_clip:
			anim_time = 0.0
		else:
			anim_time += delta * clip_speed

	rig.set_meta("anim_clip", target_clip)
	rig.set_meta("anim_time", anim_time)

	# 5. Evaluate All 65 Bones of `target_clip` Directly onto `Skeleton3D`!
	_sample_mocap_clip_to_skeleton(skel, bone_map, target_clip, anim_time, is_looping)

	# 6. Upper-Body Combat Weapon Stance Overlay During Locomotion/Crouch/Slide/Jump + Pelvis-Compensated Aim Pitch
	var keep_upper_aimed: bool = (not is_reloading and not is_melee and not is_healing and not is_wall_climbing and not is_mantling) and (not is_heirloom or is_first_person)
	if keep_upper_aimed and target_clip != "Pistol_Idle_Loop" and target_clip != "Pistol_Shoot":
		_overlay_upper_body_pistol_aim(skel, bone_map, float(s.get("time", anim_time)), bob_phase, is_moving, is_sprinting)
		if is_firing:
			var r_hand_i: int = bone_map[34]
			if r_hand_i >= 0:
				var q_rh: Quaternion = skel.get_bone_pose_rotation(r_hand_i)
				skel.set_bone_pose_rotation(r_hand_i, q_rh * Quaternion(Vector3.RIGHT, -0.06))

	if not is_wall_climbing and not is_mantling:
		var pelvis_idx: int = bone_map[1]
		var spine01_idx: int = bone_map[2]
		if pelvis_idx >= 0 and spine01_idx >= 0:
			var q_pel_cur: Quaternion = skel.get_bone_pose_rotation(pelvis_idx)
			var q_pel_ref: Quaternion = _get_pistol_ref_quat(1) if keep_upper_aimed else q_pel_cur
			var q_sp1_ref: Quaternion = _get_pistol_ref_quat(2) if keep_upper_aimed else skel.get_bone_pose_rotation(spine01_idx)
			var level_trim: float = -0.185 if (not is_heirloom or is_first_person) else 0.0
			var pitch_rad: float = clampf(-(aim_pitch + level_trim), -1.15, 1.15)
			var q_pitch := Quaternion(Vector3.RIGHT, pitch_rad)
			var q_yaw_comp := Quaternion(Vector3.UP, -yaw_twist)
			skel.set_bone_pose_rotation(spine01_idx, q_pel_cur.inverse() * q_yaw_comp * q_pitch * q_pel_ref * q_sp1_ref)

	# 7. First-Person Head/Neck Bone Scaling (Zero Camera Clipping in Unified 1st-Person View!)
	var head_idx: int = bone_map[6]
	var neck_idx: int = bone_map[5]
	var h_scale: Vector3 = Vector3(0.001, 0.001, 0.001) if is_first_person else Vector3.ONE
	if head_idx >= 0:
		skel.set_bone_pose_scale(head_idx, h_scale)
	if neck_idx >= 0:
		skel.set_bone_pose_scale(neck_idx, h_scale)

	# 8. Animate Unified HeldWeaponRoot Mechanical Parts (`MagPivot`, `BoltPivot`, `MuzzleFlashNode`)
	if held_wep != null and held_wep.visible:
		var mag_piv: Node3D = held_wep.find_child("MagPivot", true, false) as Node3D
		var bolt_piv: Node3D = held_wep.find_child("BoltPivot", true, false) as Node3D
		var flash_node: Node3D = held_wep.find_child("MuzzleFlashNode", true, false) as Node3D
		var bot_flash: Node3D = held_wep.find_child("BotMuzzleFlash", true, false) as Node3D
		var show_flash: bool = is_firing and ((int(Time.get_ticks_msec() / 32) % 2) == 0)
		if flash_node:
			flash_node.visible = show_flash
		if bot_flash:
			bot_flash.visible = show_flash
		if mag_piv:
			if not mag_piv.has_meta("base_pos"):
				mag_piv.set_meta("base_pos", mag_piv.position)
			var base_mp: Vector3 = mag_piv.get_meta("base_pos")
			if is_reloading:
				var drop_amt: float = 0.0
				if reload_progress >= 0.10 and reload_progress < 0.42:
					drop_amt = clampf((reload_progress - 0.10) / 0.22, 0.0, 1.0)
				elif reload_progress >= 0.42 and reload_progress < 0.68:
					drop_amt = 1.0 - clampf((reload_progress - 0.42) / 0.22, 0.0, 1.0)
				mag_piv.position = base_mp + Vector3(-0.04 * drop_amt, -0.22 * drop_amt, 0.02 * drop_amt)
			else:
				mag_piv.position = base_mp
		if bolt_piv:
			if not bolt_piv.has_meta("base_pos"):
				bolt_piv.set_meta("base_pos", bolt_piv.position)
			var base_bp: Vector3 = bolt_piv.get_meta("base_pos")
			if is_reloading and reload_progress >= 0.68 and reload_progress <= 0.92:
				var rack_t: float = sin(((reload_progress - 0.68) / 0.24) * PI)
				bolt_piv.position = base_bp + Vector3(0.0, 0.0, 0.065 * rack_t)
			elif is_firing:
				var fire_t: float = float(int(Time.get_ticks_msec() / 25) % 2)
				bolt_piv.position = base_bp + Vector3(0.0, 0.0, 0.045 * fire_t)
			else:
				bolt_piv.position = base_bp
