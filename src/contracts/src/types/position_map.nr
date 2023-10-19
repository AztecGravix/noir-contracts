use dep::aztec::context::{PrivateContext, PublicContext, Context};
use dep::aztec::types::address::AztecAddress;
use dep::std::option::Option;
use crate::types::position_set::PositionSet;


struct PositionMap {
    context: Context,
    storage_slot: Field,
}


impl PositionMap {
    pub fn new(
        context: Context,
        storage_slot: Field,
    ) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
            context,
            storage_slot,
        }
    }

    pub fn at(self, owner: AztecAddress) -> PositionSet {
        let derived_storage_slot = self.slot_for(owner);
        PositionSet::new(self.context, owner, derived_storage_slot)
    }

    pub fn slot_for(self, owner: AztecAddress) -> Field {
        dep::std::hash::pedersen([self.storage_slot, owner.address])[0]
    }
}
