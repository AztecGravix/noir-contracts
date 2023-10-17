mod types;



contract Vault {
    use dep::std::option::Option;
    use dep::safe_math::SafeU120;

    use dep::value_note::{
        balance_utils,
        utils::{increment, decrement},
        value_note::{VALUE_NOTE_LEN, ValueNote, ValueNoteMethods},
    };
    
    use dep::aztec::{
        abi,
        log::emit_encrypted_log,
        context::{PrivateContext, PublicContext, Context},
        oracle::{
            get_public_key::get_public_key,
        },
        note::{
            note_getter_options::NoteGetterOptions,
            note_header::NoteHeader,
            utils as note_utils
        },
        state_vars::{map::Map, public_state::PublicState, singleton::Singleton, set::Set},
        types::type_serialization::{
            aztec_address_serialization::{AztecAddressSerializationMethods, AZTEC_ADDRESS_SERIALIZED_LEN},
        },
        hash::{compute_secret_hash},
        types::address::{AztecAddress},
        selector::compute_selector,
    };
    use crate::types::{
        market::{MARKET_SERIALIZED_LEN, Market, MarketSerializationMethods, HUNDRED_PERCENT},
        user_pos_id::{USER_ID_POS_SERIALIZED_LEN, UserPosId, UserPosIdSerializationMethods},
        position::{POSITION_SERIALIZED_LEN, PositionSerializationMethods, Position, LIQUIDATION_THRESHOLD_RATE},
        safe_u120_serialization::{SAFE_U120_SERIALIZED_LEN, SafeU120SerializationMethods},
        transparent_note::{TransparentNote, TRANSPARENT_NOTE_LEN, TransparentNoteMethods}
    };

    struct Storage {
        admin: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
        markets: Map<PublicState<Market, MARKET_SERIALIZED_LEN>>,
        liquidity: PublicState<SafeU120, SAFE_U120_SERIALIZED_LEN>,
        positions: Map<Map<Singleton<Position, POSITION_SERIALIZED_LEN>>>,
        usersLastPosId: Map<Singleton<UserPosId, USER_ID_POS_SERIALIZED_LEN>>,
        pendingRequests: Set<TransparentNote, TRANSPARENT_NOTE_LEN>
    }

    impl Storage {
        fn init(context: Context) -> pub Self {
            Storage {
                admin: PublicState::new(
                    context,
                    1,
                    AztecAddressSerializationMethods,
                ),
                markets: Map::new(
                    context,
                    2,
                    |context, slot| {
                        PublicState::new(
                            context,
                            slot,
                            MarketSerializationMethods,
                        )
                    },
                ),
                liquidity: PublicState::new(
                    context,
                    3,
                    SafeU120SerializationMethods,
                ),
                // -------------------- PRIVATE ----------------------
                positions: Map::new(
                    context,
                    4,
                    |context, slot| {
                        Map::new(
                            context,
                            slot,
                            |context, slot| {
                                Singleton::new(context, slot, PositionSerializationMethods)
                            }
                        )
                    },
                ),
                usersLastPosId: Map::new(
                    context,
                    5,
                    |context, slot| {
                        Singleton::new(context, slot, UserPosIdSerializationMethods)
                    }
                ),
                pendingRequests: Set::new(context, 6, TransparentNoteMethods)
            }
        }
    }


    #[aztec(private)]
    fn constructor(admin: AztecAddress, liquidity: Field) {
        let selector = compute_selector("_initialize((Field),Field)");
        context.call_public_function(context.this_address(), selector, [admin.address, liquidity]);
    }

    #[aztec(public)]
    fn open_position(
        collateral: u120,
        leverage: u32,
        pos_type: u8,
        market_id: Field,
        market_price: u120, // todo: check authorized signature with price
        secret_hash: Field
    ) {
        // TODO: check market exists and other checks
        let market = storage.markets.at(market_id).read();
        let open_fee = (collateral * market.openFeeRate as u120) / HUNDRED_PERCENT as u120;
        let mut open_price = market_price;
        if (pos_type == 0) {
            // long
            open_price = (open_price * (HUNDRED_PERCENT + market.baseSpreadRate) as u120) / HUNDRED_PERCENT as u120;
        } else if (pos_type == 1) {
            // short
            open_price = (open_price * (HUNDRED_PERCENT - market.baseSpreadRate) as u120) / HUNDRED_PERCENT as u120;
        } else {
            assert (false);
        }

        let pendingRequests = storage.pendingRequests;
        let mut note = TransparentNote::new(
            collateral as Field,
            leverage as Field,
            pos_type as Field,
            market_id as Field,
            market_price as Field,
            open_price as Field,
            open_fee as Field,
            market.borrowBaseRatePerHour as Field,
            context.timestamp(),
            secret_hash
        );
        pendingRequests.insert_from_public(&mut note);
        1
    }



    #[aztec(private)]
    fn resolve_open_position(
        to: AztecAddress,
        secret: Field
    ) {
        let pendingRequests = storage.pendingRequests;
        let secret_hash = compute_secret_hash(secret);
        let options = NoteGetterOptions::new().select(9, secret_hash).set_limit(1);
        let notes = pendingRequests.get_notes(options);
        let note = notes[0].unwrap_unchecked();
        pendingRequests.remove(note);
    
        // todo: add private position
        let mut new_pos_id = UserPosId::new((last_pos_id(to.address) + 1) as Field, to.address);
        // first position of user
        if (new_pos_id.value == 1) {
            storage.usersLastPosId.at(to.address).initialize(&mut new_pos_id, Option::some(to.address));
        } else {
            storage.usersLastPosId.at(to.address).replace(&mut new_pos_id);
        }

        // todo: real values
        let mut position = Position::new(
            new_pos_id.value,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            // market.borrowBaseRatePerHour,
            1000000000,
            LIQUIDATION_THRESHOLD_RATE,
            1,
            to.address
        );

        // save new position
        storage.positions.at(to.address).at(new_pos_id.value as Field).initialize(&mut position, Option::some(to.address));

        // todo: increase market OI
        1
    }


    #[aztec(private)]
    fn resolve_open_position_test() {
        let sender = context.msg_sender();
        // update last pos id
        let mut new_pos_id = UserPosId::new((last_pos_id(sender) + 1) as Field, sender);
        // first position of user
        if (new_pos_id.value == 1) {
            storage.usersLastPosId.at(sender).initialize(&mut new_pos_id, Option::some(sender));
        } else {
            storage.usersLastPosId.at(sender).replace(&mut new_pos_id);
        }
        emit_encrypted_log(
            &mut context,
            context.this_address(),
            storage.usersLastPosId.storage_slot,
            get_public_key(sender),
            new_pos_id.serialize()
        );

        let mut position = Position::new(
            new_pos_id.value,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            // market.borrowBaseRatePerHour,
            1000000000,
            LIQUIDATION_THRESHOLD_RATE,
            1,
            sender
        );

        // save new position
        storage.positions.at(sender).at(new_pos_id.value as Field).initialize(&mut position, Option::some(sender));
        emit_encrypted_log(
            &mut context,
            context.this_address(),
            storage.positions.storage_slot,
            get_public_key(sender),
            position.serialize()
        );

        1
    }

    // ---------------------------------------- PUBLIC -----------------------------------------------
    #[aztec(public)]
    internal fn _initialize(
        new_admin: AztecAddress,
        initial_liquidity: Field
    ) {
        storage.admin.write(new_admin);
        let initial = SafeU120::new(initial_liquidity);
        storage.liquidity.write(initial);
    }

    // #[aztec(private)]
    // fn close_position(

    // )

    // #[aztec(public)]
    // internal fn _increase_market_oi(
    //     market_id: Field,
    //     amount: Field,
    //     pos_type: Field
    // ) {
        
    // }

    unconstrained fn admin() -> Field {
        storage.admin.read().address
    }

    unconstrained fn market(market_id: Field) -> Market {
        storage.markets.at(market_id).read()
    }

    unconstrained fn position(
        user: Field,
        pos_id: Field
    ) -> Position {
        storage.positions.at(user).at(pos_id).get_note()
    }

    unconstrained fn liquidity() -> u120 {
        storage.liquidity.read().value
    }

    unconstrained fn last_pos_id(
        user: Field
    ) -> u32 {
        let has_positions = storage.usersLastPosId.at(user).is_initialized(Option::some(user));
        if (has_positions) {
            storage.usersLastPosId.at(user).get_note().value
        } else {
            0
        }
    }

    unconstrained fn compute_note_hash_and_nullifier(contract_address: Field, nonce: Field, storage_slot: Field, preimage: [Field; 12]) -> [Field; 4] {
        let note_header = NoteHeader::new(contract_address, nonce, storage_slot);
        if (storage_slot == 4) {
            note_utils::compute_note_hash_and_nullifier(PositionSerializationMethods, note_header, preimage)
        } else if (storage_slot == 5) {
            note_utils::compute_note_hash_and_nullifier(UserPosIdSerializationMethods, note_header, preimage)
        } else {
            note_utils::compute_note_hash_and_nullifier(TransparentNoteMethods, note_header, preimage)
        }
    }
}

