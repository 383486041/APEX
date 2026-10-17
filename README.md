# APEX 英雄：外域协议 (Apex Legends Tribute Full Game)

致敬《Apex 英雄》(Apex Legends) 的全套同人游戏工程，采用 **Godot 4.3 3D 引擎 (Forward+)** 原生开发构建。

---

## 📁 目录结构

```text
.
├── Apex_Outlands_Godot4_3/     # Godot 4.3 (Forward+) 3D 完整工程
│   ├── autoload/               # 全局单例 (AudioManager, ItemDatabase, TalentDatabase 等)
│   ├── scenes/                 # 核心场景 (MainLobby, MatchScene, HUD, LootBox 等)
│   ├── scripts/                # 核心逻辑 (PlayerController, WeaponMeshBuilder, AbilitySystem 等)
│   ├── shaders/                # 自定义着色器
│   ├── project.godot           # Godot 4.3 项目配置文件
│   └── README_GODOT4_3.md      # Godot 版详细功能与键位说明
└── README.md
```

---

## 🎮 快速开始

1. 下载并安装 [Godot Engine 4.3](https://godotengine.org/)。
2. 启动 Godot，点击 **导入 (Import)**。
3. 选择 `Apex_Outlands_Godot4_3/project.godot` 文件。
4. 打开项目后按 **F5** 即可直接运行完整 3D 大厅、大逃杀与靶场系统。

---

## 🌟 核心特性

- **12 位传奇完整机制**：恶灵、动力小子、寻血猎犬、探路者、命脉、直布罗陀、邦加罗尔、地平线、艾许、瓦尔基里、侵蚀、幻象的专属被动、战术技能（Q）与终极技能（Z）。
- **高精度模块化 3D 枪械**：多部件组合、带实时 3D 弹药屏、准镜、抛壳与后坐力拟真。
- **三阶段拟真换弹**：卸下弹匣 -> 插入满弹匣 -> 拉栓上膛，带空仓换弹与单发拉栓机制。
- **神话传家宝与连段**：恶灵苦无、动力小子蝴蝶刀、寻血猎犬战斧，支持检视与三段式挥砍连招。
- **滑铲与身法动作**：滑铲跳、蹬墙跳、滑索架设与滑行、弹射跳垫。
