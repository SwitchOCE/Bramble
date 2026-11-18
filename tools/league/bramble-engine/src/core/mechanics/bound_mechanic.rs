//! One shared, stateless mechanic plus a unit's parameters (golden already applied).
use std::{cell::RefCell,rc::Rc};
use crate::{ToState,Variant};
use super::{mechanic::Mechanic,mechanic_params::MechanicParamsRef};
#[derive(Clone)]
pub struct BoundMechanic {pub id:String,pub mechanic:Option<Rc<dyn Mechanic>>,pub params:MechanicParamsRef,pub granted:bool}
pub type BoundMechanicRef=Rc<RefCell<BoundMechanic>>;
impl BoundMechanic {
 pub fn new(mechanic_id:&str,script:Option<Rc<dyn Mechanic>>,bound_params:MechanicParamsRef,is_granted:bool)->BoundMechanicRef {
  Rc::new(RefCell::new(Self{id:mechanic_id.to_owned(),mechanic:script,params:bound_params,granted:is_granted}))
 }
 /// Script fields, before RecordState.value's BoundMechanic special case.
 pub fn script_state(&self)->Variant {
  crate::state_dict!{"id"=>&self.id,"mechanic"=>&self.mechanic,"params"=>&self.params,"granted"=>&self.granted}
 }
}
impl ToState for BoundMechanic {
 /// RecordState.value deliberately omits the shared mechanic script.
 fn to_state(&self)->Variant{crate::state_dict!{"id"=>&self.id,"params"=>&self.params,"granted"=>&self.granted}}
 fn script_state(&self)->Variant{BoundMechanic::script_state(self)}
 fn field_names()->&'static [&'static str]{&["id","mechanic","params","granted"]}
}
