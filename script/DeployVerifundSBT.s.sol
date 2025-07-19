// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {VerifundSBT} from "../src/VerifundSBT.sol";

contract DeployVerifundSBT is Script {
    function run() external returns (VerifundSBT) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Base URI dari hasil upload Pinata
        // Update dengan hash yang didapat dari upload-to-pinata.js
        string memory baseURI = "https://ipfs.io/ipfs/QmS4eWSdpaCT6MWXu6Mf7wB5gnJpw8AkQA21bA1gUtMaA1";
        
        vm.startBroadcast(deployerPrivateKey);
        
        VerifundSBT verifundSBT = new VerifundSBT(baseURI);
        
        vm.stopBroadcast();
        
        console.log("VerifundSBT deployed to:", address(verifundSBT));
        console.log("Owner:", verifundSBT.owner());
        console.log("Base URI:", baseURI);
        
        return verifundSBT;
    }
}