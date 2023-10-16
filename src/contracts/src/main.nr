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
        context::{PrivateContext, PublicContext, Context},
        oracle::{
            get_public_key::get_public_key,
        },
        state_vars::{map::Map, public_state::PublicState, singleton::Singleton},
        types::type_serialization::{
            aztec_address_serialization::{AztecAddressSerializationMethods, AZTEC_ADDRESS_SERIALIZED_LEN},
        },
        types::address::{AztecAddress},
        selector::compute_selector,
    };
    use crate::types::{
        market::{MARKET_SERIALIZED_LEN, Market, MarketSerializationMethods},
        user_pos_id::{USER_ID_POS_SERIALIZED_LEN, UserPosId, UserPosIdSerializationMethods},
        position::{POSITION_SERIALIZED_LEN, PositionSerializationMethods, Position},
        safe_u120_serialization::{SAFE_U120_SERIALIZED_LEN, SafeU120SerializationMethods}
    };

    struct Storage {
        admin: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
        markets: Map<PublicState<Market, MARKET_SERIALIZED_LEN>>,
        liquidity: PublicState<SafeU120, SAFE_U120_SERIALIZED_LEN>,
        positions: Map<Map<Singleton<Position, POSITION_SERIALIZED_LEN>>>,
        usersLastPosId: Map<Singleton<UserPosId, USER_ID_POS_SERIALIZED_LEN>>
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
                )
            }
        }
    }


    #[aztec(private)]
    fn constructor(admin: AztecAddress, liquidity: Field) {
        let selector = compute_selector("_initialize((Field,Field))");
        context.call_public_function(context.this_address(), selector, [admin.address, liquidity]);
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
    // fn open_position(

    // )

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
        storage.usersLastPosId.at(user).get_note().value
    }
}
