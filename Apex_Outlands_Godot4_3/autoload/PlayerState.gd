extends Node
## PlayerState Autoload Singleton
## Tracks persistent account progression, currencies, selected Legend/Mode, and live Match Combat State.

signal state_updated
signal evo_leveled_up(new_level: int, tier_name: String)
signal killfeed_pushed(msg: String, col: Color)
signal toast_pushed(msg: String, kind: String)
signal hit_feedback_pushed(target_name: String, single_dmg: int, cumulative_dmg: int, is_headshot: bool, shield_tier: int, cracked_now: bool)
signal enemy_eliminated(victim_name: String, weapon_name: String, total_kills: int)
signal floating_damage_spawned(pos: Vector3, dmg: int, is_headshot: bool, shield_tier: int, cracked: bool)
signal deathbox_spawn_requested(pos: Vector3, bot_name: String, evo_tier: int, weapon_name: String)
signal deathbox_opened(dbox_data: Dictionary)
signal match_victory_achieved(stats: Dictionary)

var selected_legend_id: String = "valkyrie"
var selected_mode_id: String = "br_trios" # "br_trios", "ranked", "mixtape_tdm", "firing_range"
var match_ended: bool = false
var current_deathbox: Dictionary = {}

# Account Progression
var account_level: int = 142
var bp_level: int = 58
var ranked_rp: int = 4850
var apex_coins: int = 2400
var crafting_metals: int = 3650
var heirloom_shards: int = 150
var career_wins: int = 64
var career_kills: int = 1482

# Live Match State (100% matched to reference screenshot)
var match_active: bool = false
var ui_modal_open: bool = false
var inventory_open: bool = false
var hp: float = 100.0
var max_hp: float = 100.0
var evo_level: int = 2
var shield: float = 75.0
var max_shield: float = 75.0
var evo_points: int = 450
var next_evo_points: int = 750
var chosen_upgrades: Dictionary = {"lv2": "", "lv3": ""}

var active_slot: int = 1
var scope_alt_zoom: bool = false # 0: Primary, 1: Secondary, 2: Heirloom Melee
var loadout: Array = [
	{"weapon_id": "mozambique", "ammo": 6, "max_ammo": 6, "optic": "1x_threat", "barrel": 0, "mag": 0, "stock": 2, "hopup": "", "charged": 0.0},
	{"weapon_id": "r301", "ammo": 18, "max_ammo": 28, "optic": "2x_bruiser", "barrel": 3, "mag": 3, "stock": 3, "hopup": "anvil", "charged": 0.0}
]
var gear: Dictionary = {
	"helmet": 2,
	"armor": 2,
	"knockdown": 2,
	"backpack": 2,
	"survival": "heat_shield"
}
var ammo_reserve: Dictionary = {"light": 36, "heavy": 180, "energy": 180, "shotgun": 16, "sniper": 80, "mythic": 60}
var consumables: Dictionary = {"shield_cell": 5, "shield_battery": 2, "syringe": 5, "med_kit": 2, "phoenix_kit": 1}
var selected_heal_id: String = "syringe"
var heal_cast_timer: float = 0.0
var heal_cast_total: float = 0.0
var ordnance: Dictionary = {"frag": 1, "arc_star": 1, "thermite": 1}
var materials: int = 125

var inventory_items: Array = [
	{"type": "ammo", "id": "light", "count": 60},
	{"type": "ammo", "id": "light", "count": 60},
	{"type": "ammo", "id": "shotgun", "count": 16},
	{"type": "ammo", "id": "heavy", "count": 60},
	{"type": "ammo", "id": "energy", "count": 60},
	{"type": "consumable", "id": "shield_battery", "count": 2},
	{"type": "consumable", "id": "shield_battery", "count": 2},
	{"type": "consumable", "id": "shield_cell", "count": 4},
	{"type": "consumable", "id": "med_kit", "count": 2},
	{"type": "consumable", "id": "syringe", "count": 4},
	{"type": "consumable", "id": "phoenix_kit", "count": 1},
	{"type": "ordnance", "id": "arc_star", "count": 2},
	{"type": "ordnance", "id": "frag", "count": 2},
	{"type": "ordnance", "id": "thermite", "count": 2},
	{"type": "attachment", "id": "3x_ranger", "tier": 3, "name": "3倍 游骑兵瞄准镜"},
	{"type": "attachment", "id": "barrel_3", "tier": 3, "name": "Lv.3 紫色枪口补偿器"}
]

var squads_alive: int = 20
var players_alive: int = 60
var kills: int = 0
var damage_dealt: int = 0
var ring_stage: int = 1
var ring_radius: float = 290.0

# Legend Skill Cooldowns & Active Buff Timers
var tac_cooldown: float = 0.0
var ult_charge: float = 38.0
var stim_timer: float = 0.0
var void_timer: float = 0.0
var beast_timer: float = 0.0
var scan_timer: float = 0.0
var double_time_timer: float = 0.0
var gun_shield_hp: float = 50.0
var vtol_fuel: float = 100.0
var passive_warning_text: String = ""

func reset_for_match() -> void:
	match_active = true
	match_ended = false
	current_deathbox = {}
	ui_modal_open = false
	hp = 100.0
	max_hp = 100.0
	kills = 0
	damage_dealt = 0
	materials = 125
	chosen_upgrades = {"lv2": "", "lv3": ""}
	evo_level = 2
	var tier: Dictionary = GameData.get_evo_tier(evo_level)
	max_shield = float(tier["max_shield"])
	shield = max_shield
	evo_points = 450
	next_evo_points = 750
	if selected_mode_id == "firing_range":
		squads_alive = 1
		players_alive = 3
	elif selected_mode_id == "mixtape_tdm":
		squads_alive = 2
		players_alive = 18
	else:
		squads_alive = 20
		players_alive = 60
	ring_stage = 1
	ring_radius = 290.0
	tac_cooldown = 0.0
	ult_charge = 38.0
	stim_timer = 0.0
	void_timer = 0.0
	beast_timer = 0.0
	scan_timer = 0.0
	double_time_timer = 0.0
	heal_cast_timer = 0.0
	gun_shield_hp = 50.0
	vtol_fuel = 100.0
	passive_warning_text = ""
	active_slot = 1
	loadout = [
		{"weapon_id": "mozambique", "ammo": 6, "max_ammo": 6, "optic": "1x_threat", "barrel": 0, "mag": 0, "stock": 2, "hopup": "", "charged": 0.0},
		{"weapon_id": "r301", "ammo": 18, "max_ammo": 28, "optic": "2x_bruiser", "barrel": 3, "mag": 3, "stock": 3, "hopup": "anvil", "charged": 0.0}
	]
	ammo_reserve["light"] = 36
	ammo_reserve["shotgun"] = 16
	state_updated.emit()

func add_damage_and_evo(dmg: int) -> void:
	damage_dealt += dmg
	evo_points += dmg
	ult_charge = minf(100.0, ult_charge + float(dmg) * 0.12)
	while evo_level < 5 and evo_points >= next_evo_points:
		evo_level += 1
		if evo_level == 4:
			evo_level = 5
		var tier: Dictionary = GameData.get_evo_tier(evo_level)
		var diff: float = float(tier["max_shield"]) - max_shield
		max_shield = float(tier["max_shield"])
		shield = minf(max_shield, shield + maxf(25.0, diff))
		next_evo_points = int(tier["next_evo"])
		AudioSynthesizer.play_evo_level_up()
		evo_leveled_up.emit(evo_level, str(tier["name"]))
		toast_pushed.emit("⚡ 进化护盾升级至 %s！按 [F1 / F2] 激活传奇进化天赋" % str(tier["name"]), "evo")
	state_updated.emit()

func perform_armor_swap(target_evo_level: int) -> void:
	if target_evo_level > evo_level:
		evo_level = target_evo_level
		var tier: Dictionary = GameData.get_evo_tier(evo_level)
		max_shield = float(tier["max_shield"])
	shield = max_shield
	AudioSynthesizer.play_evo_level_up()
	toast_pushed.emit("⚡ 死亡之箱一键秒换护盾核心成功！护盾已回满 100%！", "evo")
	state_updated.emit()
