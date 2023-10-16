use dep::aztec::types::type_serialization::TypeSerializationInterface;

struct Market {
    totalLongs: u120,
    totalShorts: u120,
    maxTotalLongs: u120,
    maxTotalShorts: u120,
    maxLeverage: u32,
    openFeeRate: u64,
    baseSpreadRate: u64,
    borrowBaseRatePerHour: u64
}

global MARKET_SERIALIZED_LEN: Field = 8;

fn deserialize(fields: [Field; MARKET_SERIALIZED_LEN]) -> Market {
    Market {
        totalLongs: fields[0] as u120,
        totalShorts: fields[1] as u120,
        maxTotalLongs: fields[2] as u120,
        maxTotalShorts: fields[3] as u120,
        maxLeverage: fields[4] as u32,
        openFeeRate: fields[5] as u64,
        baseSpreadRate: fields[6] as u64,
        borrowBaseRatePerHour: fields[7] as u64
    }
}

fn serialize(market: Market) -> [Field; MARKET_SERIALIZED_LEN] {
    [
        market.totalLongs as Field,
        market.totalShorts as Field,
        market.maxTotalLongs as Field,
        market.maxTotalShorts as Field,
        market.maxLeverage as Field,
        market.openFeeRate as Field,
        market.baseSpreadRate as Field,
        market.borrowBaseRatePerHour as Field,
    ]
}

impl Market {
    fn serialize(self: Self) -> [Field; MARKET_SERIALIZED_LEN] {
        serialize(self)
    }
}

global MarketSerializationMethods = TypeSerializationInterface {
    deserialize,
    serialize
};