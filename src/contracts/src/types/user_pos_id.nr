use dep::aztec::context::{PrivateContext, PublicContext, Context};
use dep::aztec::types::address::AztecAddress;
use dep::std::option::Option;
use dep::aztec::note::{
    utils::compute_note_hash_for_read_or_nullify,
    note_header::NoteHeader,
    note_interface::NoteInterface,
};
use dep::aztec::oracle::get_secret_key::get_secret_key;



struct UserPosId {
    value: u32,
    owner: Field,
    header: NoteHeader
}


global USER_ID_POS_SERIALIZED_LEN: Field = 2;


impl UserPosId {
    pub fn new(value: Field, owner: Field) -> Self {
        Self {
            value: value as u32,
            owner: owner,
            header: NoteHeader::empty()
        }
    }

    pub fn serialize(self: Self) -> [Field; USER_ID_POS_SERIALIZED_LEN] {
        [
            self.value as Field,
            self.owner
        ]
    }

    pub fn deserialize(preimage: [Field; USER_ID_POS_SERIALIZED_LEN]) -> Self {
        UserPosId {
            value: preimage[0] as u32,
            owner: preimage[1],
            header: NoteHeader::empty()
        }
    }

    pub fn compute_note_hash(self) -> Field {
        dep::std::hash::pedersen(self.serialize())[0]
    }

    pub fn compute_nullifier(self) -> Field {
        let note_hash_for_nullify = compute_note_hash_for_read_or_nullify(UserPosIdSerializationMethods, self);
        let secret = get_secret_key(self.owner);
        dep::std::hash::pedersen([
            note_hash_for_nullify,
            secret.low,
            secret.high,
        ])[0]
    }

    pub fn set_header(&mut self, header: NoteHeader) {
        self.header = header;
    }
}

fn deserialize(preimage: [Field; USER_ID_POS_SERIALIZED_LEN]) -> UserPosId {
    UserPosId::deserialize(preimage)
}

fn serialize(note: UserPosId) -> [Field; USER_ID_POS_SERIALIZED_LEN] {
    note.serialize()
}

fn compute_note_hash(note: UserPosId) -> Field {
    note.compute_note_hash()
}

fn compute_nullifier(note: UserPosId) -> Field {
    note.compute_nullifier()
}

fn get_header(note: UserPosId) -> NoteHeader {
    note.header
}

fn set_header(note: &mut UserPosId, header: NoteHeader) {
    note.set_header(header)
}

global UserPosIdSerializationMethods = NoteInterface {
    deserialize,
    serialize,
    compute_note_hash,
    compute_nullifier,
    get_header,
    set_header,
};
