use crate::{Ended, Run, SourceKind, at, is_hex, sha256};
use serde::{Deserialize, Serialize};
use std::{
    collections::BTreeSet,
    fs::{self, File},
    io::{self, BufRead, BufReader, BufWriter, Write},
    ops::RangeInclusive,
    path::{Path, PathBuf},
    process::{Command, Stdio},
    sync::atomic::{AtomicU64, Ordering},
};

pub trait GhostStore {
    fn add(&self, bytes: &[u8]) -> Result<String, String>;
    fn fetch(&self, id: &str) -> Result<Option<Run>, String>;
    fn find(&self, query: &Query) -> Result<Vec<RunInfo>, String>;
}

#[derive(Clone, Debug, Default)]
pub struct Query {
    pub rules_hash: Option<String>,
    pub kinds: Vec<SourceKind>,
    pub labels: Vec<String>,
    pub placement: Option<RangeInclusive<i64>>,
    pub exclude: BTreeSet<String>,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct RunInfo {
    pub id: String,
    pub rules_hash: String,
    pub kind: SourceKind,
    pub label: String,
    pub placement: i64,
    pub last_turn: usize,
    pub made: String,
    /// The source record and seat. One record seat is one run, whatever `made` says.
    #[serde(default)]
    pub record_sha256: String,
    #[serde(default)]
    pub seat: i64,
    #[serde(default)]
    pub ended: Option<Ended>,
}

impl Query {
    fn matches(&self, info: &RunInfo) -> bool {
        self.rules_hash
            .as_ref()
            .is_none_or(|hash| *hash == info.rules_hash)
            && (self.kinds.is_empty() || self.kinds.contains(&info.kind))
            && (self.labels.is_empty() || self.labels.contains(&info.label))
            && self
                .placement
                .as_ref()
                .is_none_or(|range| range.contains(&info.placement))
            && !self.exclude.contains(&info.id)
    }
}

impl RunInfo {
    fn from_run(id: String, run: Run) -> Self {
        Self {
            id,
            rules_hash: run.rules_hash().to_owned(),
            kind: run.source.kind,
            label: run.source.label,
            placement: run.placement,
            last_turn: run.last_turn,
            made: run.made,
            record_sha256: run.source.record_sha256,
            seat: run.source.seat,
            ended: Some(run.ended),
        }
    }
}

#[derive(Clone, Debug)]
pub struct FolderStore {
    root: PathBuf,
}

impl FolderStore {
    pub fn new(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    /// Hash and parse every run on disk, independently of the index.
    pub fn verify(&self) -> Result<usize, String> {
        Ok(self.scan()?.len())
    }

    /// Verify an exported run against the id in its filename.
    pub fn verify_file(path: &Path) -> Result<Run, String> {
        let id = file_id(path)?;
        let bytes = at(path, fs::read(path))?;
        at(path, Run::verify_bytes(id, &bytes))
    }

    pub fn rebuild_index(&self) -> Result<usize, String> {
        let _lock = self.write_lock()?;
        self.rebuild_locked()
    }

    /// Archive the exact source bytes under their SHA-256, using the same gzip tool as league.
    pub fn archive_record(&self, bytes: &[u8]) -> Result<String, String> {
        let id = sha256(bytes);
        let path = self.root.join("records").join(format!("{id}.jsonl.gz"));
        let _lock = self.write_lock()?;
        if !path.is_file() {
            write_temp(
                &path,
                |from, to| fs::hard_link(from, to),
                |file| {
                    let mut gzip = Command::new("gzip")
                        .args(["-n", "-c"])
                        .stdin(Stdio::piped())
                        .stdout(file)
                        .spawn()
                        .map_err(|e| format!("cannot start gzip: {e}"))?;
                    let written = gzip
                        .stdin
                        .take()
                        .expect("piped gzip input")
                        .write_all(bytes);
                    let status = at(&path, gzip.wait())?;
                    if !status.success() {
                        return Err(format!("{}: gzip exited with {status}", path.display()));
                    }
                    at(&path, written)
                },
            )?;
        }
        Ok(id)
    }

    fn run_path(&self, id: &str) -> Result<PathBuf, String> {
        if !is_hex(id, 64) {
            return Err(format!("invalid run id {id:?}"));
        }
        Ok(self
            .root
            .join("runs")
            .join(&id[..2])
            .join(format!("{id}.json")))
    }

    fn index_path(&self) -> PathBuf {
        self.root.join("index.jsonl")
    }

    fn lock_path(&self) -> PathBuf {
        self.root.join(".index.lock")
    }

    fn write_lock(&self) -> Result<File, String> {
        at(&self.root, fs::create_dir_all(&self.root))?;
        let path = self.lock_path();
        let file = at(
            &path,
            File::options()
                .read(true)
                .write(true)
                .create(true)
                .truncate(false)
                .open(&path),
        )?;
        at(&path, file.lock())?;
        Ok(file)
    }

    fn scan(&self) -> Result<Vec<RunInfo>, String> {
        at(&self.root, fs::metadata(&self.root))?;
        let mut infos = Vec::new();
        for shard in directory(&self.root.join("runs"))? {
            if !shard.is_dir() {
                continue;
            }
            for path in directory(&shard)? {
                if path.extension().is_none_or(|ext| ext != "json") {
                    continue;
                }
                let id = file_id(&path)?;
                if path != self.run_path(id)? {
                    return Err(format!("{}: run is in the wrong shard", path.display()));
                }
                infos.push(RunInfo::from_run(id.into(), Self::verify_file(&path)?));
            }
        }
        infos.sort_unstable_by(|a, b| a.id.cmp(&b.id));
        Ok(infos)
    }

    fn rebuild_locked(&self) -> Result<usize, String> {
        let infos = self.scan()?;
        let path = self.index_path();
        write_temp(
            &path,
            |from, to| fs::rename(from, to),
            |file| {
                let mut writer = BufWriter::new(file);
                for info in &infos {
                    let line = info_line(&path, info)?;
                    at(&path, writer.write_all(&line))?;
                }
                at(&path, writer.flush())
            },
        )?;
        Ok(infos.len())
    }

    fn read_index(&self, file: File) -> Result<Vec<RunInfo>, String> {
        let path = self.index_path();
        BufReader::new(file)
            .lines()
            .enumerate()
            .map(|(i, line)| {
                let line = at(&path, line)?;
                serde_json::from_str(&line).map_err(|e| {
                    format!(
                        "{}:{}: {e}; rebuild with ghost index",
                        path.display(),
                        i + 1
                    )
                })
            })
            .collect()
    }
}

impl GhostStore for FolderStore {
    fn add(&self, bytes: &[u8]) -> Result<String, String> {
        let run = Run::from_bytes(bytes)?;
        let id = sha256(bytes);
        let path = self.run_path(&id)?;
        let index = self.index_path();
        let _lock = self.write_lock()?;
        if !index.is_file() {
            self.rebuild_locked()?;
        }

        // The same record seat cut again (say with another `made`) would be a second id for one
        // board, and could fill two seats of a lobby. Return the run already stored.
        let mut indexed = self.read_index(at(&index, File::open(&index))?)?;
        if indexed.iter().any(|info| info.record_sha256.is_empty()) {
            // An index written before these fields existed: rebuild it from the files.
            self.rebuild_locked()?;
            indexed = self.read_index(at(&index, File::open(&index))?)?;
        }
        if let Some(existing) = indexed.iter().find(|info| {
            info.id != id
                && info.record_sha256 == run.source.record_sha256
                && info.seat == run.source.seat
        }) {
            return Ok(existing.id.clone());
        }

        if self.fetch(&id)?.is_some() {
            // An earlier add can have published the immutable file before updating the cache.
            let indexed = self.read_index(at(&index, File::open(&index))?);
            if !indexed.is_ok_and(|infos| infos.iter().any(|info| info.id == id)) {
                self.rebuild_locked()?;
            }
            return Ok(id);
        }

        write_temp(
            &path,
            |from, to| fs::hard_link(from, to),
            |mut file| at(&path, file.write_all(bytes)),
        )?;
        let line = info_line(&index, &RunInfo::from_run(id.clone(), run))?;
        let mut file = at(&index, File::options().append(true).open(&index))?;
        let previous_len = at(&index, file.metadata())?.len();
        if let Err(error) = file.write_all(&line) {
            at(&index, file.set_len(previous_len))?;
            return at(&index, Err(error));
        }
        Ok(id)
    }

    fn fetch(&self, id: &str) -> Result<Option<Run>, String> {
        let path = self.run_path(id)?;
        let bytes = match fs::read(&path) {
            Err(e) if e.kind() == io::ErrorKind::NotFound => return Ok(None),
            result => at(&path, result)?,
        };
        at(&path, Run::verify_bytes(id, &bytes)).map(Some)
    }

    fn find(&self, query: &Query) -> Result<Vec<RunInfo>, String> {
        let lock_path = self.lock_path();
        let lock = open_optional(&lock_path)?;
        if let Some(lock) = &lock {
            at(&lock_path, lock.lock_shared())?;
        }
        let infos = match open_optional(&self.index_path())? {
            Some(file) => self.read_index(file)?,
            None => self.scan()?,
        };
        Ok(infos
            .into_iter()
            .filter(|info| query.matches(info))
            .collect())
    }
}

fn file_id(path: &Path) -> Result<&str, String> {
    path.file_name()
        .and_then(|name| name.to_str())
        .and_then(|name| name.strip_suffix(".json"))
        .filter(|id| is_hex(id, 64))
        .ok_or_else(|| format!("{}: expected a SHA-256 run filename", path.display()))
}

fn open_optional(path: &Path) -> Result<Option<File>, String> {
    match File::open(path) {
        Err(e) if e.kind() == io::ErrorKind::NotFound => Ok(None),
        result => at(path, result).map(Some),
    }
}

fn directory(path: &Path) -> Result<Vec<PathBuf>, String> {
    let entries = match fs::read_dir(path) {
        Err(e) if e.kind() == io::ErrorKind::NotFound => return Ok(Vec::new()),
        result => at(path, result)?,
    };
    entries
        .map(|entry| at(path, entry.map(|entry| entry.path())))
        .collect()
}

fn info_line(path: &Path, info: &RunInfo) -> Result<Vec<u8>, String> {
    let mut line = at(path, serde_json::to_vec(info))?;
    line.push(b'\n');
    Ok(line)
}

/// Publish a complete file from the same directory. A hard link installs a run without replacing it.
fn write_temp(
    path: &Path,
    publish: impl FnOnce(&Path, &Path) -> io::Result<()>,
    write: impl FnOnce(File) -> Result<(), String>,
) -> Result<(), String> {
    static NEXT: AtomicU64 = AtomicU64::new(0);
    let dir = path.parent().expect("store file has a parent");
    at(dir, fs::create_dir_all(dir))?;
    let (temp, file) = loop {
        let temp = dir.join(format!(
            ".ghost-{}-{}.tmp",
            std::process::id(),
            NEXT.fetch_add(1, Ordering::Relaxed)
        ));
        match File::create_new(&temp) {
            Err(e) if e.kind() == io::ErrorKind::AlreadyExists => continue,
            result => break (temp.clone(), at(&temp, result)?),
        }
    };
    let result = write(file).and_then(|()| at(path, publish(&temp, path)));
    match fs::remove_file(&temp) {
        Err(e) if e.kind() != io::ErrorKind::NotFound && result.is_ok() => at(&temp, Err(e)),
        _ => result,
    }
}
