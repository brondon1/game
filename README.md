# 像素地牢

一个类似《元气骑士》的 2D 俯视角 Roguelike 地牢射击游戏骨架，用 **Godot 4.7** 开发。

素材（像素图、音效、背景音乐）目前全是程序生成的占位素材，玩法流程已经完整：

> 主菜单选角色 → 随机地牢（带小地图）→ 进房间锁门、分波刷怪 → 清完开门 → 宝箱房捡武器 → 商店花金币 → 打 Boss → 传送门 → 强化三选一 → 下一层 → 第 3 层 Boss 后通关 / 死亡结算 → 记录最高纪录

## 运行

1. 用 Godot 4.7 打开本目录下的 `project.godot`
2. 按 F5 运行（主场景是 `ui/main_menu.tscn`）

## 操作

| 操作 | 键盘鼠标 | 手柄 |
|---|---|---|
| 移动 | WASD / 方向键 | 左摇杆 |
| 射击 | 鼠标左键 / J | RT / X |
| 切换武器 | Q | Y |
| 角色技能 | 空格 / 鼠标右键 / K | RB |
| 拾取 / 购买 | E | A |
| 全屏地图 | Tab / M | Back |
| 暂停 | Esc / P | Start |

## 角色

| 角色 | 生命 | 护盾 | 能量 | 速度 | 技能 |
|---|---|---|---|---|---|
| 骑士 | 7 | 5 | 180 | 慢 | **双持**：5 秒内副手拿起另一把武器，两把一起开火（冷却 10 秒） |
| 游侠 | 5 | 4 | 200 | 快 | **翻滚**：朝移动方向快速翻滚，翻滚中无敌（冷却 1.5 秒） |
| 法师 | 4 | 3 | 260 | 中 | **元素新星**：清除身边的敌方子弹，向四周放出 20 颗穿透弹（冷却 6 秒） |

技能冷却从效果结束后开始计算，冷却进度显示在左下角。游戏会记住上次选的角色。

瞄准默认是**自动瞄准**：瞄准视线内最近的敌人，附近没有敌人时朝鼠标方向瞄准。可以在 `player/player.tscn` 的检查器里关掉 `auto_aim`，改成纯鼠标瞄准。

## 项目结构

```
autoload/
  events.gd            全局信号总线（玩家死亡、房间清空、Boss 血量、屏幕震动）
  game_state.gd        一局的状态：所选角色、血量/护盾/能量、武器、楼层、Buff 列表、存档
  sound.gd             音效和背景音乐管理器，音量设置
characters/            角色数据（CharacterData）：骑士、游侠、法师
skills/                技能基类 skill.gd，以及双持、翻滚、元素新星
player/                玩家：移动、自动瞄准、射击、技能、受伤、护盾回复、拾取武器
weapons/
  weapon_data.gd       武器数据（Resource）
  data/*.tres          枪：手枪、霰弹枪、冲锋枪、穿甲步枪；近战：骑士剑、大铁锤
  weapon.gd            按 WeaponData 开火或挥砍（玩家和敌人都能用）
  bullet.gd            子弹：阵营决定和谁碰撞
enemies/
  enemy.gd             敌人基类：出生预警、追击、接触伤害、闪白、击退、掉落
  gunner.gd            远程怪：保持距离、绕圈走位、扇形射击
  boss.gd              Boss：追击 / 环形弹幕 / 扇形连射 循环
dungeon/
  dungeon_generator.gd 随机游走生成房间布局，最远的房间是 Boss 房
  dungeon.gd           把布局铺成 TileMap、挖走廊、放门，处理过关/死亡流程
  room.gd              房间：进门锁门、分波刷怪、清空开门；宝箱房放奖励；商店房放商人和商品
  door.gd / portal.gd  门、传送门
pickups/               金币、能量、药水、地上的武器
shop/                  商店商品（武器、药水、能量瓶、神秘强化）
common/                命中粒子、挥砍刀光、受击闪白 shader、震屏相机
ui/                    主菜单、HUD、小地图、全屏地图、Buff 三选一、暂停菜单、结算
assets/sprites/        占位像素图（可直接替换）
assets/audio/          占位音效和背景音乐（可直接替换）
default_bus_layout.tres 音频总线：Music、SFX
```

**碰撞层**（在 项目设置 → Layer Names → 2D Physics 里有命名）：
1 墙和门 · 2 玩家 · 3 敌人 · 4 玩家子弹 · 5 敌人子弹 · 6 掉落物

## 怎么扩展

**加一把新武器**：在 `weapons/data/` 里右键新建一个 `WeaponData` 资源，填写伤害、射速、能耗、子弹数、散射等参数，然后把它加进 `autoload/game_state.gd` 的 `weapon_pool`。宝箱房会随机掉落它，不需要写代码。

**加一把近战武器**：同样新建一个 `WeaponData` 资源，勾选“近战”分组里的 `is_melee`，再设置挥砍半径、扇形角度、击退倍率，以及能不能打掉敌人的子弹（骑士剑可以，大铁锤不行但伤害高、击退远）。近战武器只用到射击参数里的伤害、射击间隔和能耗。

**加一个新角色**：在 `characters/` 里新建一个 `CharacterData` 资源，设置贴图、属性、初始武器和技能场景，再把路径加到 `game_state.gd` 的 `CHARACTER_PATHS`，主菜单会自动出现。

**加一个新技能**：新建一个脚本 `extends Skill`，在 `_activate()` 里写效果；有持续时间的技能在 `_end()` 里撤销效果。然后新建一个场景，根节点是 Node 并挂上这个脚本，在检查器里填名字、描述、冷却、持续时间和音效。玩家身上可以直接用的能力有：`start_dash()`（冲刺并无敌）、`set_offhand()`（副手武器）、`aim_direction`（瞄准方向）。

**加一种新敌人**：新建一个脚本 `extends Enemy`，重写 `_think(delta)`，返回每帧想移动的方向，需要开枪时调用 `shoot_bullet()`，可以参考 `gunner.gd`。再复制一份 `slime.tscn` 换上新贴图和脚本，最后在 `room.gd` 的 `_random_wave()` 里把它加进刷怪列表。

**加一个新 Buff**：在 `game_state.gd` 的 `BUFFS` 里加一条，再在 `apply_buff()` 里写上效果。

**小地图和全屏地图**：`ui/minimap.gd` 用地牢生成器输出的网格数据来画，只显示去过的房间和与之相邻的房间。宝箱房是黄点，商店是绿点，Boss 房是红点，青色小点是玩家。方块大小和间距可以改 `ROOM_SIZE` / `SPACING`。全屏地图（`ui/map_overlay.tscn`）复用同一个脚本，只是勾选了 `fit_all`，会把所有已知房间按整数倍放大铺满画面。

**商店**：每层有一个商店房，卖一把随机武器、生命药水、能量瓶和神秘强化（随机一个 Buff），价格随楼层上涨。商品种类和价格在 `room.gd` 的 `_spawn_shop()` 里调，效果在 `shop/shop_item.gd` 里。买武器时背包满了，换下来的武器会放在地上。

**可交互物体**：按 E 交互的东西（地上的武器、商店商品）都是带 `interact(player)` 方法的 Area2D。玩家走近时调用 `player.add_interactable(self)`，离开时调用 `remove_interactable(self)`，按 E 会和最近的那个交互。加宝箱、传送点、NPC 对话都可以照这个写。

**音效和音乐**：在任何脚本里调用 `Sound.play(音频资源, 音量dB, 音高随机幅度)` 播放音效，`Sound.play_music(音频资源)` 切换背景音乐；常用的音效都在 `autoload/sound.gd` 里定义成了常量。每把武器的开火音效在它的 `WeaponData` 资源里配置。同一个音效 30 毫秒内只会播放一次，所以大量子弹同时命中也不会爆音。背景音乐有两首：地牢和 Boss 战，进入 Boss 房时自动切换。暂停菜单里可以分别调节音乐和音效的音量，设置保存在 `user://settings.cfg`。

替换音频：直接覆盖 `assets/audio/` 下的同名文件就行，也可以用 .ogg 或 .mp3，改一下引用路径即可。背景音乐需要在 Godot 的导入面板里把 Loop Mode 设为 Forward。推荐用 [jsfxr](https://sfxr.me/) 制作 8-bit 音效。

**调难度**：
- 楼层数：`GameState.FINAL_FLOOR`
- 房间数：`room_count()`
- 敌人血量成长：`enemy_hp_mult()`
- 每波敌人数量和远程怪比例：`Room._random_wave()`
- 每个房间刷几波：`Room._on_trigger_body_entered()`

**换美术**：直接替换 `assets/sprites/` 下的同名 PNG 就行，尺寸可以不同。地板和墙在 `tiles.png` 里：左边 16×16 是地板，右边 16×16 是墙，碰撞配置在 `dungeon/tileset.tres`。推荐的免费素材：
- [0x72 16x16 DungeonTileset II](https://0x72.itch.io/dungeontileset-ii)：风格和元气骑士很像
- Kenney 的 Tiny Dungeon

**中文字体**：目前用的是系统字体回退，桌面端能正常显示。导出到网页或手机前，建议下载一款开源像素中文字体（如 [Fusion Pixel](https://github.com/TakWolf/fusion-pixel-font)、[Ark Pixel](https://github.com/TakWolf/ark-pixel-font)），在 `ui/theme.tres` 里设为默认字体。

## 下一步可以做

- [ ] 房间里的障碍物和箱子，加 `NavigationAgent2D` 让敌人绕路
- [ ] 可以打开的宝箱（先显示箱子，按 E 打开再掉奖励）
- [ ] 局外成长：用金币解锁角色、初始武器
- [ ] 更多角色和技能（召唤随从、时停、护盾……）
