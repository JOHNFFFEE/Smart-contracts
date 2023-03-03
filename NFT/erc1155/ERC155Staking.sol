
pragma solidity >=0.8.13 <0.9.0;
  
  import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
  import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
  import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
  import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
  import "@openzeppelin/contracts/access/Ownable.sol";
  import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
  import "@openzeppelin/contracts/security/Pausable.sol";

  
  contract ERC1155Staking is Ownable, ReentrancyGuard, Pausable ,ERC1155Holder  {

     event Stake (address indexed tokenOwner,  uint256 tokenIds, uint256 amount ,uint256 time);
     event Withdraw (address indexed tokenOwner, uint256 tokenIds,  uint256 amount ,uint256 time);
     event ClaimReward (address indexed tokenOwner, uint256 value, uint256 time);
     event ChangedStakingPeriod (uint256 time , uint256 value );


      using SafeERC20 for IERC20;
  
      string CollectionAddress;
      string RewardAddress;
      string StakingTime;
      uint16 public StakingReward;
  
      // Interfaces for ERC20 and ERC721
      IERC20 public immutable rewardsToken;
      IERC1155 public immutable nftCollection;
  
    struct Staker {
      /**
      * @dev The Token Ids staked by the user.
     */
    uint256[] stakedTokenIds;
    /**
     * @dev The amounts of Token Ids staked by the user.
     */
    uint256[] stakedAmounts;
        /**
         * @dev The time of the last update of the rewards.
         */
        uint256 timeOfLastUpdate;
        /**
         * @dev The amount of ERC20 Reward Tokens that have not been claimed by the user.
         */
        uint256 unclaimedRewards;

         /*returns the amount of all tokenIds staked*/
        uint256 globalAmount ;
    }
    uint public stakingTime = 300 ;


      // Rewards per hour per token deposited in wei.
      // Rewards are cumulated once every hour.
      uint256 public rewardsPerHour;
  
      // Mapping of User Address to Staker info
      mapping(address => Staker) public stakers;
      // Mapping of Token Id to staker. Made for the SC to remeber
      address[] stakersArray;

  
      // Constructor function
      constructor(IERC1155 _nftCollection, 
        IERC20 _rewardsToken,
        uint256 _StakingReward
        // ,address _serviceFeeAddress,
        // uint256 _serviceCost
        ) /*payable*/ {
          nftCollection = _nftCollection;
          rewardsToken = _rewardsToken;
          rewardsPerHour = _StakingReward;

        //   payable(_serviceFeeAddress).transfer(_serviceCost);
      }
  
      // If address already has ERC721 Token/s staked, calculate the rewards.
      // For every new Token Id in param transferFrom user to this Smart Contract,
      // increment the amountStaked and map msg.sender to the Token Id of the staked
      // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
      // value of now.

function stake(uint256 _tokenId, uint256 _amount) public {
    require(nftCollection.balanceOf(msg.sender, _tokenId) >= _amount, 'you dont have enough balance');
    Staker storage staker = stakers[msg.sender];    
    nftCollection.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
 //no staked before
    if (staker.stakedTokenIds.length == 0) {
        staker.stakedTokenIds.push(_tokenId);
        staker.stakedAmounts.push(_amount);
        staker.timeOfLastUpdate = block.timestamp;
        staker.unclaimedRewards = 0;
        staker.globalAmount = _amount;
        stakersArray.push(msg.sender); //for updating the price correctly
    } else {
      //stake same tokenId
        uint256 index = getIndexOfTokenId(staker.stakedTokenIds, _tokenId);
        if (index < staker.stakedTokenIds.length) {
            uint256 rewards = calculateRewards(msg.sender) + staker.unclaimedRewards;
            staker.stakedAmounts[index] += _amount;
            staker.globalAmount += _amount;
            staker.timeOfLastUpdate = block.timestamp;
            staker.unclaimedRewards = rewards;
        } else {  //stake no same tokenId
            uint256 rewards = calculateRewards(msg.sender) + staker.unclaimedRewards;
            staker.stakedTokenIds.push(_tokenId);
            staker.stakedAmounts.push(_amount);
            staker.timeOfLastUpdate = block.timestamp;
            staker.unclaimedRewards = rewards;
            staker.globalAmount += _amount;
        }
    }

    emit Stake(msg.sender, _tokenId, _amount, block.timestamp);
}


  
    /**
     * @notice Function used to withdraw ERC1155 Tokens.
     * tokenIds - The Token Ids to withdraw.
     */

  function withdraw(uint256 _id, uint256 _amount) external nonReentrant {
      Staker storage staker = stakers[msg.sender];
      require(staker.stakedTokenIds.length > 0, "You have no tokens staked");
      uint256 index = getIndexOfTokenId(staker.stakedTokenIds, _id);
      require(index < staker.stakedTokenIds.length, "Token is not staked by user");
      require(staker.stakedAmounts[index] >= _amount, "Insufficient staked balance");

      updateRewards(msg.sender);
      staker.stakedAmounts[index] -= _amount;
      staker.globalAmount -= _amount;
      staker.timeOfLastUpdate = block.timestamp;
      nftCollection.safeTransferFrom(address(this), msg.sender, _id, _amount, "");
      emit Withdraw(msg.sender, _id, _amount, block.timestamp);
    }


  
  // Calculate rewards for the msg.sender, check if there are any rewards
  // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
  // to the user.
  function claimRewards() external {
      uint256 rewards = calculateRewards(msg.sender) +
          stakers[msg.sender].unclaimedRewards;
      require(rewards > 0, "You have no rewards to claim");            
      stakers[msg.sender].timeOfLastUpdate = block.timestamp;
      stakers[msg.sender].unclaimedRewards = 0;
      rewardsToken.safeTransfer(msg.sender, rewards);
      emit  ClaimReward (msg.sender, rewards, block.timestamp);           
  }

  // Set the rewardsPerHour variable
  // Because the rewards are calculated passively, the owner has to first update the rewards
  // to all the stakers, witch could result in very heavy load and expensive transactions
  function setRewardsPerHour(uint256 _newValue) public onlyOwner {
      address[] memory _stakers = stakersArray;
      uint256 len = _stakers.length;
      for (uint256 i; i < len; ++i) {
          updateRewards(_stakers[i]);
      }

      rewardsPerHour = _newValue;
    }

     /**
     * @dev Pause staking.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Resume staking.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setStakingTime(uint _newPeriod) external onlyOwner {
       stakingTime = _newPeriod;
      emit ChangedStakingPeriod (block.timestamp ,_newPeriod );
    }
  
      //////////
      // View //
      //////////
  
  function userStakeInfo(address _user)
        public
        view
        returns (uint256 _stakedTokenIds, uint256 _availableRewards)
    {
        return (stakers[_user].globalAmount, availableRewards(_user));
    }

  function getStakedIdsAndAmounts(address _staker) public view returns (uint256[] memory token, uint256[] memory qty) {
    Staker memory staker = stakers[_staker];
    uint256[] memory tokenIds = new uint256[](staker.stakedTokenIds.length);
    uint256[] memory amounts = new uint256[](staker.stakedTokenIds.length);
    uint256 count = 0;
    for (uint256 i = 0; i < staker.stakedTokenIds.length; i++) {
        if (staker.stakedAmounts[i] > 0) {
            tokenIds[count] = staker.stakedTokenIds[i];
            amounts[count] = staker.stakedAmounts[i];
            count++;
        }
    }
    // Resize the arrays to remove empty slots
    assembly {
        mstore(tokenIds, count)
        mstore(amounts, count)
    }
    return (tokenIds, amounts);
}
  
      /////////////
      // Internal//
      /////////////
  function calculateRewards(address _staker) internal view returns  (uint256 _rewards) {
        Staker memory staker = stakers[_staker];
        return (
            ((((block.timestamp - staker.timeOfLastUpdate) * staker.globalAmount)) * rewardsPerHour)
         / stakingTime);
      }


         /**
     * @notice Function used to update the rewards for a user.
     * @param _staker - The address of the user.
     */
    function updateRewards(address _staker) internal {
        Staker storage staker = stakers[_staker];

        staker.unclaimedRewards += calculateRewards(_staker);
        staker.timeOfLastUpdate = block.timestamp;
    }

        function getIndexOfTokenId(uint256[] storage tokenIds, uint256 tokenId) internal view returns (uint256) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                return i;
            }
        }
        return tokenIds.length;
    }

  
      function availableRewards(address _user) internal view returns (uint256 _rewards) {
        Staker memory staker = stakers[_user];

        if (staker.globalAmount == 0) {
            return staker.unclaimedRewards;
        }
        _rewards = staker.unclaimedRewards + calculateRewards(_user);
        }
  
  }
  
