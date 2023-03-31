//each period of time a certain amount of tokens is released and is able to be bought
//preset with 100k tokens
//when transfer some tokens are send to some wallets - better to use uniswap for this case


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
//@AUTHOR Lax

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "hardhat/console.sol"; 

contract BOUNDING is ERC20, ERC20Permit, ERC20Votes, ERC20Burnable, Pausable, Ownable { 

    uint256 public constant MAX_SUPPLY = 1e26;
    uint256 public constant GROWTH_RATE = 1e23;
    uint256 private constant MARKETING_FEE = 1e21;
    uint256 private constant AIRDROP = 1e21;
    uint256 public constant MINT_INTERVAL = 60 ;// 6 * 30 days;
    uint256 public currentMintLimit; //CHANGE TO PRIVATE LATER
    uint256 private lastMintTime;
    uint256 private airdropped;

    uint256 private constant LIQUIDITY_FEE_PERCENT = 50;
    uint256 private constant TREASURY_FEE_PERCENT = 25;
    uint256 private constant TEAM_FEE_PERCENT = 10;
    uint256 private constant MARKETING_FEE_PERCENT = 10;
    uint256 private constant AUDIT_FEE_PERCENT = 5;

    // Define the fee destinations
    address payable private liquidityAddress = payable(0xdD870fA1b7C4700F2BD7f44238821C26f7392148);
    address payable private treasuryAddress = payable(0xdD870fA1b7C4700F2BD7f44238821C26f7392148);
    address payable private teamAddress = payable(0xdD870fA1b7C4700F2BD7f44238821C26f7392148);
    address payable private marketingAddress= payable(0xdD870fA1b7C4700F2BD7f44238821C26f7392148);
    address payable private auditAddress= payable(0xdD870fA1b7C4700F2BD7f44238821C26f7392148);

    // Define the current fees for the different destinations
    uint256 private currentLiquidityFee;
    uint256 private currentTreasuryFee;
    uint256 private currentTeamFee;
    uint256 private currentMarketingFee;
    uint256 private currentAuditFee;


    uint public price = 1 ; //ether ;

    constructor()
     ERC20("BATH", "$BATH") ERC20Permit("BATH") {
        lastMintTime = block.timestamp;
        currentMintLimit = GROWTH_RATE;
        }

    function mint(address to, uint256 amount) public payable whenNotPaused  {
      require(msg.value >= price * amount, 'Not sufficient funds');
      updateMintLimit() ;
      _mint(to, amount);
    }


    // view

   /* The _getMintAmount function calculates the amount of tokens that should be minted based on the current time and the growth rate. and returns the period*/
    function _getMintAmount() internal view returns (uint256) {
        uint256 elapsedTime = block.timestamp - lastMintTime;
        uint256 periodsElapsed = elapsedTime / MINT_INTERVAL;
        return GROWTH_RATE * periodsElapsed;
    }

    /*every 6 months update currentMintLimit to GROWTH_RATE, and only once a period*/
    function updateMintLimit() internal {
        // require(block.timestamp - lastMintTime >= MINT_INTERVAL, "BATH: Mint interval has not elapsed yet");
        currentMintLimit = currentMintLimit + _getMintAmount();
        if (currentMintLimit > MAX_SUPPLY) {
            currentMintLimit = MAX_SUPPLY;
        }
        lastMintTime = block.timestamp;
    }


    // onlyOwner

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function airdrop(address[] memory recipients , uint amount) public onlyOwner {
        require(recipients.length + airdropped <= AIRDROP, "Airdrop cap reached");
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amount);
        }
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        require(totalSupply() + amount <= MAX_SUPPLY, "BATH: total supply exceeds max supply");
        require(amount <= currentMintLimit, "BATH: mint amount exceeds current limit");
        super._mint(to, amount);
        currentMintLimit -= amount;
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    // Transfer tokens between two addresses
function transfer(address to, uint256 amount) public override returns (bool) {
    // Calculate fee for each recipient
    uint256 liquidityFee = amount * LIQUIDITY_FEE_PERCENT / 100;
    uint256 treasuryFee = amount * TREASURY_FEE_PERCENT / 100;
    uint256 teamFee = amount * TEAM_FEE_PERCENT / 100;
    uint256 marketingFee = amount * MARKETING_FEE_PERCENT / 100;
    uint256 auditFee = amount * AUDIT_FEE_PERCENT / 100;

    // Transfer the amount minus fees
    uint256 transferAmount = amount - liquidityFee - treasuryFee - teamFee - marketingFee - auditFee;
    
    _transfer(msg.sender, treasuryAddress, treasuryFee);
    _transfer(msg.sender, teamAddress, teamFee);
    _transfer(msg.sender, marketingAddress, marketingFee);
    _transfer(msg.sender, auditAddress, auditFee);
super.transfer(to, transferAmount);
    return true;
}


// //Sure, here's how you can update the mint function to include the fee distribution in Ethereum:
// function mint(address to, uint256 amount) public payable whenNotPaused  {
//     uint256 ethAmount = price * amount;
//     require(msg.value >= ethAmount, 'Not sufficient funds');

//     // Calculate the fee amounts in Ethereum
//     uint256 liquidityFee = (ethAmount * LIQUIDITY_FEE_PERCENT) / 100;
//     uint256 treasuryFee = (ethAmount * TREASURY_FEE_PERCENT) / 100;
//     uint256 teamFee = (ethAmount * TEAM_FEE_PERCENT) / 100;
//     uint256 marketingFee = (ethAmount * MARKETING_FEE_PERCENT) / 100;
//     uint256 auditFee = (ethAmount * AUDIT_FEE_PERCENT) / 100;

//     // Transfer the fees to the corresponding addresses
//     liquidityAddress.transfer(liquidityFee);
//     treasuryAddress.transfer(treasuryFee);
//     teamAddress.transfer(teamFee);
//     marketingAddress.transfer(marketingFee);
//     auditAddress.transfer(auditFee);

//     // Update the mint limit and mint the tokens
//     updateMintLimit();
//     _mint(to, amount);
// }


}
