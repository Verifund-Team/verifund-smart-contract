// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/IDRX.sol";

contract IDRXSimpleTest is Test {
    IDRX public token;
    address public owner = address(0x1);
    address public user = address(0x2);
    address public recipient = address(0x3);

    function setUp() public {
        vm.prank(owner);
        token = new IDRX();
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1_000_000 * 10 ** 2);
        assertEq(token.balanceOf(owner), 1_000_000 * 10 ** 2);
    }

    function testDecimals() public {
        assertEq(token.decimals(), 2);
    }

    function testTokenInfo() public {
        assertEq(token.name(), "Indonesia Rupiah");
        assertEq(token.symbol(), "IDRX");
    }

    function testPublicMint() public {
        vm.prank(user);
        token.mint(100 * 10 ** 2);
        assertEq(token.balanceOf(user), 100 * 10 ** 2);
    }

    function testMint10k() public {
        vm.prank(user);
        token.mint10k();
        assertEq(token.balanceOf(user), 10000 * 10 ** 2);
    }

    function testMintTo() public {
        vm.prank(user);
        token.mintTo(recipient, 500 * 10 ** 2);
        assertEq(token.balanceOf(recipient), 500 * 10 ** 2);
    }

    function testTransfer() public {
        vm.prank(owner);
        token.transfer(user, 50 * 10 ** 2);
        assertEq(token.balanceOf(user), 50 * 10 ** 2);
        assertEq(token.balanceOf(owner), (1_000_000 - 50) * 10 ** 2);
    }

    function testBurn() public {
        vm.prank(owner);
        token.burn(100 * 10 ** 2);
        assertEq(token.balanceOf(owner), (1_000_000 - 100) * 10 ** 2);
        assertEq(token.totalSupply(), (1_000_000 - 100) * 10 ** 2);
    }

    function testMultipleMints() public {
        vm.prank(user);
        token.mint(100 * 10 ** 2);

        vm.prank(user);
        token.mint(200 * 10 ** 2);

        assertEq(token.balanceOf(user), 300 * 10 ** 2);
    }

    function testNoRestrictions() public {
        vm.prank(user);
        token.mint(1_000_000 * 10 ** 2);

        vm.prank(user);
        token.mint(5_000_000 * 10 ** 2);

        assertEq(token.balanceOf(user), 6_000_000 * 10 ** 2);
    }

    function testMintZeroAmount() public {
        vm.prank(user);
        token.mint(0);
        assertEq(token.balanceOf(user), 0);
    }

    function testMintToZeroAddress() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC20InvalidReceiver(address)")), address(0)));
        token.mintTo(address(0), 100 * 10 ** 2);
    }

    function testBurnMoreThanBalance() public {
        vm.prank(user);
        token.mint(100 * 10 ** 2);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("ERC20InsufficientBalance(address,uint256,uint256)")),
                user,
                100 * 10 ** 2,
                200 * 10 ** 2
            )
        );
        token.burn(200 * 10 ** 2);
    }
}