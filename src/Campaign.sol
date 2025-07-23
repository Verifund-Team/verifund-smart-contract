pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Campaign {
  enum CampaignCategory {
        Pendidikan, // value = 0
        Kesehatan,  // value = 1
        Lingkungan, // value = 2
        BencanaAlam,// value = 3
        Sosial,     // value = 4
        Lainnya     // value = 5
    }


  address public owner;
  string public name;
  uint256 public targetAmount;
  uint256 public deadline;
  uint256 public amountRaised;
  string public ipfsHash; 

  CampaignCategory public immutable category;
  IERC20 public token;
  mapping(address => uint256) public donations;

  event Donated(address indexed donor, uint256 amount);
  event Withdraw(address indexed donor, uint256 amount);
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
    address _tokenAddress,
    CampaignCategory _category
  ) {
    require(_owner != address(0), "Campaign: Owner cannot be the zero address");
    require(_deadline > block.timestamp, "Campaign: Deadline must be in the future");
    require(_tokenAddress != address(0), "Campaign: Invalid token address");

    owner = _owner;
    name = _name;
    targetAmount = _targetAmount;
    deadline = _deadline;
    ipfsHash = _ipfsHash;
    token = IERC20(_tokenAddress);
    category = _category;
  }

  function donate(uint256 _amount) public payable beforeDeadline {
    require(_amount > 0, "Campaign: Donation must be greater than zero");
    require(
      token.transferFrom(msg.sender, address(this), _amount),
      "Campaign: Token transfer failed"
    );

    amountRaised += _amount;
    donations[msg.sender] += _amount;

    emit Donated(msg.sender, _amount);
  }

  function withdraw() public onlyOwner afterDeadline {
      require(amountRaised >= targetAmount, "Target not reached");

      uint256 tokenBalance = token.balanceOf(address(this));
      require(tokenBalance > 0, "Campaign: No funds to withdraw");

      require(
          token.transfer(owner, tokenBalance),
          "Campaign: Token transfer to owner failed"
      );

      emit Withdraw(owner, tokenBalance);
  }

  function refund() public afterDeadline {
    require(amountRaised < targetAmount, "Target was met");

    uint256 donatedAmount = donations[msg.sender];
    require(donatedAmount > 0, "No donations to refund");

    donations[msg.sender] = 0;

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
}