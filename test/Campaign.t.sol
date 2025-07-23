// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Campaign} from "../src/Campaign.sol"; 
import {IDRX} from "../src/IDRX.sol";       

contract CampaignTest is Test {
    Campaign campaign;
    IDRX idrx;

    address public owner = makeAddr("owner");
    address public donor1 = makeAddr("donor1");
    address public donor2 = makeAddr("donor2");

    uint256 public constant TARGET_AMOUNT = 1000 * 1e2;
    uint256 public constant DONATION_AMOUNT = 600 * 1e2;
    uint256 public constant DEADLINE_IN_FUTURE = 1 days;

    function setUp() public {
        vm.startPrank(owner);
        idrx = new IDRX();
        idrx.mintTo(donor1, 1_000_000 * 1e2); 
        idrx.mintTo(donor2, 1_000_000 * 1e2); 
        vm.stopPrank();

        uint256 deadline = block.timestamp + DEADLINE_IN_FUTURE;
        campaign = new Campaign(
            owner,
            "Yang ngadain calon juara",
            TARGET_AMOUNT,
            deadline,
            "ipfs_hash_string",
            address(idrx),
            Campaign.CampaignCategory.Sosial
        );
    }


    function test_InitialState() public view {
        assertEq(campaign.owner(), owner);
        assertEq(campaign.targetAmount(), TARGET_AMOUNT);
        assertEq(campaign.amountRaised(), 0);
        assertEq(address(campaign.token()), address(idrx));
        assertEq(uint(campaign.category()), uint(Campaign.CampaignCategory.Sosial));
    }

    // SCENARIO 1: Donasi berhasil
    function test_Donate_Succeeds() public {
        vm.prank(donor1);
        idrx.approve(address(campaign), DONATION_AMOUNT);

        vm.prank(donor1);
        campaign.donate(DONATION_AMOUNT);

        assertEq(campaign.amountRaised(), DONATION_AMOUNT, "amountRaised should be updated");
        assertEq(campaign.donations(donor1), DONATION_AMOUNT, "donations mapping should be updated");
        assertEq(idrx.balanceOf(address(campaign)), DONATION_AMOUNT, "Campaign contract should receive tokens");
    }

    // SCENARIO 2: Penarikan dana oleh owner berhasil setelah target tercapai
    function test_Withdraw_Succeeds_WhenTargetMet() public {
        vm.prank(donor1);
        idrx.approve(address(campaign), DONATION_AMOUNT);
        vm.prank(donor1);
        campaign.donate(DONATION_AMOUNT);

        vm.prank(donor2);
        idrx.approve(address(campaign), DONATION_AMOUNT);
        vm.prank(donor2);
        campaign.donate(DONATION_AMOUNT);

        vm.warp(block.timestamp + DEADLINE_IN_FUTURE + 1);

        uint256 totalRaised = DONATION_AMOUNT * 2;
        uint256 ownerInitialBalance = idrx.balanceOf(owner);

        vm.prank(owner);
        campaign.withdraw();

        assertEq(idrx.balanceOf(address(campaign)), 0, "Campaign balance should be zero after withdrawal");
        assertEq(idrx.balanceOf(owner), ownerInitialBalance + totalRaised, "Owner should receive all funds");
    }

    // SCENARIO 3: Refund berhasil jika target tidak tercapai
    function test_Refund_Succeeds_WhenTargetNotMet() public {
        vm.prank(donor1);
        idrx.approve(address(campaign), DONATION_AMOUNT);
        vm.prank(donor1);
        campaign.donate(DONATION_AMOUNT);

        vm.warp(block.timestamp + DEADLINE_IN_FUTURE + 1);

        uint256 donorInitialBalance = idrx.balanceOf(donor1);

        vm.prank(donor1);
        campaign.refund();

        assertEq(idrx.balanceOf(donor1), donorInitialBalance + DONATION_AMOUNT, "Donor should get their money back");
        assertEq(campaign.donations(donor1), 0, "Donor's contribution should be reset to zero");
    }
    
    // SCENARIO 4: Pengecekan status kampanye
    function test_GetStatus() public {
        assertEq(uint(campaign.getStatus()), uint(Campaign.CampaignStatus.Active));

        vm.prank(donor1);
        idrx.approve(address(campaign), TARGET_AMOUNT);
        vm.prank(donor1);
        campaign.donate(TARGET_AMOUNT);
        vm.warp(block.timestamp + DEADLINE_IN_FUTURE + 1);
        assertEq(uint(campaign.getStatus()), uint(Campaign.CampaignStatus.Successful));

        setUp();

        vm.prank(donor1);
        idrx.approve(address(campaign), 100);
        vm.prank(donor1);
        campaign.donate(100);
        vm.warp(block.timestamp + DEADLINE_IN_FUTURE + 1);
        assertEq(uint(campaign.getStatus()), uint(Campaign.CampaignStatus.Failed));
    }

    // Revert Scenario
    function test_Revert_DonateAfterDeadline() public {
        vm.warp(block.timestamp + DEADLINE_IN_FUTURE + 1);
        
        vm.prank(donor1);
        idrx.approve(address(campaign), DONATION_AMOUNT);

        vm.expectRevert("Campaign: Deadline has passed");
        vm.prank(donor1);
        campaign.donate(DONATION_AMOUNT);
    }

    function test_Revert_WithdrawBeforeDeadline() public {
        vm.prank(owner);
        vm.expectRevert("Campaign: Deadline has not been reached yet");
        campaign.withdraw();
    }

    function test_Revert_WithdrawByNonOwner() public {
        vm.warp(block.timestamp + DEADLINE_IN_FUTURE + 1);
        
        vm.prank(donor1); 
        vm.expectRevert("Campaign: Caller is not the owner");
        campaign.withdraw();
    }

    function test_Revert_WithdrawIfTargetNotMet() public {
        vm.prank(donor1);
        idrx.approve(address(campaign), 100);
        vm.prank(donor1);
        campaign.donate(100);
        
        vm.warp(block.timestamp + DEADLINE_IN_FUTURE + 1);

        vm.prank(owner);
        vm.expectRevert("Target not reached");
        campaign.withdraw();
    }
}
