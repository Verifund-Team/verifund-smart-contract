// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/CampaignFactory.sol";

contract DeployCampaignFactory is Script {
    function run() public returns (CampaignFactory) {
        vm.startBroadcast(); 

        CampaignFactory factory = new CampaignFactory();

        vm.stopBroadcast();
        return factory;
    }
}