import json, sys, os
d = os.path.dirname(os.path.abspath(__file__))
data = open(os.path.join(d, "data.json")).read()
cmp_path = sys.argv[1]
cmp = json.dumps(json.load(open(cmp_path)))
t = open(os.path.join(d, "template.html")).read()
safe = lambda s: s.replace("</", "<\\/")
out = t.replace("/*DATA*/", safe(data)).replace("/*CMP*/", safe(cmp))
open(os.path.join(d, "ogre-tribes.html"), "w").write(out)
print(len(out), "bytes")
