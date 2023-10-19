use dep::std::option::Option;
use dep::aztec::{
  context::Context,
  state_vars::set::Set,
  log::emit_encrypted_log,
  types::address::AztecAddress,
};
use dep::aztec::note::{
    note_getter_options::{NoteGetterOptions}
};
use dep::aztec::oracle::{
    get_public_key::get_public_key,
};
use crate::types::position_note::{PositionNote, PositionNoteSerializationMethods, POSITION_NOTE_SERIALIZED_LEN};


struct PositionSet {
  context: Context,
  owner: AztecAddress,
  set: Set<PositionNote, POSITION_NOTE_SERIALIZED_LEN>
}


impl PositionSet {
  pub fn new(context: Context, owner: AztecAddress, storage_slot: Field) -> Self {
    assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
    let set = Set {
        context,
        storage_slot,
        note_interface: PositionNoteSerializationMethods,
    };
    Self {
        context,
        owner,
        set,
    }
  }

    pub fn add(self: Self, position: &mut PositionNote) {
        self.set.insert(position);

        let context = self.context.private.unwrap();
        let application_contract_address = context.this_address();
        let encryption_pub_key = get_public_key(self.owner.address);
        let encrypted_data = position.serialize();

        emit_encrypted_log(
            context,
            application_contract_address,
            self.set.storage_slot,
            encryption_pub_key,
            encrypted_data,
        );
    }

    pub fn remove(self: Self, position_id: Field) {
        let options = NoteGetterOptions::new().select(0, position_id).set_limit(1);
        let maybe_notes = self.set.get_notes(options);
        if maybe_notes[0].is_some() {
            let note = maybe_notes[0].unwrap_unchecked();
            self.set.remove(note);
        }
    }

    pub fn get_position(self: Self, position_id: Field) -> PositionNote {
        let options = NoteGetterOptions::new().select(0, position_id).set_limit(1);
        let maybe_notes = self.set.get_notes(options);
        maybe_notes[0].unwrap_unchecked()
    }
}
