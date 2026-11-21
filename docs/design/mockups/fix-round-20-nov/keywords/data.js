// The real cards these pages show (names, tiers and stats from the build at 13f44dd9; art under units/).
// Mouse and Pigeon cards use dev's numbers (origin/dev 5d697e07), where those tribes were reworked. Cards marked
// cand: have no art in the game yet; their picture is a candidate from the art round (cand/, a whole card picture
// used as the art layer under the real frame).
// A unit's keywords are the ones the game gives it in that state: printed, or from an aura named in `why`.
const U = {
  "gate-warden": { name: "Gate Warden", f: "badger", tier: 3, a: 3, h: 11 },
  "hedge-knight": { name: "Hedge Knight", f: "badger", tier: 1, a: 2, h: 8 },
  "hedge-lancer": { name: "Hedge Lancer", f: "badger", tier: 3, a: 6, h: 10 },
  "ironhide-berserker": { name: "Ironhide Berserker", f: "badger", tier: 5, a: 8, h: 18 },
  "old-brock": { name: "Old Brock", f: "badger", tier: 6, a: 8, h: 20 },
  "greatsword-bearer": { name: "Greatsword Bearer", f: "badger", tier: 4, a: 4, h: 12 },
  "dame-of-the-old-sett": { name: "Dame of the Old Sett", f: "badger", tier: 5, a: 6, h: 16 },
  "brock-cub": { name: "Brock Cub", f: "badger", tier: 1, a: 2, h: 6 },
  "husk-sentry": { name: "Husk Sentry", f: "locust", tier: 1, a: 3, h: 3 },
  "wheat-raider": { name: "Wheat Raider", f: "locust", tier: 2, a: 4, h: 2 },
  "skin-shedder": { name: "Skin-shedder", f: "locust", tier: 3, a: 3, h: 8 },
  "needle-page": { name: "Needle Page", f: "mouse", tier: 1, a: 4, h: 3 },
  "hedgerow-scout": { name: "Hedgerow Scout", f: "mouse", tier: 1, a: 3, h: 10 },
  "thimble-captain": { name: "Thimble Captain", f: "mouse", tier: 3, a: 3, h: 18 },
  "dame-bodkin": { name: "Dame Bodkin", f: "mouse", tier: 5, a: 6, h: 9 },
  "cousin": { name: "Cousin", f: "mouse", tier: 1, a: 2, h: 2 },
  "thimble-sentinel": { name: "Thimble Sentinel", f: "mouse", tier: 4, a: 3, h: 24, cand: true },
  "hayloft-aunt": { name: "Hayloft Aunt", f: "mouse", tier: 2, a: 2, h: 9, cand: true },
  "drill-sergeant": { name: "Drill-sergeant", f: "mouse", tier: 4, a: 4, h: 8, cand: true },
  "needle-pikeman": { name: "Needle Pikeman", f: "mouse", tier: 3, a: 4, h: 5 },
  "shrew-harrier": { name: "Shrew Harrier", f: "mouse", tier: 3, a: 5, h: 5 },
  "fencing-master": { name: "Fencing Master", f: "mouse", tier: 3, a: 10, h: 5 },
  "kettle-drummer": { name: "Kettle-drummer", f: "mouse", tier: 6, a: 5, h: 10 },
  "territorial": { name: "Territorial", f: "pigeon", tier: 1, a: 5, h: 7 },
  "sentry": { name: "Sentry", f: "pigeon", tier: 1, a: 2, h: 5 },
  "padre": { name: "Padre", f: "pigeon", tier: 3, a: 2, h: 9 },
  "wing-commander": { name: "Wing Commander", f: "pigeon", tier: 5, a: 10, h: 8 },
  "old-campaigner": { name: "Old Campaigner", f: "pigeon", tier: 2, a: 6, h: 9 },
  "flying-ace": { name: "Flying Ace", f: "pigeon", tier: 4, a: 8, h: 7 },
  "lance-corporal": { name: "Lance Corporal", f: "pigeon", tier: 2, a: 3, h: 6 },
  "squadron-leader": { name: "Squadron Leader", f: "pigeon", tier: 3, a: 4, h: 9 },
  "brigadier": { name: "Brigadier", f: "pigeon", tier: 5, a: 7, h: 13 },
  "field-marshal": { name: "Field Marshal", f: "pigeon", tier: 6, a: 9, h: 15 },
  "the-colonel": { name: "The Colonel", f: "pigeon", tier: 6, a: 6, h: 16 },
  "private": { name: "Private", f: "pigeon", tier: 1, a: 2, h: 2 },
  "nettle-sprout": { name: "Nettle Sprout", f: "thorn", tier: 1, a: 2, h: 7 },
  "blackthorn-sapling": { name: "Blackthorn Sapling", f: "thorn", tier: 2, a: 5, h: 6 },
  "nettle-skirmisher": { name: "Nettle Skirmisher", f: "thorn", tier: 3, a: 4, h: 10 },
  "hawthorn-warden": { name: "Hawthorn Warden", f: "thorn", tier: 4, a: 6, h: 14 },
  "lone-hawthorn": { name: "Lone Hawthorn", f: "thorn", tier: 5, a: 6, h: 22 },
  "the-old-hedge": { name: "The Old Hedge", f: "thorn", tier: 6, a: 9, h: 16 },
  "holly-knight": { name: "Holly Knight", f: "thorn", tier: 4, a: 5, h: 12 },
  "pip": { name: "Pip", f: "thorn", tier: 1, a: 3, h: 3 },
  "bramble-runner": { name: "Bramble Runner", f: "thorn", tier: 1, a: 4, h: 5 },
  "crab-apple": { name: "Crab Apple", f: "thorn", tier: 3, a: 4, h: 8 },
};

// make a card: id from U, keywords [{k, n, spent}], and stat overrides {a, h, hp (Health now, red if lower)}
function unitCard(id, kws, h, o = {}) {
  const u = U[id], a = o.a ?? u.a, hh = o.h ?? u.h, hp = o.hp ?? hh;
  const art = u.cand ? `cand/a-${id}.jpg` : `units/${u.f}/${id}.jpg`;
  const el = Cards.make({ tier: u.tier, art, attack: a, health: hp, hurt: hp < hh, h, id: o.uid || id });
  if (o.golden) el.classList.add("golden");
  return KW.decorate(el, kws, { h, tier: u.tier, flip: !!o.flip, looks: o.looks !== false, pips: o.pips || null });
}
