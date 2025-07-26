pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Campaign {
    address public immutable owner;
    string public name;
    uint256 public immutable targetAmount;
    uint256 public immutable deadline;
    string public ipfsHash;
    IERC20 public immutable token;
    
    uint256 public amountRaised;
    bool public isWithdrawn;
    mapping(address => uint256) public donations;
    
    event Donated(address indexed donor, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);
    event Refunded(address indexed donor, uint256 amount);
    
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
        address _tokenAddress
    ) {
        require(_owner != address(0), "Campaign: Owner cannot be the zero address");
        require(_deadline > block.timestamp, "Campaign: Deadline must be in the future");
        require(_tokenAddress != address(0), "Campaign: Invalid token address");
        require(_targetAmount > 0, "Campaign: Target must be greater than zero");
        
        owner = _owner;
        name = _name;
        targetAmount = _targetAmount;
        deadline = _deadline;
        ipfsHash = _ipfsHash;
        token = IERC20(_tokenAddress);
    }
    
    function donate(uint256 _amount) external beforeDeadline {
        require(_amount > 0, "Campaign: Donation must be greater than zero");
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Campaign: Token transfer failed"
        );
        
        amountRaised += _amount;
        donations[msg.sender] += _amount;
        
        emit Donated(msg.sender, _amount);
    }
    
    function withdraw() external onlyOwner afterDeadline {
        require(amountRaised >= targetAmount, "Campaign: Target not reached");
        require(!isWithdrawn, "Campaign: Funds already withdrawn");
        
        isWithdrawn = true;
        
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Campaign: No funds to withdraw");
        
        require(
            token.transfer(owner, balance),
            "Campaign: Token transfer to owner failed"
        );
        
        emit Withdrawn(owner, balance);
    }
    
    function refund() external afterDeadline {
        require(amountRaised < targetAmount, "Campaign: Target was met");
        require(!isWithdrawn, "Campaign: Owner already withdrew");
        
        uint256 donatedAmount = donations[msg.sender];
        require(donatedAmount > 0, "Campaign: No donations to refund");
        
        donations[msg.sender] = 0;
        amountRaised -= donatedAmount;
        
        require(
            token.transfer(msg.sender, donatedAmount),
            "Campaign: Refund transfer failed"
        );
        
        emit Refunded(msg.sender, donatedAmount);
    }
    
    function getRemainingTime() public view returns(uint256) {
        if(block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
    
    enum CampaignStatus {Active, Successful, Failed}
    function getStatus() public view returns (CampaignStatus) {
        if (block.timestamp < deadline) {
            return CampaignStatus.Active;
        } else if (amountRaised >= targetAmount) {
            return CampaignStatus.Successful;
        } else {
            return CampaignStatus.Failed;
        }
    }
    
    function getCampaignInfo() external view returns (
        address campaignOwner,
        string memory campaignName,
        uint256 target,
        uint256 raised,
        uint256 timeRemaining,
        CampaignStatus status
    ) {
        return (
            owner,
            name,
            targetAmount,
            amountRaised,
            getRemainingTime(),
            getStatus()
        );
    }
}