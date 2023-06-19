
// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
/**
    * @title   .A Sample Raffle Contract
    * @author  .Ahmet Said Oguz
    * @notice  .For creating simple raffle
    * @dev     .Implementing Chainlink VRFv2
    
    */
//! CEI  => Checks Effects Interactions
contract Raffle is VRFConsumerBaseV2{
/**Custome errors */
error Raffle__NotEnoughEthSent();
error Raffle__TransferFailed();
error Raffle__RaffleNotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance,uint256 Numplayers,uint256 Raffle_state);
/**Type Declerations */

enum RaffleState{
    OPEN,       // 0
    CALCULATING//  1
}

/**STATE VARIABLES */
uint16 private constant REQUEST_CONFIRMNATIONS=3;
uint32 private constant NUM_WORDS=1;
uint256 private immutable i_entranceFee;
// @dev: duration of the raffle in seconds;
uint256 private immutable i_interval;
VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
bytes32 private immutable i_gasLane;
uint64  private immutable i_subscriptionId;
uint32  private immutable i_callbackGasLimit;
address payable[] private s_players;
address payable s_recentWinner;
uint256 private s_lastTimestamp;
RaffleState private s_raffleState;
/**EVENTS */
event EnteredRaffle(address indexed player);
event PickedWinner(address indexed winner);
event RequestedRaffleWinner(uint256 indexed requestId);
constructor(uint256 _entranceFee,
           uint256 _interval,
           address _vrfCoordinator,
           bytes32 _gasLane,
           uint64 _subscriptionId,
           uint32 _callbackGasLimit) VRFConsumerBaseV2(_vrfCoordinator){
i_entranceFee=_entranceFee;
i_interval=_interval;
i_vrfCoordinator=VRFCoordinatorV2Interface(_vrfCoordinator);
i_gasLane=_gasLane;
i_subscriptionId=_subscriptionId;
i_callbackGasLimit=_callbackGasLimit;

s_raffleState=RaffleState.OPEN;
s_lastTimestamp=block.timestamp;
}
  function enterRaffle()public payable{
  if(msg.value<i_entranceFee){
    revert Raffle__NotEnoughEthSent();
  }
  if(s_raffleState!= RaffleState.OPEN){
    revert Raffle__RaffleNotOpen();
  }
  s_players.push(payable(msg.sender));

  //makes migration easier
  //makes front-end "indexing" easier
  emit EnteredRaffle(msg.sender);
  }

/**
 This is the chainlink function which determines and trigger automated invokation
     returns true in case of
     1. The time interval has passed between raffle runs
     2. The raffle state is OPEN
     3. The contract has ETH(aka players)
     4. (implicit) the subscription is funded with LINK token 
 */
function checkUpKeep(bytes memory /*checkData*/) public view returns(bool upkeepNeeded,bytes memory /*performData */){
bool timeHasPassed= (block.timestamp-s_lastTimestamp)>=i_interval;
bool isOpen=RaffleState.OPEN==s_raffleState;
bool hasBalance=address(this).balance>0;
bool hasPlayer=s_players.length>0;
upkeepNeeded=(timeHasPassed &&isOpen && hasBalance && hasPlayer);
//! this is how we return blank bytes object "0x0"
  return(upkeepNeeded,"0x0");
}


  // 1. Get a random number..
  // 2. use random number to pick a player..
  // 3. Be automatically called..
  function performUpkeep(bytes calldata /*performData */)external{
    (bool upkeepNeeded,)=checkUpKeep("");
  if(!upkeepNeeded){
    revert Raffle__UpkeepNotNeeded(
        address(this).balance,
        s_players.length,
        uint256(s_raffleState)

    );
  }
    s_raffleState=RaffleState.CALCULATING;
     uint256 requestId=i_vrfCoordinator.requestRandomWords(
            i_gasLane,// gas lane
            i_subscriptionId,
            REQUEST_CONFIRMNATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
  }
 function fulfillRandomWords(
        uint256 /*requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfwinner = randomWords[0]% s_players.length;
        address payable winner=s_players[indexOfwinner];
        s_recentWinner=winner;

        s_raffleState=RaffleState.OPEN;
        s_lastTimestamp=block.timestamp;
        s_players=new address payable[](0);
        (bool success,)=winner.call{value:address(this).balance}("");
        if(!success){
            revert Raffle__TransferFailed();
        }
        emit PickedWinner(winner);
    }
  
  /** GETTER FUNCTIONS */
  function getEntranceFee()public view returns(uint256){
    return i_entranceFee;
  }
  function getRaffleState() public view returns(RaffleState){
    return s_raffleState;
  }
  function getPlayer(uint256 _index) public view returns(address){
     return s_players[_index];

  }
  function getRecentWinner() public view returns(address){
    return s_recentWinner;
  }

  function getPlayersCount()public view returns(uint256){
    return s_players.length;
  }

   function getLasTimestamp()public view returns(uint256){
    return s_lastTimestamp;
  }
  
}