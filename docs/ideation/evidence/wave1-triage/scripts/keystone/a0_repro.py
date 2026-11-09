import sys; sys.path.insert(0, '.')
from common import *
import collections
print(collections.Counter((b['line'], b['start']) for b in BOARDS if b['round']==12 and b['start']!='hard_field'))
for line in LINES:
    for r in (8,10,12,14):
        bs=committed(line,r)
        print(line, r, len(bs), med([b['stats'] for b in bs]))
