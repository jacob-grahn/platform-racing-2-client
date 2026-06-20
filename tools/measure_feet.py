import sys
from PIL import Image

# find bottom-most blue (shoe) pixel rows in a region
path = sys.argv[1]
x0, y0, x1, y1 = int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
im = Image.open(path).convert("RGB")
px = im.load()
for y in range(y0, y1):
    cnt = 0
    for x in range(x0, x1):
        r, g, b = px[x, y]
        if b > 90 and b > r + 20 and b > g + 20:
            cnt += 1
    if cnt > 0:
        print("y=%d blue=%d" % (y, cnt))
