# Verifund Smart Contract

**Verifund** is a blockchain-based crowdfunding platform that allows users to create fundraising campaigns with verification systems using Soulbound Tokens (SBT). The platform uses IDRX tokens as the primary currency for donations.

## 🏗️ System Architecture

The project consists of 4 main smart contracts:

### 1. **IDRX Token** (`src/IDRX.sol`)
- **Function**: ERC20 token that represents the Indonesian Rupiah currency in digital form
- **Symbol**: IDRX
- **Decimals**: 2 (following the Rupiah currency standard)
- **Features**:
  - Unlimited minting for testing
  - `mint10k()` function for quick minting of 10,000 IDRX
  - Support for burning tokens

### 2. **Campaign** (`src/Campaign.sol`)
- **Function**: Individual contract for each crowdfunding campaign
- **Main Features**:
  - Donations using IDRX tokens
  - Configurable target amount and deadline
  - Automatic refund system if the target is not achieved
  - Campaign metadata is stored on IPFS
  - Status tracking (Active, Successful, Failed, VerifiedWithdrawable)
  - IDRX donation synchronization for external transfers
  - Comprehensive campaign information retrieval
  - **Verification-based withdrawal**: Verified owners can withdraw funds even if target not reached
  - Integration with VerifundSBT for owner verification status

### 3. **CampaignFactory** (`src/CampaignFactory.sol`)
- **Function**: Factory contract to create new campaigns
- **Features**:
  - Deploy new campaigns with customizable parameters
  - Track all created campaigns
  - Event logging for monitoring
  - Automatic linking of campaigns with verification contract

### 4. **VerifundSBT** (`src/VerifundSBT.sol`)
- **Function**: Soulbound Token (Non-transferable NFT) for user verification
- **Features**:
  - Non-transferable badge verification
  - Whitelist system for access control
  - Metadata stored on IPFS
  - One badge per address

## 🚀 Setup & Installation

### Prerequisites
- [Node.js](https://nodejs.org/) >= 16
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Installation

1. **Clone repository**
```bash
git clone <repository-url>
cd verifund-smart-contract
```

2. **Install dependencies**
```bash
forge install
```

3. **Setup environment variables**
Create a `.env` file in the root directory (you can copy from `.env.example`):
```bash
PRIVATE_KEY=your_private_key_here
ETHERSCAN_KEY=your_etherscan_api_key
IDRX_TOKEN_ADDRESS=deployed_idrx_token_address
CAMPAIGN_FACTORY_ADDRESS=deployed_campaign_factory_address
VERIFUND_SBT_ADDRESS=deployed_verifund_sbt_address
```

## 🔧 Development Commands

### Build Contract
```bash
forge build
```

### Run Tests
```bash
forge test
```

### Run Tests with Gas Report
```bash
forge test --gas-report
```

### Format Code
```bash
forge fmt
```

### Generate Gas Snapshots
```bash
forge snapshot
```

## 🌐 Deployment

### Local Development (Anvil)

1. **Start local node**
```bash
anvil
```

2. **Deploy IDRX Token**
```bash
forge script script/Deploy.s.sol:DeployIDRX --rpc-url http://localhost:8545 --private-key <your_private_key> --broadcast
```

3. **Deploy VerifundSBT**
```bash
forge script script/DeployVerifundSBT.s.sol:DeployVerifundSBT --rpc-url http://localhost:8545 --private-key <your_private_key> --broadcast
```

4. **Deploy CampaignFactory**
```bash
# Make sure IDRX_TOKEN_ADDRESS and VERIFUND_SBT_ADDRESS are set in .env
forge script script/DeployCampaignFactory.s.sol:DeployCampaignFactory --rpc-url http://localhost:8545 --private-key <your_private_key> --broadcast
```

### Testnet Deployment (Lisk Sepolia)

```bash
forge script script/Deploy.s.sol:DeployIDRX --rpc-url lisk_sepolia --private-key $PRIVATE_KEY --broadcast --verify
```

## 📋 Smart Contract Addresses

### Lisk Sepolia Testnet
- **IDRX Token**: `0x31c0C6e0F048d259Cd8597e1e3594F842555b235`
- **VerifundSBT**: `0x388878A2e2c404a2567c070a4C39D9A75EFFeb61`
- **CampaignFactory**: `0x5fc7BB8359fE43Ad330711708A573b9A502f0534`

### Lisk Mainnet
- **IDRX Token**: `0x18Bc5bcC660cf2B9cE3cd51a404aFe1a0cBD3C22` (Official IDRX)
- **VerifundSBT**: `0x3eb9972beA8f2fDE0C011c77E432f3706078E65E`
- **CampaignFactory**: `0x72c4C531d16458622Fbd3B050923a1A2c7E69E3E`

## 🔄 Platform Workflow

### 1. Initial Setup
1. Deploy IDRX token
2. Deploy VerifundSBT with base URI metadata
3. Deploy CampaignFactory with both IDRX token address and VerifundSBT address
4. Set environment variables with deployed contract addresses

### 2. User Verification
1. Admin adds address to VerifundSBT whitelist
2. User claims their verification badge
3. Badge becomes proof of verification (non-transferable)

### 3. Creating Campaign
1. User creates a campaign via CampaignFactory
2. Set target amount, duration, and IPFS hash for metadata
3. Campaign contract is automatically deployed

### 4. Donation & Withdrawal
1. Donor approves IDRX to campaign contract
2. Donor calls `donate()` function with IDRX amount
3. **Withdrawal conditions after deadline**:
   - If target achieved: Owner can withdraw
   - If target not achieved BUT owner is verified: Owner can still withdraw
   - If target not achieved AND owner not verified: Donors can request refunds
4. **Refund conditions**: Available only when target not reached AND owner not verified

## 🧪 Testing

This project uses Foundry for testing. Test files are available in the `test/` folder:

- `CampaignFactory.t.sol` - Test for factory contract
- `VerifundSBT.t.sol` - Test for SBT verification
- `IDRX.t.sol` - Test for IDRX token

### Run Specific Test
```bash
forge test --match-contract CampaignFactoryTest
forge test --match-test testCreateCampaign
```

## 📚 Integration Guide

### Frontend Integration

#### Create a New Campaign
```javascript
const campaignFactory = new ethers.Contract(FACTORY_ADDRESS, factoryAbi, signer);
const tx = await campaignFactory.createCampaign(
    "Campaign Name",
    ethers.parseUnits("1000", 2), // Target 1000 IDRX
    2592000, // 30 days duration in seconds (30 * 24 * 60 * 60)
    "QmHash..." // IPFS hash
);

// Note: CampaignFactory automatically integrates with VerifundSBT for verification
```

#### Donate to Campaign
```javascript
const idrx = new ethers.Contract(IDRX_ADDRESS, idrxAbi, signer);
const campaign = new ethers.Contract(CAMPAIGN_ADDRESS, campaignAbi, signer);

// Approve IDRX
await idrx.approve(CAMPAIGN_ADDRESS, donationAmount);

// Donate
await campaign.donate(donationAmount);
```

#### Sync External IDRX Donations
```javascript
const campaign = new ethers.Contract(CAMPAIGN_ADDRESS, campaignAbi, signer);

// Sync donations that were sent directly to campaign contract
await campaign.syncIDRXDonations();
```

#### Get Campaign Information
```javascript
const campaign = new ethers.Contract(CAMPAIGN_ADDRESS, campaignAbi, signer);

// Get comprehensive campaign info
const [owner, name, target, raised, actualBalance, timeRemaining, status] = 
    await campaign.getCampaignInfo();

// Check campaign status (now includes VerifiedWithdrawable)
// Status: 0=Active, 1=Successful, 2=Failed, 3=VerifiedWithdrawable
const status = await campaign.getStatus();
```

#### Claim Verification Badge
```javascript
const sbt = new ethers.Contract(SBT_ADDRESS, sbtAbi, signer);
await sbt.klaimLencanaSaya();
```

## 🔐 Security Considerations

1. **Access Control**: SBT uses a whitelist system
2. **Time Locks**: Campaigns have deadline protections
3. **Reentrancy**: Uses checks-effects-interactions pattern
4. **Token Safety**: Uses OpenZeppelin standard contracts
5. **Non-transferable**: SBT cannot be transferred to maintain verification integrity
6. **Verification Integration**: Campaign withdrawal logic integrates with SBT verification status
7. **Dual Withdrawal Logic**: Protects both verified and unverified campaign owners appropriately

## 🛣️ Roadmap

- [x] Basic crowdfunding functionality
- [x] SBT verification system
- [x] IPFS metadata integration
- [x] **Verification-based withdrawal system**
- [x] **Enhanced campaign status tracking**
- [ ] Multi-signature campaign approval
- [ ] Milestone-based fund release
- [ ] Governance token integration

## 📄 License

MIT License - See `LICENSE` file for full details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For questions and support, please create an issue in this repository or contact the development team.
