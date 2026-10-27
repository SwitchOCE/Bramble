import json, sys, urllib.request, urllib.error, urllib.parse, time, os
from PIL import Image
import io

OUT = sys.argv[1]  # scratchpad dir
SPECIES = {
 "mouse":"Wood mouse","dormouse":"Edible dormouse","hazel_dormouse":"Hazel dormouse","vole":"Field vole","water_vole":"European water vole",
 "hedgehog":"European hedgehog","rabbit":"European rabbit","hare":"European hare","badger":"European badger","mole":"European mole",
 "ant":"Formica rufa","stagbeetle":"Lucanus cervus","snail":"Helix pomatia","otter":"Eurasian otter","beaver":"Eurasian beaver",
 "shrew":"Eurasian water shrew","heron":"Grey heron","goose":"Greylag goose","redsquirrel":"Red squirrel","flyingsquirrel":"Siberian flying squirrel",
 "jay":"Eurasian jay","woodpecker":"Great spotted woodpecker","wren":"Eurasian wren","robin":"European robin","fox":"Red fox","arcticfox":"Arctic fox",
 "weasel":"Least weasel","stoat":"Stoat","marten":"European pine marten","wolverine":"Wolverine","lemming":"Norway lemming","rat":"Brown rat",
 "magpie":"Eurasian magpie","jackdaw":"Western jackdaw","raven":"Common raven","rook":"Rook (bird)","wolf":"Eurasian wolf","lynx":"Eurasian lynx",
 "wildcat":"European wildcat","owl":"Tawny owl","toad":"Common toad","frog":"Common frog","salamander":"Fire salamander","newt":"Smooth newt",
 "olm":"Olm","adder":"Vipera berus","bat":"Greater horseshoe bat","moth":"Saturnia pavonia","stork":"White stork","cuckoo":"Common cuckoo",
 "puffin":"Atlantic puffin","pelican":"Dalmatian pelican","marmot":"Alpine marmot","ibex":"Alpine ibex","chamois":"Chamois",
 "hamster":"European hamster","souslik":"European ground squirrel","hoopoe":"Eurasian hoopoe","genet":"Common genet","capercaillie":"Western capercaillie",
 "bison":"European bison","stag":"Red deer","bear":"Eurasian brown bear","boar":"Wild boar","swan":"Mute swan","bee":"Western honey bee",
 "cicada":"Cicada orni","coot":"Eurasian coot","bittern":"Eurasian bittern","gull":"European herring gull"
}
UA = {"User-Agent":"WoodlandFolio/1.0 (personal reference page; keechalexander research)"}
def get(u, js):
    for i in range(5):
        try:
            r = urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=20)
            return json.load(r) if js else r.read()
        except urllib.error.HTTPError as e:
            if e.code == 429: time.sleep(6*(i+1)); continue
            raise
    raise RuntimeError("429 after retries")
res = json.load(open(os.path.join(OUT,"photos.json"))) if os.path.exists(os.path.join(OUT,"photos.json")) else {}
os.makedirs(os.path.join(OUT,"ph"), exist_ok=True)
for k, t in SPECIES.items():
    if k in res and res[k].get("thumb") and os.path.exists(os.path.join(OUT,"ph",k+".jpg")): continue
    url = "https://en.wikipedia.org/api/rest_v1/page/summary/" + urllib.parse.quote(t.replace(" ","_"), safe="()")
    try:
        d = get(url, True)
        th = d.get("thumbnail",{}).get("source"); orig = d.get("originalimage",{}).get("source")
        res[k] = {"name": d.get("title", t), "thumb": th, "orig": orig, "page": d.get("content_urls",{}).get("desktop",{}).get("page")}
        if th:
            b = get(th, False)
            Image.open(io.BytesIO(b)).convert("RGB").save(os.path.join(OUT,"ph",k+".jpg"))
    except Exception as e:
        res[k] = {"error": str(e)}
    time.sleep(1.5)
json.dump(res, open(os.path.join(OUT,"photos.json"),"w"), indent=1)
print({k:v.get("error") for k,v in res.items() if "error" in v or not v.get("thumb")})
