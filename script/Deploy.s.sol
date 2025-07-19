// script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/IDRX.sol";

contract DeployIDRX is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        IDRX idrx = new IDRX();
        
        console.log("=== IDRX Simple Deployment ===");
        console.log("Contract Address:", address(idrx));
        console.log("Token Name:", idrx.name());
        console.log("Token Symbol:", idrx.symbol());
        console.log("Decimals:", idrx.decimals());
        console.log("Initial Supply:", idrx.totalSupply());
        console.log("Owner Balance:", idrx.balanceOf(msg.sender));
        console.log("================================");
        
        vm.stopBroadcast();
    }
}