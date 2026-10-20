import sys, collections
from PIL import Image, ImageFilter
import numpy as np
src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert('RGB')
a = np.asarray(im).astype(np.int32)
h, w, _ = a.shape
r,g,b = a[...,0],a[...,1],a[...,2]
# background = sky blue or near-white clouds: high brightness, blue >= red, low saturation-ish
bright = (r+g+b)/3
sky = (b > 200) & (b >= r + 5) & (b >= g - 5) & (bright > 175)
cloud = (r > 225) & (g > 225) & (b > 225)
bg = sky | cloud
# flood fill from borders over bg pixels
mask = np.zeros((h,w), bool)
q = collections.deque()
for x in range(w):
    for y in (0, h-1):
        if bg[y,x]: mask[y,x]=True; q.append((y,x))
for y in range(h):
    for x in (0, w-1):
        if bg[y,x] and not mask[y,x]: mask[y,x]=True; q.append((y,x))
while q:
    y,x = q.popleft()
    for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)):
        ny,nx=y+dy,x+dx
        if 0<=ny<h and 0<=nx<w and not mask[ny,nx] and bg[ny,nx]:
            mask[ny,nx]=True; q.append((ny,nx))
# enclosed pockets of the *same* sky colour as the image border (holes in a torii gate,
# under a slide) become transparent too; saturated blue paint/toys are kept.
skyc = a[mask & sky].mean(axis=0)
near = (np.abs(a - skyc).sum(axis=2) < 30) | cloud
from collections import deque
seen = mask.copy()
for sy in range(0,h,3):
    for sx in range(0,w,3):
        if near[sy,sx] and not seen[sy,sx] and not cloud[sy,sx]:
            comp=[(sy,sx)]; seen[sy,sx]=True; qq=deque(comp)
            while qq:
                y,x=qq.popleft()
                for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)):
                    ny,nx=y+dy,x+dx
                    if 0<=ny<h and 0<=nx<w and not seen[ny,nx] and near[ny,nx]:
                        seen[ny,nx]=True; qq.append((ny,nx)); comp.append((ny,nx))
            ys,xs=map(np.array,zip(*comp))
            skyn=(~cloud[ys,xs]).sum()
            if len(comp)>800 and skyn>0.7*len(comp):
                mask[ys,xs]=True
# drop stray specks (cloud edges) – keep opaque components >= 1% of the subject
fg = ~mask
seen2 = np.zeros_like(fg); comps=[]
for sy in range(0,h,2):
    for sx in range(0,w,2):
        if fg[sy,sx] and not seen2[sy,sx]:
            comp=[(sy,sx)]; seen2[sy,sx]=True; qq=deque(comp)
            while qq:
                y,x=qq.popleft()
                for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)):
                    ny,nx=y+dy,x+dx
                    if 0<=ny<h and 0<=nx<w and fg[ny,nx] and not seen2[ny,nx]:
                        seen2[ny,nx]=True; qq.append((ny,nx)); comp.append((ny,nx))
            comps.append(comp)
total=sum(len(c) for c in comps)
for c in comps:
    if len(c) < 0.01*total:
        ys,xs=map(np.array,zip(*c)); mask[ys,xs]=True
alpha = Image.fromarray(np.where(mask,0,255).astype(np.uint8))
# keep largest component only: fill holes / remove specks via morphology
alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
alpha = alpha.filter(ImageFilter.GaussianBlur(1.2))
out = im.copy(); out.putalpha(alpha)
bbox = alpha.point(lambda v: 255 if v>40 else 0).getbbox()
out = out.crop(bbox)
out.thumbnail((560,560), Image.LANCZOS)
out.save(dst, optimize=True)
print(dst, out.size, bbox)
