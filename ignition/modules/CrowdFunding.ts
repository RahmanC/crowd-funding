import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const CrowdFundingModule = buildModule("CrowdFundingModule", (m) => {
  const crowdFund = m.contract("Crowdfunding");

  return { crowdFund };
});

export default CrowdFundingModule;
