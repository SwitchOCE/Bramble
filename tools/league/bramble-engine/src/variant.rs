use indexmap::IndexMap;
use std::{
    cell::{Ref, RefCell, RefMut},
    fmt,
    hash::Hash,
    rc::{Rc, Weak},
};

/// Godot arrays alias their storage on assignment. `duplicate` copies just the container.
pub struct Array<T = Variant>(Rc<RefCell<Vec<T>>>);
impl<T> Clone for Array<T> {
    fn clone(&self) -> Self {
        Self(self.0.clone())
    }
}
impl<T> Default for Array<T> {
    fn default() -> Self {
        Self::new()
    }
}
impl<T> Array<T> {
    pub fn new() -> Self {
        Self(Rc::new(RefCell::new(Vec::new())))
    }
    pub fn borrow(&self) -> Ref<'_, Vec<T>> {
        self.0.borrow()
    }
    pub fn borrow_mut(&self) -> RefMut<'_, Vec<T>> {
        self.0.borrow_mut()
    }
    pub fn len(&self) -> usize {
        self.borrow().len()
    }
    pub fn is_empty(&self) -> bool {
        self.borrow().is_empty()
    }
    pub fn push(&self, value: T) {
        self.borrow_mut().push(value);
    }
    pub fn append(&self, value: T) {
        self.push(value);
    }
    pub fn clear(&self) {
        self.borrow_mut().clear();
    }
}
impl<T: Clone> Array<T> {
    pub fn duplicate(&self) -> Self {
        self.borrow().clone().into()
    }
    pub fn get(&self, index: usize) -> Option<T> {
        self.borrow().get(index).cloned()
    }
    pub fn to_vec(&self) -> Vec<T> {
        self.borrow().clone()
    }
    /// Godot-style index iteration over aliased live storage. No storage borrow
    /// survives a yielded item, so callbacks may mutate the array safely.
    /// For frozen board caches and private batches this visits the same handles
    /// as to_vec(), without allocating a second snapshot.
    pub fn iter_live(&self) -> impl Iterator<Item = T> + use<T> {
        let array = self.clone();
        let mut index = 0;
        std::iter::from_fn(move || {
            let value = array.get(index)?;
            index += 1;
            Some(value)
        })
    }
}
impl<T: PartialEq> Array<T> {
    pub fn has(&self, value: &T) -> bool {
        self.borrow().contains(value)
    }
}
impl<T> From<Vec<T>> for Array<T> {
    fn from(v: Vec<T>) -> Self {
        Self(Rc::new(RefCell::new(v)))
    }
}
impl<T, const N: usize> From<[T; N]> for Array<T> {
    fn from(v: [T; N]) -> Self {
        Vec::from(v).into()
    }
}
impl<T> FromIterator<T> for Array<T> {
    fn from_iter<I: IntoIterator<Item = T>>(i: I) -> Self {
        i.into_iter().collect::<Vec<_>>().into()
    }
}
impl<T: fmt::Debug> fmt::Debug for Array<T> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.borrow().fmt(f)
    }
}
impl<T: PartialEq> PartialEq for Array<T> {
    fn eq(&self, other: &Self) -> bool {
        *self.borrow() == *other.borrow()
    }
}

// IndexMap's ordered entry storage governs iteration and shift_remove; changing
// hash buckets does not change insertion/replacement/removal order.
type StateMap<K, V> = IndexMap<K, V, foldhash::fast::RandomState>;

/// Values first permits `Dictionary<CardHeapRef>`; non-string keys retain their rules type.
pub struct Dictionary<T = Variant, K = String>(Rc<RefCell<StateMap<K, T>>>);
impl<T, K> Clone for Dictionary<T, K> {
    fn clone(&self) -> Self {
        Self(self.0.clone())
    }
}
impl<T, K> Default for Dictionary<T, K> {
    fn default() -> Self {
        Self::new()
    }
}
impl<T, K> Dictionary<T, K> {
    pub fn new() -> Self {
        Self::with_capacity(0)
    }
    pub fn with_capacity(capacity: usize) -> Self {
        Self(Rc::new(RefCell::new(StateMap::with_capacity_and_hasher(
            capacity,
            foldhash::fast::RandomState::default(),
        ))))
    }
    pub fn borrow(&self) -> Ref<'_, StateMap<K, T>> {
        self.0.borrow()
    }
    pub fn borrow_mut(&self) -> RefMut<'_, StateMap<K, T>> {
        self.0.borrow_mut()
    }
    pub fn len(&self) -> usize {
        self.borrow().len()
    }
    pub fn is_empty(&self) -> bool {
        self.borrow().is_empty()
    }
    pub fn clear(&self) {
        self.borrow_mut().clear();
    }
}
impl<T: Clone, K: Clone + Hash + Eq> Dictionary<T, K> {
    pub fn duplicate(&self) -> Self {
        self.borrow().clone().into()
    }
}
impl<T, K: Hash + Eq> From<IndexMap<K, T>> for Dictionary<T, K> {
    fn from(v: IndexMap<K, T>) -> Self {
        v.into_iter().collect()
    }
}
impl<T, K: Hash + Eq> From<StateMap<K, T>> for Dictionary<T, K> {
    fn from(v: StateMap<K, T>) -> Self {
        Self(Rc::new(RefCell::new(v)))
    }
}
impl<T, K: Hash + Eq> FromIterator<(K, T)> for Dictionary<T, K> {
    fn from_iter<I: IntoIterator<Item = (K, T)>>(i: I) -> Self {
        i.into_iter().collect::<StateMap<_, _>>().into()
    }
}
impl<T: fmt::Debug, K: fmt::Debug> fmt::Debug for Dictionary<T, K> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.borrow().fmt(f)
    }
}
impl<T: PartialEq, K: Hash + Eq> PartialEq for Dictionary<T, K> {
    fn eq(&self, other: &Self) -> bool {
        *self.borrow() == *other.borrow()
    }
}
impl Dictionary {
    pub fn get(&self, key: &str) -> Variant {
        self.borrow().get(key).cloned().unwrap_or(Variant::Nil)
    }
    pub fn get_or(&self, key: &str, default: Variant) -> Variant {
        self.borrow().get(key).cloned().unwrap_or(default)
    }
    pub fn has(&self, key: &str) -> bool {
        self.borrow().contains_key(key)
    }
    pub fn insert(&self, key: impl Into<String>, value: Variant) -> Option<Variant> {
        self.borrow_mut().insert(key.into(), value)
    }
    pub fn erase(&self, key: &str) -> Option<Variant> {
        self.borrow_mut().shift_remove(key)
    }
}

#[derive(Clone, Debug, PartialEq, Default)]
pub enum Variant {
    #[default]
    Nil,
    Bool(bool),
    Int(i64),
    Float(f64),
    String(String),
    Array(Array<Variant>),
    Dictionary(Dictionary),
}
impl Variant {
    pub fn array(items: Vec<Variant>) -> Self {
        Self::Array(items.into())
    }
    pub fn dictionary(items: IndexMap<String, Variant>) -> Self {
        Self::Dictionary(items.into())
    }
    /// Copy nested arrays and dictionaries without changing scalar types.
    pub fn duplicate_deep(&self) -> Self {
        match self {
            Self::Array(items) => {
                Self::Array(items.borrow().iter().map(Self::duplicate_deep).collect())
            }
            Self::Dictionary(fields) => Self::Dictionary(
                fields
                    .borrow()
                    .iter()
                    .map(|(key, value)| (key.clone(), value.duplicate_deep()))
                    .collect(),
            ),
            value => value.clone(),
        }
    }
    pub fn as_dict(&self) -> Dictionary {
        if let Self::Dictionary(d) = self {
            d.clone()
        } else {
            Dictionary::new()
        }
    }
    pub fn as_array(&self) -> Array<Variant> {
        if let Self::Array(a) = self {
            a.clone()
        } else {
            Array::new()
        }
    }
    pub fn as_i64(&self) -> i64 {
        crate::core::util::core_util::CoreUtil::to_int(self)
    }
    pub fn as_text(&self) -> String {
        match self {
            Self::String(s) => s.clone(),
            Self::Int(n) => n.to_string(),
            Self::Float(n) => n.to_string(),
            Self::Bool(b) => b.to_string(),
            Self::Nil => "<null>".into(),
            _ => crate::util::godot_json::stringify(self),
        }
    }
}
impl From<&str> for Variant {
    fn from(v: &str) -> Self {
        Self::String(v.to_owned())
    }
}
impl From<String> for Variant {
    fn from(v: String) -> Self {
        Self::String(v)
    }
}
impl From<i64> for Variant {
    fn from(v: i64) -> Self {
        Self::Int(v)
    }
}
impl From<bool> for Variant {
    fn from(v: bool) -> Self {
        Self::Bool(v)
    }
}

pub trait ToState {
    fn to_state(&self) -> Variant;
    /// Equivalent to RecordState.fields, before its special UnitDef/BoundMechanic conversions.
    fn script_state(&self) -> Variant {
        self.to_state()
    }
    /// Apply RecordState's exclusions before conversion when the type supports it.
    /// The fallback preserves special script_state implementations and erase order.
    fn script_state_without(&self, skip: &[&str]) -> Variant {
        let state = self.script_state();
        if let Variant::Dictionary(out) = &state {
            for key in skip {
                out.erase(key);
            }
        }
        state
    }
    fn field_names() -> &'static [&'static str]
    where
        Self: Sized,
    {
        &[]
    }
}
impl ToState for Variant {
    fn to_state(&self) -> Variant {
        match self {
            Self::Float(n) if n.is_finite() && n.floor() == *n => Self::Int(*n as i64),
            Self::Array(a) => a.to_state(),
            Self::Dictionary(d) => d.to_state(),
            _ => self.clone(),
        }
    }
}
impl<T: ToState> ToState for Array<T> {
    fn to_state(&self) -> Variant {
        Variant::array(self.borrow().iter().map(ToState::to_state).collect())
    }
}
impl<T: ToState, K: ToString> ToState for Dictionary<T, K> {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(
            self.borrow()
                .iter()
                .map(|(k, v)| (k.to_string(), v.to_state()))
                .collect(),
        )
    }
}
impl<T: ToState> ToState for Rc<RefCell<T>> {
    fn to_state(&self) -> Variant {
        self.borrow().to_state()
    }
}
impl<T: ToState> ToState for Option<T> {
    fn to_state(&self) -> Variant {
        self.as_ref().map_or(Variant::Nil, ToState::to_state)
    }
}
impl<T> ToState for Weak<RefCell<T>> {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
}
impl ToState for i64 {
    fn to_state(&self) -> Variant {
        Variant::Int(*self)
    }
}
impl ToState for usize {
    fn to_state(&self) -> Variant {
        Variant::Int(*self as i64)
    }
}
impl ToState for bool {
    fn to_state(&self) -> Variant {
        Variant::Bool(*self)
    }
}
impl ToState for f64 {
    fn to_state(&self) -> Variant {
        Variant::Float(*self).to_state()
    }
}
impl ToState for String {
    fn to_state(&self) -> Variant {
        Variant::String(self.clone())
    }
}
impl ToState for str {
    fn to_state(&self) -> Variant {
        Variant::String(self.to_owned())
    }
}
impl<T: ToState> ToState for Vec<T> {
    fn to_state(&self) -> Variant {
        Variant::array(self.iter().map(ToState::to_state).collect())
    }
}
impl<T: ToState, const N: usize> ToState for [T; N] {
    fn to_state(&self) -> Variant {
        Variant::array(self.iter().map(ToState::to_state).collect())
    }
}
impl ToState for (i64, i64) {
    fn to_state(&self) -> Variant {
        Variant::array(vec![self.0.to_state(), self.1.to_state()])
    }
}
impl<T: ToState, K: ToString> ToState for IndexMap<K, T> {
    fn to_state(&self) -> Variant {
        Variant::dictionary(
            self.iter()
                .map(|(k, v)| (k.to_string(), v.to_state()))
                .collect(),
        )
    }
}

#[cfg(test)]
mod dictionary_order_tests {
    use super::*;

    #[test]
    fn fast_hasher_preserves_insert_replace_remove_and_duplicate_order() {
        let original: IndexMap<_, _> = [
            ("z".to_owned(), Variant::Int(1)),
            ("a".to_owned(), Variant::Int(2)),
            ("é".to_owned(), Variant::Int(3)),
        ]
        .into_iter()
        .collect();
        let dictionary: Dictionary = original.into();
        assert_eq!(
            dictionary.insert("a", Variant::Int(4)),
            Some(Variant::Int(2))
        );
        dictionary.insert("last", Variant::Int(5));
        assert_eq!(dictionary.erase("a"), Some(Variant::Int(4)));
        dictionary.insert("a", Variant::Int(6));
        let duplicate = dictionary.duplicate();
        dictionary.erase("é");
        let keys = |dict: &Dictionary| dict.borrow().keys().cloned().collect::<Vec<_>>();
        assert_eq!(keys(&dictionary), vec!["z", "last", "a"]);
        assert_eq!(keys(&duplicate), vec!["z", "é", "last", "a"]);
        assert_eq!(duplicate.get("a"), Variant::Int(6));
        let converted = duplicate.to_state().as_dict();
        assert_eq!(keys(&converted), keys(&duplicate));
        assert_eq!(converted, duplicate);
    }
}

#[cfg(test)]
mod array_live_tests {
    use super::Array;

    #[test]
    fn iterator_owns_storage_and_observes_alias_edits_between_items() {
        let array = Array::from([1, 2, 3]);
        let alias = array.clone();
        let mut items = array.iter_live();
        drop(array);
        assert_eq!(items.next(), Some(1));
        alias.borrow_mut().remove(1);
        alias.push(4);
        assert_eq!(items.next(), Some(3));
        alias.borrow_mut()[2] = 5;
        assert_eq!(items.next(), Some(5));
        assert_eq!(items.next(), None);
    }
}
