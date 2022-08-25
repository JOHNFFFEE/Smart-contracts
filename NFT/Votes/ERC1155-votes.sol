// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC1155 {
  function balanceOf(address account, uint256 id) external view returns (uint256);
}


import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC1155Dao is Ownable {

    // Take index of Proposal and address of voter to find if they have voted.
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    // Proposals to vote on.
    Proposal[] public proposals;
    // List of DAO executors.
    address[] public executors;

    IERC1155  fractionizedToken ;

    // Typing for the Proposal object
    struct Proposal {
        string  name; // short name (up to 32 bytes),
        uint256 voteCountFor; // number of accumulated votes, should use counter util in future
        uint256 voteCountAgainst; // number of accumulated votes, should use counter util in future
        uint256 voteCountDraw; // number of accumulated votes, should use counter util in future
        uint256  d_startAt;// when the proposal was proposed
        uint256  d_endsAt;   // when the proposal will end
        bool executed ;   //was executed
    }

    /**
     * Emitted when a user emitted a NewProposal.
     * @param ProposedOwner User address.
     * @param ProposalTimestamp The time proposal was made.
     */
    event NewProposal(
        address indexed ProposedOwner,
        // uint256 indexed id,
        uint256 ProposalTimestamp
    );

    /**
     * Emitted when a user stakes tokens.
     * @param voter User address.
     * @param id proposalId.
     * @param voteTimestamp The time vote was made.
     */
     event Voted(
        address indexed voter,
        uint256 indexed id,
        uint256 voteTimestamp
    );

    // Pass in the array of executors and base URI
    constructor(address[] memory _executors,  address _fractionizedToken)
      
    {
        fractionizedToken = IERC1155(_fractionizedToken) ;
        executors = _executors ;
    }

    //Only executors of the DAO can launch new proposals.
    function newProposal(string memory newName, uint256 _endsAt) public onlyOwner {
        proposals.push(Proposal({name: newName, voteCountFor: 0 , voteCountAgainst: 0, voteCountDraw: 0, d_startAt: block.timestamp, d_endsAt:  uint32(_endsAt+ block.timestamp) , executed:false}));
         emit NewProposal(msg.sender ,  block.timestamp );
    }

    //onlyNFTOwner can vote, For proposal
    function newVoteFor(uint256 index, uint256 tokenId) public  {
        require( fractionizedToken.balanceOf(msg.sender, tokenId) > 0 , "You need NFT token for this." );
        require (block.timestamp < proposals[index].d_endsAt  , "vote time is over");

        require(
            hasVoted[index][msg.sender] != true,
            "You already voted on this proposal"
        );
        // In future, check that I or the NFT artist cannot vote.
        proposals[index].voteCountFor++;
        hasVoted[index][msg.sender] = true;

        emit Voted(msg.sender , index , block.timestamp );
    }

        function newVoteAgainst(uint256 index, uint256 tokenId) public  {
            require( fractionizedToken.balanceOf(msg.sender, tokenId) > 0 , "You need NFT token for this." );
             require (block.timestamp < proposals[index].d_endsAt  , "vote time is over");

        require(
            hasVoted[index][msg.sender] != true,
            "You already voted on this proposal"
        );
        // In future, check that I or the NFT artist cannot vote.
        proposals[index].voteCountAgainst++;
        hasVoted[index][msg.sender] = true;
         emit Voted(msg.sender , index , block.timestamp );
    }

        function newVoteDraw(uint256 index, uint256 tokenId) public  {
            require( fractionizedToken.balanceOf(msg.sender, tokenId) > 0 , "You need NFT token for this." );
           require (block.timestamp <  proposals[index].d_endsAt  , "vote time is over");

        require(
            hasVoted[index][msg.sender] != true,
            "You already voted on this proposal"
        );
        // In future, check that I or the NFT artist cannot vote.
        proposals[index].voteCountDraw++;
        hasVoted[index][msg.sender] = true;
         emit Voted(msg.sender , index , block.timestamp);
    }   

    function viewVotes (uint256 index) view external returns(uint pors , uint cons, uint draw) {
      return  (proposals[index].voteCountFor, proposals[index].voteCountAgainst,  proposals[index].voteCountDraw );
    }

//may change the executors to be one of the list
    function executed (bool _executed, uint _index) external onlyOwner {
        //  require( executors[msg.sender] >0,"Need to be an executor");
         proposals[_index].executed = _executed ;

    }



}