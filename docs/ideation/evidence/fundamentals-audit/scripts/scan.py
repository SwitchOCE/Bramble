# Scan a video at 2 fps; print per-second features to find "Combat" banners.
import sys, subprocess, numpy as np
ff, video, out = sys.argv[1], sys.argv[2], sys.argv[3]
W,H=320,180
p = subprocess.Popen([ff,'-hide_banner','-loglevel','error','-i',video,'-vf',f'fps=2,scale={W}:{H}','-f','rawvideo','-pix_fmt','rgb24','-'],stdout=subprocess.PIPE)
rows=[]; i=0
while True:
    b=p.stdout.read(W*H*3)
    if len(b)<W*H*3: break
    f=np.frombuffer(b,np.uint8).reshape(H,W,3).astype(np.float32)
    g=f.mean(2)
    lap=np.abs(4*g[1:-1,1:-1]-g[:-2,1:-1]-g[2:,1:-1]-g[1:-1,:-2]-g[1:-1,2:]).mean()
    c=f[70:110,120:200]   # centre
    r,gg,bb=c[...,0],c[...,1],c[...,2]
    gold=((r>180)&(gg>140)&(bb<120)).mean()
    purple=((r>100)&(bb>120)&(gg<80)).mean()
    rows.append((i/2,lap,gold,purple)); i+=1
np.save(out,np.array(rows))
print(len(rows))
