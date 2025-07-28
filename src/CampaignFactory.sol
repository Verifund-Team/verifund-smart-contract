pragma solidity ^0.8.20;

import "./Campaign.sol";

contract CampaignFactory {
    address[] public deployedCampaigns;
    address public immutable idrxTokenAddress;
    address public immutable verifundSBTAddress;

    constructor(address _idrxTokenAddress, address _verifundSBTAddress) {
        require(_idrxTokenAddress != address(0), "Invalid IDRX token address");
        require(_verifundSBTAddress != address(0), "Invalid VerifundSBT address");
        idrxTokenAddress = _idrxTokenAddress;
        verifundSBTAddress = _verifundSBTAddress;
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
        uint256 _durationInSeconds,
        string memory _ipfsHash
    ) public {
        require(_targetAmount > 0, "Target must be greater than zero");
        require(_durationInSeconds > 0, "Duration must be greater than zero");
        require(bytes(_ipfsHash).length > 0, "IPFS hash required");
        
        uint256 deadline = block.timestamp + _durationInSeconds;

        Campaign newCampaign = new Campaign(
            msg.sender,
            _name,
            _targetAmount,
            deadline,
            _ipfsHash,
            idrxTokenAddress,
            verifundSBTAddress
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