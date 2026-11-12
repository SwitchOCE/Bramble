exec(open("h40.py").read().split("table=")[0])
for name,f in {"Round + 1, max 10": lambda t: min(10,t+1), "Round + 1, max 12": lambda t: min(12,t+1)}.items():
    print(name)
    for av,lab in ((1.0,"everyone avoids big losses"),(0.0,"toy mix, nobody avoids")):
        print(f"   {lab:28s} {run(f,av)}")
