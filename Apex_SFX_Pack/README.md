# APEX 英雄 原声音效资源库 (Apex Legends SFX Library)

本目录为 **《Apex 英雄》官方原声音效素材库**，已剔除无关冗余杂音，并按 **游戏机制体系（5 大核心模块、37 个细分子目录）** 完成了标准化分类与命名：

---

## 📂 顶层结构一览

```text
Apex_SFX_Pack/
├── 1_Guns/             # 枪械系统动作链原声 (6 大武器类，24 把核心枪械，130+ 个音效)
├── 2_Grenades/         # 投掷物完整音频链 (电弧星、破片雷、铝热剂，20 个音效)
├── 3_Combat_and_HUD/   # 核心战斗反馈与系统音效 (碎甲、击倒、标点、打药、跳伞)
├── 4_Announcer/        # 官方比赛播报员原声 (第一滴血、新击杀王、捍卫者淘汰等)
└── 5_Legends_Voice/    # 传奇专属战斗台词 (动力小子、探路者、幻象、恶灵、侵蚀等)
```

---

## 🎯 详细分类清单

### 1. 枪械系统原声 (`1_Guns/`)
每把武器均按照真实开火动作链细分归档：
- **`Assault_Rifles/` (突击步枪)**
  - `R301_Carbine/`：单发点射 (`Single Shot`)、全自动扫射 (`Spray`)、低弹药提示 (`Low Ammo Shot`)、空仓击发 (`Empty Shot`)、战术换弹 (`Reload`)、空仓完整拉栓换弹 (`Full Reload`)
  - `VK47_Flatline/`：单发、扫射、低弹药、空仓、战术换弹、完整换弹
  - `Havoc_Rifle/`：涡轮增压蓄能开火 (`Charge Up`)、单发、连射、换弹
  - `Hemlok_AR/`：三连发爆发 (`Burst Shot`)、单发点射、三连低弹药、换弹
  - `G7_Scout/`：击发、低弹药、打空、换弹、完整换弹
- **`SMGs/` (冲锋枪)**
  - `R99_SMG/`：超高射速泼水扫射、低弹药提示、清脆弹匣卡扣换弹
  - `Volt_SMG/`：等离子脉冲开火、单发、换弹
  - `Prowler_PDW/`：五连发爆发、单发、全自动、低弹药、换弹
  - `Alternator/`：双管交替射击、全自动、低弹药、换弹
- **`Snipers/` (狙击枪)**
  - `Kraber_50Cal/`：克雷贝尔重炮轰鸣、推弹入膛 (`Chamber`)、拉栓退壳、空仓换弹
  - `Sentinel/`：哨兵大电充能 (`Amping`)、充能过载重击 (`Amped Shot`)、拉栓上膛
  - `Charge_Rifle/`：预充能束线、终结爆裂光束、换弹
  - `Longbow_DMR/`：重型射击、上膛动作、换弹
  - `Triple_Take/`：三重收束射击、换弹
- **`Shotguns/` (霰弹枪)**
  - `Peacekeeper/`：单发轰击、杠杆转枪上膛、精准收束蓄力 (`Choke Charging`)
  - `Mastiff/`：横向爆裂轰鸣、单发装填 (`Single Shell Reload`)、空仓换弹
  - `Eva8_Auto/`：全自动连击、空仓提示、弹鼓换弹
  - `Mozambique/`：三管喷射、低弹药、换弹
- **`LMGs/` (轻机枪)**
  - `Devotion_LMG/`：初始低速点射、转速步进爬升扫射、涡轮增压即时扫射 (`Turbocharger Spray`)
  - `M600_Spitfire/`：沉重压制连射、大容量弹匣换弹
  - `LStar_EMG/`：过热排气警报 (`Spray into Overheat`)、过热换弹
- **`Pistols/` (手枪)**
  - `Wingman/`：辅助手枪重响、左轮转轮摆出换弹
  - `RE45_Auto/`：全自动极速手枪
  - `P2020/`：战术点射与快速换弹

---

### 2. 战术投掷物 (`2_Grenades/`)
包含从握持、投掷到引信与爆炸的完整物理声效：
- **`Arc_Star/` (电弧星)**：准备蓄能 (`Prime`)、切雷 (`Swap`)、掷出破空 (`Throw`)、扎中蜂鸣、近距电爆 (`Detonation`)、远距雷暴残响 (`Distant Explosion`)
- **`Frag_Grenade/` (破片手雷)**：拔环准备、投掷、近距震颤引爆、远距离破片回声
- **`Thermite_Grenade/` (铝热剂燃烧弹)**：准备、掷出、裂地火墙引爆、地面持续燃烧滋滋声 (`Residue`)、目标灼烧受击反馈 (`Hit Sounds`)

---

### 3. 核心战斗反馈与系统音效 (`3_Combat_and_HUD/`)
Apex 灵魂级战斗反馈音效：
- `Shield_Crack.mp3`：护甲破裂高脆爆鸣声（碎盾）
- `Knockdown_Sound.mp3`：击倒敌人专属成就结算音
- `Ping_Sound.mp3`：战术标记与轮盘标点音效
- `Shield_Cell_Heal.mp3`：护甲电池注入充能完毕音效
- `Jumpmaster_Drop.mp3`：跳伞指挥官开局俯冲音乐
- `Evo_Shield_Upgrade.mp3`：进化护甲充能升级音效
- `Mozambique_Here.mp3`：“莫桑比克在这里”经典语音标点
- `Apex_Predator.mp3`：顶尖猎杀者提示音

---

### 4. 官方播报员语音 (`4_Announcer/`)
- `First_Blood.mp3`：第一滴血（First Blood）
- `New_Kill_Leader.mp3`：新击杀王诞生（New Kill Leader Appointed）
- `Apex_Champions.mp3`：你已成为 Apex 捍卫者（You Are The Apex Champions）
- `Champion_Eliminated.mp3`：捍卫者已被淘汰（Champion Eliminated）
- `Care_Package_Delivering.mp3`：空投补给仓运送中
- `Care_Package_Arrived.mp3`：注意空投降落

---

### 5. 传奇战斗语音 (`5_Legends_Voice/`)
- `Octane/`：动力小子（`I have a need for speed`、`Move faster Amigo` 飙车与长跑台词）
- `Pathfinder/`：探路者（`Good Luck Have Fun`、`Ready and Excited`、`Lets go for a ride` 滑索与钩爪语音）
- `Mirage/`：幻象（`You got Bamboozled` 诱饵戏耍语音合集）
- `Wraith/`：恶灵（虚空低语“你在被瞄准”、“危险即将来临”）
- `Caustic/`：侵蚀（“加入我的实验”、毒气陷阱触发）
- `Lifeline/`：命脉（治疗与战术呼叫）
- `Crypto/`：密客（无人机视界）
- `Revenant/`：亡灵（死亡图腾）
- `Gibraltar/`：直布罗陀（战术圆顶护盾）

---

## 🎮 在 Godot 4.3 中直接调用

```gdscript
# 播放碎盾音效
var crack_sfx: AudioStream = load("res://Apex_SFX_Pack/3_Combat_and_HUD/Shield_Crack.mp3")
audio_player.stream = crack_sfx
audio_player.play()

# 播放克雷贝尔开火
var kraber_sfx: AudioStream = load("res://Apex_SFX_Pack/1_Guns/Snipers/Kraber_50Cal/Shot with Chamber.mp3")
```
