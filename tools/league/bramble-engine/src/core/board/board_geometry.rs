#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/board/board_geometry.gd`; gameplay TODO bodies belong to the later port workers.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

// GDScript rule and contract comments:
// Rulebook chapter 8 as instance data (prototype lesson: geometry as instance data, so a
// modifier can change the board's shape in one place). Slots are ints in reading order (1.2.3):
// the front row first, then the back row; for the 4-3 board 0 = F1 ... 3 = F4, 4 = B1 ... 6 = B3.
// The tables are built from each slot's row and x position (8.1.3), so they hold for any row
// sizes where the back row sits between front slots. Cards and the engine ask this module; they
// never do slot arithmetic.
// The working board: 4 front, 3 back (8.1.1-8.1.2), or other row sizes.
// 8.4.2: same row first, then the other row; nearest by x, a tie goes to the right.
// 8.2.7 the slots of this slot's row, in reading order.
// 8.2.2 next to each other in the same row.
// 8.2.1 the front slots a back slot sits between.
// 8.2.1 the back slots touching a front slot.
// 8.2.3 adjacent plus in front of and behind, in reading order.
// 8.2.6 the enemy slot with the same label.
// 8.4.2 the order empty slots are tried for a summon from `slot`.
// 8.4.1-8.4.5: where a summon goes. `occupied[i]` says whether slot i is taken. `source_slot`
// is -1 for a source with no slot (8.4.3). `own_slot_first` is for a dying unit's own death
// or return effect (8.4.1). Returns -1 when the board is full (8.4.5).
pub type BoardGeometryRef = Rc<RefCell<BoardGeometry>>;
pub struct BoardGeometry {
    pub slot_count: i64,
    pub labels: Array<String>,
    pub front: Array<i64>,
    pub back: Array<i64>,
    pub _x: Array<f64>,
    pub _adjacent: Array<Array<i64>>,
    pub _in_front: Array<Array<i64>>,
    pub _behind: Array<Array<i64>>,
    pub _summon_order: Array<Array<i64>>,
}
impl Default for BoardGeometry {
    fn default() -> Self {
        Self {
            slot_count: 0,
            labels: Array::new(),
            front: Array::new(),
            back: Array::new(),
            _x: Array::new(),
            _adjacent: Array::new(),
            _in_front: Array::new(),
            _behind: Array::new(),
            _summon_order: Array::new(),
        }
    }
}
impl ToState for BoardGeometry {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "slot_count" => &self.slot_count,
            "labels" => &self.labels,
            "front" => &self.front,
            "back" => &self.back,
            "_x" => &self._x,
            "_adjacent" => &self._adjacent,
            "_in_front" => &self._in_front,
            "_behind" => &self._behind,
            "_summon_order" => &self._summon_order,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "slot_count",
            "labels",
            "front",
            "back",
            "_x",
            "_adjacent",
            "_in_front",
            "_behind",
            "_summon_order",
        ]
    }
}
impl BoardGeometry {
    pub fn standard(front_count: i64, back_count: i64) -> BoardGeometryRef {
        let mut geometry = Self::default();
        geometry._build(front_count, back_count);
        Rc::new(RefCell::new(geometry))
    }
    pub fn _build(&mut self, front_count: i64, back_count: i64) {
        self.slot_count = front_count + back_count;
        for i in 0..front_count {
            self.front.push(i);
            self.labels.push(format!("F{}", i + 1));
            self._x.push(i as f64);
        }
        for i in 0..back_count {
            self.back.push(front_count + i);
            self.labels.push(format!("B{}", i + 1));
            self._x.push(i as f64 + 0.5);
        }
        for slot in 0..self.slot_count {
            self._adjacent.push(self._same_row_within(slot, 1.0));
            self._in_front.push(if self.is_back(slot) {
                self._other_row_within(slot, 0.5)
            } else {
                Array::new()
            });
            self._behind.push(if self.is_front(slot) {
                self._other_row_within(slot, 0.5)
            } else {
                Array::new()
            });
            self._summon_order.push(self._nearest_order(slot));
        }
    }
    pub fn _same_row_within(&self, slot: i64, distance: f64) -> Array<i64> {
        self.row_of(slot)
            .borrow()
            .iter()
            .copied()
            .filter(|other| {
                *other != slot && (self.x_of(*other) - self.x_of(slot)).abs() <= distance
            })
            .collect()
    }
    pub fn _other_row_within(&self, slot: i64, distance: f64) -> Array<i64> {
        let row = if self.is_front(slot) {
            &self.back
        } else {
            &self.front
        };
        row.borrow()
            .iter()
            .copied()
            .filter(|other| (self.x_of(*other) - self.x_of(slot)).abs() <= distance)
            .collect()
    }
    pub fn _nearest_order(&self, slot: i64) -> Array<i64> {
        let out = Array::new();
        for row in [
            self.row_of(slot),
            if self.is_front(slot) {
                self.back.clone()
            } else {
                self.front.clone()
            },
        ] {
            let mut others: Vec<i64> = row
                .borrow()
                .iter()
                .copied()
                .filter(|other| *other != slot)
                .collect();
            let origin = self.x_of(slot);
            crate::util::godot_sort::sort_custom(&mut others, |a, b| {
                let da = (self.x_of(*a) - origin).abs();
                let db = (self.x_of(*b) - origin).abs();
                if da != db {
                    da < db
                } else {
                    self.x_of(*a) > self.x_of(*b)
                }
            });
            out.borrow_mut().extend(others);
        }
        out
    }
    pub fn is_valid(&self, slot: i64) -> bool {
        slot >= 0 && slot < self.slot_count
    }
    pub fn is_front(&self, slot: i64) -> bool {
        self.front.borrow().contains(&slot)
    }
    pub fn is_back(&self, slot: i64) -> bool {
        self.back.borrow().contains(&slot)
    }
    pub fn label(&self, slot: i64) -> String {
        if self.is_valid(slot) {
            self.labels.borrow()[slot as usize].clone()
        } else {
            "-".to_string()
        }
    }
    pub fn x_of(&self, slot: i64) -> f64 {
        self._x.borrow()[slot as usize]
    }
    pub fn row_of(&self, slot: i64) -> Array<i64> {
        if self.is_front(slot) {
            self.front.clone()
        } else {
            self.back.clone()
        }
    }
    pub fn adjacent(&self, slot: i64) -> Array<i64> {
        self._adjacent.borrow()[slot as usize].duplicate()
    }
    pub fn in_front_of(&self, slot: i64) -> Array<i64> {
        self._in_front.borrow()[slot as usize].duplicate()
    }
    pub fn behind(&self, slot: i64) -> Array<i64> {
        self._behind.borrow()[slot as usize].duplicate()
    }
    pub fn neighbours(&self, slot: i64) -> Array<i64> {
        let out = self.adjacent(slot);
        out.borrow_mut()
            .extend(self.in_front_of(slot).borrow().iter().copied());
        out.borrow_mut()
            .extend(self.behind(slot).borrow().iter().copied());
        crate::util::godot_sort::sort(&mut out.borrow_mut());
        out
    }
    pub fn across(&self, slot: i64) -> i64 {
        slot
    }
    pub fn summon_order(&self, slot: i64) -> Array<i64> {
        self._summon_order.borrow()[slot as usize].duplicate()
    }
    pub fn summon_slot(
        &self,
        occupied: &Array<bool>,
        source_slot: i64,
        own_slot_first: bool,
    ) -> i64 {
        let occupied = occupied.borrow();
        if !self.is_valid(source_slot) {
            for slot in 0..self.slot_count {
                if !occupied[slot as usize] {
                    return slot;
                }
            }
            return -1;
        }
        if own_slot_first && !occupied[source_slot as usize] {
            return source_slot;
        }
        for slot in self._summon_order.borrow()[source_slot as usize]
            .borrow()
            .iter()
        {
            if !occupied[*slot as usize] {
                return *slot;
            }
        }
        -1
    }
    pub fn new() -> Self {
        Self::default()
    }
}
