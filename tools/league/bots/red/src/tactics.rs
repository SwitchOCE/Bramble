use league_api::{Action, BotView, UnitView};

/// Choose one late-recruit action from the current legal actions.
pub fn tactic(view: &BotView, value: &dyn Fn(&UnitView) -> f64) -> Option<Action> {
    let me = view.me();
    let board_count = me.board_count();
    let board_full = board_count == 7;
    let has_eater = me.board_units().any(|u| is_gorger(u) || is_glutton(u));
    let is_briar = |u: &UnitView| has_tribe(view, u, "Briar");
    let compost_swap = board_full
        && me.board_units().filter(|u| is_briar(u)).count() >= 3
        && me.hand.iter().any(|u| !u.spell && is_briar(u));

    if !has_eater && board_full && me.hand.iter().any(|u| u.def == "hopper") {
        // hopper_to_hand.gd gives Horde-runner's Hoppers directly to the hand.
        return None;
    }

    if has_eater || compost_swap {
        // legal_actions.gd and recruit.gd permit sales from the board only.
        let weakest = me
            .board_units()
            .map(value)
            .filter(|v| !v.is_nan())
            .min_by(f64::total_cmp);
        let sell = |u: &UnitView| {
            let action = Action::Sell { slot: u.slot };
            view.legal().contains(&action).then_some(action)
        };
        if has_eater {
            let can_replace = board_full || me.hand.iter().any(|u| !u.spell);
            let fodder = me.board_units().filter_map(|u| {
                let sale = sell(u)?;
                let hopper = u.def == "hopper";
                let score = value(u);
                if !hopper && !(can_replace && weakest == Some(score)) {
                    return None;
                }
                let eater = eater_for(view, u, board_count)?;
                (hopper || score < feeding_gain(view, eater, u, value))
                    .then_some((sale, hopper, score))
            });
            if let Some((sale, _, _)) =
                fodder.min_by(|a, b| b.1.cmp(&a.1).then_with(|| a.2.total_cmp(&b.2)))
            {
                return Some(sale);
            }
        }

        // compost.gd adds one entry per bought copy, regardless of the sold unit's tribe.
        if compost_swap
            && let Some(sale) = me
                .board_units()
                .filter(|u| !is_briar(u) && weakest == Some(value(u)))
                .find_map(sell)
        {
            return Some(sale);
        }
    }

    buy_reserve(view)
}

fn is_gorger(unit: &UnitView) -> bool {
    unit.def == "gorger"
}

fn is_glutton(unit: &UnitView) -> bool {
    unit.def == "granary-glutton"
}

fn has_tribe(view: &BotView, unit: &UnitView, tribe: &str) -> bool {
    view.library()
        .get(&unit.def)
        .is_some_and(|card| card.has_tribe(tribe))
}

fn eater_for<'a>(view: &'a BotView, sold: &UnitView, board_count: i64) -> Option<&'a UnitView> {
    let remaining = || view.me().board_units().filter(|u| u.uid != sold.uid);
    // gorge.gd and locust.gd give the first ready Gorger priority across all tribes.
    if let Some(gorger) = remaining().find(|u| {
        is_gorger(u)
            && !u
                .turn_counters
                .iter()
                .any(|(id, n)| id == "locust_ate" && *n != 0)
    }) {
        return Some(gorger);
    }

    // glut.gd has no meal counter on the eater. In this late-recruit sequence, two opened
    // slots are the limit. Skip recruit death effects that could refill them during the sale.
    if board_count < 6
        || !has_tribe(view, sold, "Locust")
        || sold.mechanics.iter().any(|id| {
            matches!(
                id.as_str(),
                "locust_hoppers_on_death" | "locust_brood" | "thorn_pip"
            )
        })
    {
        return None;
    }
    remaining().find(|u| is_glutton(u))
}

// locust.gd transfers own stats. Estimate the change in the eater's value from those stats.
fn feeding_gain(
    view: &BotView,
    eater: &UnitView,
    sold: &UnitView,
    value: &dyn Fn(&UnitView) -> f64,
) -> f64 {
    let Some(card) = view.library().get(&sold.def) else {
        return 0.0;
    };
    let cap = view.library().config("stat_max").unwrap_or(i64::MAX).max(0);
    let gain = |axis, printed: i64| {
        let layer = |kind| sold.snapshot.stat(&format!("{kind}_{axis}"));
        let base = layer("base").unwrap_or(printed.saturating_mul(if sold.golden { 2 } else { 1 }));
        let start = layer("set").filter(|&n| n != -1).unwrap_or(base);
        let own = i128::from(start)
            + i128::from(layer("perm").unwrap_or(0))
            + i128::from(layer("turn").unwrap_or(0))
            + i128::from(layer("combat").unwrap_or(0));
        let multiplier = if eater.golden { 2 } else { 1 };
        (own.clamp(0, i128::from(cap)) as i64).saturating_mul(multiplier)
    };
    let mut fed = eater.clone();
    fed.attack = eater
        .attack
        .saturating_add(gain("attack", card.attack))
        .min(cap);
    fed.health = eater
        .health
        .saturating_add(gain("health", card.health))
        .min(cap);
    value(&fed) - value(eater)
}

fn buy_reserve(view: &BotView) -> Option<Action> {
    let me = view.me();
    let hand_size = me.hand.len();
    // colonel.gd grants hand units Reserve at fight start. reserve.gd and fight_arrivals.gd
    // put them into slots vacated by friendly deaths, in hand order.
    if hand_size as i64 >= me.hand_limit.saturating_sub(1)
        || me.hand.iter().filter(|u| !u.spell).count() >= 4
        || !me.board_units().any(|u| u.def == "the-colonel")
    {
        return None;
    }

    let cheapest = me
        .shop_units
        .iter()
        .zip(&me.unit_prices)
        .filter(|&(id, price)| !id.is_empty() && *price >= 0)
        .map(|(_, &price)| price)
        .min()?;
    if me.gold <= cheapest {
        return None;
    }

    view.legal()
        .iter()
        .filter_map(|action| {
            let Action::Buy {
                spell: false,
                index,
            } = action
            else {
                return None;
            };
            let id = me.shop_units.get(usize::try_from(*index).ok()?)?;
            let card = view.library().get(id)?;
            Some((card.health, action))
        })
        .max_by_key(|(health, _)| *health)
        .map(|(_, action)| action.clone())
}
