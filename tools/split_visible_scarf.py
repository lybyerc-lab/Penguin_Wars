"""Split complete Blender beauty and visible scarf matte into Godot base/scarf layers.

Requires Pillow and NumPy. Run: python split_visible_scarf.py <raw_root> <runtime_root>.
The alpha compensation preserves Blender beauty under standard source-over composition.
"""
from pathlib import Path
import sys
import numpy as np
from PIL import Image

raw_root, runtime_root = map(Path, sys.argv[1:3])
counts = {'idle': 40, 'move': 16, 'dash': 10, 'hit': 7, 'downed': 14, 'revive': 14}
for state, count in counts.items():
    beauty_files = sorted((raw_root / state).glob('beauty_*.png'))
    mask_files = sorted((raw_root / state).glob('mask_*.png'))
    assert len(beauty_files) == len(mask_files) == count, (state, len(beauty_files), len(mask_files), count)
    state_max_diff = 0
    for i in range(1, count + 1):
        bp = raw_root / state / f'beauty_{i:04d}.png'
        mp = raw_root / state / f'mask_{i:04d}.png'
        assert bp.exists() and mp.exists(), (bp, mp)
        beauty_img = Image.open(bp).convert('RGBA')
        mask_img = Image.open(mp).convert('L')
        assert beauty_img.size == mask_img.size == (256, 256)
        beauty = np.asarray(beauty_img, dtype=np.float64) / 255.0
        matte = np.asarray(mask_img, dtype=np.float64) / 255.0
        alpha = beauty[:, :, 3]
        assert np.count_nonzero(matte) > 0, (state, i, 'empty scarf mask')
        assert np.max(matte[alpha == 0]) <= 2 / 255, (state, i, 'matte outside beauty')
        scarf_alpha = alpha * matte
        base_alpha = np.divide(alpha - scarf_alpha, 1 - scarf_alpha,
                               out=np.zeros_like(alpha), where=(1 - scarf_alpha) > 1e-9)
        assert np.all(base_alpha >= -1e-9) and np.all(base_alpha <= 1 + 1e-9)
        for layer, layer_alpha in (('base', base_alpha), ('scarf', scarf_alpha)):
            rgba = np.concatenate((beauty[:, :, :3], layer_alpha[:, :, None]), axis=2)
            rgba8 = np.rint(np.clip(rgba, 0, 1) * 255).astype(np.uint8)
            rgba8[rgba8[:, :, 3] == 0, :3] = 0
            dest = runtime_root / layer / state / f'penguin_{state}_{i-1:03d}.png'
            dest.parent.mkdir(parents=True, exist_ok=True)
            Image.fromarray(rgba8, 'RGBA').save(dest)
        base = Image.open(runtime_root / 'base' / state / f'penguin_{state}_{i-1:03d}.png')
        scarf = Image.open(runtime_root / 'scarf' / state / f'penguin_{state}_{i-1:03d}.png')
        if state == 'idle':
            scarf_a = np.asarray(scarf.convert('RGBA'))[:, :, 3]
            for label, (y0, y1, x0, x1) in {'face': (95, 135, 110, 170), 'belly': (185, 201, 115, 155), 'feet': (210, 235, 70, 190)}.items():
                assert not np.any(scarf_a[y0:y1, x0:x1]), (state, i, 'body pixel contamination', label)
        reconstructed = Image.alpha_composite(base, scarf)
        background = Image.new('RGBA', (256, 256), (70, 90, 110, 255))
        original_flat = np.asarray(Image.alpha_composite(background, beauty_img), dtype=np.int16)
        result_flat = np.asarray(Image.alpha_composite(background, reconstructed), dtype=np.int16)
        max_diff = int(np.abs(original_flat - result_flat).max())
        state_max_diff = max(state_max_diff, max_diff)
        assert max_diff <= 2, (state, i, 'recomposition mismatch', max_diff)
        if i == 1 and state == 'idle':
            proof = raw_root / 'proof'
            proof.mkdir(parents=True, exist_ok=True)
            for name, img in [('beauty', beauty_img), ('mask', mask_img), ('base', base),
                              ('scarf', scarf), ('recomposed', reconstructed)]:
                img.save(proof / f'{name}.png')
            diff = np.abs(original_flat - result_flat)
            difference = np.clip(diff * 40, 0, 255).astype(np.uint8)
            difference[:, :, 3] = 255
            Image.fromarray(difference, 'RGBA').save(proof / 'difference_x40.png')
            print('IDLE_PROOF_MAX_DIFF', max_diff, 'MASK_PIXELS', int(np.count_nonzero(matte)))
    print('PW_SPLIT_OK', state, count, 'MAX_DIFF', state_max_diff)
