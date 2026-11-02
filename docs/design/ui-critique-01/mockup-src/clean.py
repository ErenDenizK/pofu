# Remove baked-in chrome from CI screenshots by per-column interpolation (sky is smooth).
import sys
import numpy as np
from PIL import Image, ImageFilter

src, dst, bands = sys.argv[1], sys.argv[2], sys.argv[3:]
im = np.asarray(Image.open(src).convert('RGB')).astype(float)
for b in bands:
    y0, y1 = map(int, b.split(':'))
    a, c = im[y0 - 1].copy(), im[y1 + 1].copy()
    for y in range(y0, y1 + 1):
        t = (y - y0 + 1) / (y1 - y0 + 2)
        im[y] = a * (1 - t) + c * t
out = Image.fromarray(im.clip(0, 255).astype('uint8'))
for b in bands:
    y0, y1 = map(int, b.split(':'))
    box = (0, max(y0 - 6, 0), out.width, min(y1 + 6, out.height))
    out.paste(out.crop(box).filter(ImageFilter.GaussianBlur(3)), box[:2])
out.save(dst, quality=95)
