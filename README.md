# 像素地牢

一个类似《元气骑士》的 2D 俯视角 Roguelike 地牢射击游戏骨架，用 **Godot 4.7** 开发。

素材目前全是程序生成的占位像素图，玩法流程已经完整：

> 主菜单 → 随机地牢（带小地图）→ 进房间锁门、分波刷怪 → 清完开门 → 宝箱房捡武器 → 打 Boss → 传送门 → 强化三选一 → 下一层 → 第 3 层 Boss 后通关 / 死亡结算 → 记录最高纪录

## 运行

1. 用 Godot 4.7 打开本目录下的 `project.godot`
2. 按 F5 运行（主场景是 `ui/main_menu.tscn`）

## 操作

| 操作 | 键盘鼠标 | 手柄 |
|---|---|---|
| 移动 | WASD / 方向键 | 左摇杆 |
| 射击 | 鼠标左键 / J | RT / X |
| 切换武器 | Q | Y |
| 拾取武器 | E | A |
| 暂停 | Esc / P | Start |

瞄准默认是**自动瞄准**：瞄准视线内最近的敌人，附近没有敌人时朝鼠标方向瞄准。可以在 `player/player.tscn` 的检查器里关掉 `auto_aim`，改成纯鼠标瞄准。

## 项目结构

```
autoload/
  events.gd            全局信号总线（玩家死亡、房间清空、Boss 血量、屏幕震动）
  game_state.gd        一局的状态：血量/护盾/能量、武器、楼层、Buff 列表、存档
player/                玩家：移动、自动瞄准、射击、受伤、护盾回复、拾取武器
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
  room.gd              房间：进门锁门、分波刷怪、清空开门；宝箱房放奖励
  door.gd / portal.gd  门、传送门
pickups/               金币、能量、药水、地上的武器
common/                命中粒子、挥砍刀光、受击闪白 shader、震屏相机
ui/                    主菜单、HUD、小地图、Buff 三选一、暂停菜单、结算
assets/sprites/        占位像素图（可直接替换）
```

**碰撞层**（在 项目设置 → Layer Names → 2D Physics 里有命名）：
1 墙和门 · 2 玩家 · 3 敌人 · 4 玩家子弹 · 5 敌人子弹 · 6 掉落物

## 怎么扩展

**加一把新武器**：在 `weapons/data/` 里右键新建一个 `WeaponData` 资源，填写伤害、射速、能耗、子弹数、散射等参数，然后把它加进 `autoload/game_state.gd` 的 `weapon_pool`。宝箱房会随机掉落它，不需要写代码。

**加一把近战武器**：同样新建一个 `WeaponData` 资源，勾选“近战”分组里的 `is_melee`，再设置挥砍半径、扇形角度、击退倍率，以及能不能打掉敌人的子弹（骑士剑可以，大铁锤不行但伤害高、击退远）。近战武器只用到射击参数里的伤害、射击间隔和能耗。

**加一种新敌人**：新建一个脚本 `extends Enemy`，重写 `_think(delta)`，返回每帧想移动的方向，需要开枪时调用 `shoot_bullet()`，可以参考 `gunner.gd`。再复制一份 `slime.tscn` 换上新贴图和脚本，最后在 `room.gd` 的 `_random_wave()` 里把它加进刷怪列表。

**加一个新 Buff**：在 `game_state.gd` 的 `BUFFS` 里加一条，再在 `apply_buff()` 里写上效果。

**小地图**：`ui/minimap.gd` 用地牢生成器输出的网格数据来画，只显示去过的房间和与之相邻的房间，Boss 房是红点，宝箱房是黄点，青色小点是玩家。方块大小和间距可以改 `ROOM_SIZE` / `SPACING`。

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

- [ ] 按 Tab 显示全屏大地图
- [ ] 角色技能（元气骑士的双持、冲刺等），用一个冷却键触发
- [ ] 房间里的障碍物和箱子，加 `NavigationAgent2D` 让敌人绕路
- [ ] 音效（`AudioStreamPlayer2D`），可以用 jsfxr 快速做 8-bit 音效
- [ ] 商店房：用金币买武器或药水
- [ ] 局外成长：解锁新角色、初始武器
