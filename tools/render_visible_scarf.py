"""Render full neutral penguin beauty and visible scarf Cryptomatte from a locked Blender source.

Run with: blender -b <source.blend> --python render_visible_scarf.py -- <state> <output_root>
No source .blend is saved. Both outputs come from the same render per frame.
"""
import bpy
import sys
from pathlib import Path

args = sys.argv[sys.argv.index('--') + 1:]
state, output_root = args
expected = {'idle': 40, 'move': 16, 'dash': 10, 'hit': 7, 'downed': 14, 'revive': 14}
camera = {
    'idle': (1.35, 0.0, 9.0 / 256.0),
    'move': (0.8, 0.0, 5.0 / 256.0),
    'dash': (0.8, 0.0, 5.0 / 256.0),
    'hit': (0.8, 0.0, 5.0 / 256.0),
    'downed': (1.65, -10.0 / 256.0, 37.0 / 256.0),
    'revive': (1.65, -10.0 / 256.0, 37.0 / 256.0),
}
assert state in expected
scene = bpy.context.scene
assert scene.render.fps == 24, (bpy.data.filepath, scene.render.fps)
assert scene.frame_start == 1
assert scene.frame_end == expected[state], (state, scene.frame_end, expected[state])
assert scene.camera is not None
scene.render.resolution_x = 256
scene.render.resolution_y = 256
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.image_settings.color_depth = '8'
zoom, shift_x, shift_y = camera[state]
scene.camera.data.lens *= zoom
scene.camera.data.shift_x = shift_x
scene.camera.data.shift_y = shift_y

scarf_names = {'PW_Scarf', 'PW_ScarfKnot', 'PW_ScarfTail'}
scarf_objects = [bpy.data.objects[name] for name in sorted(scarf_names)]
assert all(o.type == 'MESH' for o in scarf_objects)
for obj in scarf_objects:
    assert obj.data.materials
    neutral = obj.data.materials[0].copy()
    obj.data.materials[0] = neutral
    neutral.diffuse_color = (1, 1, 1, 1)
    if neutral.use_nodes:
        for node in neutral.node_tree.nodes:
            if node.type == 'BSDF_PRINCIPLED':
                node.inputs['Base Color'].default_value = (1, 1, 1, 1)

scene.view_layers[0].use_pass_cryptomatte_object = True
scene.use_nodes = True
nodes = scene.node_tree.nodes
nodes.clear()
links = scene.node_tree.links
render_layers = nodes.new('CompositorNodeRLayers')
crypto = nodes.new('CompositorNodeCryptomatteV2')
crypto.source = 'RENDER'
crypto.scene = scene
crypto.layer_name = f'{scene.view_layers[0].name}.CryptoObject'
crypto.matte_id = ','.join(sorted(scarf_names))
links.new(render_layers.outputs['Image'], crypto.inputs['Image'])
output = Path(output_root) / state
output.mkdir(parents=True, exist_ok=True)
beauty = nodes.new('CompositorNodeOutputFile')
beauty.base_path = str(output)
beauty.file_slots[0].path = 'beauty_'
beauty.format.file_format = 'PNG'
beauty.format.color_mode = 'RGBA'
beauty.format.color_depth = '8'
links.new(render_layers.outputs['Image'], beauty.inputs[0])
mask = nodes.new('CompositorNodeOutputFile')
mask.base_path = str(output)
mask.file_slots[0].path = 'mask_'
mask.format.file_format = 'PNG'
mask.format.color_mode = 'BW'
mask.format.color_depth = '8'
links.new(crypto.outputs['Matte'], mask.inputs[0])
scene.render.filepath = str(output / 'unused.png')

for frame in range(1, expected[state] + 1):
    scene.frame_set(frame)
    # Set IDs after frame evaluation, so animated object properties cannot override them.
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            obj.pass_index = 42 if obj.name in scarf_names else 0
    bpy.ops.render.render(write_still=False)
    assert (output / f'beauty_{frame:04d}.png').exists()
    assert (output / f'mask_{frame:04d}.png').exists()
    print('PW_VISIBLE_SCARF_FRAME', state, frame, flush=True)
print('PW_VISIBLE_SCARF_OK', state, expected[state], flush=True)
