// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Campaign.sol";

contract CampaignFactory {
    address[] public deployedCampaigns;

    event CampaignCreated(
        address indexed campaignAddress,
        address indexed owner,
        string name,
        uint256 targetAmount,
        uint256 deadline,
        string ipfsHash 
    );

    function createCampaign(
        string memory _name,
        uint256 _targetAmount,
        uint256 _durationInDays,
        string memory _ipfsHash,
        address _tokenAddress
    ) public {
        uint256 deadline = block.timestamp + (_durationInDays * 1 days);

        Campaign newCampaign = new Campaign(
            msg.sender,
            _name,
            _targetAmount,
            deadline,
            _ipfsHash,
            _tokenAddress
        );

        deployedCampaigns.push(address(newCampaign));

        emit CampaignCreated(
            address(newCampaign),
            msg.sender,
            _name,
            _targetAmount,
            deadline,
            _ipfsHash
        );
    }

    function getDeployedCampaign() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}