pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {VerifundSBT} from "../src/VerifundSBT.sol";

contract DeployVerifundSBT is Script {
    function run() external returns (VerifundSBT) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        string memory baseURI = "https://ipfs.io/ipfs/QmV4bJuAVn5eDSkviiGBEa8ZST3sLkwRBmg6jKtQa6osdY";

        vm.startBroadcast(deployerPrivateKey);

        VerifundSBT verifundSBT = new VerifundSBT(baseURI);

        vm.stopBroadcast();

        console.log("VerifundSBT deployed to:", address(verifundSBT));
        console.log("Owner:", verifundSBT.owner());
        console.log("Base URI:", baseURI);

        return verifundSBT;
    }
}