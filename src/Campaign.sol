pragma solidity ^0.8.20;

contract Campaign {
  address public owner;
  string public name;
  uint256 public targetAmount;
  uint256 public deadline;
  uint256 public amountRaised;
  string public ipfsHash; 

  event Donated(address indexed donor, uint256 amount);
  event Withdraw(address indexed donor, uint256 amount);

  mapping(address => uint256) public donations;

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
    string memory _ipfsHash
  ) {
    require(_owner != address(0), "Campaign: Owner cannot be the zero address");
    require(_deadline > block.timestamp, "Campaign: Deadline must be in the future");

    owner = _owner;
    name = _name;
    targetAmount = _targetAmount;
    deadline = _deadline;
    ipfsHash = _ipfsHash;
  }

  function donate() public payable beforeDeadline {
    require(msg.value > 0, "Campaign: Donation must be greater than zero");
    amountRaised += msg.value;
    donations[msg.sender] += msg.value;
    emit Donated(msg.sender, msg.value);
  }

  function refund() public afterDeadline {
    require(amountRaised < targetAmount, "Target was met");
    uint256 donatedAmount = donations[msg.sender];
    require(donatedAmount > 0, "No donations to refund");

    donations[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: donatedAmount}("");
    require(success, "Refund failed"); 
  }
  
  function withdraw() public onlyOwner afterDeadline {
    uint256 balance = address(this).balance;
    require(amountRaised >= targetAmount, "Target not reached");
    require(balance > 0, "Campaign: No funds to withdraw");

    (bool success,) = owner.call{value: balance}("");
    require(success, "Campaign: Fund transfer failed");

    emit Withdraw(owner, balance);
  }

  function getRemainingTime() public view returns(uint256) {
    if(block.timestamp >= deadline) {
      return 0;
    }
    return deadline - block.timestamp;
  }

  enum campaignStatus {Active, Successful, Failed}
  function getStatus() public view returns (campaignStatus) {
    if (block.timestamp < deadline) {
      return campaignStatus.Active;
    } else if (amountRaised >= targetAmount) {
      return campaignStatus.Successful;
    } else {
      return campaignStatus.Failed;
    }
  }

  receive() external payable {
      donate();
  }
}