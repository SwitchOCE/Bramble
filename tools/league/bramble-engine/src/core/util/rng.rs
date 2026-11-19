//! Bit-for-bit port of `src/core/util/rng.gd`.
use std::{cell::RefCell, rc::Rc};

use crate::{Array, ToState, Variant};

pub type RngRef = Rc<RefCell<Rng>>;

#[derive(Debug, Clone)]
pub struct Rng {
    pub _s: Array<i64>,
}

impl Default for Rng {
    fn default() -> Self {
        Self::new(0)
    }
}

impl Rng {
    pub const MASK: i64 = 0xffff_ffff;
    pub const FNV_OFFSET: i64 = 0x811c_9dc5;
    pub const FNV_PRIME: i64 = 0x0100_0193;

    /// GDScript `_init(seed_value = 0)`.
    pub fn new(seed_value: i64) -> Self {
        let mut state = seed_value & Self::MASK;
        let mut words = vec![0_i64; 4];
        for word in &mut words {
            state = (state + 0x9e37_79b9) & Self::MASK;
            let mut z = state;
            z = Self::mul32(z ^ (z >> 16), 0x85eb_ca6b);
            z = Self::mul32(z ^ (z >> 13), 0xc2b2_ae35);
            *word = z ^ (z >> 16);
        }
        if words.iter().all(|word| *word == 0) {
            words[0] = 1;
        }
        Self {
            _s: Array::from(words),
        }
    }

    /// A stream for one purpose: the same seed and label always give the same numbers.
    pub fn derive(seed_value: i64, label: &str) -> RngRef {
        Rc::new(RefCell::new(Self::new(Self::hash32(&format!(
            "{seed_value}|{label}"
        )))))
    }

    /// FNV-1a over the UTF-8 bytes of `text`.
    pub fn hash32(text: &str) -> i64 {
        let mut h = Self::FNV_OFFSET;
        for byte in text.as_bytes() {
            h = Self::mul32(h ^ i64::from(*byte), Self::FNV_PRIME);
        }
        h
    }

    /// (a * b) mod 2^32 without leaving 48 bits.
    pub fn mul32(a: i64, b: i64) -> i64 {
        let a = a & Self::MASK;
        let b = b & Self::MASK;
        let low = a * (b & 0xffff);
        let high = ((a * (b >> 16)) & 0xffff) << 16;
        (low + high) & Self::MASK
    }

    pub fn _rotl(x: i64, k: i64) -> i64 {
        ((x << k) | (x >> (32 - k))) & Self::MASK
    }

    /// The next 32-bit output, 0 to 2^32 - 1.
    pub fn next_u32(&mut self) -> i64 {
        let mut s = self._s.borrow_mut();
        let result = Self::mul32(Self::_rotl(Self::mul32(s[1], 5), 7), 9);
        let t = (s[1] << 9) & Self::MASK;
        s[2] ^= s[0];
        s[3] ^= s[1];
        s[1] ^= s[2];
        s[0] ^= s[3];
        s[2] ^= t;
        s[3] = Self::_rotl(s[3], 11);
        result
    }

    /// Uniform in [low, high], without modulo bias.
    pub fn range_int(&mut self, low: i64, high: i64) -> i64 {
        if high <= low {
            return low;
        }
        let bound = high.wrapping_sub(low).wrapping_add(1);
        let limit = (Self::MASK + 1) - ((Self::MASK + 1) % bound);
        let mut roll = self.next_u32();
        while roll >= limit {
            roll = self.next_u32();
        }
        low.wrapping_add(roll % bound)
    }

    /// Uniform index into a list of `size` items; -1 for an empty list.
    pub fn index(&mut self, size: i64) -> i64 {
        if size <= 0 {
            return -1;
        }
        self.range_int(0, size - 1)
    }

    /// Fisher-Yates in place. Borrow the live shared container for the whole shuffle.
    pub fn shuffle<T>(&mut self, items: &Array<T>) {
        let mut items = items.borrow_mut();
        self.shuffle_slice(&mut items);
    }

    /// Same algorithm for locally owned work arrays; never use Rust's random shuffle.
    pub fn shuffle_slice<T>(&mut self, items: &mut [T]) {
        for i in (1..items.len()).rev() {
            let j = self.range_int(0, i as i64) as usize;
            items.swap(i, j);
        }
    }
}

impl ToState for Rng {
    fn to_state(&self) -> Variant {
        crate::state_dict! { "_s" => &self._s }
    }
    fn field_names() -> &'static [&'static str] {
        &["_s"]
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{core::util::core_util::CoreUtil, util::godot_json::parse_string};

    #[test]
    fn godot_rng_oracle_30_streams() {
        let oracle = parse_string(include_str!("../../../../gd/util_vectors.json")).as_dict();
        for case in oracle.get("rng").as_array().borrow().iter() {
            let case = case.as_dict();
            let seed = case.get("seed").as_text().parse::<i64>().unwrap();
            let label = case.get("label").as_text();
            let rng = if label == "DIRECT" {
                Rc::new(RefCell::new(Rng::new(seed)))
            } else {
                Rng::derive(seed, &label)
            };
            let ints = |key: &str| -> Vec<i64> {
                case.get(key)
                    .as_array()
                    .borrow()
                    .iter()
                    .map(CoreUtil::to_int)
                    .collect()
            };
            assert_eq!(
                *rng.borrow()._s.borrow(),
                ints("initial"),
                "seed={seed}, label={label}"
            );
            let next: Vec<_> = (0..12).map(|_| rng.borrow_mut().next_u32()).collect();
            assert_eq!(next, ints("next"), "seed={seed}, label={label}");
            let mut ranges: Vec<_> = (0..12)
                .map(|_| rng.borrow_mut().range_int(-13, 27))
                .collect();
            ranges.extend((0..12).map(|_| rng.borrow_mut().range_int(0, 2_147_483_648)));
            assert_eq!(ranges, ints("ranges"), "seed={seed}, label={label}");
            let shuffled: Array<i64> = (0..24).collect();
            rng.borrow_mut().shuffle(&shuffled);
            assert_eq!(
                *shuffled.borrow(),
                ints("shuffle"),
                "seed={seed}, label={label}"
            );
            assert_eq!(
                *rng.borrow()._s.borrow(),
                ints("final"),
                "seed={seed}, label={label}"
            );
        }
    }

    #[test]
    fn degenerate_rng_ranges_do_not_draw() {
        let mut rng = Rng::new(7);
        let before = rng._s.to_vec();
        assert_eq!(rng.range_int(3, 3), 3);
        assert_eq!(rng.range_int(8, -1), 8);
        assert_eq!(rng.index(0), -1);
        assert_eq!(*rng._s.borrow(), before);
    }
}
