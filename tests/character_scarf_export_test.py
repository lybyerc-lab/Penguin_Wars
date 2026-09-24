"""Validate the production scarf split and its one-frame Blender proof.

Run with Python, Pillow and NumPy: python tests/character_scarf_export_test.py
"""
from pathlib import Path
import numpy as np
from PIL import Image

root = Path(__file__).resolve().parents[1]
production = root / 'assets/characters/penguin/production'
proof = root / 'docs/character-production-review/scarf-visible-v2/proof'
counts = {'idle': 40, 'move': 16, 'dash': 10, 'hit': 7, 'downed': 14, 'revive': 14}
for state, count in counts.items():
    for layer in ('base', 'scarf'):
        frames = sorted((production / layer / state).glob('*.png'))
        assert len(frames) == count, (layer, state, len(frames), count)
        assert [f.name for f in frames] == [f'penguin_{state}_{i:03d}.png' for i in range(count)]
        for frame in frames:
            assert Image.open(frame).size == (256, 256), frame
    for i in range(count):
        alpha = np.asarray(Image.open(production / 'scarf' / state / f'penguin_{state}_{i:03d}.png').convert('RGBA'))[:, :, 3]
        assert np.count_nonzero(alpha) > 0, (state, i, 'empty scarf')
        if state == 'idle':
            # Face, belly, and feet are visible in all Idle frames; none is scarf geometry.
            for label, (y0, y1, x0, x1) in {
                'face': (95, 135, 110, 170),
                'belly': (185, 201, 115, 155),
                'feet': (210, 235, 70, 190),
            }.items():
                assert not np.any(alpha[y0:y1, x0:x1]), (state, i, label, 'body contamination')
    print('SCARF_EXPORT_STATE_PASS', state, count)
beauty = Image.open(proof / 'beauty.png').convert('RGBA')
mask = np.asarray(Image.open(proof / 'mask.png').convert('L'), dtype=np.float64) / 255.0
base = Image.open(proof / 'base.png').convert('RGBA')
scarf = Image.open(proof / 'scarf.png').convert('RGBA')
assert np.count_nonzero(mask) > 0
scarf_alpha = np.asarray(scarf)[:, :, 3]
beauty_alpha = np.asarray(beauty)[:, :, 3]
assert np.max(np.abs(scarf_alpha.astype(np.int16) - np.rint(beauty_alpha * mask).astype(np.int16))) <= 1
for color in ((0, 0, 0, 255), (70, 90, 110, 255), (255, 255, 255, 255)):
    bg = Image.new('RGBA', (256, 256), color)
    original = np.asarray(Image.alpha_composite(bg, beauty), dtype=np.int16)
    rebuilt = np.asarray(Image.alpha_composite(bg, Image.alpha_composite(base, scarf)), dtype=np.int16)
    max_diff = int(np.abs(original - rebuilt).max())
    assert max_diff <= 2, (color, max_diff)
    print('SCARF_EXPORT_RECOMPOSE_PASS', color, max_diff)
print('CHARACTER SCARF EXPORT TEST: PASS')
