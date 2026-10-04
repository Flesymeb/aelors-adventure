# Ranger 弓箭交互与动画调研

日期：2026-09-26。范围：当前 Godot 4.7 村庄示例。本文的本地证据描述改动前的状态。后续已接入右键瞄准、渐进镜头缩放、准星/蓄力圆弧、KayKit 动作重定向、右手 IK、动态弓弦、搭箭及松弦射击；现状与轻量回归命令见 [README](README.md)。音效、专用方向步态和完整战斗反馈仍是后续工作。

## 结论

首选本地缓存中的 KayKit Character Animations 1.1 弓箭动作，重定向到当前 Quaternius Ranger，再实现瞄准、拉弓、保持、松弦、恢复与取消。保留当前角色和换肤材质。完整弓箭效果还需要动态弓弦、搭箭模型、手部接触校正与正确的出箭事件。

当前问题不是一个动作播放速度参数能解决的：输入、动画、武器形变、箭矢和镜头缺少统一状态。

## 1. 本地证据

`player_controller.gd::_attack()` 在弓模式调用 `Pistol_Shoot`，并在同次左键按下处理中立即调用 `_fire_arrow()`。没有右键瞄准、按住蓄力、松开射击或取消状态。

`_update_animation()` 使用全身单动画播放；移动仍按移动方向转身，没有瞄准横移。`_fire_arrow()` 从左手附近生成箭，未使用箭尾搭弦挂点。`arrow_projectile.gd` 固定速度 22 m/s、重力 3 m/s²，瞄准射线的几何方向没有补偿下坠。

本地 `UAL1_Standard.glb` 和 `UAL2_Standard.glb` 各有 43 个动画；解析 GLB 的动画列表，没有找到弓箭动作。该结论仅针对这两个本地文件，不代表作者的全部动画产品。

现有 `Bow_Golden.obj` 是静态网格，没有弓弦骨骼或形变动画。材料组为 Gold、LightWood、White；White 是现有直弓弦。实现动态弦时应移除或隐藏原直弦，避免两条弦同时显示。

### 已在缓存中的真正弓箭动画

资产收据：

`assets/model-pool/local_import/63d439252663bf7df59554839684d912c231fa22eda976b3031b4f8909f7092a/fc284e65d414f47aa95b401dc8cff29542f30ed23c072a96a6e5556acdbe275d/receipt.json`

目录下：`extracted/Animations/gltf/Rig_Medium/Rig_Medium_CombatRanged.glb`。

| 动画 | 源文件时长 | 建议用途 |
| --- | ---: | --- |
| Ranged_Bow_Idle | 1.567 s | 装备弓后的待机 |
| Ranged_Bow_Draw | 1.333 s | 拉弓过程，按设计调整播放时长 |
| Ranged_Bow_Aiming_Idle | 1.833 s | 满弓保持，需检查与 Draw 末姿态是否连续 |
| Ranged_Bow_Release | 1.333 s | 松弦与恢复，实际出箭点需要逐帧确定 |
| Ranged_Bow_Draw_Up | 1.333 s | 向上拉弓，先查看是否适合做俯仰混合 |
| Ranged_Bow_Release_Up | 1.367 s | 向上射击，同上 |

来源与许可：[KayKit 作者页面](https://kaylousberg.itch.io/kaykit-character-animations)标注动画免费、CC0，可重定向到其他人形角色。作者同时说明其他体型的效果需要自行评估。当前缓存可先使用，无需重复下载。

源骨架有 23 个关节，Ranger 有 65 个关节；例如 `upperarm.l/lowerarm.l/hand.l` 对应 `upperarm_l/lowerarm_l/hand_l`，但源还有 `wrist.l`，目标另有锁骨、更多脊椎与手指骨骼。因此直接重命名轨道或复制 AnimationPlayer 不足以保证正确。

## 2. 参考工程核查

| 参考 | 核查结果 | 可借鉴范围 |
| --- | --- | --- |
| [DangerDrome/RenegadeController](https://github.com/DangerDrome/RenegadeController) | MIT，Godot 4.6+；实际源码有按住 aim、减速、禁止瞄准冲刺和面向目标 | 输入意图与角色移动分离；瞄准横移；镜头预设。它不是现成的完整弓箭动画库 |
| [Jeh3no/Godot-Third-Person-Controller](https://github.com/Jeh3no/Godot-Third-Person-Controller) | MIT；实际 camera_holder_script.gd 有左右肩偏移与镜头缩放 | 肩后镜头参数。现有实现按键切换瞄准，且直接设置偏移；本项目应改为按住右键、平滑过渡并检查侧向碰撞 |
| [MrEliptik/godot_experiments](https://github.com/MrEliptik/godot_experiments) 的 `3.x/VR/bow_and_arrow` | MIT 工程中的 Godot 3 VR 实验；阅读了拉弦距离、弦骨骼和箭跟随逻辑 | 弦和箭随拉弦点移动。VR 输入和旧 API 不直接移植；其按拉距计算射速仍是 TODO，不能当完整蓄力弹道参考 |
| [Lakshman-YT/RPG-template](https://github.com/Lakshman-YT/RPG-template) | 树目录核查：GitHub 只有 README、许可与图片，无控制器源码。作者页面售卖完整工程并禁止再分发 | 可查看功能展示；不作为免费开源实现依赖 |
| [Mixamo](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html) | Adobe 说明角色和动画可用于游戏，免费使用需 Adobe ID；此轮没有登录确认具体拉弓动作 | 第二选择；本地已有 CC0 动作时不增加账号与下载依赖。免费使用不等于开源素材 |

Renegade 的方向代码按模型 -Z 朝前增加 PI；当前 Ranger 前向是 +Z。照搬会重复此前朝向错误。它的目标来自 cursor，本例应使用屏幕准星射线目标。

## 3. Godot 实现路线

### 3.1 重定向优先于大规模替换

依据 [Godot 4.7 重定向文档](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html)，使用 BoneMap/SkeletonProfileHumanoid，同时处理 Bone Rest、骨轴、体型比例与非必要位置轨道。不能只改骨名。

先在独立测试场景重定向 Bow_Draw、Bow_Aiming_Idle、Bow_Release：侧面和正面查看肩、肘、手腕、脚和角色高度。源没有对应的手指动画时，要补 Ranger 握弓和拉弦指姿。不要在重定向尚未正确时调整镜头掩盖问题。

通过资源盘点和本机 ClassDB 检查，Godot 4.7 有 TwoBoneIK3D、SkeletonModifier3D、RetargetModifier3D。按 [TwoBoneIK3D 文档](https://docs.godotengine.org/en/4.7/classes/class_twoboneik3d.html)和 [SkeletonModifier3D 设计](https://godotengine.org/article/design-of-the-skeleton-modifier-3d/)，可在动画求值后校正手部接触。需要设置肘部 pole 目标、旋转及影响权重，避免手臂翻折。

现有 UAL 与 Ranger 的原始骨架应先保留；选择离线导出到 Ranger 骨架，或经过验证的实时重定向。若统一更改目标骨轴，必须同时重导现有走跑跳、挥剑动画并复核挂点，不能只改弓动作。

### 3.2 输入与状态

建议默认操作：

- 按住右键：抬弓瞄准，肩后镜头，准星显示，角色水平面向目标。
- 瞄准时按住左键：搭箭并拉弓；满弓后保持。
- 松开左键：达到最小拉距后松弦出箭；过早松开取消，具体阈值属于待调手感参数。
- 松开右键、切换武器、Esc/失焦、重生：取消未射出的箭，清除拉弓和输入锁存。
- 首版跳跃中禁止拉弓；跳跃打断蓄力并取消。以后若要空中射箭，再单独增加状态和验收。

状态：`BowIdle → AimReady → Draw → Hold → Release → Recover → AimReady`，Draw/Hold 均可到 Cancel。瞄准可以独立于是否满弓，不应把右键直接等同于拉弓。

拉弓量作为同一参数驱动动画进度、弦中心位置、弓臂弯曲、准星和射速。一个 shot_id 对应最多一次真实箭生成。出箭由松弦事件触发，不能继续在左键按下时立即生成。

### 3.3 上下身混合与瞄准

按 [AnimationTree 文档](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html)，保留下身行走，上身混合弓箭动作；Release 可用 [AnimationNodeOneShot](https://docs.godotengine.org/en/4.7/classes/class_animationnodeoneshot.html)播放和取消。检查缺失轨道的初始姿态及过滤范围，避免走路时上身被重置。

不要仅把现有 Walk 裁出下身就宣称横移完整；侧移、后退需要匹配的方向步态或可验证的混合。首版瞄准减速、禁止冲刺。肩后偏移、FOV、灵敏度和过渡时间先作为可配置参数，使用当前 SpringArm 避障并检查侧偏镜头的碰撞。

俯仰由瞄准方向驱动上身姿态与手部目标；不能只有箭朝上、角色仍平举。先限制合理俯仰范围，再验证抬头和低头瞄准。

### 3.4 弓弦、双手、搭箭

弓需要独立的上下弦端点、string_draw_target、arrow_nock、arrow_rest。左手握把，右手拉弦，箭尾与弦中心同步移动。隐藏原 White 直弦，再用两段细几何或带骨骼的弦连接端点与拉弦点；弓臂可增加轻微程序形变，首版无需复杂物理软体。

目标层级必须避免循环约束：由角色/瞄准参考架定义独立握弓目标，左臂 IK 跟随；弓随左手，右手再跟随弓的拉弦点。不要把左手 IK 目标直接设成左手挂着的弓握点。

搭在弓上的展示箭与飞行箭在释放帧交接。以真实搭箭姿态的世界位置和方向生成/转为飞行状态，避免箭从手旁跳出。重新校准现在为待机设计的握点旋转；验证 BowIdle/Draw/Hold/Release，而非只看静止一帧。

### 3.5 弹道和近距离遮挡

第一条射线从镜头准星选择目标；第二步从真实箭位检查近距离遮挡，避免镜头越过墙而弓在墙后仍可射中目标。飞行继续使用当前逐物理帧的线段碰撞检查。

由于现有箭有重力，几何直线瞄准不保证落点在准星处。可选择低弧弹道求解，或显示预测落点；无法到达的目标应显示受限状态。蓄力改变速度时要同时更新解算，不能只改速度而沿用旧发射方向。

## 4. 优先级与验收

| 优先级 | 工作 | 验收证据 |
| --- | --- | --- |
| P0 | 重定向三段核心动作、校准双手 | 正面/侧面/背面拉弓连续片段，关节无明显翻折 |
| P0 | 右键瞄准、左键拉/放、取消状态 | 长按、短按、提前取消、切换武器、Esc/失焦均无幽灵箭 |
| P0 | 动态弦、搭箭、松弦事件 | 拉距与弦一致；射击前有搭箭；松弦帧只生成一支箭 |
| P1 | 肩后镜头、上下身混合、俯仰 | 横移不转离目标，抬头低头时双手和弓跟随；近墙不穿镜头 |
| P1 | 蓄力弹道与近墙射击 | 近/中/远目标与可达准星一致；墙挡住箭时不能穿过 |
| P2 | 拉弦/松弦声音、轻微弓臂回弹、命中反馈 | 声音与动作事件同步，不靠过强镜头抖动遮盖问题 |

验收关键帧应绑定实际状态/动画归一化进度：抬弓、拉到一半、满弓、离弦前后、恢复、取消。截图检查接触和方向；连续短片检查流畅性。不能只用“箭数增加、动画名称存在、无报错”作为射箭质量通过依据。

自动回归用物理时间或状态事件推进，不假设 48 个渲染帧等于 0.8 秒；此前无头测试已经证明渲染帧数与武器切换计时并不等价。优先在轻量角色测试场景验证，再在完整村庄检查镜头、遮挡和脚步。

## 5. 对 HoH 的直接启示

此次需要的弓箭动作早已在本地池中，但实现用了手枪动作。这暴露出“缓存已有”与“开发者实际发现并选用”之间缺口。任务开始应按动作语义检索缓存（bow/draw/aim/release），读取 GLB 的真实片段列表、骨架及许可，再决定外部检索。

素材与 demo 是两类候选：前者检查动作内容和重定向兼容性；后者检查真正的源码、版本及实现机制。GitHub 介绍页、付费工程展示和可再分发开源代码不能被同一个“找到参考”结果混为一谈。
