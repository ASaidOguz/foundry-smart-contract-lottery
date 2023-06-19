// SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
contract HelperConfig is Script{
struct NetworkConfig{
           uint256 entranceFee;
           uint256 interval;
           address vrfCoordinator;
           bytes32 gasLane;
           uint64 subscriptionId;
           uint32 callbackGasLimit;
           address Link;
           uint256 deployerKey;
}
NetworkConfig public activeNetworkconfig;
uint256 public constant DEFAULT_ANVIL_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
constructor(){
    if(block.chainid==11155111){
        activeNetworkconfig=getSepoliaConfig();
    }else{
        activeNetworkconfig=getOrCreateAnvilConfig();
    }
}
function getSepoliaConfig() public view returns(NetworkConfig memory){
    return(NetworkConfig({
        entranceFee:0.01 ether,
        interval: 30,
        vrfCoordinator:0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
        gasLane:0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
        subscriptionId:2965,
        callbackGasLimit:500000, //500,000 gas
        Link:0x779877A7B0D9E8603169DdbD7836e478b4624789,
        deployerKey:vm.envUint("PRIVATE_KEY_SEPOLIA")
    }));
}

function getOrCreateAnvilConfig() public  returns(NetworkConfig memory){
     if(activeNetworkconfig.vrfCoordinator!=address(0)){
       return activeNetworkconfig;
     }

     uint96 _baseFee=0.25 ether;//0.25 LINK
     uint96 _gasPriceLink=1e9;//1 gwei LINK

     vm.startBroadcast();
     VRFCoordinatorV2Mock vrfcoodinatorV2mock= new VRFCoordinatorV2Mock(_baseFee,_gasPriceLink);
     LinkToken link=new LinkToken();
     vm.stopBroadcast();

    return(NetworkConfig({
        entranceFee:0.01 ether,
        interval: 30,
        vrfCoordinator:address(vrfcoodinatorV2mock),
        gasLane:0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
        subscriptionId:0, //our script will add this...
        callbackGasLimit:500000, //500,000 gas
        Link:address(link),
        deployerKey:DEFAULT_ANVIL_KEY
    }));
}
}