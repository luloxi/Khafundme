import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const localChainId = "31337";

/**
 * Deploys a contract named "YourContract" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployKhafundme: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network goerli`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` which will fill DEPLOYER_PRIVATE_KEY
    with a random private key in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;
  const chainId = await hre.getChainId();

  await deploy("Khafundme", {
    from: deployer,
    // Contract constructor arguments
    args: [],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
    waitConfirmations: chainId === localChainId ? 0 : 5,
  });

  // Get the deployed contract
  // const yourContract = await hre.ethers.getContract("YourContract", deployer);
  // try {
  //   // Verify contract if not on local chain

  //   if (chainId !== localChainId) {
  //     const khafundmeDeployment = await hre.deployments.get("Khafundme");
  //     const khafundmeAddress = khafundmeDeployment.address;
  //     run("verify:verify", {
  //       // address: khafundmeAddress,
  //       // contract: "contracts/Khafundme.sol:Khafundme",
  //       // constructorArguments: [],
  //     });
  //   }
  // } catch (error) {
  //   console.error("Verification Error =>", error);
  // }
};
export default deployKhafundme;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployKhafundme.tags = ["Khafundme"];
