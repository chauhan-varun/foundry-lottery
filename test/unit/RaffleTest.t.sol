// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console, console2} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig, Constants} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {LinkToken} from "../../test/mocks/LinkToken.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, Constants {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RequestedRaffleWinner(uint256 indexed requestId);
    event PlayerEntered(address indexed player);
    event PickedWinner(address indexed winner);

    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    bytes32 keyHash;
    LinkToken link;

    address public PLAYER = makeAddr("player");
    uint256 public constant PLAYER_INIITAL_BALANCE = 10 ether;
    uint256 public constant LINK_BALANCE = 100 ether;

    /** events */

    function setUp() public {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.deal(PLAYER, PLAYER_INIITAL_BALANCE);

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        keyHash = config.keyHash;
        link = LinkToken(config.link);

        vm.startPrank(msg.sender);
        if (block.chainid == LOCAL_CHAIN_ID) {
            link.mint(msg.sender, LINK_BALANCE);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                LINK_BALANCE
            );
        }
        link.approve(vrfCoordinator, LINK_BALANCE);
        vm.stopPrank();
    }

    function testRaffleInitializesIsOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.Open);
    }

    /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/

    modifier enteredRaffle() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        _;
    }

    modifier timeHasPassed() {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) return;
        _;
    }

    function testRaffleRevertWhenYouDontPay() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughFunds.selector);
        raffle.enterRaffle();
    }

    function testRafflePlayerRecords() public enteredRaffle {
        assert(raffle.getRafflePlayer(0) == PLAYER);
    }

    function testEnteringRaffleEventEmits() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit PlayerEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testRevertPlayerWhenRaffleIsClosed()
        public
        enteredRaffle
        timeHasPassed
    {
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__Closed.selector);
        vm.prank(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
    }

    /*//////////////////////////////////////////////////////////////
                              CHECKUP KEEP
    //////////////////////////////////////////////////////////////*/

    function testCheckUpKeepReturnFalseIfInsufficientBalance()
        public
        timeHasPassed
    {
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        assert(upKeepNeeded == false);
    }

    function testCheckUpKeepReturnFalseIfRaffleIsntOpen()
        public
        enteredRaffle
        timeHasPassed
    {
        raffle.performUpkeep("");
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // bool upkeep = raffle.checkUpkeep("");

        assert(Raffle.RaffleState.Closed == raffle.getRaffleState());
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnFalseIfEnoughTimeHasntPass()
        public
        enteredRaffle
    {
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnTrueIfConditionsMet()
        public
        enteredRaffle
        timeHasPassed
    {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORM UPKEEP
    //////////////////////////////////////////////////////////////*/

    function testPerformUpKeepRunsOnlyIfCheckUpkeepTrue()
        public
        enteredRaffle
        timeHasPassed
    {
        raffle.performUpkeep("");
    }

    function testPerformUpKeepRevertIfCheckUpkeepFalse() public enteredRaffle {
        uint256 balance = entranceFee;
        uint256 length = 1;
        Raffle.RaffleState state = raffle.getRaffleState();

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                balance,
                length,
                state
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpKeepEmitRequestId()
        public
        enteredRaffle
        timeHasPassed
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestId = entries[1].topics[1];
        Raffle.RaffleState state = raffle.getRaffleState();

        assert(requestId > 0);
        assertEq(uint256(state), 1);
    }

    /*//////////////////////////////////////////////////////////////
                         FULLFILL RANDOM WORDS
    //////////////////////////////////////////////////////////////*/

    function testFullFillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(
        uint256 randomRequestId
    ) public skipFork enteredRaffle timeHasPassed {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        enteredRaffle
        skipFork
    {
        address expectedWinner = address(1);

        // Arrange
        uint256 additionalEntrances = 3;
        uint256 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrances;
            i++
        ) {
            address player = address(uint160(i));
            hoax(player, 1 ether); // deal 1 eth to the player
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 startingBalance = expectedWinner.balance;

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        console2.logBytes32(entries[1].topics[1]);
        bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrances + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == startingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
