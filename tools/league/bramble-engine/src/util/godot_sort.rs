//! Godot 4.7.2 SortArray: introsort, then insertion sort (threshold 16).
//!
//! Ported from https://github.com/godotengine/godot/blob/4.7.2-stable/core/templates/sort_array.h
//! Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
//! Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
//!
//! Permission is hereby granted, free of charge, to any person obtaining a copy
//! of this software and associated documentation files (the "Software"), to deal
//! in the Software without restriction, including without limitation the rights
//! to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//! copies of the Software, and to permit persons to whom the Software is
//! furnished to do so, subject to the following conditions:
//!
//! The above copyright notice and this permission notice shall be included in
//! all copies or substantial portions of the Software.
//!
//! THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//! IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//! FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//! AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//! LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//! OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//! THE SOFTWARE.
use std::marker::PhantomData;

pub const INTROSORT_THRESHOLD: i64 = 16;

pub struct SortArray<T, F> {
    pub compare: F,
    _element: PhantomData<T>,
}

impl<T: Clone, F: Fn(&T, &T) -> bool> SortArray<T, F> {
    pub fn new(compare: F) -> Self {
        Self {
            compare,
            _element: PhantomData,
        }
    }

    pub fn median_of_3_index(&self, array: &[T], a: i64, b: i64, c: i64) -> i64 {
        let av = &array[a as usize];
        let bv = &array[b as usize];
        let cv = &array[c as usize];
        if (self.compare)(av, bv) {
            if (self.compare)(bv, cv) {
                b
            } else if (self.compare)(av, cv) {
                c
            } else {
                a
            }
        } else if (self.compare)(av, cv) {
            a
        } else if (self.compare)(bv, cv) {
            c
        } else {
            b
        }
    }

    pub fn bitlog(&self, mut n: i64) -> i64 {
        let mut k = 0;
        while n != 1 {
            k += 1;
            n >>= 1;
        }
        k
    }

    pub fn push_heap(&self, first: i64, mut hole: i64, top: i64, value: T, array: &mut [T]) {
        let mut parent = (hole - 1) / 2;
        while hole > top && (self.compare)(&array[(first + parent) as usize], &value) {
            array[(first + hole) as usize] = array[(first + parent) as usize].clone();
            hole = parent;
            parent = (hole - 1) / 2;
        }
        array[(first + hole) as usize] = value;
    }

    pub fn pop_heap_with_value(
        &self,
        first: i64,
        last: i64,
        result: i64,
        value: T,
        array: &mut [T],
    ) {
        array[result as usize] = array[first as usize].clone();
        self.adjust_heap(first, 0, last - first, value, array);
    }

    pub fn pop_heap(&self, first: i64, last: i64, array: &mut [T]) {
        self.pop_heap_with_value(
            first,
            last - 1,
            last - 1,
            array[(last - 1) as usize].clone(),
            array,
        );
    }

    pub fn adjust_heap(&self, first: i64, mut hole: i64, len: i64, value: T, array: &mut [T]) {
        let top = hole;
        let mut second_child = 2 * hole + 2;
        while second_child < len {
            if (self.compare)(
                &array[(first + second_child) as usize],
                &array[(first + second_child - 1) as usize],
            ) {
                second_child -= 1;
            }
            array[(first + hole) as usize] = array[(first + second_child) as usize].clone();
            hole = second_child;
            second_child = 2 * (second_child + 1);
        }
        if second_child == len {
            array[(first + hole) as usize] = array[(first + second_child - 1) as usize].clone();
            hole = second_child - 1;
        }
        self.push_heap(first, hole, top, value, array);
    }

    pub fn sort_heap(&self, first: i64, mut last: i64, array: &mut [T]) {
        while last - first > 1 {
            self.pop_heap(first, last, array);
            last -= 1;
        }
    }

    pub fn make_heap(&self, first: i64, last: i64, array: &mut [T]) {
        if last - first < 2 {
            return;
        }
        let len = last - first;
        let mut parent = (len - 2) / 2;
        loop {
            self.adjust_heap(
                first,
                parent,
                len,
                array[(first + parent) as usize].clone(),
                array,
            );
            if parent == 0 {
                return;
            }
            parent -= 1;
        }
    }

    pub fn partial_sort(&self, first: i64, last: i64, middle: i64, array: &mut [T]) {
        self.make_heap(first, middle, array);
        for i in middle..last {
            if (self.compare)(&array[i as usize], &array[first as usize]) {
                self.pop_heap_with_value(first, middle, i, array[i as usize].clone(), array);
            }
        }
        self.sort_heap(first, middle, array);
    }

    pub fn partial_select(&self, first: i64, last: i64, middle: i64, array: &mut [T]) {
        self.make_heap(first, middle, array);
        for i in middle..last {
            if (self.compare)(&array[i as usize], &array[first as usize]) {
                self.pop_heap_with_value(first, middle, i, array[i as usize].clone(), array);
            }
        }
    }

    pub fn partitioner(&self, mut first: i64, mut last: i64, pivot: i64, array: &mut [T]) -> i64 {
        let mut pivot_location = pivot;
        loop {
            while first != pivot
                && (self.compare)(&array[first as usize], &array[pivot_location as usize])
            {
                first += 1;
            }
            last -= 1;
            while last != pivot
                && (self.compare)(&array[pivot_location as usize], &array[last as usize])
            {
                last -= 1;
            }
            if first >= last {
                return first;
            }
            if pivot_location == first {
                pivot_location = last;
            } else if pivot_location == last {
                pivot_location = first;
            }
            array.swap(first as usize, last as usize);
            first += 1;
        }
    }

    pub fn introsort(&self, first: i64, mut last: i64, array: &mut [T], mut max_depth: i64) {
        while last - first > INTROSORT_THRESHOLD {
            if max_depth == 0 {
                self.partial_sort(first, last, last, array);
                return;
            }
            max_depth -= 1;
            let pivot = self.median_of_3_index(array, first, first + (last - first) / 2, last - 1);
            let cut = self.partitioner(first, last, pivot, array);
            self.introsort(cut, last, array, max_depth);
            last = cut;
        }
    }

    pub fn introselect(
        &self,
        mut first: i64,
        mut nth: i64,
        mut last: i64,
        array: &mut [T],
        mut max_depth: i64,
    ) {
        while last - first > 3 {
            if max_depth == 0 {
                self.partial_select(first, nth + 1, last, array);
                std::mem::swap(&mut first, &mut nth);
                return;
            }
            max_depth -= 1;
            let pivot = self.median_of_3_index(array, first, first + (last - first) / 2, last - 1);
            let cut = self.partitioner(first, last, pivot, array);
            if cut <= nth {
                first = cut;
            } else {
                last = cut;
            }
        }
        self.insertion_sort(first, last, array);
    }

    pub fn unguarded_linear_insert(&self, mut last: i64, value: T, array: &mut [T]) {
        let mut next = last - 1;
        while (self.compare)(&value, &array[next as usize]) {
            array[last as usize] = array[next as usize].clone();
            last = next;
            next -= 1;
        }
        array[last as usize] = value;
    }

    pub fn linear_insert(&self, first: i64, last: i64, array: &mut [T]) {
        let value = array[last as usize].clone();
        if (self.compare)(&value, &array[first as usize]) {
            for i in ((first + 1)..=last).rev() {
                array[i as usize] = array[(i - 1) as usize].clone();
            }
            array[first as usize] = value;
        } else {
            self.unguarded_linear_insert(last, value, array);
        }
    }

    pub fn insertion_sort(&self, first: i64, last: i64, array: &mut [T]) {
        if first == last {
            return;
        }
        for i in (first + 1)..last {
            self.linear_insert(first, i, array);
        }
    }

    pub fn unguarded_insertion_sort(&self, first: i64, last: i64, array: &mut [T]) {
        for i in first..last {
            self.unguarded_linear_insert(i, array[i as usize].clone(), array);
        }
    }

    pub fn final_insertion_sort(&self, first: i64, last: i64, array: &mut [T]) {
        if last - first > INTROSORT_THRESHOLD {
            self.insertion_sort(first, first + INTROSORT_THRESHOLD, array);
            self.unguarded_insertion_sort(first + INTROSORT_THRESHOLD, last, array);
        } else {
            self.insertion_sort(first, last, array);
        }
    }

    pub fn sort_range(&self, first: i64, last: i64, array: &mut [T]) {
        if first != last {
            self.introsort(first, last, array, self.bitlog(last - first) * 2);
            self.final_insertion_sort(first, last, array);
        }
    }

    pub fn sort(&self, array: &mut [T]) {
        self.sort_range(0, array.len() as i64, array);
    }

    pub fn nth_element(&self, first: i64, last: i64, nth: i64, array: &mut [T]) {
        if first == last || nth == last {
            return;
        }
        self.introselect(first, nth, last, array, self.bitlog(last - first) * 2);
    }
}

pub fn sort_custom<T: Clone>(array: &mut [T], compare: impl Fn(&T, &T) -> bool) {
    SortArray::new(compare).sort(array);
}

/// Engine-facing name for a Godot `sort_custom` comparator (returns less-than).
pub fn sort_by<T: Clone>(array: &mut [T], compare: impl Fn(&T, &T) -> bool) {
    sort_custom(array, compare);
}

pub fn sort<T: Clone + Ord>(array: &mut [T]) {
    sort_custom(array, |a, b| a < b);
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{core::util::core_util::CoreUtil, util::godot_json::parse_string};

    #[test]
    fn godot_tie_order_above_threshold() {
        let oracle = parse_string(include_str!("../../../gd/util_vectors.json"))
            .as_dict()
            .get("sort")
            .as_dict();
        for size in [17_usize, 24, 64, 257] {
            let mut tied: Vec<_> = (0..size).map(|i| (i % 5, i as i64)).collect();
            sort_custom(&mut tied, |a, b| a.0 < b.0);
            let order: Vec<_> = tied.iter().map(|x| x.1).collect();
            let expected: Vec<_> = oracle
                .get(&size.to_string())
                .as_array()
                .borrow()
                .iter()
                .map(CoreUtil::to_int)
                .collect();
            assert_eq!(order, expected, "size={size}");
        }
    }

    #[test]
    fn godot_sort_fallback_heap_and_insertion() {
        for size in [0_usize, 1, 16, 17, 128] {
            let input: Vec<_> = (0..size).rev().map(|i| (i * 17 % 13) as i64).collect();
            let mut expected = input.clone();
            expected.sort_unstable();
            let mut actual = input.clone();
            sort(&mut actual);
            assert_eq!(actual, expected);
            let mut actual = input;
            SortArray::new(|a: &i64, b: &i64| a < b).introsort(0, size as i64, &mut actual, 0);
            SortArray::new(|a: &i64, b: &i64| a < b).final_insertion_sort(
                0,
                size as i64,
                &mut actual,
            );
            assert_eq!(actual, expected);
        }
    }
}
