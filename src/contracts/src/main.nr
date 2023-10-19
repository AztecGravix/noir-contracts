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
            note_viewer_options::NoteViewerOptions,
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
        position_note::{POSITION_NOTE_SERIALIZED_LEN, PositionNoteSerializationMethods, PositionNote, LIQUIDATION_THRESHOLD_RATE, LEVERAGE_BASE, SCALING_FACTOR, PnlAndLiq},
        safe_u120_serialization::{SAFE_U120_SERIALIZED_LEN, SafeU120SerializationMethods},
        position_map::{PositionMap}
    };
    struct Storage {
        admin: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
        markets: Map<PublicState<Market, MARKET_SERIALIZED_LEN>>,
        liquidity: PublicState<SafeU120, SAFE_U120_SERIALIZED_LEN>,
        positions: PositionMap,
        pendingRequests: Set<PositionNote, POSITION_NOTE_SERIALIZED_LEN>
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
                positions: PositionMap::new(context, 4),
                pendingRequests: Set::new(context, 5, PositionNoteSerializationMethods)
            }
        }
    }


    #[aztec(private)]
    fn constructor(admin: AztecAddress, liquidity: Field) {
        let selector = compute_selector("_initialize((Field),Field)");
        context.call_public_function(context.this_address(), selector, [admin.address, liquidity]);
    }


    #[aztec(private)]
    fn resolve_open_position(
        secret: Field
    ) {
        let sender = context.msg_sender();
        let pendingRequests = storage.pendingRequests;
        let secret_hash = compute_secret_hash(secret);
        let options = NoteGetterOptions::new().select(10, secret_hash).set_limit(1);
        let notes = pendingRequests.get_notes(options);
        let mut note = notes[0].unwrap_unchecked();
        pendingRequests.remove(note);

        // save new position
        storage.positions.at(AztecAddress::new(sender)).add(&mut note);
        emit_encrypted_log(
            &mut context,
            context.this_address(),
            storage.positions.slot_for(AztecAddress::new(sender)), // todo: calc slot
            get_public_key(sender),
            note.serialize()
        );
        // todo: increase market OI
        1
    }

    #[aztec(private)]
    fn close_position(position_id: Field) {
        let sender = context.msg_sender();
        storage.positions.at(AztecAddress::new(sender)).remove(position_id);
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

    #[aztec(public)]
    fn add_market(
        market_id: u8,
        maxTotalLongs: u120,
        maxTotalShorts: u120,
        maxLeverage: u32,
        openFeeRate: u64,
        baseSpreadRate: u64
    ) {
        let market = storage.markets.at(market_id as Field);
        market.write(Market {
            totalLongs: 0,
            totalShorts: 0,
            maxTotalLongs: maxTotalLongs,
            maxTotalShorts: maxTotalShorts,
            maxLeverage: maxLeverage,
            openFeeRate: openFeeRate,
            baseSpreadRate: baseSpreadRate
        });
        1
    }

      #[aztec(public)]
    fn open_position(
        id: u32,
        collateral: u120,
        leverage: u32,
        pos_type: u8,
        market_id: u8,
        market_price: u120, // todo: check authorized signature with price
        secret_hash: Field
    ) {
        let market = storage.markets.at(market_id as Field).read();
        assert (market.maxTotalLongs > 0); // check market exists
        assert (leverage < market.maxLeverage); // do not exceed max leverage!
        assert ((pos_type == 0) | (pos_type == 1)); // position type should be long (0) or short (1)

        let sender = context.msg_sender();
        let mut note = construct_position(
            id,
            collateral,
            market_id,
            market_price,
            pos_type,
            leverage,
            sender,
            secret_hash
        );
        storage.pendingRequests.insert_from_public(&mut note);
        1
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

    // just helper
    unconstrained fn construct_position(
        id: u32,
        collateral: u120,
        market_id: u8,
        market_price: u120,
        pos_type: u8,
        leverage: u32,
        owner: Field,
        secret_hash: Field
    ) -> PositionNote {
        let market = storage.markets.at(market_id as Field).read();
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

        PositionNote::new(
            id,
            market_id,
            pos_type,
            collateral,
            open_fee,
            open_price,
            market_price,
            leverage,
            LIQUIDATION_THRESHOLD_RATE,
            owner,
            secret_hash
        )
    }

    // helper func
    unconstrained fn serialize_pos(note: PositionNote) -> [Field; POSITION_NOTE_SERIALIZED_LEN] {
        note.serialize()
    }

    unconstrained fn pending_positions() -> [Option<PositionNote>; 10] {
        let options = NoteViewerOptions::new();
        storage.pendingRequests.view_notes(options)
    }

    unconstrained fn positions(user: Field) -> [Option<PositionNote>; 10] {
        let options = NoteViewerOptions::new();
        storage.positions.at(AztecAddress::new(user)).set.view_notes(options)
    }

    // return pnl, pnl sign, liq price
    unconstrained fn pnl_and_liq(note: PositionNote, close_price: u120) -> PnlAndLiq {
        let collateral = note.initialCollateral - note.openFee;
        let leveraged_pos = (collateral * LEVERAGE_BASE) / note.leverage as u120;

        let mut pnl = 0;
        let mut positive: bool = true; // noir does not support signed integers, so we will idicate sign with var. 0 - positive, 1 - negative 
        if (close_price <= note.openPrice) {
            pnl = SCALING_FACTOR - (close_price * SCALING_FACTOR) / note.openPrice;
            positive = false;
        } else {
            pnl = (close_price * SCALING_FACTOR) / note.openPrice - SCALING_FACTOR;
            positive = true;
        }
        // short
        if (note.posType == 1) {
            positive = !positive;
        }
        pnl = pnl * leveraged_pos / SCALING_FACTOR;

        let mut liq_price_dist = collateral * (HUNDRED_PERCENT - LIQUIDATION_THRESHOLD_RATE) as u120 / HUNDRED_PERCENT as u120;
        liq_price_dist = note.openPrice * liq_price_dist / leveraged_pos;

        let mut liq_price = 0;
        // long
        if (note.posType == 0) {
            if (positive) {
                liq_price = note.openPrice - liq_price_dist;
            } else {
                liq_price = note.openPrice + liq_price_dist;
            }
        } else {
            if (positive) {
                liq_price = note.openPrice + liq_price_dist;
            } else {
                liq_price = note.openPrice - liq_price_dist;
            }
        }

        PnlAndLiq { pnl: pnl, positive: positive, liqPrice: liq_price }
    }

    unconstrained fn liquidity() -> u120 {
        storage.liquidity.read().value
    }


    unconstrained fn compute_note_hash_and_nullifier(contract_address: Field, nonce: Field, storage_slot: Field, preimage: [Field; 12]) -> [Field; 4] {
        let note_header = NoteHeader::new(contract_address, nonce, storage_slot);
        note_utils::compute_note_hash_and_nullifier(PositionNoteSerializationMethods, note_header, preimage)
    }
}

