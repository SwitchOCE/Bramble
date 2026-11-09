import sys
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
frames = [int(x) for x in sys.argv[3].split(',')]
scale = float(sys.argv[4]) if len(sys.argv) > 4 else 0.6
box = [int(v) for v in sys.argv[5].split(',')] if len(sys.argv) > 5 else None
im = Image.open(src)
W, H = im.size
fw, fh = W // 4, H // 2
tiles = []
for j in frames:
    c, r = j % 4, j // 4
    t = im.crop((c*fw, r*fh, (c+1)*fw, (r+1)*fh))
    if box: t = t.crop(box)
    t = t.resize((int(t.width*scale), int(t.height*scale)))
    tiles.append(t)
cols = 2 if len(tiles) > 1 else 1
rows = (len(tiles)+cols-1)//cols
o = Image.new('RGB', (tiles[0].width*cols, tiles[0].height*rows), 'white')
for i, t in enumerate(tiles):
    o.paste(t, ((i % cols)*t.width, (i//cols)*t.height))
o.save(out, quality=85)
print(o.size)
