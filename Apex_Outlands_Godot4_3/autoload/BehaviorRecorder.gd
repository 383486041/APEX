extends Node
## BehaviorRecorder Autoload Singleton for Godot 4.3
## Records live player movement, aiming, crouching, jumping, shooting, reloading, and healing trajectories,
## exports/imports JSON logs so the user can inspect or share them, and trains AI bots (`ApexBotAI.gd`)
## via both statistical policy extraction (`learned_policy`) and k-NN state-action imitation lookup (`query_imitation_action`).

signal recording_state_changed(is_recording: bool, frame_count: int)
signal policy_trained(policy: Dictionary)

var is_recording: bool = false
var use_imitation_ai: bool = true
var sample_interval: float = 0.10 # 10 Hz state-action trajectory sampling
var _sample_accum: float = 0.0

var recorded_frames: Array = []
var recorded_events: Array = []

# Default / Learned AI Policy Parameters (strictly bounded by player performance limits)
var learned_policy: Dictionary = {
	"strafe_frequency": 2.35,
	"crouch_weave_prob": 0.30,
	"jump_peek_prob": 0.09,
	"slide_engage_prob": 0.16,
	"preferred_engagement_dist": 21.0,
	"retreat_cover_dist": 11.0,
	"ads_ratio": 0.62,
	"heal_shield_threshold": 25.0,
	"heal_hp_threshold": 65.0,
	"samples_trained": 24
}

func _ready() -> void:
	_seed_initial_demonstrations()

func _seed_initial_demonstrations() -> void:
	for i in range(24):
		var ph: float = float(i) * 0.45
		recorded_frames.append({
			"t": float(i) * 0.1,
			"dist": 16.0 + sin(ph) * 8.0,
			"hp": 90.0 if i < 18 else 60.0,
			"shield": 75.0 if i < 14 else (0.0 if i >= 18 else 25.0),
			"ammo_ratio": 1.0 - float(i % 12) * 0.08,
			"move_x": 1.0 if sin(ph) >= 0.0 else -1.0,
			"move_z": -0.3 if i < 14 else 0.5,
			"crouch": (i % 4 == 2),
			"jump": (i == 7),
			"slide": (i == 3),
			"ads": (i < 16),
			"firing": (i < 16),
			"heal": (i >= 18)
		})

func toggle_recording() -> bool:
	is_recording = not is_recording
	if is_recording:
		PlayerState.toast_pushed.emit("🔴 [F8] 已开启玩家行为录制！你的走位/蹲起/开镜/打电动作将被实时记录用于训练AI", "evo")
	else:
		train_ai_from_records()
		save_to_disk()
		PlayerState.toast_pushed.emit("⏹️ [F8] 已停止录制并完成 AI 模仿策略训练 (共 %d 帧样本)！" % recorded_frames.size(), "evo")
	recording_state_changed.emit(is_recording, recorded_frames.size())
	return is_recording

func record_step(delta: float, player: Node3D, enemies: Array) -> void:
	if not is_recording or player == null:
		return
	_sample_accum += delta
	if _sample_accum < sample_interval:
		return
	_sample_accum = 0.0

	var nearest_d: float = 999.0
	for bot in enemies:
		if is_instance_valid(bot) and bot.hp > 0.0:
			var d: float = bot.global_position.distance_to(player.global_position)
			if d < nearest_d:
				nearest_d = d

	var local_vel: Vector3 = player.global_transform.basis.inverse() * player.velocity
	var move_x: float = clampf(local_vel.x / 9.5, -1.0, 1.0)
	var move_z: float = clampf(local_vel.z / 9.5, -1.0, 1.0)

	var slot: Dictionary = PlayerState.loadout[clampi(PlayerState.active_slot, 0, 1)]
	var max_a: float = maxf(1.0, float(slot.get("max_ammo", 20)))
	var cur_a: float = float(slot.get("ammo", 20))

	var frame := {
		"t": snappedf(float(Time.get_ticks_msec()) * 0.001, 0.01),
		"dist": snappedf(minf(nearest_d, 150.0), 0.1),
		"hp": snappedf(PlayerState.hp, 1.0),
		"shield": snappedf(PlayerState.shield, 1.0),
		"ammo_ratio": snappedf(cur_a / max_a, 0.02),
		"move_x": snappedf(move_x, 0.05),
		"move_z": snappedf(move_z, 0.05),
		"crouch": Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_CTRL),
		"jump": not player.is_on_floor(),
		"slide": bool(player.get("is_sliding")),
		"ads": bool(player.get("is_ads")),
		"firing": Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),
		"heal": (PlayerState.heal_cast_timer > 0.0)
	}
	recorded_frames.append(frame)
	if recorded_frames.size() > 1200:
		recorded_frames.pop_front()

func record_event(event_type: String, meta: Dictionary = {}) -> void:
	if not is_recording:
		return
	recorded_events.append({
		"t": snappedf(float(Time.get_ticks_msec()) * 0.001, 0.01),
		"event": event_type,
		"meta": meta
	})
	if recorded_events.size() > 300:
		recorded_events.pop_front()

func train_ai_from_records() -> Dictionary:
	if recorded_frames.is_empty():
		return learned_policy

	var total_n: int = recorded_frames.size()
	var crouch_cnt: int = 0
	var jump_cnt: int = 0
	var slide_cnt: int = 0
	var ads_cnt: int = 0
	var dir_flips: int = 0
	var prev_sign: float = 0.0
	var dist_sum: float = 0.0
	var dist_cnt: int = 0
	var heal_shield_sum: float = 0.0
	var heal_cnt: int = 0

	for f in recorded_frames:
		if bool(f.get("crouch", false)):
			crouch_cnt += 1
		if bool(f.get("jump", false)):
			jump_cnt += 1
		if bool(f.get("slide", false)):
			slide_cnt += 1
		if bool(f.get("ads", false)):
			ads_cnt += 1

		var mx: float = float(f.get("move_x", 0.0))
		if absf(mx) > 0.15:
			var s: float = signf(mx)
			if prev_sign != 0.0 and s != prev_sign:
				dir_flips += 1
			prev_sign = s

		var d: float = float(f.get("dist", 25.0))
		if bool(f.get("firing", false)) and d < 120.0:
			dist_sum += d
			dist_cnt += 1

		if bool(f.get("heal", false)):
			heal_shield_sum += float(f.get("shield", 25.0))
			heal_cnt += 1

	var duration_sec: float = maxf(1.0, float(total_n) * sample_interval)
	learned_policy["strafe_frequency"] = clampf(float(dir_flips) / duration_sec, 0.8, 4.5)
	learned_policy["crouch_weave_prob"] = clampf(float(crouch_cnt) / float(total_n), 0.05, 0.75)
	learned_policy["jump_peek_prob"] = clampf(float(jump_cnt) / float(total_n), 0.02, 0.35)
	learned_policy["slide_engage_prob"] = clampf(float(slide_cnt) / float(total_n), 0.02, 0.45)
	learned_policy["ads_ratio"] = clampf(float(ads_cnt) / float(total_n), 0.15, 0.95)
	if dist_cnt > 0:
		learned_policy["preferred_engagement_dist"] = clampf(dist_sum / float(dist_cnt), 8.0, 55.0)
	if heal_cnt > 0:
		learned_policy["heal_shield_threshold"] = clampf(heal_shield_sum / float(heal_cnt), 0.0, 75.0)
	learned_policy["samples_trained"] = total_n

	policy_trained.emit(learned_policy)
	PlayerState.toast_pushed.emit("🧠 AI 已根据你的 %d 帧行为完成强化学习！横移频率 %.2fHz | 蹲起率 %.0f%%" % [
		total_n, float(learned_policy["strafe_frequency"]), float(learned_policy["crouch_weave_prob"]) * 100.0
	], "evo")
	return learned_policy

func query_imitation_action(dist_to_player: float, bot_hp: float, bot_shield: float, ammo_ratio: float) -> Dictionary:
	if not use_imitation_ai or recorded_frames.is_empty():
		return {}
	var best_score: float = 999999.0
	var best_frame: Dictionary = {}
	var step: int = maxi(1, recorded_frames.size() / 60)
	for i in range(0, recorded_frames.size(), step):
		var f: Dictionary = recorded_frames[i]
		var d_diff: float = absf(float(f.get("dist", 22.0)) - dist_to_player) * 1.2
		var s_diff: float = absf(float(f.get("shield", 75.0)) - bot_shield) * 0.4
		var h_diff: float = absf(float(f.get("hp", 100.0)) - bot_hp) * 0.4
		var a_diff: float = absf(float(f.get("ammo_ratio", 1.0)) - ammo_ratio) * 15.0
		var score: float = d_diff + s_diff + h_diff + a_diff + randf_range(0.0, 3.5)
		if score < best_score:
			best_score = score
			best_frame = f
	return best_frame

func export_to_json_string() -> String:
	var payload := {
		"version": "Apex_Outlands_Godot4_3_BehaviorLog_v1",
		"learned_policy": learned_policy,
		"events_count": recorded_events.size(),
		"frames_count": recorded_frames.size(),
		"recent_events": recorded_events.slice(maxi(0, recorded_events.size() - 30), recorded_events.size()),
		"trajectory_frames": recorded_frames.slice(maxi(0, recorded_frames.size() - 120), recorded_frames.size())
	}
	return JSON.stringify(payload, "  ")

func import_from_json_string(json_str: String) -> bool:
	var parsed = JSON.parse_string(json_str)
	if typeof(parsed) != TYPE_DICTIONARY:
		PlayerState.toast_pushed.emit("⚠️ JSON 格式解析失败，请检查粘贴内容！", "warn")
		return false
	var dict: Dictionary = parsed
	if dict.has("trajectory_frames") and typeof(dict["trajectory_frames"]) == TYPE_ARRAY:
		recorded_frames = dict["trajectory_frames"]
	if dict.has("learned_policy") and typeof(dict["learned_policy"]) == TYPE_DICTIONARY:
		for k in dict["learned_policy"].keys():
			learned_policy[k] = dict["learned_policy"][k]
	train_ai_from_records()
	use_imitation_ai = true
	PlayerState.toast_pushed.emit("✅ 成功导入玩家行为数据并更新 AI 模仿策略！", "evo")
	return true

func save_to_disk(path: String = "user://player_behavior_log.json") -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(export_to_json_string())
		f.close()
