// SPDX-License-Identifier: MIT
//adapted by LAx

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";


contract Irobots is ERC1155, Ownable, ERC1155Supply {
    
  string public name;
  string public symbol;
  bool public transferable = false;

  mapping(uint => string) public tokenURI;
  mapping(address =>uint ) private NftPerWallet;

  string  public mytokenURI= "ipfs://QmQpe1vqn8CB4ujEjscWJP7qpGTpg8EHaj37ERPTXepfG2/" ;

    uint256 private constant Robot1 = 1;
  constructor() ERC1155("")  {
    name = "xxx";
    symbol = "xxx";
  }

      modifier istransferable() {
        require(transferable==true, 'Can Not Trade');
         _;
    }

    function mint(address[] memory  account)
        public onlyOwner
    {
        for (uint i; i< account.length; i++){
               _mint(account[i], 1, 1, '');
        }     
    }


    function isTransferable(bool _choice) public onlyOwner{
    transferable = _choice;
    }


   function setURI(string memory newuri) public onlyOwner {
        mytokenURI = newuri;
    }

      function uri(uint256 _tokenid) public override view returns  (string memory) {
        return string(
            abi.encodePacked(
               mytokenURI,
                Strings.toString(_tokenid),".json"
            )
        );
    }


      function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public istransferable virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public  istransferable virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

        function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}