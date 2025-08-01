// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IVerifundSBT
 * @dev Interface for interacting with the VerifundSBT contract to check user verification status.
 * This interface allows campaigns to verify if a user has a valid verification badge.
 */
interface IVerifundSBT {
    /**
     * @notice Checks if a user has been verified (owns an SBT token).
     * @param _user The address of the user to check.
     * @return verified True if the user is verified, false otherwise.
     */
    function isVerified(address _user) external view returns (bool);
}

/**
 * @title Campaign
 * @dev Individual crowdfunding campaign contract that handles donations, withdrawals, and refunds.
 * Features include:
 * - IDRX token-based donations with automatic tracking
 * - Deadline-based campaign lifecycle management
 * - Verification-based withdrawal system using VerifundSBT
 * - Automatic refund mechanism for failed campaigns
 * - Peak balance tracking for external transfers
 * - Comprehensive campaign status and information retrieval
 */
contract Campaign {
    /// @notice The address of the campaign owner who can withdraw funds
    /// @dev Immutable address set during contract deployment, cannot be changed
    address public immutable owner;
    
    /// @notice The name/title of the campaign
    /// @dev Can be updated if needed, stored for display purposes
    string public name;
    
    /// @notice The target fundraising amount in IDRX tokens
    /// @dev Immutable value set during deployment, represents the funding goal
    uint256 public immutable targetAmount;
    
    /// @notice The Unix timestamp when the campaign ends
    /// @dev Immutable deadline after which donations are no longer accepted
    uint256 public immutable deadline;
    
    /// @notice IPFS hash containing campaign metadata and detailed information
    /// @dev Contains campaign description, images, and other relevant data
    string public ipfsHash;
    
    /// @notice The IDRX token contract interface for handling donations
    /// @dev Immutable ERC20 token used for all campaign transactions
    IERC20 public immutable token;
    
    /// @notice The VerifundSBT contract interface for checking owner verification
    /// @dev Used to determine if campaign owner is verified for withdrawal privileges
    IVerifundSBT public immutable verifundSBT;

    /// @notice Total amount raised through the donate() function
    /// @dev Tracks donations made through the official donate function
    uint256 public amountRaised;
    
    /// @notice Highest balance recorded before any withdrawals
    /// @dev Used to track the maximum funds available, especially for external transfers
    uint256 public peakBalance;
    
    /// @notice Flag indicating whether funds have been withdrawn by the owner
    /// @dev Prevents multiple withdrawals and enables proper refund logic
    bool public isWithdrawn;
    
    /// @notice Flag indicating whether peak balance has been manually updated
    /// @dev Required for campaigns with external IDRX transfers before withdrawal
    bool public peakBalanceUpdated;
    
    /// @notice Mapping of donor addresses to their total donation amounts
    /// @dev Used for refund calculations and tracking individual contributions
    mapping(address => uint256) public donations;

    /// @notice Emitted when a donation is made to the campaign
    /// @param donor Address of the donor
    /// @param amount Amount donated in IDRX tokens
    event Donated(address indexed donor, uint256 amount);
    
    /// @notice Emitted when the owner withdraws funds
    /// @param owner Address of the campaign owner
    /// @param amount Amount withdrawn in IDRX tokens
    event Withdrawn(address indexed owner, uint256 amount);
    
    /// @notice Emitted when a donor receives a refund
    /// @param donor Address of the donor receiving refund
    /// @param amount Amount refunded in IDRX tokens
    event Refunded(address indexed donor, uint256 amount);
    
    /// @notice Emitted when external IDRX donations are synchronized
    /// @param amount Amount of unrecorded donations found and added
    event IDRXDonationSynced(uint256 amount);
    
    /// @notice Emitted when peak balance is updated
    /// @param peakBalance The peak balance amount recorded
    event PeakBalanceUpdated(uint256 peakBalance);

    /// @dev Ensures only the campaign owner can call the function
    modifier onlyOwner() {
        require(msg.sender == owner, "Campaign: Caller is not the owner");
        _;
    }

    /// @dev Ensures the function can only be called before the campaign deadline
    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Campaign: Deadline has passed");
        _;
    }

    /// @dev Ensures the function can only be called after the campaign deadline
    modifier afterDeadline() {
        require(block.timestamp >= deadline, "Campaign: Deadline has not been reached yet");
        _;
    }

    constructor(
        address _owner,
        string memory _name,
        uint256 _targetAmount,
        uint256 _deadline,
        string memory _ipfsHash,
        address _tokenAddress,
        address _verifundSBTAddress
    ) {
        require(_owner != address(0), "Campaign: Owner cannot be the zero address");
        require(_deadline > block.timestamp, "Campaign: Deadline must be in the future");
        require(_tokenAddress != address(0), "Campaign: Invalid token address");
        require(_verifundSBTAddress != address(0), "Campaign: Invalid VerifundSBT address");
        require(_targetAmount > 0, "Campaign: Target must be greater than zero");

        owner = _owner;
        name = _name;
        targetAmount = _targetAmount;
        deadline = _deadline;
        ipfsHash = _ipfsHash;
        token = IERC20(_tokenAddress);
        verifundSBT = IVerifundSBT(_verifundSBTAddress);
    }

    function donate(uint256 _amount) external beforeDeadline {
        require(_amount > 0, "Campaign: Donation must be greater than zero");
        require(token.transferFrom(msg.sender, address(this), _amount), "Campaign: Token transfer failed");

        amountRaised += _amount;
        donations[msg.sender] += _amount;

        emit Donated(msg.sender, _amount);
    }

    function syncIDRXDonations() external {
        uint256 currentBalance = token.balanceOf(address(this));

        if (currentBalance > amountRaised) {
            uint256 unrecordedAmount = currentBalance - amountRaised;
            amountRaised += unrecordedAmount;

            emit IDRXDonationSynced(unrecordedAmount);
        }
    }

    function updatePeakBalance() external onlyOwner {
        require(!isWithdrawn, "Campaign: Funds already withdrawn");
        require(!peakBalanceUpdated, "Campaign: Peak balance already updated");

        uint256 currentBalance = token.balanceOf(address(this));
        peakBalance = currentBalance;
        peakBalanceUpdated = true;

        emit PeakBalanceUpdated(peakBalance);
    }

    function withdraw() external onlyOwner afterDeadline {
        uint256 actualBalance = token.balanceOf(address(this));
        require(!isWithdrawn, "Campaign: Funds already withdrawn");
        require(actualBalance > 0, "Campaign: No funds to withdraw");

        if (actualBalance > amountRaised) {
            require(
                peakBalanceUpdated, "Campaign: Must update peak balance before withdrawal due to external transfers"
            );
        } else {
            if (!peakBalanceUpdated) {
                peakBalance = actualBalance;
                peakBalanceUpdated = true;
                emit PeakBalanceUpdated(peakBalance);
            }
        }

        // Check if campaign target has been reached or if owner is verified
        bool targetReached = actualBalance >= targetAmount;
        bool ownerVerified = verifundSBT.isVerified(owner);

        // Ensure that funds can only be withdrawn if target is met or owner is verified
        require(targetReached || ownerVerified, "Campaign: Target not reached and owner not verified");

        // Mark funds as withdrawn
        isWithdrawn = true;

        // Transfer funds to the owner
        require(token.transfer(owner, actualBalance), "Campaign: Token transfer to owner failed");

        // Emit withdrawal event
        emit Withdrawn(owner, actualBalance);
    }

    /**
     * @notice Refund donations to contributors if campaign fails.
     * @dev Only callable after deadline if target is not reached and owner is not verified.
     * @dev Transfers back the original donated amount to each donor.
     * @dev Emits a Refunded event for each transaction processed.
     */
    function refund() external afterDeadline {
        uint256 actualBalance = token.balanceOf(address(this));
        bool targetReached = actualBalance >= targetAmount;
        bool ownerVerified = verifundSBT.isVerified(owner);

        // Require that target has not been reached
        require(!targetReached, "Campaign: Target was met");
        // Require that owner is not verified
        require(!ownerVerified, "Campaign: Owner is verified and can withdraw");
        // Ensure the funds have not been withdrawn yet
        require(!isWithdrawn, "Campaign: Owner already withdrew");

        // Get donation amount for the sender
        uint256 donatedAmount = donations[msg.sender];
        require(donatedAmount > 0, "Campaign: No donations to refund");

        // Reset donation balance and adjust the amount raised
        donations[msg.sender] = 0;
        amountRaised -= donatedAmount;

        // Transfer the donated amount back to the sender
        require(token.transfer(msg.sender, donatedAmount), "Campaign: Refund transfer failed");

        // Emit refund event
        emit Refunded(msg.sender, donatedAmount);
    }

    /**
     * @notice Calculate the remaining time until the campaign's deadline.
     * @return timeRemaining Number of seconds left until the deadline (0 if passed).
     */
    function getRemainingTime() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    /**
     * @notice Enum representing the possible status of the campaign.
     * @dev Active: Campaign is ongoing.
     *      Successful: Campaign ended with the target reached.
     *      Failed: Campaign ended without reaching target and is not withdrawable.
     *      VerifiedWithdrawable: Campaign ended without reaching target, but owner is verified so they can still withdraw.
     */
    enum CampaignStatus {
        Active,
        Successful,
        Failed,
        VerifiedWithdrawable
    }

    /**
     * @notice Determine the current status of the campaign based on the deadline and fund levels.
     * @return status The current status of the campaign represented by the CampaignStatus enum.
     */
    function getStatus() public view returns (CampaignStatus) {
        if (block.timestamp < deadline) {
            return CampaignStatus.Active;
        } else {
            uint256 actualBalance = token.balanceOf(address(this));
            if (actualBalance >= targetAmount) {
                return CampaignStatus.Successful;
            } else {
                bool ownerVerified = verifundSBT.isVerified(owner);
                if (ownerVerified) {
                    return CampaignStatus.VerifiedWithdrawable;
                } else {
                    return CampaignStatus.Failed;
                }
            }
        }
    }

    /**
     * @notice Retrieve comprehensive information about the campaign.
     * @return campaignOwner The address of the campaign owner.
     * @return campaignName The name/title of the campaign.
     * @return target The target fundraising amount in IDRX tokens.
     * @return raised The amount raised through the donate() function.
     * @return actualBalance The current balance of the campaign contract.
     * @return timeRemaining The remaining time until deadline in seconds.
     * @return status The current status of the campaign.
     */
    function getCampaignInfo()
        external
        view
        returns (
            address campaignOwner,
            string memory campaignName,
            uint256 target,
            uint256 raised,
            uint256 actualBalance,
            uint256 timeRemaining,
            CampaignStatus status
        )
    {
        uint256 displayBalance;

        // Determine the balance to display considering peak balance updates
        if (isWithdrawn && peakBalanceUpdated) {
            displayBalance = peakBalance;
        } else {
            displayBalance = token.balanceOf(address(this));
        }

        return (owner, name, targetAmount, amountRaised, displayBalance, getRemainingTime(), getStatus());
    }

    /**
     * @notice Access the peak balance recorded for the campaign contract.
     * @return peakBalance The peak balance in IDRX tokens.
     */
    function getPeakBalance() external view returns (uint256) {
        return peakBalance;
    }

    /**
     * @notice Check whether the peak balance has been updated manually.
     * @return peakBalanceUpdated True if the peak balance has been manually set, false otherwise.
     */
    function isPeakBalanceUpdated() external view returns (bool) {
        return peakBalanceUpdated;
    }
}