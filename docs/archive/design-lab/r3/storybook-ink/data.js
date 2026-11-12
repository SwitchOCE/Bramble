// Copied from ../../fixture.json (file:// pages cannot fetch JSON). Regenerated for round 3.
window.FIX = {
  "_note": "Shared mock data for every design-lab direction, so judges compare styles, not content. Units are the mechanics library's example units (docs/design/mechanics-library.md); stats for Belladonna Sprite and Bitter Toad use the budget review's proposed fixes. Look up each keyword's reminder text in the library entry named.",
  "hero_card": {
    "name": "Belladonna Sprite",
    "tier": 6,
    "attack": 4,
    "health": 5,
    "type_line": "Fairy",
    "tribe": "Fairies",
    "text": "Start of Combat: give the enemy with the highest Health Nightshade.",
    "keyword_reminder": "Nightshade: each time this unit is attacked, it first loses half its current Health, rounded down. Lasts this combat.",
    "library_entry": 75,
    "portrait_ink_b": "../../folio/art/web/trials/ink-b-fairy-hollowdeep.jpg"
  },
  "recruit": {
    "turn": 6,
    "gold": 7,
    "tier": 3,
    "tier_up_cost": 6,
    "refresh_cost": 1,
    "frozen": false,
    "shop": [
      {
        "name": "Drumming Woodpecker",
        "tier": 3,
        "attack": 4,
        "health": 4,
        "tribe": "Birds",
        "text": "Peck 2. Whenever this attacks, give your other Birds +1 Attack this combat.",
        "library_entry": 5
      },
      {
        "name": "Hedge Doctor",
        "tier": 3,
        "attack": 2,
        "health": 4,
        "tribe": "Hedgerow folk",
        "text": "Whenever a friendly unit with Curl pricks an enemy, your Hedgerow folk gain +1 Attack this combat.",
        "library_entry": 8
      },
      {
        "name": "Mudwallow Toad",
        "tier": 2,
        "attack": 2,
        "health": 4,
        "tribe": "Bog folk",
        "text": "Mire.",
        "library_entry": 11
      },
      {
        "name": "Garden Snail",
        "tier": 1,
        "attack": 1,
        "health": 3,
        "tribe": "Neutral",
        "text": "Shell 4.",
        "library_entry": 4,
        "frozen": true
      }
    ],
    "board": {
      "front": [
        {
          "slot": "F1",
          "name": "Bear Cub",
          "tier": 2,
          "attack": 2,
          "health": 5,
          "tribe": "Great beasts",
          "text": "Shoulder.",
          "library_entry": 14
        },
        {
          "slot": "F2",
          "name": "Sett Warden",
          "tier": 3,
          "attack": 2,
          "health": 8,
          "tribe": "Hunters",
          "text": "Hunker. Whenever this survives being attacked, your back-row units gain +1 Attack this combat.",
          "library_entry": 1
        },
        {
          "slot": "F3",
          "name": "Lesser Spotted Woodpecker",
          "tier": 1,
          "attack": 2,
          "health": 2,
          "tribe": "Birds",
          "text": "Peck 2.",
          "library_entry": 5
        },
        {
          "slot": "F4",
          "empty": true
        }
      ],
      "back": [
        {
          "slot": "B1",
          "name": "Hornet Scout",
          "tier": 2,
          "attack": 3,
          "health": 2,
          "tribe": "Hive",
          "text": "This attacks an enemy with Nightshade whenever there is one it can attack. When this dies, summon a 1/1 Hornetling with the same text minus the summon.",
          "library_entry": 75
        },
        {
          "slot": "B2",
          "name": "Garden Snail",
          "tier": 1,
          "attack": 2,
          "health": 6,
          "tribe": "Neutral",
          "text": "Shell 8.",
          "golden": true,
          "library_entry": 4
        },
        {
          "slot": "B3",
          "empty": true
        }
      ],
      "_layout": "4-3 brick: the back row is offset by half a slot; B1 sits behind F1 and F2, B2 behind F2 and F3, B3 behind F3 and F4."
    },
    "hand": [
      {
        "name": "Robin Redbreast",
        "tier": 2,
        "attack": 3,
        "health": 2,
        "tribe": "Birds",
        "text": "Rival. If this kills its Rival, it gains +2/+2 permanently.",
        "library_entry": 16
      }
    ],
    "board_count": "5/7",
    "hand_count": "1/10"
  },
  "lobby": [
    {
      "name": "You",
      "health": 31,
      "tier": 3,
      "last": "won"
    },
    {
      "name": "Bramblecrown",
      "health": 38,
      "tier": 4,
      "last": "won"
    },
    {
      "name": "Mossgrave",
      "health": 34,
      "tier": 3,
      "last": "lost"
    },
    {
      "name": "Old Tansy",
      "health": 29,
      "tier": 4,
      "last": "won",
      "next_opponent": true
    },
    {
      "name": "Fernwhistle",
      "health": 24,
      "tier": 2,
      "last": "lost"
    },
    {
      "name": "Hollowmere",
      "health": 19,
      "tier": 3,
      "last": "lost"
    },
    {
      "name": "Quillback",
      "health": 12,
      "tier": 3,
      "last": "won"
    },
    {
      "name": "Sedgewick",
      "health": 0,
      "tier": 2,
      "eliminated": true
    }
  ],
  "combat": {
    "opponent": "Old Tansy",
    "you_attack_first": true,
    "your_board": "the recruit board above, with Belladonna Sprite added in B3",
    "enemy_front": [
      {
        "slot": "F2",
        "name": "Tusker Boar",
        "tier": 5,
        "attack": 40,
        "health": 70,
        "current_health": 26,
        "tribe": "Great beasts",
        "status": [
          "Nightshade"
        ]
      }
    ],
    "enemy_back": [
      {
        "slot": "B1",
        "name": "Feeder Vole",
        "attack": 5,
        "health": 5
      },
      {
        "slot": "B2",
        "name": "Feeder Vole",
        "attack": 5,
        "health": 5
      }
    ],
    "moment": "Attack 2: your Hornetling (1/1, just summoned into B1 after the Hornet Scout there died) is attacking the Nightshaded boar: it halves 26 to 13, then takes 1, leaving 12. Show the attacker, the target, the halving and the damage number, and a combat log line.",
    "_note": "Tusker Boar and Feeder Vole are placeholders from the library's scene, not designed units.",
    "hornetling": {
      "slot": "B1",
      "name": "Hornetling",
      "tier": 2,
      "attack": 1,
      "health": 1,
      "tribe": "Hive",
      "token": true,
      "text": "This attacks an enemy with Nightshade whenever there is one it can attack.",
      "note": "Summoned into B1, the slot of the Hornet Scout that died (rulebook: a dying unit's first summon takes its slot). Back-row units attack in the cycle too."
    }
  }
};
