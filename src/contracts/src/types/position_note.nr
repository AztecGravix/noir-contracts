use dep::aztec::context::{PrivateContext, PublicContext, Context};
use dep::aztec::types::address::AztecAddress;
use dep::std::option::Option;
use dep::aztec::note::{
    utils::compute_note_hash_for_read_or_nullify,
    note_header::NoteHeader,
    note_interface::NoteInterface,
};
use dep::aztec::oracle::get_secret_key::get_secret_key;
use dep::aztec::hash::{compute_secret_hash};


struct PositionNote {
    id: u32,
    marketIdx: u8,
    posType: u8, // 0 - long, 1 - short
    initialCollateral: u120,
    openFee: u120,
    openPrice: u120, // price after spread apply
    markPrice: u120, // market price on moment of positionNote creation
    leverage: u32,
    borrowBaseRatePerHour: u64, // we store rate on moment of positionNote creation because rate could be changed in market config
    liquidationThresholdRate: u64,
    createdAt: u32,
    owner: Field,

    // this fields will exists only on 'request' phase of positionNote
    // we need it because we need 1 mega-struct because of compute_note_hash_and_nullifier can deserialize only 1 type of notes
    secret_hash: Field,
    secret: Field,

    header: NoteHeader
}

global POSITION_NOTE_SERIALIZED_LEN: Field = 13;
global LIQUIDATION_THRESHOLD_RATE: u64 = 100000000000; // 10%


impl PositionNote {
    pub fn new(
        id: u32,
        marketIdx: u8,
        posType: u8,
        initialCollateral: u120,
        openFee: u120,
        openPrice: u120,
        markPrice: u120,
        leverage: u32,
        borrowBaseRatePerHour: u64,
        liquidationThresholdRate: u64,
        createdAt: u32,
        owner: Field,
        secret_hash: Field
    ) -> Self {
        Self {
            id: id,
            marketIdx: marketIdx,
            posType: posType,
            initialCollateral: initialCollateral,
            openFee: openFee,
            openPrice: openPrice,
            markPrice: markPrice,
            leverage: leverage,
            borrowBaseRatePerHour: borrowBaseRatePerHour,
            liquidationThresholdRate: liquidationThresholdRate,
            createdAt: createdAt,
            owner: owner,
            secret_hash: secret_hash,
            secret: 0,
            header: NoteHeader::empty()
        }
    }

    pub fn serialize(self: Self) -> [Field; POSITION_NOTE_SERIALIZED_LEN] {
        [
            self.id as Field,
            self.marketIdx as Field,
            self.posType as Field,
            self.initialCollateral as Field,
            self.openFee as Field,
            self.openPrice as Field,
            self.markPrice as Field,
            self.leverage as Field,
            self.borrowBaseRatePerHour as Field,
            self.liquidationThresholdRate as Field,
            self.createdAt as Field,
            self.owner,
            self.secret_hash
        ]
    }

    pub fn deserialize(preimage: [Field; POSITION_NOTE_SERIALIZED_LEN]) -> Self {
        PositionNote {
            id: preimage[0] as u32,
            marketIdx: preimage[1] as u8,
            posType: preimage[2] as u8,
            initialCollateral: preimage[3] as u120,
            openFee: preimage[4] as u120,
            openPrice: preimage[5] as u120,
            markPrice: preimage[6] as u120,
            leverage: preimage[7] as u32,
            borrowBaseRatePerHour: preimage[8] as u64,
            liquidationThresholdRate: preimage[9] as u64,
            createdAt: preimage[10] as u32,
            owner: preimage[11],
            secret_hash: preimage[12],
            secret: 0,
            header: NoteHeader::empty()
        }
    }

    pub fn compute_note_hash(self) -> Field {
        dep::std::hash::pedersen(self.serialize())[0]
    }

    pub fn compute_nullifier(self) -> Field {
        let note_hash_for_nullify = compute_note_hash_for_read_or_nullify(PositionNoteSerializationMethods, self);
        let secret = get_secret_key(self.owner);
        dep::std::hash::pedersen([
            note_hash_for_nullify,
            secret.low,
            secret.high,
        ])[0]
    }

    pub fn new_from_secret(
        id: u32,
        marketIdx: u8,
        posType: u8,
        initialCollateral: u120,
        openFee: u120,
        openPrice: u120,
        markPrice: u120,
        leverage: u32,
        borrowBaseRatePerHour: u64,
        liquidationThresholdRate: u64,
        createdAt: u32,
        owner: Field,
        secret: Field
    ) -> Self {
         PositionNote {
            id: id,
            marketIdx: marketIdx,
            posType: posType,
            initialCollateral: initialCollateral,
            openFee: openFee,
            openPrice: openPrice,
            markPrice: markPrice,
            leverage: leverage,
            borrowBaseRatePerHour: borrowBaseRatePerHour,
            liquidationThresholdRate: liquidationThresholdRate,
            createdAt: createdAt,
            owner: owner,
            secret_hash: compute_secret_hash(secret),
            secret: secret,
            header: NoteHeader::empty()
        }
    }

    // note checker
    pub fn knows_secret(self, secret: Field) {
        let hash = compute_secret_hash(secret);
        assert(self.secret_hash == hash);
    }

    pub fn set_header(&mut self, header: NoteHeader) {
        self.header = header;
    }
}

fn deserialize(preimage: [Field; POSITION_NOTE_SERIALIZED_LEN]) -> PositionNote {
    PositionNote::deserialize(preimage)
}

fn serialize(note: PositionNote) -> [Field; POSITION_NOTE_SERIALIZED_LEN] {
    note.serialize()
}

fn compute_note_hash(note: PositionNote) -> Field {
    note.compute_note_hash()
}

fn compute_nullifier(note: PositionNote) -> Field {
    note.compute_nullifier()
}

fn get_header(note: PositionNote) -> NoteHeader {
    note.header
}

fn set_header(note: &mut PositionNote, header: NoteHeader) {
    note.set_header(header)
}

global PositionNoteSerializationMethods = NoteInterface {
    deserialize,
    serialize,
    compute_note_hash,
    compute_nullifier,
    get_header,
    set_header,
};