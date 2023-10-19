use dep::aztec::context::{PrivateContext, PublicContext, Context};
use dep::aztec::types::address::AztecAddress;
use dep::std::option::Option;
use dep::aztec::note::{
    utils::compute_note_hash_for_read_or_nullify,
    note_header::NoteHeader,
    note_interface::NoteInterface,
    utils::compute_siloed_note_hash,
};
use dep::aztec::oracle::get_secret_key::get_secret_key;



struct UserData {
    profit: u120,
    loss: u120,
    owner: Field,
    header: NoteHeader
}


global USER_DATA_SERIALIZED_LEN: Field = 3;


impl UserData {
    pub fn new(owner: Field) -> Self {
        Self {
            profit: 0,
            loss: 0,
            owner: owner,
            header: NoteHeader::empty()
        }
    }

    pub fn serialize(self: Self) -> [Field; USER_DATA_SERIALIZED_LEN] {
        [
            self.profit as Field,
            self.loss as Field,
            self.owner as Field
        ]
    }

    pub fn deserialize(preimage: [Field; USER_DATA_SERIALIZED_LEN]) -> Self {
        UserData {
            profit: preimage[0] as u120,
            loss: preimage[1] as u120,
            owner: preimage[2],
            header: NoteHeader::empty()
        }
    }

    pub fn compute_note_hash(self) -> Field {
        dep::std::hash::pedersen(self.serialize())[0]
    }

    pub fn compute_nullifier(self) -> Field {
        let note_hash_for_nullify = compute_note_hash_for_read_or_nullify(UserDataSerializationMethods, self);
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

fn deserialize(preimage: [Field; USER_DATA_SERIALIZED_LEN]) -> UserData {
    UserData::deserialize(preimage)
}

fn serialize(note: UserData) -> [Field; USER_DATA_SERIALIZED_LEN] {
    note.serialize()
}

fn compute_note_hash(note: UserData) -> Field {
    note.compute_note_hash()
}

fn compute_nullifier(note: UserData) -> Field {
    note.compute_nullifier()
}

fn get_header(note: UserData) -> NoteHeader {
    note.header
}

fn set_header(note: &mut UserData, header: NoteHeader) {
    note.set_header(header)
}

global UserDataSerializationMethods = NoteInterface {
    deserialize,
    serialize,
    compute_note_hash,
    compute_nullifier,
    get_header,
    set_header,
};
