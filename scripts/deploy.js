// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
require("@nomiclabs/hardhat-ethers");

async function main() {

  // IMPORTING CONTRACTS...
  const FactoryContract = await hre.ethers.getContractFactory("JoeFactory");
  const RouterContract  = await hre.ethers.getContractFactory("JoeRouter02");
  const ETHWContract  = await hre.ethers.getContractFactory("ETHSToken");
  const RewardManager = await hre.ethers.getContractFactory("EtherstonesRewardManager");
  const wETHContract = await hre.ethers.getContractFactory("WETH");
  const Referral = await hre.ethers.getContractFactory("Referral");
  const preSale = await hre.ethers.getContractFactory("preSale");
  const QETHW = await hre.ethers.getContractFactory("QETHW");
  // Addresses...
  const WAVAX_Address = "0x1D308089a2D1Ced3f1Ce36B1FcaF815b07217be3";
  const FactoryFeeCollector  = "0x95818F22eD28cB353164C7bb2e8f6B24e377d2ce";
  const Factory_Address = "0xC93d03Fe6283A75cC3d88964Fe4F58FA946c98b8";
  const Router_Address = "0xadcBe444619dE95aeDD82245d0B422288b27C895";
  const DAI_Address = "0x32e5539Eb6122A5e32eE8F8D62b185BCc3c41483";

  // DEPLOY PRESALE

  const deployed_QETHW = await QETHW.deploy();
  console.log("QETHW Address: ", deployed_QETHW.address);

  const deployed_preSale = await preSale.deploy(DAI_Address, deployed_QETHW.address);
  console.log("preSale Address: ", deployed_preSale.address);

  await deployed_QETHW.setPresale(deployed_preSale.address);
  console.log("Presale contract initialized in QETHW!");

//--------------------------------------------------------------------
  // owner will manually start presale
  // owner will manually enable conversion

  // LAUNCH TOKEN

  // edit ETHW constructor for initial distribution of tokens

  const deployed_ETHW = await ETHWContract.deploy();
  console.log("ETHW Token Address :", deployed_ETHW.address);

  await deployed_ETHW.setEtherstonesRewardManager(deployed_preSale.address);
  console.log("Presale initialized in ETHW!");

  await deployed_preSale.setETHW(deployed_ETHW.address);
  console.log("ETHW initialised in presale!");

  await deployed_ETHW.authorize(deployed_preSale.address);
  console.log("Presale Contract Authorise in ETHW Token contract!");

  // owner will add liquidity for AVAX/ ETHW
  // owner will add liquidity for AVAX/ WETH
  // owner will call setTransferEnabled(0) in ETHW contract after adding liquidity, in order to start token TAX deductions...
  // owner will call enableLaunch() in ETHW contract to enable launch TAX;
 
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
