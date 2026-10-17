extends Node
## GameData Autoload Singleton
## Authentic Apex Legends Database (Godot 4.3 Optimized Edition):
## - 5 Classes & 12 Playable Legends
## - 28 Authentic Weapons across all 7 official Apex Categories (AR, SMG, LMG, MARKSMAN, SNIPER, SHOTGUN, PISTOL)
## - High-Impact Calibrated Ballistic Stats (Boosted Body/Head/Leg damage, RPM, Mag Tiers, Tactical/Empty Reloads, Shotgun Bolt multipliers)
## - Unit-Normalized Deterministic Shotgun & Multi-Pellet Spread Patterns (Peacekeeper 11-pellet Star, Mastiff 8-pellet Horizontal Line, EVA-8 8-pellet Figure-8, Mozambique 3-pellet Triangle, Triple Take 3-bolt, Bocek Shatter Caps 7-pellet)

const CLASSES: Dictionary = {
	"ASSAULT": {
		"id": "ASSAULT", "name": "突击定位", "en": "Assault", "color": Color("#ef4444"),
		"perks": [
			"开启红色武器补给仓隐藏隔层（必出高阶智能枪械配件与瞄准镜）",
			"每格背包弹药堆叠上限提升 35%，并拥有额外投掷物专属栏位",
			"击碎敌方护盾后获得 3.5 秒换弹加速与 20% 爆发机动移速提升"
		]
	},
	"SKIRMISHER": {
		"id": "SKIRMISHER", "name": "游击定位", "en": "Skirmisher", "color": Color("#f59e0b"),
		"perks": [
			"远距透视扫描空投补给仓内的最高阶神话武器",
			"使用医疗与护盾恢复品时移动速度提升 25%",
			"击倒敌人后立即回复 25 点护盾并刷新战术技能充能"
		]
	},
	"RECON": {
		"id": "RECON", "name": "侦察定位", "en": "Recon", "color": Color("#38bdf8"),
		"perks": [
			"使用调查信标脉冲扫描全图敌方小队实时方位",
			"开镜瞄准（ADS）时获得数字化威胁红框高亮视野",
			"扫描敌方目标后全队获得持续追踪视野共享"
		]
	},
	"CONTROLLER": {
		"id": "CONTROLLER", "name": "控制定位", "en": "Controller", "color": Color("#a855f7"),
		"perks": [
			"激活毒圈控制台提前揭晓下一阶段安全区位置",
			"处于安全圈内部时进化护盾额外获得 +25 HP 超载上限",
			"可远距回收已部署的战术陷阱与防御工事"
		]
	},
	"SUPPORT": {
		"id": "SUPPORT", "name": "支援定位", "en": "Support", "color": Color("#22c55e"),
		"perks": [
			"开启蓝色支援补给仓隐藏隔层（必出大型护盾电池与医疗箱）",
			"使用恢复品时移速不减，扶起倒地队友速度提升 35% 并附带生命回复",
			"队友阵亡箱内自动生成移动重生信标，可在复制器制造全队旗帜"
		]
	}
}

const LEGENDS: Array = [
	{
		"id": "wraith", "name": "恶灵", "en": "WRAITH", "title": "跨维度决斗者", "class_id": "SKIRMISHER",
		"primary_color": Color("#312e81"), "secondary_color": Color("#93c5fd"), "visor_color": Color("#c4b5fd"),
		"scale": Vector3(0.92, 0.96, 0.92),
		"heirloom": {"name": "希望之暮（苦无 Kunai）", "color": Color("#8b5cf6")},
		"passive_name": "魔音传脑", "passive_desc": "被瞄准、附近存在毒气陷阱或敌队密集时，虚空之声自动发出方位预警。",
		"tac_name": "踏入虚空", "tac_cd": 20.0, "tac_desc": "0.4秒蓄力后进入虚空通道 4 秒，免疫一切伤害并提升 30% 移速。",
		"ult_name": "维度裂隙", "ult_cd": 120.0, "ult_desc": "连接起点与安全落点建立双向跨维度虚空传送门（含防穿墙射线检测）。",
		"upgrades_lv2": [
			{"id": "w_2a", "name": "虚空预警强化", "desc": "战术技能冷却缩短 4 秒，预警广播全队"},
			{"id": "w_2b", "name": "终极裂隙充能", "desc": "终极技能冷却缩短 25%，传送门距离 +25%"}
		],
		"upgrades_lv3": [
			{"id": "w_3a", "name": "瞬发虚空步", "desc": "踏入虚空前摇缩短 50%，虚空移速额外 +15%"},
			{"id": "w_3b", "name": "击倒刷新虚空", "desc": "参与击倒敌方目标立即重置战术技能冷却"}
		]
	},
	{
		"id": "octane", "name": "动力小子", "en": "OCTANE", "title": "高速特技狂人", "class_id": "SKIRMISHER",
		"primary_color": Color("#365314"), "secondary_color": Color("#22c55e"), "visor_color": Color("#84cc16"),
		"scale": Vector3(0.94, 0.97, 0.94),
		"heirloom": {"name": "辛烷蝴蝶刀（Butterfly Knife）", "color": Color("#22c55e")},
		"passive_name": "高速修复", "passive_desc": "脱离受击后每秒自动恢复 3.0 点生命值。",
		"tac_name": "兴奋剂", "tac_cd": 2.0, "tac_desc": "消耗 15 点生命值注射兴奋剂，6 秒内冲刺速度提升 35% 并免疫减速。",
		"ult_name": "跳垫", "ult_cd": 60.0, "ult_desc": "部署高压弹射跳垫，踩踏后高空弹射并可在空中按跳跃执行二段跳。",
		"upgrades_lv2": [
			{"id": "o_2a", "name": "厚皮硬化", "desc": "兴奋剂生命消耗降低 35%，爆炸伤害减免"},
			{"id": "o_2b", "name": "双倍再生", "desc": "被动生命恢复速度提升至每秒 5.5 点"}
		],
		"upgrades_lv3": [
			{"id": "o_3a", "name": "双重大跳垫", "desc": "跳垫充能上限提升至 2 层"},
			{"id": "o_3b", "name": "空中转向推进", "desc": "跳垫二段跳空中变向速度与射击精准度大幅提升"}
		]
	},
	{
		"id": "bloodhound", "name": "寻血猎犬", "en": "BLOODHOUND", "title": "科技追踪大师", "class_id": "RECON",
		"primary_color": Color("#78350f"), "secondary_color": Color("#ea580c"), "visor_color": Color("#ef4444"),
		"scale": Vector3(1.0, 1.0, 1.0),
		"heirloom": {"name": "渡鸦之咬（Raven's Bite 战斧）", "color": Color("#ef4444")},
		"passive_name": "追踪器", "passive_desc": "感知敌方足迹与白色渡鸦方向线索。",
		"tac_name": "上帝之眼", "tac_cd": 22.0, "tac_desc": "释放 95 米锥形声呐脉冲，透视高亮范围内所有敌方目标与陷阱 4.5 秒。",
		"ult_name": "狩猎野兽", "ult_cd": 110.0, "ult_desc": "强化感官 18 秒，红外热成像视野、移速提升 30%，击杀延长持续时间。",
		"upgrades_lv2": [
			{"id": "b_2a", "name": "渡鸦之眼", "desc": "上帝之眼透视持续时间延长 1.5 秒"},
			{"id": "b_2b", "name": "白鸦祝福", "desc": "扫描敌人时立即获得 20% 终极技能充能"}
		],
		"upgrades_lv3": [
			{"id": "b_3a", "name": "不朽狂猎", "desc": "狩猎野兽期间击倒敌人恢复 50 HP 并延长持续时间"},
			{"id": "b_3b", "name": "全息锁敌", "desc": "被扫描目标额外承受 8% 易伤加成"}
		]
	},
	{
		"id": "pathfinder", "name": "探路者", "en": "PATHFINDER", "title": "前方侦察马文", "class_id": "SKIRMISHER",
		"primary_color": Color("#0369a1"), "secondary_color": Color("#7dd3fc"), "visor_color": Color("#facc15"),
		"scale": Vector3(1.02, 1.05, 1.02),
		"heirloom": {"name": "拳击手套（Boxing Gloves）", "color": Color("#38bdf8")},
		"passive_name": "内线情报", "passive_desc": "扫描信标立即刷新滑索枪并缩短冷却。",
		"tac_name": "钩爪", "tac_cd": 16.0, "tac_desc": "向准星瞄准的建筑或地形发射真实物理钢缆抓钩，执行大摆锤弧线飞跃。",
		"ult_name": "滑索枪", "ult_cd": 90.0, "ult_desc": "架设供全队高速滑行转移的高空钢缆滑索（支持中途跳跃脱离）。",
		"upgrades_lv2": [
			{"id": "p_2a", "name": "全能信标插件", "desc": "同时解锁调查信标与毒圈控制台权限"},
			{"id": "p_2b", "name": "超长滑索", "desc": "滑索枪距离提升 50%，滑行速度提升 30%"}
		],
		"upgrades_lv3": [
			{"id": "p_3a", "name": "击倒重置钩爪", "desc": "参与击倒敌人立即重置钩爪冷却"},
			{"id": "p_3b", "name": "装甲钢缆", "desc": "使用滑索时获得 50% 伤害减免"}
		]
	},
	{
		"id": "lifeline", "name": "命脉", "en": "LIFELINE", "title": "战地重装医疗兵", "class_id": "SUPPORT",
		"primary_color": Color("#be185d"), "secondary_color": Color("#f8fafc"), "visor_color": Color("#2dd4bf"),
		"scale": Vector3(0.92, 0.95, 0.92),
		"heirloom": {"name": "电击鼓槌（Shock Sticks）", "color": Color("#ec4899")},
		"passive_name": "战斗医疗兵 & 滑翔", "passive_desc": "部署 D.O.C. 自动扶人并可在空中长按跳跃借助无人机滑翔。",
		"tac_name": "D.O.C. 治疗无人机", "tac_cd": 22.0, "tac_desc": "召唤跟随队友治疗的慈悲无人机，持续恢复周围友军生命值。",
		"ult_name": "D.O.C. 光环护盾", "ult_cd": 120.0, "ult_desc": "展开不可穿透的医疗能量光环并空投高阶护盾与医疗补给仓。",
		"upgrades_lv2": [
			{"id": "l_2a", "name": "极速医疗", "desc": "D.O.C. 治疗速度提升 35%"},
			{"id": "l_2b", "name": "战术减冷", "desc": "治疗无人机冷却缩短 8 秒"}
		],
		"upgrades_lv3": [
			{"id": "l_3a", "name": "金色自救包裹", "desc": "终极空投额外掉落神话电池与金击倒盾"},
			{"id": "l_3b", "name": "光环超载", "desc": "光环内每秒同时恢复生命与进化护盾"}
		]
	},
	{
		"id": "gibraltar", "name": "直布罗陀", "en": "GIBRALTAR", "title": "移动钢铁堡垒", "class_id": "SUPPORT",
		"primary_color": Color("#9a3412"), "secondary_color": Color("#fb923c"), "visor_color": Color("#38bdf8"),
		"scale": Vector3(1.18, 1.10, 1.18),
		"heirloom": {"name": "战斧火炬（War Club）", "color": Color("#f97316")},
		"passive_name": "枪盾 & 强化装甲", "passive_desc": "开镜展开 50 HP 能量臂盾阻挡正面子弹，全身减伤 15% 且免疫中弹减速。",
		"tac_name": "保护圆顶", "tac_cd": 24.0, "tac_desc": "投掷 6.5m 圆顶能量力场阻挡一切内外子弹与轰炸 12 秒，罩内打药加速。",
		"ult_name": "防御性轰炸", "ult_cd": 130.0, "ult_desc": "投掷红色信号弹呼叫密集迫击炮群轰炸目标区域。",
		"upgrades_lv2": [
			{"id": "g_2a", "name": "泡内快修", "desc": "保护圆顶内换弹加速 30%"},
			{"id": "g_2b", "name": "重装重生", "desc": "扶起队友额外恢复 60 HP"}
		],
		"upgrades_lv3": [
			{"id": "g_3a", "name": "圆顶延展", "desc": "保护圆顶冷却缩短 6 秒，体积 +20%"},
			{"id": "g_3b", "name": "密集重炮", "desc": "轰炸范围扩大 35%，枪盾提升至 75 HP"}
		]
	},
	{
		"id": "bangalore", "name": "邦加罗尔", "en": "BANGALORE", "title": "职业铁驭老兵", "class_id": "ASSAULT",
		"primary_color": Color("#7f1d1d"), "secondary_color": Color("#d97706"), "visor_color": Color("#fbbf24"),
		"scale": Vector3(0.96, 1.0, 0.96),
		"heirloom": {"name": "冷钢弯刀（Cold Steel Kukri）", "color": Color("#f59e0b")},
		"passive_name": "疾步", "passive_desc": "受击或被敌方火力压制时立即触发 30% 爆发移速加成。",
		"tac_name": "烟雾发射器", "tac_cd": 16.0, "tac_desc": "发射三联装高速烟雾榴弹形成浓密战术烟墙，阻断常规视线。",
		"ult_name": "雷鸣滚滚", "ult_cd": 120.0, "ult_desc": "呼叫地毯式推进火炮阵列轰炸并震撼减速敌军。",
		"upgrades_lv2": [
			{"id": "ba_2a", "name": "终极火炮充能", "desc": "雷鸣滚滚冷却缩短 30 秒"},
			{"id": "ba_2b", "name": "疾步感知", "desc": "触发疾步时自动高亮攻击者 3 秒"}
		],
		"upgrades_lv3": [
			{"id": "ba_3a", "name": "医疗烟雾", "desc": "处于烟雾内每秒恢复 8 点生命"},
			{"id": "ba_3b", "name": "掩体速装", "desc": "疾步期间所有武器换弹速度 +40%"}
		]
	},
	{
		"id": "ash", "name": "艾许", "en": "ASH", "title": "冷血拟像刺客", "class_id": "ASSAULT",
		"primary_color": Color("#1e293b"), "secondary_color": Color("#06b6d4"), "visor_color": Color("#f43f5e"),
		"scale": Vector3(0.92, 0.98, 0.92),
		"heirloom": {"name": "最强之刃（Strongest Link 双节刀）", "color": Color("#06b6d4")},
		"passive_name": "死神烙印", "passive_desc": "洞察全图死亡之箱并扫描幸存敌队。",
		"tac_name": "电弧陷阱", "tac_cd": 18.0, "tac_desc": "掷出旋转电弧飞盘造成 25 点电击伤害并将范围内敌人强行束缚。",
		"ult_name": "相位裂隙", "ult_cd": 90.0, "ult_desc": "挥剑斩开单向相位传送裂缝瞬间突进（自动射线检测防止穿入墙体）。",
		"upgrades_lv2": [
			{"id": "a_2a", "name": "贪婪电弧", "desc": "电弧陷阱留存 15 秒并可束缚多名敌人"},
			{"id": "a_2b", "name": "猎杀雷达", "desc": "击倒后全图追踪附近敌队 10 秒"}
		],
		"upgrades_lv3": [
			{"id": "a_3a", "name": "双重电弧", "desc": "电弧陷阱获得 2 层充能"},
			{"id": "a_3b", "name": "双段相位斩", "desc": "相位裂隙传送距离 +35%"}
		]
	},
	{
		"id": "horizon", "name": "地平线", "en": "HORIZON", "title": "引力天体物理学家", "class_id": "SKIRMISHER",
		"primary_color": Color("#1d4ed8"), "secondary_color": Color("#f97316"), "visor_color": Color("#93c5fd"),
		"scale": Vector3(0.93, 0.98, 0.93),
		"heirloom": {"name": "引力大锤（Gravity Maw）", "color": Color("#3b82f6")},
		"passive_name": "太空步", "passive_desc": "消除高空坠落硬直并大幅强化空中变向控制。",
		"tac_name": "重力电梯", "tac_cd": 20.0, "tac_desc": "生成 18m 垂直反重力上升气流托举小队升空并支持顶部悬浮射击。",
		"ult_name": "黑洞", "ult_cd": 125.0, "ult_desc": "部署纽特制造微型黑洞奇点，强力吸附周围敌人并高亮视野。",
		"upgrades_lv2": [
			{"id": "h_2a", "name": "战术减冷", "desc": "重力电梯冷却缩短 4 秒"},
			{"id": "h_2b", "name": "黑洞强化", "desc": "黑洞吸附半径扩大 25%"}
		],
		"upgrades_lv3": [
			{"id": "h_3a", "name": "电梯悬浮大师", "desc": "重力电梯顶部滞空延长 2 秒"},
			{"id": "h_3b", "name": "奇点坍缩", "desc": "黑洞结束时释放破甲引力冲击波"}
		]
	},
	{
		"id": "valkyrie", "name": "瓦尔基里", "en": "VALKYRIE", "title": "有翼天际复仇女神", "class_id": "RECON",
		"primary_color": Color("#b45309"), "secondary_color": Color("#6d28d9"), "visor_color": Color("#38bdf8"),
		"scale": Vector3(0.93, 0.97, 0.93),
		"heirloom": {"name": "朱雀战矛（Suzaku）", "color": Color("#f59e0b")},
		"passive_name": "VTOL 喷气背包", "passive_desc": "空中按跳跃启动喷气背包悬停飞行，跳伞自动扫描地面敌军。",
		"tac_name": "导弹群", "tac_cd": 22.0, "tac_desc": "肩部发射 12 枚微型制导火箭弹覆盖目标网格造成轰炸伤害与眩晕。",
		"ult_name": "天际俯冲", "ult_cd": 135.0, "ult_desc": "携带全队垂直冲入高空重新跳伞转移。",
		"upgrades_lv2": [
			{"id": "v_2a", "name": "矢量推进器", "desc": "VTOL 水平飞行速度提升 25%"},
			{"id": "v_2b", "name": "扩展弹仓", "desc": "导弹群覆盖网格扩大为 4x5"}
		],
		"upgrades_lv3": [
			{"id": "v_3a", "name": "高容量燃料箱", "desc": "喷气背包燃料上限 +35%"},
			{"id": "v_3b", "name": "平流层升空", "desc": "天际俯冲升空高度 +25%"}
		]
	},
	{
		"id": "caustic", "name": "侵蚀", "en": "CAUSTIC", "title": "剧毒捕猎科学家", "class_id": "CONTROLLER",
		"primary_color": Color("#3f6212"), "secondary_color": Color("#eab308"), "visor_color": Color("#84cc16"),
		"scale": Vector3(1.14, 1.06, 1.14),
		"heirloom": {"name": "死亡之锤（Death Hammer）", "color": Color("#84cc16")},
		"passive_name": "夜神视线 & 强化装甲", "passive_desc": "透视高亮毒气内敌人，全身减伤 15% 且免疫中弹减速。",
		"tac_name": "夜神毒气陷阱", "tac_cd": 16.0, "tac_desc": "放置充气毒气罐，敌方靠近时触发释放持续腐蚀生命的剧毒绿雾。",
		"ult_name": "夜神毒气手雷", "ult_cd": 120.0, "ult_desc": "投掷大范围高浓缩夜神毒气手雷瞬间覆盖决赛圈。",
		"upgrades_lv2": [
			{"id": "c_2a", "name": "远距投罐", "desc": "毒气罐投掷距离提升 75%"},
			{"id": "c_2b", "name": "残余毒素", "desc": "夜神视线离开毒气后仍持续 5 秒"}
		],
		"upgrades_lv3": [
			{"id": "c_3a", "name": "剧毒扩散", "desc": "夜神毒气手雷范围扩大 50%"},
			{"id": "c_3b", "name": "毒雾再生", "desc": "处于毒气中每秒恢复 10 点生命与护盾"}
		]
	},
	{
		"id": "mirage", "name": "幻象", "en": "MIRAGE", "title": "全息幻影魔术师", "class_id": "SUPPORT",
		"primary_color": Color("#ca8a04"), "secondary_color": Color("#1e293b"), "visor_color": Color("#fef08a"),
		"scale": Vector3(0.96, 1.0, 0.96),
		"heirloom": {"name": "太多金杯（Too Much Witt）", "color": Color("#facc15")},
		"passive_name": "安可！隐身救援", "passive_desc": "扶起队友时双方隐身并在完成后继续隐身加速。",
		"tac_name": "疯猫全息诱饵", "tac_cd": 14.0, "tac_desc": "派出沿地形前进的全息诱饵分身，受击时暴露敌方位置。",
		"ult_name": "派对焦点", "ult_cd": 60.0, "ult_desc": "短暂隐身并召唤 6 个同步动作的全息幻象分身混淆视听。",
		"upgrades_lv2": [
			{"id": "m_2a", "name": "派对再来一场", "desc": "派对焦点冷却缩短至 30 秒"},
			{"id": "m_2b", "name": "全能假人", "desc": "分身被击毁立即刷新战术技能"}
		],
		"upgrades_lv3": [
			{"id": "m_3a", "name": "双重分身", "desc": "疯猫战术技能获得 2 层充能"},
			{"id": "m_3b", "name": "奇迹再生", "desc": "分身受击时为本体恢复 25 点护盾"}
		]
	}
]

## Complete 28 Authentic Apex Legends Weapons (7 Categories: AR, SMG, LMG, MARKSMAN, SNIPER, SHOTGUN, PISTOL)
## Damage, headshot multipliers, RPM, magazine capacities, and spread have been tuned for punchy, authentic Apex combat feel.
const WEAPONS: Array = [
	# ==================== 1. ASSAULT RIFLES (AR - 突击步枪, ADS移速 0.50x) ====================
	{
		"id": "r301", "name": "R-301 卡宾枪", "en": "R-301 Carbine", "cat": "AR", "ammo": "light",
		"rpm": 810.0, "dmg": 15, "head": 1.75, "legs": 0.80, "pellets": 1, "pellet_pattern": "single",
		"mag": 18, "mag_tiers": [18, 20, 25, 28], "reload": 2.20, "reload_empty": 2.90,
		"reload_style": "ar_tactical", "archetype": "ar_carbine",
		"rec_len": 0.48, "barrel_len": 0.38, "mag_curve": 0.22, "stock_type": "crane",
		"spread": 0.0085, "ads_spread": 0.0008, "ads_move_scale": 0.50,
		"recoil_v": 0.010, "recoil_h": 0.0035, "proj_speed": 295.0, "grav_scale": 1.0,
		"fire_modes": ["auto", "single"], "color": Color("#06b6d4"), "accent": Color("#8b5cf6")
	},
	{
		"id": "flatline", "name": "VK-47 平行步枪", "en": "VK-47 Flatline", "cat": "AR", "ammo": "heavy",
		"rpm": 600.0, "dmg": 19, "head": 1.75, "legs": 0.80, "pellets": 1, "pellet_pattern": "single",
		"mag": 20, "mag_tiers": [20, 25, 28, 30], "reload": 2.30, "reload_empty": 2.95,
		"reload_style": "bullpup", "archetype": "bullpup_ar",
		"rec_len": 0.52, "barrel_len": 0.30, "mag_curve": 0.28, "stock_type": "bullpup",
		"spread": 0.010, "ads_spread": 0.0014, "ads_move_scale": 0.50,
		"recoil_v": 0.013, "recoil_h": 0.007, "proj_speed": 250.0, "grav_scale": 1.10,
		"fire_modes": ["auto", "single"], "color": Color("#2e3440"), "accent": Color("#14b8a6")
	},
	{
		"id": "hemlok", "name": "赫姆洛克连发步枪", "en": "Hemlok Burst AR", "cat": "AR", "ammo": "heavy",
		"rpm": 640.0, "dmg": 22, "head": 1.80, "legs": 0.80, "pellets": 1, "pellet_pattern": "single",
		"burst_count": 3, "burst_delay": 0.22,
		"mag": 18, "mag_tiers": [18, 24, 27, 30], "reload": 2.25, "reload_empty": 2.70,
		"reload_style": "ar_tactical", "archetype": "burst_ar",
		"rec_len": 0.50, "barrel_len": 0.40, "mag_curve": 0.20, "stock_type": "heavy",
		"spread": 0.009, "ads_spread": 0.0010, "ads_move_scale": 0.50,
		"recoil_v": 0.012, "recoil_h": 0.004, "proj_speed": 280.0, "grav_scale": 1.05,
		"fire_modes": ["burst", "single"], "color": Color("#1e293b"), "accent": Color("#14b8a6")
	},
	{
		"id": "nemesis", "name": "复仇女神连发步枪", "en": "Nemesis Burst AR", "cat": "AR", "ammo": "energy",
		"rpm": 660.0, "dmg": 18, "head": 1.75, "legs": 0.80, "pellets": 1, "pellet_pattern": "single",
		"burst_count": 4, "burst_delay": 0.20,
		"mag": 20, "mag_tiers": [20, 24, 28, 32], "reload": 2.45, "reload_empty": 2.45,
		"reload_style": "energy_cell", "archetype": "energy_ar",
		"rec_len": 0.54, "barrel_len": 0.42, "mag_curve": 0.0, "stock_type": "heavy",
		"spread": 0.0085, "ads_spread": 0.0010, "ads_move_scale": 0.50,
		"recoil_v": 0.011, "recoil_h": 0.0035, "proj_speed": 315.0, "grav_scale": 0.85,
		"fire_modes": ["burst"], "color": Color("#1e293b"), "accent": Color("#84cc16")
	},
	{
		"id": "havoc", "name": "哈沃克步枪", "en": "HAVOC Rifle", "cat": "AR", "ammo": "energy",
		"rpm": 672.0, "dmg": 20, "head": 1.75, "legs": 0.80, "pellets": 1, "pellet_pattern": "single",
		"windup_time": 0.32,
		"mag": 24, "mag_tiers": [24, 28, 32, 36], "reload": 2.90, "reload_empty": 2.90,
		"reload_style": "energy_cell", "archetype": "energy_ar",
		"rec_len": 0.50, "barrel_len": 0.36, "mag_curve": 0.0, "stock_type": "heavy",
		"spread": 0.011, "ads_spread": 0.0016, "ads_move_scale": 0.50,
		"recoil_v": 0.014, "recoil_h": 0.005, "proj_speed": 310.0, "grav_scale": 0.85,
		"fire_modes": ["auto"], "color": Color("#475569"), "accent": Color("#a3e635")
	},

	# ==================== 2. SUBMACHINE GUNS (SMG - 冲锋枪, ADS移速 0.75x) ====================
	{
		"id": "r99", "name": "R-99 冲锋枪", "en": "R-99 SMG", "cat": "SMG", "ammo": "light",
		"rpm": 1080.0, "dmg": 13, "head": 1.55, "legs": 0.85, "pellets": 1, "pellet_pattern": "single",
		"mag": 20, "mag_tiers": [20, 22, 25, 28], "reload": 1.65, "reload_empty": 2.20,
		"reload_style": "smg_fast", "archetype": "compact_smg",
		"rec_len": 0.34, "barrel_len": 0.22, "mag_curve": 0.15, "stock_type": "wire",
		"spread": 0.012, "ads_spread": 0.0022, "ads_move_scale": 0.75,
		"recoil_v": 0.012, "recoil_h": 0.0055, "proj_speed": 225.0, "grav_scale": 1.05,
		"fire_modes": ["auto"], "color": Color("#94a3b8"), "accent": Color("#f97316")
	},
	{
		"id": "volt", "name": "电能冲锋枪", "en": "Volt SMG", "cat": "SMG", "ammo": "energy",
		"rpm": 720.0, "dmg": 17, "head": 1.55, "legs": 0.85, "pellets": 1, "pellet_pattern": "single",
		"mag": 19, "mag_tiers": [19, 21, 24, 27], "reload": 1.40, "reload_empty": 1.95,
		"reload_style": "energy_cell", "archetype": "energy_smg",
		"rec_len": 0.38, "barrel_len": 0.25, "mag_curve": 0.08, "stock_type": "crane",
		"spread": 0.009, "ads_spread": 0.0014, "ads_move_scale": 0.75,
		"recoil_v": 0.010, "recoil_h": 0.0035, "proj_speed": 240.0, "grav_scale": 0.90,
		"fire_modes": ["auto"], "color": Color("#f8fafc"), "accent": Color("#38bdf8")
	},
	{
		"id": "car", "name": "C.A.R. 冲锋枪", "en": "C.A.R. SMG", "cat": "SMG", "ammo": "heavy",
		"secondary_ammo": "light",
		"rpm": 930.0, "dmg": 14, "head": 1.55, "legs": 0.85, "pellets": 1, "pellet_pattern": "single",
		"mag": 20, "mag_tiers": [20, 22, 25, 28], "reload": 1.60, "reload_empty": 2.00,
		"reload_style": "smg_fast", "archetype": "compact_smg",
		"rec_len": 0.36, "barrel_len": 0.23, "mag_curve": 0.20, "stock_type": "crane",
		"spread": 0.011, "ads_spread": 0.0020, "ads_move_scale": 0.75,
		"recoil_v": 0.012, "recoil_h": 0.0055, "proj_speed": 210.0, "grav_scale": 1.10,
		"fire_modes": ["auto"], "color": Color("#334155"), "accent": Color("#f59e0b")
	},
	{
		"id": "prowler", "name": "猎兽冲锋枪", "en": "Prowler Burst PDW", "cat": "SMG", "ammo": "heavy",
		"rpm": 820.0, "dmg": 17, "head": 1.55, "legs": 0.85, "pellets": 1, "pellet_pattern": "single",
		"burst_count": 5, "burst_delay": 0.19,
		"mag": 20, "mag_tiers": [20, 25, 30, 35], "reload": 1.70, "reload_empty": 2.15,
		"reload_style": "bullpup", "archetype": "bullpup_smg",
		"rec_len": 0.42, "barrel_len": 0.18, "mag_curve": 0.12, "stock_type": "bullpup",
		"spread": 0.009, "ads_spread": 0.0016, "ads_move_scale": 0.75,
		"recoil_v": 0.011, "recoil_h": 0.004, "proj_speed": 205.0, "grav_scale": 1.10,
		"fire_modes": ["burst", "auto"], "color": Color("#1e293b"), "accent": Color("#ef4444")
	},
	{
		"id": "alternator", "name": "转换者冲锋枪", "en": "Alternator SMG", "cat": "SMG", "ammo": "light",
		"rpm": 620.0, "dmg": 18, "head": 1.55, "legs": 0.85, "pellets": 1, "pellet_pattern": "single",
		"mag": 19, "mag_tiers": [19, 22, 25, 28], "reload": 1.75, "reload_empty": 2.10,
		"reload_style": "smg_fast", "archetype": "twin_smg",
		"rec_len": 0.30, "barrel_len": 0.18, "mag_curve": 0.05, "stock_type": "wire",
		"spread": 0.0065, "ads_spread": 0.0010, "ads_move_scale": 0.75,
		"recoil_v": 0.008, "recoil_h": 0.0025, "proj_speed": 210.0, "grav_scale": 1.05,
		"fire_modes": ["auto"], "color": Color("#d97706"), "accent": Color("#f8fafc")
	},

	# ==================== 3. LIGHT MACHINE GUNS (LMG - 轻机枪, ADS移速 0.40x) ====================
	{
		"id": "spitfire", "name": "M600 喷火轻机枪", "en": "M600 Spitfire", "cat": "LMG", "ammo": "light",
		"rpm": 550.0, "dmg": 20, "head": 1.55, "legs": 0.85, "pellets": 1, "pellet_pattern": "single",
		"mag": 35, "mag_tiers": [35, 40, 45, 50], "reload": 3.10, "reload_empty": 3.80,
		"reload_style": "lmg_box", "archetype": "heavy_lmg",
		"rec_len": 0.58, "barrel_len": 0.48, "mag_curve": 0.0, "stock_type": "heavy",
		"spread": 0.013, "ads_spread": 0.0022, "ads_move_scale": 0.40,
		"recoil_v": 0.012, "recoil_h": 0.0055, "proj_speed": 280.0, "grav_scale": 1.05,
		"fire_modes": ["auto"], "color": Color("#3f6212"), "accent": Color("#facc15")
	},
	{
		"id": "rampage", "name": "暴走轻机枪（可铝热剂充能）", "en": "Rampage LMG", "cat": "LMG", "ammo": "heavy",
		"rpm": 320.0, "dmg": 28, "head": 1.60, "legs": 0.85, "pellets": 1, "pellet_pattern": "single",
		"mag": 28, "mag_tiers": [28, 32, 36, 40], "reload": 2.90, "reload_empty": 3.60,
		"reload_style": "lmg_box", "archetype": "heavy_lmg",
		"rec_len": 0.60, "barrel_len": 0.50, "mag_curve": 0.18, "stock_type": "heavy",
		"spread": 0.011, "ads_spread": 0.0018, "ads_move_scale": 0.40,
		"recoil_v": 0.015, "recoil_h": 0.004, "proj_speed": 270.0, "grav_scale": 1.05,
		"fire_modes": ["auto"], "color": Color("#7f1d1d"), "accent": Color("#f97316")
	},
	{
		"id": "devotion", "name": "专注轻机枪（渐进加速）", "en": "Devotion LMG", "cat": "LMG", "ammo": "energy",
		"rpm": 900.0, "min_rpm": 360.0, "dmg": 17, "head": 1.55, "legs": 0.85, "pellets": 1, "pellet_pattern": "single",
		"mag": 36, "mag_tiers": [36, 40, 44, 48], "reload": 2.60, "reload_empty": 3.30,
		"reload_style": "lmg_box", "archetype": "energy_lmg",
		"rec_len": 0.56, "barrel_len": 0.45, "mag_curve": 0.0, "stock_type": "heavy",
		"spread": 0.014, "ads_spread": 0.0026, "ads_move_scale": 0.40,
		"recoil_v": 0.014, "recoil_h": 0.0065, "proj_speed": 335.0, "grav_scale": 0.85,
		"fire_modes": ["auto"], "color": Color("#1e293b"), "accent": Color("#38bdf8")
	},
	{
		"id": "lstar", "name": "L-STAR 能量机枪", "en": "L-STAR EMG", "cat": "LMG", "ammo": "energy",
		"rpm": 600.0, "dmg": 19, "head": 1.60, "legs": 0.85, "pellets": 1, "pellet_pattern": "single",
		"mag": 24, "mag_tiers": [24, 28, 32, 36], "reload": 2.25, "reload_empty": 2.25,
		"reload_style": "energy_cell", "archetype": "plasma_lmg",
		"rec_len": 0.52, "barrel_len": 0.38, "mag_curve": 0.0, "stock_type": "heavy",
		"spread": 0.011, "ads_spread": 0.0020, "ads_move_scale": 0.40,
		"recoil_v": 0.012, "recoil_h": 0.0055, "proj_speed": 255.0, "grav_scale": 0.80,
		"fire_modes": ["auto"], "color": Color("#334155"), "accent": Color("#ef4444")
	},

	# ==================== 4. MARKSMAN WEAPONS (MARKSMAN - 神射手, ADS移速 0.425x) ====================
	{
		"id": "g7", "name": "G7 侦察枪", "en": "G7 Scout", "cat": "MARKSMAN", "ammo": "light",
		"rpm": 240.0, "dmg": 35, "head": 1.80, "legs": 0.80, "pellets": 1, "pellet_pattern": "single",
		"mag": 10, "mag_tiers": [10, 15, 18, 20], "reload": 2.10, "reload_empty": 2.60,
		"reload_style": "ar_tactical", "archetype": "marksman_dmr",
		"rec_len": 0.54, "barrel_len": 0.46, "mag_curve": 0.06, "stock_type": "sniper",
		"spread": 0.010, "ads_spread": 0.0005, "ads_move_scale": 0.425,
		"recoil_v": 0.019, "recoil_h": 0.0025, "proj_speed": 305.0, "grav_scale": 1.0,
		"fire_modes": ["single", "burst"], "color": Color("#64748b"), "accent": Color("#f97316")
	},
	{
		"id": "tripletake", "name": "三重式狙击枪", "en": "Triple Take", "cat": "MARKSMAN", "ammo": "energy",
		"rpm": 85.0, "dmg": 23, "head": 1.80, "legs": 0.90, "pellets": 3, "pellet_pattern": "triple_3",
		"ammo_per_shot": 3, "has_choke": true,
		"mag": 18, "mag_tiers": [18, 21, 24, 30], "reload": 2.25, "reload_empty": 2.90,
		"reload_style": "energy_cell", "archetype": "triple_marksman",
		"rec_len": 0.56, "barrel_len": 0.52, "mag_curve": 0.0, "stock_type": "sniper",
		"spread": 0.016, "ads_spread": 0.007, "ads_move_scale": 0.425,
		"recoil_v": 0.021, "recoil_h": 0.0025, "proj_speed": 325.0, "grav_scale": 0.75,
		"fire_modes": ["single"], "color": Color("#0f172a"), "accent": Color("#a3e635")
	},
	{
		"id": "repeater3030", "name": "30-30 连发枪", "en": "30-30 Repeater", "cat": "MARKSMAN", "ammo": "heavy",
		"rpm": 145.0, "dmg": 44, "max_charge_dmg": 60, "head": 1.80, "legs": 0.85, "pellets": 1, "pellet_pattern": "single",
		"segmented_reload": true, "rechamber": 0.40,
		"mag": 6, "mag_tiers": [6, 8, 10, 12], "reload": 0.42, "reload_empty": 0.42,
		"reload_style": "lever_shotgun", "archetype": "lever_marksman",
		"rec_len": 0.52, "barrel_len": 0.50, "mag_curve": 0.0, "stock_type": "sniper",
		"spread": 0.011, "ads_spread": 0.0005, "ads_move_scale": 0.425,
		"recoil_v": 0.022, "recoil_h": 0.0025, "proj_speed": 295.0, "grav_scale": 1.05,
		"fire_modes": ["single"], "color": Color("#78350f"), "accent": Color("#f59e0b")
	},
	{
		"id": "bocek", "name": "博塞克复合弓（神话）", "en": "Bocek Compound Bow", "cat": "MARKSMAN", "ammo": "arrows",
		"rpm": 125.0, "dmg": 72, "min_draw_dmg": 28, "head": 1.80, "legs": 0.90, "pellets": 1, "pellet_pattern": "single",
		"draw_time_max": 0.52,
		"mag": 60, "mag_tiers": [60, 60, 60, 60], "reload": 0.32, "reload_empty": 0.32,
		"reload_style": "bow_draw", "archetype": "compound_bow",
		"rec_len": 0.25, "barrel_len": 0.20, "mag_curve": 0.0, "stock_type": "bow",
		"spread": 0.002, "ads_spread": 0.0002, "ads_move_scale": 0.55,
		"recoil_v": 0.008, "recoil_h": 0.001, "proj_speed": 290.0, "grav_scale": 0.85,
		"fire_modes": ["bow_single", "shatter_caps"], "color": Color("#ff1e42"), "accent": Color("#fbbf24")
	},

	# ==================== 5. SNIPER RIFLES (SNIPER - 狙击步枪, ADS移速 0.35x) ====================
	{
		"id": "kraber", "name": "克雷贝尔 .50 狙击步枪（神话）", "en": "Kraber .50-Cal Sniper", "cat": "SNIPER", "ammo": "sniper",
		"rpm": 28.0, "dmg": 150, "head": 2.00, "legs": 0.85, "pellets": 1, "pellet_pattern": "single",
		"rechamber": 1.15,
		"mag": 4, "mag_tiers": [4, 4, 4, 4], "reload": 3.00, "reload_empty": 4.00,
		"reload_style": "bolt_sniper", "archetype": "heavy_sniper",
		"rec_len": 0.64, "barrel_len": 0.72, "mag_curve": 0.0, "stock_type": "sniper",
		"spread": 0.024, "ads_spread": 0.0001, "ads_move_scale": 0.35,
		"recoil_v": 0.044, "recoil_h": 0.004, "proj_speed": 310.0, "grav_scale": 1.10,
		"fire_modes": ["single"], "color": Color("#991b1b"), "accent": Color("#fbbf24")
	},
	{
		"id": "sentinel", "name": "哨兵狙击步枪（可小电充能）", "en": "Sentinel", "cat": "SNIPER", "ammo": "sniper",
		"rpm": 42.0, "dmg": 74, "amped_dmg": 92, "head": 2.00, "legs": 0.90, "pellets": 1, "pellet_pattern": "single",
		"rechamber": 0.95,
		"mag": 4, "mag_tiers": [4, 5, 6, 7], "reload": 2.35, "reload_empty": 3.30,
		"reload_style": "bolt_sniper", "archetype": "bolt_sniper",
		"rec_len": 0.58, "barrel_len": 0.62, "mag_curve": 0.0, "stock_type": "sniper",
		"spread": 0.018, "ads_spread": 0.0001, "ads_move_scale": 0.35,
		"recoil_v": 0.032, "recoil_h": 0.003, "proj_speed": 320.0, "grav_scale": 1.0,
		"fire_modes": ["single"], "color": Color("#1e3a8a"), "accent": Color("#38bdf8")
	},
	{
		"id": "longbow", "name": "长弓精确步枪", "en": "Longbow DMR", "cat": "SNIPER", "ammo": "sniper",
		"rpm": 82.0, "dmg": 60, "head": 2.15, "legs": 0.90, "pellets": 1, "pellet_pattern": "single",
		"mag": 6, "mag_tiers": [6, 8, 10, 12], "reload": 2.45, "reload_empty": 3.35,
		"reload_style": "ar_tactical", "archetype": "dmr_sniper",
		"rec_len": 0.60, "barrel_len": 0.58, "mag_curve": 0.05, "stock_type": "sniper",
		"spread": 0.015, "ads_spread": 0.0002, "ads_move_scale": 0.35,
		"recoil_v": 0.025, "recoil_h": 0.003, "proj_speed": 310.0, "grav_scale": 1.0,
		"fire_modes": ["single"], "color": Color("#334155"), "accent": Color("#38bdf8")
	},
	{
		"id": "chargerifle", "name": "充能步枪（滋崩）", "en": "Charge Rifle", "cat": "SNIPER", "ammo": "sniper",
		"rpm": 50.0, "dmg": 82, "head": 1.85, "legs": 0.90, "pellets": 1, "pellet_pattern": "single",
		"mag": 6, "mag_tiers": [6, 8, 10, 12], "reload": 3.20, "reload_empty": 4.10,
		"reload_style": "energy_cell", "archetype": "charge_sniper",
		"rec_len": 0.62, "barrel_len": 0.52, "mag_curve": 0.0, "stock_type": "sniper",
		"spread": 0.008, "ads_spread": 0.0001, "ads_move_scale": 0.35,
		"recoil_v": 0.038, "recoil_h": 0.0025, "proj_speed": 340.0, "grav_scale": 0.0,
		"fire_modes": ["charge_beam"], "color": Color("#334155"), "accent": Color("#ff7700")
	},

	# ==================== 6. SHOTGUNS (SHOTGUN - 霰弹枪, 固定弹丸阵列 + 霰弹枪栓加速) ====================
	{
		"id": "peacekeeper", "name": "和平捍卫者", "en": "Peacekeeper", "cat": "SHOTGUN", "ammo": "shotgun",
		"rpm": 58.0, "dmg": 10, "head": 1.25, "legs": 1.00, "pellets": 11, "pellet_pattern": "star_11",
		"rechamber": 0.95, "has_choke": true,
		"mag": 5, "mag_tiers": [5, 5, 5, 5], "reload": 2.35, "reload_empty": 3.15,
		"reload_style": "lever_shotgun", "archetype": "lever_shotgun",
		"rec_len": 0.48, "barrel_len": 0.44, "mag_curve": 0.0, "stock_type": "shotgun",
		"spread": 0.026, "ads_spread": 0.011, "ads_move_scale": 0.85,
		"recoil_v": 0.026, "recoil_h": 0.004, "proj_speed": 180.0, "grav_scale": 0.5,
		"fire_modes": ["single"], "color": Color("#0f172a"), "accent": Color("#38bdf8")
	},
	{
		"id": "mastiff", "name": "獒犬霰弹枪", "en": "Mastiff Shotgun", "cat": "SHOTGUN", "ammo": "shotgun",
		"rpm": 78.0, "dmg": 12, "head": 1.25, "legs": 1.00, "pellets": 8, "pellet_pattern": "line_8",
		"segmented_reload": true, "rechamber": 0.48,
		"mag": 5, "mag_tiers": [5, 5, 5, 5], "reload": 0.42, "reload_empty": 0.42,
		"reload_style": "pump_shotgun", "archetype": "pump_shotgun",
		"rec_len": 0.50, "barrel_len": 0.42, "mag_curve": 0.0, "stock_type": "shotgun",
		"spread": 0.032, "ads_spread": 0.013, "ads_move_scale": 0.85,
		"recoil_v": 0.024, "recoil_h": 0.003, "proj_speed": 180.0, "grav_scale": 0.5,
		"fire_modes": ["single"], "color": Color("#78350f"), "accent": Color("#ef4444")
	},
	{
		"id": "eva8", "name": "EVA-8 自动霰弹枪", "en": "EVA-8 Auto", "cat": "SHOTGUN", "ammo": "shotgun",
		"rpm": 148.0, "dmg": 9, "head": 1.25, "legs": 1.00, "pellets": 8, "pellet_pattern": "fig8_8",
		"mag": 8, "mag_tiers": [8, 8, 8, 8], "reload": 2.50, "reload_empty": 2.80,
		"reload_style": "lmg_box", "archetype": "drum_shotgun",
		"rec_len": 0.46, "barrel_len": 0.34, "mag_curve": 0.0, "stock_type": "crane",
		"spread": 0.028, "ads_spread": 0.020, "ads_move_scale": 0.85,
		"recoil_v": 0.018, "recoil_h": 0.004, "proj_speed": 180.0, "grav_scale": 0.5,
		"fire_modes": ["auto", "burst"], "color": Color("#334155"), "accent": Color("#ef4444")
	},
	{
		"id": "mozambique", "name": "莫桑比克霰弹手枪", "en": "Mozambique Shotgun", "cat": "SHOTGUN", "ammo": "shotgun",
		"rpm": 150.0, "dmg": 16, "head": 1.35, "legs": 1.00, "pellets": 3, "pellet_pattern": "tri_3",
		"mag": 6, "mag_tiers": [6, 6, 6, 6], "reload": 1.80, "reload_empty": 2.25,
		"reload_style": "smg_fast", "archetype": "pistol_shotgun",
		"rec_len": 0.28, "barrel_len": 0.22, "mag_curve": 0.0, "stock_type": "pistol",
		"spread": 0.020, "ads_spread": 0.009, "ads_move_scale": 1.00,
		"recoil_v": 0.016, "recoil_h": 0.003, "proj_speed": 165.0, "grav_scale": 0.6,
		"fire_modes": ["auto"], "color": Color("#e2e8f0"), "accent": Color("#ef4444")
	},

	# ==================== 7. PISTOLS (PISTOL - 手枪, ADS移速 1.00x) ====================
	{
		"id": "wingman", "name": "辅助手枪（小帮手）", "en": "Wingman", "cat": "PISTOL", "ammo": "sniper",
		"rpm": 162.0, "dmg": 48, "head": 2.15, "legs": 0.90, "pellets": 1, "pellet_pattern": "single",
		"mag": 6, "mag_tiers": [6, 7, 8, 9], "reload": 1.95, "reload_empty": 1.95,
		"reload_style": "revolver_swing", "archetype": "revolver_pistol",
		"rec_len": 0.24, "barrel_len": 0.22, "mag_curve": 0.0, "stock_type": "pistol",
		"spread": 0.007, "ads_spread": 0.0004, "ads_move_scale": 1.00,
		"recoil_v": 0.025, "recoil_h": 0.0025, "proj_speed": 210.0, "grav_scale": 1.0,
		"fire_modes": ["single"], "color": Color("#e2e8f0"), "accent": Color("#f59e0b")
	},
	{
		"id": "re45", "name": "RE-45 自动手枪（锤击点）", "en": "RE-45 Auto", "cat": "PISTOL", "ammo": "light",
		"rpm": 780.0, "dmg": 14, "head": 1.55, "legs": 0.90, "pellets": 1, "pellet_pattern": "single",
		"mag": 16, "mag_tiers": [16, 19, 22, 25], "reload": 1.40, "reload_empty": 1.80,
		"reload_style": "smg_fast", "archetype": "auto_pistol",
		"rec_len": 0.22, "barrel_len": 0.16, "mag_curve": 0.14, "stock_type": "pistol",
		"spread": 0.010, "ads_spread": 0.0020, "ads_move_scale": 1.00,
		"recoil_v": 0.010, "recoil_h": 0.004, "proj_speed": 210.0, "grav_scale": 1.05,
		"fire_modes": ["auto"], "color": Color("#475569"), "accent": Color("#f97316")
	},
	{
		"id": "p2020", "name": "P2020 半自动手枪（锤击点）", "en": "P2020", "cat": "PISTOL", "ammo": "light",
		"rpm": 430.0, "dmg": 21, "head": 1.60, "legs": 0.90, "pellets": 1, "pellet_pattern": "single",
		"mag": 14, "mag_tiers": [14, 16, 18, 21], "reload": 1.20, "reload_empty": 1.20,
		"reload_style": "smg_fast", "archetype": "semi_pistol",
		"rec_len": 0.20, "barrel_len": 0.15, "mag_curve": 0.08, "stock_type": "pistol",
		"spread": 0.006, "ads_spread": 0.0008, "ads_move_scale": 1.00,
		"recoil_v": 0.010, "recoil_h": 0.002, "proj_speed": 200.0, "grav_scale": 1.05,
		"fire_modes": ["single"], "color": Color("#94a3b8"), "accent": Color("#f97316")
	}
]

const MAP_POIS: Array = [
	{"id": "skull_town", "name": "骷髅镇 Skull Town", "pos": Vector2(-165, 145), "color": Color("#f59e0b"), "buildings": 5, "beacon": true, "crafter": true},
	{"id": "fragment_east", "name": "碎片东部 Fragment East", "pos": Vector2(68, -68), "color": Color("#ff1e42"), "buildings": 5, "beacon": true, "crafter": true},
	{"id": "bunker", "name": "地堡通道 Bunker Pass", "pos": Vector2(-88, -32), "color": Color("#a855f7"), "buildings": 3, "beacon": false, "crafter": false},
	{"id": "labs", "name": "辛迪加实验室 Labs Dome", "pos": Vector2(155, -35), "color": Color("#38bdf8"), "buildings": 4, "beacon": true, "crafter": true},
	{"id": "artillery", "name": "炮兵阵地 Artillery", "pos": Vector2(-20, -185), "color": Color("#f59e0b"), "buildings": 4, "beacon": true, "crafter": true},
	{"id": "airbase", "name": "换气空军基地 Airbase", "pos": Vector2(-195, -45), "color": Color("#38bdf8"), "buildings": 4, "beacon": true, "crafter": false},
	{"id": "market", "name": "集市中心 Market", "pos": Vector2(-85, 95), "color": Color("#a855f7"), "buildings": 4, "beacon": false, "crafter": true},
	{"id": "water_treat", "name": "水处理厂 Water Treatment", "pos": Vector2(10, 195), "color": Color("#22c55e"), "buildings": 4, "beacon": true, "crafter": true},
	{"id": "thunderdome", "name": "雷电圆顶 Thunderdome", "pos": Vector2(-185, 205), "color": Color("#ff1e42"), "buildings": 3, "beacon": true, "crafter": false},
	{"id": "energy_depot", "name": "能源中心 Energy Depot", "pos": Vector2(125, -145), "color": Color("#38bdf8"), "buildings": 4, "beacon": false, "crafter": true},
	{"id": "launch_site", "name": "飞升火箭场 Launch Site", "pos": Vector2(175, 155), "color": Color("#f97316"), "buildings": 5, "beacon": true, "crafter": true},
	{"id": "watchtower", "name": "斥候北塔 Watchtower", "pos": Vector2(-125, -155), "color": Color("#a855f7"), "buildings": 3, "beacon": true, "crafter": false}
]

const EVO_TIERS: Array = [
	{"level": 1, "name": "Lv.1 白甲（普通）", "max_shield": 50, "segments": 2, "color": Color("#e2e8f0"), "next_evo": 150},
	{"level": 2, "name": "Lv.2 蓝甲（稀有）", "max_shield": 75, "segments": 3, "color": Color("#38bdf8"), "next_evo": 400},
	{"level": 3, "name": "Lv.3 紫甲（史诗）", "max_shield": 100, "segments": 4, "color": Color("#a855f7"), "next_evo": 750},
	{"level": 4, "name": "Lv.4 金甲（传说）", "max_shield": 100, "segments": 4, "color": Color("#f59e0b"), "next_evo": 750},
	{"level": 5, "name": "Lv.5 红甲（神话）", "max_shield": 125, "segments": 5, "color": Color("#ff1e42"), "next_evo": 9999}
]

const OPTICS: Array = [
	{"id": "1x_hcog", "name": "1倍 全息衍射式瞄准镜“经典”", "fov": 62.0, "alt_fov": 62.0, "variable": false},
	{"id": "2x_bruiser", "name": "2倍 全息衍射式瞄准镜“格斗家”", "fov": 46.0, "alt_fov": 46.0, "variable": false},
	{"id": "1x_holo", "name": "1倍-2倍 可变式幻影瞄准镜", "fov": 60.0, "alt_fov": 45.0, "variable": true},
	{"id": "3x_ranger", "name": "3倍 全息衍射式瞄准镜“游骑兵”", "fov": 34.0, "alt_fov": 34.0, "variable": false},
	{"id": "2x_4x_aog", "name": "2倍-4倍 可变式高级光学瞄准镜", "fov": 45.0, "alt_fov": 26.0, "variable": true},
	{"id": "1x_threat", "name": "1倍 数字化威胁（热成像高亮）", "fov": 58.0, "alt_fov": 58.0, "variable": false},
	{"id": "6x_kraber", "name": "6倍-10倍 可变式狙击手光学镜", "fov": 20.0, "alt_fov": 12.0, "variable": true}
]

func get_legend_by_id(id: String) -> Dictionary:
	for l in LEGENDS:
		if l["id"] == id:
			return l
	return LEGENDS[0]

func get_weapon_by_id(id: String) -> Dictionary:
	if id == "empty" or id == "":
		return {
			"id": "empty", "name": "无武器", "cat": "MELEE", "ammo": "none",
			"mag": 0, "mag_tiers": [0, 0, 0, 0], "pellets": 1, "pellet_pattern": "single",
			"color": Color("#475569"), "accent": Color("#64748b")
		}
	for w in WEAPONS:
		if w["id"] == id:
			return w
	return WEAPONS[0]

func get_weapon_mag_capacity(id: String, mag_tier: int = 0) -> int:
	var w: Dictionary = get_weapon_by_id(id)
	var tiers: Array = w.get("mag_tiers", [])
	if tiers.size() > 0:
		return int(tiers[clampi(mag_tier, 0, tiers.size() - 1)])
	return int(w.get("mag", 20))

func get_shotgun_bolt_fire_mult(bolt_tier: int) -> float:
	match bolt_tier:
		1: return 1.12
		2: return 1.22
		3, 4: return 1.35
		_: return 1.00

## Returns UNIT-NORMALIZED 2D offsets in [-1.0, 1.0] for authentic Apex Legends shotgun & multi-pellet patterns.
## Note: Callers multiply these unit coordinates by `spread` (radians) for 3D ballistics or `grid_scale` (pixels) for HUD!
func get_pellet_pattern_offsets(pattern_name: String, _pellets_or_unused: float = 1.0) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	match pattern_name:
		"star_11":
			# Peacekeeper 11-pellet 5-pointed Sheriff Star pattern (1 center + 5 inner + 5 outer star tips)
			pts.append(Vector2.ZERO)
			for i in range(5):
				var ang_in: float = -PI * 0.5 + float(i) * (TAU / 5.0) + (PI / 5.0)
				pts.append(Vector2(cos(ang_in), sin(ang_in)) * 0.46)
				var ang_out: float = -PI * 0.5 + float(i) * (TAU / 5.0)
				pts.append(Vector2(cos(ang_out), sin(ang_out)) * 0.92)
		"line_8":
			# Mastiff 8-pellet Horizontal Flat Line pattern
			var norm_xs := [-0.95, -0.66, -0.38, -0.12, 0.12, 0.38, 0.66, 0.95]
			for nx in norm_xs:
				pts.append(Vector2(float(nx), 0.0))
		"fig8_8":
			# EVA-8 8-pellet Figure-8 (双环8字形) pattern
			var coords := [
				Vector2(0.0, -0.82), Vector2(-0.52, -0.52), Vector2(0.52, -0.52), Vector2(0.0, -0.15),
				Vector2(0.0, 0.15), Vector2(-0.52, 0.52), Vector2(0.52, 0.52), Vector2(0.0, 0.82)
			]
			for c in coords:
				pts.append(c)
		"tri_3":
			# Mozambique 3-pellet Triangle Drill (1 top head, 2 bottom torso)
			pts.append(Vector2(0.0, -0.62))
			pts.append(Vector2(-0.56, 0.44))
			pts.append(Vector2(0.56, 0.44))
		"triple_3":
			# Triple Take 3 horizontal energy bolts
			pts.append(Vector2(-0.85, 0.0))
			pts.append(Vector2(0.0, 0.0))
			pts.append(Vector2(0.85, 0.0))
		"shatter_7":
			# Bocek Shatter Caps 7-pellet pattern (center + 6 triangle ring)
			pts.append(Vector2.ZERO)
			for i in range(6):
				var ang: float = float(i) * (TAU / 6.0)
				pts.append(Vector2(cos(ang), sin(ang)) * 0.85)
		_:
			pts.append(Vector2.ZERO)
	return pts

func get_evo_tier(level: int) -> Dictionary:
	for t in EVO_TIERS:
		if t["level"] == level:
			return t
	return EVO_TIERS[0]

func get_optic_by_id(id: String) -> Dictionary:
	for o in OPTICS:
		if o["id"] == id:
			return o
	return OPTICS[1]

func get_consumable_name(id: String) -> String:
	match id:
		"shield_battery": return "大型护盾电池"
		"shield_cell": return "小型护盾电池"
		"med_kit": return "医疗箱"
		"syringe": return "注射器"
		"phoenix_kit": return "凤凰治疗包"
		_: return id

func get_consumable_cast_time(id: String, has_gold_armor: bool = false) -> float:
	var base_t: float = 3.0
	match id:
		"shield_cell": base_t = 3.0
		"shield_battery": base_t = 5.0
		"syringe": base_t = 5.0
		"med_kit": base_t = 8.0
		"phoenix_kit": base_t = 10.0
	if has_gold_armor and (id == "shield_cell" or id == "syringe"):
		base_t *= 0.65
	return base_t
