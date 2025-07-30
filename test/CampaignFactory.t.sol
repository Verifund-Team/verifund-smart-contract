// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {CampaignFactory} from "../src/CampaignFactory.sol";
import {Campaign} from "../src/Campaign.sol";

contract CampaignFactoryTest is Test {
    CampaignFactory public factory;
    address public idrxTokenAddress;

    function setUp() public {
        idrxTokenAddress = vm.envAddress("IDRX_TOKEN_ADDRESS");

        factory = new CampaignFactory(idrxTokenAddress);
    }

    function test_CreateCampaignWithRealIDRX() public {
        factory.createCampaign("Real IDRX Campaign", 100000, 30, "QmRealHash");

        address[] memory campaigns = factory.getDeployedCampaigns();
        assertEq(campaigns.length, 1);

        Campaign campaign = Campaign(campaigns[0]);
        assertEq(campaign.name(), "Real IDRX Campaign");
        assertEq(campaign.targetAmount(), 100000);
        assertEq(address(campaign.token()), idrxTokenAddress);
    }

    function test_FactoryIDRXTokenAddress() public {
        assertEq(factory.idrxTokenAddress(), idrxTokenAddress);
    }
}
