# 渲染与状态驱动动作（2026-09-26）

## 渲染器选择与本机边界

已查阅 Godot 官方的[渲染器比较](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)、[环境与后处理](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html)、[材质](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)和 [PhysicsBody3D 检测接口](https://docs.godotengine.org/en/stable/classes/class_physicsbody3d.html)。本地运行版本为 Godot 4.7；当前实机窗口日志为 OpenGL Compatibility / Mesa llvmpipe（CPU 软件渲染），不能把固定时间步录像的播放 FPS 当作本机实时性能。

| 渲染器 | 使用条件与当前取舍 |
| --- | --- |
| Compatibility | 默认保留；OpenGL，核心 3D、雾、灯光、法线、色调映射、MSAA。当前官方文档也列出 SSAO 和 Glow；本例在增强档开启。 |
| Mobile | RenderingDevice 后端，依赖 Vulkan、Metal 或 D3D12；可能适合具有现代集成显卡的机器。需要用同一场景实测再替换默认配置。 |
| Forward+ | 提供体积雾、SSR、SSIL、SDFGI 等高级效果。需要支持相应图形 API 的硬件；当前软件渲染环境不把它设为默认。 |

本次没有对三种渲染器做性能对比，因此不宣称切换后会更快。后续可在 Godot 编辑器右上角切换渲染器，使用同一机位、同一光照状态测量帧时间、内存和画面差异。切换渲染器后需要重新校准光照和着色器。

### 实际材质改动

原包主要使用 32×32 色板贴图。色板是颜色索引，并非可直接放大成木纹/砖纹的照片；扩大其像素尺寸不会产生新细节。部分地形材质未绑定地面贴图，原有 1024×1024 的泥土贴图未用于当前地形。

`environment_quality.gd` 对包装场景的材质进行运行时覆盖：

- 颜色图集保持最近邻与 mipmap 采样，避免相邻色块互相渗色。
- 普通贴图采用 mipmap 与各向异性过滤；工程设为 4× 各向异性。
- 地形使用原包泥土贴图，补充确定性微细节、世界空间微法线、积雪/裸地混合与坡度遮罩。覆盖原地形全部材质槽，保留原几何和碰撞。
- 日景与黄昏分别设置程序天空、环境光、阳光色温、雾与曝光，降低过曝地面的大片纯白。
- 添加三盏带实际灯杆碰撞的暖色灯；均衡档不使用局部灯阴影。
- `G` 切换均衡/增强；增强增加 2× MSAA、SSAO、Glow 和一盏局部灯的阴影。

微细节是风格化材质增强，并非高清原资产替换。建筑仍保留原有低多边形几何、色板与 UV。需要清晰木纹、砖缝或更丰富屋顶细节时，应继续寻找授权匹配的材质/模型，并重新验证 UV、视觉统一性和成本。

## 动作按状态使用

动作数量本身不能保证体验。当前共享控制器拥有姿态、移动、战斗互斥、离地、落地、恢复和冷却状态；输入只是请求，碰撞与状态决定是否能进入动作。

| 状态/条件 | 动作 | 触发方式 |
| --- | --- | --- |
| 停止移动、普通/持剑 | UAL `Idle` / `Sword_Idle` | 自动持续循环，包含资源中的待机细微动作；修复持剑待机播完停住；静止时叠加 4.2 秒周期、0.5% 幅度的胸部呼吸，在瞄准/攻击/切换时淡出。 |
| 普通移动 | UAL `Walk` | WASD 产生实际运动后自动选择。 |
| 站立、非瞄准、Shift + 移动 | UAL `Sprint` | 按移动状态切换；速度 9.5 m/s。 |
| 蹲下、蹲走 | UAL `Crouch_Idle` / `Crouch_Fwd` | C 切换姿态；停/走自动切换，速度 2.2 m/s。 |
| 趴下、爬行 | KayKit `Crawling` | Z 请求姿态；静止保持趴姿，移动循环爬行，速度 1.15 m/s；收起手持武器。 |
| 起跳 → 空中 → 落地 | UAL `Jump_Start` → `Jump` → `Jump_Land` | Space 仅请求跳跃，后续由实际离地/落地及垂直速度自动触发。 |
| 翻滚 | UAL `Roll` | F 请求，0.72 秒恢复；横向 Root Motion 由物理控制，保留竖向骨骼动作。 |
| 四向闪避 | KayKit `Dodge_Forward/Backward/Left/Right` | Alt + 当前移动方向；无方向时后撤。0.4 秒动作，朝向由进入状态时锁定。 |
| 换武器 | UAL `Interact` | 武器请求触发，中途同步交换手持/背负。 |
| 拉弓、满弓、射击 | KayKit Bow Draw / Aiming Idle / Release | 由瞄准、蓄力、释放与恢复状态选择；手弦 IK 保留。 |
| 挥剑 | UAL `Sword_Attack` | 当前站立且未处于闪避/翻滚/切换时，左键请求。 |

现有 UAL1 中还缓存了受击、死亡、交谈、拾取、游泳、坐下、修理、法术等；UAL2 中有攀爬、种植、砍树、盾牌和剑招。这些应由伤害、NPC 对话、物品交互、水体、座位、任务或对应技能状态触发。当前示例没有这些系统，不能仅播放动画便宣称已实现相应机制。资源仍保留在池/本机目录中，后续按真实系统接入。

爬行和闪避复用已缓存的 KayKit CC0 `Rig_Medium_MovementAdvanced.glb`，用 Rest 旋转差重定向到 Ranger；按目标骨架长度补偿竖向髋部位置，并校准爬行支撑高度。它不是专门为 Ranger 制作的趴下过渡动画；手脚贴地仍可进一步加入逐脚/逐手地形 IK。

## 碰撞与小台阶

- 站立胶囊高 1.8 米；蹲下高 1.15 米；趴下改为长 1.75 米、直径 0.72 米的水平胶囊，随角色朝向旋转。
- 起身/变姿态前检查目标形状，头顶或周边没有空间时维持原姿态并显示提示。趴着转向时也检查长胶囊，防止横穿墙体。
- 最大步高 0.32 米，坡度上限 46°。抬升和前向通路先用实际胶囊进行碰撞预测，再检查前方踏面和高度；不会水平传送角色。
- 台阶边缘短暂提供 0.14 秒支撑缓冲，并平滑相机高度，避免胶囊接触角导致下吸和动作闪成跳跃；没有踏面时不会授予缓冲。
- 翻滚/闪避的速度经过 `move_and_slide()`，会受墙体阻挡。翻滚使用较低胶囊，恢复时空间不足则保持蹲姿。
- 当前没有敌人或伤害系统，因此闪避/翻滚只实现位移与动作，不宣称具有无敌帧。

## 验证

```bash
godot --headless --path examples/emaceart-village-demo --script res://traversal_smoke.gd
xvfb-run -a godot --path examples/emaceart-village-demo --script res://archery_smoke.gd
```

移动测试覆盖台阶、高障碍、低顶、姿态胶囊、爬行姿态、薄墙阻挡、闪避方向、冲刺、自动起落动画、待机循环与重生恢复。弓箭回归检查新状态加入后原有瞄准、蓄力、镜头切换、出箭与取消保持正常。

本机渲染截图：[日景](previews/terrain_day_balanced.png)、[黄昏暖光](previews/terrain_dusk_balanced.png)、[蹲下](previews/movement_crouch.png)、[趴下](previews/movement_prone.png)、[增强档](previews/terrain_dusk_enhanced.png)。这些为本地验证产物，不随资产源码分发。
