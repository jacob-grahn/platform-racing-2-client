import sys
from PIL import Image

# usage: measure_bands.py img x0 y0 x1 y1 bgR bgG bgB tol
path = sys.argv[1]
x0, y0, x1, y1 = int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
bg = (int(sys.argv[6]), int(sys.argv[7]), int(sys.argv[8]))
tol = int(sys.argv[9])

im = Image.open(path).convert("RGB")
px = im.load()

def is_fg(r, g, b):
    return abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) > tol

rows = []
for y in range(y0, y1):
    cnt = 0
    for x in range(x0, x1):
        r, g, b = px[x, y]
        if is_fg(r, g, b):
            cnt += 1
    rows.append((y, cnt))

# find runs of rows with >=2 fg pixels (ignore tiny stem noise of 1px)
bands = []
cur = None
for y, cnt in rows:
    if cnt >= 2:
        if cur is None:
            cur = [y, y, cnt]
        else:
            cur[1] = y
            cur[2] = max(cur[2], cnt)
    else:
        if cur is not None:
            bands.append(cur)
            cur = None
if cur is not None:
    bands.append(cur)

print("bands (top_y, bottom_y, maxwidth):")
for b in bands:
    print("  %d - %d  (h=%d, w=%d)" % (b[0], b[1], b[1] - b[0] + 1, b[2]))
