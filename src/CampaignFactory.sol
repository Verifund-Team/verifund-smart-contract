pragma solidity ^0.8.20;

import "./Campaign.sol";

contract CampaignFactory {
    address[] public deployedCampaigns;
    address public immutable idrxTokenAddress;

    constructor(address _idrxTokenAddress) {
        require(_idrxTokenAddress != address(0), "Invalid IDRX token address");
        idrxTokenAddress = _idrxTokenAddress;
    }

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
        string memory _ipfsHash
    ) public {
        require(_targetAmount > 0, "Target must be greater than zero");
        require(_durationInDays > 0, "Duration must be greater than zero");
        require(bytes(_ipfsHash).length > 0, "IPFS hash required");
        
        uint256 deadline = block.timestamp + (_durationInDays * 1 days);

        Campaign newCampaign = new Campaign(
            msg.sender,
            _name,
            _targetAmount,
            deadline,
            _ipfsHash,
            idrxTokenAddress
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

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}