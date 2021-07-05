
const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const RPS = await hre.ethers.getContractFactory("RpsGame");
  const contract = await RPS.deploy();


  console.log("contract deployed to:", contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
