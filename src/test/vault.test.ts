import {VaultContract, VaultContractArtifact} from '../artifacts/Vault.js'
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
    it('Call succeeds after deploy', async () => {
      const vault = await getVault(owner, vaultAddress);
      const res = await vault.methods.market(1).view();
      console.log(res);

      const res2 = await vault.methods.last_pos_id(owner.getAddress()).view();
      console.log(res2);
    });

    it('Open position',async () => {
      const vault = await getVault(owner, vaultAddress);
      // const tx = await vault.methods.open_position(
      //   1000000,
      //   1000000,
      //   0,
      //   1,
      //   2000000,
      //   123123
      // ).send();

      const tx = await vault.methods.resolve_open_position_test().send();

      console.log(`Sent transfer transaction ${await tx.getTxHash()}`);
      const receipt = await tx.wait();
      console.log(`Transaction has been mined on block ${receipt.blockNumber}, ${receipt.error}, ${receipt.status}`);
    });

    it('Check getters',async () => {
      const vault = await getVault(owner, vaultAddress);
      const res = await vault.methods.last_pos_id(owner.getAddress()).view();
      console.log(res);

      const pos = await vault.methods.position(owner.getAddress(), 1).view();
      console.log(pos);
    });
  });
});

// {
//   totalLongs: 0n,
//     totalShorts: 0n,
//   maxTotalLongs: 0n,
//   maxTotalShorts: 0n,
//   maxLeverage: 0n,
//   openFeeRate: 0n,
//   baseSpreadRate: 0n,
//   borrowBaseRatePerHour: 0n
// }


