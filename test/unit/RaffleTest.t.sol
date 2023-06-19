// SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import{HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test,console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
contract RaffleTest is Test{
   /**EVENTS */
   event EnteredRaffle(address indexed player);

   //------------------------------------------
    Raffle raffle;
    HelperConfig helperconfig;

           uint256 entranceFee;
           uint256 interval;
           address vrfCoordinator;
           bytes32 gasLane;
           uint64 subscriptionId;
           uint32 callbackGasLimit;
           address Link;
    address public PLAYER=makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE= 10 ether;
function setUp()external{
    //fund PLAYER with eth
    vm.deal(PLAYER,STARTING_PLAYER_BALANCE);
    DeployRaffle deployraffle= new DeployRaffle();
     (raffle,helperconfig)=deployraffle.run();
            (entranceFee,
             interval,
             vrfCoordinator,
             gasLane,
             subscriptionId,
             callbackGasLimit,
             Link,
             
             )=helperconfig.activeNetworkconfig();
             
}

function testRafflegetInitializeState()external view{
    //!  Raffle contracts RaffleState enums value of OPEN ... this value is taken from contract.. 
    assert(raffle.getRaffleState()==Raffle.RaffleState.OPEN);
}
//? ////////////////////////
/// enterRaffle function///
//? ////////////////////////

function testRaffleRevertWhenYouDontPayEnough()external{
    //Arrange
    vm.prank(PLAYER);
    //Act+Asssert
    vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
    raffle.enterRaffle();
}

function testRaffleRecordEnteredPlayer()external{
    //Arrange
    vm.prank(PLAYER);
    //Act
    raffle.enterRaffle{value:entranceFee}();
    //assert
    assert(raffle.getPlayer(0)==address(PLAYER));
}

function testEmitsEventOnEntrance()external{
    vm.prank(PLAYER); 
    vm.expectEmit(true,false,false,false,address(raffle));
    emit EnteredRaffle(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
}

function testCantenterWhileCalculating()external{
  vm.prank(PLAYER);
  raffle.enterRaffle{value:entranceFee}();
  vm.warp(block.timestamp+interval+1);
  vm.roll(block.timestamp+1);
  raffle.performUpkeep("");
 
  vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
  vm.prank(PLAYER);
  raffle.enterRaffle{value:entranceFee}();

}

function testCheckUpkeepReturnFalseIfitHasNoBalance() public {
  //! vm.warp=> Sets block.timestamp.
  vm.warp(block.timestamp+interval+1);
  //! vm.roll=> Sets block.number.
  vm.roll(block.number+1);

  (bool upKeepNeeded,)=raffle.checkUpKeep("");
  assert(!upKeepNeeded);
}

function testCheckUpkeepReturnsFalsIfRaffleNotOpen()public{
    //Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
      //! vm.warp=> Sets block.timestamp.
    vm.warp(block.timestamp+interval+1);
      //! vm.roll=> Sets block.number.
    vm.roll(block.number+1);
    //Act
    raffle.performUpkeep("");
     //Assert
    assert(raffle.getRaffleState()==Raffle.RaffleState.CALCULATING);
}

function checkUpkeepReturnsFalseIfEnougtimeHasntPassed()public{
     //Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
      //! vm.warp=> Sets block.timestamp.
    vm.warp(block.timestamp+interval-1);
      //! vm.roll=> Sets block.number.
    vm.roll(block.number+1);
    (bool upKeepNeeded,)=raffle.checkUpKeep("");
     assert(raffle.getRaffleState()==Raffle.RaffleState.OPEN);
     assert(!upKeepNeeded);
}

function checkUpKeepReturnsTrueIfparamatersGood() public{
      //Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
      //! vm.warp=> Sets block.timestamp.
    vm.warp(block.timestamp+interval+1);
      //! vm.roll=> Sets block.number.
    vm.roll(block.number+1);
    (bool upKeepNeeded,)=raffle.checkUpKeep("");
      assert(raffle.getRaffleState()==Raffle.RaffleState.OPEN);
      assert(upKeepNeeded);
}
                //? ////////////////////
                ///  performUpkeep  ///
                //? ///////////////////
function testPerformUpkeepOnlyRunsIfCheckUpkeepIsTrue()public{
        //Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
      //! vm.warp=> Sets block.timestamp.
    vm.warp(block.timestamp+interval+1);
      //! vm.roll=> Sets block.number.
    vm.roll(block.number+1);
    raffle.performUpkeep("");
    //! in foundry theres no expectNoRevert 
    //! so if function goes without revert means test passes
}

function testPerformUpkeepRevertsIfCheckupKeepReturnsFalse()public{
    //Arrange
    uint256 currentbalance=0;
    uint256 numlayer=0;
    uint256 RaffleState=0;
    //act+assert
    vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector,
                                                                    currentbalance,
                                                                    numlayer,
                                                                    RaffleState));
    raffle.performUpkeep("");
}

modifier raffleEnteredAndTimePassed(){
          //Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
      //! vm.warp=> Sets block.timestamp.
    vm.warp(block.timestamp+interval+1);
      //! vm.roll=> Sets block.number.
    vm.roll(block.number+1);
    _;
}

function testPerformUpkeepUpdateRaffleStateandEmitsRequestId() raffleEnteredAndTimePassed public{
    //Act
     vm.recordLogs();
     raffle.performUpkeep("");
     Vm.Log [] memory entries=vm.getRecordedLogs();
     bytes32 requestId=entries[1].topics[0];
     Raffle.RaffleState rState=raffle.getRaffleState();
    assert(uint256(rState)==1); 
    assert(uint256(requestId)>0);
}

//! Use only for anvil local chain cause some test requires more arguments in fork-test
modifier skipFork(){
  if(block.chainid!=31337){
    return;
  }
  _;
}
function testFullFillRandomWordsCanOnlyBeCalledAfterPeformUpkeep(uint256 randomRequestId) 
             raffleEnteredAndTimePassed
             skipFork public{
    vm.expectRevert("nonexistent request");
    VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomRequestId,address(raffle));
}

function testFullfillRandomWordsPicksWinnerResetsAndSendsMoney()  
             skipFork 
             public{
    uint256 additionalEntrants=5;
    uint256 startingIndex=0;
    uint256 previousTimeStamp=raffle.getLasTimestamp();
    for(uint256 i=startingIndex;i<additionalEntrants;i++){
          address player=address(uint160(i));
          hoax(player,STARTING_PLAYER_BALANCE);
          raffle.enterRaffle{value:entranceFee}();
    }
          //! vm.warp=> Sets block.timestamp.
         vm.warp(block.timestamp+interval+1);
         //! vm.roll=> Sets block.number.
         vm.roll(block.number+1);

    uint256 totalPrize=(entranceFee*(additionalEntrants));
     vm.recordLogs();
     raffle.performUpkeep("");
     Vm.Log [] memory entries=vm.getRecordedLogs();
     bytes32 requestId=entries[1].topics[1];
     console.log("Sub-ID:",uint256(requestId));
      VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
        uint256(requestId),
        address(raffle));
     assert(uint256(raffle.getRaffleState())==0);
     assert(raffle.getRecentWinner()!=address(0));
     assert(raffle.getLasTimestamp()>previousTimeStamp);
     console.log("Recent Winners balance:",address(raffle.getRecentWinner()).balance);
     console.log("Starting balance+total_prize:",STARTING_PLAYER_BALANCE+totalPrize);
     assert(address(raffle.getRecentWinner()).balance==STARTING_PLAYER_BALANCE+totalPrize-entranceFee);
}
}