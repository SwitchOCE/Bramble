use crate::{GhostStore, Query, run::Ended};
use bramble_engine::core::util::rng::Rng;
use std::{collections::BTreeSet, ops::RangeInclusive};

#[derive(Clone, Debug, Default)]
pub struct Band {
    pub labels: Vec<String>,
    pub placement: Option<RangeInclusive<i64>>,
}

pub trait Matchmaker {
    /// Return the ids in seat order, for seats 1 through 7.
    fn pick(
        &self,
        store: &dyn GhostStore,
        rules_hash: &str,
        band: &Band,
        exclude: &BTreeSet<String>,
        rng: &mut Rng,
    ) -> Result<[String; 7], String>;
}

#[derive(Clone, Copy, Debug, Default)]
pub struct LocalMatchmaker;

impl Matchmaker for LocalMatchmaker {
    fn pick(
        &self,
        store: &dyn GhostStore,
        rules_hash: &str,
        band: &Band,
        exclude: &BTreeSet<String>,
        rng: &mut Rng,
    ) -> Result<[String; 7], String> {
        let query = Query {
            rules_hash: Some(rules_hash.into()),
            labels: band.labels.clone(),
            placement: band.placement.clone(),
            exclude: exclude.clone(),
            ..Query::default()
        };
        let mut infos = store.find(&query)?;
        // Stable input order for a given seed, independent of the store's index order.
        infos.sort_unstable_by(|a, b| a.id.cmp(&b.id));
        infos.dedup_by(|a, b| a.id == b.id);
        // An unfinished run never fought its last turns; and one record seat is one board.
        let mut seen = BTreeSet::new();
        let mut ids: Vec<String> = infos
            .into_iter()
            .filter(|info| info.ended != Some(Ended::Unfinished))
            .filter(|info| {
                info.record_sha256.is_empty()
                    || seen.insert((info.record_sha256.clone(), info.seat))
            })
            .map(|info| info.id)
            .collect();
        if ids.len() < 7 {
            return Err(format!("need 7 eligible ghost runs, found {}", ids.len()));
        }
        // The first seven steps of Fisher-Yates draw seven ordered seats without replacement.
        for i in 0..7 {
            let j = rng.range_int(i as i64, ids.len() as i64 - 1) as usize;
            ids.swap(i, j);
        }
        Ok(std::array::from_fn(|i| std::mem::take(&mut ids[i])))
    }
}
