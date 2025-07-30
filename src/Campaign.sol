pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVerifundSBT {
    function isVerified(address _user) external view returns (bool);
}

contract Campaign {
    address public immutable owner;
    string public name;
    uint256 public immutable targetAmount;
    uint256 public immutable deadline;
    string public ipfsHash;
    IERC20 public immutable token;
    IVerifundSBT public immutable verifundSBT;

    uint256 public amountRaised;
    uint256 public peakBalance;
    bool public isWithdrawn;
    bool public peakBalanceUpdated;
    mapping(address => uint256) public donations;

    event Donated(address indexed donor, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);
    event Refunded(address indexed donor, uint256 amount);
    event IDRXDonationSynced(uint256 amount);
    event PeakBalanceUpdated(uint256 peakBalance);

    modifier onlyOwner() {
        require(msg.sender == owner, "Campaign: Caller is not the owner");
        _;
    }

    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Campaign: Deadline has passed");
        _;
    }

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

        bool targetReached = actualBalance >= targetAmount;
        bool ownerVerified = verifundSBT.isVerified(owner);

        require(targetReached || ownerVerified, "Campaign: Target not reached and owner not verified");

        isWithdrawn = true;

        require(token.transfer(owner, actualBalance), "Campaign: Token transfer to owner failed");

        emit Withdrawn(owner, actualBalance);
    }

    function refund() external afterDeadline {
        uint256 actualBalance = token.balanceOf(address(this));
        bool targetReached = actualBalance >= targetAmount;
        bool ownerVerified = verifundSBT.isVerified(owner);

        require(!targetReached, "Campaign: Target was met");
        require(!ownerVerified, "Campaign: Owner is verified and can withdraw");
        require(!isWithdrawn, "Campaign: Owner already withdrew");

        uint256 donatedAmount = donations[msg.sender];
        require(donatedAmount > 0, "Campaign: No donations to refund");

        donations[msg.sender] = 0;
        amountRaised -= donatedAmount;

        require(token.transfer(msg.sender, donatedAmount), "Campaign: Refund transfer failed");

        emit Refunded(msg.sender, donatedAmount);
    }

    function getRemainingTime() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    enum CampaignStatus {
        Active,
        Successful,
        Failed,
        VerifiedWithdrawable
    }

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

        if (isWithdrawn && peakBalanceUpdated) {
            displayBalance = peakBalance;
        } else {
            displayBalance = token.balanceOf(address(this));
        }

        return (owner, name, targetAmount, amountRaised, displayBalance, getRemainingTime(), getStatus());
    }

    function getPeakBalance() external view returns (uint256) {
        return peakBalance;
    }

    function isPeakBalanceUpdated() external view returns (bool) {
        return peakBalanceUpdated;
    }
}
