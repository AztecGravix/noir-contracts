
/* Autogenerated file, do not edit! */

/* eslint-disable */
import {
  AztecAddress,
  AztecAddressLike,
  CompleteAddress,
  Contract,
  ContractArtifact,
  ContractBase,
  ContractFunctionInteraction,
  ContractMethod,
  DeployMethod,
  EthAddress,
  EthAddressLike,
  FieldLike,
  Fr,
  PXE,
  Point,
  PublicKey,
  Wallet,
} from '@aztec/aztec.js';
import VaultContractArtifactJson from './Vault.json' assert { type: 'json' };
export const VaultContractArtifact = VaultContractArtifactJson as ContractArtifact;

/**
 * Type-safe interface for contract Vault;
 */
export class VaultContract extends ContractBase {
  
  private constructor(
    completeAddress: CompleteAddress,
    wallet: Wallet,
    portalContract = EthAddress.ZERO
  ) {
    super(completeAddress, VaultContractArtifact, wallet, portalContract);
  }
  

  
  /**
   * Creates a contract instance.
   * @param address - The deployed contract's address.
   * @param wallet - The wallet to use when interacting with the contract.
   * @returns A promise that resolves to a new Contract instance.
   */
  public static async at(
    address: AztecAddress,
    wallet: Wallet,
  ) {
    return Contract.at(address, VaultContract.artifact, wallet) as Promise<VaultContract>;
  }

  
  /**
   * Creates a tx to deploy a new instance of this contract.
   */
  public static deploy(pxe: PXE, admin: AztecAddressLike, liquidity: FieldLike) {
    return new DeployMethod<VaultContract>(Point.ZERO, pxe, VaultContractArtifact, Array.from(arguments).slice(1));
  }

  /**
   * Creates a tx to deploy a new instance of this contract using the specified public key to derive the address.
   */
  public static deployWithPublicKey(pxe: PXE, publicKey: PublicKey, admin: AztecAddressLike, liquidity: FieldLike) {
    return new DeployMethod<VaultContract>(publicKey, pxe, VaultContractArtifact, Array.from(arguments).slice(2));
  }
  

  
  /**
   * Returns this contract's artifact.
   */
  public static get artifact(): ContractArtifact {
    return VaultContractArtifact;
  }
  

  /** Type-safe wrappers for the public methods exposed by the contract. */
  public methods!: {
    
    /** _initialize(new_admin: struct, initial_liquidity: field) */
    _initialize: ((new_admin: AztecAddressLike, initial_liquidity: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** add_market(market_id: integer, maxTotalLongs: integer, maxTotalShorts: integer, maxLeverage: integer, openFeeRate: integer, baseSpreadRate: integer) */
    add_market: ((market_id: (bigint | number), maxTotalLongs: (bigint | number), maxTotalShorts: (bigint | number), maxLeverage: (bigint | number), openFeeRate: (bigint | number), baseSpreadRate: (bigint | number)) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** admin() */
    admin: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** compute_note_hash_and_nullifier(contract_address: field, nonce: field, storage_slot: field, preimage: array) */
    compute_note_hash_and_nullifier: ((contract_address: FieldLike, nonce: FieldLike, storage_slot: FieldLike, preimage: FieldLike[]) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** construct_position(id: integer, collateral: integer, market_id: integer, market_price: integer, pos_type: integer, leverage: integer, owner: field, secret_hash: field) */
    construct_position: ((id: (bigint | number), collateral: (bigint | number), market_id: (bigint | number), market_price: (bigint | number), pos_type: (bigint | number), leverage: (bigint | number), owner: FieldLike, secret_hash: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** liquidity() */
    liquidity: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** market(market_id: field) */
    market: ((market_id: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** open_position(id: integer, collateral: integer, leverage: integer, pos_type: integer, market_id: integer, market_price: integer, secret_hash: field) */
    open_position: ((id: (bigint | number), collateral: (bigint | number), leverage: (bigint | number), pos_type: (bigint | number), market_id: (bigint | number), market_price: (bigint | number), secret_hash: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** pending_positions() */
    pending_positions: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** pnl_and_liq(note: struct, close_price: integer) */
    pnl_and_liq: ((note: { id: (bigint | number), marketIdx: (bigint | number), posType: (bigint | number), initialCollateral: (bigint | number), openFee: (bigint | number), openPrice: (bigint | number), markPrice: (bigint | number), leverage: (bigint | number), liquidationThresholdRate: (bigint | number), owner: FieldLike, secret_hash: FieldLike, secret: FieldLike, header: { contract_address: FieldLike, nonce: FieldLike, storage_slot: FieldLike, is_transient: boolean } }, close_price: (bigint | number)) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** positions(user: field) */
    positions: ((user: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** resolve_open_position(secret: field) */
    resolve_open_position: ((secret: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** serialize_pos(note: struct) */
    serialize_pos: ((note: { id: (bigint | number), marketIdx: (bigint | number), posType: (bigint | number), initialCollateral: (bigint | number), openFee: (bigint | number), openPrice: (bigint | number), markPrice: (bigint | number), leverage: (bigint | number), liquidationThresholdRate: (bigint | number), owner: FieldLike, secret_hash: FieldLike, secret: FieldLike, header: { contract_address: FieldLike, nonce: FieldLike, storage_slot: FieldLike, is_transient: boolean } }) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;
  };
}
