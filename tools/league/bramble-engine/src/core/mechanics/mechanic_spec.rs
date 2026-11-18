//! A card's use of a mechanic: its id and parsed parameters.
use std::{cell::RefCell,rc::Rc};
use crate::{ToState,Variant};
use super::mechanic_params::{MechanicParams,MechanicParamsRef};
#[derive(Clone)]
pub struct MechanicSpec {pub id:String,pub params:MechanicParamsRef}
pub type MechanicSpecRef=Rc<RefCell<MechanicSpec>>;
impl MechanicSpec {
 pub fn new(mechanic_id:&str,parsed:Option<MechanicParamsRef>)->MechanicSpecRef {
  Rc::new(RefCell::new(Self{id:mechanic_id.to_owned(),params:parsed.unwrap_or_else(MechanicParams::new)}))
 }
}
impl Default for MechanicSpec {fn default()->Self{Self{id:String::new(),params:MechanicParams::new()}}}
impl ToState for MechanicSpec {
 fn to_state(&self)->Variant{crate::state_dict!{"id"=>&self.id,"params"=>&self.params}}
 fn field_names()->&'static [&'static str]{&["id","params"]}
}
