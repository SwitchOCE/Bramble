import re,sys
lines=open(sys.argv[1]).read().split('\n')
rows=[]
for i,l in enumerate(lines):
    m=re.match(r'\d+:(res://\S+)',l)
    if m and i+1<len(lines):
        n=re.search(r'total: ([\d.]+)/\d+ % \tself: ([\d.]+)/\d+ % tcalls: (\d+)',lines[i+1])
        if n: rows.append((float(n.group(2)),float(n.group(1)),int(n.group(3)),m.group(1)))
print("sum self", sum(r[0] for r in rows))
for r in sorted(rows,reverse=True)[:int(sys.argv[2]) if len(sys.argv)>2 else 30]: print("%7.3f self %7.3f tot %8d  %s"%r)
