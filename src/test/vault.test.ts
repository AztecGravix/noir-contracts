import {VaultContract, VaultContractArtifact} from '../artifacts/Vault.ts'
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
    });

    it('Deploy vault', async function() {
      const vault = await VaultContract.deploy(pxe, owner.getCompleteAddress(), 1000000000).send().deployed();
      vaultAddress = vault.address;
    });
  });

  describe('Test', async() => {

  });
});

