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
        todo!("port src/core/session/matchmaking.gd:avoiding")
    }
    pub fn _matchings(people: &Array<i64>, partial: &Array<Variant>, out: &Array<Variant>) {
        todo!("port src/core/session/matchmaking.gd:_matchings")
    }
    pub fn _repeats(pairs: &Array<Variant>, history: &Dictionary) -> i64 {
        todo!("port src/core/session/matchmaking.gd:_repeats")
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
