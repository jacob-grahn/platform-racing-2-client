import sys
from PIL import Image
path = sys.argv[1]
x0, y0, x1, y1 = int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
im = Image.open(path).convert("RGB")
px = im.load()
for y in range(y0, y1):
    cnt = 0
    for x in range(x0, x1):
        r, g, b = px[x, y]
        # strong red: head cherry
        if r > 120 and r > g + 50 and r > b + 50:
            cnt += 1
    if cnt > 0:
        print("y=%d red=%d" % (y, cnt))
