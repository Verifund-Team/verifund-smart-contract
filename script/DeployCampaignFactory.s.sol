pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/CampaignFactory.sol";

contract DeployCampaignFactory is Script {
    function run() public returns (CampaignFactory) {
        address idrxTokenAddress = vm.envAddress("IDRX_TOKEN_ADDRESS");
        address verifundSBTAddress = vm.envAddress("VERIFUND_SBT_ADDRESS");

        console.log("Deploying CampaignFactory with IDRX token:", idrxTokenAddress);
        console.log("Using VerifundSBT address:", verifundSBTAddress);

        vm.startBroadcast();

        CampaignFactory factory = new CampaignFactory(idrxTokenAddress, verifundSBTAddress);

        console.log("CampaignFactory deployed to:", address(factory));

        vm.stopBroadcast();
        return factory;
    }
}
