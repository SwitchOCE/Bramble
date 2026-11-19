//! Mirrors src/core/records/game_record.gd. Writer settings are outside the rules state.
use super::{record_build::RecordBuild, record_state::RecordState};
use crate::core::session::game_session::{GameSession, GameSessionRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    fs::File,
    io::Write,
    path::{Path, PathBuf},
    rc::Rc,
    sync::{LazyLock, Mutex},
    time::{SystemTime, UNIX_EPOCH},
};

// Source static fields are not script variables and never enter the state hash.
static SETTINGS: LazyLock<Mutex<(PathBuf, PathBuf, u64)>> = LazyLock::new(|| {
    Mutex::new((
        Path::new(env!("CARGO_MANIFEST_DIR"))
            .ancestors()
            .nth(3)
            .expect("repository root")
            .to_owned(),
        std::env::var_os("BRAMBLE_RECORD_DIR")
            .map(PathBuf::from)
            .unwrap_or_else(|| {
                PathBuf::from(std::env::var_os("HOME").unwrap_or_default())
                    .join(".local/share/godot/app_userdata/Bramble/records")
            }),
        0,
    ))
});
pub type GameRecordRef = Rc<RefCell<GameRecord>>;
#[derive(Default)]
pub struct GameRecord {
    pub path: String,
    pub error: String,
    pub _file: Option<File>,
}
impl GameRecord {
    pub const FORMAT: i64 = 4;
    /// Filesystem equivalent of the source's static directory setting; not hashed state.
    pub fn configure(repo_root: &Path, directory: &Path) {
        let mut settings = SETTINGS.lock().expect("record settings");
        settings.0 = repo_root.to_owned();
        settings.1 = directory.to_owned();
    }
    pub fn begin(game: &GameSessionRef) -> GameRecordRef {
        let mut record = Self::default();
        let (repo_root, directory, serial) = {
            let mut settings = SETTINGS.lock().expect("record settings");
            settings.2 += 1;
            settings.clone()
        };
        if let Err(error) = std::fs::create_dir_all(&directory) {
            record._fail(&format!("Cannot create records folder: {error}"));
            return Rc::new(RefCell::new(record));
        }
        // Microseconds + process + serial prevent simultaneous games sharing a file, even at one seed.
        let micros = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock")
            .as_micros();
        record.path = directory
            .join(format!("{micros}-{}-{serial}.jsonl", std::process::id()))
            .to_string_lossy()
            .into_owned();
        match File::create(&record.path) {
            Ok(file) => record._file = Some(file),
            Err(error) => {
                record._fail(&format!("Cannot write game record: {error}"));
                return Rc::new(RefCell::new(record));
            }
        }
        let game = game.borrow();
        let runs = Self::run_entries(&game);
        record.append(
            &crate::state_dict! {
                "op"=>"header", "format"=>&Self::FORMAT, "seed"=>&game.seed_value.to_string(),
                "mode"=>if game.is_async() { "async" } else { "live" }, "runs"=>&runs,
                "build"=>&RecordBuild::identity(&repo_root), "recipe"=>&game.record_recipe,
                "config"=>&RecordState::fields(&*game.config.as_ref().expect("session config").borrow(), &[]),
                "initial_hash"=>&RecordState::state_hash(&game)
            }
            .as_dict(),
        );
        Rc::new(RefCell::new(record))
    }

    pub fn run_entries(game: &GameSession) -> Array<Dictionary> {
        game.run_ids
            .borrow()
            .iter()
            .enumerate()
            .filter(|(_, id)| !id.is_empty())
            .map(|(seat, id)| crate::state_dict! {"seat"=>&(seat as i64),"id"=>id}.as_dict())
            .collect()
    }
    pub fn append(&mut self, entry: &Dictionary) {
        if self._file.is_none() || !self.error.is_empty() {
            return;
        }
        let line = crate::util::godot_json::stringify(&Variant::Dictionary(entry.clone()));
        let file = self._file.as_mut().expect("record file");
        if let Err(error) = writeln!(file, "{line}").and_then(|()| file.flush()) {
            self._fail(&format!("Cannot save game record: {error}"));
        }
    }
    pub fn _fail(&mut self, message: &str) {
        self.error = message.into();
        eprintln!("{message}");
    }
}
impl ToState for GameRecord {
    fn to_state(&self) -> Variant {
        crate::state_dict! {"path"=>&self.path,"error"=>&self.error,"_file"=>&self._file}
    }
    fn field_names() -> &'static [&'static str] {
        &["path", "error", "_file"]
    }
}
impl ToState for File {
    fn to_state(&self) -> Variant {
        crate::state_dict! {}
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::{
        records::record_replay::RecordReplay, rules::game_config::GameConfig,
        session::game_session::GameSession,
    };
    use crate::game::game_content::GameContent;

    #[test]
    fn recorded_round_hashes_before_borrowing_the_writer_and_replays() {
        let root = Path::new(env!("CARGO_MANIFEST_DIR"))
            .ancestors()
            .nth(3)
            .unwrap();
        let directory = root.join(format!(
            ".copies/recruit/writer-test-{}",
            std::process::id()
        ));
        GameRecord::configure(root, &directory);
        let content = GameContent::load_folders(root, &Array::new());
        assert!(content.borrow().errors.is_empty());
        let config = Rc::new(RefCell::new(GameConfig {
            players: 2,
            round_limit: 1,
            ..GameConfig::new()
        }));
        let game = GameSession::create(
            42,
            &content.borrow().library,
            &content.borrow().registry,
            Some(config),
            &Array::new(),
        );
        game.borrow_mut().record_recipe = crate::state_dict!{"kind"=>"game", "paths"=>&Array::<String>::new(), "tribes"=>&Array::<String>::new()}.as_dict();
        GameSession::start_round(&game);
        GameSession::finish_round(&game);
        assert!(game.borrow().over);
        let record = game.borrow().record.as_ref().unwrap().clone();
        assert!(record.borrow().error.is_empty());
        let path = PathBuf::from(&record.borrow().path);
        let replay = RecordReplay::read(root, &path);
        assert!(replay.ok, "{}", replay.message);
        assert!(replay.complete);
        assert_eq!(replay.checkpoints, 3);
        assert_eq!(
            RecordReplay::read_entries(&path)
                .unwrap_or_else(|error| panic!("{}", error.message))
                .len(),
            4
        );
        std::fs::remove_file(path).unwrap();
        let _ = std::fs::remove_dir(directory);
    }
}
