// SPDX-License-Identifier: MIT


  pragma solidity ^0.8.4;


  import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
  import "@openzeppelin/contracts/access/Ownable.sol";
  import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
  import "./ERC20s.sol";


  
  contract ERC721Stacking is Ownable , ReentrancyGuard {

     event Stake (address indexed tokenOwner,  uint256[] tokenIds, uint256 time);
     event Withdraw (address indexed tokenOwner, uint256[] tokenIds, uint256 time);
     event ClaimReward (address indexed tokenOwner, uint256 value, uint256 time);

  
      string CollectionAddress;
      string RewardAddress;
      string StakingTime;
      uint16 StakingReward;
  
      // Interfaces for ERC20 and ERC721
      ERC20s public immutable rewardsToken;
      IERC721 public immutable nftCollection;
  
      // Staker info
      struct Staker {
          // Amount of ERC721 Tokens staked
          uint256 amountStaked;
          // Last time of details update for this User
          uint256 timeOfLastUpdate;
          // Calculated, but unclaimed rewards for the User. The rewards are
          // calculated each time the user writes to the Smart Contract
          uint256 unclaimedRewards;
      }
  
      // Rewards per hour per token deposited in wei.
      // Rewards are cumulated once every hour.
      uint256 private rewardsPerHour;
  
      // Mapping of User Address to Staker info
      mapping(address => Staker) public stakers;
      // Mapping of Token Id to staker. Made for the SC to remeber
      // who to send back the ERC721 Token to.
      mapping(uint256 => address) public stakerAddress;
  
      address[] public stakersArray;
  
      // Constructor function
      constructor(IERC721 _nftCollection, ERC20s _rewardsToken, uint256 _StakingReward)  {
          nftCollection = _nftCollection;
          rewardsToken = _rewardsToken;
          rewardsPerHour = _StakingReward;
      }
  
      // If address already has ERC721 Token/s staked, calculate the rewards.
      // For every new Token Id in param transferFrom user to this Smart Contract,
      // increment the amountStaked and map msg.sender to the Token Id of the staked
      // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
      // value of now.
      function stake(uint256[] calldata _tokenIds) external nonReentrant {
          if (stakers[msg.sender].amountStaked > 0) {
              uint256 rewards = calculateRewards(msg.sender);
              stakers[msg.sender].unclaimedRewards += rewards;
          } else {
              stakersArray.push(msg.sender);
          }
          uint256 len = _tokenIds.length;
          for (uint256 i; i < len; ++i) {
              require(
                  nftCollection.ownerOf(_tokenIds[i]) == msg.sender,
                  "Can't stake tokens you don't own!"
              );
              nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);
              stakerAddress[_tokenIds[i]] = msg.sender;
          }
          stakers[msg.sender].amountStaked += len;
          stakers[msg.sender].timeOfLastUpdate = block.timestamp;

    emit Stake (msg.sender ,  _tokenIds , block.timestamp);

      }
  
      // Check if user has any ERC721 Tokens Staked and if he tried to withdraw,
      // calculate the rewards and store them in the unclaimedRewards and for each
      // ERC721 Token in param: check if msg.sender is the original staker, decrement
      // the amountStaked of the user and transfer the ERC721 token back to them
      function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
          require(
              stakers[msg.sender].amountStaked > 0,
              "You have no tokens staked"
          );
          uint256 rewards = calculateRewards(msg.sender);
          stakers[msg.sender].unclaimedRewards += rewards;
          uint256 len = _tokenIds.length;
          for (uint256 i; i < len; ++i) {
              require(stakerAddress[_tokenIds[i]] == msg.sender);
              stakerAddress[_tokenIds[i]] = address(0);
              nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
          }
          stakers[msg.sender].amountStaked -= len;
          stakers[msg.sender].timeOfLastUpdate = block.timestamp;
          for (uint256 i; i < len; ++i) {
              if (stakersArray[i] == msg.sender) {
                  stakersArray[stakersArray.length - 1] = stakersArray[i];
                  stakersArray.pop();
              }
              rewardsToken.mint(msg.sender, rewards) ;
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

          rewardsToken.mint(msg.sender, rewards) ;
          
        //  rewardsToken.transferFrom(address(this),msg.sender, rewards);

       emit  ClaimReward (msg.sender, rewards, block.timestamp);
      }
  
      // Set the rewardsPerHour variable
      // Because the rewards are calculated passively, the owner has to first update the rewards
      // to all the stakers, witch could result in very heavy load and expensive transactions
      function setRewardsPerHour(uint256 _newValue) public onlyOwner {
          address[] memory _stakers = stakersArray;
          uint256 len = _stakers.length;
          for (uint256 i; i < len; ++i) {
              address user = _stakers[i];
              stakers[user].unclaimedRewards += calculateRewards(user);
              stakers[msg.sender].timeOfLastUpdate = block.timestamp;
          }
          rewardsPerHour = _newValue;
      }
  
      //////////
      // View //
      //////////
  
      function userStakeInfo(address _user)
          public
          view
          returns (uint256 _tokensStaked, uint256 _availableRewards)
      {
          return (stakers[_user].amountStaked, availableRewards(_user));
      }
  
      function availableRewards(address _user) internal view returns (uint256) {
          if (stakers[_user].amountStaked == 0) {
              return stakers[_user].unclaimedRewards;
          }
          uint256 _rewards = stakers[_user].unclaimedRewards +
              calculateRewards(_user);
          return _rewards;
      }
  
      /////////////
      // Internal//
      /////////////
  
      // Calculate rewards for param _staker by calculating the time passed
      // since last update in hours and mulitplying it to ERC721 Tokens Staked
      // and rewardsPerHour.
      function calculateRewards(address _staker)
          internal
          view
          returns (uint256 _rewards)
      {
          Staker memory staker = stakers[_staker];
          return (((
              ((block.timestamp - staker.timeOfLastUpdate) * staker.amountStaked)
          ) * rewardsPerHour) / 120);
      }
  }