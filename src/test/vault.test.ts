import {VaultContract} from '../artifacts/Vault.js'
import {
  AccountWalletWithPrivateKey,
  AztecAddress,
  createPXEClient,
  Fr, getSandboxAccountsWallets,
  PXE,
  waitForSandbox,
  NotePreimage,
  computeMessageSecretHash
} from '@aztec/aztec.js'
import {createDebugLogger} from '@aztec/foundation/log'

const setupSandbox = async () => {
  const { PXE_URL = 'http://167.99.212.95:8080' } = process.env
  const pxe = createPXEClient(PXE_URL)
  await waitForSandbox(pxe)
  return pxe
}


describe('ZK Contract Tests', () => {
  let owner: AccountWalletWithPrivateKey
  let _account2: AccountWalletWithPrivateKey
  let _account3: AccountWalletWithPrivateKey
  let vaultAddress: AztecAddress
  let contractAddress: AztecAddress
  let pxe: PXE;

  async function openPosAndAddNoteToPXE(
    wallet: AccountWalletWithPrivateKey,
    id: number,
    collateral: number,
    market_id: number,
    market_price: number,
    pos_type: number,
    leverage: number,
    secret_hash: Fr
  ) {
    const vault = await getVault(wallet, vaultAddress);

    const pos = await vault.methods.construct_position(
      id,
      collateral,
      market_id,
      market_price,
      pos_type,
      leverage,
      wallet.getAddress(),
      secret_hash
    ).view();
      console.log(pos);

    const serialized = await vault.methods.serialize_pos(pos).view();
    console.log(serialized);

    const tx = await vault.methods.open_position(
      id,
      collateral,
      leverage,
      pos_type,
      market_id,
      market_price,
      secret_hash
    ).send().wait();
    console.log('Open tx', tx);

    const storageSlot = new Fr(5); // The storage slot of `pendingRequests` is 5.
    const preimage = new NotePreimage(serialized.map((i: any) => new Fr(i)));
    await wallet.addNote(wallet.getAddress(), vaultAddress, storageSlot, preimage, tx.txHash);
  };
  

  async function getVault(wallet: AccountWalletWithPrivateKey, address: AztecAddress) {
    return VaultContract.at(address, wallet);
  }

  describe('Setup', async() => {
    it('Init sandbox', async () => {
      pxe = await setupSandbox();
      [owner, _account2, _account3] = await getSandboxAccountsWallets(pxe);
      const [a] = await pxe.getRegisteredAccounts();
      console.log(owner.getAddress().toString(), a.address.toString());
    });

    it('Deploy vault', async function() {
      const vault = await VaultContract.deploy(pxe, owner.getCompleteAddress(), 1000000000).send().deployed();
      vaultAddress = vault.address;
      console.log(vaultAddress.toString())
    });
  });

  describe('Test', async() => {
    let secret = Fr.random();

    it('Add market', async () => {
      const vault = await getVault(owner, vaultAddress);
      const tx = await vault.methods.add_market(1, 100_000_000_000, 100_000_000_000, 50_000_000, 10_000_000_000, 1_000_000_000).send().wait();
      await vault.methods.add_market(2, 100_000_000_000, 100_000_000_000, 50_000_000, 10_000_000_000, 1_000_000_000).send().wait();
      await vault.methods.add_market(3, 100_000_000_000, 100_000_000_000, 50_000_000, 10_000_000_000, 1_000_000_000).send().wait();

      console.log(tx);

      const market = await vault.methods.market(1).view();
      console.log(market);
    });

    it('Open position (request)',async () => {
      const secret_hash = await computeMessageSecretHash(secret);
      console.log(secret_hash);

      // long position, 10$, 1 market, 1000$ market price, 10x leverage
      await openPosAndAddNoteToPXE(owner, 1, 100_000_000, 1, 1_000_000_000, 0, 10_000_000, secret_hash);
    });

    it('Resolve position', async () => {
      const vault = await getVault(owner, vaultAddress);
      const tx = await vault.methods.resolve_open_position(secret).send().wait();
      console.log(tx);

      const positions = await vault.methods.positions(owner.getAddress()).view();
      console.log(positions[0]);
    });

    it('Check position pnl and liquidation price', async() => {
      const vault = await getVault(owner, vaultAddress);

      const positions = await vault.methods.positions(owner.getAddress()).view();
      // price dropped to 800$, we have ~20% loss
      const res = await vault.methods.pnl_and_liq(positions[0]._value, 800_000_000).view();
      console.log(res); 
    });

    it('Close position',async () => {
      const vault = await getVault(owner, vaultAddress);

      const tx = await vault.methods.close_position(1, 800_000_000).send().wait();
      console.log(tx);

      // check position dissapeared
      const positions = await vault.methods.positions(owner.getAddress()).view();
      console.log(positions[0]);
    })
  });
});
