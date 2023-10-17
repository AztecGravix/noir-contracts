// docs:start:token_types_all
use dep::std::hash::pedersen;
use dep::aztec::note::{
    note_header::NoteHeader,
    note_interface::NoteInterface,
    utils::compute_siloed_note_hash,
};
use dep::aztec::hash::{compute_secret_hash};

global TRANSPARENT_NOTE_LEN: Field = 10;


struct TransparentNote {
    collateral: Field,
    leverage: Field,
    posType: Field,
    marketId: Field,
    marketPrice: Field,
    openPrice: Field,
    openFee: Field,
    borrowBaseRatePerHour: Field,
    createdAt: Field,
    secret_hash: Field,
    secret: Field,
    header: NoteHeader,
}

impl TransparentNote {
    pub fn new(
        collateral: Field,
        leverage: Field,
        posType: Field,
        marketId: Field,
        marketPrice: Field,
        openPrice: Field,
        openFee: Field,
        borrowBaseRatePerHour: Field,
        createdAt: Field,
        secret_hash: Field
    ) -> Self {
        TransparentNote {
            collateral: collateral,
            leverage: leverage,
            posType: posType,
            marketId: marketId,
            marketPrice: marketPrice,
            openPrice: openPrice,
            openFee: openFee,
            borrowBaseRatePerHour: borrowBaseRatePerHour,
            createdAt: createdAt,
            secret_hash: secret_hash,
            secret: 0,
            header: NoteHeader::empty(),
        }
    }

    // new oracle call primitive
    // get me the secret corresponding to this hash
    // pub fn new_from_secret(amount: Field, secret: Field) -> Self {
    //     TransparentNote {
    //         amount: amount,
    //         secret_hash: compute_secret_hash(secret),
    //         secret: secret,
    //         header: NoteHeader::empty(),
    //     }
    // }


    // STANDARD NOTE_INTERFACE FUNCTIONS

    pub fn serialize(self) -> [Field; TRANSPARENT_NOTE_LEN] {
        [
            self.collateral,
            self.leverage,
            self.posType,
            self.marketId,
            self.marketPrice,
            self.openPrice,
            self.openFee,
            self.borrowBaseRatePerHour,
            self.createdAt,
            self.secret_hash
        ]
    }

    pub fn deserialize(preimage: [Field; TRANSPARENT_NOTE_LEN]) -> Self {
        TransparentNote {
            collateral: preimage[0],
            leverage: preimage[1],
            posType: preimage[2],
            marketId: preimage[3],
            marketPrice: preimage[4],
            openPrice: preimage[5],
            openFee: preimage[6],
            borrowBaseRatePerHour: preimage[7],
            createdAt: preimage[8],
            secret_hash: preimage[9],
            secret: 0,
            header: NoteHeader::empty(),
        }
    }

    pub fn compute_note_hash(self) -> Field {
        // TODO(#1205) Should use a non-zero generator index.
        dep::std::hash::pedersen(self.serialize())[0]
    }

    pub fn compute_nullifier(self) -> Field {
        // TODO(#1386): should use `compute_note_hash_for_read_or_nullify` once public functions inject nonce!
        let siloed_note_hash = compute_siloed_note_hash(TransparentNoteMethods, self);
        // TODO(#1205) Should use a non-zero generator index.
        pedersen([self.secret, siloed_note_hash])[0]
    }

    pub fn set_header(&mut self, header: NoteHeader) {
        self.header = header;
    }


    // CUSTOM FUNCTIONS FOR THIS NOTE TYPE

    pub fn knows_secret(self, secret: Field) {
        let hash = compute_secret_hash(secret);
        assert(self.secret_hash == hash);
    }
}

fn deserialize(preimage: [Field; TRANSPARENT_NOTE_LEN]) -> TransparentNote {
    TransparentNote::deserialize(preimage)
}

fn serialize(note: TransparentNote) -> [Field; TRANSPARENT_NOTE_LEN] {
    note.serialize()
}

fn compute_note_hash(note: TransparentNote) -> Field {
    note.compute_note_hash()
}

fn compute_nullifier(note: TransparentNote) -> Field {
    note.compute_nullifier()
}

fn get_header(note: TransparentNote) -> NoteHeader {
    note.header
}

fn set_header(note: &mut TransparentNote, header: NoteHeader) {
    note.set_header(header)
}

global TransparentNoteMethods = NoteInterface {
    deserialize,
    serialize,
    compute_note_hash,
    compute_nullifier,
    get_header,
    set_header,
};
// docs:end:token_types_all