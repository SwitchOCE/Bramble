#![allow(unused_variables)]
//! Mirrors src/core/session/matchmaking.gd.
use crate::core::util::rng::RngRef;
use crate::{Array, Dictionary, ToState, Variant};
pub struct Matchmaking;
impl Matchmaking {
    pub const GHOST: i64 = -1;
    pub const AVOID_ROUNDS: i64 = 3;
    // 2.3.1: circle-method round-robin.
    pub fn round_robin(order: &Array<i64>, index: i64) -> Array<Variant> {
        let order = order.borrow();
        let count = order.len();
        let rest = &order[1..];
        let shift = index as usize % rest.len().max(1);
        let mut circle = vec![order[0]];
        circle.extend_from_slice(&rest[rest.len() - shift..]);
        circle.extend_from_slice(&rest[..rest.len() - shift]);
        let pairs = Array::new();
        for i in 0..count / 2 {
            pairs.push(Variant::Array(Self::_pair(
                circle[i],
                circle[count - 1 - i],
            )));
        }
        Self::_sorted(&pairs)
    }
    // 2.3.2: fewest repeated opponents in the past three rounds.
    pub fn avoiding(ids: &Array<i64>, history: &Dictionary, rng: &RngRef) -> Array<Variant> {
        let people = ids.duplicate();
        if people.len() % 2 == 1 {
            people.push(Self::GHOST);
        }
        let all = Array::new();
        Self::_matchings(&people, &Array::new(), &all);
        let mut best = Array::new();
        let mut best_cost = -1;
        for matching in all.to_vec() {
            let pairs = matching.as_array();
            let cost = Self::_repeats(&pairs, history);
            if best_cost < 0 || cost < best_cost {
                best_cost = cost;
                best = Array::from(vec![Variant::Array(pairs)]);
            } else if cost == best_cost {
                best.push(Variant::Array(pairs));
            }
        }
        if best.is_empty() {
            return Array::new();
        }
        let chosen = best
            .get(rng.borrow_mut().index(best.len() as i64) as usize)
            .expect("best matching")
            .as_array();
        Self::_sorted(&chosen)
    }
    pub fn _matchings(people: &Array<i64>, partial: &Array<Variant>, out: &Array<Variant>) {
        if people.is_empty() {
            out.push(Variant::Array(partial.duplicate()));
            return;
        }
        let first = people.get(0).expect("first player");
        for i in 1..people.len() {
            let rest = people.duplicate();
            let other = rest.borrow_mut().remove(i);
            rest.borrow_mut().remove(0);
            partial.push(Variant::Array(Self::_pair(first, other)));
            Self::_matchings(&rest, partial, out);
            partial.borrow_mut().pop();
        }
    }
    pub fn _repeats(pairs: &Array<Variant>, history: &Dictionary) -> i64 {
        let mut cost = 0;
        for value in pairs.to_vec() {
            let pair = value.as_array();
            let a = pair.get(0).expect("pair a").as_i64();
            let b = pair.get(1).expect("pair b").as_i64();
            for who in [a, b] {
                let other = if who == a { b } else { a };
                let past = history.get(&who.to_string()).as_array();
                let start = past.len().saturating_sub(Self::AVOID_ROUNDS as usize);
                if past.borrow()[start..].iter().any(|v| v.as_i64() == other) {
                    cost += 1;
                }
            }
        }
        cost
    }
    pub fn _pair(a: i64, b: i64) -> Array<Variant> {
        if a == Self::GHOST || (b != Self::GHOST && b < a) {
            vec![b.into(), a.into()].into()
        } else {
            vec![a.into(), b.into()].into()
        }
    }
    pub fn _sorted(pairs: &Array<Variant>) -> Array<Variant> {
        let out = pairs.duplicate();
        crate::util::godot_sort::sort_by(&mut out.borrow_mut(), |x, y| {
            Self::_key(&x.as_array()) < Self::_key(&y.as_array())
        });
        out
    }
    pub fn _key(pair: &Array<Variant>) -> i64 {
        pair.borrow()[0].as_i64()
    }
}
impl ToState for Matchmaking {
    fn to_state(&self) -> Variant {
        crate::state_dict! {}
    }
}
