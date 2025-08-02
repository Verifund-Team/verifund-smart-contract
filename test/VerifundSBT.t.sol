// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {VerifundSBT} from "../src/VerifundSBT.sol";

contract VerifundSBTTest is Test {
    VerifundSBT public verifundSBT;
    address public owner;
    address public user1;
    string constant TEST_BASE_URI = "https://ipfs.io/ipfs/QmTestHash";

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");

        verifundSBT = new VerifundSBT(TEST_BASE_URI);
    }

    function test_DeploymentWithMetadata() public {
        assertEq(verifundSBT.name(), "Verifund Verified Badge");
        assertEq(verifundSBT.symbol(), "VVB");
        assertEq(verifundSBT.owner(), owner);
    }

    function test_TokenURIAfterClaim() public {
        verifundSBT.beriIzinMint(user1);
        vm.prank(user1);
        verifundSBT.klaimLencanaSaya();

        uint256 tokenId = uint256(uint160(user1));
        string memory uri = verifundSBT.tokenURI(tokenId);

        assertEq(uri, TEST_BASE_URI);
        console.log("Token URI:", uri);
    }

    function test_GetBadgeInfo() public {
        (bool hasPermission, bool isVerified, uint256 tokenId, string memory uri) = verifundSBT.getBadgeInfo(user1);

        assertFalse(hasPermission);
        assertFalse(isVerified);
        assertEq(uri, "");

        verifundSBT.beriIzinMint(user1);
        (hasPermission, isVerified, tokenId, uri) = verifundSBT.getBadgeInfo(user1);

        assertTrue(hasPermission);
        assertFalse(isVerified);
        assertEq(uri, "");

        vm.prank(user1);
        verifundSBT.klaimLencanaSaya();
        (hasPermission, isVerified, tokenId, uri) = verifundSBT.getBadgeInfo(user1);

        assertFalse(hasPermission);
        assertTrue(isVerified);
        assertEq(uri, TEST_BASE_URI);
    }

    function test_UpdateBaseURI() public {
        string memory newURI = "https://ipfs.io/ipfs/QmNewHash";

        vm.expectEmit(false, false, false, true);
        emit VerifundSBT.BaseURIUpdated(newURI);

        verifundSBT.setBaseURI(newURI);

        verifundSBT.beriIzinMint(user1);
        vm.prank(user1);
        verifundSBT.klaimLencanaSaya();

        uint256 tokenId = uint256(uint160(user1));
        assertEq(verifundSBT.tokenURI(tokenId), newURI);
    }
}