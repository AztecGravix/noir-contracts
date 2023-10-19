import {VaultContract} from '../artifacts/Vault.js'
import {
  AccountWallet,
  AccountWalletWithPrivateKey,
  AztecAddress,
  CompleteAddress,
  Contract,
  createPXEClient,
  Fr, getSandboxAccountsWallets,
  PXE,
  TxStatus,
  waitForSandbox,
  Wallet,
} from '@aztec/aztec.js'
import {createDebugLogger} from '@aztec/foundation/log'

const setupSandbox = async () => {
  const { PXE_URL = 'http://localhost:8080' } = process.env
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
    it('Add market', async () => {
      const vault = await getVault(owner, vaultAddress);
      await vault.methods.add_market(1, 10_000_000, 10_000_000, 50_000_000, 10_000_000_000, 1_000_000_000, 1_000_000_000).send().wait();

      const market = await vault.methods.market(1).view();
      console.log(market);
    });

    it('Open position (request)',async () => {
      const vault = await getVault(owner, vaultAddress);

      const tx = await vault.methods.open_position(
        1, 2, 3, 0, 5, 6, 7
      ).send().wait();

      const positions = await vault.methods.positions(owner.getAddress()).view();
      console.log(positions);
    });
  });
});
