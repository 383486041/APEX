class_name ApexInventoryUI
extends Control
## ============================================================================
## APEX LEGENDS AUTHENTIC GRAPHICAL INVENTORY & DEATHBOX LOOTING SYSTEM
## 100% Visual / Icon Driven — Strictly NO plain text buttons!
## Features:
## - 3 Top Navigation Tabs: [物品栏] (Active, Red Indicator), [小队], [传奇]
## - Top Section: Dual Graphical Weapon Panels (Weapon Silhouettes, Ammo Badges,
##   Mag Ammo Count, and 5 Tier-Colored Attachment Slots: Barrel, Mag, Optic, Stock, Hop-up)
## - Middle Section: 2x8 Rounded-Glass Backpack Grid with Vector-Drawn Item Icons
##   (Light/Heavy/Energy/Shotgun/Sniper Ammo, Shield Batteries, Shield Cells,
##   Medkits, Syringes, Phoenix Kits, Frag/Arc Star/Thermite Ordnance, Attachments)
## - Full Mouse Drag-and-Drop: drag items to reorder, drag to equip, or drag out to drop!
## - Authentic Deathbox Looting (击杀成盒搜刮):
##   - Split-screen Apex Deathbox UI with Victim Banner
##   - Prominent [一键秒换甲] Shield Core card with tier colors & 100% shield restore
##   - Deathbox loot grid (weapons, ammo, consumables) with click/drag looting
## - Red Slashed Circle (🚫) for Ammo & Attachments incompatible with equipped weapons
## - Bottom Section: 5 Equipment Gear Slots (Helmet, Evo Shield, Knockdown, Backpack, Survival)
## - Bottom-Left Squad & Player Status HUD (Legend Portrait, Segmented Shield Bar, HP Bar)
## - Interactive Hover Tooltip Cards + Left-Click to Consume / Right-Click to Drop
## ============================================================================

signal closed
signal consumable_used(item_id: String)
signal item_dropped(item_id: String)
signal weapon_dropped(w_idx: int, weapon_dict: Dictionary)
signal weapon_swapped(slot_a: int, slot_b: int)
signal attachment_dropped(att_type: String, tier: int, optic_id: String)

var active_tab: String = "inventory" # "inventory", "squad", "legends"
var hovered_slot: Dictionary = {}
var hovered_screen_pos: Vector2 = Vector2.ZERO

# Deathbox Looting State
var is_deathbox_mode: bool = false
var deathbox_data: Dictionary = {}

# Mouse Drag-and-Drop State
var is_dragging: bool = false
var drag_item: Dictionary = {}
var drag_from_type: String = "" # "inventory", "deathbox", "attachment"
var drag_from_idx: int = -1
var drag_pos: Vector2 = Vector2.ZERO
var drag_start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(1280, 720)

func open() -> void:
	visible = true
	PlayerState.inventory_open = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	queue_redraw()

func open_deathbox(dbox: Dictionary) -> void:
	deathbox_data = dbox
	is_deathbox_mode = true
	active_tab = "inventory"
	open()

func close() -> void:
	visible = false
	is_deathbox_mode = false
	deathbox_data = {}
	is_dragging = false
	drag_item = {}
	drag_from_type = ""
	drag_from_idx = -1
	PlayerState.inventory_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hovered_slot = {}
	closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE or event.keycode == KEY_I:
			close()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion:
		hovered_screen_pos = (event as InputEventMouseMotion).position
		if is_dragging:
			drag_pos = hovered_screen_pos
		_update_hovered_slot(hovered_screen_pos)
		queue_redraw()

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_update_hovered_slot(mb.position)
				if not hovered_slot.is_empty():
					var hkind: String = str(hovered_slot.get("kind", ""))
					if hkind == "item":
						is_dragging = true
						drag_from_type = "inventory"
						drag_from_idx = int(hovered_slot["index"])
						drag_item = hovered_slot["item"]
						drag_pos = mb.position
						drag_start_pos = mb.position
					elif hkind == "deathbox_item":
						is_dragging = true
						drag_from_type = "deathbox"
						drag_from_idx = int(hovered_slot["index"])
						drag_item = hovered_slot["item"]
						drag_pos = mb.position
						drag_start_pos = mb.position
					elif hkind == "weapon":
						var w_idx: int = int(hovered_slot["wep_idx"])
						var slot_d: Dictionary = PlayerState.loadout[w_idx]
						if str(slot_d.get("weapon_id", "empty")) != "empty":
							is_dragging = true
							drag_from_type = "weapon"
							drag_from_idx = w_idx
							drag_item = slot_d
							drag_pos = mb.position
							drag_start_pos = mb.position
					elif hkind == "attachment":
						var w_idx: int = int(hovered_slot["wep_idx"])
						var ak: String = str(hovered_slot["att_type"])
						var tier: int = int(hovered_slot.get("tier", 0))
						var op_id: String = str(hovered_slot.get("optic_id", ""))
						if tier > 0 or (ak == "optic" and op_id != ""):
							is_dragging = true
							drag_from_type = "attachment"
							drag_from_idx = w_idx
							drag_item = {
								"type": "attachment",
								"att_type": ak,
								"tier": tier,
								"optic_id": op_id,
								"wep_idx": w_idx
							}
							drag_pos = mb.position
							drag_start_pos = mb.position
						else:
							_handle_mouse_click(mb.position, mb.button_index)
					elif hkind == "deathbox_armor_swap":
						_execute_armor_swap()
					elif hkind == "tab":
						_handle_mouse_click(mb.position, mb.button_index)
			else:
				# Mouse released
				if is_dragging:
					var dist: float = mb.position.distance_to(drag_start_pos)
					if dist > 8.0:
						_handle_drop(mb.position)
					else:
						# Considered a simple click if barely moved
						_handle_mouse_click(mb.position, MOUSE_BUTTON_LEFT)
					is_dragging = false
					drag_item = {}
					drag_from_type = ""
					drag_from_idx = -1
					queue_redraw()
				else:
					_handle_mouse_click(mb.position, MOUSE_BUTTON_LEFT)
			get_viewport().set_input_as_handled()

		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_handle_mouse_click(mb.position, MOUSE_BUTTON_RIGHT)
			get_viewport().set_input_as_handled()

func _update_hovered_slot(mpos: Vector2) -> void:
	var vp := get_viewport_rect().size
	hovered_slot = {}

	# Check Tabs
	var tab_w: float = 120.0
	var tab_y: float = 24.0
	var tabs := ["物品栏", "小队", "传奇"]
	var tab_start_x: float = vp.x * 0.5 - (tab_w * 3.0 * 0.5)
	for i in range(tabs.size()):
		var tr := Rect2(tab_start_x + float(i) * tab_w, tab_y, tab_w, 36.0)
		if tr.has_point(mpos):
			hovered_slot = {"kind": "tab", "tab_name": tabs[i]}
			return

	# If in Deathbox mode, check left-side Deathbox panels
	if is_deathbox_mode and not deathbox_data.is_empty():
		# Check Deathbox Armor Swap Card
		var d_armor_rect := Rect2(42, 135, 346, 75)
		if d_armor_rect.has_point(mpos):
			hovered_slot = {
				"kind": "deathbox_armor_swap",
				"tier": int(deathbox_data.get("evo_tier", 3)),
				"swapped": bool(deathbox_data.get("armor_swapped", false))
			}
			return

		# Check Deathbox Items Grid (2 cols x 4 rows)
		var d_items: Array = deathbox_data.get("items", [])
		var d_start_x: float = 42.0
		var d_start_y: float = 238.0
		var d_slot_w: float = 168.0
		var d_slot_h: float = 56.0
		var d_gap: float = 10.0
		for di in range(d_items.size()):
			var c_i: int = di % 2
			var r_i: int = di / 2
			var dr := Rect2(d_start_x + float(c_i) * (d_slot_w + d_gap), d_start_y + float(r_i) * (d_slot_h + d_gap), d_slot_w, d_slot_h)
			if dr.has_point(mpos):
				hovered_slot = {
					"kind": "deathbox_item",
					"index": di,
					"item": d_items[di]
				}
				return

		var db_panel_r := Rect2(32, 78, 365, 545)
		if db_panel_r.has_point(mpos):
			hovered_slot = {
				"kind": "deathbox_panel"
			}
			return

	# Check Player Weapon Cards & Attachments
	var wep_y: float = 78.0
	var wep_w: float = minf(410.0, vp.x * 0.36) if is_deathbox_mode else minf(460.0, vp.x * 0.43)
	var wep_h: float = 185.0
	var w_offset_x: float = 410.0 if is_deathbox_mode else 0.0

	var w1_rect := Rect2((vp.x * 0.5 - wep_w - 14.0) + (w_offset_x * 0.45 if is_deathbox_mode else 0.0), wep_y, wep_w, wep_h)
	var w2_rect := Rect2((vp.x * 0.5 + 14.0) + (w_offset_x * 0.45 if is_deathbox_mode else 0.0), wep_y, wep_w, wep_h)

	for w_idx in [0, 1]:
		var wr: Rect2 = w1_rect if w_idx == 0 else w2_rect
		var slot_data: Dictionary = PlayerState.loadout[w_idx]
		var att_y: float = wr.position.y + wr.size.y - 48.0
		var att_types := ["barrel", "mag", "optic", "stock", "hopup"]
		var slot_sz: float = 38.0
		var gap: float = 8.0
		for a_i in range(att_types.size()):
			var ar := Rect2(wr.position.x + 14.0 + float(a_i) * (slot_sz + gap), att_y, slot_sz, slot_sz)
			if ar.has_point(mpos):
				hovered_slot = {
					"kind": "attachment",
					"wep_idx": w_idx,
					"att_type": att_types[a_i],
					"tier": int(slot_data.get(att_types[a_i], 0)),
					"optic_id": str(slot_data.get("optic", "2x_bruiser")) if att_types[a_i] == "optic" else ""
				}
				return
		if wr.has_point(mpos):
			hovered_slot = {
				"kind": "weapon",
				"wep_idx": w_idx,
				"slot_data": slot_data
			}
			return

	# Check Backpack Grid (2 rows x 8 slots)
	var slot_sz: float = 56.0
	var gap: float = 10.0
	var cols: int = 8
	var grid_shift_x: float = (w_offset_x * 0.45) if is_deathbox_mode else 0.0
	var start_x: float = (vp.x * 0.5 - (float(cols) * slot_sz + float(cols - 1) * gap) * 0.5) + grid_shift_x
	var start_y: float = 295.0

	for i in range(16):
		var col: int = i % cols
		var row: int = i / cols
		var sr := Rect2(start_x + float(col) * (slot_sz + gap), start_y + float(row) * (slot_sz + gap), slot_sz, slot_sz)
		if sr.has_point(mpos):
			if i < PlayerState.inventory_items.size():
				hovered_slot = {
					"kind": "item",
					"index": i,
					"item": PlayerState.inventory_items[i]
				}
			else:
				hovered_slot = {
					"kind": "backpack_empty",
					"index": i
				}
			return

	# Check Equipment Bar Slots
	var eq_y: float = 460.0
	var eq_slots := ["helmet", "armor", "knockdown", "backpack", "survival"]
	var eq_sz: float = 58.0
	var eq_gap: float = 16.0
	var eq_start_x: float = (vp.x * 0.5 - (float(eq_slots.size()) * eq_sz + float(eq_slots.size() - 1) * eq_gap) * 0.5) + grid_shift_x

	for i in range(eq_slots.size()):
		var er := Rect2(eq_start_x + float(i) * (eq_sz + eq_gap), eq_y, eq_sz, eq_sz)
		if er.has_point(mpos):
			var eq_k: String = eq_slots[i]
			hovered_slot = {
				"kind": "equipment",
				"gear_type": eq_k,
				"tier": PlayerState.evo_level if eq_k == "armor" else int(PlayerState.gear.get(eq_k, 2))
			}
			return

func _execute_armor_swap() -> void:
	if deathbox_data.is_empty() or bool(deathbox_data.get("armor_swapped", false)):
		return
	var box_tier: int = int(deathbox_data.get("evo_tier", 3))
	var player_old_tier: int = PlayerState.evo_level
	PlayerState.evo_level = maxi(PlayerState.evo_level, box_tier)
	var tier_info: Dictionary = GameData.get_evo_tier(PlayerState.evo_level)
	PlayerState.max_shield = float(tier_info["max_shield"])
	PlayerState.shield = PlayerState.max_shield
	AudioSynthesizer.play_evo_level_up()
	PlayerState.toast_pushed.emit("⚡ 成功完成死亡之箱一键秒换甲！护盾已充至 100% 满格！", "evo")
	deathbox_data["armor_swapped"] = true
	deathbox_data["evo_tier"] = player_old_tier
	PlayerState.state_updated.emit()
	queue_redraw()

func _drop_weapon(w_idx: int, spawn_in_world: bool = true) -> void:
	if w_idx < 0 or w_idx >= PlayerState.loadout.size():
		return
	var slot_data: Dictionary = PlayerState.loadout[w_idx]
	var wid: String = str(slot_data.get("weapon_id", "empty"))
	if wid == "empty" or wid == "":
		return

	var wep_info: Dictionary = GameData.get_weapon_by_id(wid)
	var dropped_data: Dictionary = slot_data.duplicate(true)

	PlayerState.loadout[w_idx] = {
		"weapon_id": "empty",
		"ammo": 0,
		"max_ammo": 0,
		"optic": "",
		"barrel": 0,
		"mag": 0,
		"stock": 0,
		"hopup": "",
		"charged": 0.0
	}

	var other_idx: int = 1 if w_idx == 0 else 0
	var other_wid: String = str(PlayerState.loadout[other_idx].get("weapon_id", "empty"))
	if other_wid != "empty":
		PlayerState.active_slot = other_idx
	else:
		PlayerState.active_slot = 2 # Melee / Heirloom

	AudioSynthesizer.play_reload_step("mag_out")
	if spawn_in_world:
		weapon_dropped.emit(w_idx, dropped_data)
		PlayerState.toast_pushed.emit("🗑️ 已将【%s】丢弃至地面！" % str(wep_info.get("name", wid)), "info")
	PlayerState.state_updated.emit()
	queue_redraw()

func _detach_attachment_to_inventory(w_idx: int, ak: String, drop_to_world: bool = false) -> void:
	if w_idx < 0 or w_idx >= PlayerState.loadout.size():
		return
	var slot_data: Dictionary = PlayerState.loadout[w_idx]
	var tier: int = int(slot_data.get(ak, 0))
	var op_id: String = str(slot_data.get("optic", ""))

	if ak == "optic" and op_id != "":
		slot_data["optic"] = ""
		var opt_name: String = "瞄准镜"
		for op in GameData.OPTICS:
			if op["id"] == op_id:
				opt_name = str(op["name"])
				break
		if drop_to_world:
			attachment_dropped.emit("optic", 2, op_id)
			PlayerState.toast_pushed.emit("🗑️ 已将【%s】丢弃至地面" % opt_name, "info")
		else:
			PlayerState.inventory_items.append({
				"type": "attachment",
				"id": op_id,
				"tier": 2,
				"name": opt_name
			})
			PlayerState.toast_pushed.emit("📦 已卸下【%s】并放入背包" % opt_name, "info")
		AudioSynthesizer.play_reload_step("lever_cock")
		PlayerState.state_updated.emit()
		queue_redraw()
	elif tier > 0:
		slot_data[ak] = 0
		var att_names: Dictionary = {
			"barrel": "枪口补偿器",
			"mag": "加长弹匣",
			"stock": "标准枪托",
			"hopup": "专属枪械芯片"
		}
		var aname: String = "Lv.%d %s" % [tier, att_names.get(ak, "配件")]
		if drop_to_world:
			attachment_dropped.emit(ak, tier, "")
			PlayerState.toast_pushed.emit("🗑️ 已将【%s】丢弃至地面" % aname, "info")
		else:
			PlayerState.inventory_items.append({
				"type": "attachment",
				"id": "%s_%d" % [ak, tier],
				"tier": tier,
				"name": aname
			})
			PlayerState.toast_pushed.emit("📦 已卸下【%s】并放入背包" % aname, "info")
		AudioSynthesizer.play_reload_step("lever_cock")
		PlayerState.state_updated.emit()
		queue_redraw()

func _equip_attachment_to_weapon(w_idx: int, att_item: Dictionary) -> void:
	if w_idx < 0 or w_idx >= PlayerState.loadout.size():
		return
	var slot_data: Dictionary = PlayerState.loadout[w_idx]
	var wid: String = str(slot_data.get("weapon_id", "empty"))
	if wid == "empty":
		return
	var it_id: String = str(att_item.get("id", ""))
	if it_id.begins_with("1x") or it_id.begins_with("2x") or it_id.begins_with("3x") or it_id.begins_with("4x") or it_id.begins_with("6x"):
		var old_op: String = str(slot_data.get("optic", ""))
		slot_data["optic"] = it_id
		if old_op != "":
			PlayerState.inventory_items.append({
				"type": "attachment",
				"id": old_op,
				"tier": 2,
				"name": "旧瞄准镜"
			})
	elif it_id.begins_with("barrel"):
		var tier: int = int(att_item.get("tier", 3))
		var old_t: int = int(slot_data.get("barrel", 0))
		slot_data["barrel"] = tier
		if old_t > 0:
			PlayerState.inventory_items.append({"type": "attachment", "id": "barrel_%d" % old_t, "tier": old_t, "name": "Lv.%d 枪口补偿器" % old_t})
	elif it_id.begins_with("mag"):
		var tier: int = int(att_item.get("tier", 3))
		var old_t: int = int(slot_data.get("mag", 0))
		slot_data["mag"] = tier
		if old_t > 0:
			PlayerState.inventory_items.append({"type": "attachment", "id": "mag_%d" % old_t, "tier": old_t, "name": "Lv.%d 加长弹匣" % old_t})
	elif it_id.begins_with("stock"):
		var tier: int = int(att_item.get("tier", 3))
		var old_t: int = int(slot_data.get("stock", 0))
		slot_data["stock"] = tier
		if old_t > 0:
			PlayerState.inventory_items.append({"type": "attachment", "id": "stock_%d" % old_t, "tier": old_t, "name": "Lv.%d 标准枪托" % old_t})

func _handle_drop(drop_pos: Vector2) -> void:
	_update_hovered_slot(drop_pos)
	var target_kind: String = str(hovered_slot.get("kind", ""))

	# 1. Dragging an equipped Weapon
	if drag_from_type == "weapon":
		if target_kind == "weapon":
			var target_w_idx: int = int(hovered_slot.get("wep_idx", 0))
			if target_w_idx != drag_from_idx:
				var temp: Dictionary = PlayerState.loadout[drag_from_idx]
				PlayerState.loadout[drag_from_idx] = PlayerState.loadout[target_w_idx]
				PlayerState.loadout[target_w_idx] = temp
				if PlayerState.active_slot == drag_from_idx:
					PlayerState.active_slot = target_w_idx
				elif PlayerState.active_slot == target_w_idx:
					PlayerState.active_slot = drag_from_idx
				AudioSynthesizer.play_reload_step("bolt_slap")
				var w1: Dictionary = GameData.get_weapon_by_id(str(PlayerState.loadout[drag_from_idx].get("weapon_id", "")))
				var w2: Dictionary = GameData.get_weapon_by_id(str(PlayerState.loadout[target_w_idx].get("weapon_id", "")))
				PlayerState.toast_pushed.emit("🔄 已交换武器槽位：【%s】↔【%s】" % [str(w1.get("name","")), str(w2.get("name",""))], "evo")
				weapon_swapped.emit(drag_from_idx, target_w_idx)
				PlayerState.state_updated.emit()
				return
		elif is_deathbox_mode and (target_kind == "deathbox_item" or target_kind == "deathbox_panel"):
			var d_items: Array = deathbox_data.get("items", [])
			var wid: String = str(drag_item.get("weapon_id", "r301"))
			var wep_info: Dictionary = GameData.get_weapon_by_id(wid)
			if target_kind == "deathbox_item" and str(hovered_slot.get("item", {}).get("type", "")) == "weapon":
				var db_item: Dictionary = hovered_slot["item"]
				var db_w_data: Dictionary = db_item.get("weapon_data", {"weapon_id": db_item["id"], "ammo": db_item.get("ammo", 20), "max_ammo": 20})
				PlayerState.loadout[drag_from_idx] = db_w_data.duplicate(true)
				db_item["id"] = wid
				db_item["name"] = str(wep_info.get("name", wid))
				db_item["weapon_data"] = drag_item.duplicate(true)
				AudioSynthesizer.play_reload_step("bolt_slap")
				PlayerState.toast_pushed.emit("🔄 已与战利品箱交换武器：【%s】" % str(wep_info.get("name", wid)), "evo")
			else:
				d_items.append({
					"type": "weapon",
					"id": wid,
					"name": str(wep_info.get("name", wid)),
					"count": 1,
					"ammo": int(drag_item.get("ammo", 0)),
					"weapon_data": drag_item.duplicate(true)
				})
				_drop_weapon(drag_from_idx, false)
				AudioSynthesizer.play_reload_step("mag_in")
				PlayerState.toast_pushed.emit("📦 已将【%s】存入死亡之箱！" % str(wep_info.get("name", wid)), "evo")
			PlayerState.state_updated.emit()
			return
		else:
			# Dropped outside UI onto world: DROP WEAPON TO GROUND!
			_drop_weapon(drag_from_idx, true)
			return

	# 2. Dragging an Attachment from a Weapon
	elif drag_from_type == "attachment":
		if target_kind == "weapon":
			var target_w_idx: int = int(hovered_slot.get("wep_idx", 0))
			if target_w_idx != drag_from_idx:
				var ak: String = str(drag_item.get("att_type", ""))
				var src_slot: Dictionary = PlayerState.loadout[drag_from_idx]
				var dst_slot: Dictionary = PlayerState.loadout[target_w_idx]
				if ak == "optic":
					var temp_op: String = str(dst_slot.get("optic", ""))
					dst_slot["optic"] = str(src_slot.get("optic", ""))
					src_slot["optic"] = temp_op
				else:
					var temp_tier: int = int(dst_slot.get(ak, 0))
					dst_slot[ak] = int(src_slot.get(ak, 0))
					src_slot[ak] = temp_tier
				AudioSynthesizer.play_reload_step("lever_cock")
				PlayerState.toast_pushed.emit("🔧 已将配件转移至另一把武器！", "evo")
				PlayerState.state_updated.emit()
				return
		elif target_kind == "item" or target_kind == "backpack_empty":
			_detach_attachment_to_inventory(drag_from_idx, str(drag_item.get("att_type", "")), false)
			return
		else:
			# Dropped outside onto world
			_detach_attachment_to_inventory(drag_from_idx, str(drag_item.get("att_type", "")), true)
			return

	# 3. Dragging from Deathbox
	elif drag_from_type == "deathbox":
		var d_items: Array = deathbox_data.get("items", [])
		if drag_item.get("type") == "weapon" and target_kind == "weapon":
			var target_w_idx: int = int(hovered_slot.get("wep_idx", 0))
			var old_slot: Dictionary = PlayerState.loadout[target_w_idx]
			var old_wid: String = str(old_slot.get("weapon_id", "empty"))
			var new_wid: String = str(drag_item.get("id", ""))
			var new_wep: Dictionary = GameData.get_weapon_by_id(new_wid)
			var new_data: Dictionary = drag_item.get("weapon_data", {
				"weapon_id": new_wid,
				"ammo": int(new_wep.get("mag", 20)),
				"max_ammo": int(new_wep.get("mag", 20)),
				"optic": "2x_bruiser",
				"charged": 0.0
			})
			if old_wid != "empty":
				d_items[drag_from_idx] = {
					"type": "weapon",
					"id": old_wid,
					"name": str(GameData.get_weapon_by_id(old_wid).get("name", old_wid)),
					"count": 1,
					"ammo": int(old_slot.get("ammo", 0)),
					"weapon_data": old_slot.duplicate(true)
				}
			else:
				d_items.remove_at(drag_from_idx)
			PlayerState.loadout[target_w_idx] = new_data.duplicate(true)
			AudioSynthesizer.play_reload_step("bolt_slap")
			PlayerState.toast_pushed.emit("🔫 已从战利品箱装备【%s】！" % str(new_wep.get("name", new_wid)), "evo")
			PlayerState.state_updated.emit()
			return
		elif drag_item.get("type") == "attachment" and target_kind == "weapon":
			var target_w_idx: int = int(hovered_slot.get("wep_idx", 0))
			_equip_attachment_to_weapon(target_w_idx, drag_item)
			d_items.remove_at(drag_from_idx)
			AudioSynthesizer.play_reload_step("lever_cock")
			PlayerState.toast_pushed.emit("✨ 已装备战利品配件！", "evo")
			PlayerState.state_updated.emit()
			return
		else:
			if drag_from_idx >= 0 and drag_from_idx < d_items.size():
				var it: Dictionary = d_items[drag_from_idx]
				PlayerState.inventory_items.append(it)
				d_items.remove_at(drag_from_idx)
				AudioSynthesizer.play_reload_step("mag_in")
				PlayerState.toast_pushed.emit("拾取战利品：【%s】" % _get_item_display_name(str(it.get("id", "物资"))), "evo")
				PlayerState.state_updated.emit()
				return

	# 4. Dragging from Backpack Inventory
	elif drag_from_type == "inventory":
		if drag_item.get("type") == "attachment" and target_kind == "weapon":
			var target_w_idx: int = int(hovered_slot.get("wep_idx", 0))
			_equip_attachment_to_weapon(target_w_idx, drag_item)
			if drag_from_idx >= 0 and drag_from_idx < PlayerState.inventory_items.size():
				PlayerState.inventory_items.remove_at(drag_from_idx)
			AudioSynthesizer.play_reload_step("lever_cock")
			PlayerState.toast_pushed.emit("✨ 已将背包配件安装至武器！", "evo")
			PlayerState.state_updated.emit()
			return
		elif target_kind == "item" or target_kind == "backpack_empty":
			var target_idx: int = int(hovered_slot.get("index", -1))
			if target_idx >= 0 and target_idx != drag_from_idx:
				if target_idx < PlayerState.inventory_items.size():
					var temp: Dictionary = PlayerState.inventory_items[drag_from_idx]
					PlayerState.inventory_items[drag_from_idx] = PlayerState.inventory_items[target_idx]
					PlayerState.inventory_items[target_idx] = temp
				else:
					var it: Dictionary = PlayerState.inventory_items[drag_from_idx]
					PlayerState.inventory_items.remove_at(drag_from_idx)
					PlayerState.inventory_items.append(it)
				AudioSynthesizer.play_reload_step("lever_cock")
				PlayerState.state_updated.emit()
				return
		elif target_kind == "weapon":
			var w_idx: int = int(hovered_slot.get("wep_idx", 0))
			var it_id: String = str(drag_item.get("id", ""))
			if it_id.begins_with("3x") or it_id.begins_with("2x") or it_id.begins_with("1x"):
				PlayerState.loadout[w_idx]["optic"] = it_id
				AudioSynthesizer.play_reload_step("lever_cock")
				PlayerState.toast_pushed.emit("已装备瞄具至槽位 [%d]" % (w_idx + 1), "evo")
				PlayerState.state_updated.emit()
				return
		elif target_kind == "":
			# Dropped outside UI onto game world: DROP ITEM!
			var it_id: String = str(drag_item.get("id", ""))
			var it_count: int = int(drag_item.get("count", 1))
			AudioSynthesizer.play_reload_step("mag_out")
			item_dropped.emit(it_id)
			if it_count > 1:
				drag_item["count"] = it_count - 1
			else:
				if drag_from_idx >= 0 and drag_from_idx < PlayerState.inventory_items.size():
					PlayerState.inventory_items.remove_at(drag_from_idx)
			PlayerState.toast_pushed.emit("📦 已丢弃物品：【%s】" % _get_item_display_name(it_id), "info")
			PlayerState.state_updated.emit()

func _handle_mouse_click(mpos: Vector2, button_idx: int) -> void:
	if hovered_slot.is_empty():
		return

	var kind: String = str(hovered_slot.get("kind", ""))
	if kind == "tab":
		var tname: String = str(hovered_slot["tab_name"])
		if tname == "物品栏": active_tab = "inventory"
		elif tname == "小队": active_tab = "squad"
		elif tname == "传奇": active_tab = "legends"
		AudioSynthesizer.play_reload_step("lever_cock")
		queue_redraw()
		return

	if kind == "deathbox_armor_swap":
		_execute_armor_swap()
		return

	if kind == "weapon":
		var w_idx: int = int(hovered_slot["wep_idx"])
		if button_idx == MOUSE_BUTTON_RIGHT:
			_drop_weapon(w_idx, true)
		elif button_idx == MOUSE_BUTTON_LEFT:
			PlayerState.active_slot = w_idx
			AudioSynthesizer.play_reload_step("lever_cock")
			var wid: String = str(PlayerState.loadout[w_idx].get("weapon_id", "empty"))
			if wid != "empty":
				PlayerState.toast_pushed.emit("🔫 已切换主手武器：[%d 槽位] 【%s】" % [w_idx + 1, str(GameData.get_weapon_by_id(wid).get("name", wid))], "info")
			PlayerState.state_updated.emit()
			queue_redraw()
		return

	if kind == "attachment":
		var w_idx: int = int(hovered_slot["wep_idx"])
		var ak: String = str(hovered_slot["att_type"])
		if button_idx == MOUSE_BUTTON_RIGHT:
			_detach_attachment_to_inventory(w_idx, ak, false)
		elif button_idx == MOUSE_BUTTON_LEFT and ak == "optic":
			# Cycle optical zoom or next optic
			PlayerState.scope_alt_zoom = not PlayerState.scope_alt_zoom
			AudioSynthesizer.play_reload_step("lever_cock")
			queue_redraw()
		return

	if kind == "deathbox_item":
		var idx: int = int(hovered_slot["index"])
		var d_items: Array = deathbox_data.get("items", [])
		if idx >= 0 and idx < d_items.size():
			var it: Dictionary = d_items[idx]
			if str(it.get("type", "")) == "weapon":
				# Click on deathbox weapon equips into current or empty slot!
				var target_slot: int = PlayerState.active_slot
				if target_slot == 2 or str(PlayerState.loadout[clampi(target_slot, 0, 1)].get("weapon_id", "empty")) == "empty":
					if str(PlayerState.loadout[0].get("weapon_id", "empty")) == "empty":
						target_slot = 0
					elif str(PlayerState.loadout[1].get("weapon_id", "empty")) == "empty":
						target_slot = 1
					else:
						target_slot = 0
				var old_slot: Dictionary = PlayerState.loadout[target_slot]
				var old_wid: String = str(old_slot.get("weapon_id", "empty"))
				var new_wid: String = str(it.get("id", ""))
				var new_wep: Dictionary = GameData.get_weapon_by_id(new_wid)
				var new_data: Dictionary = it.get("weapon_data", {
					"weapon_id": new_wid,
					"ammo": int(new_wep.get("mag", 20)),
					"max_ammo": int(new_wep.get("mag", 20)),
					"optic": "2x_bruiser",
					"charged": 0.0
				})
				if old_wid != "empty":
					d_items[idx] = {
						"type": "weapon",
						"id": old_wid,
						"name": str(GameData.get_weapon_by_id(old_wid).get("name", old_wid)),
						"count": 1,
						"ammo": int(old_slot.get("ammo", 0)),
						"weapon_data": old_slot.duplicate(true)
					}
				else:
					d_items.remove_at(idx)
				PlayerState.loadout[target_slot] = new_data.duplicate(true)
				PlayerState.active_slot = target_slot
				AudioSynthesizer.play_reload_step("bolt_slap")
				PlayerState.toast_pushed.emit("🔫 已从战利品箱装备【%s】！" % str(new_wep.get("name", new_wid)), "evo")
			else:
				PlayerState.inventory_items.append(it)
				d_items.remove_at(idx)
				AudioSynthesizer.play_reload_step("mag_in")
				PlayerState.toast_pushed.emit("拾取战利品：【%s】" % _get_item_display_name(str(it.get("id", "物资"))), "evo")
			PlayerState.state_updated.emit()
			hovered_slot = {}
			queue_redraw()
		return

	if kind == "item":
		var idx: int = int(hovered_slot["index"])
		var it: Dictionary = hovered_slot["item"]
		var it_type: String = str(it.get("type", ""))
		var it_id: String = str(it.get("id", ""))

		if button_idx == MOUSE_BUTTON_LEFT:
			if it_type == "consumable":
				PlayerState.selected_heal_id = it_id
				close()
				consumable_used.emit(it_id)
				AudioSynthesizer.play_evo_level_up()
			elif it_type == "attachment" and it_id.begins_with("3x"):
				var active_wep: Dictionary = PlayerState.loadout[PlayerState.active_slot]
				active_wep["optic"] = "3x_ranger"
				AudioSynthesizer.play_reload_step("lever_cock")
				queue_redraw()
			elif it_type == "ammo":
				var w1: Dictionary = GameData.get_weapon_by_id(PlayerState.loadout[0]["weapon_id"])
				var w2: Dictionary = GameData.get_weapon_by_id(PlayerState.loadout[1]["weapon_id"])
				if it_id == str(w1["ammo"]) or it_id == str(w2["ammo"]):
					AudioSynthesizer.play_reload_step("mag_in")
		elif button_idx == MOUSE_BUTTON_RIGHT:
			AudioSynthesizer.play_reload_step("mag_out")
			item_dropped.emit(it_id)
			if int(it.get("count", 1)) > 1:
				it["count"] = int(it["count"]) - 1
			else:
				PlayerState.inventory_items.remove_at(idx)
			hovered_slot = {}
			queue_redraw()

func _draw() -> void:
	if not visible:
		return

	var vp := get_viewport_rect().size

	# 1. Full-Screen Translucent Apex Vignette & Blur Glass Overlay
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.04, 0.07, 0.88), true)
	draw_rect(Rect2(0, 0, vp.x, 60), Color(0.01, 0.02, 0.04, 0.95), true)
	draw_rect(Rect2(0, vp.y - 70, vp.x, 70), Color(0.01, 0.02, 0.04, 0.95), true)

	# 2. Top Navigation Tabs: [物品栏] [小队] [传奇]
	_draw_top_tabs(vp)

	# 3. Deathbox Looting Panel (if deathbox is open)
	if is_deathbox_mode and not deathbox_data.is_empty():
		_draw_deathbox_panel(vp)

	# 4. Weapons & Backpack & Gear Cards
	_draw_weapon_cards(vp)
	_draw_backpack_grid(vp)
	_draw_equipment_bar(vp)

	# 5. Bottom-Left Squad & Player Status HUD
	_draw_squad_player_hud(vp)

	# 6. Bottom-Right Hints
	_draw_footer_hints(vp)

	# 7. Drag-and-Drop Ghost Card
	if is_dragging and not drag_item.is_empty():
		_draw_drag_ghost(drag_pos)

	# 8. Floating Hover Tooltip Card
	if not is_dragging:
		_draw_hover_tooltip(vp)

## ============================================================================
## 1. Top Navigation Tabs
## ============================================================================
func _draw_top_tabs(vp: Vector2) -> void:
	var tab_w: float = 120.0
	var tab_y: float = 24.0
	var tabs := ["物品栏", "小队", "传奇"]
	var tab_start_x: float = vp.x * 0.5 - (tab_w * 3.0 * 0.5)

	draw_rect(Rect2(tab_start_x - 12, tab_y - 4, tab_w * 3.0 + 24, 40), Color(0.06, 0.09, 0.14, 0.75), true)

	for i in range(tabs.size()):
		var tname: String = tabs[i]
		var is_active: bool = (tname == "物品栏" and active_tab == "inventory") or (tname == "小队" and active_tab == "squad") or (tname == "传奇" and active_tab == "legends")
		var tx: float = tab_start_x + float(i) * tab_w

		if is_active:
			var poly := PackedVector2Array([
				Vector2(tx + 8, tab_y),
				Vector2(tx + tab_w - 8, tab_y),
				Vector2(tx + tab_w, tab_y + 30),
				Vector2(tx, tab_y + 30)
			])
			draw_colored_polygon(poly, Color("#dc2626"))
			draw_line(Vector2(tx, tab_y + 32), Vector2(tx + tab_w, tab_y + 32), Color("#ef4444"), 3.0)

		var col: Color = Color.WHITE if is_active else Color("#94a3b8")
		var font := ThemeDB.fallback_font
		var str_w := font.get_string_size(tname, HORIZONTAL_ALIGNMENT_CENTER, -1, 15).x
		draw_string(font, Vector2(tx + (tab_w - str_w) * 0.5, tab_y + 20), tname, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)

## ============================================================================
## 2. Authentic Apex Deathbox Panel (击杀成盒搜刮 & 一键秒换甲)
## ============================================================================
func _draw_deathbox_panel(_vp: Vector2) -> void:
	var v_name: String = str(deathbox_data.get("victim_name", "外域战士"))
	var box_tier: int = int(deathbox_data.get("evo_tier", 3))
	var tier_info: Dictionary = GameData.get_evo_tier(box_tier)
	var tier_col: Color = tier_info["color"]
	var is_swapped: bool = bool(deathbox_data.get("armor_swapped", false))

	var db_rect := Rect2(32, 78, 365, 545)
	_draw_chamfered_card(db_rect, Color(0.04, 0.07, 0.12, 0.96), tier_col if not is_swapped else Color("#475569"), 2.2)

	# Deathbox Header Card
	var hdr_rect := Rect2(42, 88, 345, 36)
	draw_rect(hdr_rect, Color(tier_col.r, tier_col.g, tier_col.b, 0.28), true)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(52, 112), "💀 %s 的死亡之箱" % v_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

	# --- PURE GRAPHICAL ONE-CLICK ARMOR SWAP (一键秒换甲) ---
	var ar_rect := Rect2(42, 135, 345, 75)
	var is_ar_hover: bool = (hovered_slot.get("kind", "") == "deathbox_armor_swap")
	_draw_rounded_slot_box(ar_rect, Color(0.08, 0.12, 0.19, 0.95), Color("#fbbf24") if is_ar_hover else (tier_col if not is_swapped else Color("#334155")), 2.5 if is_ar_hover else 1.8)

	# Large Hexagonal Shield Badge on Left of Armor Swap Card
	var s_center := Vector2(ar_rect.position.x + 36, ar_rect.position.y + 37)
	_draw_gear_icon(s_center, "armor", box_tier, tier_col if not is_swapped else Color("#64748b"))

	# Armor Name & Max Shield
	draw_string(font, Vector2(ar_rect.position.x + 72, ar_rect.position.y + 26), "Lv.%d %s护甲核心" % [box_tier, str(tier_info["name"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, tier_col if not is_swapped else Color("#94a3b8"))

	# Full 100% Shield Segments Bar
	var seg_start_x: float = ar_rect.position.x + 72
	var seg_y: float = ar_rect.position.y + 36
	var num_segs: int = int(tier_info["segments"])
	for s_i in range(num_segs):
		var sb_r := Rect2(seg_start_x + float(s_i) * 26.0, seg_y, 22.0, 9.0)
		draw_rect(sb_r, tier_col if not is_swapped else Color("#475569"), true)
		draw_rect(sb_r, Color.WHITE, false, 1.0)

	# One-Click Armor Swap Action Tag
	var action_txt: String = "⚡ 点击一键秒换甲" if not is_swapped else "✓ 已秒换"
	var action_col: Color = Color("#fde047") if not is_swapped else Color("#64748b")
	draw_string(font, Vector2(ar_rect.position.x + 72, ar_rect.position.y + 64), action_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, action_col)

	# Deathbox Loot Items Grid
	draw_string(font, Vector2(44, 228), "战利品（点击直接拾取 / 拖入背包）：", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#94a3b8"))

	var d_items: Array = deathbox_data.get("items", [])
	var d_start_x: float = 42.0
	var d_start_y: float = 238.0
	var d_slot_w: float = 168.0
	var d_slot_h: float = 56.0
	var d_gap: float = 9.0

	for di in range(min(8, d_items.size())):
		var c_i: int = di % 2
		var r_i: int = di / 2
		var dr := Rect2(d_start_x + float(c_i) * (d_slot_w + d_gap), d_start_y + float(r_i) * (d_slot_h + d_gap), d_slot_w, d_slot_h)
		var is_h: bool = (hovered_slot.get("kind", "") == "deathbox_item" and int(hovered_slot.get("index", -1)) == di)
		_draw_rounded_slot_box(dr, Color(0.06, 0.10, 0.16, 0.92), Color("#38bdf8") if is_h else Color("#334155"), 2.0 if is_h else 1.2)

		var it: Dictionary = d_items[di]
		var it_t: String = str(it.get("type", ""))
		var it_i: String = str(it.get("id", ""))
		var it_cnt: int = int(it.get("count", 1))

		# Icon on Left
		var icon_r := Rect2(dr.position.x + 4, dr.position.y + 4, 48, 48)
		_draw_inventory_item_icon(icon_r, it_t, it_i, it)

		# Name & Quantity on Right
		var iname: String = _get_item_display_name(it_i)
		draw_string(font, Vector2(dr.position.x + 56, dr.position.y + 26), iname, HORIZONTAL_ALIGNMENT_LEFT, 105, 12, Color.WHITE)
		if it_cnt > 1:
			draw_string(font, Vector2(dr.position.x + 56, dr.position.y + 44), "x%d" % it_cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#fde047"))

## ============================================================================
## 3. Dual Weapon Cards
## ============================================================================
func _draw_weapon_cards(vp: Vector2) -> void:
	var wep_y: float = 78.0
	var wep_w: float = minf(410.0, vp.x * 0.36) if is_deathbox_mode else minf(460.0, vp.x * 0.43)
	var wep_h: float = 185.0
	var w_offset_x: float = 410.0 if is_deathbox_mode else 0.0

	var w1_rect := Rect2((vp.x * 0.5 - wep_w - 14.0) + (w_offset_x * 0.45 if is_deathbox_mode else 0.0), wep_y, wep_w, wep_h)
	var w2_rect := Rect2((vp.x * 0.5 + 14.0) + (w_offset_x * 0.45 if is_deathbox_mode else 0.0), wep_y, wep_w, wep_h)

	var font := ThemeDB.fallback_font

	for w_idx in [0, 1]:
		var wr: Rect2 = w1_rect if w_idx == 0 else w2_rect
		var is_equipped: bool = (PlayerState.active_slot == w_idx)
		var slot_data: Dictionary = PlayerState.loadout[w_idx]
		var wid: String = str(slot_data.get("weapon_id", "empty"))
		var is_empty: bool = (wid == "empty" or wid == "")
		var wep: Dictionary = GameData.get_weapon_by_id(wid) if not is_empty else {}
		var ammo_type: String = str(wep.get("ammo", "light")) if not is_empty else "light"
		var ammo_col := _get_ammo_color(ammo_type) if not is_empty else Color("#64748b")

		# Check drag-over status
		var is_drag_target: bool = false
		var drag_target_hint: String = ""
		if is_dragging:
			var hkind: String = str(hovered_slot.get("kind", ""))
			var hw_idx: int = int(hovered_slot.get("wep_idx", -1))
			if (hkind == "weapon" or hkind == "attachment") and hw_idx == w_idx:
				if drag_from_type == "weapon":
					if drag_from_idx != w_idx:
						is_drag_target = true
						drag_target_hint = "🔄 释放以交换槽位" if not is_empty else "➕ 释放以装备至此槽位"
				elif drag_from_type == "attachment" or (drag_item.get("type") == "attachment"):
					if not is_empty:
						is_drag_target = true
						drag_target_hint = "🔧 释放以安装配件"
				elif drag_from_type == "deathbox" and drag_item.get("type") == "weapon":
					is_drag_target = true
					drag_target_hint = "🔫 释放以替换装备"

		var border_col: Color = ammo_col if is_equipped else Color("#334155")
		var border_w: float = 2.0 if is_equipped else 1.2
		if is_drag_target:
			border_col = Color("#fbbf24")
			border_w = 3.0

		var bg_col: Color = Color(0.06, 0.09, 0.15, 0.92) if not is_empty else Color(0.04, 0.06, 0.10, 0.75)
		if is_dragging and drag_from_type == "weapon" and drag_from_idx == w_idx:
			bg_col = Color(0.03, 0.04, 0.07, 0.6) # dimmed while dragged

		_draw_chamfered_card(wr, bg_col, border_col, border_w)

		# Top tag: [1 武器] / [2 武器]
		var tag_rect := Rect2(wr.position.x + 12, wr.position.y + 10, 68, 20)
		draw_rect(tag_rect, ammo_col if is_equipped and not is_empty else Color("#1e293b"), true)
		draw_string(font, Vector2(tag_rect.position.x + 8, tag_rect.position.y + 14), "[%d 武器]" % (w_idx + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE if is_equipped else Color("#cbd5e1"))

		if not is_empty:
			draw_string(font, Vector2(wr.position.x + 88, wr.position.y + 24), str(wep.get("name", wid)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

			var sil_rect := Rect2(wr.position.x + 16, wr.position.y + 36, wr.size.x - 120, 80)
			_draw_weapon_silhouette(sil_rect, str(wep.get("id", "")), str(wep.get("cat", "AR")), ammo_col)

			var ammo_x: float = wr.position.x + wr.size.x - 72.0
			var ammo_str: String = "%d" % int(slot_data.get("ammo", 0))
			var num_w := font.get_string_size(ammo_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 28).x
			draw_string(font, Vector2(ammo_x + (44.0 - num_w) * 0.5, wr.position.y + 54), ammo_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)

			var badge_center := Vector2(ammo_x + 22.0, wr.position.y + 90.0)
			_draw_ammo_badge(badge_center, ammo_type, 17.0)
		else:
			# Empty slot visuals
			draw_string(font, Vector2(wr.position.x + 88, wr.position.y + 24), "[空武器槽位]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#64748b"))
			var hint_empty: String = "拖入战利品箱武器 或 地面捡取"
			draw_string(font, Vector2(wr.position.x + 24, wr.position.y + 75), hint_empty, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#475569"))
			var ammo_x: float = wr.position.x + wr.size.x - 72.0
			draw_string(font, Vector2(ammo_x + 10, wr.position.y + 54), "--", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#475569"))

		# Drag-over target indicator banner
		if is_drag_target and drag_target_hint != "":
			var h_r := Rect2(wr.position.x + 10, wr.position.y + 40, wr.size.x - 20, 32)
			draw_rect(h_r, Color(0.98, 0.75, 0.14, 0.35), true)
			draw_rect(h_r, Color("#fbbf24"), false, 1.5)
			var tw: float = font.get_string_size(drag_target_hint, HORIZONTAL_ALIGNMENT_CENTER, -1, 14).x
			draw_string(font, Vector2(h_r.position.x + (h_r.size.x - tw) * 0.5, h_r.position.y + 22), drag_target_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

		# 5 Attachment Slots
		var att_types := ["barrel", "mag", "optic", "stock", "hopup"]
		var slot_sz: float = 38.0
		var gap: float = 8.0
		var att_y: float = wr.position.y + wr.size.y - 48.0
		for a_i in range(att_types.size()):
			var ak: String = att_types[a_i]
			var tier: int = int(slot_data.get(ak, 0)) if not is_empty else 0
			var ar := Rect2(wr.position.x + 14.0 + float(a_i) * (slot_sz + gap), att_y, slot_sz, slot_sz)
			_draw_attachment_slot(ar, ak, tier, str(slot_data.get("optic", "")) if not is_empty else "")

## ============================================================================
## 4. Middle Section: Backpack Grid
## ============================================================================
func _draw_backpack_grid(vp: Vector2) -> void:
	var slot_sz: float = 56.0
	var gap: float = 10.0
	var cols: int = 8
	var w_offset_x: float = 410.0 if is_deathbox_mode else 0.0
	var grid_shift_x: float = (w_offset_x * 0.45) if is_deathbox_mode else 0.0
	var start_x: float = (vp.x * 0.5 - (float(cols) * slot_sz + float(cols - 1) * gap) * 0.5) + grid_shift_x
	var start_y: float = 295.0

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(start_x, start_y - 10), "背包物品（可鼠标拖动换位/丢弃，左键使用，右键丢弃）：", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#cbd5e1"))

	var w1: Dictionary = GameData.get_weapon_by_id(PlayerState.loadout[0]["weapon_id"])
	var w2: Dictionary = GameData.get_weapon_by_id(PlayerState.loadout[1]["weapon_id"])
	var active_ammos := [str(w1.get("ammo", "")), str(w2.get("ammo", ""))]

	var total_slots: int = 16
	for i in range(total_slots):
		var col: int = i % cols
		var row: int = i / cols
		var sr := Rect2(start_x + float(col) * (slot_sz + gap), start_y + float(row) * (slot_sz + gap), slot_sz, slot_sz)

		var is_hover: bool = (hovered_slot.get("kind", "") == "item" and int(hovered_slot.get("index", -1)) == i)
		_draw_rounded_slot_box(sr, Color(0.08, 0.12, 0.18, 0.88), Color("#38bdf8") if is_hover else Color("#334155"), 2.0 if is_hover else 1.0)

		if i < PlayerState.inventory_items.size():
			var it: Dictionary = PlayerState.inventory_items[i]
			var it_type: String = str(it.get("type", ""))
			var it_id: String = str(it.get("id", ""))
			var count: int = int(it.get("count", 1))

			_draw_inventory_item_icon(sr, it_type, it_id, it)

			if count > 1:
				var c_str: String = "%d" % count
				draw_string(font, Vector2(sr.position.x + sr.size.x - 18, sr.position.y + sr.size.y - 6), c_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 12, Color.WHITE)

			if it_type == "ammo" and not active_ammos.has(it_id):
				_draw_incompatible_slash(Vector2(sr.position.x + 12, sr.position.y + 12), 7.5)
			elif it_type == "attachment" and it_id.begins_with("mag_heavy") and not active_ammos.has("heavy"):
				_draw_incompatible_slash(Vector2(sr.position.x + 12, sr.position.y + 12), 7.5)
		else:
			var lock_col := Color(0.2, 0.28, 0.38, 0.35)
			draw_circle(sr.get_center(), 6.0, lock_col)

## ============================================================================
## 5. Bottom Section: Equipment Gear Slots
## ============================================================================
func _draw_equipment_bar(vp: Vector2) -> void:
	var eq_slots := ["helmet", "armor", "knockdown", "backpack", "survival"]
	var eq_sz: float = 58.0
	var eq_gap: float = 16.0
	var w_offset_x: float = 410.0 if is_deathbox_mode else 0.0
	var grid_shift_x: float = (w_offset_x * 0.45) if is_deathbox_mode else 0.0
	var eq_start_x: float = (vp.x * 0.5 - (float(eq_slots.size()) * eq_sz + float(eq_slots.size() - 1) * eq_gap) * 0.5) + grid_shift_x
	var eq_y: float = 460.0

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(eq_start_x, eq_y - 10), "穿戴护甲与装备：", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#cbd5e1"))

	for i in range(eq_slots.size()):
		var ek: String = eq_slots[i]
		var er := Rect2(eq_start_x + float(i) * (eq_sz + eq_gap), eq_y, eq_sz, eq_sz)
		var is_hover: bool = (hovered_slot.get("kind", "") == "equipment" and hovered_slot.get("gear_type", "") == ek)

		var tier: int = PlayerState.evo_level if ek == "armor" else int(PlayerState.gear.get(ek, 2))
		var tier_col := _get_tier_color(tier)

		_draw_rounded_slot_box(er, Color(0.06, 0.10, 0.16, 0.92), tier_col, 2.5 if is_hover else 1.8)
		_draw_gear_icon(er.get_center(), ek, tier, tier_col)

## ============================================================================
## 6. Drag Ghost Follower
## ============================================================================
func _draw_drag_ghost(pos: Vector2) -> void:
	var font := ThemeDB.fallback_font
	if drag_from_type == "weapon":
		var wid: String = str(drag_item.get("weapon_id", "empty"))
		var wep: Dictionary = GameData.get_weapon_by_id(wid)
		var ammo_type: String = str(wep.get("ammo", "light"))
		var ammo_col: Color = _get_ammo_color(ammo_type)
		var gw: float = 230.0
		var gh: float = 78.0
		var g_rect := Rect2(pos.x - gw * 0.5, pos.y - gh * 0.5, gw, gh)
		_draw_chamfered_card(g_rect, Color(0.08, 0.12, 0.20, 0.96), ammo_col, 2.5)

		# Tag & Name
		draw_rect(Rect2(g_rect.position.x + 8, g_rect.position.y + 8, 48, 18), ammo_col, true)
		draw_string(font, Vector2(g_rect.position.x + 12, g_rect.position.y + 22), "武器", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		draw_string(font, Vector2(g_rect.position.x + 62, g_rect.position.y + 22), str(wep.get("name", wid)), HORIZONTAL_ALIGNMENT_LEFT, 150, 14, Color.WHITE)

		# Mini silhouette / Ammo
		var sil_r := Rect2(g_rect.position.x + 12, g_rect.position.y + 32, 110, 38)
		_draw_weapon_silhouette(sil_r, wid, str(wep.get("cat", "AR")), ammo_col)

		# Ammo badge and count
		var badge_c := Vector2(g_rect.position.x + gw - 32, g_rect.position.y + 44)
		_draw_ammo_badge(badge_c, ammo_type, 14.0)
		var ammo_str: String = "%d" % int(drag_item.get("ammo", 0))
		draw_string(font, Vector2(g_rect.position.x + gw - 64, g_rect.position.y + 50), ammo_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 16, Color.WHITE)

		# Hint below
		draw_string(font, Vector2(pos.x - 120, pos.y + gh * 0.5 + 16), "【拖至另一武器槽交换 / 拖出丢弃】", HORIZONTAL_ALIGNMENT_CENTER, 240, 11, Color("#fde047"))

	elif drag_from_type == "attachment":
		var ak: String = str(drag_item.get("att_type", "barrel"))
		var tier: int = int(drag_item.get("tier", 1))
		var tier_col: Color = _get_tier_color(tier)
		var sz: float = 64.0
		var g_rect := Rect2(pos.x - sz * 0.5, pos.y - sz * 0.5, sz, sz)
		_draw_rounded_slot_box(g_rect, Color(0.08, 0.12, 0.20, 0.95), tier_col, 2.5)
		_draw_attachment_slot(g_rect, ak, tier, str(drag_item.get("optic_id", "")))
		draw_string(font, Vector2(pos.x - 80, pos.y + sz * 0.5 + 16), "【拖至武器安装 / 移入背包】", HORIZONTAL_ALIGNMENT_CENTER, 160, 11, Color("#fde047"))

	else:
		# Backpack or Deathbox
		if drag_item.get("type") == "weapon":
			var wid: String = str(drag_item.get("id", ""))
			var wep: Dictionary = GameData.get_weapon_by_id(wid)
			var ammo_type: String = str(wep.get("ammo", "light"))
			var ammo_col: Color = _get_ammo_color(ammo_type)
			var gw: float = 210.0
			var gh: float = 72.0
			var g_rect := Rect2(pos.x - gw * 0.5, pos.y - gh * 0.5, gw, gh)
			_draw_chamfered_card(g_rect, Color(0.08, 0.12, 0.20, 0.96), ammo_col, 2.5)
			draw_string(font, Vector2(g_rect.position.x + 12, g_rect.position.y + 22), str(wep.get("name", wid)), HORIZONTAL_ALIGNMENT_LEFT, 180, 14, Color.WHITE)
			var sil_r := Rect2(g_rect.position.x + 12, g_rect.position.y + 28, 100, 36)
			_draw_weapon_silhouette(sil_r, wid, str(wep.get("cat", "AR")), ammo_col)
			_draw_ammo_badge(Vector2(g_rect.position.x + gw - 28, g_rect.position.y + 44), ammo_type, 13.0)
			draw_string(font, Vector2(pos.x - 80, pos.y + gh * 0.5 + 16), "【拖至武器槽装备】", HORIZONTAL_ALIGNMENT_CENTER, 160, 11, Color("#fde047"))
		else:
			var g_rect := Rect2(pos.x - 30, pos.y - 30, 60, 60)
			_draw_rounded_slot_box(g_rect, Color(0.12, 0.18, 0.28, 0.92), Color("#38bdf8"), 2.5)
			var it_type: String = str(drag_item.get("type", ""))
			var it_id: String = str(drag_item.get("id", ""))
			_draw_inventory_item_icon(g_rect, it_type, it_id, drag_item)
			draw_string(font, Vector2(pos.x - 60, pos.y + 45), "[拖动中...]", HORIZONTAL_ALIGNMENT_CENTER, 120, 11, Color("#fde047"))

## ============================================================================
## 7. Squad & Player HUD and Footer
## ============================================================================
func _draw_squad_player_hud(vp: Vector2) -> void:
	var leg: Dictionary = GameData.get_legend_by_id(PlayerState.selected_legend_id)
	var tier: Dictionary = GameData.get_evo_tier(PlayerState.evo_level)
	var tier_col: Color = tier["color"]

	var panel_rect := Rect2(42, vp.y - 120, 360, 95)
	_draw_chamfered_card(panel_rect, Color(0.04, 0.07, 0.12, 0.92), Color("#334155"), 1.5)

	# Legend Portrait Silhouette Box
	var port_r := Rect2(panel_rect.position.x + 12, panel_rect.position.y + 12, 60, 70)
	draw_rect(port_r, Color(tier_col.r, tier_col.g, tier_col.b, 0.25), true)
	draw_rect(port_r, tier_col, false, 1.8)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(port_r.position.x + 8, port_r.position.y + 42), "传奇", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

	# Name & Shield HP
	draw_string(font, Vector2(panel_rect.position.x + 84, panel_rect.position.y + 28), str(leg["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

	var seg_box_x: float = panel_rect.position.x + 84
	var seg_box_y: float = panel_rect.position.y + 38
	var segs: int = int(tier["segments"])
	for s in range(segs):
		var sb_r := Rect2(seg_box_x + float(s) * 34.0, seg_box_y, 28.0, 10.0)
		draw_rect(sb_r, Color(0.12, 0.18, 0.24, 0.9), true)
		var fill_amt: float = clampf((PlayerState.shield - float(s * 25)) / 25.0, 0.0, 1.0)
		draw_rect(Rect2(sb_r.position.x, sb_r.position.y, sb_r.size.x * fill_amt, sb_r.size.y), tier_col, true)
		draw_rect(sb_r, Color.WHITE, false, 1.0)

	# HP Bar
	var hp_r := Rect2(seg_box_x, seg_box_y + 18, 160.0, 10.0)
	draw_rect(hp_r, Color(0.15, 0.2, 0.25), true)
	draw_rect(Rect2(hp_r.position.x, hp_r.position.y, hp_r.size.x * (PlayerState.hp / 100.0), hp_r.size.y), Color("#22c55e"), true)
	draw_rect(hp_r, Color.WHITE, false, 1.0)

func _draw_footer_hints(vp: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var hint_str: String = "⚡ 拖动物品/枪械以换位/装备/丢弃  |  [左键] 使用恢复品  |  [右键] 丢弃单个/枪械  |  [TAB / ESC] 关闭"
	var hw := font.get_string_size(hint_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 13).x
	draw_string(font, Vector2((vp.x - hw) * 0.5, vp.y - 25), hint_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#94a3b8"))

## ============================================================================
## 8. Hover Tooltip Card
## ============================================================================
func _draw_hover_tooltip(vp: Vector2) -> void:
	if hovered_slot.is_empty():
		return

	var kind: String = str(hovered_slot.get("kind", ""))
	var title: String = ""
	var desc: String = ""
	var action: String = ""
	var tier_col: Color = Color("#38bdf8")

	if kind == "weapon":
		var w_idx: int = int(hovered_slot.get("wep_idx", 0))
		var s_data: Dictionary = PlayerState.loadout[w_idx]
		var wid: String = str(s_data.get("weapon_id", "empty"))
		if wid != "empty" and wid != "":
			var w_info: Dictionary = GameData.get_weapon_by_id(wid)
			title = "【%d 武器】%s" % [w_idx + 1, str(w_info.get("name", wid))]
			var ammo_str: String = "轻型" if str(w_info.get("ammo")) == "light" else ("重型" if str(w_info.get("ammo")) == "heavy" else ("能量" if str(w_info.get("ammo")) == "energy" else ("霰弹" if str(w_info.get("ammo")) == "shotgun" else "狙击")))
			desc = "%s枪械 · 弹药: %s · 当前载弹: %d\n左键拖动可与另一槽位交换，拖出丢至地面。" % [
				str(w_info.get("cat", "突击步枪")),
				ammo_str,
				int(s_data.get("ammo", 0))
			]
			action = "【左键拖动】交换槽位/存箱  【右键】丢弃至地面"
			tier_col = _get_ammo_color(str(w_info.get("ammo", "light")))
		else:
			title = "【%d 武器】空武器槽" % (w_idx + 1)
			desc = "当前未装备武器。可从战利品箱或地面拾取武器拖入装备。"
			action = "【拖入武器】装备至此槽位"
			tier_col = Color("#64748b")

	elif kind == "deathbox_armor_swap":
		var b_tier: int = int(hovered_slot.get("tier", 3))
		var is_sw: bool = bool(hovered_slot.get("swapped", false))
		var t_info := GameData.get_evo_tier(b_tier)
		tier_col = t_info["color"]
		title = "⚡ 死亡之箱 · Lv.%d 进化护盾核心" % b_tier
		desc = "包含满额 %d 点护盾值！无需打大电，秒换恢复 100%% 战斗力！" % int(t_info["max_shield"])
		action = "【鼠标左键】 一键秒换甲！" if not is_sw else "【已秒换拾取】"

	elif kind == "deathbox_item":
		var it: Dictionary = hovered_slot["item"]
		var it_id: String = str(it.get("id", ""))
		var it_type: String = str(it.get("type", ""))
		if it_type == "weapon":
			var w_info := GameData.get_weapon_by_id(it_id)
			title = "🔫 %s" % str(w_info.get("name", it_id))
			desc = "战利品箱武器。载弹量: %d 发。\n点击直接装备至当前武器槽位，或拖拽选择槽位。" % int(it.get("ammo", 20))
			action = "【左键点击/拖拽】替换装备至武器槽"
			tier_col = _get_ammo_color(str(w_info.get("ammo", "light")))
		else:
			title = _get_item_display_name(it_id)
			desc = "战利品箱物资。点击直接拾取至背包，或拖入槽位。"
			action = "【鼠标左键】 立即拾取"
			tier_col = Color("#38bdf8")

	elif kind == "item":
		var it: Dictionary = hovered_slot["item"]
		var it_id: String = str(it.get("id", ""))
		match it_id:
			"light": title = "轻型弹药"; desc = "适用于 R-301、R-99 等轻型武器。"; tier_col = Color("#f97316")
			"heavy": title = "重型弹药"; desc = "适用于 VK-47 平行步枪、CAR 等重型武器。"; tier_col = Color("#14b8a6")
			"energy": title = "能量弹药"; desc = "适用于 哈沃克、复仇女神等能量武器。"; tier_col = Color("#84cc16")
			"shotgun": title = "霰弹枪弹药"; desc = "适用于 和平捍卫者、獒犬等霰弹枪。"; tier_col = Color("#ef4444")
			"sniper": title = "狙击弹药"; desc = "适用于 哨兵、充能步枪等狙击枪。"; tier_col = Color("#38bdf8")
			"shield_battery": title = "大型护盾电池 (大电)"; desc = "5.0秒完全充满所有护盾槽位。"; action = "[左键]立即打电  [右键]丢弃"; tier_col = Color("#38bdf8")
			"shield_cell": title = "小型护盾电池 (小电)"; desc = "3.0秒充能 1 格护盾 (25 HP)。"; action = "[左键]立即使用  [右键]丢弃"; tier_col = Color("#38bdf8")
			"med_kit": title = "医疗箱 (大药)"; desc = "8.0秒完全恢复所有失去的生命值。"; action = "[左键]立即使用  [右键]丢弃"; tier_col = Color("#22c55e")
			"syringe": title = "注射器 (小药)"; desc = "5.0秒恢复 25 点生命值。"; action = "[左键]立即使用  [右键]丢弃"; tier_col = Color("#22c55e")
			"phoenix_kit": title = "凤凰治疗包"; desc = "10.0秒完全恢复全部生命与所有护盾。"; action = "[左键]立即使用  [右键]丢弃"; tier_col = Color("#fbbf24")
			"arc_star": title = "电弧星"; desc = "吸附目标造成电击减速并破除护盾。"; tier_col = Color("#38bdf8")
			"frag": title = "破片手雷"; desc = "延时高爆破片手雷。"; tier_col = Color("#f97316")
			"thermite": title = "铝热剂手雷"; desc = "横向燃烧火墙持续灼烧。"; tier_col = Color("#ef4444")
			_: title = str(it.get("name", it_id)); desc = "战术战备物资。"; tier_col = _get_tier_color(int(it.get("tier", 2)))

	elif kind == "attachment":
		var ak: String = str(hovered_slot.get("att_type", ""))
		var tier: int = int(hovered_slot.get("tier", 0))
		var op_id: String = str(hovered_slot.get("optic_id", ""))
		tier_col = _get_tier_color(tier) if tier > 0 else Color("#94a3b8")
		if ak == "optic" and op_id != "":
			var op := GameData.get_optic_by_id(op_id)
			title = str(op.get("name", "瞄准镜"))
			desc = "高精度光学瞄准镜，提供清晰开镜视野。"
			action = "【左键拖动】转移至另一武器  【右键】卸下至背包"
		elif tier > 0:
			var att_names: Dictionary = {"barrel": "枪口补偿器", "mag": "加长弹匣", "stock": "战术枪托", "hopup": "专属枪械辅助芯片"}
			title = "Lv.%d %s" % [tier, att_names.get(ak, "配件")]
			match ak:
				"barrel": desc = "大幅降低后坐力水平与垂直散布。"
				"mag": desc = "大幅提高弹匣装弹量与战术换弹速度。"
				"stock": desc = "提升拔枪、收枪与瞄准操控速度。"
				"hopup": desc = "激发武器特殊强力攻击性能。"
			action = "【左键拖动】转移至另一武器  【右键】卸下至背包"
		else:
			var att_names: Dictionary = {"barrel": "枪口槽位", "mag": "弹匣槽位", "optic": "瞄准镜槽位", "stock": "枪托槽位", "hopup": "辅助器槽位"}
			title = "【空】%s" % att_names.get(ak, "配件槽位")
			desc = "当前未安装配件。可将背包或战利品中的配件拖入安装。"
			action = "【拖入配件】安装至武器"
			tier_col = Color("#64748b")

	elif kind == "equipment":
		var gk: String = str(hovered_slot["gear_type"])
		var tier: int = int(hovered_slot["tier"])
		tier_col = _get_tier_color(tier)
		match gk:
			"helmet": title = "战术防弹头盔 Lv.%d" % tier; desc = "大幅降低被爆头击中的额外伤害。"
			"armor": title = "进化护盾 Lv.%d" % tier; desc = "承受伤害，造成伤害即可持续自我进化！"
			"knockdown": title = "倒地护盾 Lv.%d" % tier; desc = "倒地状态展开高额定向防弹屏障。"
			"backpack": title = "战术背包 Lv.%d" % tier; desc = "扩展更多背包装备栏位空间。"
			"survival": title = "热能护盾 / 移动重生信标"; desc = "抵抗风暴辐射伤害或现场呼叫重生机。"

	if title == "":
		return

	var mpos: Vector2 = hovered_screen_pos + Vector2(18, 18)
	mpos.x = minf(mpos.x, vp.x - 290)
	mpos.y = minf(mpos.y, vp.y - 130)

	var card_r := Rect2(mpos.x, mpos.y, 280, 108)
	_draw_chamfered_card(card_r, Color(0.04, 0.07, 0.12, 0.96), tier_col, 2.0)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(card_r.position.x + 12, card_r.position.y + 24), title, HORIZONTAL_ALIGNMENT_LEFT, 255, 14, Color.WHITE)
	draw_string(font, Vector2(card_r.position.x + 12, card_r.position.y + 46), desc, HORIZONTAL_ALIGNMENT_LEFT, 255, 11, Color("#94a3b8"))
	if action != "":
		draw_string(font, Vector2(card_r.position.x + 12, card_r.position.y + 90), action, HORIZONTAL_ALIGNMENT_LEFT, 255, 11, Color("#fde047"))

## ============================================================================
## 9. Helper Vector Drawing Functions
## ============================================================================
func _get_item_display_name(it_id: String) -> String:
	match it_id:
		"shield_battery": return "大型护盾电池"
		"shield_cell": return "小型护盾电池"
		"med_kit": return "医疗箱"
		"syringe": return "注射器"
		"phoenix_kit": return "凤凰治疗包"
		"arc_star": return "电弧星"
		"frag": return "破片手雷"
		"thermite": return "铝热剂手雷"
		"light": return "轻型弹药"
		"heavy": return "重型弹药"
		"energy": return "能量弹药"
		"shotgun": return "霰弹枪弹药"
		"sniper": return "狙击弹药"
		_: return it_id

func _get_ammo_color(ammo_type: String) -> Color:
	match ammo_type:
		"light": return Color("#f97316")
		"heavy": return Color("#14b8a6")
		"energy": return Color("#84cc16")
		"shotgun": return Color("#ef4444")
		"sniper": return Color("#38bdf8")
		"mythic": return Color("#dc2626")
		_: return Color("#38bdf8")

func _get_tier_color(tier: int) -> Color:
	match tier:
		1: return Color("#94a3b8")
		2: return Color("#38bdf8")
		3: return Color("#c084fc")
		4: return Color("#fbbf24")
		5: return Color("#ff1e42")
		_: return Color("#64748b")

func _draw_chamfered_card(r: Rect2, bg: Color, border: Color, bw: float = 1.5) -> void:
	var ch: float = 8.0
	var pts := PackedVector2Array([
		Vector2(r.position.x + ch, r.position.y),
		Vector2(r.position.x + r.size.x - ch, r.position.y),
		Vector2(r.position.x + r.size.x, r.position.y + ch),
		Vector2(r.position.x + r.size.x, r.position.y + r.size.y - ch),
		Vector2(r.position.x + r.size.x - ch, r.position.y + r.size.y),
		Vector2(r.position.x + ch, r.position.y + r.size.y),
		Vector2(r.position.x, r.position.y + r.size.y - ch),
		Vector2(r.position.x, r.position.y + ch),
		Vector2(r.position.x + ch, r.position.y)
	])
	draw_colored_polygon(pts, bg)
	draw_polyline(pts, border, bw)

func _draw_rounded_slot_box(r: Rect2, bg: Color, border: Color, bw: float = 1.5) -> void:
	var rad: float = 6.0
	var pts := PackedVector2Array([
		Vector2(r.position.x + rad, r.position.y),
		Vector2(r.position.x + r.size.x - rad, r.position.y),
		Vector2(r.position.x + r.size.x, r.position.y + rad),
		Vector2(r.position.x + r.size.x, r.position.y + r.size.y - rad),
		Vector2(r.position.x + r.size.x - rad, r.position.y + r.size.y),
		Vector2(r.position.x + rad, r.position.y + r.size.y),
		Vector2(r.position.x, r.position.y + r.size.y - rad),
		Vector2(r.position.x, r.position.y + rad),
		Vector2(r.position.x + rad, r.position.y)
	])
	draw_colored_polygon(pts, bg)
	draw_polyline(pts, border, bw)

func _draw_ammo_badge(c: Vector2, ammo_type: String, r: float) -> void:
	var col := _get_ammo_color(ammo_type)
	if ammo_type == "shotgun":
		draw_rect(Rect2(c.x - r * 0.7, c.y - r * 0.7, r * 1.4, r * 1.4), col, false, 2.0)
		draw_rect(Rect2(c.x - r * 0.4, c.y - r * 0.5, r * 0.8, r * 1.0), col, true)
	else:
		var tri := PackedVector2Array([
			Vector2(c.x - r, c.y - r * 0.8),
			Vector2(c.x + r, c.y - r * 0.8),
			Vector2(c.x, c.y + r * 0.9),
			Vector2(c.x - r, c.y - r * 0.8)
		])
		draw_colored_polygon(tri, Color(col.r, col.g, col.b, 0.25))
		draw_polyline(tri, col, 2.0)
		if ammo_type == "energy":
			draw_line(Vector2(c.x + 2, c.y - 7), Vector2(c.x - 3, c.y - 1), col, 2.0)
			draw_line(Vector2(c.x - 3, c.y - 1), Vector2(c.x + 2, c.y), col, 2.0)
			draw_line(Vector2(c.x + 2, c.y), Vector2(c.x - 2, c.y + 6), col, 2.0)
		else:
			draw_line(Vector2(c.x - 5, c.y - 4), Vector2(c.x + 5, c.y - 4), col, 2.0)
			draw_line(Vector2(c.x - 4, c.y), Vector2(c.x + 4, c.y), col, 2.0)
			draw_line(Vector2(c.x - 2, c.y + 4), Vector2(c.x + 2, c.y + 4), col, 2.0)

func _draw_incompatible_slash(c: Vector2, r: float) -> void:
	draw_arc(c, r, 0, TAU, 24, Color("#ef4444"), 2.2)
	draw_line(c + Vector2(-r * 0.7, -r * 0.7), c + Vector2(r * 0.7, r * 0.7), Color("#ef4444"), 2.2)

func _draw_attachment_slot(r: Rect2, att_type: String, tier: int, _optic_id: String) -> void:
	var tier_col := _get_tier_color(tier) if tier > 0 else Color("#334155")
	var bg_col := Color(tier_col.r, tier_col.g, tier_col.b, 0.25) if tier > 0 else Color(0.08, 0.12, 0.18, 0.8)
	_draw_rounded_slot_box(r, bg_col, tier_col, 1.8 if tier > 0 else 1.0)
	var c := r.get_center()
	var icol := tier_col if tier > 0 else Color("#64748b")
	match att_type:
		"barrel":
			draw_rect(Rect2(c.x - 8, c.y - 5, 16, 10), icol, false, 1.8)
			draw_line(Vector2(c.x - 4, c.y - 5), Vector2(c.x - 4, c.y + 5), icol, 1.5)
			draw_line(Vector2(c.x + 4, c.y - 5), Vector2(c.x + 4, c.y + 5), icol, 1.5)
		"mag":
			var mpts := PackedVector2Array([
				Vector2(c.x - 7, c.y - 8), Vector2(c.x + 7, c.y - 8),
				Vector2(c.x + 5, c.y + 9), Vector2(c.x - 5, c.y + 9),
				Vector2(c.x - 7, c.y - 8)
			])
			draw_colored_polygon(mpts, Color(icol.r, icol.g, icol.b, 0.35))
			draw_polyline(mpts, icol, 1.8)
		"optic":
			draw_line(Vector2(c.x - 9, c.y - 4), Vector2(c.x - 9, c.y + 7), icol, 2.0)
			draw_line(Vector2(c.x + 9, c.y - 4), Vector2(c.x + 9, c.y + 7), icol, 2.0)
			draw_line(Vector2(c.x - 9, c.y + 7), Vector2(c.x + 9, c.y + 7), icol, 2.5)
			draw_circle(c + Vector2(0, -1), 2.0, Color("#ef4444"))
		"stock":
			draw_line(Vector2(c.x - 9, c.y - 6), Vector2(c.x + 6, c.y - 6), icol, 2.5)
			draw_line(Vector2(c.x + 6, c.y - 6), Vector2(c.x + 6, c.y + 7), icol, 3.5)
			draw_line(Vector2(c.x - 9, c.y - 6), Vector2(c.x - 9, c.y + 4), icol, 2.0)
		"hopup":
			var dpts := PackedVector2Array([
				Vector2(c.x, c.y - 9), Vector2(c.x + 8, c.y),
				Vector2(c.x, c.y + 9), Vector2(c.x - 8, c.y),
				Vector2(c.x, c.y - 9)
			])
			draw_colored_polygon(dpts, Color(icol.r, icol.g, icol.b, 0.45))
			draw_polyline(dpts, icol, 1.8)

func _draw_inventory_item_icon(r: Rect2, it_type: String, it_id: String, it: Dictionary) -> void:
	var c := r.get_center()
	match it_type:
		"ammo":
			_draw_ammo_badge(c, it_id, 16.0)
		"consumable":
			match it_id:
				"shield_battery":
					draw_rect(Rect2(c.x - 8, c.y - 14, 16, 28), Color("#0284c7"), true)
					draw_rect(Rect2(c.x - 8, c.y - 14, 16, 28), Color("#38bdf8"), false, 1.5)
					draw_circle(c, 4.0, Color.WHITE)
				"shield_cell":
					draw_rect(Rect2(c.x - 6, c.y - 8, 12, 16), Color("#0284c7"), true)
					draw_rect(Rect2(c.x - 6, c.y - 8, 12, 16), Color("#38bdf8"), false, 1.5)
					draw_circle(c, 2.5, Color.WHITE)
				"med_kit":
					draw_rect(Rect2(c.x - 12, c.y - 10, 24, 20), Color("#f8fafc"), true)
					draw_rect(Rect2(c.x - 12, c.y - 10, 24, 20), Color("#cbd5e1"), false, 1.5)
					draw_rect(Rect2(c.x - 3, c.y - 7, 6, 14), Color("#ef4444"), true)
					draw_rect(Rect2(c.x - 7, c.y - 3, 14, 6), Color("#ef4444"), true)
				"syringe":
					draw_line(Vector2(c.x - 8, c.y + 8), Vector2(c.x + 8, c.y - 8), Color("#22c55e"), 4.0)
					draw_circle(Vector2(c.x + 9, c.y - 9), 2.5, Color("#f8fafc"))
				"phoenix_kit":
					draw_rect(Rect2(c.x - 10, c.y - 15, 20, 30), Color("#0f172a"), true)
					draw_rect(Rect2(c.x - 10, c.y - 15, 20, 30), Color("#fbbf24"), false, 2.0)
					draw_circle(c, 5.0, Color("#f59e0b"))
		"ordnance":
			match it_id:
				"frag":
					draw_circle(c, 10.0, Color("#475569"))
					draw_arc(c, 10.0, 0, TAU, 16, Color("#f97316"), 1.8)
					draw_line(Vector2(c.x, c.y - 10), Vector2(c.x, c.y - 14), Color("#cbd5e1"), 2.0)
				"arc_star":
					var as_pts := PackedVector2Array([
						Vector2(c.x, c.y - 13), Vector2(c.x + 4, c.y - 4),
						Vector2(c.x + 13, c.y), Vector2(c.x + 4, c.y + 4),
						Vector2(c.x, c.y + 13), Vector2(c.x - 4, c.y + 4),
						Vector2(c.x - 13, c.y), Vector2(c.x - 4, c.y - 4),
						Vector2(c.x, c.y - 13)
					])
					draw_colored_polygon(as_pts, Color(0.1, 0.6, 0.95, 0.6))
					draw_polyline(as_pts, Color("#38bdf8"), 2.0)
				"thermite":
					draw_rect(Rect2(c.x - 6, c.y - 13, 12, 26), Color("#ea580c"), true)
					draw_circle(c, 4.0, Color("#fde047"))
		"attachment":
			_draw_attachment_slot(Rect2(c.x - 18, c.y - 18, 36, 36), "optic" if str(it.get("id","")).begins_with("3x") else "barrel", int(it.get("tier", 3)), "")

func _draw_gear_icon(c: Vector2, gear_type: String, _tier: int, col: Color) -> void:
	match gear_type:
		"helmet":
			var hpts := PackedVector2Array([
				Vector2(c.x - 13, c.y - 2), Vector2(c.x - 8, c.y - 12),
				Vector2(c.x + 8, c.y - 12), Vector2(c.x + 13, c.y - 2),
				Vector2(c.x + 11, c.y + 8), Vector2(c.x - 11, c.y + 8),
				Vector2(c.x - 13, c.y - 2)
			])
			draw_colored_polygon(hpts, Color(col.r, col.g, col.b, 0.45))
			draw_polyline(hpts, col, 2.0)
		"armor":
			var spts := PackedVector2Array([
				Vector2(c.x, c.y - 14), Vector2(c.x + 12, c.y - 8),
				Vector2(c.x + 10, c.y + 8), Vector2(c.x, c.y + 15),
				Vector2(c.x - 10, c.y + 8), Vector2(c.x - 12, c.y - 8),
				Vector2(c.x, c.y - 14)
			])
			draw_colored_polygon(spts, Color(col.r, col.g, col.b, 0.5))
			draw_polyline(spts, col, 2.2)
		"knockdown":
			draw_arc(c, 12.0, -PI * 0.6, PI * 0.6, 16, col, 3.5)
			draw_line(Vector2(c.x, c.y - 10), Vector2(c.x, c.y + 10), col, 2.0)
		"backpack":
			draw_rect(Rect2(c.x - 10, c.y - 11, 20, 22), Color(col.r, col.g, col.b, 0.4), true)
			draw_rect(Rect2(c.x - 10, c.y - 11, 20, 22), col, false, 2.0)
			draw_line(Vector2(c.x - 6, c.y - 11), Vector2(c.x - 6, c.y + 11), col, 1.5)
			draw_line(Vector2(c.x + 6, c.y - 11), Vector2(c.x + 6, c.y + 11), col, 1.5)
		"survival":
			draw_arc(c + Vector2(0, 4), 11.0, PI, TAU, 16, col, 2.5)
			draw_line(Vector2(c.x - 11, c.y + 4), Vector2(c.x + 11, c.y + 4), col, 2.0)

func _draw_weapon_silhouette(r: Rect2, _wid: String, cat: String, accent: Color) -> void:
	var sx: float = r.size.x / 180.0
	var sy: float = r.size.y / 54.0
	var ox: float = r.position.x
	var oy: float = r.position.y

	var pts: Array
	if cat == "SNIPER":
		pts = [Vector2(8,28), Vector2(34,24), Vector2(55,24), Vector2(62,16), Vector2(112,16), Vector2(118,24), Vector2(174,24), Vector2(174,28), Vector2(120,28), Vector2(112,34), Vector2(82,34), Vector2(78,46), Vector2(68,46), Vector2(70,34), Vector2(50,34), Vector2(42,44), Vector2(32,44), Vector2(36,32), Vector2(8,34)]
	elif cat == "SHOTGUN":
		pts = [Vector2(14,30), Vector2(42,22), Vector2(152,22), Vector2(156,30), Vector2(120,32), Vector2(114,36), Vector2(68,36), Vector2(58,46), Vector2(44,46), Vector2(50,34), Vector2(14,38)]
	elif cat == "PISTOL":
		pts = [Vector2(52,18), Vector2(126,18), Vector2(128,28), Vector2(94,30), Vector2(84,48), Vector2(66,48), Vector2(74,30), Vector2(52,28)]
	elif cat == "SMG":
		pts = [Vector2(26,24), Vector2(56,20), Vector2(134,20), Vector2(146,24), Vector2(146,28), Vector2(116,30), Vector2(108,48), Vector2(96,48), Vector2(100,30), Vector2(72,30), Vector2(64,44), Vector2(52,44), Vector2(58,30), Vector2(26,32)]
	else:
		pts = [Vector2(14,26), Vector2(46,20), Vector2(158,20), Vector2(164,24), Vector2(158,28), Vector2(118,28), Vector2(110,46), Vector2(96,46), Vector2(102,30), Vector2(70,30), Vector2(62,44), Vector2(50,44), Vector2(56,30), Vector2(14,34)]

	var poly := PackedVector2Array()
	for pt in pts:
		poly.append(Vector2(ox + pt.x * sx, oy + pt.y * sy))

	draw_colored_polygon(poly, Color(0.95, 0.97, 1.0, 0.22))
	var closed_poly := poly.duplicate()
	closed_poly.append(poly[0])
	draw_polyline(closed_poly, Color.WHITE, 1.8)
	draw_rect(Rect2(Vector2(ox + 68 * sx, oy + 18 * sy), Vector2(36 * sx, 4 * sy)), accent, true)
