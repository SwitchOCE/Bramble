#!/usr/bin/env python3
"""Zone wireframe of the L1 buy screen. Usage: zones.py <card width> <out html>  (card height 250, regular-hexagon points)"""
import sys, math
cw=float(sys.argv[1]); out=sys.argv[2]
W,H=1920,1080; PIER=244; SHOP_B=330; EDGE=898; HAND_T=924; G=20; NICHE=12
ch=250; p=cw*math.tan(math.pi/6)/2
rowStep=ch-p+0.866*G; boardH=rowStep+ch
def hexa(x,y,label):
    pts=[(cw/2,0),(cw,p),(cw,ch-p),(cw/2,ch),(0,ch-p),(0,p)]
    d=" ".join(f"{x+a:.1f},{y+b:.1f}" for a,b in pts)
    return f'<polygon class="g" points="{d}"/><text class="slot" x="{x+cw/2:.1f}" y="{y+ch/2-28:.1f}">{label}</text>'
o=[]
def zone(x,y,w,h,cls): o.append(f'<rect class="{cls}" x="{x}" y="{y}" width="{w}" height="{h}"/>')
def dash(x1,y1,x2,y2): o.append(f'<line class="d" x1="{x1:.1f}" y1="{y1}" x2="{x2:.1f}" y2="{y2}"/>')
def sub(x,y,t): o.append(f'<text class="sub" x="{x:.1f}" y="{y}">{t}</text>')
zone(0,0,PIER,H,"col"); zone(W-PIER,0,PIER,H,"col")
zone(PIER,0,W-2*PIER,SHOP_B,"shop"); zone(PIER,SHOP_B,W-2*PIER,HAND_T-SHOP_B,"board"); zone(PIER,HAND_T,W-2*PIER,H-HAND_T,"hand")
for x0 in (0,W-PIER):
    dash(x0,SHOP_B,x0+PIER,SHOP_B); dash(x0,HAND_T,x0+PIER,HAND_T)
nw=cw+2*NICHE; row=5*nw+4*G; ux0=W/2-row/2
wl=ux0-NICHE; wr=ux0+row+NICHE
dash(wl,0,wl,SHOP_B); dash(wr,0,wr,SHOP_B)
bw=4*cw+3*G; bx=W/2-bw/2; tl=bx-40; tr=bx+bw+40
dash(tl,SHOP_B,tl,HAND_T); dash(tr,SHOP_B,tr,HAND_T)
by=SHOP_B+(EDGE-SHOP_B-boardH)/2
hx=W/2-(7*cw+6*G)/2
for i in range(5): o.append(hexa(ux0+NICHE+i*(nw+G),34,f"Shop {i+1}"))
for i in range(4): o.append(hexa(bx+i*(cw+G),by,f"Front {i+1}"))
for i in range(3): o.append(hexa(bx+(cw+G)/2+i*(cw+G),by+rowStep,f"Back {i+1}"))
for i in range(7): o.append(hexa(hx+i*(cw+G),955,f"Hand {i+1}").replace(f'y="{955+ch/2-28:.1f}"','y="1010"'))
for x0,name,short in ((0,"LEFT COLUMN","Left"),(W-PIER,"RIGHT COLUMN","Right")):
    cx=x0+PIER/2
    o.append(f'<text class="big2" x="{cx}" y="78">{name.split()[0]}</text><text class="big2" x="{cx}" y="126">{name.split()[1]}</text>')
    sub(cx,236,f"{short} top"); sub(cx,640,f"{short} middle"); sub(cx,1012,f"{short} bottom")
o.append(f'<text class="big" x="960" y="320">SHOP</text>')
wide=(wl-PIER)>=200
for cx,side in (((PIER+wl)/2,"left"),((wr+W-PIER)/2,"right")):
    if wide: sub(cx,150,"Shop"); sub(cx,186,f"{side} wing")
    else: sub(cx,130,"Shop"); sub(cx,166,side); sub(cx,202,"wing")
o.append(f'<text class="big" x="960" y="{HAND_T-12}">BOARD</text>')
for cx,side in (((PIER+tl)/2,"left"),((tr+W-PIER)/2,"right")):
    sub(cx,610,"Table"); sub(cx,646,side)
o.append(f'<text class="big hb" x="960" y="{H-10}">HAND</text>')
o.append(f'<text class="note" x="{PIER+24}" y="372">Card {cw:.0f} × {ch} · {cw/ch+1e-9:.2f} wide to 1 tall</text>')
css='''svg{font-family:"IBM Plex Mono",ui-monospace,Menlo,monospace}
.col{fill:#e0ebef;stroke:#26221a;stroke-width:4}.shop{fill:#f6f0e0;stroke:#26221a;stroke-width:4}
.board{fill:#efe7d2;stroke:#26221a;stroke-width:4}.hand{fill:#e4dbc2;stroke:#26221a;stroke-width:4}
.d{stroke:#5f584a;stroke-width:2.5;stroke-dasharray:10 9}.g{fill:none;stroke:#8a8069;stroke-width:2.5;stroke-dasharray:7 7}
.slot{font-size:22px;fill:#5f584a;text-anchor:middle;font-weight:500}
.big,.big2{font-family:"Zilla Slab",Georgia,serif;font-weight:700;fill:#26221a;text-anchor:middle;letter-spacing:.04em}
.big{font-size:50px;paint-order:stroke;stroke:#f6f0e0;stroke-width:10px;stroke-linejoin:round}.hb{stroke:#e4dbc2}.big2{font-size:42px}
.note{font-size:22px;fill:#26221a;font-weight:600;paint-order:stroke;stroke:#efe7d2;stroke-width:8px;stroke-linejoin:round}
.sub{font-size:30px;fill:#2f6d8e;text-anchor:middle;font-weight:600}'''
open(out,'w').write(f'''<!doctype html><meta charset="utf-8"><title>Buy screen zones</title><link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Zilla+Slab:wght@600;700&family=IBM+Plex+Mono:wght@500;600&display=swap">
<style>html,body{{margin:0;background:#efe7d2}}{css}</style>
<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(o)}</svg>''')
print(f"card {cw}x{ch} point {p:.1f}; wing {wl-PIER:.0f} wide; table side {tl-PIER:.0f} wide; board {bw:.0f}x{boardH:.0f} at y {by:.0f}; shop row {row:.0f}; hand {7*cw+6*G:.0f}; fight needs {4*G+2*boardH+64:.0f} of 1080")
