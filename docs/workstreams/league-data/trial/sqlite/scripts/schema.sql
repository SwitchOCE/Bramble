-- Analysis layer for Bramble match data (SQLite)
CREATE TABLE cards(id TEXT PRIMARY KEY, name TEXT, tier INT, attack INT, health INT, spell INT, token INT) WITHOUT ROWID;
CREATE TABLE card_tribes(card TEXT, tribe TEXT, PRIMARY KEY(card,tribe)) WITHOUT ROWID;
CREATE TABLE games(game INTEGER PRIMARY KEY, seed TEXT, swapped INT, rounds INT, round_limit_hit INT);
CREATE TABLE seats(game INT, seat INT, colour TEXT, bot TEXT, place INT, main_tribe TEXT, commit_round INT,
  died_round INT, refused INT, fault TEXT, panic TEXT, clock_out TEXT, cpu_ms REAL, PRIMARY KEY(game,seat)) WITHOUT ROWID;
-- one row per seat per round it played
CREATE TABLE seat_rounds(game INT, seat INT, round INT, tier INT, board_attack INT, board_health INT, n_units INT,
  gold_start INT, gold_left INT, gold_from_cards INT, triple INT, golden_gained INT, slot_buff INT, lead_tribe TEXT,
  PRIMARY KEY(game,seat,round)) WITHOUT ROWID;
CREATE TABLE seat_round_tribes(game INT, seat INT, round INT, tribe TEXT, n INT, PRIMARY KEY(game,seat,round,tribe)) WITHOUT ROWID;
-- tribe resource counters and heaps (kind = 'counter' | 'heap')
CREATE TABLE seat_round_counters(game INT, seat INT, round INT, kind TEXT, name TEXT, value INT,
  PRIMARY KEY(game,seat,round,kind,name)) WITHOUT ROWID;
-- board units per round (summary form from games.jsonl); round = 0 means final board
CREATE TABLE board_units(game INT, seat INT, round INT, slot INT, card TEXT, golden INT, attack INT, health INT,
  PRIMARY KEY(game,seat,round,slot)) WITHOUT ROWID;
-- every shop view: one row per offered card
CREATE TABLE shops(shop_id INTEGER PRIMARY KEY, game INT, seat INT, round INT, reason TEXT, gold INT, tier INT, strategy TEXT);
CREATE TABLE shop_offers(shop_id INT, spell INT, idx INT, card TEXT, buyable INT, bought INT, value REAL, PRIMARY KEY(shop_id, spell, idx)) WITHOUT ROWID;
-- every chosen bot action (from decisions)
CREATE TABLE actions(game INT, seat INT, round INT, step INT, type TEXT, card TEXT, gold INT, tier INT, board_n INT, hand_n INT,
  PRIMARY KEY(game,seat,round,step)) WITHOUT ROWID;
CREATE TABLE discovers(game INT, seat INT, round INT, n INT, options TEXT, pick INT, card TEXT, PRIMARY KEY(game,seat,round,n)) WITHOUT ROWID;
CREATE TABLE fights(game INT, round INT, fight INT, a INT, b INT, winner INT, loser INT, damage INT, attacks INT, triggers INT,
  reason TEXT, deaths_a INT, deaths_b INT, killed_a INT, killed_b INT, starting_a INT, starting_b INT, ghost_of TEXT,
  PRIMARY KEY(game,round,fight)) WITHOUT ROWID;
CREATE TABLE fight_kills(game INT, round INT, fight INT, side INT, n INT, card TEXT, golden INT, slot INT, origin TEXT, source TEXT, kills INT,
  PRIMARY KEY(game,round,fight,side,n)) WITHOUT ROWID;
CREATE TABLE fight_summons(game INT, round INT, fight INT, side INT, n INT, source TEXT, card TEXT, count INT,
  PRIMARY KEY(game,round,fight,side,n)) WITHOUT ROWID;
-- full refightable board state at fight time, cut from the replay record's fight_boards op (JSON text)
CREATE TABLE fight_snapshots(id INTEGER PRIMARY KEY, game INT, round INT, player INT, snapshot TEXT, UNIQUE(game,round,player));
