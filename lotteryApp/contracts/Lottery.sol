// SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/KeeperCompatible.sol';
import '@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol';

//errors
error Lottery__Not_Have_Enough_Eth();
error Lottery__Transaction_Failed();
error Lottery__Is_Not_Open();
error Lottery_Upkeep_Not_Needed(uint256 currentBalance,uint256 players,uint256 lotteryState);

// Paying the amount
// Time-based trigger automation for winner for every x minutes
// Selecting the random winner (verifying randomness)
// Chainlink keepers - automation,time triggers


/*
@title Lottery,
@author Syed Hussain Saber
@implementing Chainlink VRF and Chainlink Automation
 */

 contract Lottery is VRFConsumerBaseV2,KeeperCompatibleInterface{
VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
//events
event lotteryEnter(address indexed player);
event requestedLotteryWinner(uint256 indexed requestId);
event previousRecentWinners(address indexed recentWinners);

//enums
enum lotteryState{OPEN,CALCULATING}
// State Variables
uint256 private immutable i_entrance_fees;
address[] private s_players;
bytes32 immutable private i_gasLane;
uint64 immutable private i_subId;
uint16 constant private MINIMUMREQUESTCONFIRMATIONS=3;
uint32 immutable private i_callBackGasLimit;
uint32 private constant NUMWORDS=1;
uint256 private immutable i_interval;

//Lottery Variables
uint256 private s_last_time_stamped;
address private s_recentWinner;
lotteryState private s_lotteryState;

// Functions
constructor(address _vrfCoordinator,uint256 entranceFees,bytes32 gasLane,uint64 subId
,uint32 callBackGasLimit,uint256 interval)VRFConsumerBaseV2(_vrfCoordinator){
    s_lotteryState=lotteryState.OPEN;
i_entrance_fees=entranceFees;
i_vrfCoordinator=VRFCoordinatorV2Interface(_vrfCoordinator);
i_gasLane=gasLane;
i_subId=subId;
i_callBackGasLimit=callBackGasLimit;
s_last_time_stamped=block.timestamp;
i_interval=interval;
}

function lotteryEntrance() payable public {
if(msg.value < i_entrance_fees){
revert Lottery__Not_Have_Enough_Eth();
}
if(s_lotteryState!=lotteryState.OPEN)
{
    revert Lottery__Is_Not_Open();
}

s_players.push(payable(msg.sender));
emit lotteryEnter(msg.sender);
}

function checkUpkeep(bytes memory /* checkData */) public returns (bool upkeepNeeded, bytes memory /*performData*/){
bool isOpen = (s_lotteryState==lotteryState.OPEN);
bool timePassed=((block.timestamp-s_last_time_stamped)>i_interval);
bool hasBalance=(address(this).balance>0);
bool hasPlayers=(s_players.length>0);
upkeepNeeded=(isOpen && timePassed && hasBalance && hasPlayers);
}

function performUpkeep(bytes calldata /*performData*/) external {
(bool upKeepNeeded,)=checkUpkeep("");
if(!upKeepNeeded){
revert Lottery_Upkeep_Not_Needed(address(this).balance,s_players.length,uint256(s_lotteryState));
}
    s_lotteryState=lotteryState.CALCULATING;
uint256 requestId=i_vrfCoordinator.requestRandomWords(
i_gasLane,
i_subId,
MINIMUMREQUESTCONFIRMATIONS,
i_callBackGasLimit,
NUMWORDS
);
emit requestedLotteryWinner(requestId);
}

function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override{
    uint256 randomIndex=(randomWords[0]%s_players.length);
address recentWinner=s_players[randomIndex];
s_recentWinner=recentWinner;
s_last_time_stamped=block.timestamp;
s_players=new address payable[](0);
(bool success,)=s_recentWinner.call{value:address(this).balance}("");
if(!success){
    revert Lottery__Transaction_Failed();
}
s_lotteryState=lotteryState.OPEN;
emit previousRecentWinners(recentWinner);
}



// view and pure functions

    function getEntranceFees() public view returns(uint256){
uint256 entrance_fees = i_entrance_fees;
return entrance_fees;
    }

    function getPlayers(uint256 index) public view returns(address){
        return s_players[index];
    }

function getRecentWinner()public view returns(address){
return s_recentWinner;
}

function getLotteryState() public view returns(lotteryState){
    return s_lotteryState;
}

function getLastTimeStamp() view public returns(uint256){
    return s_last_time_stamped;
}

function getNumWords() public pure returns(uint256){
    return NUMWORDS;
}
function getRequesConfirmations() pure public returns(uint256){
    return MINIMUMREQUESTCONFIRMATIONS;
}

function getInterval() public view returns(uint256){
return i_interval;
}
}
