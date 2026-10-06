# 艾洛的冒险 · Snaiel 训练战斗底座

当前增量把 Snaiel [Godot4ThirdPersonCombatPrototype](https://github.com/Snaiel/Godot4ThirdPersonCombatPrototype) `cbfecf427f9a703ebf7e940fd067ed31a729d637` 的 health、damage resources/source、melee、hitbox、hit interaction 与其 Beehave blackboard/selector/sequence/leaf 机制适配到 `combat/snaiel/`。完整 MIT 通知及模块改造边界见 `combat/snaiel/LICENSES.txt`；不导入 Blender 场景、demo Globals、额外控制器或未逐项确认的模板音频。

普通路线保持：徒手开局 → 伊莎接受请求 → 赫斯授剑 → 实际击中草靶 → 格挡或闪避模拟攻击 → 河边训练怪。抬手锁定攻击方向，真实碰撞且无遮挡才结算。剑的三段连击与怪物出拳由 AnimationPlayer 方法事件开闭 Snaiel damage window；hitbox 对同一 damage source 的同一 instance 只结算一次。敌人 HP 仅由 HealthComponent 修改；玩家 HP/命数、教学事实及奖励保存仍归现有 DialogueState/训练策略，PlayerController 保留物理、镜头和全部挂点。旧怪物 HP/攻击时钟与剑训练 struck/contact 结算已移除。

训练怪胜利只产生一次金色残响，靠近自动拾取 +10 XP；未领取、已领取和死亡恢复都保存，不在加载时回放反馈。取得弓后，可回赫斯按 E 开始无额外奖励的复练，让合法取得的弓箭能对同一个训练怪练习；初战完成事实不重置，复练本身不随保存重生。1/2 仍为剑/弓；右键格挡、接触前短窗振刀，Alt 闪避。暂停停止战斗与反馈时钟；静音战斗反馈和减少反馈动态保持可读的数字与危险提示。

开发 smoke 覆盖了组件/clip 绑定、实际剑/箭命中与遮挡、单次接触去重、减伤/振刀、致死钳制、自动拾取及死亡/未拾取奖励重启恢复。场景设置探测与普通输入分开记录，不替代独立 Tester 的完整 foundation review。Forest 性能缺口和既有编辑器草纹理警告仍存在；模板采用不关闭环境、PRD R01–R24 或全产品验收。

---

# 艾洛的冒险 · Forest 环境增量

运行当前工程的 `Preview.tscn`（Godot 4.7，桌面 Forward+）。普通第三人称游戏实例化 `world.tscn` 的 Terrain3D、原有植被分布、河水、天空、环境音与两座木桥，同时保留 Ranger 完整头部、动作、剑弓挂点和 Isha/Hers/Ronen、训练、奖励及存档系统。旧 Demo 世界、地面、自然物与雪效应不进入普通游戏；三个保留的村庄房屋使用原 prefab 的材质与建筑碰撞。

`WASD` 移动、`Shift` 冲刺、`Space` 跳跃、鼠标转镜头、`E` 交互、`1/2` 取剑/弓、左键挥剑，持弓时右键瞄准、左键按住蓄力并松开射箭。`F10` 设置/存档，`G` 切换默认/低画质。武器需要剧情取得。低画质缩短小植被与阴影视距，并使用 70% 内部 3D 分辨率；输出窗口保持 1280×720。

村口 CP01 / 伊莎 → 赫斯与草靶 → 草地训练怪 / 罗恩 → 河边第一木桥 → 对岸林间路 → 第二木桥 → 返回村口。锚点统一由 `forest_ground.gd` 管理，出生等待实际地形碰撞就绪，放置同时检查坡度与站立空间。Terrain3D 保留原区域数据，桥使用作者已有碰撞并适配产品的地面层；没有替代地板。

存档加入地图标识 `forest-885de576-v1`，保留剧情、武器、箭数、经验、奖励领取、命数和训练事实。旧村庄存档搬到新 CP01，未领取残响搬到训练场；当前地图的坐标重新验证地面，不可用坐标退回 CP01。读取不重写源槽位；手动加载只有落地与原子保存成功后才提交。无效数据或写失败保留恢复界面与原历史，不通过删除存档解决问题。

来源为 [GW Tuts / Lakshman 的 Forest-Godot4](https://github.com/Lakshman-YT/Forest-Godot4)，版本 `885de5769b2d0cf7ea0808752e44d680abecfd5b`。本轮沿用 Host 已暂存的完整来源，没有重新下载。来源记录与参考图保留在 `forest_source/`；实际依赖位于 `terrain_Data/`、`terrain mat/`、`env models/`、`addons/terrain_3d/` 和 `addons/sky_3d/`。移除来源的示例人物、演示相机、调试标签、统计脚本和 movie-writer 配置，保留当前产品输入与暂停所有权。

请保留 `forest_source/!Credits-README!.txt` 及插件许可：Terrain3D / Sky3D 为 MIT，各模型、纹理与星图的许可分别适用。上游没有整包统一 LICENSE；草、树、植物等独立分发/商用许可仍需逐项确认，不能将整包称为 MIT。原村庄包仍受下述本机素材授权限制。

开发探测已看到 Intel(R) Graphics (RPL-S) / Vulkan / Forward+ 正常渲染，以及实际出生、NPC 与训练模块的地面支持。普通输入检查已覆盖伊莎接受、赫斯授剑、暂停恢复、移动、草靶实际命中和重启后的装备/训练进度恢复。性能快照仍低于 30 FPS；完整桥路线、弓箭/战斗/奖励回归、遗留存档文件与写失败、60 秒默认/低画质采样及独立 Tester 验收尚不由这些探测证明。当前增量不关闭 PRD R01–R24、原五个里程碑或后续章节。最终当次观察与未验证项见 Developer 交付报告，Host 负责证据哈希与仓库角色提交。

---

以下为继承的示例来源说明及历史验证，仅供来源/绑定参考，不代表当前候选验收。

# 免费村庄第三人称探索示例

本机已导入 EmacEArt 村庄、Quaternius Ranger、动画和两种武器。运行 Godot 4.7：

最新材质、渲染器选择、碰撞和状态驱动动作见 [渲染与动作说明](RENDERING-AND-MOTION.md)。`C` 蹲下、`Z` 趴下/爬行、`F` 翻滚、`Alt` 四向闪避、`Shift` 冲刺，`G` 切换均衡/增强画质；小台阶自动跨越，低顶下不能强行起身。起跳、空中、落地与待机自动选择动作。

拉弓、右键瞄准与动画重定向的资源盘点见 [弓箭系统调研](ARCHERY-RESEARCH.md)。当前示例已接入右键瞄准、平滑镜头缩放、准星及蓄力圆弧、拉弓与松弦动作、动态弓弦和手部 IK。

```bash
godot --path examples/emaceart-village-demo
```

操作：`WASD` 按镜头方向移动，鼠标转动第三人称镜头，`Shift` 跑步，`Space` 跳跃；`1` 装备刀、`2` 装备弓、`Q` 轮换。持刀时左键挥刀；持弓时按住右键瞄准，再按住左键拉弓，松开左键射击。`E` 切换左右肩视角，`V` 切换第一/第三人称；`3` 轮换 Forest、Frost、Ember 三种服装配色，`4` 切换日景与黄昏，`R` 重生，`Esc` 释放鼠标，左键重新捕获鼠标。

瞄准镜头平滑从 FOV 70° 过渡到 48°，弹簧臂从 3.8 米缩至 2.65 米，并偏移至肩后。准星右侧以大半径（104 像素）、圆心偏左的 30° 圆弧从下往上显示蓄力：1 秒达到满弓并变为金色 READY，拉弓不足 12% 松开则取消。射速随蓄力从 18 增至 38 m/s。瞄准移动速度为 2.2 m/s，角色保持面向目标。左右肩切换平滑过渡，第一人称平滑移动到 1.65 米眼高，保留身体、手臂和武器，将兜帽和基础头部、眼睛、眉毛统一设为只投影以避免遮挡镜头；第一人称正常/瞄准 FOV 为 78°/55°，回到第三人称会记住肩侧。切换视角不会取消当前蓄力。UI 使用 Inter/Ubuntu/Noto Sans 系统字体回退和半透明底板，无粗文字描边。松开右键、换武器、跳跃/离地、Esc、窗口失焦或重生会取消未射出的箭；重新捕获鼠标不会射箭。

箭在松弦时从搭箭尾部位置生成，发射方向对当前重力做低弧补偿；近墙检查包含箭尖，避免模型先穿墙再检测到箭尾。目前没有敌人、伤害、箭矢库存、音效或专用瞄准横移步态，下身移动仍使用已有步行动画。切换武器时先播放取用动作，中途交换手持与背负可见性。趴下时将两件武器收至背上。

角色使用地形碰撞、重力、跳跃和弹簧臂镜头避障。模型面朝局部 `+Z`；移动朝向已经按这个轴计算。角色周围有有限范围内的持续飘雪，左右脚每走一步会在实际脚骨骼下方的地面产生短时扬雪粒子。

武器绑定使用 `hand_r` / `hand_l` 的 `BoneAttachment3D`。手骨骼原点在手腕，因此挂点沿手掌方向移动约 0.065 米；剑模型的柄中心在局部 `Y≈-0.05`，弓模型的握把中心在局部 `X≈0.03`。弓弦位于原模型局部 `+X`，持弓时将其转向角色后方，弓臂指向目标。未使用的武器挂在 `spine_02` 背部插槽，切换动作中途同步改变手持与背负模型的可见性。更换模型或缩放时应重新校准握点和背部插槽。

换肤只改变 Ranger 服装的绿色布料区域，原版 Forest 不覆盖模型材质；皮肤、皮革、金属纹理及法线细节保留。三种配色使用同一个角色网格和骨架，因此动作、持剑、持弓和背负挂点不需要重新绑定。换成另一套角色模型属于换装/换角色，仍需逐个检查骨架、比例与挂点。

弓箭动作使用缓存中的 KayKit `Ranged_Bow_Draw`、`Ranged_Bow_Aiming_Idle` 和 `Ranged_Bow_Release`。`bow_pose_modifier.gd` 根据源/目标骨架的模型空间 Rest 差异传递旋转，保留目标骨骼长度，再使用 Godot 4.7 `TwoBoneIK3D` 将右手掌贴到拉弦点。原 OBJ 的 White 直弦已从手持弓网格移除，替换为两段随拉弦点变化的细几何。瞄准时弓保持朝目标，剑仍背负在背上。

轻量交互回归（不加载整个村庄，Linux 无桌面时使用 Xvfb）：

```bash
xvfb-run -a godot --path examples/emaceart-village-demo --script res://archery_smoke.gd
```

检查真实鼠标按下/松开事件、渐进 FOV、半弓/满弓、松开一次只射一箭、过短蓄力、右键/武器/Esc/失焦/重生取消、满弓时手掌与弦的接触、弹道和近墙遮挡，以及左右肩/第一第三人称切换、兜帽可见性和第一人称释放射箭。无头 DisplayServer 不支持鼠标捕获，该测试应使用真实窗口或 Xvfb。动作接触位置在 IK 的 modification_processed 信号中采样，因为动画修改器在帧结束后会恢复基础姿态。

最新视角截图：[向上蓄力半弓](previews/bow_charge_upward.png)、[右侧蓄力弧](previews/bow_right_arc.png)、[左肩视角](previews/bow_left_shoulder.png)、[第一人称](previews/bow_first_person.png)。

上一版操作验证产物（包围式圆弧，供动作参考）：[弓箭操作视频](previews/archery_demo.mp4)、[半弓蓄力圆弧](previews/bow_charge_half.png)、[满弓准星](previews/bow_charge_full.png)。视频使用 Godot MovieMaker 固定时间步录制，播放帧率不代表本机实时运行性能。

本机渲染的[持刀与飘雪](previews/sword_snow.png)、[持弓与飘雪](previews/bow_snow.png)、[行走时的脚步扬雪](previews/foot_snow.png)截图由 Godot 4.7、OpenGL Compatibility、Mesa llvmpipe 直接生成。截图是本地验证产物，不随源码分发。

## 素材与复现

仓库只跟踪控制器和工程配置。原始村庄模型与贴图受作者单独许可约束，只放在本机 `assets/model-pool` 及本示例目录内，不随 HoH 源码分发。要在另一台机器运行，先取得下列作者免费包并完成 Godot 首次导入：

| 素材 | 作者来源 | 放入示例的目录 |
| --- | --- | --- |
| 村庄 | [EmacEArt 免费村庄包](https://store.godotengine.org/asset/emace-art/free-fantasy-medieval-houses-and-props-pack/) | 将 `SlavicWorldFree` 内文件复制到示例根目录，保留现有 `project.godot`、`Preview.tscn`、`Player.tscn` 和脚本 |
| Ranger | [Quaternius Modular Character Outfits Fantasy](https://quaternius.com/packs/modularcharacteroutfitsfantasy.html) | 免费包 `Exports/glTF (Godot-Unreal)/Outfits/` 中的 `Male_Ranger.gltf`、`.bin` 及其引用的六张 PNG，复制到 `Characters/QuaterniusRanger/` |
| 基础头部 | 同一 Quaternius Modular Character 包内的基础角色 | 将已有 `Superhero_Male_FullBody.gltf`、同名 `.bin` 与其引用贴图完整放入 `Characters/QuaterniusBase/`，保留原文件名；控制器仅提取头、眼睛和眉毛，不加入完整身体 |
| 动画 | [Quaternius Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html) | 免费包 `Unreal-Godot/UAL1_Standard.glb` 复制到 `Characters/QuaterniusAnimations/` |
| 弓箭与移动动作 | [KayKit Character Animations](https://kaylousberg.itch.io/kaykit-character-animations) | Free 1.1 中 `Animations/gltf/Rig_Medium/Rig_Medium_CombatRanged.glb`、`Rig_Medium_MovementAdvanced.glb` 和 `License.txt` 复制到 `Characters/KayKitAnimations/` |
| 铜剑 | [Quaternius Fantasy Props MegaKit](https://quaternius.itch.io/fantasy-props-megakit) | 免费包 `Exports/glTF/` 中的 `Sword_Bronze.gltf`、同名 `.bin` 和引用的三张 `T_Trim_Props_*.png`，复制到 `Weapons/` |
| 金弓与箭 | [Quaternius LowPoly Medieval Weapons](https://quaternius.itch.io/lowpoly-medieval-weapons) | 免费包 `OBJ/` 中的 `Bow_Golden.obj/.mtl` 与 `Arrow.obj/.mtl`，复制到 `Weapons/` |

上述 Quaternius 免费包的下载页面或包内许可标注 CC0 1.0；Ranger 的骨架与动画库匹配，控制器播放 `Idle`、`Walk`、`Jog_Fwd`、`Jump`、`Sword_Idle`、`Sword_Attack` 和武器切换时的 `Interact`。本机已把精选角色、动画、铜剑、弓箭分别导入私有素材池，保留来源和原始下载包哈希。村庄原包 SHA256：`fa1617aa00b73a35d08e0e1b2eafc102b2faf6e473a55d100fb66c2a85416374`；Ranger：`c3468b18871cc8c8f05ab14df7712baf22cb9f389cbd870babf130e595187f70`；动画：`cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724`；铜剑包：`8b6f7e806d222e585478f0e1bdc6b271bbc7bc6f84dd6af8ca703a7c64f0cb1e`；弓箭包：`546d6e168d71cc3ea0c5d388a7834658619ac2ace8be960050e5fb1dbd344a2a`。

此示例保留作者原始 `Demo/Slavica Free 2026 Version.scn` 的地形、房屋、碰撞和着色器。包装场景 `Preview.tscn` 修复了源场景相机极小正交视野，并加入可控角色；它是探索和武器操作验证场景，尚无敌人或剧情。源包仍有缺失的 `Objects/Grass_Texture.psd` 与一个墙体预制件继承节点告警；当前运行截图可正常渲染。

### Ranger 头部装配与验证

`Male_Ranger.gltf` 是服装模块：有兜帽，没有裸头、眼睛或眉毛。`ranger_head_assembly.gd` 从本地基础角色中提取三个面部组件的真实三角形，仅保留每个顶点至少 50% 权重属于 `Head` 的完整三角形，并保留原始材质、UV、法线和切线。源 Skin 的 Head 逆绑定矩阵将顶点转到头骨局部空间，再通过目标 Ranger 的 `BoneAttachment3D` 随动；没有复用全身不同的绑定矩阵，也没有添加躯干或四肢。兜帽与三个面部组件在第一人称一起变为仅投射阴影，回到第三人称一起恢复。

这是刚性头部装配，暂不支持基础角色的独立颈部权重变形、面部表情或口型动画；兜帽遮挡处需要实际近景检查。基础资源缺失时会报错，不能将空兜帽视为完整人物。原始 glTF、二进制与缓存没有改写。

由持有唯一 Godot 会话的执行者完成导入后运行：

```sh
godot --headless --path examples/emaceart-village-demo --script res://ranger_head_smoke.gd
# 有窗口时可额外保存正面、四分之三侧面、转头、第一人称和恢复第三人称近景：
godot --path examples/emaceart-village-demo --script res://ranger_head_smoke.gd -- --capture-head
```

脚本检查实际面部三角形与材质、头骨旋转后头/眼/眉的真实随动、仅头部区域以及第三→第一→第三的隐藏恢复。可选截图位于 `previews/head-smoke/`，仍需人工检查脸部遮挡、颈部接缝与第一人称是否穿头；准备脚本本身不代表已通过引擎或画面验证。

本机验证（2026-09-27）：Godot 4.7 Intel OpenGL Compatibility 下，头部几何/骨骼随动/视角切换检查通过（12,690 个三角形顶点、3 个面部组件）；正面、侧面、转头和恢复第三人称近景已实际检查。射箭回归 failures=0、射出 2 箭。验证仅限本示例；头部仍采用刚性骨骼挂接，不含口型或独立颈部变形。
