//! Hand-written card knowledge: where a unit wants to stand, and a bonus for what its text does
//! beyond its stats. Values are in "points"; a shop tier is worth about 10.

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Pos {
    /// Wants the front row (tanky, Guard, needs to be attacked or to attack first).
    Front,
    /// Wants the back row (support, lenders, Squires, fragile hitters).
    Back,
    /// No strong preference.
    Any,
}

pub struct Know {
    pub pos: Pos,
    /// Value of the text beyond stats, in points.
    pub bonus: f64,
    /// Extra value that grows each turn it is kept (scaling, economy).
    pub scale: f64,
}

const fn k(pos: Pos, bonus: f64, scale: f64) -> Know {
    Know { pos, bonus, scale }
}

pub fn know(id: &str) -> Know {
    use Pos::*;
    match id {
        // ---- Badgers ----
        "brock-cub" => k(Front, 1.0, 0.5),
        "hedge-knight" => k(Front, 2.0, 0.0),
        "sett-shield-bearer" => k(Back, 3.0, 0.5),
        "armsbearer" => k(Back, 4.0, 0.5),
        "relic-seeker" => k(Back, 2.0, 1.0),
        "gate-warden" => k(Front, 4.0, 1.0),
        "grudge-keeper" => k(Front, 3.0, 0.5),
        "hedge-lancer" => k(Front, 3.0, 0.0),
        "sword-heir" => k(Back, 2.0, 0.0),
        "herald-of-the-charge" => k(Back, 4.0, 0.0),
        "greatsword-bearer" => k(Back, 3.0, 0.0),
        "sett-sexton" => k(Back, 1.0, 0.0),
        "master-at-arms" => k(Front, 1.0, 0.0),
        "ironhide-berserker" => k(Front, 3.0, 0.0),
        "dame-of-the-old-sett" => k(Front, 4.0, 0.0),
        "tourney-champion" => k(Front, 3.0, 0.0),
        "the-oakfeller" => k(Front, 4.0, 0.0),
        "old-brock" => k(Front, 3.0, 0.0),
        "marshal-of-the-red-mist" => k(Back, 3.0, 0.0),
        // ---- Locusts ----
        "green-recruit" => k(Front, 2.0, 0.0),
        "husk-sentry" => k(Front, 2.0, 0.0),
        "prophet-of-the-dust" => k(Back, 4.0, 1.5),
        "horde-runner" => k(Back, 3.0, 1.0),
        "wheat-raider" => k(Front, 1.0, 0.0),
        "brood-mother" => k(Front, 4.0, 0.5),
        "skin-shedder" => k(Any, 2.0, 0.0),
        "gleaner" => k(Back, 3.0, 0.0),
        "gorger" => k(Back, 1.0, 0.0),
        "famine-caller" => k(Front, 3.0, 0.5),
        "sky-darkener" => k(Back, 4.0, 0.0),
        "orchard-stripper" => k(Front, 4.0, 0.0),
        "granary-glutton" => k(Back, 2.0, 0.0),
        "war-drummer" => k(Front, 3.0, 0.0),
        "twice-shed-veteran" => k(Back, 2.0, 0.0),
        "the-eighth-plague" => k(Back, 3.0, 0.0),
        "dirge-singer" => k(Back, 5.0, 0.0),
        "swarm-lord" => k(Back, 3.0, 0.5),
        "mother-of-thousands" => k(Back, 4.0, 0.0),
        // ---- Mice ----
        "needle-page" => k(Front, 1.0, 0.0),
        "hedgerow-scout" => k(Front, 2.0, 0.0),
        "harvest-piper" => k(Front, 2.0, 0.0),
        "whetstone-vole" => k(Any, 4.0, 1.5),
        "shrew-cutpurse" => k(Front, 2.0, 0.5),
        "thimble-captain" => k(Front, 3.0, 0.0),
        "needle-pikeman" => k(Front, 3.0, 0.5),
        "toothpick-ballista" => k(Back, 2.0, 0.0),
        "shrew-harrier" => k(Front, 3.0, 0.0),
        "spoon-catapult" => k(Back, 3.0, 0.0),
        "grindstone-miller" => k(Any, 4.0, 1.5),
        "dormouse-cook" => k(Back, 3.0, 1.0),
        "fencing-master" => k(Front, 4.0, 0.5),
        "parish-standard-bearer" => k(Back, 6.0, 0.0),
        "master-of-engines" => k(Back, 3.0, 0.0),
        "edgewright" => k(Back, 4.0, 0.0),
        "king-speck" => k(Front, 4.0, 0.0),
        "dame-bodkin" => k(Front, 4.0, 0.0),
        "kettle-drummer" => k(Back, 4.0, 0.0),
        // ---- Pigeons ----
        "sentry" => k(Any, 3.0, 1.5),
        "territorial" => k(Front, 0.0, 0.0),
        "old-campaigner" => k(Front, 3.0, 1.0),
        "recruiting-sergeant" => k(Back, 2.0, 0.0),
        "lance-corporal" => k(Back, 4.0, 1.5),
        "colour-sergeant" => k(Any, 3.0, 1.0),
        "padre" => k(Back, 2.0, 0.5),
        "flying-ace" => k(Front, 2.0, 0.5),
        "grenadier-guard" => k(Front, 4.0, 1.5),
        "lieutenant" => k(Any, 2.0, 0.0),
        "squadron-leader" => k(Back, 3.0, 0.0),
        "adjutant" => k(Back, 3.0, 1.0),
        "bugler" => k(Back, 3.0, 0.0),
        "colour-ensign" => k(Any, 3.0, 0.0),
        "brigadier" => k(Back, 3.0, 0.0),
        "wing-commander" => k(Front, 3.0, 0.0),
        "regimental-sergeant-major" => k(Back, 6.0, 2.0),
        "the-colonel" => k(Back, 3.0, 0.0),
        "field-marshal" => k(Back, 4.0, 0.0),
        // ---- Briars ----
        "bramble-runner" => k(Front, 0.5, 0.0),
        "nettle-sprout" => k(Front, 1.0, 0.0),
        "hedge-layer" => k(Back, 3.0, 1.0),
        "sweetbriar" => k(Any, 2.0, 0.5),
        "blackthorn-sapling" => k(Front, 2.0, 0.5),
        "blackberry-sprawl" => k(Front, 2.0, 0.0),
        "nettle-skirmisher" => k(Front, 2.0, 0.0),
        "crab-apple" => k(Front, 2.0, 0.0),
        "old-stump" => k(Front, 2.0, 0.0),
        "ivy-climber" => k(Back, 2.0, 0.0),
        "hawthorn-warden" => k(Front, 3.0, 0.0),
        "holly-knight" => k(Back, 2.0, 0.0),
        "leafmould-carter" => k(Back, 5.0, 1.5),
        "lone-hawthorn" => k(Front, 4.0, 0.0),
        "hazel-coppicer" => k(Back, 3.0, 0.5),
        "elder-mother" => k(Back, 4.0, 0.0),
        "briar-king" => k(Back, 3.0, 0.0),
        "mother-midden" => k(Back, 5.0, 1.5),
        "the-old-hedge" => k(Back, 4.0, 0.0),
        // tokens
        "hopper" | "cousin" | "pip" | "private" => k(Front, -2.0, 0.0),
        _ => k(Any, 0.0, 0.0),
    }
}
