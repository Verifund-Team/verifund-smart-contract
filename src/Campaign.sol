pragma solidity ^0.8.20;

contract Campaign {
  address public owner;
  string public name;
  uint256 public targetAmount;
  uint256 public deadline;
  uint256 public amountRaised;
  string public ipfsHash; 

  event Donated(address indexed donor, uint256 amount);

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
    emit Donated(msg.sender, msg.value);
  }
  
}