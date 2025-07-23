// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Campaign} from "../src/Campaign.sol";
import {IDRX} from "../src/IDRX.sol";

contract DeployCampaign is Script {
    address constant IDRX_TOKEN_ADDRESS = 0x31c0C6e0F048d259Cd8597e1e3594F842555b235; 

    function run() external returns (address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        string memory name = "Bantuan Korban Banjir Pati";
        uint256 targetAmount = 5000 * 1e2; 
        uint256 deadline = block.timestamp + 30 days; 
        string memory ipfsHash = "bafkreihofx6lgsjhdma6ekuf6wbgwwp6y52ir2wefjnlgmeohjf6qc76ve";
        Campaign.CampaignCategory category = Campaign.CampaignCategory.BencanaAlam;

        Campaign campaign = new Campaign(
            msg.sender, 
            name,
            targetAmount,
            deadline,
            ipfsHash,
            IDRX_TOKEN_ADDRESS, 
            category
        );

        console.log("=== Campaign Deployed Successfully ===");
        console.log("Campaign Contract Address:", address(campaign));
        console.log("Campaign Owner:", campaign.owner());
        console.log("Campaign Name:", campaign.name());
        console.log("Target:", campaign.targetAmount());
        console.log("====================================");

        vm.stopBroadcast();

        return address(campaign);
    }
}
