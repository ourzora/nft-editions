module.exports = async ({ getNamedAccounts, deployments }: any) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const sharedNFTLogicAddress = (await deployments.get("SharedNFTLogic"))
    .address;

  await deploy("ExpandedNFT", {
    from: deployer,
    args: [sharedNFTLogicAddress],
    log: true,
  });
};
module.exports.tags = ["ExpandedNFT"];
module.exports.dependencies = ["SharedNFTLogic"];
