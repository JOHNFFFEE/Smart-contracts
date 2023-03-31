// SPDX-License-Identifier: MIT


pragma solidity >=0.8.13 <0.9.0;



interface ERC20Interface {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ERC20Staking is Context, Ownable, ReentrancyGuard, Pausable {
    using Address for address;


        /**
     * Emitted when a user store farming rewards.
     * @param sender User address.
     * @param amount Current store amount.
     * @param storeTimestamp The time when store farming rewards.
     */
    event ContractFunded(
        address indexed sender,
        uint256 amount,
        uint256 storeTimestamp
    );

    // Staker info
    struct Staker {
        // The deposited tokens of the Staker
        uint256 deposited;
        // Last time of details update for Deposit
        uint256 timeOfLastUpdate;
        // Calculated, but unclaimed rewards. These are calculated each time
        // a user writes to the contract.
        uint256 unclaimedRewards;
    }

    // stake token
    ERC20Interface public rewardToken;

    // Rewards per hour. A fraction calculated as x/10.000.000 to get the percentage
    uint256 public rewardsPerHour =  10 ; // 0.00285%/h or 25% APR

    // Minimum amount to stake
    uint256 public minStake ;

    // Compounding frequency limit in seconds
    uint256 public compoundFreq = 14400; //4 hours

    // Mapping of address to Staker info
    mapping(address => Staker) internal stakers;

    // The farming rewards of users(address => total amount)
    //  mapping(address => uint256) public funding;
    // the total farming rewards for users
    uint256 public totalFunding;

    //every 100k tokens users get rewarded faster
    uint256 public amountToBeRewarded  = 100000 ;

    // Constructor function
     constructor(address _tokenAddress ) {
        require(
            _tokenAddress.isContract(),
            "_tokenAddress is not a contract address"
        );
        rewardToken = ERC20Interface(_tokenAddress);
    }

       /**
     * Store farming rewards to contract, in order to pay the user interest later.
     *
     * Note: _amount should be more than 0
     */
    function fundingContract(uint256 _amount) external nonReentrant {
        require(_amount > 0, "fundingContract _amount should be more than 0");

      //  funding[msg.sender] += _amount;
        // increase total funding
        totalFunding += _amount;
        require(
            rewardToken.transferFrom(msg.sender, address(this), _amount),
            "fundingContract transferFrom failed"
        );    
        // send event
        emit ContractFunded(msg.sender, _amount, block.timestamp);
    }


    // If address has no Staker struct, initiate one. If address already was a stake,
    // calculate the rewards and add them to unclaimedRewards, reset the last time of
    // deposit and then add _amount to the already deposited amount.
    function stake(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount >= minStake, "Amount smaller than minimimum deposit");
        require(
            rewardToken.balanceOf(msg.sender) >= _amount,
            "Can't stake more than you own"
        );
        rewardToken.transferFrom(msg.sender , address(this), _amount);
        if (stakers[msg.sender].deposited == 0) {
            stakers[msg.sender].deposited = _amount;
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
            stakers[msg.sender].unclaimedRewards = 0;
        } else {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
            stakers[msg.sender].deposited += _amount;
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        }
    }

    // Compound the rewards and reset the last time of update for Deposit info
    function stakeRewards() external whenNotPaused nonReentrant {
        require(stakers[msg.sender].deposited > 0, "You have no deposit");
        require(
            compoundRewardsTimer(msg.sender) == 0,
            "Tried to compound rewards too soon"
        );
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].deposited += rewards;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    // Mints rewards for msg.sender
    function claimRewards() external whenNotPaused nonReentrant {
       
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards");
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        rewardToken.transfer(msg.sender, rewards);
        totalFunding-= rewards ;
          
    }

    // unstake specified amount of staked tokens
    function unstakeCertainAmount(uint256 _amount) external whenNotPaused nonReentrant {
        // require(rewardToken.balanceOf(address(this)) > _amount, "Not enough tokens in contract balance");
        require(
            stakers[msg.sender].deposited >= _amount,
            "Can't withdraw more than you have"
        );

        uint256 _rewards = calculateRewards(msg.sender);
        stakers[msg.sender].deposited -= _amount;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = _rewards;
        rewardToken.transfer(msg.sender, _amount);
        // totalFunding-= _amount ;
  
    }

    // unstake all stake and rewards and mints them to the msg.sender
    function unstakeAll() external whenNotPaused nonReentrant {
        require(stakers[msg.sender].deposited > 0, "You have no deposit");
        uint256 _rewards = calculateRewards(msg.sender) +
        stakers[msg.sender].unclaimedRewards;
        uint256 _deposit = stakers[msg.sender].deposited;
        uint256 _amount = _rewards + _deposit;
        
      //   require(rewardToken.balanceOf(address(this)) > _amount, "Not enough tokens in contract balance");
             stakers[msg.sender].deposited = 0;
        stakers[msg.sender].timeOfLastUpdate = 0;        
        rewardToken.transfer(msg.sender, _amount);
        totalFunding-= _amount ; 
       // delete stakers[msg.sender] ;
    }

    // Function useful for fron-end that returns user stake and rewards by address
    function getDepositInfo(address _user)
        public
        view
        returns (uint256 _stake, uint256 _rewards)
    {
        _stake = stakers[_user].deposited;
        _rewards =
            calculateRewards(_user) +
            stakers[msg.sender].unclaimedRewards;
        return (_stake, _rewards);
    }

    // Utility function that returns the timer for restaking rewards
    function compoundRewardsTimer(address _user)
        public
        view
        returns (uint256 _timer)
    {
        if (stakers[_user].timeOfLastUpdate + compoundFreq <= block.timestamp) {
            return 0;
        } else {
            return
                (stakers[_user].timeOfLastUpdate + compoundFreq) -
                block.timestamp;
        }
    }

    // Calculate the rewards since the last update on Deposit info
    //every 100k tokens you get rewards
    function calculateRewards(address _staker)
        internal
        view
        returns (uint256 rewards)
    {
        return (((((block.timestamp - stakers[_staker].timeOfLastUpdate) *
            stakers[_staker].deposited) * rewardsPerHour) / compoundFreq)/amountToBeRewarded);
    }


    // Functions for modifying  staking mechanism variables:

    // Set rewards per hour as x/10.000.000 (Example: 100.000 = 1%)
    function setRewards(uint256 _rewardsPerHour) public onlyOwner {
        rewardsPerHour = _rewardsPerHour;
    }

    // Set the minimum amount for staking in wei
    function setMinStake(uint256 _minStake) public onlyOwner {
        minStake = _minStake;
    }

    // Set the minimum time that has to pass for a user to be able to restake rewards
    function setCompFreq(uint256 _compoundFreq) public onlyOwner {
        compoundFreq = _compoundFreq;
    }

        // Set the minimum time that has to pass for a user to be able to restake rewards
    function setRewardQtyFaster(uint256 _amountToBeRewarded) public onlyOwner {
        amountToBeRewarded = _amountToBeRewarded;
    }

        /**
     * Pauses all token stake, unstake.
     * 
     * See {Pausable-_pause}.
     * 
     * Requirements: the caller must be the owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * Unpauses all token stake, unstake.
     * 
     * See {Pausable-_unpause}.
     * 
     * Requirements: the caller must be the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}