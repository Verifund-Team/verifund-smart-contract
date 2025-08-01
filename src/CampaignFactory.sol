// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Campaign.sol";

/**
 * @title CampaignFactory
 * @dev Factory contract for creating and managing Campaign contracts.
 * This contract serves as the central deployment point for all campaigns in the Verifund platform.
 * Features include:
 * - Automated campaign deployment with standardized parameters
 * - Integration with IDRX token and VerifundSBT verification system
 * - Campaign registry and tracking
 * - Event logging for monitoring and indexing
 * - Validation of campaign parameters before deployment
 */
contract CampaignFactory {
    /// @notice Array of all deployed campaign contract addresses
    /// @dev Stores addresses of all campaigns created through this factory for easy retrieval and tracking
    address[] public deployedCampaigns;
    
    /// @notice Address of the IDRX token contract used for all campaigns
    /// @dev Immutable address set during deployment, ensures all campaigns use the same token standard
    address public immutable idrxTokenAddress;
    
    /// @notice Address of the VerifundSBT contract for verification functionality
    /// @dev Immutable address that enables campaigns to check owner verification status
    address public immutable verifundSBTAddress;

    /**
     * @notice Initializes the CampaignFactory with required contract addresses.
     * @param _idrxTokenAddress Address of the IDRX ERC20 token contract.
     * @param _verifundSBTAddress Address of the VerifundSBT contract for user verification.
     * @dev Both addresses are validated to ensure they are not zero addresses.
     * @dev These addresses are immutable and cannot be changed after deployment.
     */
    constructor(address _idrxTokenAddress, address _verifundSBTAddress) {
        require(_idrxTokenAddress != address(0), "Invalid IDRX token address");
        require(_verifundSBTAddress != address(0), "Invalid VerifundSBT address");
        idrxTokenAddress = _idrxTokenAddress;
        verifundSBTAddress = _verifundSBTAddress;
    }

    /**
     * @notice Emitted when a new campaign is successfully created.
     * @param campaignAddress The address of the newly deployed campaign contract.
     * @param owner The address of the campaign owner who initiated the creation.
     * @param name The name/title of the campaign.
     * @param targetAmount The fundraising target amount in IDRX tokens.
     * @param deadline The Unix timestamp when the campaign ends.
     * @param ipfsHash The IPFS hash containing campaign metadata and details.
     */
    event CampaignCreated(
        address indexed campaignAddress,
        address indexed owner,
        string name,
        uint256 targetAmount,
        uint256 deadline,
        string ipfsHash
    );

    /**
     * @notice Creates a new crowdfunding campaign with specified parameters.
     * @param _name The name/title of the campaign (stored in campaign metadata).
     * @param _targetAmount The fundraising target amount in IDRX tokens (must be > 0).
     * @param _durationInSeconds Campaign duration in seconds from current timestamp.
     * @param _ipfsHash IPFS hash containing detailed campaign information and media.
     * @dev Requirements:
     * - Target amount must be greater than zero
     * - Duration must be greater than zero
     * - IPFS hash must not be empty
     * @dev Effects:
     * - Deploys a new Campaign contract with msg.sender as owner
     * - Adds the new campaign address to deployedCampaigns array
     * - Emits CampaignCreated event for indexing and monitoring
     * @dev The deadline is calculated as current timestamp + duration
     */
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

        Campaign newCampaign =
            new Campaign(msg.sender, _name, _targetAmount, deadline, _ipfsHash, idrxTokenAddress, verifundSBTAddress);

        deployedCampaigns.push(address(newCampaign));

        emit CampaignCreated(address(newCampaign), msg.sender, _name, _targetAmount, deadline, _ipfsHash);
    }

    /**
     * @notice Returns an array of all deployed campaign contract addresses.
     * @return Array of campaign contract addresses created by this factory.
     * @dev This function allows frontend applications to retrieve all campaigns for display.
     * @dev The array includes all campaigns regardless of their current status.
     */
    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}