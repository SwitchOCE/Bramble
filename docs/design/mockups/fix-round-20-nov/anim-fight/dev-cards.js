// The dev branch's cards (origin/dev 5d697e07), for these prototypes only. PROPOSAL page support, not decided.
// kit/data.js holds main's cards; the owner plays dev, where Medals, Orders, Stiff Upper Lip and some units are
// gone and Renown, Hand-me-down, Charge and Supply are new. This file swaps ALL_CARDS for dev's (names, tiers,
// stats, card text as dev shows it, from a dump of src/content/<tribe>/units.json), updates the keyword marks
// (assets/glass/keywords.json and the display.json reminders on dev), and adds the two dev pieces the cards show:
// Charge and Supply pips over the stat discs (src/screens/card_pips.gd) and the Renown pill (glass_slot.gd).
// Load after kit/kit.js and before kit/screen.js or anim.js. The same file sits in anim-recruit/ and anim-fight/.
const DEV_CARDS = [
  {"id": "brock-cub", "name": "Brock Cub", "tier": 1, "attack": 2, "health": 6, "tribe": "badger", "text": "Fury 1. Grudge.", "token": false},
  {"id": "hedge-knight", "name": "Hedge Knight", "tier": 1, "attack": 2, "health": 8, "tribe": "badger", "text": "Guard. Fury 1.", "token": false},
  {"id": "sett-shield-bearer", "name": "Sett Shield-bearer", "tier": 2, "attack": 2, "health": 8, "tribe": "badger", "text": "Squire. Grudge. Lends its Health to the units in front of it.", "token": false},
  {"id": "armsbearer", "name": "Armsbearer", "tier": 2, "attack": 3, "health": 5, "tribe": "badger", "text": "Squire. Grudge. Lends its Attack to the units in front of it.", "token": false},
  {"id": "relic-seeker", "name": "Relic Seeker", "tier": 2, "attack": 2, "health": 6, "tribe": "badger", "text": "Squire. After each fight, gain 1 gold, or 2 if you were outnumbered by 3 or more.", "token": false},
  {"id": "gate-warden", "name": "Gate Warden", "tier": 3, "attack": 3, "health": 11, "tribe": "badger", "text": "Guard. Whenever this is attacked, gain +1/+3 permanently.", "token": false},
  {"id": "grudge-keeper", "name": "Grudge-keeper", "tier": 3, "attack": 4, "health": 10, "tribe": "badger", "text": "Fury 1. Your Knights have Grudge.", "token": false},
  {"id": "hedge-lancer", "name": "Hedge Lancer", "tier": 3, "attack": 6, "health": 10, "tribe": "badger", "text": "Fury 1. Start of fight: This attacks immediately and takes no damage.", "token": false},
  {"id": "sword-heir", "name": "Sword-heir", "tier": 3, "attack": 3, "health": 9, "tribe": "badger", "text": "Squire. After a unit in front of this dies, gain its Attack, Health and Fury this fight.", "token": false},
  {"id": "herald-of-the-charge", "name": "Herald of the Charge", "tier": 4, "attack": 4, "health": 10, "tribe": "badger", "text": "Squire. Start of fight: The units in front of this attack immediately.", "token": false},
  {"id": "greatsword-bearer", "name": "Greatsword Bearer", "tier": 4, "attack": 4, "health": 12, "tribe": "badger", "text": "Squire. The units in front of this have Overrun.", "token": false},
  {"id": "sett-sexton", "name": "Sett Sexton", "tier": 4, "attack": 3, "health": 12, "tribe": "badger", "text": "Squire. After a unit in front of this gains Attack from Fury, it gains +2 Attack permanently (2 a fight each).", "token": false},
  {"id": "master-at-arms", "name": "Master-at-Arms", "tier": 3, "attack": 5, "health": 9, "tribe": "badger", "text": "Recruit: Give a unit +1 Fury.", "token": false},
  {"id": "ironhide-berserker", "name": "Ironhide Berserker", "tier": 5, "attack": 8, "health": 18, "tribe": "badger", "text": "Fury 3. Overrun.", "token": false},
  {"id": "dame-of-the-old-sett", "name": "Dame of the Old Sett", "tier": 5, "attack": 6, "health": 16, "tribe": "badger", "text": "Your Knights have +2 Fury and Overrun.", "token": false},
  {"id": "tourney-champion", "name": "Tourney Champion", "tier": 5, "attack": 10, "health": 14, "tribe": "badger", "text": "Fury 1. Start of fight: This attacks the enemy with the most Attack and takes no damage.", "token": false},
  {"id": "the-oakfeller", "name": "The Oakfeller", "tier": 6, "attack": 12, "health": 22, "tribe": "badger", "text": "Fury 3. Overrun. After this attacks and kills a unit, it attacks once more.", "token": false},
  {"id": "old-brock", "name": "Old Brock, Last of His Sett", "tier": 6, "attack": 8, "health": 20, "tribe": "badger", "text": "After a friendly unit dies, gain its Attack and Health this fight.", "token": false},
  {"id": "marshal-of-the-red-mist", "name": "Marshal of the Red Mist", "tier": 6, "attack": 10, "health": 18, "tribe": "badger", "text": "Your units' Fury is doubled.", "token": false},
  {"id": "hopper", "name": "Hopper", "tier": 1, "attack": 2, "health": 2, "tribe": "locust", "text": "", "token": true},
  {"id": "green-recruit", "name": "Green Recruit", "tier": 1, "attack": 2, "health": 2, "tribe": "locust", "text": "When this dies, summon a Hopper.", "token": false},
  {"id": "husk-sentry", "name": "Husk Sentry", "tier": 1, "attack": 3, "health": 3, "tribe": "locust", "text": "Guard. Molt.", "token": false},
  {"id": "prophet-of-the-dust", "name": "Prophet of the Dust", "tier": 2, "attack": 2, "health": 7, "tribe": "locust", "text": "At the end of your turn, Tide +1.", "token": false},
  {"id": "horde-runner", "name": "Horde-runner", "tier": 2, "attack": 3, "health": 5, "tribe": "locust", "text": "At the start of your turn, get a Hopper.", "token": false},
  {"id": "wheat-raider", "name": "Wheat Raider", "tier": 2, "attack": 4, "health": 2, "tribe": "locust", "text": "Molt. When this dies, deal 4 damage to a random enemy.", "token": false},
  {"id": "brood-mother", "name": "Brood Mother", "tier": 3, "attack": 3, "health": 6, "tribe": "locust", "text": "When this dies, summon a Hopper and give your Hoppers +1/+1 for the rest of the game.", "token": false},
  {"id": "skin-shedder", "name": "Skin-shedder", "tier": 3, "attack": 3, "health": 8, "tribe": "locust", "text": "Start of fight: Give Molt to the units next to this.", "token": false},
  {"id": "gleaner", "name": "Gleaner", "tier": 3, "attack": 2, "health": 8, "tribe": "locust", "text": "After a friendly unit dies, deal 5 damage to the highest-Health enemy.", "token": false},
  {"id": "gorger", "name": "Gorger", "tier": 4, "attack": 5, "health": 7, "tribe": "locust", "text": "The first time you sell a unit each turn, this eats it.", "token": false},
  {"id": "famine-caller", "name": "Famine-caller", "tier": 3, "attack": 6, "health": 4, "tribe": "locust", "text": "When this dies, Tide +2.", "token": false},
  {"id": "sky-darkener", "name": "Sky-darkener", "tier": 4, "attack": 4, "health": 8, "tribe": "locust", "text": "Start of fight: Summon 2 Hoppers.", "token": false},
  {"id": "orchard-stripper", "name": "Orchard Stripper", "tier": 4, "attack": 6, "health": 6, "tribe": "locust", "text": "When this dies, deal 5 damage to all enemies.", "token": false},
  {"id": "granary-glutton", "name": "Granary Glutton", "tier": 4, "attack": 5, "health": 7, "tribe": "locust", "text": "Whenever you sell a Locust, this eats it.", "token": false},
  {"id": "war-drummer", "name": "War-drummer", "tier": 5, "attack": 5, "health": 10, "tribe": "locust", "text": "Whenever this attacks, trigger the death effect of a unit behind it.", "token": false},
  {"id": "twice-shed-veteran", "name": "Twice-shed Veteran", "tier": 5, "attack": 6, "health": 8, "tribe": "locust", "text": "After another friendly unit returns, it and this gain +6/+6 this fight.", "token": false},
  {"id": "the-eighth-plague", "name": "The Eighth Plague", "tier": 5, "attack": 4, "health": 12, "tribe": "locust", "text": "After a friendly unit dies, deal damage to a random enemy equal to the number of friendly units that died this fight.", "token": false},
  {"id": "dirge-singer", "name": "Dirge-singer", "tier": 6, "attack": 3, "health": 14, "tribe": "locust", "text": "Your death effects trigger twice.", "token": false},
  {"id": "swarm-lord", "name": "Swarm-lord", "tier": 6, "attack": 6, "health": 10, "tribe": "locust", "text": "After 2 friendly Locusts die, Tide +1.", "token": false},
  {"id": "mother-of-thousands", "name": "Mother of Thousands", "tier": 6, "attack": 5, "health": 12, "tribe": "locust", "text": "Whenever you summon Hoppers, summon twice as many.", "token": false},
  {"id": "cousin", "name": "Cousin", "tier": 1, "attack": 2, "health": 2, "tribe": "mouse", "text": "Hand-me-down.", "token": true},
  {"id": "needle-page", "name": "Needle Page", "tier": 1, "attack": 4, "health": 3, "tribe": "mouse", "text": "Pile on 1.", "token": false},
  {"id": "hedgerow-scout", "name": "Hedgerow Scout", "tier": 1, "attack": 3, "health": 10, "tribe": "mouse", "text": "Hand-me-down.", "token": false},
  {"id": "harvest-piper", "name": "Harvest Piper", "tier": 2, "attack": 3, "health": 11, "tribe": "mouse", "text": "Recruit: Give your other Mice +5 Attack.", "token": false},
  {"id": "hayloft-aunt", "name": "Hayloft Aunt", "tier": 2, "attack": 2, "health": 9, "tribe": "mouse", "text": "Hand-me-down. Recruit: Add a Cousin to your hand.", "token": false, "noArt": true},
  {"id": "shrew-cutpurse", "name": "Shrew Cutpurse", "tier": 2, "attack": 2, "health": 4, "tribe": "mouse", "text": "Pile on 1. After this piles on, gain 1 gold.", "token": false},
  {"id": "thimble-captain", "name": "Thimble Captain", "tier": 3, "attack": 3, "health": 18, "tribe": "mouse", "text": "Charge 2: Whenever a neighbour attacks, summon a Cousin.", "token": false},
  {"id": "fencing-master", "name": "Fencing Master", "tier": 3, "attack": 10, "health": 5, "tribe": "mouse", "text": "Pile on 2. After this piles on, it gains +2 Attack permanently.", "token": false},
  {"id": "bell-ringer", "name": "Bell-ringer", "tier": 3, "attack": 3, "health": 5, "tribe": "mouse", "text": "Hand-me-down. Your Hand-me-downs give +3 more Attack.", "token": false, "noArt": true},
  {"id": "needle-sister", "name": "Needle Sister", "tier": 3, "attack": 4, "health": 12, "tribe": "mouse", "text": "Charge 2: After this gains a Hand-me-down, it attacks immediately.", "token": false, "noArt": true},
  {"id": "dormouse-cook", "name": "Dormouse Cook", "tier": 4, "attack": 2, "health": 24, "tribe": "mouse", "text": "At the end of your turn, give your other Mice +7 Attack.", "token": false},
  {"id": "grandmother-hob", "name": "Grandmother Hob", "tier": 4, "attack": 3, "health": 8, "tribe": "mouse", "text": "Charge 4: After one of your Mice gains a Hand-me-down, give it +4 Attack permanently.", "token": false, "noArt": true},
  {"id": "thimble-sentinel", "name": "Thimble Sentinel", "tier": 4, "attack": 3, "health": 24, "tribe": "mouse", "text": "Guard. Hand-me-down.", "token": false, "noArt": true},
  {"id": "drill-sergeant", "name": "Drill-sergeant", "tier": 4, "attack": 4, "health": 8, "tribe": "mouse", "text": "Your Mice neighbouring this have Pile on 1.", "token": false, "noArt": true},
  {"id": "parish-standard-bearer", "name": "Parish Standard-bearer", "tier": 5, "attack": 6, "health": 16, "tribe": "mouse", "text": "Start of fight: Give your Mice +3 Attack this fight for each Mouse you have.", "token": false},
  {"id": "widow-thimble", "name": "Widow Thimble", "tier": 5, "attack": 5, "health": 28, "tribe": "mouse", "text": "Your Hand-me-downs go to the 2 nearest Mice.", "token": false, "noArt": true},
  {"id": "dame-bodkin", "name": "Dame Bodkin", "tier": 5, "attack": 6, "health": 9, "tribe": "mouse", "text": "Pile on 2. Your Mice's pile-on hits deal double damage.", "token": false},
  {"id": "needle-pikeman", "name": "Needle Pikeman", "tier": 6, "attack": 6, "health": 36, "tribe": "mouse", "text": "Pile on 5. Can't attack. After this piles on, your Mice with Pile on gain +2 Attack permanently.", "token": false},
  {"id": "king-speck", "name": "King Speck", "tier": 6, "attack": 6, "health": 24, "tribe": "mouse", "text": "Whenever this attacks, fill your empty slots with Cousins.", "token": false},
  {"id": "old-mother-needle", "name": "Old Mother Needle", "tier": 6, "attack": 7, "health": 14, "tribe": "mouse", "text": "Charge 3: Your Hand-me-downs are permanent.", "token": false, "noArt": true},
  {"id": "private", "name": "Private", "tier": 1, "attack": 2, "health": 2, "tribe": "pigeon", "text": "", "token": true},
  {"id": "sentry", "name": "Sentry", "tier": 1, "attack": 2, "health": 5, "tribe": "pigeon", "text": "Supply 6: At the end of your turn, give this slot 1 Renown.", "token": false},
  {"id": "territorial", "name": "Territorial", "tier": 1, "attack": 5, "health": 7, "tribe": "pigeon", "text": "Reserve.", "token": false},
  {"id": "recruiting-sergeant", "name": "Recruiting Sergeant", "tier": 2, "attack": 3, "health": 7, "tribe": "pigeon", "text": "Charge 1: After a unit in front of this dies, a Private steps in there.", "token": false},
  {"id": "lance-corporal", "name": "Lance Corporal", "tier": 2, "attack": 3, "health": 6, "tribe": "pigeon", "text": "1: Give the slots in front of this 2 Renown.", "token": false},
  {"id": "old-campaigner", "name": "Old Campaigner", "tier": 2, "attack": 6, "health": 9, "tribe": "pigeon", "text": "After each fight, give this slot 1 Renown, or 2 if this survived.", "token": false},
  {"id": "colour-sergeant", "name": "Colour Sergeant", "tier": 3, "attack": 4, "health": 9, "tribe": "pigeon", "text": "At the end of your turn, if this row is full of Pigeons, give each slot in it 2 Renown.", "token": false},
  {"id": "padre", "name": "Padre", "tier": 3, "attack": 2, "health": 9, "tribe": "pigeon", "text": "Charge 4: After a friendly unit dies, give its slot 1 Renown.", "token": false},
  {"id": "grenadier-guard", "name": "Grenadier Guard", "tier": 3, "attack": 4, "health": 11, "tribe": "pigeon", "text": "0: Make a slot your Guard post. At the end of your turn, give your Guard post 3 Renown.", "token": false},
  {"id": "squadron-leader", "name": "Squadron Leader", "tier": 3, "attack": 4, "health": 9, "tribe": "pigeon", "text": "The units in front of this have Sortie and +3 Attack.", "token": false},
  {"id": "home-guard", "name": "Home Guard", "tier": 3, "attack": 3, "health": 11, "tribe": "pigeon", "text": "Guard. Reserve.", "token": false, "noArt": true},
  {"id": "flying-ace", "name": "Flying Ace", "tier": 4, "attack": 8, "health": 7, "tribe": "pigeon", "text": "Cleave. Charge 2: After this kills, give this slot 1 Renown.", "token": false},
  {"id": "lieutenant", "name": "Lieutenant", "tier": 4, "attack": 9, "health": 11, "tribe": "pigeon", "text": "Start of fight: If this row is full, each unit in it deals half its slot's Renown as damage to the enemy across from it.", "token": false},
  {"id": "bugler", "name": "Bugler", "tier": 4, "attack": 3, "health": 8, "tribe": "pigeon", "text": "Charge 2: After a friendly unit dies, a Private steps in there.", "token": false},
  {"id": "quartermaster", "name": "Quartermaster", "tier": 4, "attack": 3, "health": 12, "tribe": "pigeon", "text": "Recruit: Give a unit in your hand Reserve. You can call 1 more reservist each fight.", "token": false, "noArt": true},
  {"id": "colour-ensign", "name": "Colour Ensign", "tier": 5, "attack": 6, "health": 14, "tribe": "pigeon", "text": "Start of fight: This slot copies your highest Renown.", "token": false},
  {"id": "wing-commander", "name": "Wing Commander", "tier": 5, "attack": 10, "health": 8, "tribe": "pigeon", "text": "Sortie. Start of fight: Your Pigeons with Sortie attack immediately.", "token": false},
  {"id": "group-captain", "name": "Group Captain", "tier": 5, "attack": 6, "health": 14, "tribe": "pigeon", "text": "Your reservists have Sortie and +4 Attack.", "token": false, "noArt": true},
  {"id": "regimental-sergeant-major", "name": "Regimental Sergeant Major", "tier": 6, "attack": 8, "health": 14, "tribe": "pigeon", "text": "At the end of your turn, give every slot 4 Renown.", "token": false},
  {"id": "the-colonel", "name": "The Colonel", "tier": 6, "attack": 6, "health": 16, "tribe": "pigeon", "text": "Reservists from your hand have double Renown.", "token": false},
  {"id": "air-marshal", "name": "Air Marshal", "tier": 6, "attack": 7, "health": 15, "tribe": "pigeon", "text": "Charge 3: After a reservist steps in, it attacks immediately.", "token": false, "noArt": true},
  {"id": "pip", "name": "Pip", "tier": 1, "attack": 3, "health": 3, "tribe": "thorn", "text": "Seed.", "token": true},
  {"id": "bramble-runner", "name": "Bramble Runner", "tier": 1, "attack": 4, "health": 5, "tribe": "thorn", "text": "Seed.", "token": false},
  {"id": "nettle-sprout", "name": "Nettle Sprout", "tier": 1, "attack": 2, "health": 7, "tribe": "thorn", "text": "Thorns 2.", "token": false},
  {"id": "hedge-layer", "name": "Hedge Layer", "tier": 2, "attack": 2, "health": 7, "tribe": "thorn", "text": "Bury: Gain 1 gold.", "token": false},
  {"id": "sweetbriar", "name": "Sweetbriar", "tier": 2, "attack": 3, "health": 7, "tribe": "thorn", "text": "Whenever a unit goes into your Compost, gain +1/+1 permanently.", "token": false},
  {"id": "blackthorn-sapling", "name": "Blackthorn Sapling", "tier": 2, "attack": 5, "health": 6, "tribe": "thorn", "text": "Root 1. After this returns, gain +2/+2 permanently.", "token": false},
  {"id": "blackberry-sprawl", "name": "Blackberry Sprawl", "tier": 3, "attack": 4, "health": 8, "tribe": "thorn", "text": "Grow 2.", "token": false},
  {"id": "nettle-skirmisher", "name": "Nettle Skirmisher", "tier": 3, "attack": 4, "health": 10, "tribe": "thorn", "text": "Thorns 4. Root 1.", "token": false},
  {"id": "crab-apple", "name": "Crab-apple", "tier": 3, "attack": 4, "health": 8, "tribe": "thorn", "text": "Seed. When this dies, summon a Pip.", "token": false},
  {"id": "old-stump", "name": "Old Stump", "tier": 3, "attack": 5, "health": 6, "tribe": "thorn", "text": "When this dies, summon a copy of the highest-tier unit in your Compost.", "token": false},
  {"id": "ivy-climber", "name": "Ivy Climber", "tier": 4, "attack": 3, "health": 12, "tribe": "thorn", "text": "The units in front of this have Grow 1.", "token": false},
  {"id": "hawthorn-warden", "name": "Hawthorn Warden", "tier": 4, "attack": 6, "health": 14, "tribe": "thorn", "text": "Guard. Root 2.", "token": false},
  {"id": "holly-knight", "name": "Holly Knight", "tier": 4, "attack": 5, "health": 12, "tribe": "thorn", "text": "Your front-row Briars have +1 Thorns for every 3 units in your Compost.", "token": false},
  {"id": "leafmould-carter", "name": "Leafmould Carter", "tier": 4, "attack": 5, "health": 11, "tribe": "thorn", "text": "Bury: Give your Briars +2/+2 permanently.", "token": false},
  {"id": "lone-hawthorn", "name": "Lone Hawthorn", "tier": 5, "attack": 6, "health": 22, "tribe": "thorn", "text": "Guard. Thorns 8. Enemies your Thorns kill go into your Compost.", "token": false},
  {"id": "hazel-coppicer", "name": "Hazel Coppicer", "tier": 5, "attack": 6, "health": 14, "tribe": "thorn", "text": "After a friendly unit returns, give your units +1/+1 permanently.", "token": false},
  {"id": "elder-mother", "name": "Elder Mother", "tier": 5, "attack": 5, "health": 13, "tribe": "thorn", "text": "Start of fight: Summon copies of the 2 highest-tier units in your Compost, with +1/+1 for each unit in it.", "token": false},
  {"id": "briar-king", "name": "Briar King", "tier": 6, "attack": 8, "health": 16, "tribe": "thorn", "text": "Your other front-row Briars have Grow 2.", "token": false},
  {"id": "mother-midden", "name": "Old Mother Midden", "tier": 6, "attack": 7, "health": 18, "tribe": "thorn", "text": "Bury: Give your Briars +2/+2 permanently. Your Bury effects happen twice.", "token": false},
  {"id": "the-old-hedge", "name": "The Old Hedge", "tier": 6, "attack": 9, "health": 16, "tribe": "thorn", "text": "Your other Briars have Root 1.", "token": false}
];
(function () {
  const keepTypes = {}; ALL_CARDS.forEach(c => keepTypes[c.id] = c.types);
  ALL_CARDS.length = 0;
  DEV_CARDS.forEach(c => ALL_CARDS.push({ ...c, effects: [], reminders: [], types: keepTypes[c.id] || [TRIBE_NAME[c.tribe]] }));
  // keyword marks: dev's names, families, icons and reminders
  ["Medal", "Decorated", "Stiff Upper Lip", "Order", "Slot buff", "Joins the fight"].forEach(k => delete KW[k]);
  Object.assign(IC, {
    star: '<path d="M12 3.5l2.5 5.2 5.6.7-4.1 3.9 1 5.6L12 16.2l-5 2.7 1-5.6-4.1-3.9 5.6-.7z"/>',
    handdown: '<circle cx="5.5" cy="17" r="2.5"/><circle cx="18.5" cy="17" r="2.5"/><path d="M5.5 12c1.5-6 11.5-6 13 0"/><path d="M15 10.5l3.5 1.5 1-3.5"/>',
    charge: '<path d="M13 2 5 14h6l-1 8 9-13h-6z"/>',
    supply: '<path d="M3 7h18v13H3zM2 4h20v4H2zM6 11l12 6M18 11 6 17"/>',
  });
  Object.assign(KW, {
    "Renown": ["growth", "star", "The unit that starts the fight here, and any reservist who steps in, has +1/+1 for each."],
    "Hand-me-down": ["growth", "handdown", "When this dies, the nearest friendly Mouse gains its Attack this fight."],
    "Charge": ["count", "charge", "Works this many times, then stops. Refills each fight."],
    "Supply": ["count", "supply", "Works this many times in all, then never again."],
    "Pile on": ["strike", "pile", "The first N times a neighbour attacks each fight, this hits the target first."],
    "Cousin": ["kin", "mouse", "A 2/2 Mouse with Hand-me-down."],
    "Cleave": ["strike", "cleave", "Also damages a random unit next to its target."],
    "Reserve": ["kin", "reserve", "In a fight, this steps from your hand into a slot a friendly unit died in. Your Guard post first. Up to 2 a fight."],
  });
})();
// card text to marks, with dev's keywords (kit.js's own pattern was built before they existed)
const DEV_KW_RE = new RegExp("\\b(" + Object.keys(KW).sort((a, b) => b.length - a.length).map(s => s.replace(/ /g, "\\s")).join("|") +
  ")(s)?\\b(?:\\s(\\+?\\d+)\\b|\\s\\((\\d+)\\))?", "g");
function marksIn(text) {
  return text.replace(DEV_KW_RE, (m, name, pl, n1, n2) => kwMark(name.replace(/\s/g, " "), n1 || n2, "", name.replace(/\s/g, " ") + (pl || "")));
}
// a card's Charge and Supply from its text ("Charge 2: ...", "Supply 6: ..."), as dev's CardTerms.pips
function pipsOf(text) {
  const out = [], m1 = /\bCharge (\d+):/.exec(text || ""), m2 = /\bSupply (\d+):/.exec(text || "");
  if (m1) out.push({ kind: "charge", total: +m1[1] });
  if (m2) out.push({ kind: "supply", total: +m2[1] });
  return out;
}
// the pips just over the stat discs: round for Charge, square crates for Supply; `spent` of each are dimmed
// (card_pips.gd: side 5% of the card's height, 3 px apart, 3 px over the discs, rows of up to 9)
function cardPips(el, text, h, tier, spent = {}) {
  el.querySelectorAll(".pips").forEach(e => e.remove());
  const groups = pipsOf(text); if (!groups.length) return null;
  const k = h / 1000, r = window.CARD_DATA.roundels["tier" + Math.min(Math.max(tier || 1, 1), 6)].attack;
  let bottom = (r.centre_units[1] - r.radius_units * 1.12) * k - 3;
  const side = Math.max(8, Math.round(h * 0.05)), gap = 3, w = h * 0.56;
  const box = document.createElement("div"); box.className = "pips";
  box.style.cssText = "position:absolute;left:0;top:0;width:100%;height:100%;pointer-events:none;z-index:4";
  for (const g of groups) {
    const rows = Math.ceil(g.total / 9), left = g.total - (spent[g.kind] || 0);
    for (let n = 0; n < g.total; n++) {
      const row = Math.floor(n / 9), inRow = Math.min(9, g.total - row * 9), rw = inRow * side + (inRow - 1) * gap;
      const p = document.createElement("i");
      p.className = "pip " + g.kind + (n >= left ? " spent" : "");
      p.style.cssText = `position:absolute;left:${((w - rw) / 2 + (n % 9) * (side + gap)).toFixed(1)}px;top:${(bottom - side - (rows - 1 - row) * (side + 4)).toFixed(1)}px;` +
        `width:${side}px;height:${side}px;box-sizing:border-box;background:#e2e8ee;border:2px solid #16120e;border-radius:${g.kind === "charge" ? "50%" : Math.round(side * .2) + "px"};` +
        `opacity:${n >= left ? .4 : 1}`;
      box.append(p);
    }
    bottom -= rows * (side + 4);
  }
  el.append(box); return box;
}
// the Renown pill: "Renown N" in a small leaded pill at the top of a slot (dev's glass_slot.gd renown_banner),
// over the unit standing there; in a fight the unit carries it
function renownPill(n, h = 250) {
  const fs = Math.round(h * 0.068);
  const el = document.createElement("div"); el.className = "renown";
  el.innerHTML = `Renown <b>${n}</b>`;
  el.style.cssText = `position:absolute;z-index:9;white-space:nowrap;height:${Math.round(fs * 1.7)}px;padding:0 ${Math.round(fs * .6)}px;border-radius:${fs}px;display:flex;align-items:center;gap:.3em;` +
    `font:700 ${fs}px var(--body,Georgia),serif;color:#16120e;background:url(assets/ui/rd-cream.png) center/150% auto,#efe2bf;border:3px solid #16120e;box-shadow:0 2px 4px rgba(0,0,0,.6);pointer-events:none`;
  return el;
}
