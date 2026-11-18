//! Mirrors src/core/records/game_record.gd. Record writing belongs to the replay/harness phase.
use crate::{Dictionary,ToState,Variant};
use crate::core::session::game_session::GameSessionRef;
use std::{cell::RefCell,rc::Rc,fs::File};
pub type GameRecordRef=Rc<RefCell<GameRecord>>;
#[derive(Default)]
pub struct GameRecord{pub path:String,pub error:String,pub _file:Option<File>}
impl GameRecord{
    pub const FORMAT:i64=2;
    pub fn begin(_game:&GameSessionRef)->GameRecordRef{todo!("port src/core/records/game_record.gd:begin")}
    pub fn append(&mut self,_entry:&Dictionary){todo!("port src/core/records/game_record.gd:append")}
    pub fn _fail(&mut self,message:&str){self.error=message.into();eprintln!("{message}");}
}
impl ToState for GameRecord{fn to_state(&self)->Variant{crate::state_dict!{"path"=>&self.path,"error"=>&self.error,"_file"=>&self._file}}fn field_names()->&'static [&'static str]{&["path","error","_file"]}}
impl ToState for File{fn to_state(&self)->Variant{crate::state_dict!{}}}
