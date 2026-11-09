"""Fairies: biggest Ring slot at R12 (count, stats), what Fetch can copy, empty-slot Rings."""
import sys, math; sys.path.insert(0, '.')
from common import *
for line in ["line_fairies_ring", "line_fairies_court"]:
    bs = committed(line, 12)
    mx = [max(b['rings']) if b['rings'] else 0 for b in bs]
    mxs = [2*math.ceil(max(b['rings'])*b['ring_size']) if b['rings'] else 0 for b in bs]
    occ = [sum(1 for u in b['units'] if u[6]=='board' and u[7]) for b in bs]
    emptyr = [sum(c for i,c in enumerate(b['rings']) if i not in {u[5] for u in b['units'] if u[6]=='board'}) for b in bs]
    print(line, "biggest slot Rings q25/50/75", q(mx,.25), med(mx), q(mx,.75), "| its stats med", med(mxs), "(paper B1 33 Rings -> 396 stats)",
          "| units on board med", med(occ), "| Rings on empty slots med", med(emptyr))
