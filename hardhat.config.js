require("@nomiclabs/hardhat-waffle");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
   networks: {
   localhost: {
     url: "http://127.0.0.1:8545/",
   },
  //  kovan: {
  //   provider: function() {
  //     return new HDWalletProvider(
  //       //private keys array
  //       [privateKey],
  //       //url to ethereum node
  //       endpointUrl
  //     )
  //   },
  //   gas: 5000000,
  //   gasPrice: 25000000000,
  //   network_id: 42
  // }
  },
};

