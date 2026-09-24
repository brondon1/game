extends Node
## 全局信号总线：房间、敌人、UI 之间通过这里通信，不用互相持有引用。

@warning_ignore("unused_signal")
signal player_died

@warning_ignore("unused_signal")
signal room_cleared(room: Room)

@warning_ignore("unused_signal")
signal boss_health_changed(hp: int, max_hp: int)

@warning_ignore("unused_signal")
signal screen_shake(strength: float)

## 在屏幕中央显示一条提示文字（HUD 负责显示）
@warning_ignore("unused_signal")
signal message(text: String)
