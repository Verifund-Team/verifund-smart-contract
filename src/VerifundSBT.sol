// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VerifundSBT is ERC721, Ownable {
    mapping(address => bool) public isWhitelisted;

    string private _baseTokenURI;
    uint256 public totalSupply;

    event LencanaDiklaim(address indexed pengguna, uint256 indexed tokenId);
    event BaseURIUpdated(string newBaseURI);

    constructor(string memory baseURI) ERC721("Verifund Verified Badge", "VVB") Ownable(msg.sender) {
        _baseTokenURI = baseURI;
    }

    function beriIzinMint(address _user) external onlyOwner {
        require(_user != address(0), "Verifund: Alamat tidak valid");
        isWhitelisted[_user] = true;
    }

    function klaimLencanaSaya() external {
        require(isWhitelisted[msg.sender] == true, "Verifund: Anda tidak memiliki izin untuk klaim.");

        uint256 tokenId = uint256(uint160(msg.sender));
        require(_ownerOf(tokenId) == address(0), "Verifund: Lencana sudah pernah diklaim.");

        isWhitelisted[msg.sender] = false;
        _safeMint(msg.sender, tokenId);
        totalSupply++;

        emit LencanaDiklaim(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Verifund: Token tidak exists");

        return _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        require(from == address(0), "Verifund: Lencana ini tidak bisa ditransfer.");
        return super._update(to, tokenId, auth);
    }

    function approve(address, uint256) public pure override {
        revert("Verifund: Token tidak dapat di-approve karena non-transferabel.");
    }

    function setApprovalForAll(address, bool) public pure override {
        revert("Verifund: Token tidak dapat di-approve karena non-transferabel.");
    }

    function isVerified(address _user) external view returns (bool) {
        uint256 tokenId = uint256(uint160(_user));
        return _ownerOf(tokenId) != address(0);
    }

    function hapusIzinMint(address _user) external onlyOwner {
        isWhitelisted[_user] = false;
    }

    function getBadgeInfo(address _user)
        external
        view
        returns (bool hasWhitelistPermission, bool isCurrentlyVerified, uint256 tokenId, string memory metadataURI)
    {
        tokenId = uint256(uint160(_user));
        hasWhitelistPermission = isWhitelisted[_user];
        isCurrentlyVerified = _ownerOf(tokenId) != address(0);
        metadataURI = isCurrentlyVerified ? tokenURI(tokenId) : "";
    }
}
