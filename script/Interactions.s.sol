// SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;

import {Script,console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
contract CreateSubscription is Script{

function createSubscriptionUsingConfig() public returns(uint64){
HelperConfig helperconfig=new HelperConfig();
           ( , ,address vrfCoordinator, , , , )= helperconfig.activeNetworkconfig();
           return createSubscription(vrfCoordinator);
}
function createSubscription(address _vrfCoordinator) public returns(uint64){
console.log("Creating SubscriptionId!!!");
vm.startBroadcast();
uint64 subId=VRFCoordinatorV2Mock(_vrfCoordinator).createSubscription();
vm.stopBroadcast();
console.log("Your Sub-Id:",subId);
console.log("Please update Sub-Id in HelperConfig.s.sol");
return subId;

}

function run() public  returns(uint64){
    return createSubscriptionUsingConfig();
}
}


contract FundSubscription is Script{
    uint96 public constant FUND_AMOUNT=3 ether;

    function fundSubscriptionUsingConfig()public{
      HelperConfig helperconfig=new HelperConfig();
           ( , ,address vrfCoordinator, ,uint64 subId , ,address Link)= helperconfig.activeNetworkconfig();
           fundSubscription(vrfCoordinator,subId,Link);
    }
   function fundSubscription(address _vrfCoordinator,uint64 _subId,address _link)public{
        console.log("Funding subscription:",_subId);
        console.log("Using vrf-coordinator:",_vrfCoordinator);
        console.log("On chain:",block.chainid);

        if(block.chainid==31337){
            vm.startBroadcast();
            VRFCoordinatorV2Mock(_vrfCoordinator).fundSubscription(_subId,FUND_AMOUNT);
            vm.stopBroadcast();
        }else{
            vm.startBroadcast();
            LinkToken(_link).transferAndCall(_vrfCoordinator,FUND_AMOUNT,abi.encode(_subId));
            vm.stopBroadcast();
        }
    }
    function run()public{
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script{
    function addConsumer(address _raffle,address _vrfcoordinator,uint64 _subId)public{
            console.log("Adding consumer contract:",_raffle);
            console.log("Using vrfCoordinator:",_vrfcoordinator);
            console.log("On Chain-Id:",block.chainid);
            vm.startBroadcast();
            VRFCoordinatorV2Mock(_vrfcoordinator).addConsumer(_subId,_raffle);
            vm.stopBroadcast();
    }

    function addConsumerByConfig(address _raffle) public{
        HelperConfig helperconfig=new HelperConfig();
         ( , ,address vrfCoordinator, ,uint64 subId , , )= helperconfig.activeNetworkconfig();
         addConsumer(_raffle,vrfCoordinator,subId);
    }
    function run() external{
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerByConfig(raffle);
    }
}