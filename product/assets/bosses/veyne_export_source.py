"""Reproducible CC0 native Demon binding conversion; not a runtime script.

Run with Blender's --background --python from the project root. The source
FBX, atlas and original notice remain unchanged in veyne_monster_source.
"""
from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(ROOT / "veyne_monster_source/Demon.fbx"))

armature = next(o for o in bpy.data.objects if o.type == "ARMATURE")
for action in bpy.data.actions:
    action.name = action.name.rsplit("|", 1)[-1]

# FBX stores all native actions on the same skeleton. Export them without a
# foreign skeleton, root-motion controller, camera, lights or physics owner.
armature.animation_data.action = bpy.data.actions["Idle"]
bpy.context.scene.frame_set(1)
# The active action is otherwise treated as the rest pose by the ACTIONS
# exporter and omitted. Clear that binding after evaluating the base frame so
# Idle is carried as a real sampled clip alongside every transient action.
armature.animation_data.action = None
for image in bpy.data.images:
    if image.filepath:
        image.filepath = str(ROOT / "veyne_monster_source/Atlas_Monsters.png")
        image.reload()
        image.pack()

bpy.context.view_layer.objects.active = armature
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(
    filepath=str(ROOT / "veyne_animations.glb"),
    export_format="GLB",
    export_animations=True,
    export_animation_mode="ACTIONS",
    export_force_sampling=True,
    export_frame_range=False,
    export_nla_strips=True,
    export_yup=True,
    export_cameras=False,
    export_lights=False,
    export_extras=True,
)
print("VEYNE_EXPORT_NATIVE_CLIPS", [a.name for a in bpy.data.actions])
