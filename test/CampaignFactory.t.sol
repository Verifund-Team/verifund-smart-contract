// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/CampaignFactory.sol";
import "../src/Campaign.sol";

contract CampaignFactoryTest is Test {
    CampaignFactory public factory;
    address public user = address(1); 
    address public mockToken = address(0x123);

    function setUp() public {
        factory = new CampaignFactory();
    }

    function test_CreateCampaignSuccessfully() public {
        // Kita panggil `createCampaign` dengan 5 argumen, termasuk alamat token
        vm.prank(user);
        factory.createCampaign(
            "Kampanye Kemanusiaan",
            100 ether,
            30,
            "ipfs_hash_xyz",
            mockToken
        );

        // Cek apakah jumlah kampanye yang dibuat sudah benar (1)
        assertEq(factory.getDeployedCampaign().length, 1, "Jumlah kampanye seharusnya 1");

        // Ambil alamat kontrak kampanye yang baru dibuat
        address newCampaignAddress = factory.getDeployedCampaign()[0];
        
        // Pastikan alamatnya valid
        assertNotEq(newCampaignAddress, address(0), "Alamat kampanye tidak boleh nol");

        // Buat instance dari kontrak kampanye untuk mengecek isinya
        Campaign newCampaign = Campaign(newCampaignAddress);

        // Cek semua data apakah sudah tersimpan dengan benar
        assertEq(newCampaign.owner(), user, "Pemilik kampanye salah");
        assertEq(newCampaign.name(), "Kampanye Kemanusiaan", "Nama kampanye salah");
        assertEq(newCampaign.targetAmount(), 100 ether, "Target dana salah");
        assertEq(address(newCampaign.token()), mockToken, "Alamat token salah");
    }
}