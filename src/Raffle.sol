// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Raffle contract
 * @author varun chauhan
 * @notice this is for creating sample Raffle contract
 * @dev Raffle contract
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /** errors */
    error Raffle__NotEnoughFunds();
    error Raffle__Closed();
    error Raffle__TransactionFailed();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 length,
        RaffleState state
    );

    /** type declerations */
    enum RaffleState {
        Open,
        Closed
    }

    /** variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;

    /** events */
    event PlayerEntered(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        uint256 subscriptionId,
        uint32 callbackGasLimit,
        bytes32 keyHash
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_interval = interval;
        i_keyHash = keyHash;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.Open;
    }

    function enterRaffle() public payable {
        if (s_raffleState != RaffleState.Open) revert Raffle__Closed();
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughFunds();
        }
        s_players.push(payable(msg.sender));
        emit PlayerEntered(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool timeHasPassed = block.timestamp - s_lastTimeStamp > i_interval;
        bool isOpen = s_raffleState == RaffleState.Open;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > i_entranceFee;

        upkeepNeeded = timeHasPassed && isOpen && hasPlayers && hasBalance;
        return (upkeepNeeded, "");
    }

    function pickWinner(bytes calldata /*performData*/) public {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded)
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                s_raffleState
            );

        s_raffleState = RaffleState.Closed;

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        // Effects (internal contract state)
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;

        s_raffleState = RaffleState.Open;
        s_lastTimeStamp = block.timestamp;
        s_players = new address payable[](0);
        emit PickedWinner(winner);

        // interactions (external contract interactions)
        (bool sucess, ) = winner.call{value: address(this).balance}("");
        if (!sucess) revert Raffle__TransactionFailed();
    }

    /** getters */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
