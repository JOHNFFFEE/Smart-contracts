// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract myerc1155  is ERC1155, ERC2981, Ownable {
    string private _baseURI;

    // Land      Max Supply
    // SAVANNAH  = 1000
    // FOREST    = 500
    // ARCTIC    = 100
    uint256[] public supplies = [1000, 500, 100];

    // track the number of land minted per category
    mapping(uint256 => uint256) public landMinted;

    /// @dev Constructor can call only once upon deployment,
    ///         Fee numerator for collection only works if it is honor by exchange
    /// @param _feeNumerator Set fee for every collection
    constructor(uint96 _feeNumerator)
        ERC1155(
            "some_uri/{id}.json"
        )
    {
        _setDefaultRoyalty(_msgSender(), _feeNumerator);
    }

    /// @dev Allow any user to mint token
    /// @param id the id of the collection
    /// @param amount the number of items to be mint per specific collection
    function mint(uint256 id, uint256 amount) external {
        // check id must not greater than the 3
        require(id > 0 && id <= supplies.length, "invalid token id");
        // check landMinted per category not greater than the supply/cap provided
        require(landMinted[id] + amount <= supplies[id - 1], "supply exceeded");

        landMinted[id] = amount;
        _mint(_msgSender(), id, amount, "");
    }

    // === Only Owner functions ===

    /// @dev Set new base URI, kindly take a look on https://eips.ethereum.org/EIPS/eip-1155 for the format
    /// @param newuri The new URI to set
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /// @dev Set the royalty for all collection
    /// @param _feeNumerator The fee for collection
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /// @dev Set royalty fee for specific token
    /// @param _tokenId The tokenId where to add the royalty
    /// @param _receiver The royalty receiver
    /// @param _feeNumerator the fee for specific tokenId
    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    /// @dev Allow owner to delete the default royalty for all collection
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /// @dev Reset specific royalty
    /// @param tokenId The token id where to reset the royalty
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    // === override interface ===

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
