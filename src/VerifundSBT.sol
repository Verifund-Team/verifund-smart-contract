// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title VerifundSBT
 * @dev Soulbound Token (SBT) contract for user verification in the Verifund platform.
 * This contract implements a non-transferable NFT system for identity verification.
 * Features include:
 * - Non-transferable verification badges (Soulbound Tokens)
 * - Whitelist-based permission system for badge claiming
 * - One-time claiming mechanism per address
 * - Metadata stored via IPFS with configurable base URI
 * - Administrative controls for managing verification permissions
 * - Badge information retrieval for external contracts
 */
contract VerifundSBT is ERC721, Ownable {
    /// @notice Mapping of whitelisted addresses authorized to claim badges
    /// @dev Only whitelisted addresses can claim the non-transferable badge
    mapping(address => bool) public isWhitelisted;

    /// @notice Base URI for token metadata stored on IPFS
    /// @dev Used to retrieve metadata for each SBT issued to verified users
    string private _baseTokenURI;

    /// @notice Total number of Soulbound Tokens (SBTs) claimed
    /// @dev Tracks the number of badges issued to users across the system
    uint256 public totalSupply;

    /// @notice Emitted when a user successfully claims their badge
    /// @param pengguna Address of the user claiming the badge
    /// @param tokenId Unique ID of the badge issued (based on user address)
    event LencanaDiklaim(address indexed pengguna, uint256 indexed tokenId);

    /// @notice Emitted when the base URI for metadata is updated
    /// @param newBaseURI The new base URI to be used for token metadata
    event BaseURIUpdated(string newBaseURI);

    /**
     * @notice Initializes the VerifundSBT contract with a base URI.
     * @param baseURI The default URI used for all metadata of SBT tokens.
     * @dev Base URI applies to all tokens and can be updated by the owner.
     */
    constructor(string memory baseURI) ERC721("Verifund Verified Badge", "VVB") Ownable(msg.sender) {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Grants minting permission for an address to claim a badge.
     * @param _user The address to be whitelisted for badge claiming.
     * @dev Only callable by the contract owner to control badge distribution.
     * @dev Validates that the user address is not a zero address.
     */
    function beriIzinMint(address _user) external onlyOwner {
        require(_user != address(0), "Verifund: Alamat tidak valid");
        isWhitelisted[_user] = true;
    }

    /**
     * @notice Allows whitelisted users to claim their non-transferable badge.
     * @dev Requirements:
     * - Caller must be whitelisted
     * - Caller must not have previously claimed a badge
     * @dev Effects:
     * - Removes the caller from the whitelist
     * - Mints a unique SBT to the caller's address
     * - Increments the total supply counter
     * - Emits LencanaDiklaim event
     * @dev The token ID is derived from the user's address for uniqueness
     */
    function klaimLencanaSaya() external {
        require(isWhitelisted[msg.sender] == true, "Verifund: Anda tidak memiliki izin untuk klaim.");

        uint256 tokenId = uint256(uint160(msg.sender));
        require(_ownerOf(tokenId) == address(0), "Verifund: Lencana sudah pernah diklaim.");

        isWhitelisted[msg.sender] = false;
        _safeMint(msg.sender, tokenId);
        totalSupply++;

        emit LencanaDiklaim(msg.sender, tokenId);
    }

    /**
     * @notice Returns the metadata URI for a given token ID.
     * @param tokenId The ID of the token to retrieve URI for.
     * @return The base URI containing metadata for the badge.
     * @dev Ensures the specified tokenId corresponds to an existing, owned badge.
     * @dev All tokens share the same base URI since they represent the same verification status.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Verifund: Token tidak exists");

        return _baseTokenURI;
    }

    /**
     * @notice Internal function to access the base URI for ERC721 metadata.
     * @return The baseTokenURI used for resolving token metadata paths.
     * @dev Override of ERC721 internal function to provide custom base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Updates the base URI used for all token metadata.
     * @param newBaseURI The new base URI to be adopted for all badges.
     * @dev Requirements:
     * - Only callable by the contract owner
     * @dev Effects:
     * - Updates the base URI for all existing and future tokens
     * - Emits BaseURIUpdated event
     * @dev This allows updating metadata location (e.g., new IPFS hash) without redeploying
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @dev Internal override to prevent unauthorized transfers of Soulbound Tokens.
     * @param to Intended recipient address of internal transfer call.
     * @param tokenId ID of the badge meant for transfer.
     * @param auth Authorizing address for the transfer (ignored in this implementation).
     * @return The original owner address before the update.
     * @dev This function enforces the "soulbound" property by only allowing minting (from address(0)).
     * @dev Any attempt to transfer existing tokens will revert.
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        require(from == address(0), "Verifund: Lencana ini tidak bisa ditransfer.");
        return super._update(to, tokenId, auth);
    }

    /**
     * @notice Prevents users from approving token transfers (Soulbound Token restriction).
     * @dev Always reverts as approval functionality is disabled for non-transferable tokens.
     * @dev This ensures no third party can be authorized to transfer badges.
     */
    function approve(address, uint256) public pure override {
        revert("Verifund: Token tidak dapat di-approve karena non-transferabel.");
    }

    /**
     * @notice Prevents approval of all tokens for transfers (Soulbound Token restriction).
     * @dev Always reverts as batch approval functionality is also disabled.
     * @dev This ensures no operator can be authorized to transfer any badges.
     */
    function setApprovalForAll(address, bool) public pure override {
        revert("Verifund: Token tidak dapat di-approve karena non-transferabel.");
    }

    /**
     * @notice Checks if a user is verified by confirming their SBT ownership.
     * @param _user The address to check for badge ownership.
     * @return True if the user has been issued and owns a verification badge, false otherwise.
     * @dev This function is used by other contracts (like Campaign) to verify user status.
     * @dev The token ID is derived from the user's address for consistency.
     */
    function isVerified(address _user) external view returns (bool) {
        uint256 tokenId = uint256(uint160(_user));
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @notice Removes minting permission for a specific address.
     * @param _user The address to revoke badge claiming rights from.
     * @dev Requirements:
     * - Only callable by the contract owner
     * @dev Effects:
     * - Removes the user from the whitelist
     * - Prevents the user from claiming a badge until re-whitelisted
     * @dev This can be used to revoke permissions before a badge is claimed.
     */
    function hapusIzinMint(address _user) external onlyOwner {
        isWhitelisted[_user] = false;
    }

    /**
     * @notice Retrieves comprehensive badge status information for a user.
     * @param _user The address of the user to retrieve badge information for.
     * @return hasWhitelistPermission Whether the user is currently whitelisted to claim a badge.
     * @return isCurrentlyVerified Whether the user has already claimed and owns a verification badge.
     * @return tokenId The unique token ID associated with the user's address.
     * @return metadataURI The IPFS URI containing badge metadata (empty if not verified).
     * @dev This function provides all relevant information for frontend applications and integration.
     * @dev Token ID is always calculated from the user's address for predictability.
     */
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