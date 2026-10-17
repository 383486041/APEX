extends Node
## GameData Autoload Singleton
## Complete database for 5 Classes, 12 Legends, 22 Weapons, Optics, Consumables, Evo Tiers & 12 POIs.

const CLASSES: Dictionary = {
	"ASSAULT": {
		"id": "ASSAULT", "name": "突击定位", "en": "Assault", "color": Color("#ef4444"),
		"perks": [
			"开启红色武器补给仓隐藏隔层（必出高阶智能配件）",
			"每格背包弹药堆叠上限提升 35%，额外投掷物栏位",
			"破敌护盾后获得 3 秒换弹加速与 20% 机动移速提升"
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
			"扫描敌方目标后全队获得短暂追踪视野共享"
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
			"开启蓝色支援补给仓隐藏隔层（必出大电与医疗箱）",
			"使用恢复品时移速不减，扶起倒地队友速度提升 35% 并附带生命回复",
			"队友阵亡箱内自动生成移动重生信标，可在复制器制造全队旗帜"
		]
	}
}

const LEGENDS: Array = [
	{
		"id": "wraith", "name": "恶灵", "en": "WRAITH", "title": "跨维度决斗者", "class_id": "SKIRMISHER",
		"primary_color": Color("#312e81"), "secondary_color": Color("#93c5fd"), "visor_color": Color("#c4b5fd"),
		"scale": Vector3(0.9, 0.95, 0.9),
		"heirloom": {"name": "希望之暮（苦无 Kunai）", "color": Color("#8b5cf6")},
		"passive_name": "魔音传脑", "passive_desc": "被瞄准或附近敌队密集时虚空之声自动发出预警。",
		"tac_name": "踏入虚空", "tac_cd": 20.0, "tac_desc": "进入虚空通道 4 秒免疫伤害并提升 35% 移速。",
		"ult_name": "维度裂隙", "ult_cd": 120.0, "ult_desc": "建立连接两地的双向跨维度传送门。",
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
		"scale": Vector3(0.92, 0.96, 0.92),
		"heirloom": {"name": "辛烷蝴蝶刀（Butterfly Knife）", "color": Color("#22c55e")},
		"passive_name": "高速修复", "passive_desc": "脱离受击后每秒自动恢复 3.0 点生命值。",
		"tac_name": "兴奋剂", "tac_cd": 2.0, "tac_desc": "消耗少量生命值，6 秒内冲刺速度提升 35%。",
		"ult_name": "跳垫", "ult_cd": 60.0, "ult_desc": "部署高压弹射跳垫，踩踏后高空弹射并可执行二段跳。",
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
		"passive_name": "追踪器", "passive_desc": "感知敌方足迹与白色渡鸦线索。",
		"tac_name": "上帝之眼", "tac_cd": 22.0, "tac_desc": "释放声呐脉冲透视高亮 90 米内所有敌方目标 4.5 秒。",
		"ult_name": "狩猎野兽", "ult_cd": 110.0, "ult_desc": "强化感官 18 秒，热成像视野并提升 35% 移速。",
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
		"scale": Vector3(1.02, 1.06, 1.02),
		"heirloom": {"name": "拳击手套（Boxing Gloves）", "color": Color("#38bdf8")},
		"passive_name": "内线情报", "passive_desc": "扫描信标立即刷新滑索枪并缩短冷却。",
		"tac_name": "钩爪", "tac_cd": 16.0, "tac_desc": "发射抓钩执行大摆锤弧线高速飞跃。",
		"ult_name": "滑索枪", "ult_cd": 90.0, "ult_desc": "架设供全队高速滑行转移的高空钢缆滑索。",
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
		"scale": Vector3(0.9, 0.94, 0.9),
		"heirloom": {"name": "电击鼓槌（Shock Sticks）", "color": Color("#ec4899")},
		"passive_name": "战斗医疗兵 & 滑翔", "passive_desc": "部署 D.O.C. 自动扶人并可借助无人机高空滑翔。",
		"tac_name": "D.O.C. 治疗无人机", "tac_cd": 22.0, "tac_desc": "召唤跟随队友治疗的慈悲无人机持续恢复生命。",
		"ult_name": "D.O.C. 光环护盾", "ult_cd": 120.0, "ult_desc": "展开不可穿透的医疗能量光环并空投高阶护盾与补给。",
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
		"scale": Vector3(1.22, 1.12, 1.22),
		"heirloom": {"name": "战斧火炬（War Club）", "color": Color("#f97316")},
		"passive_name": "枪盾 & 强化装甲", "passive_desc": "开镜展开 50 HP 能量臂盾，全身减伤 15%。",
		"tac_name": "保护圆顶", "tac_cd": 24.0, "tac_desc": "投掷圆顶能量力场阻挡一切内外子弹与轰炸 12 秒。",
		"ult_name": "防御性轰炸", "ult_cd": 130.0, "ult_desc": "呼叫密集迫击炮群轰炸目标区域。",
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
		"passive_name": "疾步", "passive_desc": "受击或被压制时立即触发 30% 爆发移速加成。",
		"tac_name": "烟雾发射器", "tac_cd": 16.0, "tac_desc": "发射高爆烟雾榴弹形成浓密战术烟墙。",
		"ult_name": "雷鸣滚滚", "ult_cd": 120.0, "ult_desc": "呼叫地毯式推进火炮阵列轰炸。",
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
		"scale": Vector3(0.9, 0.98, 0.9),
		"heirloom": {"name": "最强之刃（Strongest Link 双节刀）", "color": Color("#06b6d4")},
		"passive_name": "死神烙印", "passive_desc": "洞察全图死亡之箱并扫描幸存敌队。",
		"tac_name": "电弧陷阱", "tac_cd": 18.0, "tac_desc": "掷出旋转电弧飞盘造成电击伤害并束缚敌人。",
		"ult_name": "相位裂隙", "ult_cd": 90.0, "ult_desc": "挥剑斩开单向相位传送裂缝瞬间突进。",
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
		"scale": Vector3(0.92, 0.98, 0.92),
		"heirloom": {"name": "引力大锤（Gravity Maw）", "color": Color("#3b82f6")},
		"passive_name": "太空步", "passive_desc": "消除高空坠落硬直并大幅强化空中变向控制。",
		"tac_name": "重力电梯", "tac_cd": 20.0, "tac_desc": "生成垂直反重力上升气流托举小队升空。",
		"ult_name": "黑洞", "ult_cd": 125.0, "ult_desc": "部署纽特制造微型黑洞强力吸附周围敌人。",
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
		"scale": Vector3(0.92, 0.97, 0.92),
		"heirloom": {"name": "朱雀战矛（Suzaku）", "color": Color("#f59e0b")},
		"passive_name": "VTOL 喷气背包", "passive_desc": "空中按跳跃启动喷气背包悬停飞行，跳伞自动扫描。",
		"tac_name": "导弹群", "tac_cd": 22.0, "tac_desc": "肩部发射 12 枚微型制导火箭弹轰炸并眩晕目标。",
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
		"scale": Vector3(1.16, 1.08, 1.16),
		"heirloom": {"name": "死亡之锤（Death Hammer）", "color": Color("#84cc16")},
		"passive_name": "夜神视线 & 强化装甲", "passive_desc": "透视毒气内敌人，全身减伤 15%。",
		"tac_name": "夜神毒气陷阱", "tac_cd": 16.0, "tac_desc": "放置充气毒气罐，触发后释放持续扣血绿雾。",
		"ult_name": "夜神毒气手雷", "ult_cd": 120.0, "ult_desc": "投掷大范围高浓缩夜神毒气手雷覆盖决赛圈。",
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
		"tac_name": "疯猫全息诱饵", "tac_cd": 14.0, "tac_desc": "派出全息诱饵分身，受击时暴露敌方位置。",
		"ult_name": "派对焦点", "ult_cd": 60.0, "ult_desc": "短暂隐身并召唤 6 个同步动作的全息幻象分身。",
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

const WEAPONS: Array = [
	{"id": "r301", "name": "R-301 卡宾枪", "cat": "AR", "ammo": "light", "rpm": 810.0, "dmg": 14, "head": 1.75, "pellets": 1, "mag": 28, "reload": 1.85, "reload_style": "ar_tactical", "rec_len": 0.48, "barrel_len": 0.38, "mag_curve": 0.22, "stock_type": "crane", "spread": 0.011, "ads_spread": 0.002, "color": Color("#d8dee9"), "accent": Color("#f97316")},
	{"id": "flatline", "name": "VK-47 平行步枪", "cat": "AR", "ammo": "heavy", "rpm": 600.0, "dmg": 19, "head": 1.75, "pellets": 1, "mag": 30, "reload": 2.10, "reload_style": "bullpup", "rec_len": 0.52, "barrel_len": 0.30, "mag_curve": 0.28, "stock_type": "bullpup", "spread": 0.015, "ads_spread": 0.0035, "color": Color("#2e3440"), "accent": Color("#14b8a6")},
	{"id": "nemesis", "name": "复仇女神连发步枪", "cat": "AR", "ammo": "energy", "rpm": 680.0, "dmg": 17, "head": 1.75, "pellets": 1, "mag": 32, "reload": 2.00, "reload_style": "energy_cell", "rec_len": 0.54, "barrel_len": 0.42, "mag_curve": 0.0, "stock_type": "heavy", "spread": 0.010, "ads_spread": 0.002, "color": Color("#1e293b"), "accent": Color("#84cc16")},
	{"id": "havoc", "name": "哈沃克步枪（涡轮）", "cat": "AR", "ammo": "energy", "rpm": 672.0, "dmg": 18, "head": 1.75, "pellets": 1, "mag": 36, "reload": 2.25, "reload_style": "energy_cell", "rec_len": 0.50, "barrel_len": 0.36, "mag_curve": 0.0, "stock_type": "heavy", "spread": 0.014, "ads_spread": 0.003, "color": Color("#475569"), "accent": Color("#a3e635")},
	{"id": "r99", "name": "R-99 冲锋枪", "cat": "SMG", "ammo": "light", "rpm": 1080.0, "dmg": 12, "head": 1.5, "pellets": 1, "mag": 27, "reload": 1.55, "reload_style": "smg_fast", "rec_len": 0.34, "barrel_len": 0.22, "mag_curve": 0.15, "stock_type": "wire", "spread": 0.017, "ads_spread": 0.0045, "color": Color("#94a3b8"), "accent": Color("#f97316")},
	{"id": "volt", "name": "电能冲锋枪", "cat": "SMG", "ammo": "energy", "rpm": 720.0, "dmg": 15, "head": 1.5, "pellets": 1, "mag": 26, "reload": 1.65, "reload_style": "energy_cell", "rec_len": 0.38, "barrel_len": 0.25, "mag_curve": 0.08, "stock_type": "crane", "spread": 0.011, "ads_spread": 0.0022, "color": Color("#f8fafc"), "accent": Color("#38bdf8")},
	{"id": "car", "name": "C.A.R. 冲锋枪", "cat": "SMG", "ammo": "heavy", "rpm": 930.0, "dmg": 13, "head": 1.5, "pellets": 1, "mag": 27, "reload": 1.60, "reload_style": "smg_fast", "rec_len": 0.36, "barrel_len": 0.23, "mag_curve": 0.20, "stock_type": "crane", "spread": 0.016, "ads_spread": 0.0045, "color": Color("#334155"), "accent": Color("#f59e0b")},
	{"id": "alternator", "name": "转换者冲锋枪（干扰器）", "cat": "SMG", "ammo": "light", "rpm": 600.0, "dmg": 19, "head": 1.5, "pellets": 1, "mag": 27, "reload": 1.55, "reload_style": "smg_fast", "rec_len": 0.30, "barrel_len": 0.18, "mag_curve": 0.05, "stock_type": "wire", "spread": 0.009, "ads_spread": 0.0018, "color": Color("#d97706"), "accent": Color("#f8fafc")},
	{"id": "spitfire", "name": "M600 喷火轻机枪", "cat": "LMG", "ammo": "light", "rpm": 540.0, "dmg": 18, "head": 1.75, "pellets": 1, "mag": 50, "reload": 2.55, "reload_style": "lmg_box", "rec_len": 0.58, "barrel_len": 0.48, "mag_curve": 0.0, "stock_type": "heavy", "spread": 0.018, "ads_spread": 0.0045, "color": Color("#3f6212"), "accent": Color("#facc15")},
	{"id": "rampage", "name": "暴走轻机枪（铝热剂充能）", "cat": "LMG", "ammo": "heavy", "rpm": 420.0, "dmg": 26, "head": 1.75, "pellets": 1, "mag": 40, "reload": 2.45, "reload_style": "lmg_box", "rec_len": 0.60, "barrel_len": 0.50, "mag_curve": 0.18, "stock_type": "heavy", "spread": 0.014, "ads_spread": 0.0032, "color": Color("#7f1d1d"), "accent": Color("#f97316")},
	{"id": "devotion", "name": "专注轻机枪（涡轮）", "cat": "LMG", "ammo": "energy", "rpm": 820.0, "dmg": 15, "head": 1.75, "pellets": 1, "mag": 48, "reload": 2.65, "reload_style": "lmg_box", "rec_len": 0.56, "barrel_len": 0.45, "mag_curve": 0.0, "stock_type": "heavy", "spread": 0.019, "ads_spread": 0.0048, "color": Color("#1e293b"), "accent": Color("#38bdf8")},
	{"id": "g7", "name": "G7 侦察枪", "cat": "MARKSMAN", "ammo": "light", "rpm": 240.0, "dmg": 33, "head": 1.75, "pellets": 1, "mag": 20, "reload": 2.00, "reload_style": "ar_tactical", "rec_len": 0.54, "barrel_len": 0.46, "mag_curve": 0.06, "stock_type": "sniper", "spread": 0.013, "ads_spread": 0.001, "color": Color("#64748b"), "accent": Color("#f97316")},
	{"id": "tripletake", "name": "三重式狙击枪", "cat": "MARKSMAN", "ammo": "energy", "rpm": 110.0, "dmg": 21, "head": 1.75, "pellets": 3, "mag": 27, "reload": 2.15, "reload_style": "energy_cell", "rec_len": 0.56, "barrel_len": 0.52, "mag_curve": 0.0, "stock_type": "sniper", "spread": 0.016, "ads_spread": 0.0035, "color": Color("#0f172a"), "accent": Color("#a3e635")},
	{"id": "bocek", "name": "博切克复合弓（神话）", "cat": "MARKSMAN", "ammo": "mythic", "rpm": 150.0, "dmg": 70, "head": 1.85, "pellets": 1, "mag": 60, "reload": 0.65, "reload_style": "bow_draw", "rec_len": 0.25, "barrel_len": 0.20, "mag_curve": 0.0, "stock_type": "bow", "spread": 0.003, "ads_spread": 0.0005, "color": Color("#ff1e42"), "accent": Color("#fbbf24")},
	{"id": "kraber", "name": "克雷贝尔 .50 狙击步枪（神话）", "cat": "SNIPER", "ammo": "mythic", "rpm": 42.0, "dmg": 140, "head": 2.0, "pellets": 1, "mag": 4, "reload": 2.95, "reload_style": "bolt_sniper", "rec_len": 0.64, "barrel_len": 0.72, "mag_curve": 0.0, "stock_type": "sniper", "spread": 0.028, "ads_spread": 0.0001, "color": Color("#991b1b"), "accent": Color("#fbbf24")},
	{"id": "sentinel", "name": "哨兵狙击步枪（充能）", "cat": "SNIPER", "ammo": "sniper", "rpm": 55.0, "dmg": 70, "head": 2.0, "pellets": 1, "mag": 7, "reload": 2.35, "reload_style": "bolt_sniper", "rec_len": 0.58, "barrel_len": 0.62, "mag_curve": 0.0, "stock_type": "sniper", "spread": 0.022, "ads_spread": 0.0004, "color": Color("#1e3a8a"), "accent": Color("#38bdf8")},
	{"id": "chargerifle", "name": "充能步枪（滋崩）", "cat": "SNIPER", "ammo": "sniper", "rpm": 52.0, "dmg": 68, "head": 1.75, "pellets": 1, "mag": 8, "reload": 2.65, "reload_style": "energy_cell", "rec_len": 0.62, "barrel_len": 0.52, "mag_curve": 0.0, "stock_type": "sniper", "spread": 0.014, "ads_spread": 0.0001, "color": Color("#334155"), "accent": Color("#ff7700")},
	{"id": "peacekeeper", "name": "和平捍卫者（杠杆转枪）", "cat": "SHOTGUN", "ammo": "shotgun", "rpm": 72.0, "dmg": 9, "head": 1.25, "pellets": 11, "mag": 5, "reload": 2.15, "reload_style": "lever_shotgun", "rec_len": 0.48, "barrel_len": 0.44, "mag_curve": 0.0, "stock_type": "shotgun", "spread": 0.040, "ads_spread": 0.014, "color": Color("#0f172a"), "accent": Color("#38bdf8")},
	{"id": "mastiff", "name": "獒犬霰弹枪", "cat": "SHOTGUN", "ammo": "shotgun", "rpm": 90.0, "dmg": 11, "head": 1.25, "pellets": 8, "mag": 6, "reload": 2.05, "reload_style": "lever_shotgun", "rec_len": 0.50, "barrel_len": 0.42, "mag_curve": 0.0, "stock_type": "shotgun", "spread": 0.046, "ads_spread": 0.018, "color": Color("#78350f"), "accent": Color("#ef4444")},
	{"id": "eva8", "name": "EVA-8 自动霰弹枪", "cat": "SHOTGUN", "ammo": "shotgun", "rpm": 165.0, "dmg": 7, "head": 1.25, "pellets": 8, "mag": 8, "reload": 2.00, "reload_style": "lmg_box", "rec_len": 0.46, "barrel_len": 0.34, "mag_curve": 0.0, "stock_type": "crane", "spread": 0.042, "ads_spread": 0.028, "color": Color("#334155"), "accent": Color("#ef4444")},
	{"id": "wingman", "name": "辅助手枪（小帮手左轮）", "cat": "PISTOL", "ammo": "sniper", "rpm": 156.0, "dmg": 45, "head": 2.15, "pellets": 1, "mag": 9, "reload": 1.70, "reload_style": "revolver_swing", "rec_len": 0.24, "barrel_len": 0.22, "mag_curve": 0.0, "stock_type": "pistol", "spread": 0.010, "ads_spread": 0.001, "color": Color("#e2e8f0"), "accent": Color("#f59e0b")},
	{"id": "re45", "name": "RE-45 自动手枪（锤击点）", "cat": "PISTOL", "ammo": "light", "rpm": 780.0, "dmg": 14, "head": 1.5, "pellets": 1, "mag": 25, "reload": 1.30, "reload_style": "smg_fast", "rec_len": 0.22, "barrel_len": 0.16, "mag_curve": 0.14, "stock_type": "pistol", "spread": 0.014, "ads_spread": 0.0035, "color": Color("#475569"), "accent": Color("#f97316")},
	{"id": "mozambique", "name": "莫桑比克", "cat": "SHOTGUN", "ammo": "shotgun", "rpm": 180.0, "dmg": 15, "head": 1.5, "pellets": 3, "mag": 6, "reload": 1.70, "reload_style": "lever_shotgun", "rec_len": 0.28, "barrel_len": 0.22, "mag_curve": 0.0, "stock_type": "pistol", "spread": 0.032, "ads_spread": 0.012, "color": Color("#e2e8f0"), "accent": Color("#ef4444")},
	{"id": "p2020", "name": "P2020 手枪", "cat": "PISTOL", "ammo": "light", "rpm": 420.0, "dmg": 18, "head": 1.5, "pellets": 1, "mag": 14, "reload": 1.25, "reload_style": "smg_fast", "rec_len": 0.20, "barrel_len": 0.15, "mag_curve": 0.08, "stock_type": "pistol", "spread": 0.010, "ads_spread": 0.002, "color": Color("#94a3b8"), "accent": Color("#f97316")}
]

const MAP_POIS: Array = [
	{"id": "skull_town", "name": "骷髅镇 Skull Town", "pos": Vector2(-165, 145), "color": Color("#f59e0b"), "buildings": 5, "beacon": true, "crafter": true},
	{"id": "fragment_east", "name": "碎片东部 Fragment East", "pos": Vector2(15, -15), "color": Color("#ff1e42"), "buildings": 6, "beacon": true, "crafter": true},
	{"id": "bunker", "name": "地堡通道 Bunker Pass", "pos": Vector2(-65, -20), "color": Color("#a855f7"), "buildings": 3, "beacon": false, "crafter": false},
	{"id": "labs", "name": "辛迪加实验室 Labs Dome", "pos": Vector2(155, -35), "color": Color("#38bdf8"), "buildings": 4, "beacon": true, "crafter": true},
	{"id": "artillery", "name": "炮兵阵地 Artillery", "pos": Vector2(-20, -185), "color": Color("#f59e0b"), "buildings": 4, "beacon": true, "crafter": true},
	{"id": "airbase", "name": "换气空军基地 Airbase", "pos": Vector2(-195, -45), "color": Color("#38bdf8"), "buildings": 4, "beacon": true, "crafter": false},
	{"id": "market", "name": "集市中心 Market", "pos": Vector2(-85, 85), "color": Color("#a855f7"), "buildings": 4, "beacon": false, "crafter": true},
	{"id": "water_treat", "name": "水处理厂 Water Treatment", "pos": Vector2(10, 195), "color": Color("#22c55e"), "buildings": 4, "beacon": true, "crafter": true},
	{"id": "thunderdome", "name": "雷电圆顶 Thunderdome", "pos": Vector2(-185, 205), "color": Color("#ff1e42"), "buildings": 3, "beacon": true, "crafter": false},
	{"id": "energy_depot", "name": "能源中心 Energy Depot", "pos": Vector2(110, -140), "color": Color("#38bdf8"), "buildings": 4, "beacon": false, "crafter": true},
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

func get_legend_by_id(id: String) -> Dictionary:
	for l in LEGENDS:
		if l["id"] == id:
			return l
	return LEGENDS[0]

func get_weapon_by_id(id: String) -> Dictionary:
	if id == "empty" or id == "":
		return {"id": "empty", "name": "无武器", "cat": "MELEE", "ammo": "none", "mag": 0, "color": Color("#475569"), "accent": Color("#64748b")}
	for w in WEAPONS:
		if w["id"] == id:
			return w
	return WEAPONS[0]

func get_evo_tier(level: int) -> Dictionary:
	for t in EVO_TIERS:
		if t["level"] == level:
			return t
	return EVO_TIERS[0]


const OPTICS: Array = [
	{"id": "1x_hcog", "name": "1倍 全息衍射式瞄准镜“经典”", "fov": 62.0, "alt_fov": 62.0, "variable": false},
	{"id": "2x_bruiser", "name": "2倍 全息衍射式瞄准镜“格斗家”", "fov": 46.0, "alt_fov": 46.0, "variable": false},
	{"id": "1x_holo", "name": "1倍-2倍 可变式幻影瞄准镜", "fov": 60.0, "alt_fov": 45.0, "variable": true},
	{"id": "3x_ranger", "name": "3倍 全息衍射式瞄准镜“游骑兵”", "fov": 34.0, "alt_fov": 34.0, "variable": false},
	{"id": "2x_4x_aog", "name": "2倍-4倍 可变式高级光学瞄准镜", "fov": 45.0, "alt_fov": 26.0, "variable": true},
	{"id": "1x_threat", "name": "1倍 数字化威胁（热成像高亮）", "fov": 58.0, "alt_fov": 58.0, "variable": false},
	{"id": "6x_kraber", "name": "6倍-10倍 可变式狙击手光学镜", "fov": 20.0, "alt_fov": 12.0, "variable": true}
]

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

