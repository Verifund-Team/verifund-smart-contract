# Verifund Smart Contract

**Verifund** adalah platform crowdfunding berbasis blockchain yang memungkinkan pengguna untuk membuat kampanye penggalangan dana dengan sistem verifikasi menggunakan Soulbound Token (SBT). Platform ini menggunakan token IDRX sebagai mata uang utama untuk donasi.

## 🏗️ Arsitektur Sistem

Proyek ini terdiri dari 4 smart contract utama:

### 1. **IDRX Token** (`src/IDRX.sol`)
- **Fungsi**: Token ERC20 yang merepresentasikan mata uang Indonesia Rupiah dalam bentuk digital
- **Symbol**: IDRX
- **Decimals**: 2 (mengikuti standar mata uang rupiah)
- **Fitur**:
  - Unlimited minting untuk testing
  - Fungsi `mint10k()` untuk mint 10,000 IDRX dengan cepat
  - Support burning token

### 2. **Campaign** (`src/Campaign.sol`)
- **Fungsi**: Contract individual untuk setiap kampanye crowdfunding
- **Fitur Utama**:
  - Donasi menggunakan token IDRX
  - Target amount dan deadline yang dapat dikonfigurasi
  - Sistem refund otomatis jika target tidak tercapai
  - Metadata campaign disimpan di IPFS
  - Status tracking (Active, Successful, Failed)

### 3. **CampaignFactory** (`src/CampaignFactory.sol`)
- **Fungsi**: Factory contract untuk membuat campaign baru
- **Fitur**:
  - Deploy campaign baru dengan parameter yang dapat dikustomisasi
  - Tracking semua campaign yang telah dibuat
  - Event logging untuk monitoring

### 4. **VerifundSBT** (`src/VerifundSBT.sol`)
- **Fungsi**: Soulbound Token (Non-transferable NFT) untuk verifikasi pengguna
- **Fitur**:
  - Non-transferable badge verification
  - Whitelist system untuk kontrol akses
  - Metadata disimpan di IPFS
  - Satu badge per address

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
Buat file `.env` di root directory:
```bash
PRIVATE_KEY=your_private_key_here
ETHERSCAN_KEY=your_etherscan_api_key
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

### Run Tests dengan Gas Report
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
forge script script/DeployCampaignFactory.s.sol:DeployCampaignFactory --rpc-url http://localhost:8545 --private-key <your_private_key> --broadcast
```

### Testnet Deployment (Lisk Sepolia)

```bash
forge script script/Deploy.s.sol:DeployIDRX --rpc-url lisk_sepolia --private-key $PRIVATE_KEY --broadcast --verify
```

## 📋 Smart Contract Addresses

### Lisk Sepolia Testnet
- **IDRX Token**: `[Akan diupdate setelah deployment]`
- **VerifundSBT**: `[Akan diupdate setelah deployment]`
- **CampaignFactory**: `[Akan diupdate setelah deployment]`

## 🔄 Workflow Platform

### 1. Setup Awal
1. Deploy IDRX token
2. Deploy VerifundSBT dengan base URI metadata
3. Deploy CampaignFactory dengan address IDRX token

### 2. Verifikasi Pengguna
1. Admin menambahkan address ke whitelist VerifundSBT
2. User claim badge verifikasi mereka
3. Badge menjadi proof of verification (non-transferable)

### 3. Membuat Campaign
1. User membuat campaign melalui CampaignFactory
2. Set target amount, duration, dan IPFS hash untuk metadata
3. Campaign contract otomatis ter-deploy

### 4. Donasi & Pencairan
1. Donor melakukan approve IDRX ke campaign contract
2. Donor memanggil fungsi `donate()` dengan jumlah IDRX
3. Jika target tercapai: Owner bisa withdraw setelah deadline
4. Jika target tidak tercapai: Donor bisa refund setelah deadline

## 🧪 Testing

Project ini menggunakan Foundry untuk testing. Test files tersedia di folder `test/`:

- `CampaignFactory.t.sol` - Test untuk factory contract
- `VerifundSBT.t.sol` - Test untuk SBT verification
- `IDRX.t.sol` - Test untuk IDRX token
- `Counter.t.sol` - Template test

### Run Specific Test
```bash
forge test --match-contract CampaignFactoryTest
forge test --match-test testCreateCampaign
```

## 📚 Integration Guide

### Frontend Integration

#### Membuat Campaign Baru
```javascript
const campaignFactory = new ethers.Contract(FACTORY_ADDRESS, factoryAbi, signer);
const tx = await campaignFactory.createCampaign(
    "Campaign Name",
    ethers.parseUnits("1000", 2), // Target 1000 IDRX
    30, // 30 days duration
    "QmHash..." // IPFS hash
);
```

#### Donasi ke Campaign
```javascript
const idrx = new ethers.Contract(IDRX_ADDRESS, idrxAbi, signer);
const campaign = new ethers.Contract(CAMPAIGN_ADDRESS, campaignAbi, signer);

// Approve IDRX
await idrx.approve(CAMPAIGN_ADDRESS, donationAmount);

// Donate
await campaign.donate(donationAmount);
```

#### Claim Verification Badge
```javascript
const sbt = new ethers.Contract(SBT_ADDRESS, sbtAbi, signer);
await sbt.klaimLencanaSaya();
```

## 🔐 Security Considerations

1. **Access Control**: SBT menggunakan whitelist system
2. **Time Locks**: Campaign memiliki deadline protection
3. **Reentrancy**: Menggunakan checks-effects-interactions pattern
4. **Token Safety**: Menggunakan OpenZeppelin standard contracts
5. **Non-transferable**: SBT tidak dapat ditransfer untuk menjaga integritas verifikasi

## 🛣️ Roadmap

- [x] Basic crowdfunding functionality
- [x] SBT verification system
- [x] IPFS metadata integration
- [ ] Multi-signature campaign approval
- [ ] Milestone-based fund release
- [ ] Governance token integration
- [ ] Mobile app integration

## 📄 License

MIT License - Lihat file `LICENSE` untuk detail lengkap.

## 🤝 Contributing

1. Fork repository
2. Buat feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## 📞 Support

Untuk pertanyaan dan dukungan, silakan buat issue di repository ini atau hubungi tim development.
