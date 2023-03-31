
  // SPDX-License-Identifier: MIT

  // @author andreitoma8
  //   __         ______     __  __     __   __     ______     __  __     __     ______   __    
  //  /\ \       /\  __ \   /\ \/\ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\ \   /\  ___\ /\ \   
  //  \ \ \____  \ \  __ \  \ \ \_\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \ \  \ \  __\ \ \ \  
  //   \ \_____\  \ \_\ \_\  \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\  \ \_\    \ \_\ 
  //    \/_____/   \/_/\/_/   \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/   \/_/     \/_/ 

  pragma solidity ^0.8.10;
  
  import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
  import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
  import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
  import "@openzeppelin/contracts/access/Ownable.sol";
  import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
  import "@openzeppelin/contracts/security/Pausable.sol";

  
  contract ERC721Staking is Ownable, ReentrancyGuard, Pausable  {

     event Stake (address indexed tokenOwner,  uint256[] tokenIds, uint256 time);
     event Withdraw (address indexed tokenOwner, uint256[] tokenIds, uint256 time);
     event ClaimReward (address indexed tokenOwner, uint256 value, uint256 time);
     event ChangedStakingPeriod (uint256 time , uint256 value );


      using SafeERC20 for IERC20;
  
      string CollectionAddress;
      string RewardAddress;
      string StakingTime;
      uint16 public StakingReward;
  
      // Interfaces for ERC20 and ERC721
      IERC20 public immutable rewardsToken;
      IERC721 public immutable nftCollection;
  
    struct Staker {
        /**
         * @dev The array of Token Ids staked by the user.
         */
        uint256[] stakedTokenIds;
        /**
         * @dev The time of the last update of the rewards.
         */
        uint256 timeOfLastUpdate;
        /**
         * @dev The amount of ERC20 Reward Tokens that have not been claimed by the user.
         */
        uint256 unclaimedRewards;
    }
    uint public stakingTime = 300 ;


      // Rewards per hour per token deposited in wei.
      // Rewards are cumulated once every hour.
      uint256 public rewardsPerHour;
  
      // Mapping of User Address to Staker info
      mapping(address => Staker) public stakers;
      // Mapping of Token Id to staker. Made for the SC to remeber
      // who to send back the ERC721 Token to.
      mapping(uint256 => address) public stakerAddress;
  
      address[] public stakersArray;
       /**
     * @dev Mapping of stakers addresses to their index in the stakersArray.
     */
    mapping(address => uint256) public stakerToArrayIndex;

    /**
     * @notice Mapping of Token Id to it's index in the staker's stakedTokenIds array.
     */
    mapping(uint256 => uint256) public tokenIdToArrayIndex;

  
      // Constructor function
      constructor(IERC721 _nftCollection, 
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
      function stake(uint256[] calldata _tokenIds) external whenNotPaused {
        Staker storage staker = stakers[msg.sender];

        if (staker.stakedTokenIds.length > 0) {
            updateRewards(msg.sender);
        } else {
            stakersArray.push(msg.sender);
            stakerToArrayIndex[msg.sender] = stakersArray.length - 1;
            staker.timeOfLastUpdate = block.timestamp;
        }

        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(nftCollection.ownerOf(_tokenIds[i]) == msg.sender, "Can't stake tokens you don't own!");

            nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);

            staker.stakedTokenIds.push(_tokenIds[i]);
            tokenIdToArrayIndex[_tokenIds[i]] = staker.stakedTokenIds.length - 1;
            stakerAddress[_tokenIds[i]] = msg.sender;
        }

           emit Stake (msg.sender ,  _tokenIds , block.timestamp);
      }
  
    /**
     * @notice Function used to withdraw ERC721 Tokens.
     * @param _tokenIds - The array of Token Ids to withdraw.
     */
    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(staker.stakedTokenIds.length > 0, "You have no tokens staked");
        updateRewards(msg.sender);

        uint256 lenToWithdraw = _tokenIds.length;
        for (uint256 i; i < lenToWithdraw; ++i) {
            require(stakerAddress[_tokenIds[i]] == msg.sender);

            uint256 index = tokenIdToArrayIndex[_tokenIds[i]];
            uint256 lastTokenIndex = staker.stakedTokenIds.length - 1;
            if (index != lastTokenIndex) {
                staker.stakedTokenIds[index] = staker.stakedTokenIds[lastTokenIndex];
                tokenIdToArrayIndex[staker.stakedTokenIds[index]] = index;
            }
            staker.stakedTokenIds.pop();

            delete stakerAddress[_tokenIds[i]];

            nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }

        if (staker.stakedTokenIds.length == 0) {
            uint256 index = stakerToArrayIndex[msg.sender];
            uint256 lastStakerIndex = stakersArray.length - 1;
            if (index != lastStakerIndex) {
                stakersArray[index] = stakersArray[lastStakerIndex];
                stakerToArrayIndex[stakersArray[index]] = index;
            }
            stakersArray.pop();
        } 
           emit Withdraw (msg.sender ,  _tokenIds , block.timestamp);

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
  
      //////////
      // View //
      //////////
  
   function userStakeInfo(address _user)
        public
        view
        returns (uint256[] memory _stakedTokenIds, uint256 _availableRewards)
    {
        return (stakers[_user].stakedTokenIds, availableRewards(_user));
    }
  
     function availableRewards(address _user) internal view returns (uint256 _rewards) {
        Staker memory staker = stakers[_user];

        if (staker.stakedTokenIds.length == 0) {
            return staker.unclaimedRewards;
        }

        _rewards = staker.unclaimedRewards + calculateRewards(_user);
    }
  
      /////////////
      // Internal//
      /////////////
  
      // Calculate rewards for param _staker by calculating the time passed
      // since last update in hours and mulitplying it to ERC721 Tokens Staked
      // and rewardsPerHour.
      function calculateRewards(address _staker) internal view returns (uint256 _rewards) {
        Staker memory staker = stakers[_staker];
        return (
            ((((block.timestamp - staker.timeOfLastUpdate) * staker.stakedTokenIds.length)) * rewardsPerHour)
                / stakingTime
        );
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



    //   function tokens() public view returns (uint[] memory)  {
    //       return nftCollection.getOwnedNFTs(msg.sender) ;
    //   }

  }